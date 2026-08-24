import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/localization/app_localizations.dart';
import 'package:frontend/core/localization/app_localizations_ar.dart';
import 'package:frontend/core/localization/app_localizations_en.dart';

void main() {
  group('Screen 37: Ports & Transport Locations Localization Tests', () {
    const AppLocalizations ar = AppLocalizationsAr();
    const AppLocalizations en = AppLocalizationsEn();

    test('All Screen 37 getters should have non-empty Arabic and English translations', () {
      final List<String> arStrings = [
        ar.transportLocationsScreenTitle,
        ar.transportLocationsScreenSubtitle,
        ar.addTransportLocationBtn,
        ar.locationTypeAll,
        ar.locationTypeSeaPort,
        ar.locationTypeAirport,
        ar.locationTypeDryPort,
        ar.locationTypeLandBorder,
        ar.locationTypeIcd,
        ar.locationTypeRailTerminal,
        ar.searchTransportLocationsHint,
        ar.locationsFetchError('Connection timeout'),
        ar.noTransportLocationsFound,
        ar.unLocodeCol,
        ar.locationNameCol,
        ar.locationTypeCol,
        ar.countryCol,
        ar.cityCol,
        ar.statusCol,
        ar.actionsCol,
        ar.printLocationSnack('Alexandria Port', 'EGALY'),
        ar.confirmDeactivateLocation('Alexandria Port'),
        ar.confirmActivateLocation('Alexandria Port'),
        ar.deactivateLocationTooltip,
        ar.activateLocationTooltip,
        ar.showingLocationsCount(1, 50, 150, 'Sea Port'),
        ar.addLocationDialogTitle,
        ar.editLocationDialogTitle('EGALY'),
        ar.unLocodeLabel,
        ar.unLocodeHint,
        ar.locationTypeLabel,
        ar.locationNameLabel,
        ar.locationNameHint,
        ar.countryLabelRequired,
        ar.countryHint,
        ar.cityLabelRequired,
        ar.cityHint,
        ar.locationNotesLabel,
        ar.createLocationSubmitBtn,
        ar.importingLocationsDataset,
        ar.importWarningsTitle,
        ar.locationsImportSuccess,
      ];

      final List<String> enStrings = [
        en.transportLocationsScreenTitle,
        en.transportLocationsScreenSubtitle,
        en.addTransportLocationBtn,
        en.locationTypeAll,
        en.locationTypeSeaPort,
        en.locationTypeAirport,
        en.locationTypeDryPort,
        en.locationTypeLandBorder,
        en.locationTypeIcd,
        en.locationTypeRailTerminal,
        en.searchTransportLocationsHint,
        en.locationsFetchError('Connection timeout'),
        en.noTransportLocationsFound,
        en.unLocodeCol,
        en.locationNameCol,
        en.locationTypeCol,
        en.countryCol,
        en.cityCol,
        en.statusCol,
        en.actionsCol,
        en.printLocationSnack('Alexandria Port', 'EGALY'),
        en.confirmDeactivateLocation('Alexandria Port'),
        en.confirmActivateLocation('Alexandria Port'),
        en.deactivateLocationTooltip,
        en.activateLocationTooltip,
        en.showingLocationsCount(1, 50, 150, 'Sea Port'),
        en.addLocationDialogTitle,
        en.editLocationDialogTitle('EGALY'),
        en.unLocodeLabel,
        en.unLocodeHint,
        en.locationTypeLabel,
        en.locationNameLabel,
        en.locationNameHint,
        en.countryLabelRequired,
        en.countryHint,
        en.cityLabelRequired,
        en.cityHint,
        en.locationNotesLabel,
        en.createLocationSubmitBtn,
        en.importingLocationsDataset,
        en.importWarningsTitle,
        en.locationsImportSuccess,
      ];

      expect(arStrings.length, enStrings.length);
      for (int i = 0; i < arStrings.length; i++) {
        expect(arStrings[i].trim().isNotEmpty, isTrue, reason: 'Arabic string at index $i is empty');
        expect(enStrings[i].trim().isNotEmpty, isTrue, reason: 'English string at index $i is empty');
      }
    });

    test('Verify pure Arabic translations without stacked or Latin characters in static keys', () {
      final List<String> arStaticStrings = [
        ar.transportLocationsScreenTitle,
        ar.transportLocationsScreenSubtitle,
        ar.addTransportLocationBtn,
        ar.locationTypeAll,
        ar.locationTypeSeaPort,
        ar.locationTypeAirport,
        ar.locationTypeDryPort,
        ar.locationTypeLandBorder,
        ar.locationTypeIcd,
        ar.locationTypeRailTerminal,
        ar.searchTransportLocationsHint,
        ar.noTransportLocationsFound,
        ar.unLocodeCol,
        ar.locationNameCol,
        ar.locationTypeCol,
        ar.countryCol,
        ar.cityCol,
        ar.statusCol,
        ar.actionsCol,
        ar.deactivateLocationTooltip,
        ar.activateLocationTooltip,
        ar.addLocationDialogTitle,
        ar.unLocodeLabel,
        ar.locationTypeLabel,
        ar.locationNameLabel,
        ar.locationNameHint,
        ar.countryLabelRequired,
        ar.countryHint,
        ar.cityLabelRequired,
        ar.cityHint,
        ar.locationNotesLabel,
        ar.createLocationSubmitBtn,
        ar.importingLocationsDataset,
        ar.importWarningsTitle,
        ar.locationsImportSuccess,
      ];

      for (final s in arStaticStrings) {
        expect(RegExp(r'[a-zA-Z]').hasMatch(s), isFalse, reason: 'Arabic string contains Latin characters: $s');
      }
    });
  });
}
