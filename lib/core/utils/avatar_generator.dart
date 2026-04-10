// lib/core/utils/avatar_generator.dart
class AvatarGenerator {
  static const _styles = [
    'avataaars', 'bottts', 'fun-emoji', 'micah', 'adventurer', 'lorelei',
  ];

  static String generate({required String seed, String? style}) {
    final s = style ?? _styles[
      seed.codeUnits.reduce((a, b) => a + b) % _styles.length
    ];
    // Use a more reliable avatar service
    return 'https://api.dicebear.com/7.x/$s/png?seed=${Uri.encodeComponent(seed)}&size=200&backgroundColor=transparent';
  }
}