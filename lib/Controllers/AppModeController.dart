import 'package:flutter/material.dart';

enum AppMode { dating, social }

class AppModeController extends ValueNotifier<AppMode?> {
  AppModeController({AppMode? initialMode}) : super(initialMode);

  AppMode? get mode => value;

  void setMode(AppMode? mode) {
    value = mode;
  }
}

class AppModeProvider extends InheritedNotifier<AppModeController> {
  const AppModeProvider({
    super.key,
    required AppModeController notifier,
    required super.child,
  }) : super(notifier: notifier);

  static AppModeController of(BuildContext context, {bool listen = true}) {
    if (listen) {
      final provider = context.dependOnInheritedWidgetOfExactType<AppModeProvider>();
      if (provider == null) {
        throw FlutterError(
            'AppModeProvider.of() called with a context that does not contain an AppModeProvider.');
      }
      return provider.notifier!;
    } else {
      final provider = context.getInheritedWidgetOfExactType<AppModeProvider>();
      if (provider == null) {
        throw FlutterError(
            'AppModeProvider.of() called with a context that does not contain an AppModeProvider.');
      }
      return provider.notifier!;
    }
  }
}
