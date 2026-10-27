// mainUnit.pas
unit mainUnit;

interface

uses
  winapi.windows, winapi.messages, system.sysUtils, system.variants,
  system.classes, vcl.graphics, vcl.controls, vcl.forms, vcl.dialogs,
  vcl.grids, vcl.extCtrls, system.types, system.uiTypes;

type
  TMainForm = class(TForm)
  private
    FCrosswordGrid: TDrawGrid;
    FIsBlack: array[0..14, 0..14] of boolean;
    FNumbers: array[0..14, 0..14] of integer;
    FLetters: array[0..14, 0..14] of char;
    FBoldRight: array[0..14, 0..14] of boolean;
    FBoldBottom: array[0..14, 0..14] of boolean;
    FHyphenRight: array[0..14, 0..14] of boolean;
    FHyphenBottom: array[0..14, 0..14] of boolean;
    FAcrossDirection: boolean;

    procedure gridDrawCell(sender: TObject; aCol, aRow: integer; aRect: TRect; aState: TGridDrawState);
    procedure gridKeyPress(sender: TObject; var aKey: char);
    procedure gridKeyDown(sender: TObject; var aKey: word; aShift: TShiftState);
    procedure calculateNumbers;
  public
    constructor create(aOwner: TComponent); override;
    procedure setupGrid(const aLayout: string);
  end;

var
  mainForm: TMainForm;

implementation

constructor TMainForm.create(aOwner: TComponent);
var
  vBorderPanel: TPanel;
begin
  inherited create(aOwner);
  SELF.caption := 'Cryptic Crossword Grid';
  SELF.clientwidth := 550;
  SELF.clientheight := 550;
  SELF.position := poScreenCenter;
  SELF.color := clWhite;

  FAcrossDirection := TRUE;

  vBorderPanel := TPanel.create(SELF);
  vBorderPanel.parent := SELF;
  vBorderPanel.left := 24;
  vBorderPanel.top := 24;
  vBorderPanel.width := 501;
  vBorderPanel.height := 501;
  vBorderPanel.color := clBlack;
  vBorderPanel.bevelOuter := bvNone;

  vBorderPanel.padding.left := 3;
  vBorderPanel.padding.top := 3;
  vBorderPanel.padding.right := 3;
  vBorderPanel.padding.bottom := 3;

  FCrosswordGrid := TDrawGrid.create(SELF);
  FCrosswordGrid.parent := vBorderPanel;
  FCrosswordGrid.align := alClient;
  FCrosswordGrid.colCount := 15;
  FCrosswordGrid.rowCount := 15;
  FCrosswordGrid.defaultColWidth := 33;
  FCrosswordGrid.defaultRowHeight := 33;
  FCrosswordGrid.fixedCols := 0;
  FCrosswordGrid.fixedRows := 0;
  FCrosswordGrid.scrollBars := System.UITypes.TScrollStyle.ssNone;
  FCrosswordGrid.gridLineWidth := 0;
  FCrosswordGrid.options := [];
  FCrosswordGrid.borderStyle := bsNone;

  FCrosswordGrid.onDrawCell := gridDrawCell;
  FCrosswordGrid.onKeyPress := gridKeyPress;
  FCrosswordGrid.onKeyDown := gridKeyDown;
end;

procedure TMainForm.setupGrid(const aLayout: string);
var
  vChar: char;
  vIndex: integer;
  vCol, vRow: integer;
  vNumStr: string;
  vSpaceCount: integer;
  vC: integer;
  vNumStrEmpty: boolean;
  vIsDigit: boolean;
  vIsBlackBlock: boolean;
  vIsSlash: boolean;
