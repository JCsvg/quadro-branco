import 'package:signals/signals_flutter.dart';
import 'package:sdwb/models/sala.dart';

enum AppRoute { home, view, board, create }

class RouteEntry {
  final AppRoute route;
  final Sala? sala;

  const RouteEntry(this.route, {this.sala});
}

final currentRoute = signal<RouteEntry>(const RouteEntry(AppRoute.home));

final List<RouteEntry> _routeHistory = [];

void goTo(AppRoute route, {Sala? sala}) {
  _routeHistory.add(currentRoute.value);
  currentRoute.value = RouteEntry(route, sala: sala);
}

bool get canGoBack => _routeHistory.isNotEmpty;

void goBack() {
  if (_routeHistory.isNotEmpty) {
    currentRoute.value = _routeHistory.removeLast();
  }
}
