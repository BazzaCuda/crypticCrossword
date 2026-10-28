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
  TClueDirection  = (cdAcross, cdDown);
  TGridModifier   = (gmHorzWordBreak, gmVertWordBreak, gmHorzHyphen, gmVertHyphen);

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
    FCrosswordGrid:   TDrawGrid;
    FIsBlack:         array[1..GRID_SIZE, 1..GRID_SIZE] of boolean;
    FNumbers:         array[1..GRID_SIZE, 1..GRID_SIZE] of integer;
    FLetters:         array[1..GRID_SIZE, 1..GRID_SIZE] of char;
    FBoldRight:       array[1..GRID_SIZE, 1..GRID_SIZE] of boolean;
    FBoldBottom:      array[1..GRID_SIZE, 1..GRID_SIZE] of boolean;
    FHyphenRight:     array[1..GRID_SIZE, 1..GRID_SIZE] of boolean;
    FHyphenBottom:    array[1..GRID_SIZE, 1..GRID_SIZE] of boolean;
    FAcrossDirection: boolean;

    procedure gridDrawCell(sender: TObject; aCol, aRow: integer; aRect: TRect; aState: TGridDrawState);
    procedure gridKeyPress(sender: TObject; var aKey: char);
    procedure gridKeyDown(sender: TObject; var aKey: word; aShift: TShiftState);
    procedure gridMouseDown(sender: TObject; button: TMouseButton; shift: TShiftState; x, y: integer);

    procedure advanceCursor(aCol, aRow: integer);
    procedure retreatCursor(aCol, aRow: integer);
    procedure calculateNumbers;
    procedure fillBlanks(var aCol: integer; aRow: integer; var aNumStr: string);
    function  needsNumber(aCol, aRow: integer): boolean;
    function  encodeRow(aRow: integer): string;

    procedure drawBackground(aCanvas: TCanvas; aCol, aRow: integer; aRect: TRect);
    procedure drawBorders(aCanvas: TCanvas; aCol, aRow: integer; aRect: TRect);
    procedure drawHyphens(aCanvas: TCanvas; aCol, aRow: integer; aRect: TRect);
    procedure drawContent(aCanvas: TCanvas; aCol, aRow: integer; aRect: TRect);
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

function TCrosswordGrid.encodeRow(aRow: integer): string;
begin
  result := '';
  var vEmptyCount := 0;

  for var vCol := 1 to GRID_SIZE do begin
    var vIsCellBlack := FIsBlack[vCol, aRow];
    var vHasLetter   := FLetters[vCol, aRow] <> #0;
    var vHasModifier := FBoldRight[vCol, aRow] OR FBoldBottom[vCol, aRow] OR FHyphenRight[vCol, aRow] OR FHyphenBottom[vCol, aRow];

    case (NOT vIsCellBlack) AND (NOT vHasLetter) of TRUE: inc(vEmptyCount); end;

    case vIsCellBlack OR vHasLetter of TRUE: begin
      case vEmptyCount > 0 of TRUE: begin result := result + intToStr(vEmptyCount); vEmptyCount := 0; end; end;
      case vIsCellBlack    of TRUE: result := result + '.'; end;
      case vHasLetter AND (NOT vIsCellBlack) of TRUE: result := result + FLetters[vCol, aRow]; end;
    end; end;

    case vHasModifier of TRUE: begin
      case vEmptyCount > 0           of TRUE: begin result := result + intToStr(vEmptyCount); vEmptyCount := 0; end; end;
      case FBoldRight[vCol, aRow]    of TRUE: result := result + '|'; end;
      case FBoldBottom[vCol, aRow]   of TRUE: result := result + '_'; end;
      case FHyphenRight[vCol, aRow]  of TRUE: result := result + '-'; end;
      case FHyphenBottom[vCol, aRow] of TRUE: result := result + '='; end;
    end; end;
  end;

  case vEmptyCount > 0 of TRUE: result := result + intToStr(vEmptyCount); end;
end;

