/// Whether a surface is presented as a bottom sheet or a full page.
///
/// `pickerSurface` and `cropSurface` are configured independently, so an
/// avatar picker can be a lightweight sheet while a post composer is a page
/// (design §2.6).
enum PickerSurface {
  /// The `sheet` variant.
  sheet,

  /// The `page` variant.
  page,
}

/// The shape of the crop overlay. `circle` is the avatar case.
enum CropOverlayShape {
  /// The `rectangle` variant.
  rectangle,

  /// The `circle` variant.
  circle,
}

/// Identifies a [CropAspect] for the text delegate, so the label is
/// translatable instead of a hardcoded "1:1".
enum CropAspectLabel {
  /// The `square` variant.
  square,

  /// The `portrait` variant.
  portrait,

  /// The `landscape` variant.
  landscape,

  /// The `story` variant.
  story,

  /// The `banner` variant.
  banner,

  /// The `custom` variant.
  custom,
}
