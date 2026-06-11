import 'package:flutter_test/flutter_test.dart';
import 'package:swarnbook/l10n/app_localizations_en.dart';

void main() {
  test('English localization exposes the SwarnaLekh app title', () {
    expect(AppLocalizationsEn().appTitle, 'SwarnaLekh');
    expect(AppLocalizationsEn().navMortgage, 'Mortgage');
  });
}
