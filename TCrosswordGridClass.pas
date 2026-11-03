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
  TGridDirection  = (gdAcross, gdDown);

  ICrosswordGrid = interface
    function  addModifier       (const aCol: integer; const aRow: integer; const aModifier: TGridModifier): void;
    function  addModifierByClue (const aClueNumber: integer; const aDirection: TClueDirection; const aLetterPosition: integer; const aModifier: TGridModifier): void;
    function  applyModifier     (const aCol: integer; const aRow: integer; aKey: char): void;
    function  arrayToGrid       (const aLines: array of string): void;
    function  changed:        boolean;
    function  clearGrid:      void;
    function  readSavedGrid     (const aFilename: string; const aIx: integer): void;
    function  saveGridToFile    (const aFilename: string): void;
    function  setupGrid:      boolean;
    function  stringToGrid      (const aLayout: string): void;
    function  title             (const aTitle: string = ''): string;
  end;

function newCrosswordGrid(const aParent: TWinControl): ICrosswordGrid;

implementation

uses
  _debugWindow;

const
  CLUE_JUMP_TIMEOUT_MS  = 750;

  EMPTY_CHAR            = #0;
  EMPTY_STRING: string  = '';

  CHAR_BACKSPACE        =  #8;
  CHAR_DOLLAR           = '$';
  CHAR_DOT              = '.';
  CHAR_EQUALS           = '=';
  CHAR_HASH             = '#';
  CHAR_HYPHEN           = '-';
  CHAR_SLASH            = '/';
  CHAR_UNDERSCORE       = '_';
  CHAR_VERTICAL_BAR     = '|';

  CHAR_SET_0_TO_9       = ['0'..'9'];
  CHAR_SET_A_TO_Z       = ['A'..'Z'];
  CHAR_SET_MODIFIERS    = [CHAR_VERTICAL_BAR, CHAR_UNDERSCORE, CHAR_HYPHEN, CHAR_EQUALS];

