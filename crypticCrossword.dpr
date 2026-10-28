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
program crypticCrossword;

uses
  system.sysUtils,
  vcl.forms,
  mainUnit in 'mainUnit.pas' {MainForm},
  TCrosswordGridClass in 'TCrosswordGridClass.pas',
  _debugWindow in '_debugWindow\_debugWindow.pas';

{$R *.res}

begin
  application.initialize;
  application.mainFormOnTaskbar := TRUE;
  Application.CreateForm(TmainForm, mainForm);

  { example uses }
  mainForm.mainGrid.stringToGrid('15/1.1.1.1.1.1.1.1/15/1.1.1.1.1.1.1.1/7.7/1.1.1.1.1.1.1.1/15/.1.1.1.1.1.1./15/1.1.1.1.1.1.1.1/7.7/1.1.1.1.1.1.1.1/15/1.1.1.1.1.1.1.1/15');
  mainForm.mainGrid.stringToGrid('5.9/1.1.1.1.1.1.1.1/9.5/1...1.1_.1.1.1_.1/13../1.1.1.1...1.1.1/4.2-2|2|4/1.1.1.1.1.1.1.1/10.4/1.1.1...1.1.1.1=/..13/1.1.1.1.1.1...1/5.9/1.1.1.1.1.1.1.1/9.5');

  mainForm.mainGrid.arrayToGrid([
    '5.9',
    '1.1.1.1.1.1.1.1',
    '9.5',
    '1...1.1_.1.1.1_.1',
    '13..',
    '1.1.1.1...1.1.1',
    '4.2-2|2|4',
    '1.1.1.1.1.1.1.1',
    '10.4',
    '1.1.1...1.1.1.1=',
    '..13',
    '1.1.1.1.1.1...1',
    '5.9',
    '1.1.1.1.1.1.1.1',
    '9.5'
  ]);

  mainForm.mainGrid.arrayToGrid([
    '5.9',
    '1.1.1.1.1.1.1.1',
    '9.5',
    '1...1.1.1.1.1.1',
    '13..',
    '1.1.1.1...1.1.1',
    '4.10',
    '1.1.1.1.1.1.1.1',
    '10.4',
    '1.1.1...1.1.1.1',
    '..13',
    '1.1.1.1.1.1...1',
    '5.9',
    '1.1.1.1.1.1.1.1',
    '9.5'
  ]);

  mainForm.mainGrid.addModifierByClue(15, cdAcross, 4, gmAcrossWordBreak);
  mainForm.mainGrid.addModifierByClue(15, cdAcross, 6, gmAcrossWordBreak);
  mainForm.mainGrid.addModifierByClue(27, cdAcross, 4, gmAcrossWordBreak);
  mainForm.mainGrid.addModifierByClue( 3, cdDown,   1, gmDownWordBreak);
  mainForm.mainGrid.addModifierByClue( 4, cdAcross, 4, gmAcrossHyphen);
  mainForm.mainGrid.addModifierByClue( 4, cdDown,   4, gmDownHyphen);

  mainForm.mainGrid.stringToGrid('5_.4-5/1.1.1.1.1.1.1.1/9.5/1...1.1=.1.1.1.1/BUTTERFINGERS../1.1.1.1...1.1.1/4.4|2|4/1.1.1.1.1.1.1.1/10.4/1.1.1...1.1.1.1/..13/1.1.1.1.1.1...1/5.9/1.1.1.1.1.1.1.1/4|5.5');

  mainForm.mainGrid.clearGrid;

  mainForm.mainGrid.readSavedGrid(extractFilePath(paramStr(0)) + 'crypticCrossword.txt', -1);

  // case mainForm.mainGrid.setupGrid of TRUE: mainForm.mainGrid.clearGrid; end;

  application.run;
end.
