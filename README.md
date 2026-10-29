# crypticCrossword
Crossword Grid creator

<img width="585" height="608" alt="2026-10-28_011257 grid" src="https://github.com/user-attachments/assets/eee619b2-d2ad-477b-b378-99187821228b" />


**layout string**

The layout string describes the grid, row by row, similar to FEN chess notation
| character | purpose |
| ----- | ----- |
| dot . | is a black, non-square in the grid |
| digits 0..9 | indicate a number of consecutive letter squares |
| slash / | indicates the end of a row |
| vertical bar \| | the current across-clue square is to be followed by a bold vertical word-break |
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

Ctrl-Delete to toggle setup mode.

BACKSPACE to clear grid

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

**square modifiers at any time (not just in setup mode)**

| key | action |
| --- | --- |
| underscore _ | place a down clue word-break under the current square |
| vertical bar \| | place an across clue word-break at the current square |
| hyphen - | place an across clue hyphen to the next square |
| equals = | place a down clue hyphen to the next square |

**save the grid at any time**

Ctrl-S to save the grid to a text file in the same folder as the exe

Closing the app also saves the current grid


  
