import 'package:flutter_test/flutter_test.dart';
import 'package:sdwb/core/network/tcp_client.dart';
import 'package:sdwb/services/coordinator_server.dart';
import 'package:sdwb/services/coordnator_client.dart';
import 'package:sdwb/services/name_service_client.dart';
import 'package:sdwb/state/board_state.dart';

void main() {
  test('criar sala, registrar no Serviço de Nomes e outro cliente entrar', () async {
    final boardCoordenador = BoardState(meuClienteId: 'coord-1');
    final coordenador = CoordinatorServer(
      boardState: boardCoordenador,
      meuId: 'coord-1',
    );
    await coordenador.iniciar();
    addTearDown(coordenador.encerrar);

    final ip = await TcpClient.ipLocal();

    final nameService = await NameServiceClient.conectarAutomatico();
    await nameService.registrar(
      nome: 'sala-teste',
      ip: ip,
      porta: coordenador.porta,
    );

    final salas = await nameService.listar();
    await nameService.fechar();

    expect(salas.any((s) => s.nome == 'sala-teste'), isTrue);

    final boardMembro = BoardState(meuClienteId: 'membro-1');
    final cliente = CoordnatorClient(
      boardState: boardMembro,
      meuId: 'membro-1',
      meuNome: 'Lucas M.',
    );
    addTearDown(cliente.sair);

    await cliente.entrarNaSala(
      ipCoordenador: ip,
      portaCoordenador: coordenador.porta,
    );

    await Future.delayed(const Duration(milliseconds: 300));

    expect(cliente.membros.any((m) => m.id == 'membro-1'), isTrue);
    expect(coordenador.membros.any((m) => m.id == 'membro-1'), isTrue);

    await cliente.sair();
    await Future.delayed(const Duration(milliseconds: 300));

    expect(coordenador.membros.any((m) => m.id == 'membro-1'), isFalse);
  });
}
