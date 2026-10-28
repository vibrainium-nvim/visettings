/// Compiles and evaluates wildcard/glob patterns (supporting `*`, `**`, `?`,
/// and trailing `/` for directory-only matching).
class WildcardPattern {
  final String rawPattern;
  final bool directoryOnly;
  final bool matchBasename;
  final RegExp _regex;

  WildcardPattern._({
    required this.rawPattern,
    required this.directoryOnly,
    required this.matchBasename,
    required RegExp regex,
  }) : _regex = regex;

  factory WildcardPattern(String rawPattern) {
    var pattern = rawPattern.trim().replaceAll(r'\', '/');
    var directoryOnly = false;

    if (pattern.endsWith('/') && pattern.length > 1) {
      directoryOnly = true;
      while (pattern.endsWith('/') && pattern.length > 1) {
        pattern = pattern.substring(0, pattern.length - 1);
      }
    }

    var anchoredToRoot = false;
    if (pattern.startsWith('./')) {
      anchoredToRoot = true;
      pattern = pattern.substring(2);
    } else if (pattern.startsWith('/')) {
      anchoredToRoot = true;
      while (pattern.startsWith('/')) {
        pattern = pattern.substring(1);
      }
    }

    final hasSlash = anchoredToRoot || pattern.contains('/');
    final matchBasename = !hasSlash;

    final regexSource = _globToRegex(pattern);
    return WildcardPattern._(
      rawPattern: rawPattern,
      directoryOnly: directoryOnly,
      matchBasename: matchBasename,
      regex: RegExp('^$regexSource\$'),
    );
  }

  /// Returns `true` if this pattern matches an entry with workspace-relative
  /// [relativePath] (normalized with `/`) and basename [name].
  bool matches(
    String relativePath, {
    required String name,
    bool isDirectory = false,
  }) {
    if (directoryOnly && !isDirectory) {
      return false;
    }

    var normRel = relativePath.replaceAll(r'\', '/');
    while (normRel.startsWith('./')) {
      normRel = normRel.substring(2);
    }
    while (normRel.startsWith('/')) {
      normRel = normRel.substring(1);
    }
    while (normRel.endsWith('/') && normRel.length > 1) {
      normRel = normRel.substring(0, normRel.length - 1);
    }

    if (matchBasename) {
      if (_regex.hasMatch(name)) {
        return true;
      }
    }
    return _regex.hasMatch(normRel);
  }

  static String _globToRegex(String pattern) {
    final buf = StringBuffer();
    var i = 0;
    final len = pattern.length;

    while (i < len) {
      if (pattern.startsWith('**/', i)) {
        buf.write('(?:.+/)?');
        i += 3;
        while (i < len && pattern[i] == '/') {
          i++;
        }
        continue;
      }
      if (pattern.startsWith('/**', i) && i + 3 == len) {
        buf.write('(?:/.*)?');
        i += 3;
        continue;
      }
      if (pattern.startsWith('**', i)) {
        buf.write('.*');
        i += 2;
        continue;
      }

      final ch = pattern[i];
      switch (ch) {
        case '*':
          buf.write('[^/]*');
        case '?':
          buf.write('[^/]');
        case '.':
        case '+':
        case '^':
        case r'$':
        case '(':
        case ')':
        case '[':
        case ']':
        case '{':
        case '}':
        case '|':
        case r'\':
          buf.write(r'\');
          buf.write(ch);
        default:
          buf.write(ch);
      }
      i++;
    }

    return buf.toString();
  }
}

/// Evaluates a list of wildcard patterns against workspace paths.
class WildcardMatcher {
  final List<WildcardPattern> patterns;

  const WildcardMatcher.empty() : patterns = const [];

  factory WildcardMatcher(Iterable<String> rawPatterns) {
    final compiled = <WildcardPattern>[];
    for (final raw in rawPatterns) {
      final trimmed = raw.trim();
      if (trimmed.isNotEmpty) {
        compiled.add(WildcardPattern(trimmed));
      }
    }
    return WildcardMatcher._(List.unmodifiable(compiled));
  }

  const WildcardMatcher._(this.patterns);

  bool get isEmpty => patterns.isEmpty;

  bool matches(
    String relativePath, {
    required String name,
    bool isDirectory = false,
  }) {
    for (final p in patterns) {
      if (p.matches(relativePath, name: name, isDirectory: isDirectory)) {
        return true;
      }
    }
    return false;
  }
}
