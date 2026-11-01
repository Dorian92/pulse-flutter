import 'package:flutter/material.dart';
import 'package:pulse/core/widgets/placeholder_feature_page.dart';
import 'package:pulse/l10n/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PlaceholderFeaturePage(
      title: l10n.settingsPlaceholderTitle,
      body: l10n.settingsPlaceholderBody,
    );
  }
}
