# Delphi AI Spec-Kit

This is the **Delphi AI Spec-Kit**, the master guide for Delphi (Object Pascal) development in this repository.

## Project Stack
- **Language:** Object Pascal (Delphi)
- **Native IDE:** RAD Studio / Delphi
- **Main Frameworks:** VCL, FMX, FireDAC
- **Tests:** DUnitX
- **Build / Tooling:** MSBuild, dcc32/dcc64, Boss (Package Manager)

## Crucial Directives (Memory Management)
- **Watched Blocks (Required):** EVERYTHING you instantiate with `.Create` (if it is `TObject` and does not have `Owner`) **MUST** have a `try..finally` on the IMMEDIATELY subsequent line.
  ```pascal
  Obj := TMyClass.Create;
  try
    Obj.DoSomething;
  finally
    Obj.Free; //my FreeAndNil(Obj)
  end;
  ```
- **DO NOT use** `with`.
- **DO NOT create** God Classes. Use SOLID Principles.
- Isolate visual components (FMX/VCL) from strict business rules. Do not access DBGrid or form edits in pure logical units.
- For dependency injection, pass abstractions in the constructor.

## File Organization & Naming (PascalCase)
- Classes: Start with `T` (ex: `TCustomer`).
- Interfaces: Start with `I` (ex: `ICustomer`).
- Exceptions: Start with `E` (ex: `EValidationError`).
- Private attributes or fields: Start with `F` (ex: `FName`).
- Local variables: Start with `L` (ex: `LCustomer`).
- Parameters: Start with `A` (ex: `ACustomer`).
- Unit nomenclature: `NomeProjeto.Camada.Dominio.Funcionalidade.pas`

*(See the `AGENTS.md` global file and `rules/` folder for guidelines specific to frameworks such as FireDAC, Rest, Horse and Database).*
