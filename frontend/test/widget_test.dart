import 'package:flutter_test/flutter_test.dart';

import 'package:lims_app/core/constants/app_constants.dart';

void main() {
  test('app identity is configured', () {
    expect(AppConstants.appShortName, 'LIMS');
    expect(AppConstants.appName, 'Livestock Insurance');
  });
}
