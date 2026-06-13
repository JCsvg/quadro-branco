"""Testes da lógica pura: catálogo e protocolo (sem sockets)."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

from protocolo import tratar  # noqa: E402
from registro import Catalogo  # noqa: E402


def test_registrar_e_listar():
    catalogo = Catalogo()
    tratar({"tipo": "registrar", "nome": "sala1", "ip": "1.2.3.4", "porta": 9001}, catalogo)
    resposta = tratar({"tipo": "listar"}, catalogo)
    assert resposta["tipo"] == "salas"
    assert resposta["salas"] == [{"nome": "sala1", "ip": "1.2.3.4", "porta": 9001}]


def test_registrar_mesmo_nome_atualiza_endereco():
    # Cenário de eleição: novo coordenador reusa o nome com novo ip/porta.
    catalogo = Catalogo()
    tratar({"tipo": "registrar", "nome": "s", "ip": "1.1.1.1", "porta": 1}, catalogo)
    tratar({"tipo": "registrar", "nome": "s", "ip": "2.2.2.2", "porta": 2}, catalogo)
    resposta = tratar({"tipo": "listar"}, catalogo)
    assert resposta["salas"] == [{"nome": "s", "ip": "2.2.2.2", "porta": 2}]


def test_remover():
    catalogo = Catalogo()
    tratar({"tipo": "registrar", "nome": "s", "ip": "1.1.1.1", "porta": 1}, catalogo)
    tratar({"tipo": "remover", "nome": "s"}, catalogo)
    assert tratar({"tipo": "listar"}, catalogo)["salas"] == []


def test_campo_ausente_retorna_erro():
    resposta = tratar({"tipo": "registrar", "nome": "s"}, Catalogo())
    assert resposta["tipo"] == "erro"


def test_tipo_desconhecido():
    assert tratar({"tipo": "xpto"}, Catalogo())["tipo"] == "erro"