procedure TCrosswordGrid.saveGridToFile(const aFilename: string);
begin
  var vStringList := TStringList.create;
  try
    case fileExists(aFilename) of TRUE: vStringList.loadFromFile(aFilename); end;

    var vCombined := '';
    for var vRow := 1 to GRID_SIZE do begin
      case vCombined <> '' of TRUE: vCombined := vCombined + '/'; end;
      vCombined := vCombined + encodeRow(vRow);
    end;

    vStringList.add(vCombined);
    vStringList.saveToFile(aFilename);
  finally
    vStringList.free;
  end;
end;

procedure TCrosswordGrid.fillBlanks(var aCol: integer; aRow: integer; var aNumStr: string);
begin
  case aNumStr = '' of TRUE: EXIT; end;

  var vSpaceCount := strToInt(aNumStr);
  for var vC := 1 to vSpaceCount do begin
    FIsBlack[aCol, aRow] := FALSE;
    inc(aCol);
  end;

  aNumStr := '';
end;

procedure TCrosswordGrid.setupGrid(const aLayout: string);
begin
  clearGrid;

  var vCol             := 1;
  var vRow             := 1;
  var vNumStr : string := '';

  for var vIndex := 1 to length(aLayout) do begin
    var vChar := aLayout[vIndex];

    case vChar in ['A'..'Z'] of TRUE: begin fillBlanks(vCol, vRow, vNumStr); FLetters[vCol, vRow] := vChar; inc(vCol); CONTINUE; end; end;
    case vChar in ['0'..'9'] of TRUE: begin vNumStr := vNumStr + vChar; CONTINUE; end; end;

    fillBlanks(vCol, vRow, vNumStr);

    case vChar = '.' of TRUE: begin FIsBlack[vCol, vRow] := TRUE; inc(vCol); CONTINUE; end; end;
    case vChar = '/' of TRUE: begin vCol := 1; inc(vRow); CONTINUE; end; end;

    FBoldRight[vCol - 1, vRow]    := FBoldRight[vCol - 1, vRow]    OR (vChar = '|');
    FBoldBottom[vCol - 1, vRow]   := FBoldBottom[vCol - 1, vRow]   OR (vChar = '_');
    FHyphenRight[vCol - 1, vRow]  := FHyphenRight[vCol - 1, vRow]  OR (vChar = '-');
    FHyphenBottom[vCol - 1, vRow] := FHyphenBottom[vCol - 1, vRow] OR (vChar = '=');
  end;

  fillBlanks(vCol, vRow, vNumStr);
  calculateNumbers;
end;

procedure TCrosswordGrid.addModifier(aCol, aRow: integer; aModifier: TGridModifier);
begin
  FBoldRight[aCol, aRow]    := FBoldRight[aCol, aRow]    OR (aModifier = gmHorzWordBreak);
  FBoldBottom[aCol, aRow]   := FBoldBottom[aCol, aRow]   OR (aModifier = gmVertWordBreak);
  FHyphenRight[aCol, aRow]  := FHyphenRight[aCol, aRow]  OR (aModifier = gmHorzHyphen);
  FHyphenBottom[aCol, aRow] := FHyphenBottom[aCol, aRow] OR (aModifier = gmVertHyphen);

  FCrosswordGrid.invalidate;
end;

procedure TCrosswordGrid.addModifierByClue(aClueNumber: integer; aDirection: TClueDirection; aLetterPosition: integer; aModifier: TGridModifier);
begin
  var vFound     := FALSE;
  var vTargetCol := 0;
  var vTargetRow := 0;

  for var vRow := 1 to GRID_SIZE do
    for var vCol := 1 to GRID_SIZE do begin
      var vIsMatch := (FNumbers[vCol, vRow] = aClueNumber) AND (NOT vFound);
      case vIsMatch AND (aDirection = cdAcross) of TRUE: begin vTargetCol := vCol + aLetterPosition - 1; vTargetRow := vRow; vFound := TRUE; end; end;
      case vIsMatch AND (aDirection = cdDown)   of TRUE: begin vTargetCol := vCol; vTargetRow := vRow + aLetterPosition - 1; vFound := TRUE; end; end;
    end;

  case vFound of TRUE: addModifier(vTargetCol, vTargetRow, aModifier); end;
end;