begin
  vCol := 0;
  vRow := 0;
  vNumStr := '';

  for vIndex := 1 to length(aLayout) do
  begin
    vChar := aLayout[vIndex];

    vIsDigit := vChar in ['0'..'9'];
    case vIsDigit of
      TRUE:
        begin
          vNumStr := vNumStr + vChar;
          CONTINUE;
        end;
    end;

    vNumStrEmpty := (vNumStr = '');
    case vNumStrEmpty of
      FALSE:
        begin
          vSpaceCount := strToInt(vNumStr);
          for vC := 1 to vSpaceCount do
          begin
            FIsBlack[vCol, vRow] := FALSE;
            inc(vCol);
          end;
          vNumStr := '';
        end;
    end;

    vIsBlackBlock := (vChar = 'B') or (vChar = 'b');
    case vIsBlackBlock of
      TRUE:
        begin
          FIsBlack[vCol, vRow] := TRUE;
          inc(vCol);
          CONTINUE;
        end;
    end;

    vIsSlash := vChar = '/';
    case vIsSlash of
      TRUE:
        begin
          vCol := 0;
          inc(vRow);
        end;
    end;
  end;

  vNumStrEmpty := (vNumStr = '');
  case vNumStrEmpty of
    FALSE:
      begin
        vSpaceCount := strToInt(vNumStr);
        for vC := 1 to vSpaceCount do
        begin
          FIsBlack[vCol, vRow] := FALSE;
          inc(vCol);
        end;
      end;
  end;

  calculateNumbers;
end;

procedure TMainForm.calculateNumbers;
var
  vCol, vRow: integer;
  vNum: integer;
  vHasRight, vHasLeft, vHasBottom, vHasTop: boolean;
  vNeedsAcrossNum, vNeedsDownNum: boolean;
  vIsCellBlack: boolean;
begin
  vNum := 1;
  for vRow := 0 to 14 do
  begin
    for vCol := 0 to 14 do
    begin
      FNumbers[vCol, vRow] := 0;
      vIsCellBlack := FIsBlack[vCol, vRow];
      case vIsCellBlack of
        TRUE: CONTINUE;
      end;

      vHasLeft := FALSE;
      case vCol > 0 of
        TRUE: vHasLeft := NOT FIsBlack[vCol - 1, vRow];
      end;

      vHasRight := FALSE;
      case vCol < 14 of
        TRUE: vHasRight := NOT FIsBlack[vCol + 1, vRow];
      end;

      vHasTop := FALSE;
      case vRow > 0 of
        TRUE: vHasTop := NOT FIsBlack[vCol, vRow - 1];
      end;

      vHasBottom := FALSE;
      case vRow < 14 of
        TRUE: vHasBottom := NOT FIsBlack[vCol, vRow + 1];
      end;

      vNeedsAcrossNum := vHasRight and (NOT vHasLeft);
      vNeedsDownNum := vHasBottom and (NOT vHasTop);

      case vNeedsAcrossNum or vNeedsDownNum of
        TRUE:
          begin
            FNumbers[vCol, vRow] := vNum;
            inc(vNum);
          end;
      end;
    end;
  end;
end;

procedure TMainForm.gridDrawCell(sender: TObject; aCol, aRow: integer; aRect: TRect; aState: TGridDrawState);
var
  vCanvas: TCanvas;
  vText: string;
  vIsCellBlack: boolean;
  vIsSelected: boolean;
  vDrawRect: TRect;
  vHasNumber: boolean;
  vHasLetter: boolean;
begin
  vCanvas := FCrosswordGrid.canvas;
  vIsCellBlack := FIsBlack[aCol, aRow];

  case vIsCellBlack of
    TRUE: vCanvas.brush.color := clBlack;
    FALSE:
      begin
        vIsSelected := (aCol = FCrosswordGrid.col) and (aRow = FCrosswordGrid.row);
        case vIsSelected of
          TRUE: vCanvas.brush.color := $00EAF5EA;
          FALSE: vCanvas.brush.color := clWhite;
        end;
      end;
  end;

  vCanvas.fillRect(aRect);

  vCanvas.pen.color := clBlack;
  vCanvas.pen.width := 1;

  vCanvas.moveTo(aRect.left, aRect.top);
  vCanvas.lineTo(aRect.right, aRect.top);

  vCanvas.moveTo(aRect.left, aRect.top);
  vCanvas.lineTo(aRect.left, aRect.bottom);

  case aCol = 14 of
    TRUE:
      begin
        vCanvas.moveTo(aRect.right - 1, aRect.top);
        vCanvas.lineTo(aRect.right - 1, aRect.bottom);
      end;
  end;

  case aRow = 14 of
    TRUE:
      begin
        vCanvas.moveTo(aRect.left, aRect.bottom - 1);
        vCanvas.lineTo(aRect.right, aRect.bottom - 1);
      end;
  end;

  case vIsCellBlack of
    TRUE: EXIT;
  end;

  vHasNumber := FNumbers[aCol, aRow] > 0;
  case vHasNumber of
    TRUE:
      begin
        vCanvas.font.name := 'Arial';
        vCanvas.font.size := 8;
        vCanvas.font.style := [fsBold];
        vCanvas.font.color := clBlack;
        vCanvas.brush.style := bsClear;
        vCanvas.textOut(aRect.left + 2, aRect.top + 1, intToStr(FNumbers[aCol, aRow]));
      end;
  end;

  vHasLetter := FLetters[aCol, aRow] <> #0;
  case vHasLetter of
    FALSE: EXIT;
  end;

  vCanvas.font.name := 'Arial';
  vCanvas.font.size := 15;
  vCanvas.font.style := [fsBold];
  vCanvas.font.color := clBlack;
  vCanvas.brush.style := bsClear;
  vText := FLetters[aCol, aRow];

  vDrawRect := aRect;
  vDrawRect.top := vDrawRect.top + 6;
  drawText(vCanvas.handle, pChar(vText), length(vText), vDrawRect, DT_CENTER or DT_SINGLELINE or DT_VCENTER);