type
  TCrosswordGrid = class(TInterfacedObject, ICrosswordGrid)
  private
    FCrosswordGrid:   TDrawGrid;

    FBlackSquare:     array[1..GRID_SIZE, 1..GRID_SIZE] of boolean;
    FNumbers:         array[1..GRID_SIZE, 1..GRID_SIZE] of integer;
    FLetters:         array[1..GRID_SIZE, 1..GRID_SIZE] of char;
    FBoldRight:       array[1..GRID_SIZE, 1..GRID_SIZE] of boolean;
    FBoldBottom:      array[1..GRID_SIZE, 1..GRID_SIZE] of boolean;
    FHyphenRight:     array[1..GRID_SIZE, 1..GRID_SIZE] of boolean;
    FHyphenBottom:    array[1..GRID_SIZE, 1..GRID_SIZE] of boolean;

    FClueJumpBuffer:  string;
    FDate:            string;
    FDirty:           boolean;
    FGridDirection:   TGridDirection;
    FLastDigitTick:   uint64;
    FSetupGrid:       boolean;
    FTitle:           string;

    { TCrosswordGrid }
    function  advanceCursor (const aCol: integer; const aRow: integer): void;
    function  advanceGridCol: void;
    function  advanceGridRow: void;
    function  applyBlanks   (var aCol: integer; const aRow: integer; var aNumStr: string): void;
    function  calculateNumbers: void;
    function  checkClueDigit  (const aDigit: char): void;
    function  checkGridDirection(const aCol: integer; const aRow: integer; const aGridDirection: TGridDirection): TGridDirection;
    function  clearSquare:  void;
    function  gridCol:      integer;
    function  gridRow:      integer;
    function  encodeGrid:   string;
    function  encodeRow     (const aRow: integer): string;
    function  jumpToClue    (const aClueNumber: integer): void;
    function  needsNumber   (const aCol: integer; const aRow: integer): boolean;
    function  retreatCursor (const aCol: integer; const aRow: integer): void;
    function  retreatGridCol: void;
    function  retreatGridRow: void;
    function  stripInfo(const aLayout: string; const aDelimiter: char; out oInfo: string): string;

    { draw methods }
    function  drawBackground  (const aCanvas: TCanvas; const aCol: integer; const aRow: integer; const aRect: TRect): void;
    function  drawBorders     (const aCanvas: TCanvas; const aCol: integer; const aRow: integer; const aRect: TRect): void;
    function  drawHyphens     (const aCanvas: TCanvas; const aCol: integer; const aRow: integer; const aRect: TRect): void;
    function  drawContent     (const aCanvas: TCanvas; const aCol: integer; const aRow: integer; const aRect: TRect): void;

    { TDrawGrid event handlers }
    procedure gridDrawCell(sender: TObject; aCol: integer; aRow: integer; aRect: TRect; aState: TGridDrawState);
    procedure gridKeyDown(sender: TObject; var aKey: word; aShift: TShiftState);
    procedure gridKeyPress(sender: TObject; var aKey: char);
    procedure gridMouseDown(sender: TObject; button: TMouseButton; shift: TShiftState; X: integer; Y: integer);

    { key handlers }
    function  handleBackspace(var aKey: char): boolean;
    function  handleDot(var aKey: char): boolean;
    function  handleDigit(var aKey: char): boolean;
    function  handleLetter(var aKey: char): boolean;
    function  handleModifier(var aKey: char): boolean;

    function  squareInActiveAcrossClue(const aCol: integer; const aRow: integer): boolean;
    function  squareInActiveClue      (const aCol: integer; const aRow: integer): boolean;
    function  squareInActiveDownClue  (const aCol: integer; const aRow: integer): boolean;

  public
    constructor Create(const aParent: TWinControl);

    { ICrosswordGrid }
    function  addModifier         (const aCol: integer; const aRow: integer; const aModifier: TGridModifier): void;
    function  addModifierByClue   (const aClueNumber: integer; const aDirection: TClueDirection; const aLetterPosition: integer; const aModifier: TGridModifier): void;
    function  applyModifier       (const aCol: integer; const aRow: integer; aKey: char): void;
    function  arrayToGrid         (const aLines: array of string): void;
    function  changed:            boolean;
    function  clearGrid:          void;
    function  readSavedGrid       (const aFilename: string; const aIx: integer): void;
    function  saveGridToFile      (const aFilename: string): void;
    function  setupGrid: boolean;
    function  stringToGrid        (const aLayout: string): void;
    function  title               (const aTitle: string = ''): string;
  end;

function newCrosswordGrid(const aParent: TWinControl): ICrosswordGrid;
begin
  result := TCrosswordGrid.create(aParent);
end;

constructor TCrosswordGrid.Create(const aParent: TWinControl);
begin
  inherited create;

  FCrosswordGrid                  := TDrawGrid.create(aParent);
  FCrosswordGrid.parent           := aParent;
  FCrosswordGrid.align            := alClient;
  FCrosswordGrid.colCount         := GRID_SIZE;
  FCrosswordGrid.rowCount         := GRID_SIZE;
  FCrosswordGrid.defaultColWidth  := 33;
  FCrosswordGrid.defaultRowHeight := 33;
  FCrosswordGrid.fixedCols        := 0;
  FCrosswordGrid.fixedRows        := 0;
  FCrosswordGrid.scrollBars       := system.UITypes.TScrollStyle.ssNone;
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

function  TCrosswordGrid.addModifier(const aCol: integer; const aRow: integer; const aModifier: TGridModifier): void;
begin
  FBoldRight    [aCol, aRow]  := FBoldRight     [aCol, aRow]  OR (aModifier = gmAcrossWordBreak);
  FBoldBottom   [aCol, aRow]  := FBoldBottom    [aCol, aRow]  OR (aModifier = gmDownWordBreak);
  FHyphenRight  [aCol, aRow]  := FHyphenRight   [aCol, aRow]  OR (aModifier = gmAcrossHyphen);
  FHyphenBottom [aCol, aRow]  := FHyphenBottom  [aCol, aRow]  OR (aModifier = gmDownHyphen);

  FCrosswordGrid.invalidate;
end;

function  TCrosswordGrid.addModifierByClue(const aClueNumber: integer; const aDirection: TClueDirection; const aLetterPosition: integer; const aModifier: TGridModifier): void;
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

