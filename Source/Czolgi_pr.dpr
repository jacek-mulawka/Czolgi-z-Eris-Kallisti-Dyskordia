program Czolgi_pr;

uses
  Vcl.Forms,
  Czolgi in 'Czolgi.pas' {Czolgi_Form};

{$R *.res}

begin

  //???ReportMemoryLeaksOnShutdown := DebugHook <> 0;

  Application.Initialize();
  Application.MainFormOnTaskbar := True;
  Application.HintHidePause := 30000;
  Application.CreateForm( TCzolgi_Form, Czolgi_Form );
  Application.Run();

end.
