unit TCrosswordGridClass;

interface

uses
  winAPI.messages, winAPI.windows,
  system.classes, system.sysUtils, system.types, system.UITypes, system.variants,
  vcl.controls, vcl.dialogs, vcl.extCtrls, vcl.forms, vcl.graphics, vcl.grids;

const
  GRID_SIZE = 15;
  SETUP = FALSE;

type
  TClueDirection = (cdAcross, cdDown);
  TGridModifier = (gmHorzWordBreak, gmVertWordBreak, gmHorzHyphen, gmVertHyphen);

  ICrosswordGrid = interface
    procedure addModifier(aCol: integer; aRow: integer; aModifier: TGridModifier);
    procedure addModifierByClue(aClueNumber: integer; aDirection: TClueDirection; aLetterPosition: integer; aModifier: TGridModifier);
    procedure applySetupModifier(aCol: integer; aRow: integer; aKey: char);
    procedure arrayGrid(const aLines: array of string);
    procedure clearGrid;
    procedure readSavedGrid(const aFilename: string; aIndex: integer);
    procedure saveGridToFile(const aFilename: string);
    procedure setupGrid(const aLayout: string);
  end;

  TCrosswordGrid = class(TInterfacedObject, ICrosswordGrid)
  private
    FCrosswordGrid: TDrawGrid;
    FIsBlack:       array[1..GRID_SIZE, 1..GRID_SIZE] of boolean;
    FNumbers:       array[1..GRID_SIZE, 1..GRID_SIZE] of integer;
    FLetters:       array[1..GRID_SIZE, 1..GRID_SIZE] of char;
    FBoldRight:     array[1..GRID_SIZE, 1..GRID_SIZE] of boolean;
    FBoldBottom:    array[1..GRID_SIZE, 1..GRID_SIZE] of boolean;
    FHyphenRight:   array[1..GRID_SIZE, 1..GRID_SIZE] of boolean;
    FHyphenBottom:  array[1..GRID_SIZE, 1..GRID_SIZE] of boolean;
    FAcrossDirection: boolean;

    procedure gridDrawCell(sender: TObject; aCol, aRow: integer; aRect: TRect; aState: TGridDrawState);
    procedure gridKeyPress(sender: TObject; var aKey: char);
    procedure gridKeyDown(sender: TObject; var aKey: word; aShift: TShiftState);
    procedure gridMouseDown(sender: TObject; button: TMouseButton; shift: TShiftState; x, y: integer);
    procedure calculateNumbers;
  public
    constructor create(const aParent: TWinControl);
    procedure addModifier(aCol: integer; aRow: integer; aModifier: TGridModifier);
    procedure addModifierByClue(aClueNumber: integer; aDirection: TClueDirection; aLetterPosition: integer; aModifier: TGridModifier);
    procedure applySetupModifier(aCol: integer; aRow: integer; aKey: char);
    procedure arrayGrid(const aLines: array of string);
    procedure clearGrid;
    procedure readSavedGrid(const aFilename: string; aIndex: integer);
    procedure saveGridToFile(const aFilename: string);
    procedure setupGrid(const aLayout: string);
  end;

function newCrosswordGrid(const aParent: TWinControl): ICrosswordGrid;

implementation

function newCrosswordGrid(const aParent: TWinControl): ICrosswordGrid;
begin
  result := TCrosswordGrid.create(aParent);
end;

constructor TCrosswordGrid.create(const aParent: TWinControl);
begin
  inherited create;
  FAcrossDirection  := TRUE;

  FCrosswordGrid                  := TDrawGrid.create(aParent);
  FCrosswordGrid.parent           := aParent;
  FCrosswordGrid.align            := alClient;
  FCrosswordGrid.colCount         := GRID_SIZE;
  FCrosswordGrid.rowCount         := GRID_SIZE;
  FCrosswordGrid.defaultColWidth  := 33;
  FCrosswordGrid.defaultRowHeight := 33;
  FCrosswordGrid.fixedCols        := 0;
  FCrosswordGrid.fixedRows        := 0;
  FCrosswordGrid.scrollBars       := System.UITypes.TScrollStyle.ssNone;
  FCrosswordGrid.gridLineWidth    := 0;
  FCrosswordGrid.options          := [];
  FCrosswordGrid.borderStyle      := bsNone;
  FCrosswordGrid.defaultDrawing   := FALSE;

  FCrosswordGrid.onDrawCell       := gridDrawCell;
  FCrosswordGrid.onKeyPress       := gridKeyPress;
  FCrosswordGrid.onKeyDown        := gridKeyDown;
  FCrosswordGrid.onMouseDown      := gridMouseDown;
