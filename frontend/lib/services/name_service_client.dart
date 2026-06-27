/// Cliente do Serviço de Nomes (backend Python, `backend/src/protocolo.py`).
///
/// Fala um protocolo próprio (registrar/listar/remover), diferente do
/// `core/protocol/message.dart` do quadro — ver
/// `.obsidian/conn-back/name-service-client.md`.
library;

import 'dart:convert';

import 'package:sdwb/core/network/tcp_client.dart';
import 'package:sdwb/models/sala.dart';

/// Porta padrão do Serviço de Nomes (`NS_PORT` em `backend/src/config.py`).
const kPortaServicoDeNomes = 9000;

class NameServiceClient {
  NameServiceClient(this._tcp);

  final TcpClient _tcp;

  static Future<NameServiceClient> conectar(
    String host, {
    int porta = kPortaServicoDeNomes,
  }) async {
    final tcp = await TcpClient.conectar(host, porta);
    return NameServiceClient(tcp);
  }

  /// Descobre o Serviço de Nomes sem precisar configurar host na mão:
  /// tenta primeiro o IP de rede local desta máquina (`TcpClient.ipLocal()`
  /// — funciona quando o backend roda na mesma máquina que o cliente,
  /// inclusive ao testar tudo num computador só, já que conectar na sua
  /// própria interface de rede funciona normalmente). Se isso falhar (ex:
  /// a interface detectada não é por onde o backend está acessível), cai
  /// pra `localhost`.
  ///
  /// Isso não é descoberta de serviço de verdade (não tem broadcast/mDNS) —
  /// só elimina a necessidade de editar um host fixo no código pro caso
  /// comum de testar localmente. Pra rodar em máquinas de fato diferentes
  /// na rede, ainda é preciso que o cliente saiba o IP de quem roda o
  /// backend (parâmetro [hostManual]).
  static Future<NameServiceClient> conectarAutomatico({
    int porta = kPortaServicoDeNomes,
    String? hostManual,
  }) async {
    if (hostManual != null) {
      return conectar(hostManual, porta: porta);
    }

    final ipLocal = await TcpClient.ipLocal();
    try {
      return await conectar(ipLocal, porta: porta);
    } catch (_) {
      return conectar('localhost', porta: porta);
    }
  }

  Future<void> registrar({
    required String nome,
    required String ip,
    required int porta,
  }) async {
    final resposta = await _enviarEReceber({
      'tipo': 'registrar',
      'nome': nome,
      'ip': ip,
      'porta': porta,
    });
    _verificarErro(resposta);
  }

  Future<List<Sala>> listar() async {
    final resposta = await _enviarEReceber({'tipo': 'listar'});
    _verificarErro(resposta);
    return (resposta['salas'] as List)
        .map(
          (s) => Sala(
            nome: s['nome'] as String,
            ip: s['ip'] as String,
            porta: s['porta'] as int,
            ativos: 0,
          ),
        )
        .toList();
  }

  Future<void> remover(String nome) async {
    final resposta = await _enviarEReceber({'tipo': 'remover', 'nome': nome});
    _verificarErro(resposta);
  }

  Future<Map<String, dynamic>> _enviarEReceber(
    Map<String, dynamic> mensagem,
  ) async {
    _tcp.enviarLinha(jsonEncode(mensagem));
    final linha = await _tcp.linhas.first;
    return jsonDecode(linha) as Map<String, dynamic>;
  }

  void _verificarErro(Map<String, dynamic> resposta) {
    if (resposta['tipo'] == 'erro') {
      throw Exception(resposta['mensagem'] as String?);
    }
  }

  Future<void> fechar() => _tcp.fechar();
}
