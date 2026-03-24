---
description: "Dext Framework - Padrões de Minimal API, Injeção de Dependência, Model Binding e Entity ORM"
globs: ["**/*.pas"]
alwaysApply: false
---

# Dext Framework — Cursor Rules

Use estas regras ao desenvolver APIs REST ou aplicações usando o **Dext Framework** (https://github.com/cesarliws/dext), focado em padrões .NET para Delphi.

## Estrutura de Rotas (Minimal API)

- Configure rotas usando a sintaxe fluente e concisa com `App.Builder.MapGet` e `MapPost`.
- Prefira DTOs como parâmetros das funções anônimas para usar o *Model Binding* automático.

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

## Injeção de Dependências (DI)

- O Dext resolve as dependências automaticamente nos endpoints de Minimal API.
- Registre os serviços antes do mapeamento de rotas.

```pascal
App.Services.AddSingleton<IEmailService, TEmailService>;
App.Services.AddScoped<ICustomerRepository, TCustomerRepository>;
```

## Dext.Entity (ORM)

- O ORM usa a Fluent Query API. Evite strings mágicas de SQL.
- Modelos são Code-First com classes puras. Use atributos `[DbType]` ou `[Tabela/Campo]` dependendo da versão.
- Use as Expressões de Query (Smart Properties) para filtros (ex: `U.Age > 18`).

```pascal
// Consulta com Dext.Entity
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

## Asserções e Respostas (Fluent API)

- O Dext trata a serialização nativamente. Entregue Records/Class ou use `Results.Ok(...)`, `Results.Created(...)`.
- Utilize os blocos `TAsyncTask.Run` para processamento background retornando Threads reais na UI thread usando `.OnComplete`.

## Proibições para Dext Framework

- ❌ Não construa Queries concatenando strings. Use a Fluent Query API do Dext.Entity (`.Where`, `.Select`).
- ❌ Não instancie Services manualmente. Use a injeção do Container em `App.Services`.
- ❌ Não use bibliotecas antigas de JSON se a performance for crítica, o Dext lida com serialização UTF-8 internamente em Minimal APIs.
- ❌ Não confunda os componentes DevExpress com este framework Dext (Core/ORM/Web).
