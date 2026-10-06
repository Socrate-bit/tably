import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:tably/core/model/preference_option.dart';
import 'package:tably/features/preferences/model/user_profile.dart';
import 'package:tably/features/recipe/model/recipe.dart';
import 'package:tably/features/recipe/service/recipe_ai_service.dart';
import 'package:tably/features/recipe/service/recipe_search_service.dart';

/// Gemini's REST endpoint, with the API key Firebase AI Logic can't take
/// outside the app (it needs App Check).
class GeminiRest {
  GeminiRest(this.apiKey);

  final String apiKey;
  final _client = HttpClient();

  /// The first candidate's content for [body], retrying while the API is busy.
  Future<Map<String, Object?>> generate(String model, Map<String, Object?> body) async {
    final uri = Uri.https('generativelanguage.googleapis.com', '/v1beta/models/$model:generateContent');
    for (var attempt = 1; ; attempt++) {
      final ({int statusCode, String text}) response;
      try {
        response = await _send(uri, body).timeout(const Duration(seconds: 90));
      } on TimeoutException {
        // A request that never answers is retried like a busy API.
        if (attempt == 8) rethrow;
        debugPrint('[GeminiRest] timed out, retrying');
        continue;
      }
      final text = response.text;
      if (response.statusCode == 200) {
        final json = jsonDecode(text) as Map<String, Object?>;
        final candidate = (json['candidates'] as List?)?.firstOrNull as Map?;
        return Map<String, Object?>.from(candidate?['content'] as Map? ?? {'role': 'model', 'parts': <Object?>[]});
      }
      final busy = response.statusCode == 429 || response.statusCode >= 500;
      if (!busy || attempt == 8) throw HttpException('Gemini ${response.statusCode}: $text', uri: uri);
      debugPrint('[GeminiRest] ${response.statusCode}, retrying');
      await Future<void>.delayed(Duration(seconds: (2 * attempt * attempt).clamp(2, 30)));
    }
  }

  Future<({int statusCode, String text})> _send(Uri uri, Map<String, Object?> body) async {
    final request = await _client.postUrl(uri);
    request.headers
      ..contentType = ContentType.json
      ..set('x-goog-api-key', apiKey);
    request.add(utf8.encode(jsonEncode(body)));
    final response = await request.close();
    return (statusCode: response.statusCode, text: await response.transform(utf8.decoder).join());
  }

  /// The non-thought text of a content.
  static String textOf(Map<String, Object?> content) => [
    for (final p in content['parts'] as List? ?? const [])
      if (p is Map && p['text'] is String && p['thought'] != true) p['text'] as String,
  ].join();
}

/// The app's recipe Gemini steps (checking and translating found recipes,
/// writing and deriving recipes) on real Gemini, through [GeminiRest].
class LiveAi extends RecipeAiService {
  LiveAi(this.gemini);

  final GeminiRest gemini;

  /// What the recipe writer was asked to write.
  final written = <String>[];

  @override
  Future<String?> generate({
    required String model,
    required String system,
    required GenerationConfig config,
    required String input,
  }) async => GeminiRest.textOf(
    await gemini.generate(model, {
      'systemInstruction': Content.system(system).toJson(),
      'contents': [Content.text(input).toJson()],
      'generationConfig': config.toJson(),
    }),
  );

  @override
  Future<Recipe> write(String request, UserProfile profile, {Recipe? base}) {
    written.add(base == null ? request : '${base.title}: $request');
    return super.write(request, profile, base: base);
  }
}

/// How Spoonacular behaves in a scenario.
enum SpoonacularMode {
  /// The real functions, on the emulator, on real Spoonacular.
  live,

  /// Every search finds nothing.
  empty,

  /// The user's searches for today are spent.
  spent,
}

/// The app's Cloud Functions on the local emulator, which run the deployed
/// code on real Spoonacular. Each [uid] has its own daily searches there, in
/// the emulator's Firestore, never production's.
class LiveSearch extends RecipeSearchService {
  LiveSearch({required this.uid, this.mode = SpoonacularMode.live});

  final String uid;
  final SpoonacularMode mode;

  static const _base = 'http://127.0.0.1:5001/tably-9f3c2/europe-west1';
  final _client = HttpClient();

  /// The query of each AI chef search, in order.
  final agentQueries = <String>[];

  @override
  Future<List<Map<String, dynamic>>> agentSearch(
    UserProfile profile, {
    String? query,
    List<String> includeIngredients = const [],
    Set<Cuisine> cuisines = const {},
    Craving? craving,
    RecipeProtein? protein,
  }) {
    agentQueries.add(
      [
        ?query,
        if (includeIngredients.isNotEmpty) 'with ${includeIngredients.join(', ')}',
        ...cuisines.map((c) => c.id),
        ?protein?.id,
        ?craving?.id,
      ].join(' · '),
    );
    return super.agentSearch(
      profile,
      query: query,
      includeIngredients: includeIngredients,
      cuisines: cuisines,
      craving: craving,
      protein: protein,
    );
  }

  @override
  Future<Map<String, dynamic>> invoke(String name, Map<String, Object?> data) async {
    switch (mode) {
      case SpoonacularMode.empty:
        return {'recipes': <Object?>[]};
      case SpoonacularMode.spent:
        throw _FunctionsError('resource-exhausted', 'Recipe search quota reached.');
      case SpoonacularMode.live:
    }
    final request = await _client.postUrl(Uri.parse('$_base/$name'));
    request.headers
      ..contentType = ContentType.json
      // The emulator reads the caller from an unsigned token.
      ..set('Authorization', 'Bearer ${_token(uid)}');
    request.add(utf8.encode(jsonEncode({'data': data})));
    // The app's callable timeout.
    final response = await request.close().timeout(const Duration(seconds: 70));
    final body = jsonDecode(await response.transform(utf8.decoder).join()) as Map<String, dynamic>;
    if (body['error'] case final Map error) {
      final status = '${error['status']}'.toLowerCase().replaceAll('_', '-');
      throw _FunctionsError(status, '${error['message']}');
    }
    return Map<String, dynamic>.from(body['result'] as Map);
  }

  static String _token(String uid) {
    String part(Map<String, Object?> json) => base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return '${part({'alg': 'none', 'typ': 'JWT'})}.${part({
      'sub': uid,
      'user_id': uid,
      'aud': 'tably-9f3c2',
      'iss': 'https://securetoken.google.com/tably-9f3c2',
      'iat': now,
      'exp': now + 3600,
    })}.';
  }
}

/// A Cloud Function error, as the app's callable client raises it.
class _FunctionsError extends FirebaseFunctionsException {
  _FunctionsError(String code, String message) : super(code: code, message: message);
}