end;

procedure TMainForm.gridKeyPress(sender: TObject; var aKey: char);
var
  vCol, vRow: integer;
  vUpperKey: char;
  vIsLetter: boolean;
  vIsBackspace: boolean;
  vIsCellBlack: boolean;
  vRightIsAvailable: boolean;
  vBelowIsAvailable: boolean;
begin
  vCol := FCrosswordGrid.col;
  vRow := FCrosswordGrid.row;

  vIsCellBlack := FIsBlack[vCol, vRow];
  case vIsCellBlack of
    TRUE: EXIT;
  end;

  vIsLetter := aKey in ['a'..'z', 'A'..'Z'];
  vIsBackspace := aKey = #8;

  case vIsLetter or vIsBackspace of
    FALSE: EXIT;
  end;

  case vIsBackspace of
    TRUE:
      begin
        FLetters[vCol, vRow] := #0;
        case FAcrossDirection of
          TRUE:
            case vCol > 0 of
              TRUE: FCrosswordGrid.col := vCol - 1;
            end;
          FALSE:
            case vRow > 0 of
              TRUE: FCrosswordGrid.row := vRow - 1;
            end;
        end;
        FCrosswordGrid.invalidate;
        EXIT;
      end;
  end;

  vUpperKey := upCase(aKey);
  FLetters[vCol, vRow] := vUpperKey;

  vRightIsAvailable := FALSE;
  case vCol < 14 of
    TRUE: vRightIsAvailable := NOT FIsBlack[vCol + 1, vRow];
  end;

  vBelowIsAvailable := FALSE;
  case vRow < 14 of
    TRUE: vBelowIsAvailable := NOT FIsBlack[vCol, vRow + 1];
  end;

  case FAcrossDirection of
    TRUE:
      case vRightIsAvailable of
        TRUE: FCrosswordGrid.col := vCol + 1;
        FALSE:
          case vBelowIsAvailable of
            TRUE:
              begin
                FCrosswordGrid.row := vRow + 1;
                FAcrossDirection := FALSE;
              end;
          end;
      end;
    FALSE:
      case vBelowIsAvailable of
        TRUE: FCrosswordGrid.row := vRow + 1;
        FALSE:
          case vRightIsAvailable of
            TRUE:
              begin
                FCrosswordGrid.col := vCol + 1;
                FAcrossDirection := TRUE;
              end;
          end;
      end;
  end;

  FCrosswordGrid.invalidate;
end;

procedure TMainForm.gridKeyDown(sender: TObject; var aKey: word; aShift: TShiftState);
var
  vIsRightOrLeft: boolean;
  vIsUpOrDown: boolean;
  vIsSpace: boolean;
begin
  vIsRightOrLeft := (aKey = VK_RIGHT) or (aKey = VK_LEFT);
  case vIsRightOrLeft of
    TRUE: FAcrossDirection := TRUE;
  end;

  vIsUpOrDown := (aKey = VK_DOWN) or (aKey = VK_UP);
  case vIsUpOrDown of
    TRUE: FAcrossDirection := FALSE;
  end;

  vIsSpace := aKey = VK_SPACE;
  case vIsSpace of
    TRUE:
      begin
        FAcrossDirection := NOT FAcrossDirection;
        FCrosswordGrid.invalidate;
      end;
  end;
end;

{$R *.dfm}

end.
