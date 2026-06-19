import 'package:flutter/material.dart';
import 'package:sdwb/core/theme/app_bar.dart';
import 'package:sdwb/models/sala.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  bool _isLoading = true;
  List<Sala> _salas = [];

  @override
  void initState() {
    super.initState();
    _carregarSalas();
  }

  Future<void> _carregarSalas() async {
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
      _salas = [
        Sala(nome: 'Gartic Phone', ip: 'localhost', porta: 8080),
        Sala(nome: 'Só Quadrados', ip: 'localhost', porta: 8081),
        Sala(nome: 'Só Quadrados', ip: 'localhost', porta: 8081),
        Sala(nome: 'Só Quadrados', ip: 'localhost', porta: 8081),
        Sala(nome: 'Só Quadrados', ip: 'localhost', porta: 8081),
        Sala(nome: 'Só Quadrados', ip: 'localhost', porta: 8081),
        Sala(nome: 'Só Quadrados', ip: 'localhost', porta: 8081),
        Sala(nome: 'Só Quadrados', ip: 'localhost', porta: 8081),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_salas.isEmpty) {
      return Scaffold(body: Center(child: Column()));
    }

    return Scaffold(
      appBar: SdwbAppBar(title: 'Board', showBack: true),
      body: ListView.builder(
        itemCount: _salas.length,
        itemBuilder: (context, index) {
          return Row(
            children: [
              Expanded(child: ListTile(title: Text(_salas[index].nome))),
              ElevatedButton(child: Text('Entrar'), onPressed: () {}),
            ],
          );
        },
      ),
    );
  }
}
