import 'package:flutter/material.dart';


///
/// icon + text
/// sizedbox
/// elevatebutton
/// outlinebutton


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.light_mode, size: 100),
            const SizedBox(height: 20),
            const Text('Quadro Branco', style: TextStyle(fontSize: 30)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => {},//Navigator.pushNamed(context, 'view'),
              child: const Text('Jogar'),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => {}, ///Navigator.pushNamed(context, 'board'),
              child: const Text('Criar Quadro'),
            ),
          ]
        ),
      ),
    );
  }
}