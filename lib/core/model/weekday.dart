/// The seven cooking days. Persisted by [id] so the stored profile is
/// independent of the user's language.
enum Weekday {
  monday('monday'),
  tuesday('tuesday'),
  wednesday('wednesday'),
  thursday('thursday'),
  friday('friday'),
  saturday('saturday'),
  sunday('sunday');

  const Weekday(this.id);
  final String id;

  static Weekday fromId(String id) =>
      Weekday.values.firstWhere((d) => d.id == id, orElse: () => Weekday.monday);
}
