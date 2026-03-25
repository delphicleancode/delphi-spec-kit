# Frameworks — Delphi Spec-Kit

## Supported Frameworks

This spec-kit supports three popular frameworks from the Delphi ecosystem. The choice depends on the type of project.

### Horse (Minimalist REST API)

- **When to use:** Simple/medium REST APIs, microservices, rapid prototyping
- **Style:** Minimalist, inspired by Express.js
- **Features:** Middleware chain, low coupling, quick to configure
- **Installation:** `boss install horse`
- **Skills:** `.gemini/skills/horse-framework/SKILL.md`
- **Rules:** `.cursor/rules/horse-patterns.md`

### DelphiMVCFramework (Full-Featured API)

- **When to use:** Complex REST APIs, enterprise projects, when you need Active Record, Swagger, SSE, WebSockets
- **Style:** MVC complete with annotations/attributes
- **Features:** Active Record, RQL, built-in JWT, automatic serialization, Swagger
- **Installation:** Repository clone + search paths
- **Skills:** `.gemini/skills/dmvc-framework/SKILL.md`
- **Rules:** `.cursor/rules/dmvc-patterns.md`

### Dext Framework (Minimal APIs & ORM)

- **When to use:** Modern enterprise applications, REST APIs based on Dependency Injection and Entity ORM
- **Style:** Inspired by .NET Core / Spring Boot (Minimal APIs, DTOs, DI)
- **Features:** Fluent Routing, Smart Properties, Dext.Entity, TAsyncTask
- **Links:** https://github.com/cesarliws/dext
- **Skills:** `.gemini/skills/dext-framework/SKILL.md`
- **Rules:** `.cursor/rules/dext-patterns.md`

### DevExpress Components

- **When to use:** Rich desktop interfaces with advanced grids, dashboards, reports
- **Style:** Component-based (design-time + runtime) VCL
- **Features:** TcxGrid, TdxLayoutControl, skins, export, advanced filters
- **Installation:** DevExpress commercial license
- **Attention:** "DEXT" here historically refers to the suffixes of DevExtreme components, but **is not** the Dext Framework mentioned above.
- **Skills:** `.gemini/skills/devexpress-components/SKILL.md`

### ACBr Project (Commercial and Tax Automation)

- **When to use:** Issuing tax documents (NF-e, NFC-e, CT-e, SAT), TEF, Bills and access to non-fiscal hardware.
- **Architecture:** Do not throw visual components directly into forms. Create Services/Adapters (`INFeService`) that inject and isolate the `TACBrNFe` component.
- **Skills:** `.gemini/skills/acbr-components/SKILL.md`
- **Rules:** `.cursor/rules/acbr-patterns.md`

### Intraweb Framework

- **When to use:** Rapid migration from desktop ERPs to Web with stateful server-based paradigm, VCL-only teams creating Web.
- **Style:** Component-based, Stateful, RAD, Server-side rendered (AJAX/Postbacks).
- **Attention:** Avoid using global data (such as instances in `var` in `interface`), as they leak cross-session state. Target transient state always on `UserSession` instances.
- **Skills:** `.gemini/skills/intraweb-framework/SKILL.md`
- **Rules:** `.cursor/rules/intraweb-patterns.md`

### Firebird Database

- **When to use:** Corporate applications that need a robust database, with PSQL, ACID transactions and embedded mode.
- **Access:** Via FireDAC (`FB` driver) — the most used native driver in the Delphi ecosystem.
- **Features:** Generators/Sequences, Stored Procedures (Selectable/Executable), Domains, Triggers, Events, Packages (FB3+), IDENTITY columns (FB3+), native BOOLEAN (FB3+).
- **Critical rules:** Dialect 3 ALWAYS, CharacterSet UTF8, PageSize 16384, `RETURNING` with `Open` (not `ExecSQL`).
- **Skills:** `.gemini/skills/firebird-database/SKILL.md`
- **Rules:** `.cursor/rules/firebird-patterns.md`

### PostgreSQL Database

