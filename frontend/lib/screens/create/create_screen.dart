import 'package:flutter/material.dart';
import 'package:sdwb/core/network/tcp_client.dart';
import 'package:sdwb/core/signals/router_signals.dart';
import 'package:sdwb/core/theme/app_bar.dart';
import 'package:sdwb/models/sala.dart';
import 'package:sdwb/services/coordinator_server.dart';
import 'package:sdwb/services/name_service_client.dart';
import 'package:sdwb/state/board_state.dart';
import 'package:uuid/uuid.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final _nomeSalaController = TextEditingController();
  final _portaController = TextEditingController(text: '3001');
  bool _isLoading = false;
  String? _erro;

  @override
  void dispose() {
    _nomeSalaController.dispose();
    _portaController.dispose();
    super.dispose();
  }

  Future<void> _criarSala() async {
    setState(() {
      _isLoading = true;
      _erro = null;
    });

    final nomeSala = _nomeSalaController.text.trim();
    final meuId = const Uuid().v4();
    final boardState = BoardState(meuClienteId: meuId);
    final coordenador = CoordinatorServer(boardState: boardState, meuId: meuId);

    try {
      final portaDesejada = int.tryParse(_portaController.text.trim()) ?? 0;
      await coordenador.iniciar(porta: portaDesejada);

      final ip = await TcpClient.ipLocal();
      final nameService = await NameServiceClient.conectarAutomatico();
      try {
        await nameService.registrar(
          nome: nomeSala,
          ip: ip,
          porta: coordenador.porta,
        );
      } finally {
        await nameService.fechar();
      }

      if (!mounted) return;
      final sala = Sala(nome: nomeSala, ip: ip, porta: coordenador.porta, ativos: 1);
      goTo(AppRoute.board, sala: sala, boardState: boardState, conexao: coordenador);
    } catch (e) {
      await coordenador.encerrar();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _erro = 'Não foi possível criar a sala: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final porta = _portaController.text;
    final endereco = 'definido ao criar:${porta.isEmpty ? '----' : porta}';

    return Scaffold(
      appBar: const SdwbAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
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
                          Icons.add,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Criar Sala',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontSize: 22),
                          ),
                          Text(
                            'Configure sua sessão colaborativa',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NOME DA SALA',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nomeSalaController,
                            decoration: const InputDecoration(
                              hintText: 'Ex: Sprint Planning',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'PORTA',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _portaController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(hintText: '3001'),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'ENDEREÇO DA SALA',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.wifi,
                                  size: 16,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(endereco),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Compartilhe este endereço com seu time.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (_erro != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _erro!,
                              style: TextStyle(color: colorScheme.error),
                            ),
                          ],
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed:
                                  (_isLoading ||
                                      _nomeSalaController.text.trim().isEmpty)
                                  ? null
                                  : _criarSala,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.add, size: 18),
                              label: const Text('Criar Sala'),
                            ),
                          ),
                        ],
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
