// lib/core/utils/name_generator.dart
import 'dart:math';

class NameGenerator {
  static const _adj = [
    'Cosmic', 'Turbo', 'Neon', 'Fluffy', 'Mighty', 'Galactic',
    'Funky', 'Clever', 'Speedy', 'Brave', 'Zappy', 'Jolly',
  ];
  static const _animals = [
    'Panda', 'Raccoon', 'Koala', 'Penguin', 'Llama',
    'Axolotl', 'Capybara', 'Narwhal', 'Quokka', 'Platypus',
  ];

  static String random() {
    final rng = Random();
    final num = rng.nextInt(99) + 1;
    return '${_adj[rng.nextInt(_adj.length)]}${_animals[rng.nextInt(_animals.length)]}$num';
  }
}