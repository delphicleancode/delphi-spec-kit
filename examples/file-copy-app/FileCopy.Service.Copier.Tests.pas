/// <summary>
///   Testes unitários DUnitX para TFileCopierService.
///   Utiliza diretórios temporários criados e destruídos em cada teste.
/// </summary>
unit FileCopy.Service.Copier.Tests;

interface

uses
  System.SysUtils,
  System.IOUtils,
  System.Types,
  DUnitX.TestFramework,
  FileCopy.Service.Copier;

type
  [TestFixture]
  TFileCopierServiceTest = class
  private
    FService: IFileCopierService;
    FTempDir: string;
    FSourceDir: string;
    FDestDir: string;
    procedure CreateTempFiles(ACount: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure ListFiles_WithFiles_ReturnsCorrectCount;

    [Test]
    procedure ListFiles_EmptyDirectory_ReturnsEmptyArray;

    [Test]
    procedure ListFiles_NonExistentDirectory_RaisesException;

    [Test]
    procedure CopyFiles_WithFiles_CopiesAllFiles;

    [Test]
    procedure CopyFiles_NonExistentSource_RaisesException;

    [Test]
    procedure CopyFiles_NonExistentDest_CreatesDirectory;

    [Test]
    procedure CopyFiles_WithCallback_ReportsProgress;

    [Test]
    procedure CopyFiles_EmptySource_ReturnsZero;

    [Test]
    procedure CopyFiles_ExistingFile_OverwritesDestination;
  end;

implementation

{ TFileCopierServiceTest }

procedure TFileCopierServiceTest.Setup;
begin
  FService := TFileCopierService.Create;
  FTempDir := TPath.Combine(TPath.GetTempPath, 'FileCopyTest_' + TGUID.NewGuid.ToString);
  FSourceDir := TPath.Combine(FTempDir, 'source');
  FDestDir := TPath.Combine(FTempDir, 'dest');
  TDirectory.CreateDirectory(FSourceDir);
end;

procedure TFileCopierServiceTest.TearDown;
begin
  if TDirectory.Exists(FTempDir) then
    TDirectory.Delete(FTempDir, True);
end;

procedure TFileCopierServiceTest.CreateTempFiles(ACount: Integer);
var
  I: Integer;
  LFilePath: string;
begin
  for I := 1 to ACount do
  begin
    LFilePath := TPath.Combine(FSourceDir, Format('arquivo_%d.txt', [I]));
    TFile.WriteAllText(LFilePath, Format('Conteúdo do arquivo %d', [I]));
  end;
end;

procedure TFileCopierServiceTest.ListFiles_WithFiles_ReturnsCorrectCount;
var
  LFiles: TStringDynArray;
begin
  CreateTempFiles(3);

  LFiles := FService.ListFiles(FSourceDir);

  Assert.AreEqual(3, Length(LFiles));
end;

procedure TFileCopierServiceTest.ListFiles_EmptyDirectory_ReturnsEmptyArray;
var
  LFiles: TStringDynArray;
begin
  LFiles := FService.ListFiles(FSourceDir);

  Assert.AreEqual(0, Length(LFiles));
end;

procedure TFileCopierServiceTest.ListFiles_NonExistentDirectory_RaisesException;
begin
  Assert.WillRaise(
    procedure
    begin
      FService.ListFiles('C:\caminho\inexistente\xyz');
    end,
    EDirectoryNotFoundException);
end;

procedure TFileCopierServiceTest.CopyFiles_WithFiles_CopiesAllFiles;
var
  LCopied: Integer;
  LDestFiles: TStringDynArray;
begin
  CreateTempFiles(3);

  LCopied := FService.CopyFiles(FSourceDir, FDestDir);

  Assert.AreEqual(3, LCopied);
  LDestFiles := TDirectory.GetFiles(FDestDir);
  Assert.AreEqual(3, Length(LDestFiles));
end;

procedure TFileCopierServiceTest.CopyFiles_NonExistentSource_RaisesException;
begin
  Assert.WillRaise(
    procedure
    begin
      FService.CopyFiles('C:\caminho\inexistente\xyz', FDestDir);
    end,
    EDirectoryNotFoundException);
end;

procedure TFileCopierServiceTest.CopyFiles_NonExistentDest_CreatesDirectory;
var
  LCopied: Integer;
begin
  CreateTempFiles(1);

  LCopied := FService.CopyFiles(FSourceDir, FDestDir);

  Assert.AreEqual(1, LCopied);
  Assert.IsTrue(TDirectory.Exists(FDestDir));
end;

procedure TFileCopierServiceTest.CopyFiles_WithCallback_ReportsProgress;
var
  LCallbackCount: Integer;
  LLastCurrent: Integer;
  LLastTotal: Integer;
begin
  CreateTempFiles(3);
  LCallbackCount := 0;
  LLastCurrent := 0;
  LLastTotal := 0;

  FService.CopyFiles(FSourceDir, FDestDir,
    procedure(const AFileName: string; ACurrent, ATotal: Integer)
    begin
      Inc(LCallbackCount);
      LLastCurrent := ACurrent;
      LLastTotal := ATotal;
    end);

  Assert.AreEqual(3, LCallbackCount, 'Callback deveria ser chamado 3 vezes');
  Assert.AreEqual(3, LLastCurrent, 'Último ACurrent deveria ser 3');
  Assert.AreEqual(3, LLastTotal, 'ATotal deveria ser 3');
end;

procedure TFileCopierServiceTest.CopyFiles_EmptySource_ReturnsZero;
var
  LCopied: Integer;
begin
  LCopied := FService.CopyFiles(FSourceDir, FDestDir);

  Assert.AreEqual(0, LCopied);
end;

procedure TFileCopierServiceTest.CopyFiles_ExistingFile_OverwritesDestination;
var
  LDestFile: string;
  LContent: string;
begin
  CreateTempFiles(1);
  TDirectory.CreateDirectory(FDestDir);
  LDestFile := TPath.Combine(FDestDir, 'arquivo_1.txt');
  TFile.WriteAllText(LDestFile, 'conteúdo antigo');

  FService.CopyFiles(FSourceDir, FDestDir);

  LContent := TFile.ReadAllText(LDestFile);
  Assert.AreEqual('Conteúdo do arquivo 1', LContent);
end;

initialization
  TDUnitX.RegisterTestFixture(TFileCopierServiceTest);

end.
