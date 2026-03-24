# Frameworks — Delphi Spec-Kit

## Frameworks Suportados

Este spec-kit oferece suporte a três frameworks populares do ecossistema Delphi. A escolha depende do tipo de projeto.

### Horse (REST API Minimalista)

- **Quando usar:** APIs REST simples/médias, microsserviços, prototipagem rápida
- **Estilo:** Minimalista, inspirado no Express.js
- **Características:** Middleware chain, baixo acoplamento, rápido de configurar
- **Instalação:** `boss install horse`
- **Skills:** `.gemini/skills/horse-framework/SKILL.md`
- **Rules:** `.cursor/rules/horse-patterns.md`

### DelphiMVCFramework (API Full-Featured)

- **Quando usar:** APIs REST complexas, projetos enterprise, quando precisa de Active Record, Swagger, SSE, WebSockets
- **Estilo:** MVC completo com annotations/attributes
- **Características:** Active Record, RQL, JWT built-in, serialização automática, Swagger
- **Instalação:** Clone do repositório + search paths
- **Skills:** `.gemini/skills/dmvc-framework/SKILL.md`
- **Rules:** `.cursor/rules/dmvc-patterns.md`

### Dext Framework (Minimal APIs & ORM)

- **Quando usar:** Aplicações enterprise modernas, APIs REST baseadas em Injeção de Dependências e Entity ORM
- **Estilo:** Inspirado em .NET Core / Spring Boot (Minimal APIs, DTOs, DI)
- **Características:** Roteamento fluente, Smart Properties, Dext.Entity, TAsyncTask
- **Links:** https://github.com/cesarliws/dext
- **Skills:** `.gemini/skills/dext-framework/SKILL.md`
- **Rules:** `.cursor/rules/dext-patterns.md`

### DevExpress Components

- **Quando usar:** Interfaces desktop ricas com grids avançados, dashboards, relatórios
- **Estilo:** Component-based (design-time + runtime) VCL
- **Características:** TcxGrid, TdxLayoutControl, skins, exportação, filtros avançados
- **Instalação:** Licença comercial DevExpress
- **Atenção:** "DEXT" aqui refere-se historicamente aos sufixos dos componentes DevExtreme, mas **não** é o Dext Framework citado acima.
- **Skills:** `.gemini/skills/devexpress-components/SKILL.md`

### Projeto ACBr (Automação Comercial e Fiscal)

- **Quando usar:** Emissão de documentos fiscais (NF-e, NFC-e, CT-e, SAT), TEF, Boletos e acesso a hardware não fiscal.
- **Arquitetura:** Não jogue componentes visuais diretamente nos formulários. Crie Serviços/Adapters (`INFeService`) que injetem e isolem o componente `TACBrNFe`.
- **Skills:** `.gemini/skills/acbr-components/SKILL.md`
- **Rules:** `.cursor/rules/acbr-patterns.md`

### Intraweb Framework

- **Quando usar:** Migração rápida de ERPs de desktop para Web com paradigma stateful baseado no servidor, equipes unicamente VCL criando Web.
- **Estilo:** Component-based, Stateful, RAD, Server-side rendered (AJAX/Postbacks).
- **Atenção:** Evite o uso de dados globais (como instâncias em `var` no `interface`), pois vazam state cross-session. Direcione o estado transiente sempre em instâncias do `UserSession`.
- **Skills:** `.gemini/skills/intraweb-framework/SKILL.md`
- **Rules:** `.cursor/rules/intraweb-patterns.md`

### Firebird Database

- **Quando usar:** Aplicações corporativas que precisam de banco de dados robusto, com PSQL, transações ACID e embedded mode.
- **Acesso:** Via FireDAC (driver `FB`) — o driver nativo mais utilizado no ecossistema Delphi.
- **Características:** Generators/Sequences, Stored Procedures (Selectable/Executable), Domains, Triggers, Events, Packages (FB3+), IDENTITY columns (FB3+), BOOLEAN nativo (FB3+).
- **Regras críticas:** Dialect 3 SEMPRE, CharacterSet UTF8, PageSize 16384, `RETURNING` com `Open` (não `ExecSQL`).
- **Skills:** `.gemini/skills/firebird-database/SKILL.md`
- **Rules:** `.cursor/rules/firebird-patterns.md`

### PostgreSQL Database

