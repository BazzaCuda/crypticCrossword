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
unit TCrosswordGridClass;

{ from the readme.md:

**layout string**

The layout string describes the grid, row by row, similar to FEN chess notation
| character | purpose |
| ----- | ----- |
| dot . | is a black, non-square in the grid |
| digits 0..9 | indicate a number of consecutive letter squares |
| slash / | indicates the end of a row |
| vertical bar | the current across-clue square is to be followed by a bold vertical word-break |
| underscore _ | the current down-clue square is to have a bold horizontal word-break |
| hyphen - | the current across-clue square is to have a horizontal hyphen to the next square |
| equals = | the current down-clue square is to have a vertical hyphen to the next square |
| any capital letter A..Z | is entered in the square |

e.g. a standard empty grid
```
1.1.1.1.1.1.1.1/9.5/1.1.1.1.1.1.1.1/5.9/..1.1.1.1...1../7.7/1...1...1.1.1.1/5.3.5/1.1.1.1...1...1/7.7/..1...1.1.1.1../9.5/1.1.1.1.1.1.1.1/5.9/1.1.1.1.1.1.1.1
```

e.g. a partially-completed grid
```
1.1.1.M.1.E=.1.B/6I2.FRAIL/1.1.1.S.1.I.1.U/5.SPECTACLE/..1.1.U.1...1../G5S.6S/A...1...1.1.1.T/VALUE.FOR.MONEY/E.A.1.O...1...L/LIMITER.FELLINI/..B_...W.1.1.1_../KICK-START.4M/1.H.1.R.1.1.1.O/2O2.DERRING-DO/1.P.1.S.1.1.1.N
```

e.g. a fully-completed grid (see screenshot)
```
S.G.E.M.O.E=.S.B/PLAINTIFF.FRAIL/A.M.R.S.F.I.N.U/TEMPI.SPECTACLE/..O.C.U.N...T../GENGHIS.DISMISS/A...M...E.I.O.T/VALUE.FOR.MONEY/E.A.N.O...P...L/LIMITER.FELLINI/..B_...W.U.I.N_../KICK-START.SCRUM/H.H.A.R.U.T.A.O/ACORN.DERRING-DO/N.P.D.S.E.C.S.N
```

Simply pass the string to the stringToGrid method to populate the grid.

**grid setup**

left-click: set the square to an empty letter square

right-click: set the square to a black non-letter square

across and down clue numbers are assigned automatically as you amend the grid

**entering letters**

DELETE - empty the square but stay put

BACKSPACE - empty the square and reverse the cursor one square

arrow keys - move cursor

**square modifiers**

In addition to specifying the word-break and hyphenations in the layout string, they can be set independently of the layout string either by grid location or by specifying the clue number and the number of the letter:
```
  addModifierByClue(15, cdAcross, 4, gmAcrossWordBreak);
  addModifierByClue(15, cdAcross, 6, gmAcrossWordBreak);
  addModifierByClue(27, cdAcross, 4, gmAcrossWordBreak);
  addModifierByClue( 3, cdDown,   1, gmDownWordBreak);
  addModifierByClue( 4, cdAcross, 4, gmAcrossHyphen);
  addModifierByClue( 4, cdDown,   4, gmDownHyphen);
```


}

interface

uses
  winAPI.messages, winAPI.windows,
  system.classes, system.sysUtils, system.types, system.UITypes, system.variants,
  vcl.controls, vcl.dialogs, vcl.extCtrls, vcl.forms, vcl.graphics, vcl.grids;

const
  GRID_SIZE   = 15;

type
  void            = record end;
  TClueDirection  = (cdAcross, cdDown);
  TGridModifier   = (gmAcrossWordBreak, gmDownWordBreak, gmAcrossHyphen, gmDownHyphen);

  ICrosswordGrid = interface
    function  addModifier(aCol: integer; aRow: integer; aModifier: TGridModifier): void;
    function  addModifierByClue(aClueNumber: integer; aDirection: TClueDirection; aLetterPosition: integer; aModifier: TGridModifier): void;
    function  applyModifier(aCol: integer; aRow: integer; aKey: char): void;
    function  arrayToGrid(const aLines: array of string): void;
    function  clearGrid: void;
    function  isDirty: boolean;
    function  readSavedGrid(const aFilename: string; aIndex: integer): void;
    function  saveGridToFile(const aFilename: string): void;
    function  setupGrid: boolean;
    function  stringToGrid(const aLayout: string): void;
  end;

