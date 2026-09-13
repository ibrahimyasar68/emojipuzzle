import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_settings.dart';

/// Seçilen görünüme bağlı MaterialApp.
///
/// Uygulama kabuğundan ayrı durur ki testler gerçek ses çalıcısını kurmadan
/// tema bağlantısını sınayabilsin.
class ThemedApp extends StatelessWidget {
  const ThemedApp({super.key, required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Android'in son uygulamalar ekranında görünen ad; launcher'daki
      // android:label ve iOS'taki CFBundleDisplayName ile aynı olmalı.
      title: 'EmojiPuzzle',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: context.watch<ThemeSettings>().mode,
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: AppTheme.overlayFor(Theme.of(context).brightness),
        child: child!,
      ),
      home: home,
    );
  }
}
