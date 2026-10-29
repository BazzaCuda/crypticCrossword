{   crypticCrossword
    Copyright (C) 2026-2099 Baz Cuda
    https://github.com/BazzaCuda/crypticCrossword

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307, USA
}
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
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    FGridPanel:     TPanel;
    FCrosswordGrid: ICrosswordGrid;
    FSetupGrid:     boolean;
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

  FCrosswordGrid := newCrosswordGrid(FGridPanel);
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  case FCrosswordGrid = NIL   of  TRUE: EXIT; end;
  case FCrosswordGrid.isDirty of FALSE: EXIT; end;
  FCrosswordGrid.saveGridToFile(extractFilePath(paramStr(0)) + 'crypticCrossword.txt');
end;

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case (ssCtrl in shift) and (key = VK_DELETE) of TRUE: FSetupGrid := FCrosswordGrid.setupGrid; end;
  case FSetupGrid and (key = VK_BACK) of TRUE: FCrosswordGrid.clearGrid; end;
  case (ssCtrl in shift) and ((key = ord('s')) or (key = ord('S'))) of TRUE: FCrosswordGrid.saveGridToFile(extractFilePath(paramStr(0)) + 'crypticCrossword.txt'); end;
end;

end.
