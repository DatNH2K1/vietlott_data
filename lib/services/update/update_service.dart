import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vietlott_data/config.dart';
import 'package:vietlott_data/services/localization/app_localizations.dart';

/// A class representing the release information fetched from GitHub.
class GitHubRelease {
  GitHubRelease({
    required this.version,
    required this.releaseUrl,
    required this.body,
    this.apkDownloadUrl,
  });

  factory GitHubRelease.fromJson(Map<String, dynamic> json) {
    final tagName = json['tag_name'] as String? ?? '0.0.0';
    // Strip leading 'v' or 'V' if present
    final cleanVersion = tagName.startsWith(RegExp('[vV]'))
        ? tagName.substring(1)
        : tagName;

    final htmlUrl = json['html_url'] as String? ?? '';

    // Find the first asset ending with .apk
    String? directApkUrl;
    final assets = json['assets'] as List<dynamic>?;
    if (assets != null) {
      for (final asset in assets) {
        if (asset is Map<String, dynamic>) {
          final name = asset['name'] as String? ?? '';
          if (name.toLowerCase().endsWith('.apk')) {
            directApkUrl = asset['browser_download_url'] as String?;
            break;
          }
        }
      }
    }

    return GitHubRelease(
      version: cleanVersion,
      releaseUrl: htmlUrl,
      apkDownloadUrl: directApkUrl,
      body: json['body'] as String? ?? '',
    );
  }

  final String version;
  final String releaseUrl;
  final String? apkDownloadUrl;
  final String body;
}

class UpdateService {
  UpdateService._();

  static final UpdateService instance = UpdateService._();

  bool _isShowingDialog = false;

  /// Compares two semantic version strings.
  /// Returns positive if version1 > version2, negative if version1 < version2, 0 if equal.
  int compareVersions(String v1, String v2) {
    final v1Parts = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final v2Parts = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLength =
        v1Parts.length > v2Parts.length ? v1Parts.length : v2Parts.length;
    for (var i = 0; i < maxLength; i++) {
      final p1 = i < v1Parts.length ? v1Parts[i] : 0;
      final p2 = i < v2Parts.length ? v2Parts[i] : 0;

      if (p1 != p2) {
        return p1.compareTo(p2);
      }
    }
    return 0;
  }

  /// Checks if a new version is available on GitHub.
  Future<GitHubRelease?> checkForUpdate() async {
    try {
      final url = Uri.parse(
        'https://api.github.com/repos/${AppConfig.githubUsername}/${AppConfig.githubRepo}/releases/latest',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final gitRelease = GitHubRelease.fromJson(data);

        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;

        if (compareVersions(gitRelease.version, currentVersion) > 0) {
          return gitRelease;
        }
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
    return null;
  }

  /// Checks for updates and displays a gorgeous prompt dialog if available.
  /// If [showUpToDateFeedback] is true (e.g. from settings page manual check),
  /// it will show a message when the app is up to date or on error.
  Future<void> checkAndShowUpdateDialog(
    BuildContext context, {
    bool showUpToDateFeedback = false,
  }) async {
    if (_isShowingDialog) return;

    if (showUpToDateFeedback) {
      // Show loading indicator first
      unawaited(
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) =>
              const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final release = await checkForUpdate();

    if (showUpToDateFeedback && context.mounted) {
      Navigator.of(context).pop(); // Dismiss loading
    }

    if (!context.mounted) return;

    if (release != null) {
      _isShowingDialog = true;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          final localizations = AppLocalizations.of(dialogContext);
          final theme = Theme.of(dialogContext);
          final isDark = theme.brightness == Brightness.dark;

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(51),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Beautiful UI Icon for update
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(31),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.system_update_alt_rounded,
                      size: 32,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    localizations.updateAvailable,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    localizations.translateWithParam(
                      'updateMessage',
                      'version',
                      release.version,
                    ),
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.grey[300] : Colors.grey[600],
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (release.body.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF1F5F9),
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Text(
                          release.body,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : Colors.grey[700],
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _isShowingDialog = false;
                            Navigator.of(dialogContext).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            side: BorderSide(
                              color: isDark
                                  ? const Color(0xFF475569)
                                  : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Text(
                            localizations.updateLater,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.grey[300]
                                  : Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final targetUrl =
                                release.apkDownloadUrl ?? release.releaseUrl;
                            final uri = Uri.parse(targetUrl);
                            if (await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            )) {
                              _isShowingDialog = false;
                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop();
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            localizations.updateBtn,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else if (showUpToDateFeedback && context.mounted) {
      // Show "App is up to date" feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).appUpToDate),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}
