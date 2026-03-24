---
name: Intraweb Framework
description: Guias e padrões para o uso do framework web stateful Intraweb em projetos Delphi.
---

# Intraweb Framework - Spec-Kit

Intraweb é um framework VCL-for-the-Web que permite que você crie aplicações web de negócios estado de forma semântica parecida à criação de aplicações Desktop. Ao lidar com o Intraweb no Copilot ou no projeto, considere as seguintes práticas recomendadas para garantir a manutenibilidade e escalabilidade.

## 1. Sessões (UserSession) e Variáveis Globais
**Regra de Ouro:** Não use variáveis globais clássicas de unit `var` ou instâncias Singleton para dados de usuários, uma vez que aplicações Intraweb rodam em ambiente Multithread com sessões concorrentes (cada usuário tem a sua).
- Para manter dados específicos do usuário, utilize estritamente a unidade `UserSessionUnit.pas` (Instância `ServerController.UserSession`).

```pascal
// ❌ RUIM: Uso Incorreto (Variável de escopo global atende todos as sessões, problema de Multithreading)
var
  LCustomerId: Integer;

// ✅ BOM: Uso Correto (Propriedades seguras do contexto atual)
UserSession.CustomerId := 10;
```

## 2. ServerController e Configuração
As parametrizações globais do sistema, pool de conexões ao banco e inicializações que não dependem do usuário devem ser resolvidas no objeto `ServerController` (`IWServerController.pas`). Evite tratar injeção de dependências pesadas e escopos de banco direto nos `TIWAppForm`.

## 3. Interfaces de Usuário Não Bloqueantes (Callbacks Assíncronos)
No contexto web, você não deve usar código bloqueante para "esperar" o usuário, como chamadas de `ShowMessage`, `InputBox` ou ModalResults clássicos da VCL que dependem do travamento do código na mesma linha.
- Utilize a propriedade `OnAsyncClick` para atualizações de DOM sem postback na tela toda.
- No Intraweb versão 15 ou mais recente, explore os recursos de `WebApplication.ShowMessage` combinados com chamadas por Ajax e interrupções seguras de interface web.

```pascal
// ❌ RUIM: Bloqueando a thread no Intraweb 
procedure TIWForm1.iwBtnSaveClick(Sender: TObject);
begin
  if Application.MessageBox('Deseja salvar?', 'Confirme', MB_YESNO) = IDYES then
    // Código de salvamento
end;

// ✅ BOM: Usando Ajax Async do Intraweb
procedure TIWForm1.iwBtnSaveAsyncClick(Sender: TObject; EventParams: TStringList);
begin
  WebApplication.ShowMessage('Registro Salvo via Callback Assíncrono!', smAlert);
end;
```

## 4. Separação de Regras e UI
É fácil construir projetos monstruosos no Intraweb agrupando toda a regra do sistema por de trás do clique (ex: num `iwBtnProcessarAsyncClick`). Siga os princípios de SRP (Single Responsibility Principle):
- O formulário mapeia para a requisição de Controller e re-renderiza componentes. As regras continuam na camada *Application/Services*.
- Uma camada Application/Service ou Repositório que for usada no Intraweb **não pode acoplar nem conhecer** o unit `IWApplication` (não use `WebApplication.ShowMessage` dentre os Services de persistência). 

## 5. Nomenclatura de Componentes Visuais (Prefixos Intraweb)
Utilize `iw` concatenado com as tipologias nativas:
- `TIWButton` -> `iwBtnSave`
- `TIWEdit` -> `iwEdtName`
- `TIWLabel` -> `iwLblTitle`
- `TIWComboBox` -> `iwCmbStatus`
- `TIWGrid` -> `iwGrdItems`
- `TIWRegion` -> `iwRegContainer`

## 6. HTML Dinâmico e Custom CSS
Apesar de ser VCL-like, as estilizações massivas nos componentes criam DOMS grandes na interface. Prefira definir arquivos externos CSS usando a injeção em `ExtraHeader` no formulário e aplique a propriedade `Css` nas tags dos T componentes visuais `TIW*` no lugar de pintar manualmente a cor dos botões e fontes via Inspector de Objetos.