function newCrosswordGrid(const aParent: TWinControl): ICrosswordGrid;

implementation

uses
  _debugWindow;

const
  KEY_BACKSPACE =  #8;

type
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
    FIsDirty:         boolean;
    FSetupGrid:       boolean;

    { TCrosswordGrid }
    function  advanceCursor(aCol: integer; aRow: integer): void;
    function  applyBlanks(var aCol: integer; aRow: integer; var aNumStr: string): void;
    function  calculateNumbers: void;
    function  clearSquare: void;
    function  encodeRow(aRow: integer): string;
    function  needsNumber(aCol: integer; aRow: integer): boolean;
    function  retreatCursor(aCol: integer; aRow: integer): void;

    { draw methods }
    function  drawBackground  (aCanvas: TCanvas; aCol: integer; aRow: integer; aRect: TRect): void;
    function  drawBorders     (aCanvas: TCanvas; aCol: integer; aRow: integer; aRect: TRect): void;
    function  drawHyphens     (aCanvas: TCanvas; aCol: integer; aRow: integer; aRect: TRect): void;
    function  drawContent     (aCanvas: TCanvas; aCol: integer; aRow: integer; aRect: TRect): void;

    { TDrawGrid event handlers }
    procedure gridDrawCell(sender: TObject; aCol: integer; aRow: integer; aRect: TRect; aState: TGridDrawState);
    procedure gridKeyDown(sender: TObject; var aKey: word; aShift: TShiftState);
    procedure gridKeyPress(sender: TObject; var aKey: char);
    procedure gridMouseDown(sender: TObject; button: TMouseButton; shift: TShiftState; X: integer; Y: integer);

  public
    constructor Create(const aParent: TWinControl);

    { ICrosswordGrid }
    function  addModifier(aCol: integer; aRow: integer; aModifier: TGridModifier): void;
    function  addModifierByClue(aClueNumber: integer; aDirection: TClueDirection; aLetterPosition: integer; aModifier: TGridModifier): void;
    function  applyModifier(aCol: integer; aRow: integer; aKey: char): void;
    function  arrayToGrid(const aLines: array of string): void;
    function  clearGrid: void;
    function  isDirty: boolean;
    function  readSavedGrid(const aFilename: string; aIndex: integer): void;
    function  saveGridToFile(const aFilename: string): void;
    function  setupGrid: boolean;
    function  stringToGrid(const aLayout: string): void;
  end;

function newCrosswordGrid(const aParent: TWinControl): ICrosswordGrid;
begin
  result := TCrosswordGrid.create(aParent);
end;

constructor TCrosswordGrid.Create(const aParent: TWinControl);
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

{ ICrosswordGrid }

function  TCrosswordGrid.addModifier(aCol, aRow: integer; aModifier: TGridModifier): void;
begin
  FBoldRight    [aCol, aRow]  := FBoldRight     [aCol, aRow]  OR (aModifier = gmAcrossWordBreak);
  FBoldBottom   [aCol, aRow]  := FBoldBottom    [aCol, aRow]  OR (aModifier = gmDownWordBreak);
  FHyphenRight  [aCol, aRow]  := FHyphenRight   [aCol, aRow]  OR (aModifier = gmAcrossHyphen);
  FHyphenBottom [aCol, aRow]  := FHyphenBottom  [aCol, aRow]  OR (aModifier = gmDownHyphen);

  FCrosswordGrid.invalidate;
end;

