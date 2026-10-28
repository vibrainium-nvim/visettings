import 'package:test/test.dart';
import 'package:visettings/visettings.dart';

void main() {
  group('WildcardPattern & WildcardMatcher', () {
    test('matches exact basename anywhere when pattern has no slash', () {
      final matcher = WildcardMatcher(['node_modules', 'pubspec.lock']);

      expect(
        matcher.matches('node_modules', name: 'node_modules', isDirectory: true),
        isTrue,
      );
      expect(
        matcher.matches(
          'packages/app/node_modules',
          name: 'node_modules',
          isDirectory: true,
        ),
        isTrue,
      );
      expect(
        matcher.matches('pubspec.lock', name: 'pubspec.lock'),
        isTrue,
      );
      expect(
        matcher.matches('sub/pubspec.lock', name: 'pubspec.lock'),
        isTrue,
      );
      expect(
        matcher.matches('pubspec.yaml', name: 'pubspec.yaml'),
        isFalse,
      );
    });

    test('supports single asterisk (*) and question mark (?) wildcards', () {
      final matcher = WildcardMatcher(['*.g.dart', 'temp_?.txt']);

      expect(
        matcher.matches('lib/models/user.g.dart', name: 'user.g.dart'),
        isTrue,
      );
      expect(
        matcher.matches('user.g.dart', name: 'user.g.dart'),
        isTrue,
      );
      expect(
        matcher.matches('lib/models/user.dart', name: 'user.dart'),
        isFalse,
      );
      expect(
        matcher.matches('logs/temp_1.txt', name: 'temp_1.txt'),
        isTrue,
      );
      expect(
        matcher.matches('logs/temp_12.txt', name: 'temp_12.txt'),
        isFalse,
      );
    });

    test('supports trailing slash for directory-only patterns', () {
      final matcher = WildcardMatcher(['build/', 'dist/']);

      expect(
        matcher.matches('build', name: 'build', isDirectory: true),
        isTrue,
      );
      expect(
        matcher.matches('packages/a/build', name: 'build', isDirectory: true),
        isTrue,
      );
      // File named `build` should not match `build/`
      expect(
        matcher.matches('build', name: 'build', isDirectory: false),
        isFalse,
      );
    });

    test('supports double asterisk (**) for multi-segment path matching', () {
      final matcher = WildcardMatcher([
        '**/generated/**',
        'ios/Pods/**',
        'lib/**/internal/*.dart',
      ]);

      expect(
        matcher.matches('generated', name: 'generated', isDirectory: true),
        isTrue,
      );
      expect(
        matcher.matches(
          'lib/src/generated',
          name: 'generated',
          isDirectory: true,
        ),
        isTrue,
      );
      expect(
        matcher.matches(
          'lib/src/generated/a/b.dart',
          name: 'b.dart',
        ),
        isTrue,
      );
      expect(
        matcher.matches('ios/Pods', name: 'Pods', isDirectory: true),
        isTrue,
      );
      expect(
        matcher.matches('ios/Pods/Podfile', name: 'Podfile'),
        isTrue,
      );
      expect(
        matcher.matches('android/Pods', name: 'Pods', isDirectory: true),
        isFalse,
      );
      expect(
        matcher.matches('lib/internal/secret.dart', name: 'secret.dart'),
        isTrue,
      );
      expect(
        matcher.matches('lib/a/b/internal/secret.dart', name: 'secret.dart'),
        isTrue,
      );
      expect(
        matcher.matches('lib/a/b/internal/sub/secret.dart', name: 'secret.dart'),
        isFalse,
      );
    });

    test('anchors to workspace root when pattern starts with / or ./', () {
      final matcher = WildcardMatcher(['/build', './dist']);

      expect(
        matcher.matches('build', name: 'build', isDirectory: true),
        isTrue,
      );
      expect(
        matcher.matches('sub/build', name: 'build', isDirectory: true),
        isFalse,
      );
      expect(
        matcher.matches('dist', name: 'dist', isDirectory: true),
        isTrue,
      );
      expect(
        matcher.matches('sub/dist', name: 'dist', isDirectory: true),
        isFalse,
      );
    });
  });
}
