/// Converts a `ReorderableListView` `newIndex` into a plain list index.
///
/// `ReorderableListView` reports the destination in the coordinate space
/// *before* the dragged item is removed, so every downward move arrives one too
/// high. `Selection.reorder` takes plain remove-then-insert indices, so the
/// adjustment happens here — once, in a tested function, rather than inline in
/// a callback where it is invisible.
int normalizedReorderTarget(int oldIndex, int newIndex) =>
    newIndex > oldIndex ? newIndex - 1 : newIndex;