function  TCrosswordGrid.addModifierByClue(aClueNumber: integer; aDirection: TClueDirection; aLetterPosition: integer; aModifier: TGridModifier): void;
begin
  var vFound     := FALSE;
  var vTargetCol := 0;
  var vTargetRow := 0;

  for var vRow := 1 to GRID_SIZE do
    for var vCol := 1 to GRID_SIZE do begin
      var vIsMatch := (FNumbers[vCol, vRow] = aClueNumber) AND (NOT vFound);

      case vIsMatch AND (aDirection = cdAcross) of TRUE: begin
        vTargetCol := vCol + aLetterPosition - 1;
        vTargetRow := vRow;
        vFound := TRUE;
      end;end;

      case vIsMatch AND (aDirection = cdDown) of TRUE: begin
        vTargetCol := vCol;
        vTargetRow := vRow + aLetterPosition - 1;
        vFound := TRUE;
      end;end;
    end;


  case vFound of TRUE: addModifier(vTargetCol, vTargetRow, aModifier); end;
end;

function  TCrosswordGrid.applyModifier(aCol, aRow: integer; aKey: char): void;
begin
  FBoldRight    [aCol, aRow]  := FBoldRight     [aCol, aRow] XOR (aKey = '|');
  FBoldBottom   [aCol, aRow]  := FBoldBottom    [aCol, aRow] XOR (aKey = '_');
  FHyphenRight  [aCol, aRow]  := FHyphenRight   [aCol, aRow] XOR (aKey = '-');
  FHyphenBottom [aCol, aRow]  := FHyphenBottom  [aCol, aRow] XOR (aKey = '=');

  FCrosswordGrid.invalidate;
end;

function  TCrosswordGrid.arrayToGrid(const aLines: array of string): void;
begin
  var vCombined := '';
  for var vIndex := low(aLines) to high(aLines) do begin
    case vCombined <> '' of TRUE: vCombined := vCombined + '/'; end;
    vCombined := vCombined + aLines[vIndex];
  end;
  stringToGrid(vCombined);
end;

function  TCrosswordGrid.clearGrid;
begin
  for var vRow := 1 to GRID_SIZE do
    for var vCol := 1 to GRID_SIZE do begin
      FIsBlack      [vCol, vRow]  := FALSE;
      FNumbers      [vCol, vRow]  := 0;
      FLetters      [vCol, vRow]  := #0;
      FBoldRight    [vCol, vRow]  := FALSE;
      FBoldBottom   [vCol, vRow]  := FALSE;
      FHyphenRight  [vCol, vRow]  := FALSE;
      FHyphenBottom [vCol, vRow]  := FALSE;
    end;
end;

function TCrosswordGrid.isDirty: boolean;
begin
  result := FIsDirty;
end;

function  TCrosswordGrid.readSavedGrid(const aFilename: string; aIndex: integer): void;
begin
  case fileExists(aFilename) of FALSE: EXIT; end;

  var vStringList := TStringList.create;
  try
    vStringList.loadFromFile(aFilename);
    case aIndex = -1 of TRUE: aIndex := vStringList.count - 1; end;

    case (aIndex >= 0) AND (aIndex < vStringList.count) of TRUE: stringToGrid(vStringList[aIndex]); end;
  finally
    vStringList.free;
  end;
end;

function  TCrosswordGrid.saveGridToFile(const aFilename: string): void;
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

function TCrosswordGrid.setupGrid: boolean;
begin
  FSetupGrid := NOT FSetupGrid;
  result := FSetupGrid;
end;

function  TCrosswordGrid.stringToGrid(const aLayout: string): void;
begin
  clearGrid;

  var vCol            := 1;
  var vRow            := 1;
  var vNumStr: string := '';

  for var vIx := 1 to length(aLayout) do begin
    var vChar := aLayout[vIx];

    case vChar in ['A'..'Z'] of TRUE: begin
      applyBlanks(vCol, vRow, vNumStr);
      FLetters[vCol, vRow] := vChar;
      inc(vCol);
      CONTINUE;
    end;end;

    case vChar in ['0'..'9'] of TRUE: begin
      vNumStr := vNumStr + vChar;
      CONTINUE;
    end;end;

    applyBlanks(vCol, vRow, vNumStr);

    case vChar = '.' of TRUE: begin
      FIsBlack[vCol, vRow] := TRUE;
      inc(vCol);
      CONTINUE;
    end;end;

    case vChar = '/' of TRUE: begin
      vCol := 1;
      inc(vRow);
      CONTINUE;
    end;end;

    FBoldRight    [vCol - 1, vRow]  := FBoldRight     [vCol - 1, vRow] OR (vChar = '|');
    FBoldBottom   [vCol - 1, vRow]  := FBoldBottom    [vCol - 1, vRow] OR (vChar = '_');
    FHyphenRight  [vCol - 1, vRow]  := FHyphenRight   [vCol - 1, vRow] OR (vChar = '-');
    FHyphenBottom [vCol - 1, vRow]  := FHyphenBottom  [vCol - 1, vRow] OR (vChar = '=');
  end;

  applyBlanks(vCol, vRow, vNumStr);
  calculateNumbers;
