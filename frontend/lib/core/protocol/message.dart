/// Protocolo de mensagens do quadro distribuído.
///
/// Mesma convenção do Serviço de Nomes (`backend/src/protocolo.py`): cada
/// mensagem é um objeto JSON com campo "tipo", em uma linha terminada por
/// '\n'.
///
/// Cliente -> Coordenador (entrada/saída da sala, exigem uma autoridade
/// única que aceita conexões e mantém a lista de membros). `ip`/`porta` em
/// `entrar` são o endereço onde o próprio cliente está escutando, pra
/// outros membros conseguirem abrir conexão direta com ele (malha):
///   {"tipo": "entrar", "nome": "Lucas M.", "clienteId": "...", "ip": "192.168.0.5", "porta": 5001}
///   {"tipo": "sair"}
///
/// Coordenador -> Cliente(s):
///   {"tipo": "sync", "membroId": "...", "objetos": [...], "membros": [{"id":..., "nome":..., "ip":..., "porta":...}]}
///   {"tipo": "membroEntrou", "membro": {"id":..., "nome":..., "ip":..., "porta":...}}
///   {"tipo": "membroSaiu", "membroId": "..."}
///
/// Cliente -> TODOS os membros da sala, broadcast direto (sem passar pelo
/// Coordenador — ver `.obsidian/conn-client.md` pro motivo da escolha):
///   {"tipo": "desenhar", "objeto": {...BoardObject}}
///   {"tipo": "colorir", "objetoId": "...", "cor": 4283215696}
///   {"tipo": "preencher", "objetoId": "...", "cor": 4283215696}
///   {"tipo": "remover", "objetoId": "..."}
///   {"tipo": "selecionar", "objetoId": "...", "clienteId": "...", "lamport": 5}
///   {"tipo": "desselecionar", "objetoId": "...", "clienteId": "...", "lamport": 6}
///
/// `selecionar`/`desselecionar` carregam um timestamp lógico de Lamport
/// (`lamport`) + o id de quem mandou, pra cada peer conseguir desempatar de
/// forma determinística duas seleções conflitantes do mesmo objeto sem
/// precisar de um árbitro central (ver [LamportClock]).
///
/// Comuns:
///   {"tipo": "ok"}
///   {"tipo": "erro", "mensagem": "..."}
library;

import 'dart:convert';

import 'package:sdwb/models/board_object.dart';

class ErroProtocolo implements Exception {
  ErroProtocolo(this.mensagem);

  final String mensagem;

  @override
  String toString() => 'ErroProtocolo: $mensagem';
}

class MembroInfo {
  const MembroInfo({
    required this.id,
    required this.nome,
    required this.ip,
    required this.porta,
  });

  final String id;
  final String nome;

  /// Endereço onde esse membro está escutando, pra outros conseguirem
  /// abrir conexão direta com ele (malha).
  final String ip;
  final int porta;

  factory MembroInfo.fromJson(Map<String, dynamic> json) => MembroInfo(
    id: json['id'] as String,
    nome: json['nome'] as String,
    ip: json['ip'] as String,
    porta: json['porta'] as int,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'ip': ip,
    'porta': porta,
  };
}

abstract class BoardMessage {
  const BoardMessage();

  String get tipo;

  Map<String, dynamic> toJson();
}

dynamic _exigir(Map<String, dynamic> json, String campo) {
  if (!json.containsKey(campo)) {
    throw ErroProtocolo("campo obrigatório ausente: '$campo'");
  }
  return json[campo];
}

