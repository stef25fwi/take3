import 'package:flutter/material.dart';

import 'router/router.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const Take30App());
}

class Take30App extends StatelessWidget {
  const Take30App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Take30',
      theme: AppTheme.lightTheme,
      initialRoute: AppRouter.splash,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