function  TCrosswordGrid.applyModifier(const aCol: integer; const aRow: integer; aKey: char): void;
begin
  FBoldRight    [aCol, aRow]  := FBoldRight     [aCol, aRow] XOR (aKey = CHAR_VERTICAL_BAR);
  FBoldBottom   [aCol, aRow]  := FBoldBottom    [aCol, aRow] XOR (aKey = CHAR_UNDERSCORE);
  FHyphenRight  [aCol, aRow]  := FHyphenRight   [aCol, aRow] XOR (aKey = CHAR_HYPHEN);
  FHyphenBottom [aCol, aRow]  := FHyphenBottom  [aCol, aRow] XOR (aKey = CHAR_EQUALS);

  FCrosswordGrid.invalidate;
end;

function  TCrosswordGrid.arrayToGrid(const aLines: array of string): void;
begin
  var vCombined := EMPTY_STRING;
  for var vIndex := low(aLines) to high(aLines) do begin
    case vCombined <> EMPTY_STRING of TRUE: vCombined := vCombined + CHAR_SLASH; end;
    vCombined := vCombined + aLines[vIndex];
  end;
  stringToGrid(vCombined);
end;

function TCrosswordGrid.changed: boolean;
begin
  result := FDirty;
end;

function TCrosswordGrid.checkClueDigit(const aDigit: char): void;
begin
  var vCurrentTick := winApi.windows.getTickCount64;

  case (vCurrentTick - FLastDigitTick) <= CLUE_JUMP_TIMEOUT_MS of
     TRUE: FClueJumpBuffer := FClueJumpBuffer + aDigit;
    FALSE: FClueJumpBuffer := aDigit;
  end;

  FLastDigitTick := vCurrentTick;
  jumpToClue(strToInt(FClueJumpBuffer));
end;

function TCrosswordGrid.checkGridDirection(const aCol: integer; const aRow: integer; const aGridDirection: TGridDirection): TGridDirection;
begin
  result := aGridDirection;

  var vCanAcross := ((aCol > 1) and (NOT FBlackSquare[aCol - 1, aRow])) or ((aCol < GRID_SIZE) and (NOT FBlackSquare[aCol + 1, aRow]));
  var vCanDown   := ((aRow > 1) and (NOT FBlackSquare[aCol, aRow - 1])) or ((aRow < GRID_SIZE) and (NOT FBlackSquare[aCol, aRow + 1]));

  case aGridDirection of
    gdAcross: case vCanDown and (NOT vCanAcross) of TRUE: result := gdDown; end;
    gdDown:   case vCanAcross and (NOT vCanDown) of TRUE: result := gdAcross; end;
  end;
end;

function  TCrosswordGrid.clearGrid;
begin
  for var vRow := 1 to GRID_SIZE do
    for var vCol := 1 to GRID_SIZE do begin
      FBlackSquare  [vCol, vRow]  := FALSE;
      FNumbers      [vCol, vRow]  := 0;
      FLetters      [vCol, vRow]  := EMPTY_CHAR;
      FBoldRight    [vCol, vRow]  := FALSE;
      FBoldBottom   [vCol, vRow]  := FALSE;
      FHyphenRight  [vCol, vRow]  := FALSE;
      FHyphenBottom [vCol, vRow]  := FALSE;
    end;
  FCrosswordGrid.invalidate;
end;

function TCrosswordGrid.jumpToClue(const aClueNumber: integer): void;
begin
  for var vRow := 1 to GRID_SIZE do
    for var vCol := 1 to GRID_SIZE do begin
      case FNumbers[vCol, vRow] = aClueNumber of FALSE: CONTINUE; end;
      FCrosswordGrid.col := vCol - 1;
      FCrosswordGrid.row := vRow - 1;

      var vHasLeft   := (vCol > 1)         and (NOT FBlackSquare[vCol - 1, vRow]);
      var vHasRight  := (vCol < GRID_SIZE) and (NOT FBlackSquare[vCol + 1, vRow]);
      var vHasTop    := (vRow > 1)         and (NOT FBlackSquare[vCol, vRow - 1]);
      var vHasBottom := (vRow < GRID_SIZE) and (NOT FBlackSquare[vCol, vRow + 1]);

      case vHasRight and (NOT vHasLeft) of  TRUE: FGridDirection := gdAcross; end;
      case (NOT (vHasRight and (NOT vHasLeft))) and (vHasBottom and (NOT vHasTop)) of  TRUE: FGridDirection := gdDown; end;

      BREAK;
    end;
