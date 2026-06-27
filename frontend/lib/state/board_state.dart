/// Estado compartilhado do quadro: objetos desenhados + tabela de locks de
/// seleção. `ChangeNotifier` porque é assim que a UI escuta o estado nesse
/// projeto (ver `provider` em pubspec.yaml).
///
/// Reage tanto a ações locais do usuário (`desenharLocal`, `selecionarLocal`,
/// etc.) quanto a mensagens recebidas da malha (`receber`). Ver
/// `.obsidian/conn-client/exclusao-mutua-lamport.md` pro racional completo
/// da exclusão mútua via Lamport implementada aqui.
library;

import 'package:flutter/foundation.dart';
import 'package:sdwb/core/protocol/lamport_clock.dart';
import 'package:sdwb/core/protocol/message.dart';
import 'package:sdwb/models/board_object.dart';

/// Quem está com o objeto travado, e com qual reivindicação (lamport) isso
/// foi decidido — necessário pra poder reconciliar reivindicações
/// conflitantes que cheguem depois (ver [compararReivindicacoes]).
class LockInfo {
  const LockInfo({required this.donoId, required this.lamport});

  final String donoId;
  final int lamport;
}

class BoardState extends ChangeNotifier {
  BoardState({required this.meuClienteId});

  /// Id deste cliente (usado como `clienteId` nas mensagens de seleção e
  /// como critério de desempate de [compararReivindicacoes]).
  final String meuClienteId;

  final LamportClock relogio = LamportClock();

  final Map<String, BoardObject> _objetos = {};
  final Map<String, LockInfo> _locks = {};

  /// Callback pra mandar uma mensagem pra rede (broadcast pra todos os
  /// membros, ou pro Coordenador no caso de `entrar`/`sair`). Quem injeta
  /// isso é a camada de rede (`coordnator_client.dart`), não o BoardState —
  /// ele só decide *o quê* mandar, não *como* mandar.
  void Function(BoardMessage mensagem)? onEnviar;

  List<BoardObject> get objetos => _objetos.values.toList(growable: false);

  BoardObject? objeto(String objetoId) => _objetos[objetoId];

  String? donoDe(String objetoId) => _locks[objetoId]?.donoId;

  bool estaTravado(String objetoId) => _locks.containsKey(objetoId);

  bool souDonoDe(String objetoId) => donoDe(objetoId) == meuClienteId;

  void _enviar(BoardMessage mensagem) => onEnviar?.call(mensagem);

  // ---- Ações locais (o usuário deste cliente fez algo na UI) -------------

  void desenharLocal(BoardObject objeto) {
    _objetos[objeto.id] = objeto;
    _enviar(DesenharMsg(objeto: objeto));
    notifyListeners();
  }

  /// Tenta selecionar [objetoId]. Devolve `false` sem fazer nada se já
  /// estiver travado por alguém (inclusive por mim mesmo, é idempotente).
  bool selecionarLocal(String objetoId) {
    if (estaTravado(objetoId)) return false;

    final lamport = relogio.tick();
    _locks[objetoId] = LockInfo(donoId: meuClienteId, lamport: lamport);
    _enviar(
      SelecionarMsg(
        objetoId: objetoId,
        clienteId: meuClienteId,
        lamport: lamport,
      ),
    );
    notifyListeners();
    return true;
  }

  void desselecionarLocal(String objetoId) {
    if (!souDonoDe(objetoId)) return;

    final lamport = relogio.tick();
    _locks.remove(objetoId);
    _enviar(
      DesselecionarMsg(
        objetoId: objetoId,
        clienteId: meuClienteId,
        lamport: lamport,
      ),
    );
    notifyListeners();
  }

  void colorirLocal(String objetoId, int cor) {
    if (!souDonoDe(objetoId)) return;
    final objeto = _objetos[objetoId];
    if (objeto == null) return;

    objeto.cor = cor;
    _enviar(ColorirMsg(objetoId: objetoId, cor: cor));
    notifyListeners();
  }

  void preencherLocal(String objetoId, int cor) {
    if (!souDonoDe(objetoId)) return;
    final objeto = _objetos[objetoId];
    if (objeto == null) return;

    objeto.corPreenchimento = cor;
    _enviar(PreencherMsg(objetoId: objetoId, cor: cor));
    notifyListeners();
  }

  void removerLocal(String objetoId) {
    if (!souDonoDe(objetoId)) return;

    _objetos.remove(objetoId);
    _locks.remove(objetoId);
    _enviar(RemoverMsg(objetoId: objetoId));
    notifyListeners();
  }

  // ---- Mensagens recebidas da malha (outros clientes / Coordenador) ------

  void receber(BoardMessage mensagem) {
    switch (mensagem) {
      case DesenharMsg():
        _objetos[mensagem.objeto.id] = mensagem.objeto;
      case ColorirMsg():
        _objetos[mensagem.objetoId]?.cor = mensagem.cor;
      case PreencherMsg():
        _objetos[mensagem.objetoId]?.corPreenchimento = mensagem.cor;
      case RemoverMsg():
        _objetos.remove(mensagem.objetoId);
        _locks.remove(mensagem.objetoId);
      case SelecionarMsg():
        relogio.observar(mensagem.lamport);
        _reconciliarSelecao(mensagem.objetoId, mensagem.clienteId, mensagem.lamport);
      case DesselecionarMsg():
        relogio.observar(mensagem.lamport);
        _receberDesselecionar(mensagem.objetoId, mensagem.clienteId);
      case SyncMsg():
        _receberSync(mensagem);
      default:
        // EntrarMsg/SairMsg/MembroEntrouMsg/MembroSaiu/OkMsg/ErroMsg são
        // tratados pela camada de membresia (coordnator_client.dart), não
        // alteram o estado do quadro em si.
        break;
    }
    notifyListeners();
  }

  /// Aplica a regra de desempate de [compararReivindicacoes] quando chega
  /// uma reivindicação de seleção pra um objeto que já tem (ou não) dono na
  /// tabela local. Ver exemplo completo em
  /// `.obsidian/conn-client/exclusao-mutua-lamport.md`.
  void _reconciliarSelecao(String objetoId, String clienteId, int lamport) {
    final atual = _locks[objetoId];

    if (atual == null) {
      _locks[objetoId] = LockInfo(donoId: clienteId, lamport: lamport);
      return;
    }

    if (atual.donoId == clienteId) return; // mesma reivindicação, sem mudança

    final novaVence =
        compararReivindicacoes(
          lamportA: lamport,
          clienteA: clienteId,
          lamportB: atual.lamport,
          clienteB: atual.donoId,
        ) <
        0;

    if (novaVence) {
      _locks[objetoId] = LockInfo(donoId: clienteId, lamport: lamport);
    }
  }

  void _receberDesselecionar(String objetoId, String clienteId) {
    final atual = _locks[objetoId];
    // só remove se quem está soltando é o mesmo que está marcado como dono
    // localmente — evita que um "desselecionar" atrasado de quem já perdeu
    // a disputa derrube o lock de quem realmente venceu.
    if (atual != null && atual.donoId == clienteId) {
      _locks.remove(objetoId);
    }
  }

  void _receberSync(SyncMsg mensagem) {
    _objetos
      ..clear()
      ..addEntries(mensagem.objetos.map((o) => MapEntry(o.id, o)));
    _locks.clear();
  }
}
