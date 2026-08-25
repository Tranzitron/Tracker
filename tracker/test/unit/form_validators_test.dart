import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/pages/custom/form_validators.dart';

void main() {
  test('requiredText accepts content and rejects blank values', () {
    expect(requiredText(' value '), isNull);
    expect(requiredText(null), 'Cannot be empty');
    expect(requiredText('  '), 'Cannot be empty');
  });

  test('requiredDouble requires a positive number', () {
    expect(requiredDouble('1.5'), isNull);
    expect(requiredDouble(null), 'Must be greater than 0');
    expect(requiredDouble('0'), 'Must be greater than 0');
    expect(requiredDouble('-1'), 'Must be greater than 0');
    expect(requiredDouble('abc'), 'Must be greater than 0');
  });
}
