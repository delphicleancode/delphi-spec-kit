---
description: "Dext Framework - Minimal API, Dependency Injection, Model Binding and Entity ORM Patterns"
globs: ["**/*.pas"]
alwaysApply: false
---

# Dext Framework — Claude Rules

Use these rules when developing REST APIs or applications using the **Dext Framework** (https://github.com/cesarliws/dext), focused on .NET standards for Delphi.

## Route Structure (Minimal API)

- Configure routes using fluent and concise syntax with `App.Builder.MapGet` and `MapPost`.
- Prefer DTOs as parameters of anonymous functions to use automatic *Model Binding*.

```pascal
var App := WebApplication;
var Builder := App.Builder;

Builder.MapGet<Integer, IResult>('/users/{id}',
  function(Id: Integer): IResult
  begin
    Result := Results.Json(Format('{"userId": %d}', [Id]));
  end);

Builder.MapPost<TUserDto, IEmailService, IResult>('/register',
  function(Dto: TUserDto; EmailService: IEmailService): IResult
  begin
    EmailService.SendWelcome(Dto.Email);
    Result := Results.Created('/login', 'User registered');
  end);
```

## Dependency Injection (DI)

- Dext automatically resolves dependencies on Minimal API endpoints.
- Register services before route mapping.

```pascal
App.Services.AddSingleton<IEmailService, TEmailService>;
App.Services.AddScoped<ICustomerRepository, TCustomerRepository>;
```

## Dext.Entity (ORM)

- The ORM uses the Fluent Query API. Avoid magic SQL strings.
- Models are Code-First with pure classes. Use `[DbType]` or `[Tabela/Campo]` attributes depending on the version.
- Use Query Expressions (Smart Properties) for filters (ex: `U.Age > 18`).

```pascal
//Query with Dext.Entity
var Orders := DbContext.Orders
  .Where((O.Status = TOrderStatus.Paid) and (O.Total > 1000))
  .Include('Customer')
  .OrderBy(O.Date.Desc)
  .ToList;

// Bulk Update
DbContext.Products
  .Where(P.Category = 'Outdated')
  .Update
  .Execute;
```

## Assertions and Responses (Fluent API)

- Dext handles serialization natively. Deliver Records/Class or use `Results.Ok(...)`, `Results.Created(...)`.
- Use `TAsyncTask.Run` blocks for background processing returning real Threads in the UI thread using `.OnComplete`.

## Prohibitions for Dext Framework

- ❌ Do not build Queries by concatenating strings. Use Dext.Entity's Fluent Query API (`.Where`, `.Select`).
- ❌ Do not instantiate Services manually. Use Container injection in `App.Services`.
- ❌ Don't use old JSON libraries if performance is critical, Dext handles UTF-8 serialization internally in Minimal APIs.
- ❌ Don't confuse DevExpress components with this Dext framework (Core/ORM/Web).