end;

procedure TCrosswordGrid.saveGridToFile(const aFilename: string);
begin
  var vStringList := TStringList.create;
  try
    case fileExists(aFileName) of TRUE: vStringList.loadFromFile(aFileName); end;

    var vCombined := '';
    for var vRow := 1 to GRID_SIZE do
    begin
      var vEmptyCount := 0;
      for var vCol := 1 to GRID_SIZE do
      begin
        var vIsCellBlack      := FIsBlack       [vCol, vRow];
        var vHasLetter        := FLetters       [vCol, vRow] <> #0;
        var vHasBoldRight     := FBoldRight     [vCol, vRow];
        var vHasBoldBottom    := FBoldBottom    [vCol, vRow];
        var vHasHyphenRight   := FHyphenRight   [vCol, vRow];
        var vHasHyphenBottom  := FHyphenBottom  [vCol, vRow];

        var vHasContent   := vIsCellBlack OR vHasLetter;
        var vHasModifier  := vHasBoldRight OR vHasBoldBottom OR vHasHyphenRight OR vHasHyphenBottom;

        case vHasContent of  TRUE:  begin
                                      case vEmptyCount > 0 of  TRUE:  begin
                                                                        vCombined := vCombined + intToStr(vEmptyCount);
                                                                        vEmptyCount := 0; end;end;

                                      case vIsCellBlack of   TRUE: vCombined := vCombined + '.';
                                                            FALSE: vCombined := vCombined + FLetters[vCol, vRow]; end;
                                    end;
                            FALSE: inc(vEmptyCount);
        end;

        case vHasModifier of   TRUE:  begin
                                        case vEmptyCount > 0 of  TRUE:  begin
                                                                          vCombined := vCombined + intToStr(vEmptyCount);
                                                                          vEmptyCount := 0; end;end;

                                        case vHasBoldRight    of   TRUE:  vCombined := vCombined + '|'; end;
                                        case vHasBoldBottom   of   TRUE:  vCombined := vCombined + '_'; end;
                                        case vHasHyphenRight  of   TRUE:  vCombined := vCombined + '-'; end;
                                        case vHasHyphenBottom of   TRUE:  vCombined := vCombined + '='; end;
                                      end;end;
      end;

      case vEmptyCount > 0  of   TRUE:  vCombined := vCombined + intToStr(vEmptyCount); end;

      case vRow < GRID_SIZE of   TRUE:  vCombined := vCombined + '/'; end;
    end;

    vStringList.add(vCombined);
    vStringList.saveToFile(aFilename);
  finally
    vStringList.free;
  end;
end;

procedure TCrosswordGrid.setupGrid(const aLayout: string);
begin
  clearGrid;

  var vCol              := 1;
  var vRow              := 1;
  var vNumStr : string  := '';

  for var vIndex := 1 to length(aLayout) do
  begin
    var vChar: char := aLayout[vIndex];

    var vIsLetter := vChar in ['A'..'Z'];
    case vIsLetter of  TRUE:  begin
                                var vNumStrEmptyForLetter := (vNumStr = '');
                                case vNumStrEmptyForLetter of FALSE:  begin
                                                                        var vSpaceCount := strToInt(vNumStr);
                                                                        for var vC := 1 to vSpaceCount do begin
                                                                                                            FIsBlack[vCol, vRow] := FALSE;
                                                                                                            inc(vCol); end;
                                                                        vNumStr := ''; end;end;

                                FLetters[vCol, vRow] := vChar;
                                inc(vCol);
                                CONTINUE; end;end;

    var vIsDigit := vChar in ['0'..'9'];
    case vIsDigit of   TRUE:  begin
                                vNumStr := vNumStr + vChar;
                                CONTINUE; end;end;

    var vNumStrEmpty := (vNumStr = '');
    case vNumStrEmpty of  FALSE:  begin
                                    var vSpaceCount := strToInt(vNumStr);
                                    for var vC := 1 to vSpaceCount do begin
                                                                        FIsBlack[vCol, vRow] := FALSE;
                                                                        inc(vCol); end;
                                    vNumStr := ''; end;end;

    var vIsBlackBlock := (vChar = '.');
    case vIsBlackBlock of  TRUE:  begin
                                    FIsBlack[vCol, vRow] := TRUE;
                                    inc(vCol);
                                    CONTINUE; end;end;

    var vIsSlash := vChar = '/';
    case vIsSlash of   TRUE:  begin
                                vCol := 1;
                                inc(vRow);
                                CONTINUE; end;end;

    var vIsModifier := vChar in ['|', '_', '-', '='];
    case vIsModifier of  TRUE:  begin
                                  var vIsBoldRight := vChar = '|';
                                  case vIsBoldRight     of   TRUE:  FBoldRight[vCol - 1, vRow] := TRUE; end;

                                  var vIsBoldBottom := vChar = '_';
                                  case vIsBoldBottom    of   TRUE:  FBoldBottom[vCol - 1, vRow] := TRUE; end;

                                  var vIsHyphenRight := vChar = '-';
                                  case vIsHyphenRight   of   TRUE:  FHyphenRight[vCol - 1, vRow] := TRUE; end;

                                  var vIsHyphenBottom := vChar = '=';
                                  case vIsHyphenBottom  of   TRUE:  FHyphenBottom[vCol - 1, vRow] := TRUE; end;
                                end;end;end;

  var vNumStrEmptyFinal := (vNumStr = '');
  case vNumStrEmptyFinal of FALSE:  begin
                                      var vSpaceCount := strToInt(vNumStr);
                                      for var vC := 1 to vSpaceCount do begin
                                                                          FIsBlack[vCol, vRow] := FALSE;
                                                                          inc(vCol); end;end;end;

  calculateNumbers;
