---
description: Code rules and standards for developing applications with the Intraweb framework.
globs: *.pas, *.dfm, *.iw
---

# Intraweb Patterns - Claude Rule

When developing a native web application in Delphi using the Intraweb framework, you are working with a stateful environment for the browser hosted by multiple isolated threads. Strictly apply the guidelines below.

## 1. Competition and Sessions (`UserSession`)

- **Rule:** NEVER use global data (`var` located in `interface` or open Singleton instances) to cache online user data, credentials and ID. The application is Web/Stateful/Threaded, these variables will leak cross-session.
- **Implementation:** All transient state storage and logged-in identities must flow from or store in resident structures of the `TIWUserSession` mapped in the ServerController pool:
  ```pascal
  //Safe example for logged in user request context:
  LUsuarioId := UserSession.GetLoggedUserID;
  ```

## 2. Asynchronous Forms (`Async Events`)

- **Rule:** Favor class events `Async` over traditional submissions (`Postback`).
- **Implementation:** Interceptions such as clicking on save, cancel or change data combos buttons must prioritize methods declared in asynchronous events (AJAX), mitigating reloading of the entire DOM:
  ```pascal
  //Correct: Asynchronous Events (Ajax)
  procedure TIWFormClientes.iwBtnSalvarAsyncClick(Sender: TObject; EventParams: TStringList);
  begin
    //Bank recordings and color change in the local interface
    iwLblStatus.Caption := 'Salvo!';
  end;
  ```

## 3. Absence of Blocking Dialogs
- **Rule:** Do not use VCL Desktop synchronous mechanisms (`ShowMessage`, `InputBox`, Interactive Function Returns or exceptions that display visual Desktop errors across the system) in the Intraweb.
- **Implementation:** Trigger `WebApplication.ShowMessage` methods or callbacks and templates to guide User decisions via the frontend.

## 4. Business Rule Hiding (SRP)

- **Rule:** The `TIWAppForm` is the View (and loosely its controller/router). No business's primary insertion engine cannot live in this `TIWAppForm.pas`.
- **Implementation:** The injectable model class, `THouseService.Register()`, manages rule manipulation calls clean of any connection with ServerController components - Returning abstract data capable of rendering in Forms.

## 5. Prefixed Naming Convention `iw`

The Intraweb palette component family must have a prefix that demonstrates the oriented essence without error:
- Forms: `TIWFormLogin` `-> iwFormLogin`
- Buttons: `TIWButton` `-> iwBtnAction`
- Text Fields: `TIWEdit` `-> iwEdtUser`
- Container/Region: `TIWRegion` `-> iwRegWrapper`
- Grids: `TIWGrid` `-> iwGrdData`
