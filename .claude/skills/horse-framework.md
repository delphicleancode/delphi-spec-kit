---
name: "Horse Framework"
description: "Padrões para desenvolvimento de APIs REST com Horse framework em Delphi"
---

# Horse Framework — Skill

Use esta skill ao criar APIs REST com o framework **Horse** em Delphi.

## Quando Usar

- Ao criar um novo projeto de API REST
- Ao adicionar rotas e endpoints
- Ao implementar middleware (JWT, CORS, logging)
- Ao integrar Horse com FireDAC

## Sobre o Horse

Horse é um framework REST minimalista e performático para Delphi, inspirado no Express.js (Node.js). Usa o conceito de middleware chain e é extremamente simples de configurar.

- **Repositório:** [github.com/HashLoad/horse](https://github.com/HashLoad/horse)
- **Instalação:** Boss (`boss install horse`) ou manual

## Estrutura de Projeto

```
src/
├── MeuApp.dpr                          ← Projeto principal
├── Controllers/
│   ├── MeuApp.Controller.Customer.pas
│   ├── MeuApp.Controller.Product.pas
│   └── MeuApp.Controller.Health.pas
├── Middleware/
│   ├── MeuApp.Middleware.Auth.pas
│   ├── MeuApp.Middleware.Logger.pas
│   └── MeuApp.Middleware.CORS.pas
├── Domain/
│   ├── MeuApp.Domain.Customer.Entity.pas
│   └── MeuApp.Domain.Customer.Repository.Intf.pas
├── Application/
│   └── MeuApp.Application.Customer.Service.pas
├── Infrastructure/
│   └── MeuApp.Infra.Customer.Repository.pas
└── Config/
    └── MeuApp.Config.Server.pas
```

## Configuração Básica do Servidor

```pascal
program MeuApp;

{$APPTYPE CONSOLE}

uses
  Horse,
  Horse.Jhonson,       // JSON middleware
  Horse.CORS,          // CORS middleware
  Horse.HandleException,
  MeuApp.Controller.Customer,
  MeuApp.Controller.Health;

begin
  THorse.Use(Jhonson);
  THorse.Use(CORS);
  THorse.Use(HandleException);

  // Registrar rotas
  TCustomerController.RegisterRoutes;
  THealthController.RegisterRoutes;

  THorse.Listen(9000,
    procedure
    begin
      Writeln('Server running on port 9000');
    end
  );
end.
```

## Padrão de Controller

```pascal
unit MeuApp.Controller.Customer;

interface

uses
  Horse,
  System.JSON;

type
  TCustomerController = class
  public
    class procedure RegisterRoutes;
  private
    class procedure GetAll(AReq: THorseRequest; ARes: THorseResponse; ANext: TProc);
    class procedure GetById(AReq: THorseRequest; ARes: THorseResponse; ANext: TProc);
    class procedure Create(AReq: THorseRequest; ARes: THorseResponse; ANext: TProc);
    class procedure Update(AReq: THorseRequest; ARes: THorseResponse; ANext: TProc);
    class procedure Delete(AReq: THorseRequest; ARes: THorseResponse; ANext: TProc);
  end;

implementation

uses
  System.SysUtils,
  MeuApp.Application.Customer.Service.Intf;

class procedure TCustomerController.RegisterRoutes;
begin
  THorse.Get('/api/customers', GetAll);
  THorse.Get('/api/customers/:id', GetById);
  THorse.Post('/api/customers', Create);
  THorse.Put('/api/customers/:id', Update);
  THorse.Delete('/api/customers/:id', Delete);
end;

class procedure TCustomerController.GetAll(
  AReq: THorseRequest; ARes: THorseResponse; ANext: TProc);
var
  LService: ICustomerService;
  LResult: TJSONArray;
begin
  LService := TServiceFactory.CreateCustomerService;
  LResult := LService.GetAllAsJSON;
  ARes.Send<TJSONArray>(LResult).Status(THTTPStatus.OK);
end;

class procedure TCustomerController.GetById(
  AReq: THorseRequest; ARes: THorseResponse; ANext: TProc);
var
  LService: ICustomerService;
  LId: Integer;
  LResult: TJSONObject;
begin
  LId := AReq.Params['id'].ToInteger;
  LService := TServiceFactory.CreateCustomerService;

  LResult := LService.GetByIdAsJSON(LId);
  if not Assigned(LResult) then
  begin
    ARes.Send('Customer not found').Status(THTTPStatus.NotFound);
    Exit;
  end;

  ARes.Send<TJSONObject>(LResult).Status(THTTPStatus.OK);
end;

class procedure TCustomerController.Create(
  AReq: THorseRequest; ARes: THorseResponse; ANext: TProc);
var
  LService: ICustomerService;
  LBody: TJSONObject;
begin
  LBody := AReq.Body<TJSONObject>;
  LService := TServiceFactory.CreateCustomerService;

  try
    LService.CreateFromJSON(LBody);
    ARes.Send('Created').Status(THTTPStatus.Created);
  except
    on E: EValidationException do
      ARes.Send(E.Message).Status(THTTPStatus.BadRequest);
    on E: EBusinessRuleException do
      ARes.Send(E.Message).Status(THTTPStatus.Conflict);
  end;
end;
```

## Middleware Personalizado

```pascal
unit MeuApp.Middleware.Auth;

interface

uses
  Horse;

procedure AuthMiddleware(AReq: THorseRequest; ARes: THorseResponse; ANext: TProc);

implementation

uses
  System.SysUtils,
  Horse.JWT;

procedure AuthMiddleware(AReq: THorseRequest; ARes: THorseResponse; ANext: TProc);
var
  LToken: string;
begin
  LToken := AReq.Headers['Authorization'];

  if LToken.IsEmpty then
  begin
    ARes.Send('Token not provided').Status(THTTPStatus.Unauthorized);
    Exit;
  end;

  // Validar token JWT
  if not ValidateJWTToken(LToken) then
  begin
    ARes.Send('Invalid token').Status(THTTPStatus.Unauthorized);
    Exit;
  end;

  ANext; // continua para o próximo handler
end;

end.
```

## Middleware de Logger

```pascal
unit MeuApp.Middleware.Logger;

interface

uses
  Horse;

procedure LoggerMiddleware(AReq: THorseRequest; ARes: THorseResponse; ANext: TProc);

implementation

uses
  System.SysUtils,
  System.DateUtils;

procedure LoggerMiddleware(AReq: THorseRequest; ARes: THorseResponse; ANext: TProc);
var
  LStartTime: TDateTime;
begin
  LStartTime := Now;
  Writeln(Format('[%s] %s %s',
    [FormatDateTime('hh:nn:ss', Now),
     AReq.MethodType.ToString,
     AReq.RawWebRequest.PathInfo]));

  ANext;

  Writeln(Format('[%s] Completed in %dms',
    [FormatDateTime('hh:nn:ss', Now),
     MilliSecondsBetween(Now, LStartTime)]));
end;

end.
```

## Convenções para Horse

| Aspecto | Convenção |
|---------|-----------|
| **URLs** | Kebab-case, plural: `/api/customers`, `/api/order-items` |
| **Métodos HTTP** | GET (listar/buscar), POST (criar), PUT (atualizar), DELETE (remover) |
| **Status** | 200 OK, 201 Created, 400 Bad Request, 404 Not Found, 500 Internal |
| **Response** | Sempre JSON via `Jhonson` middleware |
| **Controller** | Class methods estáticos com `RegisterRoutes` |
| **Middleware** | Procedures standalone ou class methods |
| **Parâmetros** | Path: `AReq.Params['id']`, Query: `AReq.Query['search']` |

## Pacotes Complementares Horse

| Pacote | Uso | Instalação Boss |
|--------|-----|-----------------|
| `horse-jhonson` | JSON middleware | `boss install horse-jhonson` |
| `horse-cors` | CORS | `boss install horse-cors` |
| `horse-jwt` | Autenticação JWT | `boss install horse-jwt` |
| `horse-basic-auth` | Basic Auth | `boss install horse-basic-auth` |
| `horse-handle-exception` | Error handler | `boss install horse-handle-exception` |
| `horse-octet-stream` | Upload/download | `boss install horse-octet-stream` |

## Checklist para Projetos Horse

- [ ] `Jhonson` middleware registrado para JSON automático?
- [ ] `CORS` middleware registrado?
- [ ] `HandleException` middleware para error handling?
- [ ] Rotas seguem convenção RESTful (plural, kebab-case)?
- [ ] Controllers usam Services (não acessam repositório direto)?
- [ ] Guard clauses nos handlers antes da lógica?
- [ ] Status HTTP corretos nas respostas?
- [ ] Testes de integração com `TRESTClient` simulando chamadas?