end;

procedure TCrosswordGrid.addModifier(aCol, aRow: integer; aModifier: TGridModifier);
begin
  var vIsBoldRight := aModifier = gmHorzWordBreak;
  case vIsBoldRight     of   TRUE:  FBoldRight[aCol, aRow] := TRUE; end;

  var vIsBoldBottom := aModifier = gmVertWordBreak;
  case vIsBoldBottom    of   TRUE:  FBoldBottom[aCol, aRow] := TRUE; end;

  var vIsHyphenRight := aModifier = gmHorzHyphen;
  case vIsHyphenRight   of   TRUE:  FHyphenRight[aCol, aRow] := TRUE; end;

  var vIsHyphenBottom := aModifier = gmVertHyphen;
  case vIsHyphenBottom  of   TRUE:  FHyphenBottom[aCol, aRow] := TRUE;
  end;

  FCrosswordGrid.invalidate;
end;

procedure TCrosswordGrid.addModifierByClue(aClueNumber: integer; aDirection: TClueDirection; aLetterPosition: integer; aModifier: TGridModifier);
begin
  var vFound      := FALSE;
  var vTargetCol  := 0;
  var vTargetRow  := 0;

  for var vRow := 1 to GRID_SIZE do begin
    for var vCol := 1 to GRID_SIZE do
      case FNumbers[vCol, vRow] = aClueNumber of   TRUE:  begin
                                                            vFound := TRUE;
                                                            var vIsAcross := aDirection = cdAcross;
                                                            case vIsAcross of  TRUE:  begin
                                                                                        vTargetCol := vCol + aLetterPosition - 1;
                                                                                        vTargetRow := vRow; end;
                                                                              FALSE:  begin
                                                                                        vTargetCol := vCol;
                                                                                        vTargetRow := vRow + aLetterPosition - 1; end;end;
                                                            BREAK;
                                                          end;end;

                                                          case vFound of   TRUE: BREAK; end;end;

  case vFound of  FALSE: EXIT; end;

  addModifier(vTargetCol, vTargetRow, aModifier);
end;

procedure TCrosswordGrid.applySetupModifier(aCol, aRow: integer; aKey: char);
begin
  var vIsBoldRight := aKey = '|';
  case vIsBoldRight     of   TRUE:  FBoldRight[aCol, aRow] := NOT FBoldRight[aCol, aRow]; end;

  var vIsBoldBottom := aKey = '_';
  case vIsBoldBottom    of   TRUE:  FBoldBottom[aCol, aRow] := NOT FBoldBottom[aCol, aRow]; end;

  var vIsHyphenRight := aKey = '-';
  case vIsHyphenRight   of   TRUE:  FHyphenRight[aCol, aRow] := NOT FHyphenRight[aCol, aRow];
  end;

  var vIsHyphenBottom := aKey = '=';
  case vIsHyphenBottom  of   TRUE:  FHyphenBottom[aCol, aRow] := NOT FHyphenBottom[aCol, aRow]; end;

  FCrosswordGrid.invalidate;
