import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/library_empty_provider.dart';
import 'asset_grid.dart';
import 'empty_library_view.dart';

/// Full access: the grid, or the genuinely-empty state.
///
/// The mirror image of `LimitedAccessBody`, minus the bar — same grid, same
/// controller handoff, different empty state.
class FullAccessBody extends ConsumerWidget {
  /// Creates a [FullAccessBody].
  const FullAccessBody({super.key, this.scrollController});

  /// The scroll controller.
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(pickerLibraryEmptyProvider)
          ? const EmptyLibraryView()
          : AssetGrid(scrollController: scrollController);
}
