"""Servidor TCP do Serviço de Nomes (uma thread por conexão).

Cada conexão pode enviar várias mensagens (uma por linha); o servidor
responde uma linha por mensagem. Conexões curtas ou longas funcionam.
"""
from __future__ import annotations

import logging
import socket
import threading

from config import Configuracao, config
from protocolo import codificar, decodificar, erro, tratar, ErroProtocolo
from registro import Catalogo

log = logging.getLogger("servico_nomes")


class Servidor:
    def __init__(self, catalogo: Catalogo | None = None, cfg: Configuracao = config) -> None:
        self.catalogo = catalogo or Catalogo()
        self.cfg = cfg
        self._socket: socket.socket | None = None
        self._parar = threading.Event()

    def executar(self) -> None:
        self._socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self._socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self._socket.bind((self.cfg.endereco, self.cfg.porta))
        self._socket.listen(self.cfg.fila_conexoes)
        log.info("Serviço de Nomes ouvindo em %s:%d", self.cfg.endereco, self.cfg.porta)
        try:
            while not self._parar.is_set():
                try:
                    conexao, origem = self._socket.accept()
                except OSError:
                    break  # socket fechado em encerrar()
                threading.Thread(
                    target=self._atender, args=(conexao, origem), daemon=True
                ).start()
        finally:
            self._socket.close()

    def encerrar(self) -> None:
        self._parar.set()
        if self._socket is not None:
            self._socket.close()

    def _atender(self, conexao: socket.socket, origem) -> None:
        log.debug("conexão de %s", origem)
        buffer = b""
        with conexao:
            while not self._parar.is_set():
                try:
                    pedaco = conexao.recv(4096)
                except OSError:
                    break
                if not pedaco:
                    break
                buffer += pedaco
                if len(buffer) > self.cfg.tamanho_maximo_msg:
                    conexao.sendall(codificar(erro("mensagem muito grande")))
                    break
                # Processa todas as linhas completas já recebidas.
                while b"\n" in buffer:
                    linha, buffer = buffer.split(b"\n", 1)
                    resposta = self._processar(linha.decode("utf-8", "replace"))
                    conexao.sendall(codificar(resposta))
        log.debug("conexão encerrada %s", origem)

    def _processar(self, linha: str) -> dict:
        try:
            msg = decodificar(linha)
        except ErroProtocolo as e:
            return erro(str(e))
        return tratar(msg, self.catalogo)
