/// <summary>
///   Service responsável pela lógica de cópia de arquivos entre diretórios.
///   Segue o princípio SRP: a lógica de cópia fica isolada da UI.
/// </summary>
unit FileCopy.Service.Copier;

interface

uses
  System.SysUtils,
  System.IOUtils,
  System.Types;

type
  /// <summary>Callback invocado após copiar cada arquivo.</summary>
  /// <param name="AFileName">Nome do arquivo copiado</param>
  /// <param name="ACurrent">Índice atual (1-based)</param>
  /// <param name="ATotal">Total de arquivos</param>
  TOnFileCopied = reference to procedure(const AFileName: string;
    ACurrent, ATotal: Integer);

  /// <summary>Interface do serviço de cópia de arquivos.</summary>
  IFileCopierService = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    /// <summary>
    ///   Lista os arquivos encontrados no diretório de origem.
    /// </summary>
    function ListFiles(const ASourceDir: string): TStringDynArray;

    /// <summary>
    ///   Copia todos os arquivos do diretório de origem para o destino.
    /// </summary>
    /// <param name="ASourceDir">Caminho da pasta de origem</param>
    /// <param name="ADestDir">Caminho da pasta de destino</param>
    /// <param name="AOnFileCopied">Callback de progresso (opcional)</param>
    /// <returns>Quantidade de arquivos copiados com sucesso</returns>
    function CopyFiles(const ASourceDir, ADestDir: string;
      AOnFileCopied: TOnFileCopied = nil): Integer;
  end;

  /// <summary>Implementação concreta do serviço de cópia.</summary>
  TFileCopierService = class(TInterfacedObject, IFileCopierService)
  public
    function ListFiles(const ASourceDir: string): TStringDynArray;
    function CopyFiles(const ASourceDir, ADestDir: string;
      AOnFileCopied: TOnFileCopied = nil): Integer;
  end;

implementation

{ TFileCopierService }

function TFileCopierService.ListFiles(const ASourceDir: string): TStringDynArray;
begin
  if not TDirectory.Exists(ASourceDir) then
    raise EDirectoryNotFoundException.CreateFmt(
      'Diretório de origem não encontrado: %s', [ASourceDir]);

  Result := TDirectory.GetFiles(ASourceDir);
end;

function TFileCopierService.CopyFiles(const ASourceDir, ADestDir: string;
  AOnFileCopied: TOnFileCopied): Integer;
var
  LFiles: TStringDynArray;
  LFileName: string;
  LDestFile: string;
  I: Integer;
begin
  if not TDirectory.Exists(ASourceDir) then
    raise EDirectoryNotFoundException.CreateFmt(
      'Diretório de origem não encontrado: %s', [ASourceDir]);

  if not TDirectory.Exists(ADestDir) then
    TDirectory.CreateDirectory(ADestDir);

  LFiles := TDirectory.GetFiles(ASourceDir);
  Result := 0;

  for I := 0 to High(LFiles) do
  begin
    LFileName := TPath.GetFileName(LFiles[I]);
    LDestFile := TPath.Combine(ADestDir, LFileName);

    TFile.Copy(LFiles[I], LDestFile, True);
    Inc(Result);

    if Assigned(AOnFileCopied) then
      AOnFileCopied(LFileName, I + 1, Length(LFiles));
  end;
end;

end.