end;

function  TCrosswordGrid.readSavedGrid(const aFilename: string; const aIx: integer): void;
begin
  case fileExists(aFilename) of FALSE: EXIT; end;
  var vIx := aIx;

  var vStringList := TStringList.create;
  try
    vStringList.loadFromFile(aFilename);
    case vIx = -1 of TRUE: vIx := vStringList.count - 1; end;

    case (vIx >= 0) AND (vIx < vStringList.count) of TRUE: stringToGrid(vStringList[vIx]); end;
  finally
    vStringList.free;
  end;
end;

function  TCrosswordGrid.saveGridToFile(const aFilename: string): void;
begin
  var vStringList := TStringList.create;
  try
    case fileExists(aFilename) of TRUE: vStringList.loadFromFile(aFilename); end;
    vStringList.add(encodeGrid);
    vStringList.saveToFile(aFilename);
  finally
    vStringList.free;
  end;
  FDirty := FALSE;
end;

function TCrosswordGrid.setupGrid: boolean;
begin
  FSetupGrid  := NOT FSetupGrid;
  result      := FSetupGrid;
end;

function TCrosswordGrid.squareInActiveAcrossClue(const aCol, aRow: integer): boolean;
begin
  result := FALSE;
  case aRow <> gridRow of TRUE: EXIT; end;

  var vMinCol := aCol;
  var vMaxCol := gridCol;

  case gridCol < aCol of TRUE: begin
    vMinCol := gridCol;
    vMaxCol := aCol;
  end;end;

  for var vCol := vMinCol to vMaxCol do
    case FBlackSquare[vCol, aRow] of TRUE: EXIT; end;

  result := TRUE;
end;

function TCrosswordGrid.squareInActiveClue(const aCol: integer; const aRow: integer): boolean;
begin
  result := FALSE;
  case FBlackSquare[aCol, aRow]       of TRUE: EXIT; end;
  case FBlackSquare[gridCol, gridRow] of TRUE: EXIT; end;

  case FGridDirection of
    gdAcross: result := squareInActiveAcrossClue(aCol, aRow);
    gdDown:   result := squareInActiveDownClue(aCol, aRow);
  end;
end;

function TCrosswordGrid.squareInActiveDownClue(const aCol: integer; const aRow: integer): boolean;
begin
  result := FALSE;
  case aCol <> gridCol of TRUE: EXIT; end;

  var vMinRow := aRow;
  var vMaxRow := gridRow;

  case gridRow < aRow of TRUE: begin
    vMinRow := gridRow;
    vMaxRow := aRow;
  end;end;

  for var vRow := vMinRow to vMaxRow do
    case FBlackSquare[aCol, vRow] of TRUE: EXIT; end;

  result := TRUE;
end;

function  TCrosswordGrid.stringToGrid(const aLayout: string): void;
begin
  clearGrid;

  var vCol            := 1;
  var vRow            := 1;
  var vNumStr: string := EMPTY_STRING;

  var vLayout := aLayout;
  vLayout     := stripInfo(vLayout, CHAR_DOLLAR, FDate);
  vLayout     := stripInfo(vLayout, CHAR_HASH, FTitle);

  for var vIx := 1 to length(vLayout) do begin
    var vChar := vLayout[vIx];

    case vChar in CHAR_SET_A_TO_Z of TRUE: begin
      applyBlanks(vCol, vRow, vNumStr);
      FLetters[vCol, vRow] := vChar;
      inc(vCol);
      CONTINUE;
    end;end;

    case vChar in CHAR_SET_0_TO_9 of TRUE: begin
      vNumStr := vNumStr + vChar;
      CONTINUE;
    end;end;

    applyBlanks(vCol, vRow, vNumStr);

    case vChar = '.' of TRUE: begin
      FBlackSquare[vCol, vRow] := TRUE;
      inc(vCol);
      CONTINUE;
    end;end;

    case vChar = CHAR_SLASH of TRUE: begin
      vCol := 1;
      inc(vRow);
      CONTINUE;
    end;end;

    FBoldRight    [vCol - 1, vRow]  := FBoldRight     [vCol - 1, vRow] OR (vChar = CHAR_VERTICAL_BAR);
    FBoldBottom   [vCol - 1, vRow]  := FBoldBottom    [vCol - 1, vRow] OR (vChar = CHAR_UNDERSCORE);
    FHyphenRight  [vCol - 1, vRow]  := FHyphenRight   [vCol - 1, vRow] OR (vChar = CHAR_HYPHEN);
    FHyphenBottom [vCol - 1, vRow]  := FHyphenBottom  [vCol - 1, vRow] OR (vChar = CHAR_EQUALS);
  end;

  applyBlanks(vCol, vRow, vNumStr);
  calculateNumbers;