end;

procedure TCrosswordGrid.arrayGrid(const aLines: array of string);
begin
  var vCombined := '';
  for var vIndex := low(aLines) to high(aLines) do  begin
                                                      var vHasContent := vCombined <> '';
                                                      case vHasContent of  TRUE: vCombined := vCombined + '/'; end;
                                                      vCombined := vCombined + aLines[vIndex]; end;
  setupGrid(vCombined);
end;

procedure TCrosswordGrid.calculateNumbers;
begin
  var vNum := 1;
  for var vRow := 1 to GRID_SIZE do
    for var vCol := 1 to GRID_SIZE do begin
      FNumbers[vCol, vRow] := 0;
      var vIsCellBlack := FIsBlack[vCol, vRow];
      case vIsCellBlack of TRUE: CONTINUE; end;

      var vHasLeft := FALSE;
      case vCol > 1           of   TRUE:  vHasLeft    := NOT FIsBlack[vCol - 1, vRow]; end;

      var vHasRight := FALSE;
      case vCol < GRID_SIZE   of   TRUE:  vHasRight   := NOT FIsBlack[vCol + 1, vRow]; end;

      var vHasTop := FALSE;
      case vRow > 1           of   TRUE:  vHasTop     := NOT FIsBlack[vCol, vRow - 1]; end;

      var vHasBottom := FALSE;
      case vRow < GRID_SIZE   of   TRUE:  vHasBottom  := NOT FIsBlack[vCol, vRow + 1]; end;

      var vNeedsAcrossNum := vHasRight and (NOT vHasLeft);
      var vNeedsDownNum := vHasBottom and (NOT vHasTop);

      case vNeedsAcrossNum or vNeedsDownNum of   TRUE:  begin
                                                          FNumbers[vCol, vRow] := vNum;
                                                          inc(vNum); end;end;
    end;
end;

procedure TCrosswordGrid.clearGrid;
begin
  for var vRow := 1 to GRID_SIZE do
    for var vCol := 1 to GRID_SIZE do  begin
      FIsBlack      [vCol, vRow]  := FALSE;
      FNumbers      [vCol, vRow]  := 0;
      FLetters      [vCol, vRow]  := #0;
      FBoldRight    [vCol, vRow]  := FALSE;
      FBoldBottom   [vCol, vRow]  := FALSE;
      FHyphenRight  [vCol, vRow]  := FALSE;
      FHyphenBottom [vCol, vRow]  := FALSE;
    end;
end;

