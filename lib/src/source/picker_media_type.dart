/// The kinds of media this picker can browse.
///
/// Audio is out of scope (design §14) and `photo_manager`'s `AssetType.other`
/// is never surfaced.
enum PickerMediaType { image, video }