end;

function TCrosswordGrid.stripInfo(const aLayout: string; const aDelimiter: char; out oInfo: string): string;
begin
  result  := aLayout;
  oInfo := EMPTY_STRING;

  var vStartInt := pos(aDelimiter, result);
  case vStartInt = 0 of TRUE: EXIT;end;

  var vEndInt := pos(aDelimiter, result, vStartInt + 1);
  case vEndInt = 0 of TRUE: EXIT; end;

  oInfo := copy(result, vStartInt + 1, vEndInt - vStartInt - 1);
  delete(result, vStartInt, vEndInt - vStartInt + 1);
end;

function TCrosswordGrid.title(const aTitle: string = ''): string;
begin
  case aTitle = EMPTY_STRING of FALSE: FTitle := aTitle; end;
  result := FTitle;
end;

{ TCrosswordGrid }

function  TCrosswordGrid.advanceCursor(const aCol: integer; const aRow: integer): void;
begin
  var vMoved := FALSE;

  case FGridDirection of
    gdAcross: case (aCol < GRID_SIZE) and (NOT FBlackSquare[aCol + 1, aRow]) of
                TRUE: begin
                        advanceGridCol;
                        vMoved := TRUE;
                      end;
              end;
    gdDown:   case (aRow < GRID_SIZE) and (NOT FBlackSquare[aCol, aRow + 1]) of
                TRUE: begin
                        advanceGridRow;
                        vMoved := TRUE;
                      end;
              end;
  end;

  case vMoved and (FLetters[gridCol, gridRow] <> EMPTY_CHAR) of TRUE: advanceCursor(gridCol, gridRow); end;
end;

function TCrosswordGrid.advanceGridCol: void;
begin
  FCrosswordGrid.col := FCrosswordGrid.col + 1;
end;

function TCrosswordGrid.advanceGridRow: void;
begin
  FCrosswordGrid.row := FCrosswordGrid.row + 1;
end;

function  TCrosswordGrid.applyBlanks(var aCol: integer; const aRow: integer; var aNumStr: string): void;
begin
  case aNumStr = EMPTY_STRING of TRUE: EXIT; end;

  var vSpaceCount := strToInt(aNumStr);
  for var vC := 1 to vSpaceCount do begin
    FBlackSquare[aCol, aRow] := FALSE;
    inc(aCol);
  end;

  aNumStr := EMPTY_STRING;
end;

function  TCrosswordGrid.calculateNumbers: void;
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

function  TCrosswordGrid.clearSquare: void;
begin
  FLetters[gridCol, gridRow] := EMPTY_CHAR;
end;

function  TCrosswordGrid.encodeGrid: string;
begin
  result := '';
  for var vRow := 1 to GRID_SIZE do begin
    case result <> '' of TRUE: result := result + CHAR_SLASH; end;
    result := result + encodeRow(vRow);
  end;
  result := format('$%s$#%s#%s', [FDate, FTitle, result]);
end;