- **When to use:** Modern projects, cloud-native, microservices, when you need JSONB, Full-Text Search, UPSERT, Arrays or advanced partitioning.
- **Access:** Via FireDAC (driver `PG`) — client library `libpq.dll`.
- **Features:** IDENTITY (SQL Standard), UPSERT (`ON CONFLICT`), indexable JSONB, Full-Text Search (`tsvector`), recursive CTEs, Window Functions, ENUM types, Schemas, Partitioning, LISTEN/NOTIFY, extensions (`pgcrypto`, `pg_trgm`).
- **Critical rules:** `IDENTITY` instead of `SERIAL`, CharacterSet UTF8, `RETURNING` with `Open`, metadata via `information_schema`.
- **Skills:** `.gemini/skills/postgresql-database/SKILL.md`
- **Rules:** `.cursor/rules/postgresql-patterns.md`

### MySQL / MariaDB Database

- **When to use:** Web projects with high hosting popularity, LAMP/LEMP stack applications, high reading scenarios, compatibility with shared hosting.
- **Access:** Via FireDAC (driver `MySQL`) — client library `libmysql.dll` (or `libmariadb.dll`).
- **Features:** AUTO_INCREMENT, `LAST_INSERT_ID()`, UPSERT (`ON DUPLICATE KEY UPDATE`), native JSON (5.7+), FULLTEXT Search, native ENUM/SET, Generated Columns, CTEs and Window Functions (8.0+), Partitioning.
- **Critical rules:** `utf8mb4` ALWAYS (never `utf8`), `InnoDB` ALWAYS, without `RETURNING` (use `LAST_INSERT_ID()`), metadata via `information_schema`.
- **Skills:** `.gemini/skills/mysql-database/SKILL.md`
- **Rules:** `.cursor/rules/mysql-patterns.md`

### Threading & Multi-Threading

- **When to use:** Time-consuming operations that block the UI, parallel data processing, servers/workers, thread pools.
- **Approaches:** `TThread.CreateAnonymousThread` (simple), `TTask.Run` (modern PPL), `TParallel.For` (loops), `TFuture<T>` (asynchronous result), `TThread` legacy (permanent workers).
- **Rule of Thumb:** NEVER access VCL/FMX from secondary thread → `TThread.Synchronize` (blocking) or `TThread.Queue` (non-blocking).
- **Thread-Safety:** `TCriticalSection`, `TMonitor`, `TInterlocked`, `TThreadList<T>`, `TMultiReadExclusiveWriteSynchronizer`, `TThreadedQueue<T>`.
- **Skills:** `.gemini/skills/threading/SKILL.md`
- **Rules:** `.cursor/rules/threading-patterns.md`

## Framework Decision

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

## Common Combinations

| Frontend | Backend | Specific Components |
|----------|---------|-------------------------|
| DevExpress (VCL)| Dext.Entity ORM | Modern Monolithic Desktop |
| Intraweb (Web) | Intraweb (Stateful)| Fast Web Portability, Single Binary, UserSession |
| Web App (JS) | Dext Framework API | Web App consuming corporate API |
| VCL/FMX | Horse API | App consuming minimalist API |
| POS (VCL) | Horse API / Local| ACBr Project for Printers/TEF/NFC-e |

## Transversal Golden Rule (Memory and Exceptions)

Regardless of the chosen framework or ecosystem:
1. **Zero the possibility of Memory Leaks**: Any Class without `Reference Count` and without `Owner` injected must be instantiated next to a `try` and released in the `finally` block.
2. **Transparent and Domain Exceptions**: Do not "silence" generic error processing (`on E: Exception do`). Transform Infrastructure into typed exceptions and ensure correct propagation (DDDErrors), letting the Framework intercept in the global handler for the UI.

## General Rules for All Frameworks

- SOLID applies regardless of the framework
- Clean Code applies regardless of the framework
- Pascal Guide nomenclature always applies
- Unit tests with DUnitX are mandatory
- Separation of layers (Domain, Application, Infrastructure, Presentation) applies to everyone

