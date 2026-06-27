/// Lado de quem ENTRA numa sala existente (não é o Coordenador).
///
/// Conecta no Coordenador pra entrar/sair e receber a lista de membros
/// (`sync`/`membroEntrou`/`membroSaiu`); sobe seu próprio `ServerSocket` pra
/// aceitar conexões diretas de outros membros (malha); ao saber de um novo
/// membro (via sync ou `membroEntrou`), conecta direto nele também. Todo
/// conteúdo do quadro (desenhar/colorir/etc) é mandado direto pra todos
/// esses peers, sem passar pelo Coordenador — ver
/// `.obsidian/conn-client/visao-geral.md` pro racional completo.
library;

import 'dart:async';
import 'dart:io';

import 'package:sdwb/core/network/tcp_client.dart';
import 'package:sdwb/core/protocol/message.dart';
import 'package:sdwb/services/sala_conexao.dart';
import 'package:sdwb/state/board_state.dart';

class CoordnatorClient extends SalaConexao {
  CoordnatorClient({
    required this.boardState,
    required String meuId,
    required this.meuNome,
  }) : _meuId = meuId;

  final BoardState boardState;
  final String _meuId;
  final String meuNome;

  TcpClient? _coordenador;
  ServerSocket? _servidorLocal;
  final Map<String, TcpClient> _peers = {};
  List<MembroInfo> _membros = [];

  @override
  String get meuId => _meuId;

  @override
  List<MembroInfo> get membros => List.unmodifiable(_membros);

  /// Conecta no Coordenador em [ipCoordenador]:[portaCoordenador] e entra
  /// na sala. Sobe um `ServerSocket` próprio antes de mandar `entrar`, pra
  /// já anunciar onde os outros membros podem te encontrar.
  Future<void> entrarNaSala({
    required String ipCoordenador,
    required int portaCoordenador,
  }) async {
    _servidorLocal = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    _servidorLocal!.listen(_aoReceberConexaoDeMembro);

    final meuIp = await TcpClient.ipLocal();

    _coordenador = await TcpClient.conectar(ipCoordenador, portaCoordenador);
    _coordenador!.linhas.listen(_aoReceberDoCoordenador);

    boardState.onEnviar = _enviarParaTodos;

    _coordenador!.enviarLinha(
      codificarMensagem(
        EntrarMsg(
          nome: meuNome,
          clienteId: meuId,
          ip: meuIp,
          porta: _servidorLocal!.port,
        ),
      ),
    );
  }

  void _aoReceberDoCoordenador(String linha) {
    final BoardMessage mensagem;
    try {
      mensagem = decodificarMensagem(linha);
    } catch (_) {
      return;
    }

    if (mensagem is SyncMsg) {
      _membros = mensagem.membros;
      boardState.receber(mensagem);
      for (final membro in _membros) {
        _conectarPeer(membro);
      }
      notifyListeners();
    } else if (mensagem is MembroEntrouMsg) {
      _membros = [..._membros, mensagem.membro];
      _conectarPeer(mensagem.membro);
      notifyListeners();
    } else if (mensagem is MembroSaiuMsg) {
      final idQueSaiu = mensagem.membroId;
      _membros = _membros.where((m) => m.id != idQueSaiu).toList();
      _peers.remove(idQueSaiu)?.destruir();
      notifyListeners();
    } else {
      // Conteúdo do quadro (desenhar/colorir/preencher/remover/selecionar/
      // desselecionar) — o Coordenador também é um peer da malha, então
      // pode mandar isso pela mesma conexão usada pra entrar/sair.
      boardState.receber(mensagem);
    }
  }

  Future<void> _conectarPeer(MembroInfo info) async {
    if (info.id == meuId || _peers.containsKey(info.id)) return;
    try {
      final tcp = await TcpClient.conectar(info.ip, info.porta);
      _peers[info.id] = tcp;
      tcp.linhas.listen((linha) => _aoReceberDePeer(linha));
    } catch (_) {
      // Peer pode ter caído antes de conseguirmos conectar — sem retry por
      // ora (fica pra quando a eleição/heartbeat existir).
    }
  }

  void _aoReceberConexaoDeMembro(Socket socket) {
    final tcp = TcpClient.deSocket(socket);
    tcp.linhas.listen((linha) => _aoReceberDePeer(linha));
  }

  void _aoReceberDePeer(String linha) {
    try {
      boardState.receber(decodificarMensagem(linha));
    } catch (_) {
      // ignora mensagem malformada, não derruba a conexão.
    }
  }

  void _enviarParaTodos(BoardMessage mensagem) {
    final linha = codificarMensagem(mensagem);
    _coordenador?.enviarLinha(linha);
    for (final peer in _peers.values) {
      peer.enviarLinha(linha);
    }
  }

  bool _saiu = false;

  @override
  Future<void> sair() async {
    if (_saiu) return;
    _saiu = true;

    try {
      _coordenador?.enviarLinha(codificarMensagem(const SairMsg()));
      await _coordenador?.fechar();
    } catch (_) {
      // conexão com o Coordenador já pode ter caído — tudo bem, estamos saindo.
    }
    for (final peer in _peers.values) {
      peer.destruir();
    }
    _peers.clear();
    await _servidorLocal?.close();
  }
}
