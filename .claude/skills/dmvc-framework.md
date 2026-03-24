---
name: "DelphiMVCFramework"
description: "Padrões para desenvolvimento com DelphiMVCFramework (DMVC) — controllers, Active Record, JWT, Swagger"
---

# DelphiMVCFramework (DMVC) — Skill

Use esta skill ao criar aplicações web e APIs REST com o **DelphiMVCFramework**.

## Quando Usar

- Ao criar APIs REST com arquitetura MVC
- Ao usar Active Record para acesso a dados
- Ao implementar autenticação JWT
- Ao gerar documentação Swagger/OpenAPI

## Sobre o DMVC

DelphiMVCFramework é o framework MVC mais completo para Delphi, criado por Daniele Teti. Suporta RESTful APIs, Server-Sent Events, WebSockets, Active Record, serialização JSON/XML e muito mais.

- **Repositório:** [github.com/danieleteti/delphimvcframework](https://github.com/danieleteti/delphimvcframework)
- **Instalação:** Clonar repositório e adicionar paths, ou via Boss/Delphinus

## Estrutura de Projeto

```
src/
├── MeuApp.dpr                          ← Projeto principal
├── MeuApp.WebModule.pas                ← WebModule com engine DMVC
├── Controllers/
│   ├── MeuApp.Controller.Customer.pas
│   ├── MeuApp.Controller.Product.pas
│   └── MeuApp.Controller.Base.pas
├── Models/
│   ├── MeuApp.Model.Customer.pas       ← Active Record
│   ├── MeuApp.Model.Product.pas
│   └── MeuApp.Model.Base.pas
├── Services/
│   └── MeuApp.Service.Customer.pas
├── Middleware/
│   ├── MeuApp.Middleware.Auth.pas
│   └── MeuApp.Middleware.CORS.pas
└── Config/
    └── MeuApp.Config.pas
```

## WebModule (Bootstrap)

```pascal
unit MeuApp.WebModule;

interface

uses
  System.SysUtils,
  System.Classes,
  Web.HTTPApp,
  MVCFramework,
  MVCFramework.Commons;

type
  TAppWebModule = class(TWebModule)
    procedure WebModuleCreate(Sender: TObject);
    procedure WebModuleDestroy(Sender: TObject);
  private
    FMVCEngine: TMVCEngine;
  end;

implementation

uses
  MVCFramework.Middleware.CORS,
  MVCFramework.Middleware.JWT,
  MVCFramework.Middleware.StaticFiles,
  MeuApp.Controller.Customer,
  MeuApp.Controller.Product;

procedure TAppWebModule.WebModuleCreate(Sender: TObject);
begin
  FMVCEngine := TMVCEngine.Create(Self,
    procedure(AConfig: TMVCConfig)
    begin
      AConfig[TMVCConfigKey.DocumentRoot] := 'public';
      AConfig[TMVCConfigKey.DefaultContentType] := TMVCMediaType.APPLICATION_JSON;
      AConfig[TMVCConfigKey.DefaultViewFileExtension] := 'html';
    end
  );

  // Controllers
  FMVCEngine.AddController(TCustomerController);
  FMVCEngine.AddController(TProductController);

  // Middleware
  FMVCEngine.AddMiddleware(TMVCCORSMiddleware.Create);
end;

procedure TAppWebModule.WebModuleDestroy(Sender: TObject);
begin
  FMVCEngine.Free;
end;
```

## Padrão de Controller

```pascal
unit MeuApp.Controller.Customer;

interface

uses
  MVCFramework,
  MVCFramework.Commons,
  MVCFramework.Serializer.Commons;

type
  [MVCPath('/api/customers')]
  TCustomerController = class(TMVCController)
  public
    [MVCPath]
    [MVCHTTPMethod([httpGET])]
    [MVCProduces(TMVCMediaType.APPLICATION_JSON)]
    procedure GetAll;

    [MVCPath('/($id)')]
    [MVCHTTPMethod([httpGET])]
    [MVCProduces(TMVCMediaType.APPLICATION_JSON)]
    procedure GetById(const AId: Integer);

    [MVCPath]
    [MVCHTTPMethod([httpPOST])]
    [MVCConsumes(TMVCMediaType.APPLICATION_JSON)]
    [MVCProduces(TMVCMediaType.APPLICATION_JSON)]
    procedure CreateCustomer;

    [MVCPath('/($id)')]
    [MVCHTTPMethod([httpPUT])]
    [MVCConsumes(TMVCMediaType.APPLICATION_JSON)]
    procedure UpdateCustomer(const AId: Integer);

    [MVCPath('/($id)')]
    [MVCHTTPMethod([httpDELETE])]
    procedure DeleteCustomer(const AId: Integer);
  end;

implementation

uses
  System.SysUtils,
  MVCFramework.ActiveRecord,
  MeuApp.Model.Customer;

procedure TCustomerController.GetAll;
var
  LCustomers: TMVCActiveRecordList;
begin
  LCustomers := TMVCActiveRecord.SelectRQL<TCustomer>('', 100);
  Render<TCustomer>(LCustomers);
end;

procedure TCustomerController.GetById(const AId: Integer);
var
  LCustomer: TCustomer;
begin
  LCustomer := TMVCActiveRecord.GetByPK<TCustomer>(AId);
  if not Assigned(LCustomer) then
  begin
    Render(HTTP_STATUS.NotFound, 'Customer not found');
    Exit;
  end;
  Render(LCustomer);
end;

procedure TCustomerController.CreateCustomer;
var
  LCustomer: TCustomer;
begin
  LCustomer := Context.Request.BodyAs<TCustomer>;
  try
    LCustomer.Insert;
    Render201Created('/api/customers/' + LCustomer.Id.ToString);
  except
    on E: Exception do
    begin
      LCustomer.Free;
      raise;
    end;
  end;
end;

procedure TCustomerController.UpdateCustomer(const AId: Integer);
var
  LCustomer: TCustomer;
begin
  LCustomer := Context.Request.BodyAs<TCustomer>;
  try
    LCustomer.Id := AId;
    LCustomer.Update;
    Render(HTTP_STATUS.OK, 'Updated');
  except
    on E: Exception do
    begin
      LCustomer.Free;
      raise;
    end;
  end;
end;

procedure TCustomerController.DeleteCustomer(const AId: Integer);
var
  LCustomer: TCustomer;
begin
  LCustomer := TMVCActiveRecord.GetByPK<TCustomer>(AId);
  if not Assigned(LCustomer) then
  begin
    Render(HTTP_STATUS.NotFound, 'Customer not found');
    Exit;
  end;

  try
    LCustomer.Delete;
    Render(HTTP_STATUS.NoContent, '');
  finally
    LCustomer.Free;
  end;
end;
```

## Active Record (Model)

```pascal
unit MeuApp.Model.Customer;

interface

uses
  MVCFramework.ActiveRecord,
  MVCFramework.Serializer.Commons;

type
  [MVCTable('customers')]
  [MVCNameCase(ncLowerCase)]
  TCustomer = class(TMVCActiveRecord)
  private
    [MVCTableField('id', [foPrimaryKey, foAutoGenerated])]
    FId: Integer;

    [MVCTableField('name')]
    FName: string;

    [MVCTableField('cpf')]
    FCpf: string;

    [MVCTableField('email')]
    FEmail: string;

    [MVCTableField('status')]
    FStatus: Integer;

    [MVCTableField('created_at')]
    FCreatedAt: TDateTime;
  public
    property Id: Integer read FId write FId;
    property Name: string read FName write FName;
    property Cpf: string read FCpf write FCpf;
    property Email: string read FEmail write FEmail;
    property Status: Integer read FStatus write FStatus;
    property CreatedAt: TDateTime read FCreatedAt write FCreatedAt;
  end;

implementation

end.
```

## Middleware JWT

```pascal
uses
  MVCFramework.Middleware.JWT;

// No WebModule:
FMVCEngine.AddMiddleware(
  TMVCJWTAuthenticationMiddleware.Create(
    TAuthHandler.Create,   // implementa IMVCAuthenticationHandler
    'my-secret-key',
    '/api/login',          // rota pública de login
    [TJWTCheckableClaim.ExpirationTime]
  )
);
```

## RQL (Resource Query Language)

```pascal
// Filtrar via query string (DMVC interpreta RQL automaticamente)
// GET /api/customers?$filter=contains(name,'João')&$orderby=name&$top=10

LCustomers := TMVCActiveRecord.SelectRQL<TCustomer>(
  Context.Request.QueryStringParam('$filter'),
  Context.Request.QueryStringParam('$top').ToInteger
);
```

## Convenções DMVC

| Aspecto | Convenção |
|---------|-----------|
| **Controller** | Herda de `TMVCController` com `[MVCPath]` attribute |
| **Models** | Herda de `TMVCActiveRecord` com `[MVCTable]` attribute |
| **Rotas** | Attributes: `[MVCPath]`, `[MVCHTTPMethod]` |
| **Serialização** | Automática via `Render()` (JSON por padrão) |
| **Parâmetros** | Path: `($id)`, Query: `Context.Request.QueryStringParam` |
| **Body** | `Context.Request.BodyAs<T>` para deserializar JSON |
| **Status** | `Render(HTTP_STATUS.OK)`, `Render201Created` |
| **Middleware** | Herda de `TMVCCustomMiddleware` ou usa built-in |
| **Swagger** | Attributes `[MVCSwagSummary]`, `[MVCSwagParam]` |

## Checklist para Projetos DMVC

- [ ] WebModule configurado com `TMVCEngine`?
- [ ] Controllers registrados com `AddController`?
- [ ] Middleware CORS adicionado?
- [ ] Active Record models com `[MVCTable]` e `[MVCTableField]`?
- [ ] Rotas seguem padrão RESTful?
- [ ] `Render()` usado para todas as respostas?
- [ ] JWT middleware para rotas protegidas?
- [ ] Objetos `BodyAs<T>` liberados em caso de exception?
