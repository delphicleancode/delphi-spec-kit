---
name: Dext Framework Patterns
description: Padrões arquiteturais, Entity ORM, Minimal APIs e de injeção de dependência para projetos criados com Dext Framework (cesarliws/dext).
---

# Padrões Dext Framework (Delphi)

O **Dext Framework** é um ecossistema completo para Delphi, inspirado diretamente no **ASP.NET Core** e no **Spring Boot**. Ele se destina ao desenvolvimento corporativo de alta performance. Diferente do Horse ou DMVC, o Dext abraça a Injeção de Dependências, Minimal APIs com model binding automático e tem o próprio Entity ORM (`Dext.Entity`).

Este manual traz as convenções que devem ser seguidas pela IA ao codificar com Dext.

**Nota Importante:** Dext Framework **não** é abreviação para componentes visuais DevExpress/DevExtreme, e sim o projeto backend (https://github.com/cesarliws/dext).

## Princípios Core

1. **Roteamento Minimal (Minimal APIs):** Não utilize Controllers tradicionais MVC, a menos que necessário. Use sintaxe de roteamento funcional (`MapGet`, `MapPost`).
2. **Auto Model Binding:** Obtenha JSON body não via strings e conversões parciais, mas delegando a tipagem forte aos parâmetros anônimos da rota (`function(Dto: MyDto): IResult`).
3. **Container DI Integrado:** Toda dependência de interface deve ser resolvida via `App.Services` (Injection). Não use factories manuais.
4. **Smart ORM (Dext.Entity):** Nunca concatene SQL.

---

## 1. WebApp Lifecycle e DI

O Bootstrap de uma API Dext ocorre registrando serviços na mesma pipeline de rotas.

```pascal
program MyAPI;

uses Dext.Web, Services.Interfaces, Services.Implementations;

begin
  var App := WebApplication;
  var Builder := App.Builder;

  // 1. Registro de Serviços de Injeção de Dependências
  App.Services.AddSingleton<IEmailService, TEmailService>;
  App.Services.AddScoped<IOrderRepository, TOrderRepository>;

  // 2. Mapeamento de Rotas
  Builder.MapGet<IResult>('/health', 
    function: IResult
    begin
        Result := Results.Ok('{"status": "ok"}');
    end);

  // 3. Start
  App.Run(8080);
end.
```

---

## 2. Minimal APIs & Model Binding

A forma preferencial de construir APIs REST com o Dext é usando delegates anônimos tipados, com as dependências do DI passadas nos argumentos finais.

### Criar usuário (Post + DTO Body + Auth)

```pascal
type
  TCreateUserDto = record
    Name: string;
    Age: Integer;
  end;

// 'Dto' é populado via JSON do corpo da requisição automaticamente.
// 'Database' é injetado via DI.
Builder.MapPost<TCreateUserDto, IDatabaseService, IResult>('/users',
  function(Dto: TCreateUserDto; Database: IDatabaseService): IResult
  begin
    if Dto.Name.IsEmpty then
        Exit(Results.BadRequest('Name is required'));

    Database.SaveUser(Dto.Name, Dto.Age);
    
    Result := Results.Created('/users/new', 'User Created');
  end);
```

### Path Params & Query

```pascal
// Roteamento path-based tipado (Route parameter Binding)
Builder.MapGet<Integer, IResult>('/orders/{id}',
  function(Id: Integer): IResult
  begin
    var Order := FindOrder(Id);
    if Order = nil then
      Result := Results.NotFound
    else
      Result := Results.Ok(Order);
  end);
```

---

## 3. Dext.Entity (ORM & Smart Properties)

O mapeamento de Banco de Dados com Dext é focado em strongly typed query building e Classes "Code First".

### Consultas LINQ-Like

Evite uso de RTTI complexo ou ADOTables nativas se estiver no Dext. Entregue os resultados em Collections tipadas (`IList<T>`).

```pascal
uses Dext.Entity;

// P é a representação da Smart Property para a classe de contexto
var Products := DbContext.Products
  .Where((P.Price > 100) and (P.Stock > 0))  // 'and' bitwise/Smart property syntax
  .OrderBy(P.Name)
  .Take(10)
  .ToList;
```

### Entendendo "Update" em Massa via Dext.Entity

Com o Dext ORM, Updates podem rodar no banco de dados sem puxar os dados pra memória (como efetuado em Entity Framework Core moderno):

```pascal
DbContext.Orders
  .Where(O.Status = 'Pending')
  .Update
  .Execute;
```

---

## 4. Retornos (IResult)

Sempre retorne implementações baseadas em `IResult` em endpoints usando a factory `Results`.

- `Results.Ok( MeuRecord )` -> Status 200 + Serializa Automaticamente em JSON.
- `Results.Created('/rota', 'Msg')` -> Status 201 + Header "Location".
- `Results.NotFound` -> Status 404.
- `Results.BadRequest('Msg')` -> Status 400 bad request error.

---

## 5. Dext.Net Async Tasks e Resiliência (TAsyncTask)

O Dext inclui primitivas de promises/tasks mais modernas do que as puras `TTask` originais do Delphi.

```pascal
uses Dext.Core.Tasks; // Usar Task Flow da biblioteca central

TAsyncTask.Run<TUserProfile>(
  function: TUserProfile
  begin
    Result := ExternalService.Call();
  end)
  .OnComplete( // Callback chamado no contexto Sincrono/Main thread.
    procedure(Profile: TUserProfile)
    begin
        ShowVclMessage(Profile.Name);
    end)
  .OnException(
    procedure(Ex: Exception)
    begin
       LogError(Ex.Message);
    end)
  .Start;
```

---

## Checklist de Revisão (Dext Framework)

- **Rotas fluentes?** A aplicação usa `Builder.MapGet`/`MapPost` com binding implícito em vez de manipulação manual da request e parse de Body puro para json objects complexos?
- **O container DI foi alimentado?** Instâncias estão sendo passadas aos construtores/routers através de `App.Services`?
- **Sem Strings de Filtro em Módulos Data?** Utilizou as Smart Properties expressivas (`.Where(E.Price > 100)`) em vez de query concat?
- **Os retornos sãos baseados em records e objects POLD?** (Plain Old Delphi Objects, permitindo UTF-8 Zero Allocation JSON do Dext).
