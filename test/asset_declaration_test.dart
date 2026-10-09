import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// lib 内の assets/... 文字列リテラル(補間なし)が実在し、pubspec の
/// 宣言ディレクトリ直下に含まれることを検証する(未宣言による黙った背景なし等の再発防止)。
void main() {
  // 既知の例外(実在/宣言チェックを除外するパス)。現在なし。
  const knownExceptions = <String>{};

  test('lib の assets リテラルが実在し pubspec で宣言されている', () {
    final pubspec = File('pubspec.yaml').readAsLinesSync();
    final declared = <String>{};
    var inAssets = false;
    for (final line in pubspec) {
      if (RegExp(r'^  assets:\s*$').hasMatch(line)) {
        inAssets = true;
        continue;
      }
      if (inAssets) {
        final m = RegExp(r'^    - (assets/\S*)\s*$').firstMatch(line);
        if (m != null) {
          declared.add(m.group(1)!);
        } else if (!RegExp(r'^\s*(#.*)?$').hasMatch(line)) {
          inAssets = false;
        }
      }
    }
    expect(declared, isNotEmpty);

    final literal = RegExp("['\"](assets/[^'\"\$]*)['\"]");
    final used = <String>{};
    for (final f in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      for (final m in literal.allMatches(f.readAsStringSync())) {
        used.add(m.group(1)!);
      }
    }
    expect(used, isNotEmpty);

    final problems = <String>[];
    for (final path in used) {
      if (knownExceptions.contains(path)) continue;
      if (!File(path).existsSync()) problems.add('missing file: $path');
      final dir = path.substring(0, path.lastIndexOf('/') + 1);
      if (!declared.contains(path) && !declared.contains(dir)) {
        problems.add('not declared in pubspec: $path');
      }
    }
    expect(problems, isEmpty);
  });
}
