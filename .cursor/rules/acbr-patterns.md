---
description: "ACBr Project - Good practices, prefixes, dependency injection and isolation of fiscal components"
globs: ["**/*.pas", "**/*.dfm"]
alwaysApply: false
---

# ACBr Project — Cursor Rules

Use these rules when working with components from the **ACBr Project** suite (Commercial Automation Brazil) in Delphi applications.

## Insulation and Standards (SOLID)

- ❌ **Do not instantiate or attach ACBr components directly to UI forms** (e.g. placing a `TACBrNFe` inside `TfrmEmissao`).
- ✅ **Create abstractions or Service classes** (ex: `TNFeService`) in Domain/Infra Modules that encapsulate `TACBrNFe`.
- The form should only trigger one interface, for example: `INFeService.Emitir(Nota)`.

## Memory Management

- ACBr components created dynamically in Services **always** must be released appropriately (Try/Finally or created as Child of DataModules maintained by injection).
  
```pascal
//Encapsulated dynamic creation example
var
  LAcbrNFe: TACBrNFe;
begin
  LAcbrNFe := TACBrNFe.Create(nil);
  try
    //Settings and usage
    LAcbrNFe.Configuracoes.Certificados.NumeroSerie := 'XYZ';
  finally
    LAcbrNFe.Free;
  end;
end;
```

## Dynamic Settings

- Avoid reading from `.ini` files via UI. Load the configurations via a system configuration layer (`IConfiguration`) and inject it into the service that encapsulates the ACBr.

## Error and Return Handling

- Catch ACBr specific exceptions when possible.
- Convert long component returns (e.g. status, rejection reasons) into application Object Results/Records instead of tying the application to the component's natural formatting string.

## Prefix Conventions (UI/Design Time)

If you need to drop the component or instantiate it at runtime, follow these naming conventions:
- **TACBrNFe:** `acbrNFe`
- **TACBrCTe:** `acbrCTe`
- **TACBrBoleto:** `acbrBoleto`
- **TACBrTEFD:** `acbrTef`
- **TACBrPosPrinter:** `acbrPosPrinter`
- **TACBrECF:** `acbrEcf`
- **TACBrCEP:** `acbrCep`