function  TCrosswordGrid.encodeRow(const aRow: integer): string;
begin
  result := '';
  var vEmptyCount := 0;

  for var vCol := 1 to GRID_SIZE do begin
    var vIsCellBlack := FBlackSquare  [vCol, aRow];
    var vHasLetter   := FLetters  [vCol, aRow] <> EMPTY_CHAR;
    var vHasModifier := FBoldRight[vCol, aRow] OR FBoldBottom[vCol, aRow] OR FHyphenRight[vCol, aRow] OR FHyphenBottom[vCol, aRow];

    case (NOT vIsCellBlack) AND (NOT vHasLetter) of TRUE: inc(vEmptyCount); end;

    case (vIsCellBlack OR vHasLetter) AND (vEmptyCount > 0) of TRUE: begin
      result := result + intToStr(vEmptyCount);
      vEmptyCount := 0;
    end;end;

    case vIsCellBlack of TRUE: result := result + CHAR_DOT; end;
    case vHasLetter AND (NOT vIsCellBlack) of TRUE: result := result + FLetters[vCol, aRow]; end;

    case vHasModifier AND (vEmptyCount > 0) of TRUE: begin
      result := result + intToStr(vEmptyCount);
      vEmptyCount := 0;
    end;end;

    case FBoldRight     [vCol, aRow]  of TRUE: result := result + CHAR_VERTICAL_BAR;  end;
    case FBoldBottom    [vCol, aRow]  of TRUE: result := result + CHAR_UNDERSCORE;    end;
    case FHyphenRight   [vCol, aRow]  of TRUE: result := result + CHAR_HYPHEN;        end;
    case FHyphenBottom  [vCol, aRow]  of TRUE: result := result + CHAR_EQUALS;        end;
  end;

  case vEmptyCount > 0 of TRUE: result := result + intToStr(vEmptyCount); end;
end;

function  TCrosswordGrid.needsNumber(const aCol: integer; const aRow: integer): boolean;
begin
  result := FALSE;
  case FBlackSquare[aCol, aRow] of TRUE: EXIT; end;

  var vHasLeft   := (aCol > 1)         and (NOT FBlackSquare[aCol - 1, aRow]);
  var vHasRight  := (aCol < GRID_SIZE) and (NOT FBlackSquare[aCol + 1, aRow]);
  var vHasTop    := (aRow > 1)         and (NOT FBlackSquare[aCol, aRow - 1]);
  var vHasBottom := (aRow < GRID_SIZE) and (NOT FBlackSquare[aCol, aRow + 1]);

  result := (vHasRight AND (NOT vHasLeft)) OR (vHasBottom AND (NOT vHasTop));
end;

function TCrosswordGrid.retreatCursor(const aCol: integer; const aRow: integer): void;
begin
  case FGridDirection of
    gdAcross: case (aCol > 1) and (NOT FBlackSquare[aCol - 1, aRow]) of TRUE: retreatGridCol; end;
    gdDown:   case (aRow > 1) and (NOT FBlackSquare[aCol, aRow - 1]) of TRUE: retreatGridRow; end;
  end;
end;

function TCrosswordGrid.retreatGridCol: void;
begin
  FCrosswordGrid.col := FCrosswordGrid.col - 1;
end;

function TCrosswordGrid.retreatGridRow: void;
begin
  FCrosswordGrid.row := FCrosswordGrid.row - 1;
end;

{ draw methods }

function  TCrosswordGrid.drawBackground(const aCanvas: TCanvas; const aCol: integer; const aRow: integer; const aRect: TRect): void;
begin
  var vSelected     := NOT FSetupGrid and (NOT FBlackSquare[aCol, aRow]) and (aCol = gridCol) and (aRow = gridRow);
  var vInActiveClue := NOT FSetupGrid and (NOT vSelected) and squareInActiveClue(aCol, aRow);

  case FBlackSquare[aCol, aRow]                                                   of TRUE: aCanvas.brush.color := clBlack;   end;
  case vSelected                                                                  of TRUE: aCanvas.brush.color := $00E2E2E2; end;
  case vInActiveClue                                                              of TRUE: aCanvas.brush.color := $00EFEFEF; end;
//  case vSelected                                                                  of TRUE: aCanvas.brush.color := clMedGray; end; // less subtle, for testing
//  case vInActiveClue                                                              of TRUE: aCanvas.brush.color := clDkGray;  end; // less subtle, for testing
  case (NOT FBlackSquare[aCol, aRow]) and (NOT vSelected) and (NOT vInActiveClue) of TRUE: aCanvas.brush.color := clWhite;   end;

  aCanvas.fillRect(aRect);
