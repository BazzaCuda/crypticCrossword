unit mainUnit;

interface

uses
  winAPI.windows, winAPI.messages,
  system.classes, system.sysUtils, system.variants,
  vcl.controls, vcl.dialogs, vcl.extCtrls, vcl.forms, vcl.graphics,
  TCrosswordGridClass;

type
  TMainForm = class(TForm)
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    FGridPanel:     TPanel;
    FCrosswordGrid: ICrosswordGrid;
  public
    constructor create(aOwner: TComponent); override;
    property    mainGrid: ICrosswordGrid read FCrosswordGrid;
  end;

var
  mainForm: TMainForm;

implementation

{$R *.dfm}

constructor TMainForm.create(aOwner: TComponent);
begin
  inherited create(aOwner);
  SELF.caption      := 'Cryptic Crossword Grid';
  SELF.clientwidth  := 550;
  SELF.clientheight := 550;
  SELF.position     := poScreenCenter;
  SELF.color        := clWhite - $101010;

  FGridPanel                := TPanel.create(SELF);
  FGridPanel.parent         := SELF;
  FGridPanel.left           := 24;
  FGridPanel.top            := 24;
  FGridPanel.width          := 501;
  FGridPanel.height         := 501;
  FGridPanel.color          := clBlack;
  FGridPanel.bevelOuter     := bvNone;

  FGridPanel.padding.left   := 3;
  FGridPanel.padding.top    := 3;
  FGridPanel.padding.right  := 3;
  FGridPanel.padding.bottom := 3;

  FCrossword := newCrosswordGrid(FGridPanel);
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  case FCrossword <> NIL of
    TRUE: FCrossword.saveGridToFile(extractFilePath(paramStr(0)) + 'crypticCrossword.txt');
  end;
end;

end.
