# SDWB - Shared Distributed Write Board

Quadro branco distribuído em tempo real. Múltiplos usuários colaboram no mesmo quadro sem servidor fixo. O sistema usa um Serviço de Nomes central (Python) para descoberta de salas, e o próprio cliente Flutter assume o papel de Coordenador quando cria uma sala.

---

## Estrutura do Projeto

```
sdwb/
├── backend/                          # Python - Serviço de Nomes
│   ├── name_service.py
│   └── requirements.txt
│
├── frontend/                         # Flutter/Dart - cliente + coordenador
│   └── lib/
│       ├── main.dart
│       ├── cargo/
│       │   └── cargo.dart            # gerencia o cargo do nó (membro/coordenador)
│       ├── models/
│       │   └── board_object.dart     # representa linha, quadrado, cor, id
│       ├── screens/
│       │   ├── home_screen.dart      # tela de criar ou entrar em sala
│       │   └── board_screen.dart     # quadro branco + UI adaptada ao cargo
│       └── services/
│           ├── name_service_client.dart    # comunica com o backend Python
│           ├── coordinator_server.dart     # ServerSocket (ativo só se for coord)
│           ├── coordinator_client.dart     # conecta ao coordenador da sala
│           ├── election_service.dart       # Algoritmo do Valentão
│           └── heartbeat_service.dart      # detecta queda do coordenador
│
└── docker/
    ├── docker-compose.yml
    └── Dockerfile.backend            # somente o name_service vai pro Docker
```

---

## Arquitetura

### Backend (Python) - Serviço de Nomes

Único processo fixo do sistema. Roda em Docker com IP e porta fixos.
Mantém uma tabela simples:

```
(NomeDaSala, IP, Porta)
```

Não guarda estado do quadro, não coordena nada. É só um catálogo de salas ativas.

### Frontend (Flutter/Dart) - Cliente + Coordenador

Todo nó roda o mesmo app Flutter. O que muda é o **cargo**, definido em tempo de execução.

Quando o usuário **cria uma sala**:
- O app abre um `ServerSocket` (coordinator_server.dart)
- Registra a sala no Serviço de Nomes
- O cargo vira `coordenador`

Quando o usuário **entra em uma sala**:
- O app consulta o Serviço de Nomes para listar salas
- Conecta ao coordenador da sala escolhida
- O cargo vira `membro`

### Docker - Infraestrutura

Somente o backend vai pro Docker. O Flutter desktop não roda em container.
O docker-compose sobe o name_service com restart automático.

---

## Sistema de Cargos (cargo.dart)

O cargo é um `ChangeNotifier` que a UI escuta via `Consumer<Cargo>`.
Quando o cargo muda, a interface se adapta automaticamente.

```
CargoTipo.membro
    - não vê lista de membros
    - não recebe aviso de novo ingresso
    - envia ações para o coordenador
    - pinga o coordenador via heartbeat

CargoTipo.coordenador
    - vê lista de membros conectados
    - recebe aviso quando alguém entra ou sai
    - repassa ações de todos para todos
    - responde heartbeat dos membros
```

Transições de cargo:

```
Usuário cria sala       → cargo.assumirCoordenador([])
Usuário entra na sala   → cargo.assumirMembro()
Coordenador cai         → eleição → vencedor chama cargo.promover(membros)
```

---

## Fluxo Completo

### Criar sala
1. Usuário digita nome da sala
2. `coordinator_server.dart` abre ServerSocket em porta aleatória
3. `name_service_client.dart` registra (nome, IP, porta) no backend
4. `cargo.assumirCoordenador([])`
5. Entra na `board_screen.dart` com painel de membros visível

### Entrar em sala
1. `name_service_client.dart` busca lista de salas no backend
2. Usuário seleciona a sala desejada
3. `coordinator_client.dart` conecta ao IP/porta do coordenador
4. Coordenador envia estado atual do quadro (todos os objetos)
5. `cargo.assumirMembro()`
6. Entra na `board_screen.dart` sem painel de membros

### Queda do Coordenador
1. `heartbeat_service.dart` detecta timeout do coord
2. `election_service.dart` inicia Algoritmo do Valentão
3. Nó com maior ID que não receber resposta assume
4. Vencedor chama `cargo.promover(membrosAtuais)`
5. Vencedor fecha `coordinator_client` e abre `coordinator_server`
6. Vencedor atualiza o Serviço de Nomes com novo IP/porta

---

## Exclusão Mútua

Para operações de alterar cor e remover objeto:
1. Cliente envia `SELECIONAR objeto_id` para o coordenador
2. Coordenador marca o objeto como bloqueado por aquele cliente
3. Se outro cliente tentar selecionar o mesmo objeto, recebe erro
4. Após a operação, coordenador desbloqueia o objeto

---

## Protocolo de Mensagens (JSON via TCP)

```json
// Cliente → Coordenador
{"tipo": "entrar", "ip": "192.168.0.2", "id": 3}
{"tipo": "desenhar", "objeto": {"id": "abc", "tipo": "linha", "x1": 10, "y1": 20, "x2": 50, "y2": 80, "cor": "preto"}}
{"tipo": "selecionar", "objeto_id": "abc"}
{"tipo": "alterar_cor", "objeto_id": "abc", "cor": "vermelho"}
{"tipo": "remover", "objeto_id": "abc"}
{"tipo": "heartbeat"}

// Coordenador → Clientes
{"tipo": "estado_quadro", "objetos": [...]}
{"tipo": "novo_membro", "ip": "192.168.0.3"}
{"tipo": "update", "objeto": {...}}
{"tipo": "remocao", "objeto_id": "abc"}
{"tipo": "erro", "mensagem": "objeto já selecionado por outro usuário"}
{"tipo": "heartbeat_ok"}

// Eleição entre nós
{"tipo": "eleicao", "id": 5}
{"tipo": "ok"}
{"tipo": "coordenador", "id": 5, "ip": "192.168.0.5", "porta": 9001}

// Cliente → Serviço de Nomes (Python)
{"tipo": "registrar", "nome": "sala1", "ip": "192.168.0.2", "porta": 9001}
{"tipo": "listar"}
{"tipo": "remover", "nome": "sala1"}
```

---

## Tecnologias

| Camada | Tecnologia |
|---|---|
| Serviço de Nomes | Python 3 + socket nativo |
| Cliente + Coordenador | Flutter/Dart + dart:io |
| Comunicação | TCP via Sockets |
| Containerização | Docker + docker-compose |
| Eleição | Algoritmo do Valentão |

---

## Como rodar

```bash
# Subir o Serviço de Nomes
cd docker
docker-compose up -d

# Rodar o cliente Flutter (desktop)
cd frontend
flutter run -d linux  # ou macos / windows
```

---

## Requisitos do Trabalho

| Módulo | Peso | Status |
|---|---|---|
| Serviço de Nomes | 15% | |
| Entrada e Sync | 15% | |
| Transações (2PC) | 25% | confirmar com professor se ainda obrigatório |
| Eleição e Tolerância | 25% | |
| Exclusão Mútua | 10% | |
| Relatório/Código | 10% | |

> Atenção: o 2PC foi riscado no enunciado mas ainda aparece na tabela de avaliação com 25%. Confirmar com o professor.
