import 'package:flutter/material.dart';

import 'drawer_controller_scope.dart';

/// Reusable header widget to unify AppBar design across screens.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
  });

  @override
  Size get preferredSize {
    final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;
    return Size.fromHeight(hasSubtitle ? 110 : 96);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1B1F32) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF6B7280);
    final shadowColor = isDark ? Colors.black.withOpacity(.3) : Colors.black.withOpacity(.06);

    final appBarColor = isDark ? const Color(0xFF101325) : Colors.white;

    final drawerScope = DrawerControllerScope.maybeOf(context);

    return AppBar(
      backgroundColor: appBarColor,
      surfaceTintColor: appBarColor,
      elevation: 0,
      toolbarHeight: preferredSize.height,
      titleSpacing: 16,
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            leading ??
                (drawerScope?.openDrawer != null
                    ? _DrawerButton(onPressed: drawerScope!.openDrawer!)
                    : Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4B6BFB), Color(0xFF8F44FD)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(Icons.local_pharmacy_outlined, color: Colors.white),
                      )),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 4,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      height: 1.2,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        subtitle!,
                        maxLines: 3,
                        softWrap: true,
                        overflow: TextOverflow.visible,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: subtitleColor,
                          height: 1.2,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
     ),
      actions: actions,
    );
  }
}

class _DrawerButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _DrawerButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFF4F6DF6), Color(0xFF8454FF)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          child: const Icon(Icons.menu, color: Colors.white),
        ),
      ),
    );
  }
}
