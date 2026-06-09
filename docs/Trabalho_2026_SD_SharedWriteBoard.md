# ---

**Projeto Final: Shared Distributed Write Board (SDWB)**

**Disciplina:** Sistemas Distribuídos

## **1\. Descrição Geral**

O objetivo é desenvolver um **Quadro Branco Distribuído** onde múltiplos terminais colaboram em tempo real. O sistema não possui um servidor fixo; ele utiliza um **Serviço de Nomes** para descoberta e um **Coordenador Migrante** (um dos próprios nós) para gerenciar o estado e a consistência das operações.

Elementos do SDWB:

* Serviço de nome  
* Coordenador do Quadro  
* Interface do usuário

### **1.1. Interface do usuário (Frontend)**

O cliente do SDWD possui uma interface de usuário.

* Cada nó deve possuir uma interface gráfica simples com as seguintes opções:  
  * CRIAR NOVO QUADRO  
  * INGRESSAR EM QUADRO EXISTENTE  
  * exibir o estado atual do quadro (desenhos e figuras produzidas)  
  * escrever linhas retas (marcar dois pontos para traçar linha entre eles)  
  * criar uma figura geométrica (quadrado)  
  * Colorir uma figura ou linha: será necessário selecionar uma cor e selecionar o objeto, então aplicar a nova cor ao objeto.  Disponibilize duas cores.  
  * Remover objeto: selecionar objeto e selecionar opção remover.  
      
* As atualizações feitas por um usuário devem ser refletidas em todos os outros clientes conectados ao mesmo quadro (terminais de outros usuários).  
* Para ingressar em um quadro, um novo cliente deve entrar em contato com Serviço de Nomes e com o Coordenador do Quadro  
  * O Serviço de Nome retorna a lista de quadros existentes (nome, endereço IP e porta), o cliente seleciona o quadro desejado e entra em contato com o coordenador de quadro selecionado.

## ---

**2\. Requisitos de Infraestrutura e Descoberta**

### **A. Serviço de Nomes (Service Discovery)**

O endereço IP e a porta do "Coordenador" não podem ser fixos (hardcoded) nos clientes.

* Deve ser implementado um **Serviço de Nomes** onde o Coordenador atual registra seu endereço.  
* **Acesso Inicial:** Quando um novo terminal (usuário) entra no sistema, ele consulta primeiro este Serviço de Nomes para obter o endereço dos Coordenadores.  
* Para o **Serviço de Nomes**, você pode criar um pequeno processo separado que apenas mantém uma tabela `(NomeDoServiço, IP, Porta)`. Pensem nele como as 'Páginas Amarelas' do seu sistema.  
* O serviço de nomes deve armazenar somente a tabela com `(NomeDoServiço, IP, Porta)`

### 

### **B. Protocolo de Entrada (Onboarding)**

1. O novo integrante do SDWB se apresenta ao Coordenador do Quadro.  
2. **Sincronização de Estado:** o novo cliente deve receber o estado atual do quadro, ou seja, o novo cliente deve receber todos os desenhos realizados antes de seu ingresso no quadro.

## 

## **C. Coordenador do Quadro**

Serviço de SDWB responsável por armazenar a identificação de todos os elementos (clientes) que fazem parte do quadro no momento.  
Recebe ações dos usuários conectados e repassa aos demais.

## ---

**3\. Requisitos de Coordenação e Consistência**

### **A. Exclusão Mútua e Eleição**

* **Exclusão Mútua:** Para alterar cor e remoção, a aplicação do usuário deve selecionar objeto e selecionar operação, nessa sequência, garantir que outro usuário não realize operação no mesmo objeto simultaneamente.  
  * Na interface, permita a seleção do objeto que deseja alterar cor ou remover.  
  * Se o mesmo objeto foi selecionado por outro cliente, enviar mensagem de erro para o segundo cliente.  
* **Detectar falha e Eleição:** Se o host onde executa o Coordenador do Quadro ou mesmo o serviço apresentar falhar, os demais clientes devem detectar a falha no coordenador de quadro e iniciar uma eleição (ex: Algoritmo do Valentão) para definir o novo host para abrigar o serviço de Coordenador do Quadro. O vencedor deve atualizar o **Serviço de Nomes** com seu novo endereço.


## ---

**4\. Tolerância a Falhas**

* **Detecção de Falhas:** Implementar um mecanismo para detectar falhas: atualizar a lista de integrantes do quadro (no coordenador).  
* **Recuperação do Coordenador do Quadro:** O novo Coordenador eleito deve ser capaz de recuperar a lista de integrantes do quadro  
* **Resiliência do Serviço de Nomes:** O serviço de nomes não será afetado por falhas.

## **5\. Requisitos Técnicos e Arquitetura**

* **Comunicação:** Deve ser utilizada comunicação via Sockets (TCP ou UDP) ou RPC (gRPC).  
* **Middleware:** É proibido o uso de coordenadores externos prontos (como Zookeeper ou Etcd).  Implemente a lógica de eleição e consenso.

## ---

**5\. Cenários de Teste Obrigatórios (Demonstração)**

1. **Entrada Dinâmica:** Iniciar o Serviço de Nomes, depois o Coordenador, e em seguida os  terminais dos clientes.  
2. **Concorrência Transacional:** Dois usuários tentam iniciar transações conflitantes ao mesmo tempo; o sistema deve ordenar via exclusão mútua.  
3. **Morte do Coordenador:** "Matar" o processo do Coordenador de quadro. 

---

**Dica para os Alunos:**

"Para o **Serviço de Nomes**, vocês podem criar um pequeno processo separado que apenas mantém uma tabela (NomeDoServiço, IP, Porta). Pensem nele como as 'Páginas Amarelas' do seu sistema. Sem ele, ninguém se encontra\!"  
Este formato de enunciado é bem completo para uma disciplina de final de curso ou pós-graduação. Os alunos terão que lidar com **descoberta**, **consenso** e **recuperação**, que são o coração de qualquer sistema distribuído real.