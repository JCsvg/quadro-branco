import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sdwb/core/signals/router_signals.dart';
import 'package:sdwb/core/signals/theme_controll_signals.dart';
import 'package:signals/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SdwbAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showHome;
  final List<Widget>? actions;

  const SdwbAppBar({
    super.key,
    this.title = 'Quadro Branco',
    this.showHome = true,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    final currentTheme = themeModeControll.watch(context);
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      titleSpacing: 16,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.edit, color: colorScheme.onPrimary, size: 18),
          ),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
      actions: [
        if (showHome)
          IconButton(
            icon: const Icon(Icons.home_outlined),
            onPressed: () => goTo(AppRoute.home),
          ),
        IconButton(
          icon: FaIcon(
            (currentTheme == 1)
                ? FontAwesomeIcons.solidSun
                : FontAwesomeIcons.solidMoon,
          ),
          onPressed: () {
            themeModeControll.value = themeModeControll.value == 0 ? 1 : 0;
          },
        ),
        IconButton(
          icon: const FaIcon(FontAwesomeIcons.github),
          onPressed: () async {
            final uri = Uri.parse('https://github.com/JCsvg');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          },
        ),
        if (actions != null) ...actions!,
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
