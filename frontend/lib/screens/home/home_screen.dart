import 'package:flutter/material.dart';
import 'package:sdwb/core/signals/theme_controll_signals.dart';
import 'package:sdwb/screens/home/widgets/baseboard_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.light_mode,
              size: 100,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'Quadro Branco Distribuido',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, 'view'),
              child: const Text('Jogar'),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, 'board'),
              child: const Text('Criar Quadro'),
            ),
            const SizedBox(height: 20),
            BaseboardWidget(),
          ],
        ),
      ),
    );
  }
}
