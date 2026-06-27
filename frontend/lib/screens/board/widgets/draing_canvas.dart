/// Canvas de desenho ligado ao [BoardState] — cada ação (desenhar,
/// selecionar, colorir, preencher, remover) passa por ele, que decide o que
/// broadcastar pra rede e reage a mensagens que chegam de outros membros
/// (ver `.obsidian/conn-client/visao-geral.md`).
library;

import 'package:flutter/material.dart';
import 'package:sdwb/models/board_object.dart';
import 'package:sdwb/state/board_state.dart';
import 'package:uuid/uuid.dart';

enum DrawTool { selecionar, pen, line, circle, square, triangle }

const kStrokeColors = <Color>[
  Colors.black,
  Color(0xFF3F51B5),
  Color(0xFF29B6F6),
  Color(0xFF26A69A),
  Color(0xFFFFA726),
  Color(0xFFE53935),
  Color(0xFFEC407A),
  Color(0xFF8E63E0),
  Colors.white,
];

const kFormasFechadas = {DrawTool.square, DrawTool.circle, DrawTool.triangle};

FormaTipo? _formaDe(DrawTool tool) {
  switch (tool) {
    case DrawTool.pen:
      return FormaTipo.caneta;
    case DrawTool.line:
      return FormaTipo.linha;
    case DrawTool.circle:
      return FormaTipo.circulo;
    case DrawTool.square:
      return FormaTipo.quadrado;
    case DrawTool.triangle:
      return FormaTipo.triangulo;
    case DrawTool.selecionar:
      return null;
  }
}

bool _formaFechada(FormaTipo tipo) =>
    tipo == FormaTipo.quadrado ||
    tipo == FormaTipo.circulo ||
    tipo == FormaTipo.triangulo;

class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas({
    super.key,
    required this.boardState,
    required this.tool,
    required this.color,
    this.onSelecaoMudou,
  });

  final BoardState boardState;
  final DrawTool tool;
  final Color color;
  final ValueChanged<bool>? onSelecaoMudou;

  @override
  DrawingCanvasState createState() => DrawingCanvasState();
}

class DrawingCanvasState extends State<DrawingCanvas> {
  /// Objeto sendo desenhado agora (preview local, só vira [BoardObject] de
  /// verdade no [BoardState] — e é broadcastado — quando o gesto termina).
  BoardObject? _emAndamento;

  /// Id do objeto que EU selecionei (a tabela de locks de verdade vive no
  /// [BoardState], isso é só "qual desses é o meu" pra saber o que os
  /// botões de remover/colorir/preencher devem afetar).
  String? _meuSelecionadoId;

  @override
  void initState() {
    super.initState();
    widget.boardState.addListener(_aoMudarEstadoCompartilhado);
  }

  @override
  void dispose() {
    widget.boardState.removeListener(_aoMudarEstadoCompartilhado);
    super.dispose();
  }

  void _aoMudarEstadoCompartilhado() => setState(() {});

  void removerSelecionado() {
    final id = _meuSelecionadoId;
    if (id == null) return;
    widget.boardState.removerLocal(id);
    _meuSelecionadoId = null;
    widget.onSelecaoMudou?.call(false);
  }

  void limparSelecao() {
    final id = _meuSelecionadoId;
    if (id == null) return;
    widget.boardState.desselecionarLocal(id);
    _meuSelecionadoId = null;
    widget.onSelecaoMudou?.call(false);
  }

  void colorirSelecionado(Color cor) {
    final id = _meuSelecionadoId;
    if (id == null) return;
    widget.boardState.colorirLocal(id, cor.toARGB32());
  }

  void preencherSelecionado(Color cor) {
    final id = _meuSelecionadoId;
    if (id == null) return;
    final objeto = widget.boardState.objeto(id);
    if (objeto == null || !_formaFechada(objeto.tipo)) return;
    widget.boardState.preencherLocal(id, cor.toARGB32());
  }

  bool _hitTest(BoardObject objeto, Offset ponto) {
    final pontos = objeto.pontos.map((p) => Offset(p.x, p.y)).toList();
    switch (objeto.tipo) {
      case FormaTipo.caneta:
        return pontos.any((p) => (p - ponto).distance < 14);
      case FormaTipo.linha:
        if (pontos.length < 2) return false;
        return _distanciaSegmento(ponto, pontos[0], pontos[1]) < 14;
      case FormaTipo.quadrado:
      case FormaTipo.circulo:
      case FormaTipo.triangulo:
        if (pontos.length < 2) return false;
        return Rect.fromPoints(pontos[0], pontos[1]).inflate(8).contains(ponto);
    }
  }

  double _distanciaSegmento(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final ap = p - a;
    final t = ab.distanceSquared == 0
        ? 0.0
        : ((ap.dx * ab.dx + ap.dy * ab.dy) / ab.distanceSquared).clamp(
            0.0,
            1.0,
          );
    final proj = a + ab * t;
    return (p - proj).distance;
  }

