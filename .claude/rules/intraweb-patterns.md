---
description: Regras e padrões de código para o desenvolvimento de aplicações com o framework Intraweb.
globs: *.pas, *.dfm, *.iw
---

# Intraweb Patterns - Claude Rule

Ao desenvolver uma aplicação web nativa no Delphi utilizando o framework Intraweb, você está trabalhando com um ambiente stateful para o browser hospedado por múltiplas threads isoladas. Aplique estritamente as diretrizes abaixo.

## 1. Concorrência e Sessões (`UserSession`)

- **Regra:** NUNCA utilize dados globais (`var` localizadas em `interface` ou instâncias Singleton abertas) para guardar dados de usuário online, credenciais e ID em cache. A aplicação é Web/Stateful/Threaded, essas variáveis vazarão cross-session.
- **Implementação:** Toda a guarda de estado transiente e identidades de quem está logado devem fluir de ou guardar em estruturas residentes do `TIWUserSession` mapeado no pool do ServerController:
  ```pascal
  // Exemplo seguro para contexto de requisição do usuário logado:
  LUsuarioId := UserSession.GetLoggedUserID;
  ```

## 2. Formulários Assíncronos (`Async Events`)

- **Regra:** Privilegie os eventos de classe `Async` no lugar de submissões tradicionais (`Postback`).
- **Implementação:** Interceptações como cliques em botões de salvar, cancelar ou mudar combos de dados devem priorizar métodos declarados nos eventos assíncronos (AJAX), mitigando reloading da DOM Inteira:
  ```pascal
  // Correto: Eventos Assíncronos (Ajax)
  procedure TIWFormClientes.iwBtnSalvarAsyncClick(Sender: TObject; EventParams: TStringList);
  begin
    // Gravações do banco e troca de cor na interface local
    iwLblStatus.Caption := 'Salvo!';
  end;
  ```

## 3. Ausência de Dialogs Bloqueantes
- **Regra:** Não use mecanismos síncronos da VCL Desktop (`ShowMessage`, `InputBox`, Retornos de Função Interativas ou exceptions que exibam erros Desktop visuais pelo sistema) no Intraweb.
- **Implementação:** Acione métodos `WebApplication.ShowMessage` ou callbacks e templates para guiar decisões do Usuário via frontend.

## 4. Ocultamento de Regras de Negócio (SRP)

- **Regra:** O `TIWAppForm` é a View (e vagamente seu controller/roteador). Nenhum motor de inserção primária do negócio não pode viver neste `TIWAppForm.pas`.
- **Implementação:** A classe de modelo injetable, `THouseService.Register()`, gerencia chamadas de manipulações de regra limpas de qualquer ligação com componentes do ServerController - Retornando dados abstratos passíveis da renderização no Forms.

## 5. Convenção Prefixada de Nomes `iw`

A família de componentes da paleta Intraweb deve possuir prefixo que demonstre a essência orientada sem erro:
- Formulários: `TIWFormLogin` `-> iwFormLogin`
- Botões: `TIWButton` `-> iwBtnAction`
- Campos Texto: `TIWEdit` `-> iwEdtUser`
- Container/Region: `TIWRegion` `-> iwRegWrapper`
- Grids: `TIWGrid` `-> iwGrdData`
