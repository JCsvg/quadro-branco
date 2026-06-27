/// Representação de um objeto do quadro independente da UI (sem
/// dependência de `package:flutter`), para poder ser serializada no
/// protocolo de rede e usada tanto pelo cliente quanto pelo coordenador.
library;

enum FormaTipo { caneta, linha, circulo, quadrado, triangulo }

FormaTipo formaTipoFromString(String valor) =>
    FormaTipo.values.firstWhere((f) => f.name == valor);

class PontoXY {
  const PontoXY(this.x, this.y);

  final double x;
  final double y;

  factory PontoXY.fromJson(Map<String, dynamic> json) =>
      PontoXY((json['x'] as num).toDouble(), (json['y'] as num).toDouble());

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
}

class BoardObject {
  BoardObject({
    required this.id,
    required this.tipo,
    required this.pontos,
    required this.cor,
    this.corPreenchimento,
  });

  /// Identificador único do objeto, gerado pelo cliente que o criou (uuid).
  final String id;
  final FormaTipo tipo;
  final List<PontoXY> pontos;

  /// Cor do traço/contorno, como inteiro ARGB (`Color.value` no Flutter).
  int cor;

  /// Cor de preenchimento (só faz sentido para formas fechadas), também ARGB.
  int? corPreenchimento;

  factory BoardObject.fromJson(Map<String, dynamic> json) => BoardObject(
    id: json['id'] as String,
    tipo: formaTipoFromString(json['forma'] as String),
    pontos: (json['pontos'] as List)
        .map((p) => PontoXY.fromJson(p as Map<String, dynamic>))
        .toList(),
    cor: json['cor'] as int,
    corPreenchimento: json['corPreenchimento'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'forma': tipo.name,
    'pontos': pontos.map((p) => p.toJson()).toList(),
    'cor': cor,
    if (corPreenchimento != null) 'corPreenchimento': corPreenchimento,
  };
}
