import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../../../core/model/user_type.dart';
import '../../../core/util/functions_region.dart';

/// Reads referral codes and redeems them through the `redeemReferralCode`
/// Cloud Function, which is the only writer of `users/{uid}.userType`.
class ReferralService {
  ReferralService({FirebaseFirestore? firestore, FirebaseFunctions? functions})
      : _firestore = firestore,
        _functions = functions;

  /// Sentinel returned by [validateCode] when the code is out of uses.
  static const exhausted = 'exhausted';

  final FirebaseFirestore? _firestore;
  final FirebaseFunctions? _functions;

  /// Resolved on first use, so the service can be built before Firebase is.
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  FirebaseFunctions get _fn => _functions ?? FirebaseFunctions.instanceFor(region: functionsRegion);

  /// Codes are stored uppercase, so entry is case-insensitive.
  static String normalise(String code) => code.trim().toUpperCase();

  /// Cheap pre-check so the user gets a precise error without a round trip to
  /// the function. Returns the granted type, [exhausted], or null when the code
  /// is unusable. The function re-validates everything regardless.
  Future<String?> validateCode(String code) async {
    try {
      final doc = await _db.collection('referralCodes').doc(normalise(code)).get();
      final data = doc.data();
      if (!doc.exists || data == null) return null;
      final type = data['type'] as String?;
      final numUse = (data['numUse'] as num?)?.toInt();
      final maxUse = (data['maxUse'] as num?)?.toInt();
      if (type == null || numUse == null || maxUse == null) return null;
      if (numUse >= maxUse) return exhausted;
      return type;
    } catch (e) {
      debugPrint('[ReferralService] validateCode failed: $e');
      return null;
    }
  }

  /// Redeems the code and returns the granted type. Throws
  /// [FirebaseFunctionsException] so the cubit can tell the failures apart.
  Future<UserType> redeemCode(String code) async {
    final callable = _fn.httpsCallable('redeemReferralCode');
    final result = await callable.call<Map<String, dynamic>>({'code': normalise(code)});
    final type = UserType.fromId(result.data['userType'] as String?);
    debugPrint('[ReferralService] redeemed a code granting ${type.id}');
    return type;
  }
}
