// Settings tab. On the bar and in the drawer by design (turn-4 navItems,
// 5c), but no settings screen is designed yet (turn-5 "Try next: settings
// screen") — the honest empty pattern holds the surface until one is.

import 'package:flutter/material.dart';

import 'theme.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings',
                style: theme.textTheme.headlineSmall?.copyWith(fontSize: 22)),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.settings_rounded,
                        size: 32, color: scheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text('Settings land post-alpha.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