procedure TCrosswordGrid.applySetupModifier(aCol, aRow: integer; aKey: char);
begin
  FBoldRight[aCol, aRow]    := FBoldRight[aCol, aRow]    XOR (aKey = '|');
  FBoldBottom[aCol, aRow]   := FBoldBottom[aCol, aRow]   XOR (aKey = '_');
  FHyphenRight[aCol, aRow]  := FHyphenRight[aCol, aRow]  XOR (aKey = '-');
  FHyphenBottom[aCol, aRow] := FHyphenBottom[aCol, aRow] XOR (aKey = '=');

  FCrosswordGrid.invalidate;
end;

procedure TCrosswordGrid.arrayGrid(const aLines: array of string);
begin
  var vCombined := '';
  for var vIndex := low(aLines) to high(aLines) do begin
    case vCombined <> '' of TRUE: vCombined := vCombined + '/'; end;
    vCombined := vCombined + aLines[vIndex];
  end;
  setupGrid(vCombined);
end;

function TCrosswordGrid.needsNumber(aCol, aRow: integer): boolean;
begin
  result := FALSE;
  case FIsBlack[aCol, aRow] of TRUE: EXIT; end;

  var vHasLeft   := (aCol > 1)         AND (NOT FIsBlack[aCol - 1, aRow]);
  var vHasRight  := (aCol < GRID_SIZE) AND (NOT FIsBlack[aCol + 1, aRow]);
  var vHasTop    := (aRow > 1)         AND (NOT FIsBlack[aCol, aRow - 1]);
  var vHasBottom := (aRow < GRID_SIZE) AND (NOT FIsBlack[aCol, aRow + 1]);

  result := (vHasRight AND (NOT vHasLeft)) OR (vHasBottom AND (NOT vHasTop));
end;

procedure TCrosswordGrid.calculateNumbers;
begin
  var vNum := 1;
  for var vRow := 1 to GRID_SIZE do
    for var vCol := 1 to GRID_SIZE do begin
      FNumbers[vCol, vRow] := 0;
      case needsNumber(vCol, vRow) of TRUE: begin FNumbers[vCol, vRow] := vNum; inc(vNum); end; end;
    end;
end;

procedure TCrosswordGrid.clearGrid;
begin
  for var vRow := 1 to GRID_SIZE do
    for var vCol := 1 to GRID_SIZE do begin
      FIsBlack[vCol, vRow]      := FALSE;
      FNumbers[vCol, vRow]      := 0;
      FLetters[vCol, vRow]      := #0;
      FBoldRight[vCol, vRow]    := FALSE;
      FBoldBottom[vCol, vRow]   := FALSE;
      FHyphenRight[vCol, vRow]  := FALSE;
      FHyphenBottom[vCol, vRow] := FALSE;
    end;
end;

procedure TCrosswordGrid.drawBackground(aCanvas: TCanvas; aCol, aRow: integer; aRect: TRect);
begin
  var vIsSelected := (NOT FIsBlack[aCol, aRow]) AND (aCol - 1 = FCrosswordGrid.col) AND (aRow - 1 = FCrosswordGrid.row);

  case FIsBlack[aCol, aRow]                             of TRUE: aCanvas.brush.color := clBlack; end;
  case vIsSelected                                      of TRUE: aCanvas.brush.color := $00EAF5EA; end;
  case (NOT FIsBlack[aCol, aRow]) AND (NOT vIsSelected) of TRUE: aCanvas.brush.color := clWhite; end;

  aCanvas.fillRect(aRect);
end;

procedure TCrosswordGrid.drawBorders(aCanvas: TCanvas; aCol, aRow: integer; aRect: TRect);
begin
  aCanvas.pen.color := clBlack;
  aCanvas.pen.width := 1;

  aCanvas.moveTo(aRect.left, aRect.top);
  aCanvas.lineTo(aRect.right, aRect.top);
  aCanvas.moveTo(aRect.left, aRect.top);
  aCanvas.lineTo(aRect.left, aRect.bottom);

  var vDrawRight  := (aCol = GRID_SIZE) OR FBoldRight[aCol, aRow];
  var vDrawBottom := (aRow = GRID_SIZE) OR FBoldBottom[aCol, aRow];

  case vDrawRight  of TRUE: begin aCanvas.moveTo(aRect.right - 1, aRect.top);   aCanvas.lineTo(aRect.right - 1, aRect.bottom); end; end;
  case vDrawBottom of TRUE: begin aCanvas.moveTo(aRect.left, aRect.bottom - 1); aCanvas.lineTo(aRect.right, aRect.bottom - 1); end; end;
