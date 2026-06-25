import 'package:flutter/material.dart';
import 'package:sdwb/core/signals/router_signals.dart';
import 'package:sdwb/core/theme/app_bar.dart';
import 'package:sdwb/models/sala.dart';
import 'package:sdwb/screens/view/widgets/sala_card_widget.dart';

class ViewScreen extends StatefulWidget {
  const ViewScreen({super.key});

  @override
  State<ViewScreen> createState() => _ViewScreenState();
}

class _ViewScreenState extends State<ViewScreen> {
  bool _isLoading = true;
  List<Sala> _salas = [];

  @override
  void initState() {
    super.initState();
    _carregarSalas();
  }

  Future<void> _carregarSalas() async {
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
      _salas = [
        Sala(nome: 'Gartic Phone', ip: 'localhost', porta: 8080, ativos: 5),
        Sala(nome: 'Só Quadrados', ip: 'localhost', porta: 8081, ativos: 2),
      ];
    });
  }

  void _entrarNaSala(Sala sala) {
    goTo(AppRoute.board, sala: sala);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const SdwbAppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.wifi,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Salas Ativas',
                            style: Theme.of(
                              context,
                            ).textTheme.headlineMedium?.copyWith(fontSize: 22),
                          ),
                          Text(
                            '${_salas.length} salas disponíveis',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_salas.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'Nenhuma sala ativa no momento.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: _salas.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) => SalaCardWidget(
                          sala: _salas[index],
                          onEntrar: () => _entrarNaSala(_salas[index]),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