procedure TCrosswordGrid.gridDrawCell(sender: TObject; aCol, aRow: integer; aRect: TRect; aState: TGridDrawState);
begin
  var vCol := aCol + 1;
  var vRow := aRow + 1;

  var vCanvas := FCrosswordGrid.canvas;
  var vIsCellBlack := FIsBlack[vCol, vRow];

  case vIsCellBlack of
    TRUE: vCanvas.brush.color := clBlack;
    FALSE:
      begin
        var vIsSelected := (aCol = FCrosswordGrid.col) and (aRow = FCrosswordGrid.row);
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

  case vCol = GRID_SIZE of
    TRUE:
      begin
        vCanvas.moveTo(aRect.right - 1, aRect.top);
        vCanvas.lineTo(aRect.right - 1, aRect.bottom);
      end;
  end;

  case vRow = GRID_SIZE of
    TRUE:
      begin
        vCanvas.moveTo(aRect.left, aRect.bottom - 1);
        vCanvas.lineTo(aRect.right, aRect.bottom - 1);
      end;
  end;

  var vHasBoldRight := FBoldRight[vCol, vRow];
  case vHasBoldRight of
    TRUE:
      begin
        vCanvas.moveTo(aRect.right - 1, aRect.top);
        vCanvas.lineTo(aRect.right - 1, aRect.bottom);
      end;
  end;

  var vHasBoldBottom := FBoldBottom[vCol, vRow];
  case vHasBoldBottom of
    TRUE:
      begin
        vCanvas.moveTo(aRect.left, aRect.bottom - 1);
        vCanvas.lineTo(aRect.right, aRect.bottom - 1);
      end;
  end;

  var vHasHyphenRight := FHyphenRight[vCol, vRow];
  case vHasHyphenRight of
    TRUE:
      begin
        vCanvas.pen.width := 2;
        vCanvas.moveTo(aRect.right - 4, aRect.top + ((aRect.bottom - aRect.top) div 2));
        vCanvas.lineTo(aRect.right, aRect.top + ((aRect.bottom - aRect.top) div 2));
        vCanvas.pen.width := 1;
      end;
  end;

  var vPrevHasHyphenRight := FALSE;
  case vCol > 1 of
    TRUE: vPrevHasHyphenRight := FHyphenRight[vCol - 1, vRow];
  end;

  case vPrevHasHyphenRight of
    TRUE:
      begin
        vCanvas.pen.width := 2;
        vCanvas.moveTo(aRect.left, aRect.top + ((aRect.bottom - aRect.top) div 2));
        vCanvas.lineTo(aRect.left + 4, aRect.top + ((aRect.bottom - aRect.top) div 2));
        vCanvas.pen.width := 1;
      end;
  end;

  var vHasHyphenBottom := FHyphenBottom[vCol, vRow];
  case vHasHyphenBottom of
    TRUE:
      begin
        vCanvas.pen.width := 2;
        vCanvas.moveTo(aRect.left + ((aRect.right - aRect.left) div 2), aRect.bottom - 4);
        vCanvas.lineTo(aRect.left + ((aRect.right - aRect.left) div 2), aRect.bottom);
        vCanvas.pen.width := 1;
      end;
  end;

  var vPrevHasHyphenBottom := FALSE;
  case vRow > 1 of
    TRUE: vPrevHasHyphenBottom := FHyphenBottom[vCol, vRow - 1];
  end;

  case vPrevHasHyphenBottom of
    TRUE:
      begin
        vCanvas.pen.width := 2;
        vCanvas.moveTo(aRect.left + ((aRect.right - aRect.left) div 2), aRect.top);
        vCanvas.lineTo(aRect.left + ((aRect.right - aRect.left) div 2), aRect.top + 4);
        vCanvas.pen.width := 1;
      end;
  end;

  case vIsCellBlack of
    TRUE: EXIT;
  end;

  var vHasNumber := FNumbers[vCol, vRow] > 0;
  case vHasNumber of
    TRUE:
      begin
        vCanvas.font.name   := 'Arial';
        vCanvas.font.size   := 8;
        vCanvas.font.style  := [fsBold];
        vCanvas.font.color  := clBlack;
        vCanvas.brush.style := bsClear;
        vCanvas.textOut(aRect.left + 2, aRect.top + 1, intToStr(FNumbers[vCol, vRow]));
      end;
  end;

  var vHasLetter := FLetters[vCol, vRow] <> #0;
  case vHasLetter of
    FALSE: EXIT;
  end;

  vCanvas.font.name   := 'Arial';
  vCanvas.font.size   := 14;
  vCanvas.font.style  := [fsBold];
  vCanvas.font.color  := clBlack;
  vCanvas.brush.style := bsClear;
  var vText           := FLetters[vCol, vRow];

  var vDrawRect := aRect;
  vDrawRect.top := vDrawRect.top + 6;
  drawText(vCanvas.handle, pChar(vText), length(vText), vDrawRect, DT_CENTER or DT_SINGLELINE or DT_VCENTER);
end;