- **Quando usar:** Projetos modernos, cloud-native, microserviços, quando precisar de JSONB, Full-Text Search, UPSERT, Arrays ou particionamento avançado.
- **Acesso:** Via FireDAC (driver `PG`) — client library `libpq.dll`.
- **Características:** IDENTITY (SQL Standard), UPSERT (`ON CONFLICT`), JSONB indexável, Full-Text Search (`tsvector`), CTEs recursivas, Window Functions, ENUM types, Schemas, Partitioning, LISTEN/NOTIFY, extensões (`pgcrypto`, `pg_trgm`).
- **Regras críticas:** `IDENTITY` em vez de `SERIAL`, CharacterSet UTF8, `RETURNING` com `Open`, metadata via `information_schema`.
- **Skills:** `.gemini/skills/postgresql-database/SKILL.md`
- **Rules:** `.cursor/rules/postgresql-patterns.md`

### MySQL / MariaDB Database

- **Quando usar:** Projetos web com alta popularidade de hosting, aplicações LAMP/LEMP stack, cenários de alta leitura, compatibilidade com hosting compartilhado.
- **Acesso:** Via FireDAC (driver `MySQL`) — client library `libmysql.dll` (ou `libmariadb.dll`).
- **Características:** AUTO_INCREMENT, `LAST_INSERT_ID()`, UPSERT (`ON DUPLICATE KEY UPDATE`), JSON nativo (5.7+), FULLTEXT Search, ENUM/SET nativos, Generated Columns, CTEs e Window Functions (8.0+), Partitioning.
- **Regras críticas:** `utf8mb4` SEMPRE (nunca `utf8`), `InnoDB` SEMPRE, sem `RETURNING` (usar `LAST_INSERT_ID()`), metadata via `information_schema`.
- **Skills:** `.gemini/skills/mysql-database/SKILL.md`
- **Rules:** `.cursor/rules/mysql-patterns.md`

### Threading & Multi-Threading

- **Quando usar:** Operações demoradas que bloqueiam a UI, processamento paralelo de dados, servidores/workers, pools de threads.
- **Abordagens:** `TThread.CreateAnonymousThread` (simples), `TTask.Run` (PPL moderno), `TParallel.For` (loops), `TFuture<T>` (resultado assíncrono), `TThread` herdado (workers permanentes).
- **Regra de Ouro:** NUNCA acessar VCL/FMX de thread secundária → `TThread.Synchronize` (bloqueante) ou `TThread.Queue` (não-bloqueante).
- **Thread-Safety:** `TCriticalSection`, `TMonitor`, `TInterlocked`, `TThreadList<T>`, `TMultiReadExclusiveWriteSynchronizer`, `TThreadedQueue<T>`.
- **Skills:** `.gemini/skills/threading/SKILL.md`
- **Rules:** `.cursor/rules/threading-patterns.md`

## Decisão de Framework

```
Preciso de API REST?
├── Sim, simples e rápida (Express-like) → Horse
├── Sim, corporativa robusta com DI/ORM (.NET-like) → Dext Framework
├── Sim, completa com Active Record legados e Swagger → DMVC
```
```
Preciso de Banco de Dados?
├── Corporativo robusto com PSQL, transactions → Firebird
├── Aplicações locais e mobile → SQLite
├── Projetos modernos, cloud-native → PostgreSQL
├── Web hosting, LAMP/LEMP stack → MySQL / MariaDB
└── Ambientes Microsoft → SQL Server
```
```
Preciso de UI/Visual?
├── Desktop Rica → DevExpress Components
├── Automação Emissão/Hardware → ACBr
└── Web SPA Nativo Delphi (Form based) → Intraweb
```

## Combinações Comuns

| Frontend | Backend | Componentes Específicos |
|----------|---------|-------------------------|
| DevExpress (VCL)| Dext.Entity ORM | Desktop monolítico moderno |
| Intraweb (Web) | Intraweb (Stateful)| Portabilidade rápida Web, Single Binary, UserSession |
| Web App (JS) | Dext Framework API | Web App consumindo API corporativa |
| VCL / FMX | Horse API | App consumindo API minimalista |
| PDV (VCL) | Horse API / Local| Projeto ACBr para Impressoras/TEF/NFC-e |

## Regra de Ouro Transversal (Memória e Exceções)

Independentemente do framework ou ecossistema escolhido:
1. **Zere a possibilidade de Memory Leaks**: Qualquer Classe sem `Reference Count` e sem `Owner` injetado deve ser instanciada vizinha a um `try` e libertada em bloco `finally`.
2. **Exceções Transparentes e de Domínio**: Não "cale" processamentos de erro genéricos (`on E: Exception do`). Transforme Infraestrutura em exceções tipadas e garanta propagação correta (DDDErrors), deixando o Framework interceptar no handler global para a UI.

## Regras Gerais para Todos os Frameworks

- SOLID se aplica independente do framework
- Clean Code se aplica independente do framework
- Nomenclatura Pascal Guide se aplica sempre
- Testes unitários com DUnitX são obrigatórios
- Separação de camadas (Domain, Application, Infrastructure, Presentation) vale para todos
