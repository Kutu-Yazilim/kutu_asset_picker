import '../source/picker_asset.dart';
import '../source/picker_media_type.dart';

/// Reaches the OS camera on the picker's behalf.
///
/// The camera is a cell in the grid that delegates to the system camera
/// (design §2.8) — a fully in-package camera was rejected as a second large
/// subsystem. Reaching the system camera needs a plugin, and this package
/// ships none, so the choice of plugin belongs to the app.
///
/// Return the captured asset if you saved it into the device library (for
/// example with `PhotoManager.editor.saveImage`, which returns an
/// `AssetEntity`); the picker prepends it to the grid and selects it. Return
/// null if the user cancelled, or if the capture already landed in the library
/// — `AssetSource.changes` re-pages the grid either way, it just will not be
/// auto-selected.
///
/// Do not use `photo_manager`'s latitude/longitude save APIs: an unreleased
/// commit removes CoreLocation, which will make `saveImage(latitude:)` throw
/// (design §13).
abstract interface class PickerCameraDelegate {
  Future<PickerAsset?> capture(Set<PickerMediaType> kinds);
}
