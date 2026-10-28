import 'dart:io';

import 'package:test/test.dart';
import 'package:visettings/visettings.dart';

void main() {
  group('VibrainiumSettings', () {
    late Directory tempRoot;

    setUp(() async {
      tempRoot = await Directory.systemTemp.createTemp('visettings_test_');
    });

    tearDown(() async {
      if (await tempRoot.exists()) {
        await tempRoot.delete(recursive: true);
      }
    });

    test('returns empty settings when .vibrainium/settings.json is missing', () async {
      final settings = await VibrainiumSettings.load(tempRoot.path);
      expect(settings.workspaceExclude, isEmpty);
      expect(
        settings.isWorkspaceExcluded('build', name: 'build', isDirectory: true),
        isFalse,
      );
    });

    test('loads workspace.exclude List<String> from .vibrainium/settings.json', () async {
      final dotDir = Directory('${tempRoot.path}/.vibrainium');
      await dotDir.create();
      final settingsFile = File('${dotDir.path}/settings.json');
      await settingsFile.writeAsString('''
{
  "workspace.exclude": [
    "build/",
    "*.g.dart",
    "lib/generated/**"
  ]
}
''');

      final settings = await VibrainiumSettings.load(tempRoot.path);
      expect(
        settings.workspaceExclude,
        ['build/', '*.g.dart', 'lib/generated/**'],
      );
      expect(
        settings.isWorkspaceExcluded('build', name: 'build', isDirectory: true),
        isTrue,
      );
      expect(
        settings.isWorkspaceExcluded('build', name: 'build', isDirectory: false),
        isFalse,
      );
      expect(
        settings.isWorkspaceExcluded('lib/user.g.dart', name: 'user.g.dart'),
        isTrue,
      );
      expect(
        settings.isWorkspaceExcluded('lib/user.dart', name: 'user.dart'),
        isFalse,
      );
      expect(
        settings.isWorkspaceExcluded(
          'lib/generated/api.dart',
          name: 'api.dart',
        ),
        isTrue,
      );
    });

    test('handles malformed JSON or non-list workspace.exclude gracefully', () async {
      final dotDir = Directory('${tempRoot.path}/.vibrainium');
      await dotDir.create();
      final settingsFile = File('${dotDir.path}/settings.json');

      await settingsFile.writeAsString('{ invalid json ');
      final malformed = await VibrainiumSettings.load(tempRoot.path);
      expect(malformed.workspaceExclude, isEmpty);

      await settingsFile.writeAsString('{"workspace.exclude": {"build": true}}');
      final nonList = VibrainiumSettings.loadSync(tempRoot.path);
      expect(nonList.workspaceExclude, isEmpty);

      await settingsFile.writeAsString('{"workspace.exclude": ["*.log", 123, "", true]}');
      final mixedList = await VibrainiumSettings.load(tempRoot.path);
      expect(mixedList.workspaceExclude, ['*.log']);
    });
  });
}
