---
description: Best practices for memory management (try..finally), memory leaks and focused exception handling in Delphi
globs: *.pas, *.dfm, *.fmx, *.dpr, *.dpk
---

# Memory Rules and Exceptions (Delphi)

- **Always use `try..finally`** as soon as you instantiate an object (`.Create`), placing `.Free` or `FreeAndNil()` in `finally`. The opening of `try` must be IMMEDIATELY on the next line of creation.
- **DO NOT create multiple objects outside of a safe block.** If you have dependencies between them, nest the `try..finally` blocks. Instantiated, `try` in the bottom line.
- **Prefer Interfaces (IInterface)** whenever building injectable Services and Repository classes to benefit from the compiler's Reference Count Management (ARC), reducing pollution and eliminating the risk of instantiating without `Free` calls.
- **DO NOT "Shut" Exceptions:** When implementing `try..except` blocks, always define the exact type of error to be handled (Ex: `on E: EFDDBEngineException do`). DO NOT use generic blind exceptions or brutal suppression (`try ... except ... end`) unless explicitly required and with extensive documentation/justification.
- **DDD Exceptions:** For business logic failures, throw custom Exceptions that inherit from `Exception` (Ex: `raise EBusinessRuleException.Create('Idade inválida para essa operação');`).
- **Safe Relaunch:** Use the pure word `raise;` when you want to replay the stacktrace forward in a `except`. Standard: Infra processing, capture/intercept/log and pure `raise;`.
