# Delphi Application to Copy Files

Create a simple VCL application to copy files from one folder to another, following Delphi AI Spec-Kit conventions.

## Proposed Changes

### FileCopy Project

All files will be created in `examples/file-copy-app/`.

#### [NEW] [FileCopy.dpr](file:///c:/i9/Palestras/ACBr/delphi-spec-kit/examples/file-copy-app/FileCopy.dpr)
Delphi project file.

#### [NEW] [FileCopy.Main.View.pas](file:///c:/i9/Palestras/ACBr/delphi-spec-kit/examples/file-copy-app/FileCopy.Main.View.pas)
Main form with:
- `TEdit` + `TButton` to select source folder (with `TFileOpenDialog`)
- `TEdit` + `TButton` to select destination folder
- `TListBox` to display files from the source folder
- `TButton` to copy all files
- `TProgressBar` to indicate copy progress
- `TStatusBar` for status messages

#### [NEW] [FileCopy.Main.View.dfm](file:///c:/i9/Palestras/ACBr/delphi-spec-kit/examples/file-copy-app/FileCopy.Main.View.dfm)
Visual definition of the form (layout organized with panels).

#### [NEW] [FileCopy.Service.Copier.pas](file:///c:/i9/Palestras/ACBr/delphi-spec-kit/examples/file-copy-app/FileCopy.Service.Copier.pas)
Service isolated with copy logic, separating from the UI (SRP):
- `IFileCopierService` — interface
- `TFileCopierService` — implementation using `TFile.Copy`
- Callback `TOnFileCopied` to report progress

## Verification Plan

### Manual Verification
1. Open `FileCopy.dpr` in RAD Studio
2. Compile and Run (F9)
3. Select a source folder with files
4. Select a destination folder
5. Click "Copy" and check that the files are copied and the progress is displayed
