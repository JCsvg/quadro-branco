import 'package:flutter/material.dart';
import 'package:sdwb/core/signals/router_signals.dart';
import 'package:sdwb/core/signals/usuario_signals.dart';
import 'package:sdwb/core/theme/app_bar.dart';
import 'package:sdwb/models/sala.dart';
import 'package:sdwb/screens/view/widgets/sala_card_widget.dart';
import 'package:sdwb/services/coordnator_client.dart';
import 'package:sdwb/services/name_service_client.dart';
import 'package:sdwb/state/board_state.dart';
import 'package:uuid/uuid.dart';

class ViewScreen extends StatefulWidget {
  const ViewScreen({super.key});

  @override
  State<ViewScreen> createState() => _ViewScreenState();
}

class _ViewScreenState extends State<ViewScreen> {
  bool _isLoading = true;
  String? _erro;
  List<Sala> _salas = [];

  @override
  void initState() {
    super.initState();
    _carregarSalas();
  }

  Future<void> _carregarSalas() async {
    setState(() {
      _isLoading = true;
      _erro = null;
    });

    try {
      final nameService = await NameServiceClient.conectarAutomatico();
      final List<Sala> salas;
      try {
        salas = await nameService.listar();
      } finally {
        await nameService.fechar();
      }
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _salas = salas;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _erro = 'Não foi possível buscar as salas: $e';
      });
    }
  }

  Future<void> _entrarNaSala(Sala sala) async {
    final meuId = const Uuid().v4();
    final boardState = BoardState(meuClienteId: meuId);
    final cliente = CoordnatorClient(
      boardState: boardState,
      meuId: meuId,
      meuNome: meuNomeSignal.value,
    );

    try {
      await cliente.entrarNaSala(
        ipCoordenador: sala.ip,
        portaCoordenador: sala.porta,
      );
      if (!mounted) return;
      goTo(AppRoute.board, sala: sala, boardState: boardState, conexao: cliente);
    } catch (e) {
      await cliente.sair();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível entrar na sala: $e')),
      );
    }
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Salas Ativas',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontSize: 22),
                            ),
                            Text(
                              _erro ?? '${_salas.length} salas disponíveis',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: _erro != null
                                        ? colorScheme.error
                                        : null,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Atualizar',
                        onPressed: _carregarSalas,
                        icon: const Icon(Icons.refresh),
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
