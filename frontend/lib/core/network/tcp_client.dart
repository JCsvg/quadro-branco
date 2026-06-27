/// Wrapper genérico sobre `dart:io` `Socket`, no mesmo formato usado em
/// todo o protocolo do projeto: uma mensagem por linha, terminada em '\n'
/// (ver `backend/src/servidor.py` e `core/protocol/message.dart`).
///
/// Reusado tanto pra falar com o Serviço de Nomes quanto pra falar com
/// outros membros/Coordenador do quadro — cada uso decodifica as linhas
/// com o protocolo apropriado (são protocolos diferentes, só o transporte é
/// o mesmo). Ver `.obsidian/conn-back/name-service-client.md`.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

class TcpClient {
  TcpClient._(this._socket) {
    _linhas = _socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .asBroadcastStream();
  }

  final Socket _socket;
  late final Stream<String> _linhas;

  static Future<TcpClient> conectar(
    String host,
    int porta, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final socket = await Socket.connect(host, porta, timeout: timeout);
    socket.setOption(SocketOption.tcpNoDelay, true);
    return TcpClient._(socket);
  }

  /// Envolve um [Socket] já conectado (usado pelo lado que faz `accept()`,
  /// como o Coordenador, em vez de `connect()`).
  factory TcpClient.deSocket(Socket socket) {
    socket.setOption(SocketOption.tcpNoDelay, true);
    return TcpClient._(socket);
  }

  /// Stream de linhas já decodificadas em texto (sem o '\n' final). Pode
  /// ter múltiplos listeners (`asBroadcastStream`).
  Stream<String> get linhas => _linhas;

  InternetAddress get enderecoRemoto => _socket.remoteAddress;
  int get portaRemota => _socket.remotePort;

  void enviarLinha(String linha) => _socket.write('$linha\n');

  Future<void> fechar() async {
    await _socket.flush();
    await _socket.close();
  }

  void destruir() => _socket.destroy();

  /// Descobre o IP de rede local desta máquina (não-loopback), pra
  /// registrar no Serviço de Nomes e anunciar pros outros membros da malha.
  /// Se não achar nenhuma interface de rede, cai pro loopback (útil pra
  /// testar tudo numa máquina só).
  static Future<String> ipLocal() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    for (final interface in interfaces) {
      for (final endereco in interface.addresses) {
        if (!endereco.isLoopback) return endereco.address;
      }
    }
    return InternetAddress.loopbackIPv4.address;
  }
}