end;

procedure TCrosswordGrid.drawHyphens(aCanvas: TCanvas; aCol, aRow: integer; aRect: TRect);
begin
  aCanvas.pen.width := 2;
  var vMidY := aRect.top + ((aRect.bottom - aRect.top) div 2);
  var vMidX := aRect.left + ((aRect.right - aRect.left) div 2);

  case FHyphenRight[aCol, aRow] of TRUE: begin aCanvas.moveTo(aRect.right - 4, vMidY); aCanvas.lineTo(aRect.right, vMidY); end; end;

  var vPrevHasHyphenRight := (aCol > 1) AND FHyphenRight[aCol - 1, aRow];
  case vPrevHasHyphenRight of TRUE: begin aCanvas.moveTo(aRect.left, vMidY); aCanvas.lineTo(aRect.left + 4, vMidY); end; end;

  case FHyphenBottom[aCol, aRow] of TRUE: begin aCanvas.moveTo(vMidX, aRect.bottom - 4); aCanvas.lineTo(vMidX, aRect.bottom); end; end;

  var vPrevHasHyphenBottom := (aRow > 1) AND FHyphenBottom[aCol, aRow - 1];
  case vPrevHasHyphenBottom of TRUE: begin aCanvas.moveTo(vMidX, aRect.top); aCanvas.lineTo(vMidX, aRect.top + 4); end; end;

  aCanvas.pen.width := 1;
end;

procedure TCrosswordGrid.drawContent(aCanvas: TCanvas; aCol, aRow: integer; aRect: TRect);
begin
  case FIsBlack[aCol, aRow] of TRUE: EXIT; end;

  case FNumbers[aCol, aRow] > 0 of TRUE: begin
    aCanvas.font.name   := 'Arial';
    aCanvas.font.size   := 8;
    aCanvas.font.style  := [fsBold];
    aCanvas.font.color  := clBlack;
    aCanvas.brush.style := bsClear;
    aCanvas.textOut(aRect.left + 2, aRect.top + 1, intToStr(FNumbers[aCol, aRow]));
  end; end;

  case FLetters[aCol, aRow] <> #0 of TRUE: begin
    aCanvas.font.name   := 'Arial';
    aCanvas.font.size   := 14;
    aCanvas.font.style  := [fsBold];
    aCanvas.font.color  := clBlack;
    aCanvas.brush.style := bsClear;
    var vText           := FLetters[aCol, aRow];
    var vDrawRect       := aRect;
    vDrawRect.top       := vDrawRect.top + 6;
    drawText(aCanvas.handle, pChar(vText), length(vText), vDrawRect, DT_CENTER OR DT_SINGLELINE OR DT_VCENTER);
  end; end;
end;

procedure TCrosswordGrid.gridDrawCell(sender: TObject; aCol, aRow: integer; aRect: TRect; aState: TGridDrawState);
begin
  var vCol    := aCol + 1;
  var vRow    := aRow + 1;
  var vCanvas := FCrosswordGrid.canvas;

  drawBackground(vCanvas, vCol, vRow, aRect);
  drawBorders(vCanvas, vCol, vRow, aRect);
  drawHyphens(vCanvas, vCol, vRow, aRect);
  drawContent(vCanvas, vCol, vRow, aRect);
end;

procedure TCrosswordGrid.advanceCursor(aCol, aRow: integer);
begin
  var vCanMoveRight := (aCol < GRID_SIZE) AND (NOT FIsBlack[aCol + 1, aRow]);
  var vCanMoveDown  := (aRow < GRID_SIZE) AND (NOT FIsBlack[aCol, aRow + 1]);

  var vMoveRight := (FAcrossDirection AND vCanMoveRight) OR (NOT FAcrossDirection AND NOT vCanMoveDown AND vCanMoveRight);
  var vMoveDown  := (NOT FAcrossDirection AND vCanMoveDown) OR (FAcrossDirection AND NOT vCanMoveRight AND vCanMoveDown);

  case vMoveRight of TRUE: FCrosswordGrid.col := FCrosswordGrid.col + 1; end;
  case vMoveDown  of TRUE: FCrosswordGrid.row := FCrosswordGrid.row + 1; end;

  FAcrossDirection := (FAcrossDirection AND (NOT vMoveDown)) OR (vMoveRight AND (NOT FAcrossDirection));
