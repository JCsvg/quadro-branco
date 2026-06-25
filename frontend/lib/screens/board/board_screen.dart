import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sdwb/core/signals/router_signals.dart';
import 'package:sdwb/core/signals/theme_controll_signals.dart';
import 'package:sdwb/models/sala.dart';
import 'package:sdwb/screens/board/widgets/draing_canvas.dart';
import 'package:sdwb/screens/board/widgets/members_painel.dart';
import 'package:sdwb/screens/board/widgets/notifications_button.dart';
import 'package:signals/signals_flutter.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key, this.sala});

  final Sala? sala;

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  final _canvasKey = GlobalKey<DrawingCanvasState>();

  DrawTool _tool = DrawTool.selecionar;
  Color _color = kStrokeColors.first;
  bool _temSelecao = false;

  static const _ferramentas = <DrawTool, IconData>{
    DrawTool.selecionar: Icons.back_hand_outlined,
    DrawTool.pen: Icons.edit,
    DrawTool.line: Icons.remove,
    DrawTool.circle: Icons.circle_outlined,
    DrawTool.square: Icons.crop_square,
    DrawTool.triangle: Icons.change_history,
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sala = widget.sala;

    return Scaffold(
      appBar: _BoardAppBar(sala: sala),
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
                const MembersPainel(),
                VerticalDivider(width: 1, color: colorScheme.outlineVariant),
                Expanded(
                  child: DrawingCanvas(
                    key: _canvasKey,
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

class _BoardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _BoardAppBar({required this.sala});

  final Sala? sala;

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
          onPressed: () => goTo(AppRoute.home),
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