end;

{ TCrosswordGrid }

function TCrosswordGrid.advanceCursor(aCol, aRow: integer): void;
begin
  var vCanMoveRight := (aCol < GRID_SIZE) AND (NOT FIsBlack[aCol + 1, aRow]);
  var vCanMoveDown  := (aRow < GRID_SIZE) AND (NOT FIsBlack[aCol, aRow + 1]);

  var vMoveRight := (FAcrossDirection AND vCanMoveRight) OR (NOT FAcrossDirection AND NOT vCanMoveDown AND vCanMoveRight);
  var vMoveDown  := (NOT FAcrossDirection AND vCanMoveDown) OR (FAcrossDirection AND NOT vCanMoveRight AND vCanMoveDown);

  case vMoveRight of TRUE: FCrosswordGrid.col := FCrosswordGrid.col + 1; end;
  case vMoveDown  of TRUE: FCrosswordGrid.row := FCrosswordGrid.row + 1; end;

  FAcrossDirection := (FAcrossDirection AND (NOT vMoveDown)) OR (vMoveRight AND (NOT FAcrossDirection));
end;

function TCrosswordGrid.applyBlanks(var aCol: integer; aRow: integer; var aNumStr: string): void;
begin
  case aNumStr = '' of TRUE: EXIT; end;

  var vSpaceCount := strToInt(aNumStr);
  for var vC := 1 to vSpaceCount do begin
    FIsBlack[aCol, aRow] := FALSE;
    inc(aCol);
  end;

  aNumStr := '';
end;

function TCrosswordGrid.calculateNumbers: void;
begin
  var vNum := 1;
  for var vRow := 1 to GRID_SIZE do
    for var vCol := 1 to GRID_SIZE do begin
      FNumbers[vCol, vRow] := 0;
      case needsNumber(vCol, vRow) of TRUE: begin
        FNumbers[vCol, vRow] := vNum;
        inc(vNum);
      end;end;
    end;
end;

function TCrosswordGrid.clearSquare: void;
begin
  var vCol := FCrosswordGrid.col + 1;
  var vRow := FCrosswordGrid.row + 1;

  FLetters[vCol, vRow] := #0;
  FCrosswordGrid.invalidate;
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

    case (vIsCellBlack OR vHasLetter) AND (vEmptyCount > 0) of TRUE: begin
      result := result + intToStr(vEmptyCount);
      vEmptyCount := 0;
    end;end;

    case vIsCellBlack of TRUE: result := result + '.'; end;
    case vHasLetter AND (NOT vIsCellBlack) of TRUE: result := result + FLetters[vCol, aRow]; end;

    case vHasModifier AND (vEmptyCount > 0) of TRUE: begin
      result := result + intToStr(vEmptyCount);
      vEmptyCount := 0;
    end;end;

    case FBoldRight     [vCol, aRow]  of TRUE: result := result + '|'; end;
    case FBoldBottom    [vCol, aRow]  of TRUE: result := result + '_'; end;
    case FHyphenRight   [vCol, aRow]  of TRUE: result := result + '-'; end;
    case FHyphenBottom  [vCol, aRow]  of TRUE: result := result + '='; end;
  end;

  case vEmptyCount > 0 of TRUE: result := result + intToStr(vEmptyCount); end;
end;

function TCrosswordGrid.needsNumber(aCol: integer; aRow: integer): boolean;
begin
  result := FALSE;
  case FIsBlack[aCol, aRow] of TRUE: EXIT; end;

  var vHasLeft   := (aCol > 1)         AND (NOT FIsBlack[aCol - 1, aRow]);
  var vHasRight  := (aCol < GRID_SIZE) AND (NOT FIsBlack[aCol + 1, aRow]);
  var vHasTop    := (aRow > 1)         AND (NOT FIsBlack[aCol, aRow - 1]);
  var vHasBottom := (aRow < GRID_SIZE) AND (NOT FIsBlack[aCol, aRow + 1]);

  result := (vHasRight AND (NOT vHasLeft)) OR (vHasBottom AND (NOT vHasTop));
