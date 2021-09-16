unit form.principal;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, Json,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types,
  FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo, FMX.Objects, FMX.Layouts,
  resource.json, FMX.Edit;

type
  TForm8 = class(TForm)
    memClass: TMemo;
    lyClass: TLayout;
    rcClassTittle: TRectangle;
    Text1: TText;
    Layout2: TLayout;
    memJson: TMemo;
    Rectangle3: TRectangle;
    Text2: TText;
    Layout1: TLayout;
    Text3: TText;
    edtUnitName: TEdit;
    Text4: TText;
    edtClassRoot: TEdit;
    procedure memJsonChangeTracking(Sender: TObject);
    procedure edtUnitNameExit(Sender: TObject);
    procedure edtClassRootExit(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
  public
  end;

var
  Form8: TForm8;

implementation

{$R *.fmx}

{ TForm8 }

procedure TForm8.edtClassRootExit(Sender: TObject);
begin
  memJsonChangeTracking(memJson);
end;

procedure TForm8.edtUnitNameExit(Sender: TObject);
begin
  memJsonChangeTracking(memJson);
end;

procedure TForm8.FormShow(Sender: TObject);
begin
  edtUnitName.SetFocus;
end;

procedure TForm8.memJsonChangeTracking(Sender: TObject);
begin
  memClass.Lines.Text := TJSonToClass.new(edtUnitName.Text)
    .setClassRoot(edtClassRoot.Text)
    .convert(memJson.Text);

  lyClass.Enabled := (pos('constructor', memClass.Lines.Text) > 0);
  if (lyClass.Enabled) then
    rcClassTittle.Fill.Color := TAlphaColorRec.Dodgerblue
  else if (length(memJson.Lines.Text) > 0) then
    rcClassTittle.Fill.Color := TAlphaColorRec.Red
  else
    rcClassTittle.Fill.Color := TAlphaColorRec.Dodgerblue;
end;

end.
