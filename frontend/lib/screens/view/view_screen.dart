import 'package:flutter/material.dart';
import 'package:sdwb/core/theme/app_bar.dart';
import 'package:sdwb/models/sala.dart';

class ViewScreen extends StatefulWidget {
  const ViewScreen({super.key});

  @override
  State<ViewScreen> createState() => _ViewScreenState();
}

class _ViewScreenState extends State<ViewScreen> {
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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 520, // no desktop fica elegante
              maxHeight:
                  MediaQuery.of(context).size.height * 0.7, // 70% da tela
            ),
            child: Column(
              children: [
                Column(
                  children: [Text('Salas Ativas'), Text('Escolha um Quadro')],
                ),
                Divider(),
                Expanded(child: Text('')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
