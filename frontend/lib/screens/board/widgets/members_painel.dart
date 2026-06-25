import 'package:flutter/material.dart';

class Participante {
  final String nome;
  final Color cor;
  final bool isVoce;
  final bool ativo;

  const Participante({
    required this.nome,
    required this.cor,
    this.isVoce = false,
    this.ativo = true,
  });

  String get iniciais {
    final partes = nome.trim().split(RegExp(r'\s+'));
    final letras = partes.map((p) => p.isNotEmpty ? p[0] : '').take(2);
    return letras.join().toUpperCase();
  }
}

const kParticipantesMock = <Participante>[
  Participante(nome: 'Você', cor: Colors.indigo, isVoce: true),
  Participante(nome: 'Lucas M.', cor: Colors.blue),
  Participante(nome: 'Ana P.', cor: Colors.pink),
  Participante(nome: 'Mateus R.', cor: Colors.teal),
  Participante(nome: 'Sofia T.', cor: Colors.orange),
];

class MembersPainel extends StatelessWidget {
  const MembersPainel({super.key, this.participantes = kParticipantesMock});

  final List<Participante> participantes;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 220,
      color: colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'PARTICIPANTES',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          for (final p in participantes)
            ListTile(
              dense: true,
              leading: CircleAvatar(
                backgroundColor: p.cor,
                child: Text(
                  p.iniciais,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              title: Text(p.nome),
              subtitle: p.isVoce
                  ? Text(
                      'você',
                      style: TextStyle(color: colorScheme.primary),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: p.ativo ? Colors.green : colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(p.ativo ? 'ativo' : 'inativo'),
                      ],
                    ),
            ),
        ],
      ),
    );
  }
}
