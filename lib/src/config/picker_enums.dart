/// Whether a surface is presented as a bottom sheet or a full page.
///
/// `pickerSurface` and `cropSurface` are configured independently, so an
/// avatar picker can be a lightweight sheet while a post composer is a page
/// (design §2.6).
enum PickerSurface { sheet, page }

/// The shape of the crop overlay. `circle` is the avatar case.
enum CropOverlayShape { rectangle, circle }

/// Identifies a [CropAspect] for the text delegate, so the label is
/// translatable instead of a hardcoded "1:1".
enum CropAspectLabel { square, portrait, landscape, story, banner, custom }