procedure TCrosswordGrid.gridKeyPress(sender: TObject; var aKey: char);
begin
  var vCol := FCrosswordGrid.col + 1;
  var vRow := FCrosswordGrid.row + 1;

  var vIsCellBlack := FIsBlack[vCol, vRow];
  case vIsCellBlack of   TRUE: EXIT; end;

  var vIsModifier := aKey in ['|', '_', '-', '='];
  var vIsSetupAndModifier := {SETUP AND} vIsModifier;

  case vIsSetupAndModifier of  TRUE:  begin
                                        applySetupModifier(vCol, vRow, aKey);
                                        EXIT;
                                      end;end;

  var vIsLetter := aKey in ['a'..'z', 'A'..'Z'];
  var vIsBackspace := aKey = #8;

  case vIsLetter or vIsBackspace of FALSE: EXIT; end;

  case vIsBackspace of   TRUE:  begin
                                  FLetters[vCol, vRow] := #0;
                                  case FAcrossDirection of   TRUE:  case vCol > 1 of   TRUE: FCrosswordGrid.col := FCrosswordGrid.col - 1; end;
                                                            FALSE:  case vRow > 1 of   TRUE: FCrosswordGrid.row := FCrosswordGrid.row - 1; end;
                                  end;
                                  FCrosswordGrid.invalidate;
                                  EXIT;
                                end;end;

  var vUpperKey := upCase(aKey);
  FLetters[vCol, vRow] := vUpperKey;

  var vRightIsAvailable := FALSE;
  case vCol < GRID_SIZE of   TRUE: vRightIsAvailable := NOT FIsBlack[vCol + 1, vRow]; end;

  var vBelowIsAvailable := FALSE;
  case vRow < GRID_SIZE of   TRUE: vBelowIsAvailable := NOT FIsBlack[vCol, vRow + 1]; end;


  case FAcrossDirection of   TRUE:  case vRightIsAvailable of  TRUE:  FCrosswordGrid.col := FCrosswordGrid.col + 1;
                                                              FALSE:  case vBelowIsAvailable of  TRUE:  begin
                                                                                                          FCrosswordGrid.row := FCrosswordGrid.row + 1;
                                                                                                          FAcrossDirection := FALSE; end;end;end;

                            FALSE:  case vBelowIsAvailable of  TRUE:  FCrosswordGrid.row := FCrosswordGrid.row + 1;
                                                              FALSE:  case vRightIsAvailable of  TRUE:  begin
                                                                                                          FCrosswordGrid.col := FCrosswordGrid.col + 1;
                                                                                                          FAcrossDirection := TRUE; end;end;end;
  end;

  FCrosswordGrid.invalidate;
end;

procedure TCrosswordGrid.gridMouseDown(sender: TObject; button: TMouseButton; shift: TShiftState; x, y: integer);
begin
  case SETUP of
    FALSE: EXIT;
  end;

  var vDrawCol := -1;
  var vDrawRow := -1;
  FCrosswordGrid.mouseToCell(x, y, vDrawCol, vDrawRow);

  var vIsValidCell := (vDrawCol >= 0) AND (vDrawRow >= 0);
  case vIsValidCell of  FALSE: EXIT; end;

  var vCol := vDrawCol + 1;
  var vRow := vDrawRow + 1;

  var vIsLeftClick := button = mbLeft;
  case vIsLeftClick of   TRUE:  FIsBlack[vCol, vRow] := FALSE; end;

  var vIsRightClick := button = mbRight;
  case vIsRightClick of  TRUE:  begin
                                  FIsBlack      [vCol, vRow] := TRUE;
                                  FLetters      [vCol, vRow] := #0;
                                  FBoldRight    [vCol, vRow] := FALSE;
                                  FBoldBottom   [vCol, vRow] := FALSE;
                                  FHyphenRight  [vCol, vRow] := FALSE;
                                  FHyphenBottom [vCol, vRow] := FALSE;
                                end;end;

  calculateNumbers;
  FCrosswordGrid.invalidate;
end;

procedure TCrosswordGrid.readSavedGrid(const aFilename: string; aIndex: integer);
begin
  var vFileExists := fileExists(aFilename);
  case vFileExists of FALSE:  EXIT; end;

  var vStringList := TStringList.create;
  try
    vStringList.loadFromFile(aFilename);
    case aIndex = -1 of  TRUE: aIndex := vStringList.count - 1; end;

    var vIsValidIndex := (aIndex >= 0) and (aIndex < vStringList.count);
    case vIsValidIndex of  TRUE: setupGrid(vStringList[aIndex]); end;
  finally
    vStringList.free;
  end;
end;

procedure TCrosswordGrid.gridKeyDown(sender: TObject; var aKey: word; aShift: TShiftState);
begin
  var vIsEscape := aKey = VK_ESCAPE;
  case vIsEscape of  TRUE:  begin
                              var vForm := getParentForm(FCrosswordGrid);
                              case vForm <> NIL of   TRUE: TForm(vForm).close; end;
                              EXIT; end;end;

  var vIsRightOrLeft := (aKey = VK_RIGHT) or (aKey = VK_LEFT);
  case vIsRightOrLeft of   TRUE: FAcrossDirection := TRUE; end;

  var vIsUpOrDown := (aKey = VK_DOWN) or (aKey = VK_UP);
  case vIsUpOrDown of  TRUE: FAcrossDirection := FALSE; end;

  var vIsSpace := aKey = VK_SPACE;
  case vIsSpace of   TRUE:  begin
                              FAcrossDirection := NOT FAcrossDirection;
                              FCrosswordGrid.invalidate; end;end;
end;

end.
