import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/models/workout_split_templates.dart';

void main() {
  test('provides four usable workout templates', () {
    expect(workoutSplitTemplates, hasLength(4));
    for (final template in workoutSplitTemplates) {
      expect(template.title, isNotEmpty);
      expect(template.days, isNotEmpty);
      expect(template.createDays().length, template.days.length);
      expect(
        template.createDays().every((day) => day.exercises.isEmpty),
        isTrue,
      );
    }
  });
}
