"""Configuração do Serviço de Nomes (lida de variáveis de ambiente)."""
from __future__ import annotations

import os
from dataclasses import dataclass


@dataclass(frozen=True)
class Configuracao:
    endereco: str = os.getenv("NS_HOST", "0.0.0.0")
    porta: int = int(os.getenv("NS_PORT", "9000"))
    fila_conexoes: int = int(os.getenv("NS_BACKLOG", "50"))
    # Limite de tamanho por mensagem, proteção simples contra flood.
    tamanho_maximo_msg: int = int(os.getenv("NS_MAX_MSG", "65536"))


config = Configuracao()
