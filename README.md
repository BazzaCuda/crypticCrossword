# crypticCrossword
Crossword Grid creator

- TCrosswordGridClass is, in effect, a reusable component
- the accompanying project is, in effect, a demo of the class in use

<img width="567" height="595" alt="image" src="https://github.com/user-attachments/assets/8e69fe1c-c6c7-4191-a682-e3910c10e6bf" />



**layout string**

The layout string describes the grid, row by row, similar to FEN chess notation

see the .dpr file and `crypticCrossword.txt` for examples

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

| key | action |
| --- | --- |
| Ctrl-Delete | toggle setup mode |
| Ctrl-Backspace | clear grid completely - all squares will be white |
| left-click | set the square to an empty letter square |
| right-click | set the square to a black non-letter square |

N.B. across and down clue numbers are assigned automatically as you amend the grid

**entering letters**

| key | action |
| --- | --- |
| A - Z | entered in the grid |
| Delete | empty the square but stay put |
| Backspace | empty the square and reverse the cursor one square |
| arrow keys | move cursor - will jump over black squares |
| digits | position to first letter of a clue number. Allows for the difference between clue 24 and clues 2 and 4 |
| dot . | toggle the across/down grid direction at a clue intersection to highlight the required clue |

N.B. When typing letters into the grid, the cursor will skip over squares that already contain a letter

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
| vertical bar \| | place an across clue word-break at the current square |
| underscore _ | place a down clue word-break under the current square |
| hyphen - | place an across clue hyphen to the next square |
| equals = | place a down clue hyphen to the next square |

**save the grid at any time**

| key | action |
| --- | --- |
| Ctrl-S | add the grid to the `crypticCrossword.txt` file in the same folder as the exe |

Closing the app also saves the current grid if it has been changed


  
