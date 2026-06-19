import 'package:flutter/material.dart';
import 'package:sdwb/core/theme/app_colors.dart';
import 'package:sdwb/models/sala.dart';

class SalaCardWidget extends StatelessWidget {
  const SalaCardWidget({super.key, required this.sala});
  final Sala sala;

  @override
  Widget build(BuildContext context) {
    // ignore: avoid_unnecessary_containers
    return Container(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Column(
              children: [
                Text(sala.nome),
                Text('ip/porta: ${sala.ip}/${sala.porta}'),
              ],
            ),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(AppColors.primaryDark),
              ),
              child: Text('Entrar'),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
