import 'package:flutter_test/flutter_test.dart';
import 'package:war_card_game/game/achievement.dart';

void main() {
  group('kAchievementMeta', () {
    test('every Achievement enum value has metadata', () {
      for (final a in Achievement.values) {
        expect(
          kAchievementMeta.containsKey(a),
          true,
          reason: '${a.name} missing from kAchievementMeta',
        );
      }
    });

    test('no extra keys beyond the enum values', () {
      expect(kAchievementMeta.length, Achievement.values.length);
    });

    test('every entry has non-empty title, description, and emoji', () {
      for (final entry in kAchievementMeta.entries) {
        final meta = entry.value;
        expect(meta.title.isNotEmpty, true,
            reason: '${entry.key.name} has empty title');
        expect(meta.description.isNotEmpty, true,
            reason: '${entry.key.name} has empty description');
        expect(meta.emoji.isNotEmpty, true,
            reason: '${entry.key.name} has empty emoji');
      }
    });

    test('all titles are unique', () {
      final titles = kAchievementMeta.values.map((m) => m.title).toList();
      expect(titles.toSet().length, titles.length);
    });
  });

  group('AchievementMeta', () {
    test('const constructor stores values correctly', () {
      const meta = AchievementMeta(
        title: 'Test',
        description: 'A test achievement',
        emoji: '🎯',
      );
      expect(meta.title, 'Test');
      expect(meta.description, 'A test achievement');
      expect(meta.emoji, '🎯');
    });
  });
}