end;

{ draw methods }

function TCrosswordGrid.drawBackground(aCanvas: TCanvas; aCol: integer; aRow: integer; aRect: TRect): void;
begin
  var vIsSelected := (NOT FIsBlack[aCol, aRow]) AND (aCol - 1 = FCrosswordGrid.col) AND (aRow - 1 = FCrosswordGrid.row);

  case FIsBlack[aCol, aRow]                             of TRUE: aCanvas.brush.color := clBlack; end;
  case vIsSelected                                      of TRUE: aCanvas.brush.color := $00EAF5EA; end;
  case (NOT FIsBlack[aCol, aRow]) AND (NOT vIsSelected) of TRUE: aCanvas.brush.color := clWhite; end;

  aCanvas.fillRect(aRect);
end;

function TCrosswordGrid.retreatCursor(aCol: integer; aRow: integer): void;
begin
  var vMoveLeft := FAcrossDirection AND (aCol > 1);
  var vMoveUp   := (NOT FAcrossDirection) AND (aRow > 1);

  case vMoveLeft of TRUE: FCrosswordGrid.col := FCrosswordGrid.col - 1; end;
  case vMoveUp   of TRUE: FCrosswordGrid.row := FCrosswordGrid.row - 1; end;
end;

function TCrosswordGrid.drawBorders(aCanvas: TCanvas; aCol: integer; aRow: integer; aRect: TRect): void;
begin
  aCanvas.pen.color := clBlack;
  aCanvas.pen.width := 1;

  aCanvas.moveTo(aRect.left, aRect.top);
  aCanvas.lineTo(aRect.right, aRect.top);
  aCanvas.moveTo(aRect.left, aRect.top);
  aCanvas.lineTo(aRect.left, aRect.bottom);

  case (aCol = GRID_SIZE) OR FBoldRight[aCol, aRow] of TRUE: begin
    aCanvas.moveTo(aRect.right - 1, aRect.top);
    aCanvas.lineTo(aRect.right - 1, aRect.bottom);
  end;end;

  case (aRow = GRID_SIZE) OR FBoldBottom[aCol, aRow] of TRUE: begin
    aCanvas.moveTo(aRect.left, aRect.bottom - 1);
    aCanvas.lineTo(aRect.right, aRect.bottom - 1);
  end;end;
end;

function TCrosswordGrid.drawContent(aCanvas: TCanvas; aCol: integer; aRow: integer; aRect: TRect): void;
begin
  case FIsBlack[aCol, aRow] of TRUE: EXIT; end;

  case FNumbers[aCol, aRow] > 0 of TRUE: begin
    aCanvas.font.name   := 'Arial';
    aCanvas.font.size   := 8;
    aCanvas.font.style  := [fsBold];
    aCanvas.font.color  := clBlack;
    aCanvas.brush.style := bsClear;
    aCanvas.textOut(aRect.left + 2, aRect.top + 1, intToStr(FNumbers[aCol, aRow]));
  end;end;

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
  end;end;
end;

function TCrosswordGrid.drawHyphens(aCanvas: TCanvas; aCol: integer; aRow: integer; aRect: TRect): void;
begin
  aCanvas.pen.width := 2;
  var vMidY := aRect.top + ((aRect.bottom - aRect.top) div 2);
  var vMidX := aRect.left + ((aRect.right - aRect.left) div 2);

  case FHyphenRight[aCol, aRow] of TRUE: begin
    aCanvas.moveTo(aRect.right - 4, vMidY);
    aCanvas.lineTo(aRect.right, vMidY);
  end;end;

  case (aCol > 1) AND FHyphenRight[aCol - 1, aRow] of TRUE: begin
    aCanvas.moveTo(aRect.left, vMidY);
    aCanvas.lineTo(aRect.left + 4, vMidY);
  end;end;

  case FHyphenBottom[aCol, aRow] of TRUE: begin
    aCanvas.moveTo(vMidX, aRect.bottom - 4);
    aCanvas.lineTo(vMidX, aRect.bottom);
  end;end;

  case (aRow > 1) AND FHyphenBottom[aCol, aRow - 1] of TRUE: begin
    aCanvas.moveTo(vMidX, aRect.top);
    aCanvas.lineTo(vMidX, aRect.top + 4);
  end;end;

  aCanvas.pen.width := 1;
