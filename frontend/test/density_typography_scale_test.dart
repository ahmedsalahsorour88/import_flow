import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/density_provider.dart';

void main() {
  group('Typography Scale per Density Level (Design System Addition)', () {
    test('Comfortable density typography tokens match exact specifications', () {
      const mode = DisplayDensityMode.comfortable;
      expect(mode.headerTitleFontSize, equals(20.0));
      expect(mode.headerSubtitleFontSize, equals(13.0));
      expect(mode.metricTitleFontSize, equals(14.0));
      expect(mode.metricValueFontSize, equals(14.0));
      expect(mode.buttonFontSize, equals(13.0));
      expect(mode.tableHeaderFontSize, equals(13.0));
      expect(mode.tableCellPrimaryFontSize, equals(14.0));
      expect(mode.tableCellSecondaryFontSize, equals(12.0));
      expect(mode.inputFontSize, equals(13.0));
      expect(mode.sidebarNavFontSize, equals(13.0));
    });

    test('Compact density typography tokens match exact specifications', () {
      const mode = DisplayDensityMode.compact;
      expect(mode.headerTitleFontSize, equals(17.0));
      expect(mode.headerSubtitleFontSize, equals(12.0));
      expect(mode.metricTitleFontSize, equals(13.0));
      expect(mode.metricValueFontSize, equals(13.0));
      expect(mode.buttonFontSize, equals(12.0));
      expect(mode.tableHeaderFontSize, equals(12.0));
      expect(mode.tableCellPrimaryFontSize, equals(13.0));
      expect(mode.tableCellSecondaryFontSize, equals(11.0));
      expect(mode.inputFontSize, equals(12.0));
      expect(mode.sidebarNavFontSize, equals(13.0));
    });

    test('Ultra-Compact density typography tokens match exact specifications', () {
      const mode = DisplayDensityMode.ultraCompact;
      expect(mode.headerTitleFontSize, equals(15.0));
      expect(mode.headerSubtitleFontSize, equals(11.0));
      expect(mode.metricTitleFontSize, equals(12.0));
      expect(mode.metricValueFontSize, equals(12.0));
      expect(mode.buttonFontSize, equals(12.0));
      expect(mode.tableHeaderFontSize, equals(12.0));
      expect(mode.tableCellPrimaryFontSize, equals(12.0));
      expect(mode.tableCellSecondaryFontSize, equals(11.0));
      expect(mode.inputFontSize, equals(12.0));
      expect(mode.sidebarNavFontSize, equals(12.0));
    });

    test('Conservative icon scaling per density level', () {
      expect(DisplayDensityMode.comfortable.headerIconSize, equals(22.0));
      expect(DisplayDensityMode.compact.headerIconSize, equals(20.0));
      expect(DisplayDensityMode.ultraCompact.headerIconSize, equals(18.0));

      expect(DisplayDensityMode.comfortable.metricIconSize, equals(17.0));
      expect(DisplayDensityMode.compact.metricIconSize, equals(15.5));
      expect(DisplayDensityMode.ultraCompact.metricIconSize, equals(14.0));

      expect(DisplayDensityMode.comfortable.buttonIconSize, equals(16.0));
      expect(DisplayDensityMode.compact.buttonIconSize, equals(15.0));
      expect(DisplayDensityMode.ultraCompact.buttonIconSize, equals(14.0));
    });

    test('Strict 11px floor rule: no token is below 11px across all density modes', () {
      for (final mode in DisplayDensityMode.values) {
        expect(mode.headerTitleFontSize, greaterThanOrEqualTo(11.0));
        expect(mode.headerSubtitleFontSize, greaterThanOrEqualTo(11.0));
        expect(mode.metricTitleFontSize, greaterThanOrEqualTo(11.0));
        expect(mode.metricValueFontSize, greaterThanOrEqualTo(11.0));
        expect(mode.buttonFontSize, greaterThanOrEqualTo(11.0));
        expect(mode.tableHeaderFontSize, greaterThanOrEqualTo(11.0));
        expect(mode.tableCellPrimaryFontSize, greaterThanOrEqualTo(11.0));
        expect(mode.tableCellSecondaryFontSize, greaterThanOrEqualTo(11.0));
        expect(mode.inputFontSize, greaterThanOrEqualTo(11.0));
        expect(mode.sidebarNavFontSize, greaterThanOrEqualTo(11.0));
      }

      // Test clamping utility function
      expect(DisplayDensityMode.clampFontSize(8.5), equals(11.0));
      expect(DisplayDensityMode.clampFontSize(9.5), equals(11.0));
      expect(DisplayDensityMode.clampFontSize(10.0), equals(11.0));
      expect(DisplayDensityMode.clampFontSize(10.5), equals(11.0));
      expect(DisplayDensityMode.clampFontSize(11.0), equals(11.0));
      expect(DisplayDensityMode.clampFontSize(14.0), equals(14.0));
    });

    test('Visual hierarchy is preserved (Scale, Don\'t Flatten)', () {
      for (final mode in DisplayDensityMode.values) {
        // Page title is strictly larger than table cells and secondary text
        expect(mode.headerTitleFontSize, greaterThan(mode.tableCellPrimaryFontSize));
        expect(mode.headerTitleFontSize, greaterThan(mode.tableCellSecondaryFontSize));
        expect(mode.headerTitleFontSize, greaterThan(mode.headerSubtitleFontSize));

        // Primary table cell is greater than or equal to secondary table cell
        expect(mode.tableCellPrimaryFontSize, greaterThanOrEqualTo(mode.tableCellSecondaryFontSize));
      }
    });

    test('Top Block dimensions (Header + Strip + Toolbar) match density targets', () {
      // Metric Strip heights
      expect(DisplayDensityMode.comfortable.metricCardHeight, equals(42.0));
      expect(DisplayDensityMode.compact.metricCardHeight, equals(34.0));
      expect(DisplayDensityMode.ultraCompact.metricCardHeight, equals(28.0));

      // Toolbar heights
      expect(DisplayDensityMode.comfortable.toolbarHeight, equals(40.0));
      expect(DisplayDensityMode.compact.toolbarHeight, equals(36.0));
      expect(DisplayDensityMode.ultraCompact.toolbarHeight, equals(30.0));
    });
  });
}
