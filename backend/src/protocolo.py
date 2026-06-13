"""Protocolo de mensagens do Serviço de Nomes.

Mensagens são JSON delimitado por '\\n' (uma por linha), combinando com o
lado Dart que lê o socket como stream de linhas.

Cliente -> Serviço:
    {"tipo": "registrar", "nome": "sala1", "ip": "192.168.0.2", "porta": 9001}
    {"tipo": "listar"}
    {"tipo": "remover", "nome": "sala1"}

Serviço -> Cliente:
    {"tipo": "ok"}
    {"tipo": "salas", "salas": [{"nome": ..., "ip": ..., "porta": ...}]}
    {"tipo": "erro", "mensagem": "..."}
"""
from __future__ import annotations

import json

from registro import Catalogo


class ErroProtocolo(Exception):
    """Mensagem malformada ou com campos inválidos."""


def _exigir(msg: dict, campo: str) -> object:
    if campo not in msg:
        raise ErroProtocolo(f"campo obrigatório ausente: '{campo}'")
    return msg[campo]


def decodificar(linha: str) -> dict:
    """Converte uma linha de texto em um dict de mensagem."""
    linha = linha.strip()
    if not linha:
        raise ErroProtocolo("mensagem vazia")
    try:
        msg = json.loads(linha)
    except json.JSONDecodeError as e:
        raise ErroProtocolo(f"JSON inválido: {e}") from e
    if not isinstance(msg, dict):
        raise ErroProtocolo("mensagem deve ser um objeto JSON")
    return msg


def codificar(msg: dict) -> bytes:
    """Serializa uma resposta como linha JSON pronta para o socket."""
    return (json.dumps(msg, ensure_ascii=False) + "\n").encode("utf-8")


def erro(mensagem: str) -> dict:
    return {"tipo": "erro", "mensagem": mensagem}


def tratar(msg: dict, catalogo: Catalogo) -> dict:
    """Aplica a mensagem ao catálogo e devolve a resposta (dict).

    Traduz qualquer ErroProtocolo em resposta de erro, para o servidor só
    precisar serializar o que voltar daqui.
    """
    try:
        tipo = _exigir(msg, "tipo")
        if tipo == "registrar":
            nome = str(_exigir(msg, "nome"))
            ip = str(_exigir(msg, "ip"))
            porta = int(_exigir(msg, "porta"))
            catalogo.registrar(nome, ip, porta)
            return {"tipo": "ok"}
        if tipo == "listar":
            salas = [s.para_dict() for s in catalogo.listar()]
            return {"tipo": "salas", "salas": salas}
        if tipo == "remover":
            nome = str(_exigir(msg, "nome"))
            catalogo.remover(nome)
            return {"tipo": "ok"}
        return erro(f"tipo desconhecido: '{tipo}'")
    except ErroProtocolo as e:
        return erro(str(e))
    except (ValueError, TypeError) as e:
        return erro(f"valor inválido: {e}")
