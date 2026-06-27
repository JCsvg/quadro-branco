/// Coordenador do Quadro — roda no cliente que criou a sala (cargo
/// migrante, ver `.obsidian/conn-client/visao-geral.md`).
///
/// Aceita conexões de novos membros (`entrar`/`sair`), manda o snapshot do
/// quadro (`sync`) pra quem entra e avisa os outros membros quando alguém
/// entra/sai. Mensagens de conteúdo do quadro (desenhar/colorir/etc) que
/// chegarem por essas conexões são só espelhadas no [BoardState] local — o
/// Coordenador NÃO retransmite, porque a propagação é em malha (cada
/// cliente já manda direto pra todo mundo, ver `.obsidian/conn-client/`).
library;

import 'dart:async';
import 'dart:io';

import 'package:sdwb/core/network/tcp_client.dart';
import 'package:sdwb/core/protocol/message.dart';
import 'package:sdwb/services/sala_conexao.dart';
import 'package:sdwb/state/board_state.dart';

class _MembroConectado {
  _MembroConectado({required this.info, required this.tcp, this.sub});

  final MembroInfo info;
  final TcpClient tcp;
  StreamSubscription<String>? sub;
}

class CoordinatorServer extends SalaConexao {
  CoordinatorServer({required this.boardState, required String meuId})
    : _meuId = meuId;

  final BoardState boardState;
  final String _meuId;

  ServerSocket? _servidor;
  final Map<String, _MembroConectado> _membros = {};

  @override
  String get meuId => _meuId;

  /// Porta onde o Coordenador está escutando — só disponível depois de
  /// [iniciar]. É o valor que vai pro Serviço de Nomes.
  int get porta => _servidor!.port;

  @override
  List<MembroInfo> get membros =>
      _membros.values.map((m) => m.info).toList(growable: false);

  /// Sobe o `ServerSocket`. Se [porta] for 0 (padrão), o sistema escolhe
  /// uma porta livre automaticamente.
  Future<void> iniciar({int porta = 0}) async {
    _servidor = await ServerSocket.bind(InternetAddress.anyIPv4, porta);
    _servidor!.listen(_aoConectar);

    // O Coordenador também é um peer na malha: quando o usuário deste nó
    // desenha/seleciona/etc, isso precisa chegar nos outros membros direto,
    // do mesmo jeito que `coordnator_client.dart` faz pro lado de quem
    // entrou numa sala existente.
    boardState.onEnviar = _enviarParaTodosOsMembros;
  }

  void _enviarParaTodosOsMembros(BoardMessage mensagem) {
    final linha = codificarMensagem(mensagem);
    for (final m in _membros.values) {
      m.tcp.enviarLinha(linha);
    }
  }

  void _aoConectar(Socket socket) {
    final tcp = TcpClient.deSocket(socket);
    final conectado = _ConexaoPendente(tcp);

    conectado.sub = tcp.linhas.listen(
      (linha) => _aoReceberLinha(conectado, linha),
      onDone: () => _removerMembro(conectado.membroId),
      onError: (_) => _removerMembro(conectado.membroId),
    );
  }

  void _aoReceberLinha(_ConexaoPendente conectado, String linha) {
    final BoardMessage mensagem;
    try {
      mensagem = decodificarMensagem(linha);
    } catch (_) {
      return; // mensagem malformada — ignora, não derruba a conexão.
    }

    if (mensagem is EntrarMsg) {
      _aoEntrar(conectado, mensagem);
    } else if (mensagem is SairMsg) {
      _removerMembro(conectado.membroId);
    } else {
      // Conteúdo do quadro (desenhar/colorir/preencher/remover/selecionar/
      // desselecionar): só espelha no estado local, sem retransmitir.
      boardState.receber(mensagem);
    }
  }

  void _aoEntrar(_ConexaoPendente conectado, EntrarMsg msg) {
    final info = MembroInfo(
      id: msg.clienteId,
      nome: msg.nome,
      ip: msg.ip,
      porta: msg.porta,
    );
    conectado.membroId = info.id;
    _membros[info.id] = _MembroConectado(
      info: info,
      tcp: conectado.tcp,
      sub: conectado.sub,
    );

    conectado.tcp.enviarLinha(
      codificarMensagem(
        SyncMsg(
          membroId: info.id,
          objetos: boardState.objetos,
          membros: membros,
        ),
      ),
    );

    _broadcastExceto(info.id, MembroEntrouMsg(membro: info));
    notifyListeners();
  }

  void _removerMembro(String? id) {
    if (id == null) return;
    final removido = _membros.remove(id);
    if (removido != null) {
      _broadcastExceto(id, MembroSaiuMsg(membroId: id));
      notifyListeners();
    }
  }

  void _broadcastExceto(String idExcluido, BoardMessage mensagem) {
    final linha = codificarMensagem(mensagem);
    for (final m in _membros.values) {
      if (m.info.id != idExcluido) m.tcp.enviarLinha(linha);
    }
  }

  @override
  Future<void> sair() => encerrar();

  bool _encerrado = false;

  /// Encerra o servidor e todas as conexões — usado quando o cliente que
  /// criou a sala sai (nesse ponto, sem eleição implementada ainda, a sala
  /// fica indisponível pra novos membros).
  Future<void> encerrar() async {
    if (_encerrado) return;
    _encerrado = true;

    for (final m in _membros.values) {
      await m.sub?.cancel();
      m.tcp.destruir();
    }
    _membros.clear();
    await _servidor?.close();
  }
}

/// Conexão aceita mas que ainda não mandou `entrar` — guarda a subscription
/// pra poder cancelar e o id do membro assim que ele se identificar.
class _ConexaoPendente {
  _ConexaoPendente(this.tcp);

  final TcpClient tcp;
  StreamSubscription<String>? sub;
  String? membroId;
}
