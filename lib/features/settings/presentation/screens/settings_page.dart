import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_management/app/di/providers.dart';
import 'package:app_management/features/auth/application/auth_notifier.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final authState = ref.watch(authNotifierProvider);
    final user = authState.valueOrNull?.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          ListTile(
            title: const Text('Build flavor'),
            subtitle: Text(config.buildFlavor.name),
          ),
          ListTile(
            title: const Text('API Base URL'),
            subtitle: Text(config.apiBaseUrl),
          ),
          if (user != null)
            ListTile(
              title: const Text('Signed in as'),
              subtitle: Text(user.email),
            ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
            child: const Text('Sign out'),
          ),
          const SizedBox(height: 24),
          const Text('Deep link examples:'),
          SelectableText('myapp://todos/42\nhttps://example.com/todos/42'),
        ],
      ),
    );
  }
}