end;

{ TDrawGrid event handlers }

procedure TCrosswordGrid.gridDrawCell(sender: TObject; aCol: integer; aRow: integer; aRect: TRect; aState: TGridDrawState);
begin
  var vCol    := aCol + 1;
  var vRow    := aRow + 1;
  var vCanvas := FCrosswordGrid.canvas;

  drawBackground(vCanvas, vCol, vRow, aRect);
  drawBorders(vCanvas, vCol, vRow, aRect);
  drawHyphens(vCanvas, vCol, vRow, aRect);
  drawContent(vCanvas, vCol, vRow, aRect);
end;

procedure TCrosswordGrid.gridKeyDown(sender: TObject; var aKey: word; aShift: TShiftState);
begin
  case aKey = VK_ESCAPE of TRUE: begin
    var vForm := getParentForm(FCrosswordGrid);
    case vForm <> NIL of TRUE: TForm(vForm).close; end;
    EXIT;
  end;end;

  case (aKey = VK_RIGHT) OR (aKey = VK_LEFT) of TRUE: FAcrossDirection := TRUE;  end;
  case (aKey = VK_DOWN)  OR (aKey = VK_UP)   of TRUE: FAcrossDirection := FALSE; end;

  case aKey = VK_SPACE of TRUE: begin
    FAcrossDirection := NOT FAcrossDirection;
    FCrosswordGrid.invalidate;
  end;end;

  case aKey = VK_DELETE of TRUE: clearSquare; end;
end;

procedure TCrosswordGrid.gridKeyPress(sender: TObject; var aKey: char);
begin
  var vCol := FCrosswordGrid.col + 1;
  var vRow := FCrosswordGrid.row + 1;

  case FIsBlack[vCol, vRow] of TRUE: EXIT; end;

  var vIsModifier := aKey in ['|', '_', '-', '='];

  case vIsModifier of TRUE: begin
    applyModifier(vCol, vRow, aKey);
    FIsDirty := TRUE;
    EXIT;
  end;end;

  case aKey in ['a'..'z', 'A'..'Z', KEY_BACKSPACE] of FALSE: EXIT; end;

  FIsDirty := TRUE;

  case aKey in [KEY_BACKSPACE] of
   TRUE:  begin
            FLetters[vCol, vRow] := #0;
            retreatCursor(vCol, vRow); end;
  FALSE:  begin
            FLetters[vCol, vRow] := upCase(aKey);
            advanceCursor(vCol, vRow);
          end;end;

  FCrosswordGrid.invalidate;
end;

procedure TCrosswordGrid.gridMouseDown(sender: TObject; button: TMouseButton; shift: TShiftState; X: integer; Y: integer);
begin
  case FSetupGrid of FALSE: EXIT; end;

  var vDrawCol := -1;
  var vDrawRow := -1;
  FCrosswordGrid.mouseToCell(X, Y, vDrawCol, vDrawRow);

  case (vDrawCol < 0) OR (vDrawRow < 0) of TRUE: EXIT; end;

  var vCol := vDrawCol + 1;
  var vRow := vDrawRow + 1;

  case button = mbLeft of TRUE: FIsBlack[vCol, vRow] := FALSE; end;

  case button = mbRight of TRUE: begin
    FIsBlack      [vCol, vRow]  := TRUE;
    FLetters      [vCol, vRow]  := #0;
    FBoldRight    [vCol, vRow]  := FALSE;
    FBoldBottom   [vCol, vRow]  := FALSE;
    FHyphenRight  [vCol, vRow]  := FALSE;
    FHyphenBottom [vCol, vRow]  := FALSE;
  end;end;

  calculateNumbers;
  FIsDirty := TRUE;
  FCrosswordGrid.invalidate;
end;

end.
