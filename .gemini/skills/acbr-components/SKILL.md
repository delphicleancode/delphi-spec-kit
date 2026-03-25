---
name: ACBr Project Patterns
description: Architectural, dependency injection and UI patterns for the ACBr Project (Commercial Automation Brazil) ecosystem in Delphi.
---

# Standards for ACBr Project

The **ACBr Project** is vital for issuing NFe, CTe, NFCe, SAT, TEF and controlling fiscal/non-fiscal scales/printers in Brazil. It contains fantastic components, but due to its background and history of strong VCL coupling that accompanies older developers, the best practices below ensure maintainability in modernizations.

## 1. Rule of Thumb: No Strong Visual Coupling

Do not instantiate components `TACBrNFe`, `TACBrCTe`, `TACBrPosPrinter`, etc., directly in the View Forms of the interface (`.dfm`/`.fmx`). This breaks the clean architecture, MVC and makes unit testing immensely difficult.

### O Que Fazer?

Create Service "Wrapper" classes or Infrasctructure Repositories that inject (via constructor or Service Locator) the system configurations to the Fiscal Engine.

```pascal
type
  INFeEmissor = interface
    ['{GUID}']
    function EmitirNota(ANota: TBaseNFeModel): TEmissionResult;
  end;

  TNFeEmissorACBr = class(TInterfacedObject, INFeEmissor)
  private
    FAcbrNFe: TACBrNFe;
    FConfig: IAppConfig;
    procedure ConfigureComponent;
  public
    constructor Create(AConfig: IAppConfig);
    destructor Destroy; override;
    function EmitirNota(ANota: TBaseNFeModel): TEmissionResult;
  end;
```

## 2. Abstracting Signing and Cryptography Libraries (OpenSSL vs WinCrypt)

It is a documented good practice to also isolate the libraries for each OS version if the project is cross-platform or supports VMs (e.g. Linux Docker vs Windows).
Configure this *Always via code* dynamically within the wrapper referenced in Session 1, never at fixed design-time, using `LAcbrNFe.Configuracoes.Geral.SSLLib := libWinCrypt;` (or OpenSSL).

## 3. Handle Callbacks and Events (ex: TEF)

ACBrTEFD works heavily based on VCL events (OnExibeMensagem, OnAguardaDigitacao). Implement them by sending native bus events or defining a generic UI "Handler" injected into the class so that the component code remains in the Business/Gateway Layer, delegating only the "Draw to Screen" to specific interfaces that can be overridden in Headless/REST API scenarios.

```pascal
  ITefPresentationHandler = interface
    procedure ShowTefMessage(const Msg: string);
    procedure ClearTefMessage;
  end;
```

## 4. Dynamic Memory Management

If you instantiate sub-function components (e.g. ACBrCEP) dynamically, avoid memory leaks.

```pascal
function RetrieveAddress(const AZipCode: string): TAddressResponse;
var
  LCepComponent: TACBrCEP;
begin
  LCepComponent := TACBrCEP.Create(nil);
  try
    LCepComponent.WebService := wsViaCep;
    // Realiza a logic
    LCepComponent.BuscarPorCEP(AZipCode);
    Result := MapToResponse(LCepComponent.Enderecos[0]);
  finally
    LCepComponent.Free;
  end;
end;
```

## 5. Component Prefixes

When dealing with design-time components in `DataModules` created to facilitate events, use these mappings:

| ACBr component | Description | Typical Prefix |
|-----------------|-----------|----------------|
| `TACBrNFe` | Electronic Invoice | `acbrNfe` |
| `TACBrNFCe`| Consumer Note | `acbrNfce` |
| `TACBrCTe` | Knowledge of Transp. | `acbrCte` |
| `TACBrBoleto`| Bills | `acbrBoleto` |
| `TACBrTEFD`| TEF | `acbrTef` |
| `TACBrPosPrinter`| Printers (EscPOS) | `acbrPosPrinter`|
| `TACBrSAT` | SAT CF-e equipment | `acbrSat` |

