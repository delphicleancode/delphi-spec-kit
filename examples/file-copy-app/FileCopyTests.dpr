program FileCopyTests;

{$IFNDEF TESTINSIGHT}
{$APPTYPE CONSOLE}
{$ENDIF}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ENDIF}
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  FileCopy.Service.Copier in 'FileCopy.Service.Copy.pas',
  FileCopy.Service.Copier.Tests in 'FileCopy.Service.Copy.Tests.pas';

{$IFNDEF TESTINSIGHT}
var
  LRunner: ITestRunner;
  LResults: IRunResults;
  LLogger: ITestLogger;
  LNUnitLogger: ITestLogger;
{$ENDIF}

begin
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX.RunRegisteredTests;
  {$ELSE}
  try
    // Check if any fixtures have been registered
    TDUnitX.CheckCommandLine;

    // Create the runner
    LRunner := TDUnitX.CreateRunner;
    LRunner.UseRTTI := True;
    LRunner.FailsOnNoAsserts := False;

    // Console logger
    LLogger := TDUnitXConsoleLogger.Create(True);
    LRunner.AddLogger(LLogger);

    // NUnit XML Logger
    LNUnitLogger := TDUnitXXMLNUnitFileLogger.Create(
      TDUnitX.Options.XMLOutputFile);
    LRunner.AddLogger(LNUnitLogger);

    // Run tests
    LResults := LRunner.Execute;

    // Display result in console
    if not LResults.AllPassed then
      System.ExitCode := EXIT_FAILURE
    else
      System.ExitCode := EXIT_SUCCESS;

    {$IFNDEF CI}
    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
    begin
      System.Write('Press ENTER to exit...');
      System.Readln;
    end;
    {$ENDIF}
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
  {$ENDIF}
end.