  void _selecionarNoPonto(Offset ponto) {
    BoardObject? encontrado;
    for (final objeto in widget.boardState.objetos.reversed) {
      if (_hitTest(objeto, ponto)) {
        encontrado = objeto;
        break;
      }
    }

    if (encontrado == null) {
      // Tocou em vazio — solta o que eu tinha selecionado, se tinha.
      if (_meuSelecionadoId != null) {
        widget.boardState.desselecionarLocal(_meuSelecionadoId!);
        setState(() => _meuSelecionadoId = null);
        widget.onSelecaoMudou?.call(false);
      }
      return;
    }

    if (widget.boardState.estaTravado(encontrado.id) &&
        !widget.boardState.souDonoDe(encontrado.id)) {
      return; // já travado por outro membro — não dá pra selecionar.
    }

    final conseguiu = widget.boardState.selecionarLocal(encontrado.id);
    if (conseguiu) {
      setState(() => _meuSelecionadoId = encontrado!.id);
      widget.onSelecaoMudou?.call(true);
    }
  }

  void _onPanStart(DragStartDetails details) {
    final ponto = details.localPosition;

    if (widget.tool == DrawTool.selecionar) {
      _selecionarNoPonto(ponto);
      return;
    }

    final forma = _formaDe(widget.tool);
    if (forma == null) return;

    setState(() {
      _emAndamento = BoardObject(
        id: const Uuid().v4(),
        tipo: forma,
        pontos: [PontoXY(ponto.dx, ponto.dy), PontoXY(ponto.dx, ponto.dy)],
        cor: widget.color.toARGB32(),
      );
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (widget.tool == DrawTool.selecionar) return;

    final atual = _emAndamento;
    if (atual == null) return;

    final ponto = details.localPosition;

    setState(() {
      if (atual.tipo == FormaTipo.caneta) {
        atual.pontos.add(PontoXY(ponto.dx, ponto.dy));
      } else {
        atual.pontos[1] = PontoXY(ponto.dx, ponto.dy);
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final objeto = _emAndamento;
    _emAndamento = null;
    if (objeto == null) return;
    widget.boardState.desenharLocal(objeto);
  }

  @override
  Widget build(BuildContext context) {
    final objetos = [
      ...widget.boardState.objetos,
      ?_emAndamento,
    ];

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Container(
        color: Colors.white,
        child: CustomPaint(
          painter: _BoardPainter(objetos, _meuSelecionadoId),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter(this.objetos, this.selecionadoId);

  final List<BoardObject> objetos;
  final String? selecionadoId;

  @override
  void paint(Canvas canvas, Size size) {
    for (final objeto in objetos) {
      final pontos = objeto.pontos.map((p) => Offset(p.x, p.y)).toList();
      final paint = Paint()
        ..color = Color(objeto.cor)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      switch (objeto.tipo) {
        case FormaTipo.caneta:
          for (var i = 0; i < pontos.length - 1; i++) {
            canvas.drawLine(pontos[i], pontos[i + 1], paint);
          }
          break;
        case FormaTipo.linha:
          if (pontos.length >= 2) {
            canvas.drawLine(pontos[0], pontos[1], paint);
          }
          break;
        case FormaTipo.quadrado:
          if (pontos.length >= 2) {
            final rect = Rect.fromPoints(pontos[0], pontos[1]);
            if (objeto.corPreenchimento != null) {
              canvas.drawRect(
                rect,
                Paint()
                  ..color = Color(objeto.corPreenchimento!)
                  ..style = PaintingStyle.fill,
              );
            }
            canvas.drawRect(rect, paint);
          }
          break;
        case FormaTipo.circulo:
          if (pontos.length >= 2) {
            final rect = Rect.fromPoints(pontos[0], pontos[1]);
            if (objeto.corPreenchimento != null) {
              canvas.drawOval(
                rect,
                Paint()
                  ..color = Color(objeto.corPreenchimento!)
                  ..style = PaintingStyle.fill,
              );
            }
            canvas.drawOval(rect, paint);
          }
          break;
        case FormaTipo.triangulo:
          if (pontos.length >= 2) {
            final rect = Rect.fromPoints(pontos[0], pontos[1]);
            final path = Path()
              ..moveTo(rect.left + rect.width / 2, rect.top)
              ..lineTo(rect.left, rect.bottom)
              ..lineTo(rect.right, rect.bottom)
              ..close();
            if (objeto.corPreenchimento != null) {
              canvas.drawPath(
                path,
                Paint()
                  ..color = Color(objeto.corPreenchimento!)
                  ..style = PaintingStyle.fill,
              );
            }
            canvas.drawPath(path, paint);
          }
          break;
      }

      if (objeto.id == selecionadoId && pontos.length >= 2) {
        final destaque = Paint()
          ..color = Colors.blueAccent
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawRect(
          Rect.fromPoints(pontos[0], pontos[1]).inflate(6),
          destaque,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) => true;
}
