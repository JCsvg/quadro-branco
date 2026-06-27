import 'package:signals/signals_flutter.dart';
import 'package:sdwb/models/sala.dart';
import 'package:sdwb/services/sala_conexao.dart';
import 'package:sdwb/state/board_state.dart';

enum AppRoute { home, view, board, create }

class RouteEntry {
  final AppRoute route;
  final Sala? sala;

  /// Estado do quadro + conexão (Coordenador ou cliente comum) da sala
  /// atual, criados em `create_screen.dart`/`view_screen.dart` antes de
  /// navegar pro board. `null` enquanto não estiver numa sala de verdade.
  final BoardState? boardState;
  final SalaConexao? conexao;

  const RouteEntry(this.route, {this.sala, this.boardState, this.conexao});
}

final currentRoute = signal<RouteEntry>(const RouteEntry(AppRoute.home));

final List<RouteEntry> _routeHistory = [];

void goTo(
  AppRoute route, {
  Sala? sala,
  BoardState? boardState,
  SalaConexao? conexao,
}) {
  _routeHistory.add(currentRoute.value);
  currentRoute.value = RouteEntry(
    route,
    sala: sala,
    boardState: boardState,
    conexao: conexao,
  );
}

bool get canGoBack => _routeHistory.isNotEmpty;

void goBack() {
  if (_routeHistory.isNotEmpty) {
    currentRoute.value = _routeHistory.removeLast();
  }
}
