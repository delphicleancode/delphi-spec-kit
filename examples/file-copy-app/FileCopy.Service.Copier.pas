/// <summary>
/// Service responsible for the logic of copying files between directories.
/// Follows the SRP principle: the copy logic is isolated from the UI.
/// </summary>
unit FileCopy.Service.Copier;

interface

uses
  System.SysUtils,
  System.IOUtils,
  System.Types;

type
  /// <summary>Callback invoked after copying each file.</summary>
  /// <param name="AFileName">Name of the copied file</param>
  /// <param name="ACurrent">Current index (1-based)</param>
  /// <param name="ATotal">Total files</param>
  TOnFileCopied = reference to procedure(const AFileName: string;
    ACurrent, ATotal: Integer);

  /// <summary>File copy service interface.</summary>
  IFileCopierService = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    /// <summary>
    /// Lists files found in the source directory.
    /// </summary>
    function ListFiles(const ASourceDir: string): TStringDynArray;

    /// <summary>
    /// Copies all files from the source directory to the destination.
    /// </summary>
    /// <param name="ASourceDir">Source folder path</param>
    /// <param name="ADestDir">Destination folder path</param>
    /// <param name="AOnFileCopied">Progress callback (optional)</param>
    /// <returns>Number of files copied successfully</returns>
    function CopyFiles(const ASourceDir, ADestDir: string;
      AOnFileCopied: TOnFileCopied = nil): Integer;
  end;

  /// <summary>Concrete implementation of the copy service.</summary>
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
      'Source directory not found: %s', [ASourceDir]);

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
      'Source directory not found: %s', [ASourceDir]);

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

