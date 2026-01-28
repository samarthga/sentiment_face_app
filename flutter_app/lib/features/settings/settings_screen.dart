import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../face/data/sentiment_repository.dart';
import 'data/settings_provider.dart';
import 'domain/expression_type.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableSources = ref.watch(availableSourcesProvider);
    final selectedSources = ref.watch(selectedSourcesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _SettingsSection(
            title: 'Data Sources',
            trailing: TextButton(
              onPressed: () {
                // Toggle all sources
                final allSelected = selectedSources.length == availableSources.length;
                if (allSelected) {
                  // Keep only the first source (can't deselect all)
                  ref.read(selectedSourcesProvider.notifier).state = {availableSources.first.id};
                } else {
                  // Select all
                  ref.read(selectedSourcesProvider.notifier).state =
                      availableSources.map((s) => s.id).toSet();
                }
              },
              child: Text(
                selectedSources.length == availableSources.length ? 'Deselect All' : 'Select All',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            children: availableSources.map((source) {
              final isEnabled = selectedSources.contains(source.id);
              return _SourceTile(
                icon: source.icon,
                iconColor: source.color,
                title: source.name,
                isEnabled: isEnabled,
                canDisable: selectedSources.length > 1 || !isEnabled,
                onChanged: (enabled) {
                  final current = ref.read(selectedSourcesProvider);
                  final updated = Set<String>.from(current);

                  if (enabled) {
                    updated.add(source.id);
                  } else if (updated.length > 1) {
                    updated.remove(source.id);
                  }

                  ref.read(selectedSourcesProvider.notifier).state = updated;
                },
              );
            }).toList(),
          ),
          _SettingsSection(
            title: 'Display',
            children: [
              const _SettingsTile(
                icon: Icons.speed,
                title: 'Update Frequency',
                subtitle: 'Every 10 seconds',
              ),
              const _SettingsTile(
                icon: Icons.animation,
                title: 'Smooth Transitions',
                subtitle: 'Enabled',
                trailing: Switch(value: true, onChanged: null),
              ),
              _ExpressionTypeTile(
                currentType: ref.watch(expressionTypeProvider),
                onChanged: (type) {
                  ref.read(expressionTypeProvider.notifier).setExpressionType(type);
                },
              ),
            ],
          ),
          const _SettingsSection(
            title: 'Topics',
            children: [
              _SettingsTile(
                icon: Icons.tag,
                title: 'Filter by Topics',
                subtitle: 'All topics',
              ),
              _SettingsTile(
                icon: Icons.block,
                title: 'Blocked Keywords',
                subtitle: 'None',
              ),
            ],
          ),
          const _SettingsSection(
            title: 'About',
            children: [
              _SettingsTile(
                icon: Icons.info_outline,
                title: 'Version',
                subtitle: '1.0.0',
              ),
              _SettingsTile(
                icon: Icons.code,
                title: 'Open Source Licenses',
                subtitle: 'View licenses',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? trailing;

  const _SettingsSection({
    required this.title,
    required this.children,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        ...children,
      ],
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final bool isEnabled;
  final bool canDisable;
  final ValueChanged<bool> onChanged;

  const _SourceTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.isEnabled,
    required this.canDisable,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: isEnabled ? iconColor : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          color: isEnabled ? null : Colors.grey,
        ),
      ),
      subtitle: Text(
        isEnabled ? 'Enabled' : 'Disabled',
        style: TextStyle(
          color: isEnabled ? Colors.green : Colors.grey,
          fontSize: 12,
        ),
      ),
      trailing: Switch(
        value: isEnabled,
        activeColor: iconColor,
        onChanged: canDisable || !isEnabled ? onChanged : null,
      ),
      onTap: () {
        if (canDisable || !isEnabled) {
          onChanged(!isEnabled);
        }
      },
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }
}

class _ExpressionTypeTile extends StatelessWidget {
  final ExpressionType currentType;
  final ValueChanged<ExpressionType> onChanged;

  const _ExpressionTypeTile({
    required this.currentType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.face),
      title: const Text('Expression Type'),
      subtitle: Text(currentType.label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showExpressionTypeDialog(context),
    );
  }

  void _showExpressionTypeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Expression Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ExpressionType.values.map((type) {
            return RadioListTile<ExpressionType>(
              title: Text(type.label),
              subtitle: Text(_getDescription(type)),
              value: type,
              groupValue: currentType,
              onChanged: (value) {
                if (value != null) {
                  onChanged(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getDescription(ExpressionType type) {
    switch (type) {
      case ExpressionType.faceOnly:
        return 'Close-up portrait shot';
      case ExpressionType.upperBody:
        return 'Head, shoulders, and torso';
      case ExpressionType.fullBody:
        return 'Entire person visible';
    }
  }
}
