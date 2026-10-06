import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Reads the App Review flag at `settings/review`. Its `app_version` field
/// names the builds under review as "version.build", e.g. "0.1.0.3" for
/// version 0.1.0 build 3.
class ReviewService {
  ReviewService({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  /// Resolved on first use, so the service can be built before Firebase is.
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  /// This install's "version.build", in the same format as the flag.
  Future<String> currentBuild() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version}.${info.buildNumber}';
  }

  /// Live list of builds under review.
  Stream<List<String>> watchBuilds() =>
      _db.collection('settings').doc('review').snapshots().map((snap) => buildsFrom(snap.data()?['app_version']));

  /// The `app_version` field may hold one build or a list of them.
  static List<String> buildsFrom(Object? field) => switch (field) {
    final String build => [build],
    final List<dynamic> builds => [for (final b in builds) '$b'],
    _ => const [],
  };
}
