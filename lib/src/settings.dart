import 'dart:convert';
import 'dart:io';

import 'wildcard.dart';

/// Represents workspace settings loaded from `.vibrainium/settings.json`.
class VibrainiumSettings {
  static const String dirName = '.vibrainium';
  static const String fileName = 'settings.json';
  static const String workspaceExcludeKey = 'workspace.exclude';

  final List<String> workspaceExclude;
  final WildcardMatcher _excludeMatcher;

  const VibrainiumSettings({
    this.workspaceExclude = const [],
  }) : _excludeMatcher = const WildcardMatcher.empty();

  VibrainiumSettings._({
    required this.workspaceExclude,
    required WildcardMatcher excludeMatcher,
  }) : _excludeMatcher = excludeMatcher;

  factory VibrainiumSettings.fromExcludeList(List<String> patterns) {
    final cleaned = List<String>.unmodifiable(
      patterns.map((e) => e.trim()).where((e) => e.isNotEmpty),
    );
    return VibrainiumSettings._(
      workspaceExclude: cleaned,
      excludeMatcher: WildcardMatcher(cleaned),
    );
  }

  /// Parses [VibrainiumSettings] from a decoded JSON object map.
  factory VibrainiumSettings.fromJson(Map<String, Object?> json) {
    final rawExclude = json[workspaceExcludeKey];
    if (rawExclude is List) {
      final patterns = <String>[];
      for (final item in rawExclude) {
        if (item is String) {
          final trimmed = item.trim();
          if (trimmed.isNotEmpty) {
            patterns.add(trimmed);
          }
        }
      }
      return VibrainiumSettings.fromExcludeList(patterns);
    }
    return const VibrainiumSettings();
  }

  /// Returns the path `<workspaceRoot>/.vibrainium/settings.json`.
  static String settingsFilePath(String workspaceRoot) {
    var clean = workspaceRoot.replaceAll(r'\', '/');
    while (clean.endsWith('/') && clean.length > 1) {
      clean = clean.substring(0, clean.length - 1);
    }
    return '$clean/$dirName/$fileName';
  }

  /// Asynchronously loads `.vibrainium/settings.json` from [workspaceRoot].
  /// Returns empty [VibrainiumSettings] if the file does not exist or is invalid.
  static Future<VibrainiumSettings> load(String workspaceRoot) async {
    final file = File(settingsFilePath(workspaceRoot));
    if (!await file.exists()) {
      return const VibrainiumSettings();
    }
    try {
      final content = await file.readAsString();
      return parseJsonString(content);
    } catch (_) {
      return const VibrainiumSettings();
    }
  }

  /// Synchronously loads `.vibrainium/settings.json` from [workspaceRoot].
  /// Returns empty [VibrainiumSettings] if the file does not exist or is invalid.
  static VibrainiumSettings loadSync(String workspaceRoot) {
    final file = File(settingsFilePath(workspaceRoot));
    if (!file.existsSync()) {
      return const VibrainiumSettings();
    }
    try {
      final content = file.readAsStringSync();
      return parseJsonString(content);
    } catch (_) {
      return const VibrainiumSettings();
    }
  }

  /// Parses a JSON string into [VibrainiumSettings], returning empty settings
  /// if the string is not a valid JSON object.
  static VibrainiumSettings parseJsonString(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is Map<String, Object?>) {
        return VibrainiumSettings.fromJson(decoded);
      }
      if (decoded is Map) {
        return VibrainiumSettings.fromJson(
          decoded.map((k, v) => MapEntry(k.toString(), v)),
        );
      }
    } catch (_) {
      // Ignore malformed JSON and return default settings.
    }
    return const VibrainiumSettings();
  }

  /// Checks whether a file or directory at [relativePath] (relative to the
  /// workspace root) with basename [name] matches any pattern in `workspace.exclude`.
  bool isWorkspaceExcluded(
    String relativePath, {
    required String name,
    bool isDirectory = false,
  }) {
    if (_excludeMatcher.isEmpty) {
      return false;
    }
    return _excludeMatcher.matches(
      relativePath,
      name: name,
      isDirectory: isDirectory,
    );
  }
}
