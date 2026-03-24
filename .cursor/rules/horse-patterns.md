---
description: "Padrões Horse REST API — rotas, middleware, controllers, JSON responses"
globs: ["**/*.pas"]
alwaysApply: false
---

# Horse Framework — Cursor Rules

Use estas regras ao desenvolver APIs REST com o framework Horse.

## Estrutura de Controller

- Controller é uma classe com `class procedure RegisterRoutes`
- Cada handler: `class procedure Nome(AReq: THorseRequest; ARes: THorseResponse; ANext: TProc)`
- Controllers NÃO acessam banco diretamente — delegam para Services

## Convenções de Rotas

| Verbo | Rota | Handler | Status |
|-------|------|---------|--------|
| GET | `/api/customers` | `GetAll` | 200 |
| GET | `/api/customers/:id` | `GetById` | 200 / 404 |
| POST | `/api/customers` | `Create` | 201 |
| PUT | `/api/customers/:id` | `Update` | 200 |
| DELETE | `/api/customers/:id` | `Delete` | 204 |

## Middleware Obrigatórios

```pascal
THorse.Use(Jhonson);           // JSON automático
THorse.Use(CORS);              // Cross-Origin
THorse.Use(HandleException);   // Error handler global
```

## Padrões de Resposta

```pascal
// Sucesso com JSON
ARes.Send<TJSONObject>(LResult).Status(THTTPStatus.OK);

// Criação
ARes.Send('Created').Status(THTTPStatus.Created);

// Não encontrado
ARes.Send('Not found').Status(THTTPStatus.NotFound);

// Erro de validação
ARes.Send(E.Message).Status(THTTPStatus.BadRequest);
```

## Proibições em Horse

- ❌ Acessar `TFDConnection` direto no controller
- ❌ Lógica de negócio no handler
- ❌ Rotas sem tratamento de erro
- ❌ Concatenar SQL no controller
- ❌ Ignorar status HTTP
