import '../source/picker_media_type.dart';
import 'captured_media.dart';

/// Reaches the OS camera on the picker's behalf.
///
/// The camera is a cell in the grid that delegates to the system camera
/// (design §2.8) — a fully in-package camera was rejected as a second large
/// subsystem. Reaching the system camera needs a plugin, and this package
/// ships none, so the choice of plugin belongs to the app.
abstract interface class PickerCameraDelegate {
  /// Runs the OS camera for one of [kinds] and returns what it wrote.
  ///
  /// Return null when the user backed out.
  ///
  /// **Do not save into the device library.** The picker does that behind
  /// `AssetSource.saveToLibrary`, so `photo_manager` and `AssetEntity` stay
  /// inside the source layer (design §4.1) and a host needs no photo-library
  /// dependency of its own.
  ///
  /// [kinds] is what the surface accepts. A plugin that can only capture one
  /// kind per call narrows the set itself — how a host asks its user to
  /// choose is the host's business, not the picker's.
  Future<CapturedMedia?> capture(Set<PickerMediaType> kinds);
}