end;

function  TCrosswordGrid.drawBorders(const aCanvas: TCanvas; const aCol: integer; const aRow: integer; const aRect: TRect): void;
begin
  aCanvas.pen.color := clBlack;
  aCanvas.pen.width := 1;

  aCanvas.moveTo(aRect.left, aRect.top);
  aCanvas.lineTo(aRect.right, aRect.top);
  aCanvas.moveTo(aRect.left, aRect.top);
  aCanvas.lineTo(aRect.left, aRect.bottom);

  case (aCol = GRID_SIZE) or FBoldRight[aCol, aRow] of TRUE: begin
    aCanvas.moveTo(aRect.right - 1, aRect.top);
    aCanvas.lineTo(aRect.right - 1, aRect.bottom);
  end;end;

  case (aRow = GRID_SIZE) or FBoldBottom[aCol, aRow] of TRUE: begin
    aCanvas.moveTo(aRect.left, aRect.bottom - 1);
    aCanvas.lineTo(aRect.right, aRect.bottom - 1);
  end;end;
end;

function  TCrosswordGrid.drawContent(const aCanvas: TCanvas; const aCol: integer; const aRow: integer; const aRect: TRect): void;
begin
  case FBlackSquare[aCol, aRow] of TRUE: EXIT; end;

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

function  TCrosswordGrid.drawHyphens(const aCanvas: TCanvas; const aCol: integer; const aRow: integer; const aRect: TRect): void;
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

function TCrosswordGrid.gridCol: integer;
begin
  result := FCrosswordGrid.col + 1;
end;

function TCrosswordGrid.gridRow: integer;
begin
  result := FCrosswordGrid.row + 1;
end;

{ TDrawGrid event handlers }

procedure  TCrosswordGrid.gridDrawCell(sender: TObject; aCol: integer; aRow: integer; aRect: TRect; aState: TGridDrawState);
begin
  var vCol    := aCol + 1;
  var vRow    := aRow + 1;
  var vCanvas := FCrosswordGrid.canvas;

  drawBackground  (vCanvas, vCol, vRow, aRect);
  drawBorders     (vCanvas, vCol, vRow, aRect);
  drawHyphens     (vCanvas, vCol, vRow, aRect);
  drawContent     (vCanvas, vCol, vRow, aRect);
end;

procedure  TCrosswordGrid.gridKeyDown(sender: TObject; var aKey: word; aShift: TShiftState);
begin
  case aKey in [VK_RIGHT, VK_LEFT, VK_UP, VK_DOWN] of TRUE: begin
    var vTargetCol := gridCol;
    var vTargetRow := gridRow;

    case aKey of
      VK_RIGHT: for var vCol := gridCol + 1 to GRID_SIZE do case NOT FBlackSquare[vCol, gridRow] of TRUE: begin vTargetCol := vCol; BREAK; end; end;
      VK_LEFT:  for var vCol := gridCol - 1 downto 1     do case NOT FBlackSquare[vCol, gridRow] of TRUE: begin vTargetCol := vCol; BREAK; end; end;
      VK_DOWN:  for var vRow := gridRow + 1 to GRID_SIZE do case NOT FBlackSquare[gridCol, vRow] of TRUE: begin vTargetRow := vRow; BREAK; end; end;
      VK_UP:    for var vRow := gridRow - 1 downto 1     do case NOT FBlackSquare[gridCol, vRow] of TRUE: begin vTargetRow := vRow; BREAK; end; end;
    end;

    case (aKey = VK_RIGHT) or (aKey = VK_LEFT) of TRUE: FGridDirection := gdAcross; end;
    case (aKey = VK_DOWN)  or (aKey = VK_UP)   of TRUE: FGridDirection := gdDown;   end;

    FGridDirection     := checkGridDirection(vTargetCol, vTargetRow, FGridDirection);
    FCrosswordGrid.col := vTargetCol - 1;
    FCrosswordGrid.row := vTargetRow - 1;
    FCrosswordGrid.invalidate;

    aKey := 0;
  end;end;

  case aKey in [VK_DELETE, VK_SPACE] of TRUE: begin
    clearSquare;
    FCrosswordGrid.invalidate;
  end;end;
