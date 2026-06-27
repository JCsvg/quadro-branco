import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sdwb/core/signals/router_signals.dart';
import 'package:sdwb/core/signals/theme_controll_signals.dart';
import 'package:sdwb/core/signals/usuario_signals.dart';
import 'package:sdwb/models/sala.dart';
import 'package:sdwb/screens/board/widgets/draing_canvas.dart';
import 'package:sdwb/screens/board/widgets/members_painel.dart';
import 'package:sdwb/screens/board/widgets/notifications_button.dart';
import 'package:sdwb/services/sala_conexao.dart';
import 'package:sdwb/state/board_state.dart';
import 'package:signals/signals_flutter.dart';
import 'package:uuid/uuid.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key, this.sala, this.boardState, this.conexao});

  final Sala? sala;
  final BoardState? boardState;
  final SalaConexao? conexao;

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  final _canvasKey = GlobalKey<DrawingCanvasState>();

  DrawTool _tool = DrawTool.selecionar;
  Color _color = kStrokeColors.first;
  bool _temSelecao = false;
  bool _saindo = false;

  /// Se a tela foi aberta sem rede (sem `conexao`/`boardState` reais — ex.
  /// abrindo o board direto, fora do fluxo criar/entrar), cria um estado
  /// local efêmero só pra o canvas continuar funcionando.
  late final BoardState _boardState =
      widget.boardState ?? BoardState(meuClienteId: const Uuid().v4());

  static const _ferramentas = <DrawTool, IconData>{
    DrawTool.selecionar: Icons.back_hand_outlined,
    DrawTool.pen: Icons.edit,
    DrawTool.line: Icons.remove,
    DrawTool.circle: Icons.circle_outlined,
    DrawTool.square: Icons.crop_square,
    DrawTool.triangle: Icons.change_history,
  };

  Future<void> _sair() async {
    if (_saindo) return;
    setState(() => _saindo = true);
    await widget.conexao?.sair();
    if (!mounted) return;
    goTo(AppRoute.home);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sala = widget.sala;

    return Scaffold(
      appBar: _BoardAppBar(sala: sala, onSair: _sair),
      body: Column(
        children: [
          _Toolbar(
            tool: _tool,
            color: _color,
            ferramentas: _ferramentas,
            temSelecao: _temSelecao,
            onToolSelected: (tool) {
              _canvasKey.currentState?.limparSelecao();
              setState(() => _tool = tool);
            },
            onColorSelected: (color) => setState(() => _color = color),
            onRemover: () => _canvasKey.currentState?.removerSelecionado(),
            onColorir: () =>
                _canvasKey.currentState?.colorirSelecionado(_color),
            onPreencher: () =>
                _canvasKey.currentState?.preencherSelecionado(_color),
          ),
          const Divider(height: 1),
          Expanded(
            child: Row(
              children: [
                _MembersPainelConectado(conexao: widget.conexao),
                VerticalDivider(width: 1, color: colorScheme.outlineVariant),
                Expanded(
                  child: DrawingCanvas(
                    key: _canvasKey,
                    boardState: _boardState,
                    tool: _tool,
                    color: _color,
                    onSelecaoMudou: (selecionado) =>
                        setState(() => _temSelecao = selecionado),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Painel de participantes ligado a uma [SalaConexao] real (escuta os
/// `notifyListeners()` dela pra atualizar a lista ao vivo). Sem conexão
/// (`conexao == null`), cai pro `MembersPainel` mockado de sempre.
class _MembersPainelConectado extends StatelessWidget {
  const _MembersPainelConectado({required this.conexao});

  final SalaConexao? conexao;

  static const _coresAvatar = [
    Colors.indigo,
    Colors.blue,
    Colors.pink,
    Colors.teal,
    Colors.orange,
    Colors.purple,
  ];

  @override
  Widget build(BuildContext context) {
    final conexao = this.conexao;
    if (conexao == null) {
      return const MembersPainel();
    }

    return ListenableBuilder(
      listenable: conexao,
      builder: (context, _) {
        final outros = conexao.membros.where((m) => m.id != conexao.meuId);

        final participantes = [
          Participante(
            nome: meuNomeSignal.value,
            cor: _coresAvatar[0],
            isVoce: true,
          ),
          ...outros.map(
            (m) => Participante(
              nome: m.nome,
              cor: _coresAvatar[1 + (m.id.hashCode % (_coresAvatar.length - 1))],
            ),
          ),
        ];

        return MembersPainel(participantes: participantes);
      },
    );
  }
}

class _BoardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _BoardAppBar({required this.sala, required this.onSair});

  final Sala? sala;
  final VoidCallback onSair;

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    final currentTheme = themeModeControll.watch(context);
    final sala = this.sala;

    return AppBar(
      titleSpacing: 16,
      title: Row(
        children: [
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
          const SizedBox(width: 8),
          const Icon(Icons.circle, size: 8, color: Colors.green),
          const SizedBox(width: 8),
          Text(
            sala?.nome ?? 'Quadro',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (sala != null) ...[
            const SizedBox(width: 8),
            Text(
              '${sala.ip}:${sala.porta}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
      actions: [
        const NotificationsButton(),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: onSair,
          style: TextButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
          ),
          icon: const Icon(Icons.logout, size: 16),
          label: const Text('Sair'),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.tool,
    required this.color,
    required this.ferramentas,
    required this.temSelecao,
    required this.onToolSelected,
    required this.onColorSelected,
    required this.onRemover,
    required this.onColorir,
    required this.onPreencher,
  });

  final DrawTool tool;
  final Color color;
  final Map<DrawTool, IconData> ferramentas;
  final bool temSelecao;
  final ValueChanged<DrawTool> onToolSelected;
  final ValueChanged<Color> onColorSelected;
  final VoidCallback onRemover;
  final VoidCallback onColorir;
  final VoidCallback onPreencher;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          for (final entry in ferramentas.entries)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: IconButton(
                isSelected: tool == entry.key,
                style: IconButton.styleFrom(
                  backgroundColor: tool == entry.key
                      ? colorScheme.primary
                      : Colors.transparent,
                  foregroundColor: tool == entry.key
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                ),
                icon: Icon(entry.value),
                onPressed: () => onToolSelected(entry.key),
              ),
            ),
          const SizedBox(width: 12),
          for (final c in kStrokeColors)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GestureDetector(
                onTap: () => onColorSelected(c),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: c == color
                          ? colorScheme.onSurface
                          : colorScheme.outline,
                      width: c == color ? 2.5 : 1,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 12),
          const VerticalDivider(width: 1),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Remover selecionado',
            onPressed: temSelecao ? onRemover : null,
            icon: const Icon(Icons.delete_outline),
          ),
          IconButton(
            tooltip: 'Colorir selecionado',
            onPressed: temSelecao ? onColorir : null,
            icon: const Icon(Icons.colorize),
          ),
          IconButton(
            tooltip: 'Preencher selecionado',
            onPressed: temSelecao ? onPreencher : null,
            icon: const Icon(Icons.format_color_fill),
          ),
        ],
      ),
    );
  }
}
