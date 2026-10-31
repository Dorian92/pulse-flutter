import 'package:flutter/material.dart';
import 'package:pulse/core/theme/app_colors.dart';

class PlaceholderFeaturePage extends StatelessWidget {
  const PlaceholderFeaturePage({
    required this.title,
    required this.body,
    super.key,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.pulseTokens;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: EdgeInsets.all(tokens.spacingMd),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(tokens.spacingMd),
            child: Text(
              body,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
