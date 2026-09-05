import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/picker_tuning.dart';
import '../text/asset_picker_text.dart';
import '../text/asset_picker_text_provider.dart';
import '../theme/asset_picker_theme.dart';
import '../theme/resolved_asset_picker_theme.dart';

/// The empty state under **full** access, where the library really is empty.
///
/// This is the only empty state allowed to assert emptiness, because it is the
/// only one where emptiness is a fact: full access means the app can see
/// everything, so seeing nothing means there is nothing. Its limited-access
/// counterpart is `LimitedEmptyView` and the two are deliberately separate
/// screens with separate strings (design §4.2).
///
/// The reference above is a backticked name rather than a doc link on purpose:
/// importing `limited_empty_view.dart` here just to resolve a `[]` would be an
/// unused import, and this package's analysis options treat those as errors.
class EmptyLibraryView extends ConsumerWidget {
  const EmptyLibraryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ResolvedAssetPickerTheme theme = AssetPickerTheme.resolve(context);
    final AssetPickerText text = ref.watch(assetPickerTextProvider);

    return Padding(
      padding: PickerChromeSizes.statePadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.photo_outlined,
            size: PickerChromeSizes.stateIconSize,
            color: theme.onSurfaceMuted,
          ),
          const SizedBox(height: PickerChromeSizes.stateSpacing),
          Text(
            text.pickerEmptyLibrary,
            textAlign: TextAlign.center,
            style: theme.labelStyle.copyWith(color: theme.onSurfaceMuted),
          ),
        ],
      ),
    );
  }
}
