import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sdwb/core/signals/theme_controll_signals.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class BaseboardWidget extends StatelessWidget {
  const BaseboardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    final currentTheme = themeModeControll.watch(context);

    final themeButton = IconButton(
      icon: FaIcon(
        (currentTheme == 1)
            ? FontAwesomeIcons.solidSun
            : FontAwesomeIcons.solidMoon,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      onPressed: () {
        themeModeControll.value = themeModeControll.value == 0 ? 1 : 0;
      },
    );

    final githubButton = IconButton(
      icon: FaIcon(
        FontAwesomeIcons.github,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      onPressed: () async {
        final uri = Uri.parse('https://github.com/JCsvg');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [themeButton, githubButton],
    );
  }
}
