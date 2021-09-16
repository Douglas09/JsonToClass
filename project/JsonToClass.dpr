program JsonToClass;

uses
  System.StartUpCopy,
  FMX.Forms,
  form.principal in '..\form.principal.pas' {Form8},
  resource.json in '..\resource.json.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm8, Form8);
  Application.Run;
end.
