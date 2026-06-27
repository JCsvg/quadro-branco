import 'package:flutter_test/flutter_test.dart';
import 'package:sdwb/models/board_object.dart';
import 'package:sdwb/services/coordinator_server.dart';
import 'package:sdwb/services/coordnator_client.dart';
import 'package:sdwb/state/board_state.dart';

Future<void> _aguardarPropagacao() =>
    Future.delayed(const Duration(milliseconds: 300));

void main() {
  test(
    'desenho feito por quem criou a sala chega no membro, e vice-versa',
    () async {
      final boardCoordenador = BoardState(meuClienteId: 'coord-1');
      final coordenador = CoordinatorServer(
        boardState: boardCoordenador,
        meuId: 'coord-1',
      );
      await coordenador.iniciar();
      addTearDown(coordenador.encerrar);

      final boardMembro = BoardState(meuClienteId: 'membro-1');
      final cliente = CoordnatorClient(
        boardState: boardMembro,
        meuId: 'membro-1',
        meuNome: 'Lucas M.',
      );
      addTearDown(cliente.sair);

      await cliente.entrarNaSala(
        ipCoordenador: kIpDeTeste,
        portaCoordenador: coordenador.porta,
      );
      await _aguardarPropagacao();

      // Coordenador desenha -> precisa aparecer no membro.
      final quadrado = BoardObject(
        id: 'obj-1',
        tipo: FormaTipo.quadrado,
        pontos: const [PontoXY(0, 0), PontoXY(100, 100)],
        cor: 0xFF000000,
      );
      boardCoordenador.desenharLocal(quadrado);
      await _aguardarPropagacao();

      expect(boardMembro.objeto('obj-1'), isNotNull);

      // Membro desenha -> precisa aparecer no coordenador.
      final circulo = BoardObject(
        id: 'obj-2',
        tipo: FormaTipo.circulo,
        pontos: const [PontoXY(10, 10), PontoXY(50, 50)],
        cor: 0xFFFF0000,
      );
      boardMembro.desenharLocal(circulo);
      await _aguardarPropagacao();

      expect(boardCoordenador.objeto('obj-2'), isNotNull);

      // Membro seleciona e colore -> precisa refletir nos dois lados.
      final selecionou = boardMembro.selecionarLocal('obj-1');
      expect(selecionou, isTrue);
      await _aguardarPropagacao();

      expect(boardCoordenador.donoDe('obj-1'), 'membro-1');

      boardMembro.colorirLocal('obj-1', 0xFF00FF00);
      await _aguardarPropagacao();

      expect(boardCoordenador.objeto('obj-1')!.cor, 0xFF00FF00);

      // Coordenador tenta selecionar o mesmo objeto -> deve ser negado
      // localmente (já travado por outro).
      final coordenadorConseguiuSelecionar = boardCoordenador.selecionarLocal(
        'obj-1',
      );
      expect(coordenadorConseguiuSelecionar, isFalse);
    },
  );
}

/// 127.0.0.1 — não precisamos do IP de rede real pra esse teste, é tudo na
/// mesma máquina/processo.
const kIpDeTeste = '127.0.0.1';
