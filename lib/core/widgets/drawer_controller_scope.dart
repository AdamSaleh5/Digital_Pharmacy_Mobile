import 'package:flutter/widgets.dart';

class DrawerControllerScope extends InheritedWidget {
  final VoidCallback? openDrawer;

  const DrawerControllerScope({
    super.key,
    required this.openDrawer,
    required super.child,
  });

  static DrawerControllerScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DrawerControllerScope>();
  }

  @override
  bool updateShouldNotify(DrawerControllerScope oldWidget) {
    return oldWidget.openDrawer != openDrawer;
  }
}
