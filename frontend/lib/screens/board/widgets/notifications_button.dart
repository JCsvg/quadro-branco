import 'package:flutter/material.dart';

const kNotificacoesMock = <String>[
  'Ana P. entrou na sala',
  'Mateus R. compartilhou um desenho',
  'Sofia T. enviou uma mensagem',
];

class NotificationsButton extends StatefulWidget {
  const NotificationsButton({super.key, this.notificacoes = kNotificacoesMock});

  final List<String> notificacoes;

  @override
  State<NotificationsButton> createState() => _NotificationsButtonState();
}

class _NotificationsButtonState extends State<NotificationsButton> {
  bool _lidas = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<void>(
      tooltip: 'Notificações',
      offset: const Offset(0, 40),
      onOpened: () => setState(() => _lidas = true),
      itemBuilder: (context) => [
        PopupMenuItem<void>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: SizedBox(
            width: 260,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Notificações',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  if (widget.notificacoes.isEmpty)
                    Text(
                      'Nenhuma notificação.',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else
                    for (final item in widget.notificacoes)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('•  '),
                            Expanded(child: Text(item)),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_outlined),
            if (!_lidas && widget.notificacoes.isNotEmpty)
              Positioned(
                right: -1,
                top: -1,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
