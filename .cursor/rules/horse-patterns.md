---
description: "Horse REST API patterns — routes, middleware, controllers, JSON responses"
globs: ["**/*.pas"]
alwaysApply: false
---

# Horse Framework — Cursor Rules

Use these rules when developing REST APIs with the Horse framework.

## Controller Structure

- Controller is a class with `class procedure RegisterRoutes`
- Cada handler: `class procedure Nome(AReq: THorseRequest; ARes: THorseResponse; ANext: TProc)`
- Controllers DO NOT access the bank directly — they delegate it to Services

## Route Conventions

| verb | Route | handlers | Status |
|-------|------|---------|--------|
| GET | `/api/customers` | `GetAll` | 200 |
| GET | `/api/customers/:id` | `GetById` | 200 / 404 |
| POST | `/api/customers` | `Create` | 201 |
| PUT | `/api/customers/:id` | `Update` | 200 |
| DELETE | `/api/customers/:id` | `Delete` | 204 |

## Mandatory Middleware

```pascal
THorse.Use(Jhonson);           //Automatic JSON
THorse.Use(CORS);              //Cross-Origin
THorse.Use(HandleException);   // Error handler global
```

## Response Patterns

```pascal
//Success with JSON
ARes.Send<TJSONObject>(LResult).Status(THTTPStatus.OK);

//Creation
ARes.Send('Created').Status(THTTPStatus.Created);

//Not found
ARes.Send('Not found').Status(THTTPStatus.NotFound);

//Validation error
ARes.Send(E.Message).Status(THTTPStatus.BadRequest);
```

## Bans on Horse

- ❌ Access `TFDConnection` directly from the controller
- ❌ Business logic in the handler
- ❌ Routes without error handling
- ❌ Concatenate SQL in the controller
- ❌ Ignore HTTP status
