# Backend — Serviço de Nomes (SDWB)

Processo central do SDWB. Mantém apenas a tabela `(NomeDaSala, IP, Porta)` — as
"páginas amarelas" do sistema. Não guarda estado do quadro nem coordena nada.

## Estrutura

```
backend/
├── requirements.txt          # só pytest (dev); o serviço usa stdlib
├── src/
│   ├── main.py               # entrypoint: python src/main.py
│   ├── config.py             # endereço/porta/limites (via env vars)
│   ├── registro.py           # catálogo de salas (lógica pura, thread-safe)
│   ├── protocolo.py          # codificar/decodificar + roteamento das mensagens JSON
│   └── servidor.py           # socket TCP, uma thread por conexão
└── tests/test_catalogo.py
```

## Como rodar

```bash
python3 -m venv .venv
./.venv/bin/pip install -r requirements.txt

# Sobe o serviço (porta padrão 9000)
PYTHONPATH=src ./.venv/bin/python src/main.py
```

Variáveis de ambiente: `NS_HOST` (padrão `0.0.0.0`), `NS_PORT` (padrão `9000`).

## Testes

```bash
./.venv/bin/python -m pytest tests/ -q
```

## Rodar via Docker

A partir da pasta `docker/`:

```bash
docker-compose up -d --build   # sobe o Serviço de Nomes na porta 9000
docker-compose logs -f         # acompanha os logs
docker-compose down            # encerra
```

O container tem `restart: unless-stopped` — volta sozinho se cair.

## Protocolo (JSON delimitado por `\n`)

Cliente → Serviço de Nomes:

```json
{"tipo": "registrar", "nome": "sala1", "ip": "192.168.0.2", "porta": 9001}
{"tipo": "listar"}
{"tipo": "remover", "nome": "sala1"}
```

Serviço de Nomes → Cliente:

```json
{"tipo": "ok"}
{"tipo": "salas", "salas": [{"nome": "sala1", "ip": "192.168.0.2", "porta": 9001}]}
{"tipo": "erro", "mensagem": "..."}
```

`registrar` com um nome já existente **atualiza** o endereço — é assim que o novo
coordenador eleito assume a sala após uma falha.
```
