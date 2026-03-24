# Estrutura e Convenções — Delphi

## Arquitetura em Camadas

```
src/
├── Domain/           ← Entidades, Value Objects, Interfaces de repositório
│   ├── Customer/
│   │   ├── MeuApp.Domain.Customer.Entity.pas
│   │   └── MeuApp.Domain.Customer.Repository.Intf.pas
│   └── Order/
│       ├── MeuApp.Domain.Order.Entity.pas
│       └── MeuApp.Domain.Order.Repository.Intf.pas
│
├── Application/      ← Services, Use Cases, DTOs
│   ├── Customer/
│   │   ├── MeuApp.Application.Customer.Service.pas
│   │   └── MeuApp.Application.Customer.Service.Intf.pas
│   └── Order/
│       └── MeuApp.Application.Order.Service.pas
│
├── Infrastructure/   ← Implementações concretas, acesso a dados
│   ├── Customer/
│   │   └── MeuApp.Infra.Customer.Repository.pas
│   ├── Database/
│   │   └── MeuApp.Infra.Database.Connection.pas
│   └── Factory/
│       └── MeuApp.Infra.Factory.pas
│
└── Presentation/     ← Forms VCL/FMX, ViewModels
    ├── Customer/
    │   ├── MeuApp.Presentation.Customer.List.pas
    │   └── MeuApp.Presentation.Customer.Edit.pas
    └── Main/
        └── MeuApp.Presentation.Main.pas
```

## Regra de Dependência

```
Presentation → Application → Domain ← Infrastructure
```

- **Domain** nunca depende de outras camadas
- **Application** depende apenas de Domain (interfaces)
- **Infrastructure** implementa interfaces de Domain
- **Presentation** depende de Application (via interfaces)

## Nomenclatura de Units

### Padrão
```
{Projeto}.{Camada}.{Domínio}.{Funcionalidade}.pas
```

### Exemplos por Camada

| Camada | Padrão | Exemplo |
|--------|--------|---------|
| Domain | `*.Domain.*.Entity.pas` | `MeuApp.Domain.Customer.Entity.pas` |
| Domain | `*.Domain.*.Repository.Intf.pas` | `MeuApp.Domain.Customer.Repository.Intf.pas` |
| Application | `*.Application.*.Service.pas` | `MeuApp.Application.Customer.Service.pas` |
| Infrastructure | `*.Infra.*.Repository.pas` | `MeuApp.Infra.Customer.Repository.pas` |
| Presentation | `*.Presentation.*.View.pas` | `MeuApp.Presentation.Customer.Edit.pas` |

## Nomenclatura de Componentes em Forms

| Componente | Prefixo | Exemplo |
|-----------|---------|---------|
| TButton | `btn` | `btnSave`, `btnCancel`, `btnSearch` |
| TEdit | `edt` | `edtName`, `edtEmail` |
| TLabel | `lbl` | `lblName`, `lblStatus` |
| TComboBox | `cmb` | `cmbStatus`, `cmbCity` |
| TDBGrid | `dbg` | `dbgCustomers`, `dbgOrders` |
| TPanel | `pnl` | `pnlTop`, `pnlButtons` |
| TPageControl | `pgc` | `pgcMain` |
| TTabSheet | `tab` | `tabSearch`, `tabEdit` |
| TDataSource | `ds` | `dsCustomers` |
| TFDQuery | `qry` | `qryCustomers` |
| TFDConnection | `con` | `conMain` |

## Seções da Unit

```pascal
unit NomeDaUnit;

interface                    // Parte pública

uses                         // Units necessárias (interface)

type                         // Declarações de tipo
  // 1. Enums e Records
  // 2. Interfaces
  // 3. Classes (public antes de published)

const                        // Constantes públicas

implementation               // Parte privada

uses                         // Units só necessárias na implementação

{ TMinhaClasse }             // Seções agrupadas por classe

end.
```
