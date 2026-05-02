import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';

class Take60SettingsOption {
  const Take60SettingsOption({
    required this.value,
    required this.title,
    required this.description,
  });

  final String value;
  final String title;
  final String description;
}

class Take60SimpleSettingsScreen extends ConsumerWidget {
  const Take60SimpleSettingsScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.currentValue,
    required this.options,
    required this.onSelected,
  });

  final String title;
  final String subtitle;
  final String currentValue;
  final List<Take60SettingsOption> options;
  final Future<void> Function(WidgetRef ref, String value) onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppThemeTokens.pageBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppThemeTokens.primaryText(context),
        elevation: 0,
        title: Text(
          title,
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            subtitle,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppThemeTokens.secondaryText(context),
            ),
          ),
          const SizedBox(height: 18),
          for (final option in options) ...[
            _OptionTile(
              option: option,
              selected: option.value == currentValue,
              onTap: () async {
                await onSelected(ref, option.value);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final Take60SettingsOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppThemeTokens.surface(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? accent : AppThemeTokens.border(context),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppThemeTokens.primaryText(context),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      option.description,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppThemeTokens.secondaryText(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? accent : AppThemeTokens.tertiaryText(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}