"""Entrypoint do Serviço de Nomes: `python src/main.py`."""
from __future__ import annotations

import logging

from config import config
from servidor import Servidor


def main() -> None:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    )
    servidor = Servidor(cfg=config)
    try:
        servidor.executar()
    except KeyboardInterrupt:
        logging.getLogger("servico_nomes").info("encerrando...")
        servidor.encerrar()


if __name__ == "__main__":
    main()
