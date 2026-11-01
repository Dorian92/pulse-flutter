// Settings uses [RadioListTile] until Material [RadioGroup] migration (Flutter 3.32+).
// ignore_for_file: deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pulse/core/router/app_router.dart';
import 'package:pulse/core/theme/app_colors.dart';
import 'package:pulse/l10n/app_localizations.dart';
import 'package:pulse/settings/bloc/settings_cubit.dart';
import 'package:pulse/settings/bloc/settings_state.dart';
import 'package:pulse/settings/models/display_currency.dart';
import 'package:url_launcher/url_launcher.dart';

/// Theme, locale, currency, cache, and about.
class SettingsPage extends StatefulWidget {
  /// Creates the settings screen.
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _versionLabel = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) {
      return;
    }
    setState(() => _versionLabel = '${info.version}+${info.buildNumber}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.pulseTokens;

    return BlocConsumer<SettingsCubit, SettingsState>(
      listener: (context, state) {
        if (state.cacheClearMessage == true) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.settingsCacheCleared)));
        }
      },
      builder: (context, state) {
        final prefs = state.preferences;
        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.all(tokens.spacingMd),
              children: [
                Text(
                  l10n.tabSettings,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: tokens.spacingLg),
                Text(
                  l10n.settingsAppearanceSection,
                  style: _sectionStyle(context),
                ),
                RadioListTile<ThemeMode>(
                  title: Text(l10n.settingsThemeSystem),
                  value: ThemeMode.system,
                  groupValue: prefs.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      context.read<SettingsCubit>().setThemeMode(value);
                    }
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: Text(l10n.settingsThemeLight),
                  value: ThemeMode.light,
                  groupValue: prefs.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      context.read<SettingsCubit>().setThemeMode(value);
                    }
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: Text(l10n.settingsThemeDark),
                  value: ThemeMode.dark,
                  groupValue: prefs.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      context.read<SettingsCubit>().setThemeMode(value);
                    }
                  },
                ),
                SizedBox(height: tokens.spacingMd),
                Text(
                  l10n.settingsLanguageSection,
                  style: _sectionStyle(context),
                ),
                RadioListTile<String>(
                  title: Text(l10n.settingsLanguageEnglish),
                  value: 'en',
                  groupValue: prefs.localeCode,
                  onChanged: (value) {
                    if (value != null) {
                      context.read<SettingsCubit>().setLocaleCode(value);
                    }
                  },
                ),
                RadioListTile<String>(
                  title: Text(l10n.settingsLanguageSerbian),
                  value: 'sr_Latn',
                  groupValue: prefs.localeCode,
                  onChanged: (value) {
                    if (value != null) {
                      context.read<SettingsCubit>().setLocaleCode(value);
                    }
                  },
                ),
                SizedBox(height: tokens.spacingMd),
                Text(
                  l10n.settingsCurrencySection,
                  style: _sectionStyle(context),
                ),
                RadioListTile<DisplayCurrency>(
                  title: Text(l10n.settingsCurrencyEur),
                  value: DisplayCurrency.eur,
                  groupValue: prefs.displayCurrency,
                  onChanged: (value) {
                    if (value != null) {
                      context.read<SettingsCubit>().setDisplayCurrency(value);
                    }
                  },
                ),
                RadioListTile<DisplayCurrency>(
                  title: Text(l10n.settingsCurrencyUsd),
                  value: DisplayCurrency.usd,
                  groupValue: prefs.displayCurrency,
                  onChanged: (value) {
                    if (value != null) {
                      context.read<SettingsCubit>().setDisplayCurrency(value);
                    }
                  },
                ),
                SizedBox(height: tokens.spacingMd),
                Text(l10n.settingsDataSection, style: _sectionStyle(context)),
                ListTile(
                  title: Text(l10n.settingsClearCache),
                  trailing: const Icon(Icons.delete_outline),
                  onTap: () => context.read<SettingsCubit>().clearCache(),
                ),
                SizedBox(height: tokens.spacingMd),
                Text(l10n.settingsAboutSection, style: _sectionStyle(context)),
                ListTile(
                  title: Text(l10n.settingsVersion),
                  subtitle: Text(_versionLabel.isEmpty ? '—' : _versionLabel),
                ),
                ListTile(
                  title: Text(l10n.settingsLicenses),
                  trailing: const Icon(Icons.article_outlined),
                  onTap: () => showLicensePage(context: context),
                ),
                ListTile(
                  title: Text(l10n.settingsGitHub),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _openGitHub(context),
                ),
                if (kDebugMode) ...[
                  SizedBox(height: tokens.spacingMd),
                  FilledButton(
                    onPressed: () => context.push(AppRoutes.designGallery),
                    child: Text(l10n.designGalleryOpen),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  TextStyle? _sectionStyle(BuildContext context) {
    return Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600);
  }

  Future<void> _openGitHub(BuildContext context) async {
    const url = AppLinks.githubRepository;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// External links used in settings.
abstract final class AppLinks {
  /// Pulse Flutter repository on GitHub.
  static const String githubRepository =
      'https://github.com/Dorian92/pulse-flutter';
}
