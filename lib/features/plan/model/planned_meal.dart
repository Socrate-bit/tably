import 'package:equatable/equatable.dart';

import '../../../core/model/weekday.dart';

/// One dinner slot in the weekly plan, stored at
/// `users/{uid}/plan/{day}` so a single day can change without rewriting the week.
class PlannedMeal extends Equatable {
  const PlannedMeal({
    required this.day,
    required this.recipeId,
    required this.title,
    required this.photoKey,
    required this.cravingId,
    required this.cookTime,
    required this.price,
  });

  final Weekday day;
  final String recipeId;
  final String title;
  final String photoKey;
  final String cravingId;
  final String cookTime;

  /// Cost per serving; the card multiplies by household size.
  final double price;

  Map<String, dynamic> toMap() => {
        'day': day.id,
        'recipeId': recipeId,
        'title': title,
        'photoKey': photoKey,
        'cravingId': cravingId,
        'cookTime': cookTime,
        'price': price,
      };

  factory PlannedMeal.fromMap(Map<String, dynamic> map) => PlannedMeal(
        day: Weekday.fromId(map['day'] as String? ?? 'monday'),
        recipeId: map['recipeId'] as String? ?? '',
        title: map['title'] as String? ?? '',
        photoKey: map['photoKey'] as String? ?? '',
        cravingId: map['cravingId'] as String? ?? '',
        cookTime: map['cookTime'] as String? ?? '',
        price: (map['price'] as num?)?.toDouble() ?? 0,
      );

  @override
  List<Object?> get props => [day, recipeId, title, photoKey, cravingId, cookTime, price];
}