/// Decodifica uma linha de texto recebida do socket em uma [BoardMessage].
BoardMessage decodificarMensagem(String linha) {
  linha = linha.trim();
  if (linha.isEmpty) {
    throw ErroProtocolo('mensagem vazia');
  }

  final Map<String, dynamic> json;
  try {
    json = jsonDecode(linha) as Map<String, dynamic>;
  } on FormatException catch (e) {
    throw ErroProtocolo('JSON inválido: $e');
  }

  final tipo = _exigir(json, 'tipo') as String;
  switch (tipo) {
    case 'entrar':
      return EntrarMsg(
        nome: _exigir(json, 'nome') as String,
        clienteId: _exigir(json, 'clienteId') as String,
        ip: _exigir(json, 'ip') as String,
        porta: _exigir(json, 'porta') as int,
      );
    case 'sair':
      return const SairMsg();
    case 'desenhar':
      return DesenharMsg(
        objeto: BoardObject.fromJson(
          _exigir(json, 'objeto') as Map<String, dynamic>,
        ),
      );
    case 'selecionar':
      return SelecionarMsg(
        objetoId: _exigir(json, 'objetoId') as String,
        clienteId: _exigir(json, 'clienteId') as String,
        lamport: _exigir(json, 'lamport') as int,
      );
    case 'desselecionar':
      return DesselecionarMsg(
        objetoId: _exigir(json, 'objetoId') as String,
        clienteId: _exigir(json, 'clienteId') as String,
        lamport: _exigir(json, 'lamport') as int,
      );
    case 'colorir':
      return ColorirMsg(
        objetoId: _exigir(json, 'objetoId') as String,
        cor: _exigir(json, 'cor') as int,
      );
    case 'preencher':
      return PreencherMsg(
        objetoId: _exigir(json, 'objetoId') as String,
        cor: _exigir(json, 'cor') as int,
      );
    case 'remover':
      return RemoverMsg(objetoId: _exigir(json, 'objetoId') as String);
    case 'sync':
      return SyncMsg(
        membroId: _exigir(json, 'membroId') as String,
        objetos: (_exigir(json, 'objetos') as List)
            .map((o) => BoardObject.fromJson(o as Map<String, dynamic>))
            .toList(),
        membros: (_exigir(json, 'membros') as List)
            .map((m) => MembroInfo.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
    case 'membroEntrou':
      return MembroEntrouMsg(
        membro: MembroInfo.fromJson(
          _exigir(json, 'membro') as Map<String, dynamic>,
        ),
      );
    case 'membroSaiu':
      return MembroSaiuMsg(membroId: _exigir(json, 'membroId') as String);
    case 'ok':
      return const OkMsg();
    case 'erro':
      return ErroMsg(mensagem: _exigir(json, 'mensagem') as String);
    default:
      throw ErroProtocolo("tipo desconhecido: '$tipo'");
  }
}

/// Serializa uma [BoardMessage] como linha JSON pronta para o socket.
String codificarMensagem(BoardMessage msg) => '${jsonEncode(msg.toJson())}\n';

// ---- Cliente -> Coordenador ----------------------------------------------

class EntrarMsg extends BoardMessage {
  EntrarMsg({
    required this.nome,
    required this.clienteId,
    required this.ip,
    required this.porta,
  });

  final String nome;
  final String clienteId;

  /// Endereço onde quem está entrando vai escutar conexões diretas de
  /// outros membros (malha).
  final String ip;
  final int porta;

  @override
  String get tipo => 'entrar';

  @override
  Map<String, dynamic> toJson() => {
    'tipo': tipo,
    'nome': nome,
    'clienteId': clienteId,
    'ip': ip,
    'porta': porta,
  };
}

class SairMsg extends BoardMessage {
  const SairMsg();

  @override
  String get tipo => 'sair';

  @override
  Map<String, dynamic> toJson() => {'tipo': tipo};
}

// ---- Cliente -> todos os membros (broadcast direto) ----------------------

class DesenharMsg extends BoardMessage {
  DesenharMsg({required this.objeto});

  final BoardObject objeto;

  @override
  String get tipo => 'desenhar';

  @override
  Map<String, dynamic> toJson() => {'tipo': tipo, 'objeto': objeto.toJson()};
}

/// Anuncia pra todos que [clienteId] está selecionando [objetoId].
///
/// [lamport] é o relógio lógico de quem mandou (ver [LamportClock]). Cada
/// peer que receber dois `selecionar` conflitantes pro mesmo objeto deve
/// aplicar sempre a mesma regra de desempate: menor [lamport] vence; em
/// caso de empate, menor [clienteId] vence. Assim todos os peers convergem
/// pro mesmo dono, mesmo recebendo as mensagens em ordens diferentes.
class SelecionarMsg extends BoardMessage {
  SelecionarMsg({
    required this.objetoId,
    required this.clienteId,
    required this.lamport,
  });

  final String objetoId;
  final String clienteId;
  final int lamport;

  @override
  String get tipo => 'selecionar';

  @override
  Map<String, dynamic> toJson() => {
    'tipo': tipo,
    'objetoId': objetoId,
    'clienteId': clienteId,
    'lamport': lamport,
  };
}

class DesselecionarMsg extends BoardMessage {
  DesselecionarMsg({
    required this.objetoId,
    required this.clienteId,
    required this.lamport,
  });

  final String objetoId;
  final String clienteId;
  final int lamport;

  @override
  String get tipo => 'desselecionar';

  @override
  Map<String, dynamic> toJson() => {
    'tipo': tipo,
    'objetoId': objetoId,
    'clienteId': clienteId,
    'lamport': lamport,
  };
}

class ColorirMsg extends BoardMessage {
  ColorirMsg({required this.objetoId, required this.cor});

  final String objetoId;
  final int cor;

  @override
  String get tipo => 'colorir';

  @override
  Map<String, dynamic> toJson() => {
    'tipo': tipo,
    'objetoId': objetoId,
    'cor': cor,
  };
}

class PreencherMsg extends BoardMessage {
  PreencherMsg({required this.objetoId, required this.cor});

  final String objetoId;
  final int cor;

  @override
  String get tipo => 'preencher';

  @override
  Map<String, dynamic> toJson() => {
    'tipo': tipo,
    'objetoId': objetoId,
    'cor': cor,
  };
}

class RemoverMsg extends BoardMessage {
  RemoverMsg({required this.objetoId});

  final String objetoId;

  @override
  String get tipo => 'remover';

  @override
  Map<String, dynamic> toJson() => {'tipo': tipo, 'objetoId': objetoId};
}

// ---- Coordenador -> Cliente(s) --------------------------------------------

class SyncMsg extends BoardMessage {
  SyncMsg({
    required this.membroId,
    required this.objetos,
    required this.membros,
  });

  final String membroId;
  final List<BoardObject> objetos;
  final List<MembroInfo> membros;

  @override
  String get tipo => 'sync';

  @override
  Map<String, dynamic> toJson() => {
    'tipo': tipo,
    'membroId': membroId,
    'objetos': objetos.map((o) => o.toJson()).toList(),
    'membros': membros.map((m) => m.toJson()).toList(),
  };
}

class MembroEntrouMsg extends BoardMessage {
  MembroEntrouMsg({required this.membro});

  final MembroInfo membro;

  @override
  String get tipo => 'membroEntrou';

  @override
  Map<String, dynamic> toJson() => {'tipo': tipo, 'membro': membro.toJson()};
}

class MembroSaiuMsg extends BoardMessage {
  MembroSaiuMsg({required this.membroId});

  final String membroId;

  @override
  String get tipo => 'membroSaiu';

  @override
  Map<String, dynamic> toJson() => {'tipo': tipo, 'membroId': membroId};
}

// ---- Comuns ----------------------------------------------------------------

class OkMsg extends BoardMessage {
  const OkMsg();

  @override
  String get tipo => 'ok';

  @override
  Map<String, dynamic> toJson() => {'tipo': tipo};
}

class ErroMsg extends BoardMessage {
  ErroMsg({required this.mensagem});

  final String mensagem;

  @override
  String get tipo => 'erro';

  @override
  Map<String, dynamic> toJson() => {'tipo': tipo, 'mensagem': mensagem};
}
