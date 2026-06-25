import 'package:flutter/material.dart';
import 'package:sdwb/models/sala.dart';

class SalaCardWidget extends StatelessWidget {
  const SalaCardWidget({super.key, required this.sala, required this.onEntrar});
  final Sala sala;
  final VoidCallback onEntrar;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.edit,
                color: colorScheme.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sala.nome,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${sala.ip}:${sala.porta}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people_outline, size: 14),
                  const SizedBox(width: 4),
                  Text('${sala.ativos}'),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: onEntrar,
              icon: const Icon(Icons.chevron_right, size: 18),
              label: const Text('Entrar'),
            ),
          ],
        ),
      ),
    );
  }
}
