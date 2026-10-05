import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../analytics/analytics_service.dart';
import '../../l10n/app_localizations.dart';
import 'error_feedback.dart';

/// The legal documents, hosted online rather than shipped in the binary so a
/// wording change goes live without an App Store release — and so the in-app
/// link can never drift from the published policy.
abstract final class LegalLinks {
  /// GitHub Pages (Socrate-bit/app-support), not the repository's /blob/ URL:
  /// /blob/ opens GitHub's source viewer and shows the policy as raw HTML.
  static const privacyPolicy = 'https://ecomparis.org/privacy_tably.html';
  static const terms = 'https://ecomparis.org/terms_tably.html';
}

/// Opens a legal document in the device browser. Feedback is shown only when
/// the link fails to open.
Future<void> openLegalLink(BuildContext context, String url) async {
  final message = AppL10n.of(context).errorOpenLink;
  try {
    if (await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      debugPrint('[LegalLinks] opened $url');
      return;
    }
    debugPrint('[LegalLinks] launchUrl refused $url');
  } catch (e, s) {
    AnalyticsService.reportError('LegalLinks', 'open $url', e, stack: s);
  }
  if (context.mounted) showErrorBanner(context, message);
}
