# Aplicação Delphi para Copiar Arquivos

Criar uma aplicação VCL simples para copiar arquivos de uma pasta para outra, seguindo as convenções do Delphi AI Spec-Kit.

## Proposed Changes

### Projeto FileCopy

Todos os arquivos serão criados em `examples/file-copy-app/`.

#### [NEW] [FileCopy.dpr](file:///c:/i9/Palestras/ACBr/delphi-spec-kit/examples/file-copy-app/FileCopy.dpr)
Arquivo de projeto Delphi.

#### [NEW] [FileCopy.Main.View.pas](file:///c:/i9/Palestras/ACBr/delphi-spec-kit/examples/file-copy-app/FileCopy.Main.View.pas)
Form principal com:
- `TEdit` + `TButton` para selecionar pasta de origem (com `TFileOpenDialog`)
- `TEdit` + `TButton` para selecionar pasta de destino
- `TListBox` para exibir os arquivos da pasta de origem
- `TButton` para copiar todos os arquivos
- `TProgressBar` para indicar progresso da cópia
- `TStatusBar` para mensagens de status

#### [NEW] [FileCopy.Main.View.dfm](file:///c:/i9/Palestras/ACBr/delphi-spec-kit/examples/file-copy-app/FileCopy.Main.View.dfm)
Definição visual do form (layout organizado com painéis).

#### [NEW] [FileCopy.Service.Copier.pas](file:///c:/i9/Palestras/ACBr/delphi-spec-kit/examples/file-copy-app/FileCopy.Service.Copier.pas)
Service isolado com a lógica de cópia, separando da UI (SRP):
- `IFileCopierService` — interface
- `TFileCopierService` — implementação usando `TFile.Copy`
- Callback `TOnFileCopied` para reportar progresso

## Verification Plan

### Manual Verification
1. Abrir `FileCopy.dpr` no RAD Studio
2. Compilar e executar (F9)
3. Selecionar uma pasta de origem com arquivos
4. Selecionar uma pasta de destino
5. Clicar em "Copiar" e verificar que os arquivos são copiados e o progresso é exibido
