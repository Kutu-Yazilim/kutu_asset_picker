import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/asset_picker_config.dart';
import '../providers/injection_providers.dart';
import 'cloud_progress_bar.dart';
import 'permission_gate.dart';
import 'picker_footer.dart';
import 'picker_image_cache_scope.dart';
import 'selected_strip.dart';

/// Everything below the app bar, in both surfaces.
///
/// The order is deliberate: gate, strip, cloud bar, footer. The cloud bar sits
/// directly above the control that triggers it, so the explanation for an inert
/// *Next* is the nearest thing to it on screen rather than a banner at the top
/// of a scrolled-away list.
///
/// [scrollController] is the sheet's controller in sheet mode and null in page
/// mode; it is threaded down to the grid untouched.
class PickerBody extends ConsumerWidget {
  const PickerBody({super.key, required this.onNext, this.scrollController});

  final VoidCallback onNext;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AssetPickerConfig config = ref.watch(assetPickerConfigProvider);

    return PickerImageCacheScope(
      thumbSize: config.thumbSize,
      child: Column(
        children: <Widget>[
          Expanded(child: PermissionGate(scrollController: scrollController)),
          const SelectedStrip(),
          const CloudProgressBar(),
          PickerFooter(onNext: onNext),
        ],
      ),
    );
  }
}
