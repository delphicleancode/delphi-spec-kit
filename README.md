# 🚀 Delphi AI Spec-Kit

<div align="center">

**Um ecossistema opinativo de regras, *skills* e *steerings* para elevar o desenvolvimento Delphi ao patamar state-of-the-art com Inteligência Artificial.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Delphi](https://img.shields.io/badge/Delphi-Object%20Pascal-red?logo=delphi)](https://www.embarcadero.com/products/delphi)
[![GitHub Copilot](https://img.shields.io/badge/GitHub%20Copilot-Ready-blue?logo=github)](https://github.com/features/copilot)
[![Cursor](https://img.shields.io/badge/Cursor-Rules-purple)](https://cursor.sh)
[![Claude](https://img.shields.io/badge/Claude-Code-brown?logo=anthropic)](https://claude.ai)
[![Gemini](https://img.shields.io/badge/Gemini-Skills-orange?logo=google)](https://gemini.google.com)
[![Kiro](https://img.shields.io/badge/Kiro-Steering-teal)](https://kiro.dev)

</div>

## Patrocínio

**Componentes Delphi/Lazarus**
<www.inovefast.com.br>

Integrações com plataformas de pagamento e serviços (Asaas, MercadoPago, Cielo, PagSeguro, D4sign, Webstore, MelhorEnvio, Groq )

**i9DBTools**
<www.inovefast.com.br/i9dbTools/>
Gerencie MySQL, PostgreSQL, Firebird e SQLite em um só lugar, com IA para gerar e explicar SQL em linguagem natural, otimizar queries e criar dados fake brasileiros em segundos.

## 📋 Índice

- [O que é este projeto?](#-o-que-é-este-projeto)
- [Por que usar?](#-por-que-usar)
- [Ferramentas de IA Suportadas](#-ferramentas-de-ia-suportadas)
- [Principais Diretrizes](#-principais-diretrizes-ensinadas-à-ia)
- [Frameworks Suportados](#️-frameworks-e-bibliotecas-suportados)
- [Estrutura do Kit](#-estrutura-do-kit)
- [Quick Start](#-quick-start)
- [Exemplos de Código](#-exemplos-de-boas-práticas)
- [Contribuições](#-contribuições)

---

## 💡 O que é este projeto?

O **Delphi AI Spec-Kit** não é um framework de código — é um conjunto de **diretrizes de comportamento** para sua IA favorita. Ele "ensina" o assistente a escrever código Delphi:

- ✅ **Limpo** — sem *god classes*, sem lógica de negócio em `OnClick`
- ✅ **Seguro** — zero *memory leaks* com `try..finally` e interfaces (ARC)
- ✅ **Testável** — TDD com DUnitX, Fakes via interface, sem banco real nos testes
- ✅ **Arquitetado** — SOLID, DDD, Repository/Service Pattern e *clean architecture*

> Diga adeus à IA que mistura acesso a banco com a camada de apresentação, esquece o `try..finally` ou ignora Injeção de Dependência.

---

## 🤔 Por que usar?

| Sem o Spec-Kit | Com o Spec-Kit |
|---|---|
| IA gera código com lógica no `OnClick` | IA isola camadas corretamente |
| `TStringList.Create` sem `try..finally` | Padrão ouro de memória aplicado sempre |
| Testes acoplados ao banco real | Fakes via interface, testes rápidos e isolados |
| Nomenclatura inconsistente | `A`-params, `F`-fields, `T`-types, verbos nos métodos |
| `with` statement e variáveis globais | Code smells bloqueados proativamente |

---

## 🤖 Ferramentas de IA Suportadas

| Ferramenta | Arquivo de Configuração | Como Funciona |
|---|---|---|
| **GitHub Copilot** | `.github/copilot-instructions.md` | Pre-prompt injetado no Workspace/Chat |
| **Cursor** | `.cursor/rules/*.md` | Rules carregadas por contexto |
| **Claude Code** | `.claude/` | Rules por contexto e skills no terminal |
| **Google Gemini / Antigravity** | `.gemini/skills/*/SKILL.md` | Skills modulares por domínio |
| **Kiro AI** | `.kiro/steering/*.md` | Restrições de stack e arquitetura |
| **Qualquer IA** | `AGENTS.md` | Regras universais (raiz do projeto) |

---

## 🌟 Principais Diretrizes Ensinadas à IA

### 🧠 Memory Management Zero-Leak

A IA obriga o padrão: todo `.Create` sem *Owner* exige `try..finally` na linha **imediatamente** subsequente. Também ensina o uso de **Interfaces** (ARC) para *Garbage Collection* nativa — sem `Free` manual.

```pascal
// ✅ Padrão Ouro — gerado SEMPRE pela IA com o Spec-Kit
var LList: TStringList;
begin
  LList := TStringList.Create;
  try
    LList.Add('item');
  finally
    LList.Free;
  end;
end;
```

### 🧪 TDD com DUnitX

Fluxo *Red-Green-Refactor* com Fakes isolados por interface. Sem acoplamento ao banco de dados nos testes.

```pascal
[Test]
procedure ProcessOrder_WithoutStock_RaisesException;
begin
  Assert.WillRaise(
    procedure begin FSut.Process(FEmptyOrder); end,
    EInvalidOrderException
  );
end;
```

### 🏛️ SOLID e DDD

- **S** — Uma classe, uma responsabilidade. `TCustomerValidator` não salva no banco.
- **O** — Extensão via interfaces, sem modificar código existente.
- **L** — Herança só com contrato claro. Interfaces preferidas.
- **I** — Interfaces pequenas e específicas. Evite interfaces gigantes.
- **D** — Injeção de dependência no construtor, nunca instâncias concretas hardcoded.

```pascal
// ✅ DIP na prática
constructor TOrderService.Create(
  ARepo: IOrderRepository;
  ANotifier: INotificationService);
begin
  FRepo := ARepo;
  FNotifier := ANotifier;
end;
```

### 📖 Clean Code — Pascal Guide

Nomenclaturas consistentes e obrigatórias:

| Categoria | Convenção | Exemplo |
|---|---|---|
| Parâmetros | Prefixo `A` | `ACustomerName` |
| Campos privados | Prefixo `F` | `FCustomerName` |
| Variáveis locais | Prefixo `L` | `LCustomer` |
| Classes | Prefixo `T` | `TCustomerService` |
| Interfaces | Prefixo `I` | `ICustomerRepository` |
| Exceções | Prefixo `E` | `ECustomerNotFound` |

---

## 🛠️ Frameworks e Bibliotecas Suportados

| Framework | Domínio | Regras Incluídas |
|---|---|---|
| **Horse** | REST APIs Minimalistas | Estrutura Controller/Service/Repository, middleware |
| **Dext Framework** | .NET-style APIs, ORM, DI, Async | Minimal APIs, Entity ORM, `TAsyncTask.Run` |
| **DelphiMVC (DMVC)** | APIs REST com Attributes | `[MVCPath]`, Active Record, JWT, RQL |
| **ACBr** | Automação Comercial (NFe, CF-e, Boleto) | Isolamento fiscal, sem cruzar com UI |
| **Intraweb** | WebApps Stateful em Delphi | `UserSession`, sem variáveis globais de sessão |
| **DevExpress** | UI Corporativa avançada | `TcxGrid`, `TdxLayoutControl`, skins e exportação |
| **Firebird Database** | Banco de Dados Corporativo | Conexão FireDAC, PSQL, generators, transactions, migrations |
| **PostgreSQL Database** | Banco de Dados Moderno | Conexão FireDAC, UPSERT, JSONB, Full-Text Search, PL/pgSQL |
| **MySQL / MariaDB** | Banco de Dados Popular | Conexão FireDAC, AUTO_INCREMENT, UPSERT, JSON, FULLTEXT |
| **DUnitX** | Testes Unitários | Red-Green-Refactor, Fakes via interface |
| **Design Patterns GoF** | Padrões de Projeto | Creational, Structural e Behavioral com interfaces e ARC |
| **Threading** | Multi-Threading | TThread, TTask, Synchronize/Queue, TCriticalSection, PPL |
| **Refatoração de Código** | Code Smells e Técnicas | Extract Method/Class, Guard Clauses, Strategy, Parameter Object |

---

## 📂 Estrutura do Kit

```
delphi-spec-kit/
│
├── AGENTS.md                        # 🌐 Regras universais (Copilot, Kiro, Antigravity)
│
├── .claude/
│   ├── CLAUDE.md                    # 🧠 SysPrompt Mestre para Claude
│   ├── settings.json                # Configurações de permissões
│   ├── commands/                    # Comandos (ex: project:review)
│   ├── rules/                       # Regras específicas de contexto
│   └── skills/                      # Habilidades sob demanda em flat-files
│
├── .github/
│   └── copilot-instructions.md      # 🤖 Pre-prompt para GitHub Copilot
│
├── .cursor/
│   └── rules/
│       ├── delphi-conventions.md    # Nomenclatura e convenções
│       ├── memory-exceptions.md     # Padrões de memória e exceções
│       ├── tdd-patterns.md          # TDD e DUnitX
│       ├── solid-patterns.md        # SOLID e DDD
│       ├── design-patterns.md       # ✨ Design Patterns GoF (Creational, Structural, Behavioral)
│       ├── refactoring.md           # ✨ Refatoração de código (Extract Method, Guard Clauses, Strategy)
│       ├── horse-patterns.md        # Horse REST Framework
│       ├── dmvc-patterns.md         # DelphiMVC Framework
│       ├── dext-patterns.md         # Dext Framework
│       ├── acbr-patterns.md         # Automação Comercial (ACBr)
│       ├── intraweb-patterns.md     # Intraweb WebApps
│       ├── firebird-patterns.md     # ✨ Firebird Database (conexão, PSQL, transactions)
│       ├── postgresql-patterns.md   # ✨ PostgreSQL Database (UPSERT, JSONB, FTS)
│       ├── mysql-patterns.md        # ✨ MySQL/MariaDB (AUTO_INCREMENT, JSON, UPSERT)
│       └── threading-patterns.md    # ✨ Threading (TThread, TTask, Synchronize/Queue)
│
├── .gemini/
│   └── skills/
│       ├── clean-code/              # Clean Code e Pascal Guide
│       ├── delphi-memory-exceptions/# Memory management e try..finally
│       ├── delphi-patterns/         # Repository, Service, Factory
│       ├── design-patterns/         # ✨ Design Patterns GoF (23 padrões)
│       ├── refactoring/             # ✨ Refatoração (10 técnicas, antes/depois)
│       ├── tdd-dunitx/              # TDD com DUnitX
│       ├── horse-framework/         # Horse REST API
│       ├── dmvc-framework/          # DelphiMVC Framework
│       ├── dext-framework/          # Dext Framework
│       ├── acbr-components/         # Componentes ACBr
│       ├── intraweb-framework/      # Intraweb WebApps
│       ├── devexpress-components/   # DevExpress UI
│       ├── dunitx-testing/          # Testes unitários
│       ├── firebird-database/       # ✨ Firebird Database (conexão, PSQL, generators, migrations)
│       ├── postgresql-database/     # ✨ PostgreSQL Database (UPSERT, JSONB, FTS, PL/pgSQL)
│       ├── mysql-database/          # ✨ MySQL/MariaDB (AUTO_INCREMENT, JSON, FULLTEXT)
│       ├── threading/               # ✨ Threading (TThread, TTask, PPL, thread-safety)
│       └── code-review/             # Revisão de código
│
├── .kiro/
│   └── steering/
│       ├── product.md               # Visão do produto
│       ├── tech.md                  # Stack tecnológica
│       ├── structure.md             # Arquitetura de camadas
│       └── frameworks.md            # Guias de frameworks
│
└── examples/
    ├── clean-unit-example.pas        # Unit bem organizada (Golden Path)
    ├── memory-exception-example.pas  # Memória e exceções corretas
    ├── repository-pattern.pas        # Repository Pattern completo
    ├── service-pattern.pas           # Service Pattern completo
    ├── design-patterns-example.pas   # ✨ Design Patterns GoF na prática
    ├── refactoring-example.pas        # ✨ Refatoração antes/depois (6 técnicas)
    ├── tdd-dunitx-example.pas        # TDD e DUnitX na prática
    ├── horse-api-example.pas         # API REST com Horse
    ├── dmvc-controller-example.pas   # Controller DMVC com Attributes
    ├── dext-api-example.pas          # Minimal API com Dext
    ├── acbr-service-example.pas      # Emissão NFe com ACBr
    ├── intraweb-form-example.pas     # Form Intraweb com UserSession
    ├── firebird-repository-example.pas # ✨ Repository com FireDAC + Firebird
    ├── postgresql-repository-example.pas # ✨ Repository com FireDAC + PostgreSQL
    ├── mysql-repository-example.pas # ✨ Repository com FireDAC + MySQL
    └── threading-example.pas    # ✨ Threading patterns (TTask, BackgroundWorker, Producer-Consumer)
```

---

## ⚡ Quick Start

### 1. Clone ou baixe o kit

```bash
git clone https://github.com/delphicleancode/delphi-spec-kit.git
```

### 2. Copie para a raiz do seu projeto Delphi

```
Seu-Projeto/
├── MeuApp.dpr
├── AGENTS.md          ← copie da raiz
├── .claude/           ← copie a pasta
├── .github/           ← copie a pasta
├── .cursor/           ← copie a pasta
├── .gemini/           ← copie a pasta
└── .kiro/             ← copie a pasta
```

### 3. A IA assume as regras automaticamente

- **Claude Code** — Aplica `.claude/CLAUDE.md` e usa rules/skills diretas no terminal
- **Cursor** — Lê os `.cursor/rules/*.md` automaticamente pelo contexto
- **GitHub Copilot** — Lê `.github/copilot-instructions.md` no workspace
- **Antigravity / Gemini** — Skills em `.gemini/skills/` são ativadas por demanda
- **Kiro** — Lê `.kiro/steering/*.md` como contexto fixo de produto

> **Nenhuma configuração adicional necessária.** Abra o projeto, use sua IA preferida e observe a diferença.

---

## 💡 Exemplos de Boas Práticas

### Arquitetura de Camadas

```
src/
├── Domain/         ← Entidades, Value Objects, Interfaces de Repositório
├── Application/    ← Services, Use Cases, DTOs
├── Infrastructure/ ← Repositórios FireDAC, APIs externas
└── Presentation/   ← Forms VCL/FMX, ViewModels
tests/
└── Unit/           ← Projetos DUnitX com Fakes isolados
```

> **Regra de dependência:** `Presentation → Application → Domain ← Infrastructure`
> O **Domain nunca** depende de outras camadas.

### Guard Clauses (sem nesting desnecessário)

```pascal
procedure ProcessOrder(AOrder: TOrder);
begin
  if not Assigned(AOrder) then
    raise EArgumentNilException.Create('AOrder não pode ser nil');
  if AOrder.Items.Count = 0 then
    raise EBusinessRuleException.Create('Pedido precisa ter ao menos um item');
  if not AOrder.IsValid then
    raise EValidationException.Create('Validação do pedido falhou');

  // lógica real aqui, sem nesting
  FRepository.Save(AOrder);
  FNotifier.Send(AOrder.Customer.Email);
end;
```

### Teste com Fake via Interface

```pascal
type
  TFakeOrderRepository = class(TInterfacedObject, IOrderRepository)
  private
    FOrders: TObjectList<TOrder>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Save(AOrder: TOrder);
    function FindById(AId: Integer): TOrder;
  end;

[TestFixture]
TOrderServiceTest = class
private
  FSut: TOrderService;
  FRepo: IOrderRepository;
public
  [Setup]
  procedure SetUp;
  [Test]
  procedure PlaceOrder_ValidOrder_SavesToRepository;
  [Test]
  procedure PlaceOrder_EmptyItems_RaisesException;
end;
```

---

## 🤝 Contribuições

Pull Requests são bem-vindos! Se seu framework ou biblioteca Delphi favorita precisa de um guia para a IA, adicione:

1. **Rule do Claude** → `.claude/rules/seu-framework.md` e `.claude/skills/seu-framework.md`
2. **Rule do Cursor** → `.cursor/rules/seu-framework.md`
3. **Skill do Gemini** → `.gemini/skills/seu-framework/SKILL.md`
4. **Referência** → mencione no `AGENTS.md`

### Como contribuir

```bash
# Fork e clone
git fork https://github.com/delphicleancode/delphi-spec-kit
git clone https://github.com/SEU-FORK/delphi-spec-kit

# Crie uma branch descritiva
git checkout -b feat/add-remobjects-patterns

# Commit e Pull Request
git commit -m "feat: add RemObjects SDK patterns"
git push origin feat/add-remobjects-patterns
```

---

<div align="center">

Deixe um cafézinho para o autor pix: <pix@inovefast.com.br> ☕

Feito com ❤️ para a comunidade **Delphi**.

*Se este kit te ajudou, deixe uma ⭐ no repositório!*

</div>
