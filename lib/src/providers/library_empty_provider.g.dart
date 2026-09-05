// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_empty_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the grid genuinely has nothing to show.
///
/// Deliberately not "the page is empty". Albums arrive asynchronously and the
/// first album is adopted on a microtask, so there is always a window where the
/// page is legitimately empty and the library is not — acting on the naive rule
/// flashes an empty state for a frame on every open.
///
/// Empty means: the album list has settled, **and** either there are no albums
/// at all, or the adopted album's first page came back with nothing in it.
///
/// It lives here rather than in the two body widgets so both empty states read
/// one definition and cannot drift apart (Flutter rule 6).

@ProviderFor(pickerLibraryEmpty)
final pickerLibraryEmptyProvider = PickerLibraryEmptyProvider._();

/// Whether the grid genuinely has nothing to show.
///
/// Deliberately not "the page is empty". Albums arrive asynchronously and the
/// first album is adopted on a microtask, so there is always a window where the
/// page is legitimately empty and the library is not — acting on the naive rule
/// flashes an empty state for a frame on every open.
///
/// Empty means: the album list has settled, **and** either there are no albums
/// at all, or the adopted album's first page came back with nothing in it.
///
/// It lives here rather than in the two body widgets so both empty states read
/// one definition and cannot drift apart (Flutter rule 6).

final class PickerLibraryEmptyProvider
    extends $FunctionalProvider<bool, bool, bool> with $Provider<bool> {
  /// Whether the grid genuinely has nothing to show.
  ///
  /// Deliberately not "the page is empty". Albums arrive asynchronously and the
  /// first album is adopted on a microtask, so there is always a window where the
  /// page is legitimately empty and the library is not — acting on the naive rule
  /// flashes an empty state for a frame on every open.
  ///
  /// Empty means: the album list has settled, **and** either there are no albums
  /// at all, or the adopted album's first page came back with nothing in it.
  ///
  /// It lives here rather than in the two body widgets so both empty states read
  /// one definition and cannot drift apart (Flutter rule 6).
  PickerLibraryEmptyProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'pickerLibraryEmptyProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$pickerLibraryEmptyHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return pickerLibraryEmpty(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$pickerLibraryEmptyHash() =>
    r'07e7724ecefcf54e61e8fa3f10fd3c289f56f941';
