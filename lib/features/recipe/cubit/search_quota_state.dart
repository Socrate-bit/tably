part of 'search_quota_cubit.dart';

class SearchQuotaState extends Equatable {
  const SearchQuotaState({required this.today, this.limit = 30, this.day, this.count = 0});

  /// The current UTC day, "YYYY-MM-DD".
  final String today;

  /// Searches per UTC day for this user's type (see [UserType.dailySearches]).
  final int limit;

  /// The UTC day [count] was counted on, or null before any search.
  final String? day;
  final int count;

  /// Searches left today: the count only applies on the day it was made.
  int get remaining => day == today ? (limit - count).clamp(0, limit) : limit;

  /// The next midnight UTC, when the searches come back.
  DateTime get resetsAt => DateTime.parse('${today}T00:00:00Z').add(const Duration(days: 1));

  static String utcDay(DateTime time) => time.toUtc().toIso8601String().substring(0, 10);

  SearchQuotaState copyWith({String? today, int? limit, String? day, int? count}) => SearchQuotaState(
        today: today ?? this.today,
        limit: limit ?? this.limit,
        day: day ?? this.day,
        count: count ?? this.count,
      );

  @override
  List<Object?> get props => [today, limit, day, count];
}
