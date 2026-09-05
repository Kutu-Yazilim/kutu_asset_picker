/// The three library-access states, all of which are designed screens.
///
/// Android 14+ partial access and iOS `limited` both map to [limited], which
/// renders the same grid over the granted subset plus a permanent
/// *Manage selection* bar (design §2.10, §4.2).
enum PickerPermission {
  /// The `full` variant.
  full,

  /// The `limited` variant.
  limited,

  /// The `denied` variant.
  denied;

  /// Whether the library can be read at all.
  ///
  /// Branching on this — rather than on "is it fully authorized" — is what
  /// keeps limited users out of an empty grid.
  bool get hasAccess => this == full || this == limited;
}
