import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const _SettingsSection(
            title: 'Data Sources',
            children: [
              _SettingsTile(
                icon: Icons.reddit,
                title: 'Reddit',
                subtitle: 'Enabled',
                trailing: Switch(value: true, onChanged: null),
              ),
              _SettingsTile(
                icon: Icons.newspaper,
                title: 'HackerNews',
                subtitle: 'Enabled',
                trailing: Switch(value: true, onChanged: null),
              ),
              _SettingsTile(
                icon: Icons.rss_feed,
                title: 'RSS Feeds',
                subtitle: 'Enabled',
                trailing: Switch(value: true, onChanged: null),
              ),
            ],
          ),
          const _SettingsSection(
            title: 'Display',
            children: [
              _SettingsTile(
                icon: Icons.speed,
                title: 'Update Frequency',
                subtitle: 'Every 10 seconds',
              ),
              _SettingsTile(
                icon: Icons.animation,
                title: 'Smooth Transitions',
                subtitle: 'Enabled',
                trailing: Switch(value: true, onChanged: null),
              ),
              _SettingsTile(
                icon: Icons.face,
                title: 'Face Quality',
                subtitle: 'High (Unity 3D)',
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

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
      ],
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