end;

procedure TCrosswordGrid.retreatCursor(aCol, aRow: integer);
begin
  var vMoveLeft := FAcrossDirection AND (aCol > 1);
  var vMoveUp   := (NOT FAcrossDirection) AND (aRow > 1);

  case vMoveLeft of TRUE: FCrosswordGrid.col := FCrosswordGrid.col - 1; end;
  case vMoveUp   of TRUE: FCrosswordGrid.row := FCrosswordGrid.row - 1; end;
end;

procedure TCrosswordGrid.gridKeyPress(sender: TObject; var aKey: char);
begin
  var vCol := FCrosswordGrid.col + 1;
  var vRow := FCrosswordGrid.row + 1;

  case FIsBlack[vCol, vRow] of TRUE: EXIT; end;

  var vIsModifier := aKey in ['|', '_', '-', '='];
  var vIsSetupAndModifier := {SETUP AND} vIsModifier;

  case vIsSetupAndModifier of TRUE: begin applySetupModifier(vCol, vRow, aKey); EXIT; end; end;

  case NOT (aKey in ['a'..'z', 'A'..'Z', #8]) of TRUE: EXIT; end;

  case aKey = #8 of TRUE: begin
    FLetters[vCol, vRow] := #0;
    retreatCursor(vCol, vRow);
    FCrosswordGrid.invalidate;
    EXIT;
  end; end;

  FLetters[vCol, vRow] := upCase(aKey);
  advanceCursor(vCol, vRow);
  FCrosswordGrid.invalidate;
end;

procedure TCrosswordGrid.gridMouseDown(sender: TObject; button: TMouseButton; shift: TShiftState; x, y: integer);
begin
  case NOT SETUP of TRUE: EXIT; end;

  var vDrawCol := -1;
  var vDrawRow := -1;
  FCrosswordGrid.mouseToCell(x, y, vDrawCol, vDrawRow);

  case (vDrawCol < 0) OR (vDrawRow < 0) of TRUE: EXIT; end;

  var vCol := vDrawCol + 1;
  var vRow := vDrawRow + 1;

  case button = mbLeft of TRUE: FIsBlack[vCol, vRow] := FALSE; end;

  case button = mbRight of TRUE: begin
    FIsBlack[vCol, vRow]      := TRUE;
    FLetters[vCol, vRow]      := #0;
    FBoldRight[vCol, vRow]    := FALSE;
    FBoldBottom[vCol, vRow]   := FALSE;
    FHyphenRight[vCol, vRow]  := FALSE;
    FHyphenBottom[vCol, vRow] := FALSE;
  end; end;

  calculateNumbers;
  FCrosswordGrid.invalidate;
end;

procedure TCrosswordGrid.readSavedGrid(const aFilename: string; aIndex: integer);
begin
  case fileExists(aFilename) of FALSE: EXIT; end;

  var vStringList := TStringList.create;
  try
    vStringList.loadFromFile(aFilename);
    case aIndex = -1 of TRUE: aIndex := vStringList.count - 1; end;

    case (aIndex >= 0) AND (aIndex < vStringList.count) of TRUE: setupGrid(vStringList[aIndex]); end;
  finally
    vStringList.free;
  end;
end;

procedure TCrosswordGrid.gridKeyDown(sender: TObject; var aKey: word; aShift: TShiftState);
begin
  case aKey = VK_ESCAPE of TRUE: begin
    var vForm := getParentForm(FCrosswordGrid);
    case vForm <> NIL of TRUE: TForm(vForm).close; end;
    EXIT;
  end; end;

  case (aKey = VK_RIGHT) OR (aKey = VK_LEFT) of TRUE: FAcrossDirection := TRUE;  end;
  case (aKey = VK_DOWN)  OR (aKey = VK_UP)   of TRUE: FAcrossDirection := FALSE; end;

  case aKey = VK_SPACE of TRUE: begin
    FAcrossDirection := NOT FAcrossDirection;
    FCrosswordGrid.invalidate;
  end; end;
end;

end.
