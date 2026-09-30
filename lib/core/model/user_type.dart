/// What a user is entitled to. Granted only by redeeming a referral code, so
/// the server owns the stored value — see `redeemReferralCode` in functions/.
/// Persisted by [id] on `users/{uid}.userType`.
enum UserType {
  normal('normal'),
  ugc('ugc'),
  admin('admin');

  const UserType(this.id);
  final String id;

  /// Anything unknown or absent is a normal, paying user.
  static UserType fromId(String? id) =>
      UserType.values.firstWhere((t) => t.id == id, orElse: () => UserType.normal);

  /// Admins and creators get the app without paying.
  bool get skipsPaywall => this != UserType.normal;
}
