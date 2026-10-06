import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tably/features/chat/cubit/chat_cubit.dart';
import 'package:tably/features/chat/model/chat_message.dart';

import '../fixtures/chat_fixtures.dart';
import 'chef_scenarios.dart';
import 'gemini_rest_agent.dart';
import 'live_backends.dart';

/// Plays every scenario of chef_scenarios.dart against live Gemini and real
/// Spoonacular, with the app's real chat, tools, prompt and Cloud Functions,
/// and writes a report with each run's checks and full transcript to
/// .context/chef_eval/, to be read, not just counted. Skipped without a key,
/// so `flutter test` stays offline. Needs the emulators (see
/// chef_scenarios.md):
///
///   GEMINI_API_KEY=… flutter test test/eval/chef_eval_test.dart
///
/// EVAL_RUNS (3), EVAL_ONLY (e.g. A1,C2), EVAL_CONCURRENCY (4) and
/// EVAL_LABEL (in the report's name) tune it; EVAL_VERBOSE keeps the logs.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final env = Platform.environment;
  final key = env['GEMINI_API_KEY'] ?? '';

  test('AI chef eval', () async {
    // The test binding blocks HTTP; the eval needs the real network.
    HttpOverrides.global = null;
    if (env['EVAL_VERBOSE'] == null) debugPrint = (String? message, {int? wrapWidth}) {};

    final runs = int.tryParse(env['EVAL_RUNS'] ?? '') ?? 3;
    final only = (env['EVAL_ONLY'] ?? '').split(',').where((s) => s.isNotEmpty).toSet();
    final chosen = scenarios.where((s) => only.isEmpty || only.contains(s.id)).toList();
    final jobs = [for (final s in chosen) for (var i = 0; i < runs; i++) s];
    final results = <Scenario, List<EvalRun>>{for (final s in chosen) s: []};
    final stamp = DateTime.now().millisecondsSinceEpoch;

    // A few conversations at a time, to stay under the API's rate limit.
    var next = 0;
    Future<void> worker() async {
      while (next < jobs.length) {
        final scenario = jobs[next++];
        final run = await _play(scenario, GeminiRest(key), uid: 'eval-${scenario.id}-$next-$stamp');
        results[scenario]!.add(run);
        stdout.writeln('${scenario.id} ${_passed(scenario, run) ? 'pass' : 'FAIL'}');
      }
    }

    await Future.wait([for (var i = 0; i < (int.tryParse(env['EVAL_CONCURRENCY'] ?? '') ?? 4); i++) worker()]);

    final report = _report(results, label: env['EVAL_LABEL'] ?? 'run');
    final time = DateTime.now().toIso8601String().substring(0, 19).replaceAll(':', '-');
    final file = File('.context/chef_eval/${env['EVAL_LABEL'] ?? 'run'}-$time.md')..createSync(recursive: true);
    file.writeAsStringSync(report);
    stdout.writeln('Report: ${file.path}');
  }, skip: key.isEmpty ? 'Set GEMINI_API_KEY to run the live AI chef eval' : false, timeout: Timeout.none);
}

/// Plays [scenario] once, answering its cards by its approval policy.
Future<EvalRun> _play(Scenario scenario, GeminiRest gemini, {required String uid}) async {
  final agent = GeminiRestAgent(gemini);
  final search = LiveSearch(uid: uid, mode: scenario.spoonacular);
  final ai = LiveAi(gemini);
  final h = await ChatHarness.start(agent, user: scenario.user, search: search, ai: ai);
  try {
    if (scenario.memory.isNotEmpty) await h.profile.setCustomInstructions(scenario.memory);
    await scenario.setup?.call(h);
    await pumpEventQueue();
    final weekBefore = h.plan.state.week;
    final profileBefore = h.profile.state.profile;

    final turns = <EvalTurn>[];
    for (final (i, text) in scenario.turns.indexed) {
      final seen = {for (final m in h.chat.state.messages) m.id};
      final callsFrom = agent.calls.length;
      await h.chat.send(text);
      while (h.chat.state.status == ChatStatus.confirming) {
        final card = h.chat.state.messages.where((m) => m.action?.status == ActionStatus.pending).firstOrNull;
        if (card == null) break;
        final tool = card.action!.tool;
        if (scenario.approval(tool, i)) {
          // Sharing opens the phone's share sheet; here it just succeeds.
          await h.chat.approve(card.id, run: tool == 'share_shopping_list' ? () async => {'ok': true} : null);
        } else {
          await h.chat.decline(card.id);
        }
      }
      await pumpEventQueue();
      final added = h.chat.state.messages.where((m) => !seen.contains(m.id)).toList();
      turns.add(
        EvalTurn(
          user: text,
          calls: agent.calls.sublist(callsFrom),
          cards: [for (final m in added) ?m.action],
          reply: [for (final m in added) if (m.role == ChatRole.assistant && m.text.isNotEmpty) m.text].join('\n'),
        ),
      );
      if (h.chat.state.status == ChatStatus.failed) break;
    }
    return EvalRun(
      turns: turns,
      weekBefore: weekBefore,
      weekAfter: h.plan.state.week,
      profileBefore: profileBefore,
      profileAfter: h.profile.state.profile,
      searches: search.agentQueries,
      written: ai.written,
      error: h.chat.state.status == ChatStatus.failed ? h.chat.state.error : null,
    );
  } catch (e) {
    return EvalRun(
      turns: const [],
      weekBefore: h.plan.state.week,
      weekAfter: h.plan.state.week,
      profileBefore: h.profile.state.profile,
      profileAfter: h.profile.state.profile,
      searches: const [],
      written: const [],
      error: e,
    );
  } finally {
    await h.close();
  }
}

