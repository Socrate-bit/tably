/// Multi-select rules shared by onboarding and preferences, so both screens
/// behave identically.
abstract final class Selection {
  /// Adds [value] if absent, removes it if present.
  static Set<T> toggle<T>(Set<T> current, T value) {
    final next = Set<T>.from(current);
    next.contains(value) ? next.remove(value) : next.add(value);
    return next;
  }

  /// Like [toggle], but selecting beyond [max] is ignored.
  static Set<T> toggleCapped<T>(Set<T> current, T value, {required int max}) {
    if (!current.contains(value) && current.length >= max) return current;
    return toggle(current, value);
  }

  /// "None" is exclusive: picking it clears the rest, and clearing everything
  /// falls back to it.
  static Set<T> toggleWithNone<T>(Set<T> current, T value, T none) {
    if (value == none) return {none};
    final next = toggle(Set<T>.from(current)..remove(none), value);
    return next.isEmpty ? {none} : next;
  }

  /// Like [toggle], but the last remaining value cannot be removed.
  static Set<T> toggleKeepOne<T>(Set<T> current, T value) {
    final next = toggle(current, value);
    return next.isEmpty ? current : next;
  }
}
