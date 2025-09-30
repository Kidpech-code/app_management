import 'package:app_management/app/router/app_router.dart';
import 'package:app_management/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'App Management',
      routerConfig: router,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
    );
  }
}
