import 'package:flutter/material.dart';

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

class Stroke {
  Stroke({
    required this.tool,
    required this.color,
    List<Offset>? points,
    this.fillColor,
  }) : points = points ?? [];

  final DrawTool tool;
  Color color;
  Color? fillColor;
  final List<Offset> points;
}

class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas({
    super.key,
    required this.tool,
    required this.color,
    this.onSelecaoMudou,
  });

  final DrawTool tool;
  final Color color;
  final ValueChanged<bool>? onSelecaoMudou;

  @override
  DrawingCanvasState createState() => DrawingCanvasState();
}

class DrawingCanvasState extends State<DrawingCanvas> {
  final List<Stroke> _strokes = [];
  Stroke? _emAndamento;
  Stroke? _selecionado;

  void removerSelecionado() {
    if (_selecionado == null) return;
    setState(() {
      _strokes.remove(_selecionado);
      _selecionado = null;
    });
    widget.onSelecaoMudou?.call(false);
  }

  void limparSelecao() {
    if (_selecionado == null) return;
    setState(() => _selecionado = null);
    widget.onSelecaoMudou?.call(false);
  }

  void colorirSelecionado(Color cor) {
    final s = _selecionado;
    if (s == null) return;
    setState(() => s.color = cor);
  }

  void preencherSelecionado(Color cor) {
    final s = _selecionado;
    if (s == null || !kFormasFechadas.contains(s.tool)) return;
    setState(() => s.fillColor = cor);
  }

  bool _hitTest(Stroke s, Offset ponto) {
    switch (s.tool) {
      case DrawTool.pen:
        return s.points.any((p) => (p - ponto).distance < 14);
      case DrawTool.line:
        if (s.points.length < 2) return false;
        return _distanciaSegmento(ponto, s.points[0], s.points[1]) < 14;
      case DrawTool.square:
      case DrawTool.circle:
      case DrawTool.triangle:
        if (s.points.length < 2) return false;
        return Rect.fromPoints(
          s.points[0],
          s.points[1],
        ).inflate(8).contains(ponto);
      case DrawTool.selecionar:
        return false;
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
    Stroke? encontrado;
    for (final s in _strokes.reversed) {
      if (_hitTest(s, ponto)) {
        encontrado = s;
        break;
      }
    }
    setState(() => _selecionado = encontrado);
    widget.onSelecaoMudou?.call(encontrado != null);
  }

  void _onPanStart(DragStartDetails details) {
    final ponto = details.localPosition;

    if (widget.tool == DrawTool.selecionar) {
      _selecionarNoPonto(ponto);
      return;
    }

    setState(() {
      _emAndamento = Stroke(
        tool: widget.tool,
        color: widget.color,
        points: [ponto, ponto],
      );
      _strokes.add(_emAndamento!);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (widget.tool == DrawTool.selecionar) return;

    final atual = _emAndamento;
    if (atual == null) return;

    final ponto = details.localPosition;

    setState(() {
      if (atual.tool == DrawTool.pen) {
        atual.points.add(ponto);
      } else {
        atual.points[1] = ponto;
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _emAndamento = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Container(
        color: Colors.white,
        child: CustomPaint(
          painter: _BoardPainter(_strokes, _selecionado),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter(this.strokes, this.selecionado);

  final List<Stroke> strokes;
  final Stroke? selecionado;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      switch (stroke.tool) {
        case DrawTool.pen:
          for (var i = 0; i < stroke.points.length - 1; i++) {
            canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
          }
          break;
        case DrawTool.line:
          if (stroke.points.length >= 2) {
            canvas.drawLine(stroke.points[0], stroke.points[1], paint);
          }
          break;
        case DrawTool.square:
          if (stroke.points.length >= 2) {
            final rect = Rect.fromPoints(stroke.points[0], stroke.points[1]);
            if (stroke.fillColor != null) {
              canvas.drawRect(
                rect,
                Paint()
                  ..color = stroke.fillColor!
                  ..style = PaintingStyle.fill,
              );
            }
            canvas.drawRect(rect, paint);
          }
          break;
        case DrawTool.circle:
          if (stroke.points.length >= 2) {
            final rect = Rect.fromPoints(stroke.points[0], stroke.points[1]);
            if (stroke.fillColor != null) {
              canvas.drawOval(
                rect,
                Paint()
                  ..color = stroke.fillColor!
                  ..style = PaintingStyle.fill,
              );
            }
            canvas.drawOval(rect, paint);
          }
          break;
        case DrawTool.triangle:
          if (stroke.points.length >= 2) {
            final rect = Rect.fromPoints(stroke.points[0], stroke.points[1]);
            final path = Path()
              ..moveTo(rect.left + rect.width / 2, rect.top)
              ..lineTo(rect.left, rect.bottom)
              ..lineTo(rect.right, rect.bottom)
              ..close();
            if (stroke.fillColor != null) {
              canvas.drawPath(
                path,
                Paint()
                  ..color = stroke.fillColor!
                  ..style = PaintingStyle.fill,
              );
            }
            canvas.drawPath(path, paint);
          }
          break;
        case DrawTool.selecionar:
          break;
      }

      if (stroke == selecionado && stroke.points.length >= 2) {
        final destaque = Paint()
          ..color = Colors.blueAccent
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawRect(
          Rect.fromPoints(
            stroke.points[0],
            stroke.points[1],
          ).inflate(6),
          destaque,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) => true;
}
