/// Interface comum entre [CoordinatorServer] (quem criou a sala) e
/// [CoordnatorClient] (quem entrou numa sala existente), pra a UI
/// (`board_screen.dart`, `members_painel.dart`) tratar os dois casos da
/// mesma forma — ela não precisa saber se este nó é o Coordenador ou não.
library;

import 'package:flutter/foundation.dart';
import 'package:sdwb/core/protocol/message.dart';

abstract class SalaConexao extends ChangeNotifier {
  /// Id deste cliente na sala.
  String get meuId;

  /// Lista de membros atualmente na sala (não inclui o Coordenador, a
  /// menos que ele também conste como membro).
  List<MembroInfo> get membros;

  /// Sai da sala de forma organizada (manda `sair`/encerra conexões).
  Future<void> sair();
}