end;

procedure  TCrosswordGrid.gridKeyPress(sender: TObject; var aKey: char);
begin
  case handleDigit(aKey)      of TRUE: EXIT; end;
  case handleBackspace(aKey)  of TRUE: EXIT; end;

  case FBlackSquare[gridCol, gridRow] of TRUE: EXIT; end;

  case handleModifier(aKey)   of TRUE: EXIT; end;
  case handleLetter(aKey)     of TRUE: EXIT; end;
  case handleDot(aKey)        of TRUE: EXIT; end;
end;

procedure  TCrosswordGrid.gridMouseDown(sender: TObject; button: TMouseButton; shift: TShiftState; X: integer; Y: integer);
begin
  var vDrawCol := -1;
  var vDrawRow := -1;
  FCrosswordGrid.mouseToCell(X, Y, vDrawCol, vDrawRow);

  case (vDrawCol < 0) OR (vDrawRow < 0) of TRUE: EXIT; end;

  var vCol := vDrawCol + 1;
  var vRow := vDrawRow + 1;

  case FSetupGrid of FALSE: begin
                              var vGridDirection := checkGridDirection(vCol, vRow, FGridDirection);
                              case vGridDirection = FGridDirection of FALSE: FGridDirection := vGridDirection; end;
                              FCrosswordGrid.invalidate;
                              EXIT; end;end;


  case button = mbLeft of TRUE: FBlackSquare[vCol, vRow] := FALSE; end;

  case button = mbRight of TRUE: begin
    FBlackSquare  [vCol, vRow]  := TRUE;
    FLetters      [vCol, vRow]  := EMPTY_CHAR;
    FBoldRight    [vCol, vRow]  := FALSE;
    FBoldBottom   [vCol, vRow]  := FALSE;
    FHyphenRight  [vCol, vRow]  := FALSE;
    FHyphenBottom [vCol, vRow]  := FALSE;
  end;end;

  calculateNumbers;
  FDirty := TRUE;
  FCrosswordGrid.invalidate;
end;

function TCrosswordGrid.handleBackspace(var aKey: char): boolean;
begin
  result := aKey = CHAR_BACKSPACE;
  case result of FALSE: EXIT; end;

  FDirty                   := TRUE;
  FLetters[gridCol, gridRow] := EMPTY_CHAR;
  retreatCursor(gridCol, gridRow);
  FCrosswordGrid.invalidate;
  aKey                       := EMPTY_CHAR;
end;

function TCrosswordGrid.handleDigit(var aKey: char): boolean;
begin
  result := aKey in CHAR_SET_0_TO_9;
  case result of FALSE: EXIT; end;

  checkClueDigit(aKey);
  aKey := EMPTY_CHAR;
  var vGridDirection := checkGridDirection(gridCol, gridRow, FGridDirection);
  case vGridDirection = FGridDirection of FALSE: FGridDirection := vGridDirection; end;
  FCrosswordGrid.invalidate;
end;

function TCrosswordGrid.handleDot(var aKey: char): boolean;
begin
  result := aKey = CHAR_DOT;
  case result of FALSE: EXIT; end;

  case FGridDirection of
    gdAcross: FGridDirection := gdDown;
    gdDown:   FGridDirection := gdAcross;
  end;

  FCrosswordGrid.invalidate;
  aKey := EMPTY_CHAR;
end;

function TCrosswordGrid.handleLetter(var aKey: char): boolean;
begin
  aKey   := upCase(aKey);
  result := aKey in CHAR_SET_A_TO_Z;
  case result of FALSE: EXIT; end;

  FDirty  := TRUE;
  FLetters[gridCol, gridRow] := aKey;
  advanceCursor(gridCol, gridRow);
  FCrosswordGrid.invalidate;
  aKey    := EMPTY_CHAR;
end;

function TCrosswordGrid.handleModifier(var aKey: char): boolean;
begin
  result := aKey in CHAR_SET_MODIFIERS;
  case result of FALSE: EXIT; end;

  applyModifier(gridCol, gridRow, aKey);
  FDirty := TRUE;
  aKey     := EMPTY_CHAR;
end;

end.
