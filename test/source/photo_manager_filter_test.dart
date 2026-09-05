import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/src/source/photo_manager_filter.dart';
import 'package:photo_manager/photo_manager.dart';

void main() {
  test('a null video duration survives the query filter', () {
    // design §4.5: the DEFAULT for DurationConstraint.allowNullable is FALSE,
    // and that default silently hides every asset whose MediaStore duration
    // column is null — a real set of files on Android from some downloads and
    // third-party recorders. They simply never appear in the grid, with no
    // error anywhere.
    //
    // If you are reading this because the test went red: someone dropped
    // `allowNullable: true`. Those videos are now invisible.
    final FilterOptionGroup group =
        buildPickerFilter(maxVideoDuration: const Duration(seconds: 60));

    expect(
      group.getOption(AssetType.video).durationConstraint.allowNullable,
      isTrue,
    );
  });

  test('the configured max duration reaches the video constraint', () {
    final FilterOptionGroup group =
        buildPickerFilter(maxVideoDuration: const Duration(seconds: 60));

    expect(
      group.getOption(AssetType.video).durationConstraint.max,
      const Duration(seconds: 60),
    );
    expect(
      group.getOption(AssetType.video).durationConstraint.min,
      Duration.zero,
    );
  });

  test('an unset max duration does not filter videos out', () {
    final FilterOptionGroup group = buildPickerFilter();

    expect(
      group.getOption(AssetType.video).durationConstraint.max,
      PickerFilterDefaults.maxVideoDuration,
    );
    expect(
      group.getOption(AssetType.video).durationConstraint.allowNullable,
      isTrue,
    );
  });

  test('images are not duration-filtered', () {
    // Images report a zero/absent duration. A max constraint on the image
    // option would be at best meaningless and at worst exclusionary.
    final FilterOptionGroup group =
        buildPickerFilter(maxVideoDuration: const Duration(seconds: 1));

    expect(
      group.getOption(AssetType.image).durationConstraint.allowNullable,
      isTrue,
    );
  });

  test('the creation-time condition is ignored', () {
    // FilterOptionGroup defaults createTimeCond to DateTimeCond.def(), whose
    // `max` is DateTime.now() AT CONSTRUCTION. That timestamp goes stale the
    // instant it is built, so an asset captured through the camera tile a few
    // seconds later is silently filtered out of the very grid that is supposed
    // to show it.
    final FilterOptionGroup group = buildPickerFilter();

    expect(group.createTimeCond.ignore, isTrue);
  });

  test('results are ordered newest first', () {
    final FilterOptionGroup group = buildPickerFilter();

    expect(group.orders, hasLength(1));
    expect(group.orders.single.type, OrderOptionType.createDate);
    expect(group.orders.single.asc, isFalse);
  });

  test('size is not constrained', () {
    // SizeConstraint defaults to a 100000px ceiling rather than "no limit".
    // Nothing in this picker wants to hide an asset for being large; the
    // decode-time megapixel cap in the export path is the real control.
    final FilterOptionGroup group = buildPickerFilter();

    expect(group.getOption(AssetType.image).sizeConstraint.ignoreSize, isTrue);
    expect(group.getOption(AssetType.video).sizeConstraint.ignoreSize, isTrue);
  });
}
