"""Catálogo de salas (NomeDaSala, IP, Porta).

Lógica pura, sem sockets. Thread-safe porque o servidor atende cada
cliente em uma thread separada.
"""
from __future__ import annotations

import threading
from dataclasses import dataclass


@dataclass(frozen=True)
class Sala:
    nome: str
    ip: str
    porta: int

    def para_dict(self) -> dict:
        return {"nome": self.nome, "ip": self.ip, "porta": self.porta}


class Catalogo:
    def __init__(self) -> None:
        self._salas: dict[str, Sala] = {}
        self._trava = threading.Lock()

    def registrar(self, nome: str, ip: str, porta: int) -> Sala:
        # Atualizar uma sala existente é essencial para a eleição: o novo
        # coordenador reusa o nome e apenas troca ip/porta.
        sala = Sala(nome=nome, ip=ip, porta=porta)
        with self._trava:
            self._salas[nome] = sala
        return sala

    def remover(self, nome: str) -> bool:
        with self._trava:
            return self._salas.pop(nome, None) is not None

    def listar(self) -> list[Sala]:
        with self._trava:
            return list(self._salas.values())
