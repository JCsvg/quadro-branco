import 'package:flutter/material.dart';

class Sala {
  String _nome;
  String _ip;
  int _porta;

  Sala({
    required String nome,
    required String ip,
    required int porta,
    required this.ativos,
  }) : _nome = nome,
       _ip = ip,
       _porta = porta;
  int ativos;

  String get nome => _nome;

  String get ip => _ip;

  int get porta => _porta;
}
