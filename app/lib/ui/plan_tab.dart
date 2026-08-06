// Plan tab. The bar reserves the surface (turn-4 navItems) but no meal-plan
// screen is designed in any turn and no plan engine exists in the alpha —
// so this is the app's honest empty pattern, never a fake plan.

import 'package:flutter/material.dart';

import 'theme.dart';

class PlanTab extends StatelessWidget {
  const PlanTab({super.key});

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
            Text('Meal plan',
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
                    child: Icon(Icons.calendar_month_rounded,
                        size: 32, color: scheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text('Meal planning lands post-alpha.',
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