bool _check(Check c, EvalRun run) {
  try {
    return c.test(run);
  } catch (_) {
    return false;
  }
}

bool _passed(Scenario s, EvalRun run) => run.error == null && s.checks.every((c) => _check(c, run));

/// The summary table, then every run in full.
String _report(Map<Scenario, List<EvalRun>> results, {required String label}) {
  final out = StringBuffer('# AI chef eval: $label\n\n')
    ..writeln('${DateTime.now().toIso8601String().substring(0, 16)}, ${results.values.first.length} run(s) per scenario.\n')
    ..writeln('| Scenario | Passed | Failing checks |')
    ..writeln('|---|---|---|');
  for (final MapEntry(key: s, value: runs) in results.entries) {
    final failing = <String, int>{};
    for (final run in runs) {
      if (run.error != null) failing.update('error', (n) => n + 1, ifAbsent: () => 1);
      for (final c in s.checks.where((c) => !_check(c, run))) {
        failing.update(c.name, (n) => n + 1, ifAbsent: () => 1);
      }
    }
    final passed = runs.where((r) => _passed(s, r)).length;
    out.writeln(
      '| ${s.id} ${s.title} | $passed/${runs.length} | ${failing.entries.map((e) => '${e.key} (${e.value})').join('; ')} |',
    );
  }

  for (final MapEntry(key: s, value: runs) in results.entries) {
    out.writeln('\n## ${s.id}: ${s.title}');
    for (final (n, run) in runs.indexed) {
      out.writeln('\n### Run ${n + 1}: ${_passed(s, run) ? 'pass' : 'FAIL'}');
      for (final c in s.checks) {
        out.writeln('- ${_check(c, run) ? '✅' : '❌'} ${c.name}');
      }
      if (run.error != null) out.writeln('- ❌ error: ${_short(run.error)}');
      for (final t in run.turns) {
        out.writeln('\n**User:** ${t.user}\n');
        for (final c in t.calls) {
          out.writeln('- `${c.name}` ${_short(jsonEncode(c.args), 300)}');
          if (c.result case final result?) out.writeln('  - → ${_result(result)}');
        }
        for (final card in t.cards) {
          out.writeln('- card `${card.tool}` (${card.status.id}): ${_short(jsonEncode(card.preview), 400)}');
        }
        out.writeln('\n**Chef:** ${t.reply.isEmpty ? '(no text)' : t.reply}');
      }
      final changed = run.changedSlots;
      if (changed.isNotEmpty) {
        out.writeln('\nWeek changes:');
        for (final k in changed) {
          out.writeln('- $k: ${run.weekBefore.slotByKey(k)?.recipe.title} → ${run.weekAfter.slotByKey(k)?.recipe.title}');
        }
      }
      if (run.searches.isNotEmpty) out.writeln('\nSpoonacular queries: ${run.searches}');
      if (run.written.isNotEmpty) out.writeln('\nWritten: ${run.written}');
    }
  }
  return out.toString();
}

/// A tool's answer, with found recipes as titles.
String _result(Map<String, Object?> result) {
  final recipes = result['recipes'];
  if (recipes is! List) return _short(jsonEncode(result), 300);
  final rest = {...result}..remove('recipes');
  return [
    '${recipes.length} recipe(s): ${recipes.map((r) => '${(r as Map)['title']} (${r['id']}, ${r['protein']}, ${r['price_eur_per_portion']}€, ${r['minutes']}m${r['in_week'] == true ? ', in week' : ''})').join('; ')}',
    if (rest.isNotEmpty) jsonEncode(rest),
  ].join(' ');
}

String _short(Object? value, [int max = 200]) {
  final text = '$value'.replaceAll('\n', ' ');
  return text.length <= max ? text : '${text.substring(0, max)}…';
}
