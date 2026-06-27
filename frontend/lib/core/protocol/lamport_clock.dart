/// Relógio lógico de Lamport — usado pra desempatar seleções concorrentes
/// de objeto sem precisar de um árbitro central (ver `selecionar`/
/// `desselecionar` em `message.dart` e `.obsidian/conn-client.md`).
library;

class LamportClock {
  int _relogio = 0;

  int get valor => _relogio;

  /// Chamar antes de mandar uma mensagem própria. Incrementa e devolve o
  /// novo valor, que vai anexado na mensagem.
  int tick() {
    _relogio += 1;
    return _relogio;
  }

  /// Chamar ao receber uma mensagem de outro peer com o relógio dele
  /// (`recebido`). Alinha o relógio local pra ficar sempre adiante de
  /// qualquer relógio já visto na rede.
  void observar(int recebido) {
    if (recebido > _relogio) {
      _relogio = recebido;
    }
  }
}

/// Compara duas reivindicações de seleção do mesmo objeto e decide quem
/// vence: menor [lamport] primeiro; em caso de empate, menor [clienteId]
/// (ordem léxica) vence. Todo peer aplica a mesma regra, então todos
/// convergem pro mesmo dono mesmo recebendo as mensagens em ordens
/// diferentes.
///
/// Retorna negativo se `a` vence, positivo se `b` vence, 0 só se forem do
/// mesmo cliente (mesma reivindicação).
int compararReivindicacoes({
  required int lamportA,
  required String clienteA,
  required int lamportB,
  required String clienteB,
}) {
  if (lamportA != lamportB) return lamportA - lamportB;
  return clienteA.compareTo(clienteB);
}
