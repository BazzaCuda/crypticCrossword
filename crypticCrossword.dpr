program crypticCrossword;

uses
  system.sysUtils,
  vcl.forms,
  mainUnit in 'mainUnit.pas' {MainForm},
  TCrosswordGridClass in 'TCrosswordGridClass.pas';

{$R *.res}

begin
  application.initialize;
  application.mainFormOnTaskbar := TRUE;
  Application.CreateForm(TmainForm, mainForm);
  mainForm.mainGrid.setupGrid('15/1.1.1.1.1.1.1.1/15/1.1.1.1.1.1.1.1/7.7/1.1.1.1.1.1.1.1/15/.1.1.1.1.1.1./15/1.1.1.1.1.1.1.1/7.7/1.1.1.1.1.1.1.1/15/1.1.1.1.1.1.1.1/15');
  mainForm.mainGrid.setupGrid('5.9/1.1.1.1.1.1.1.1/9.5/1...1.1_.1.1.1_.1/13../1.1.1.1...1.1.1/4.2-2|2|4/1.1.1.1.1.1.1.1/10.4/1.1.1...1.1.1.1=/..13/1.1.1.1.1.1...1/5.9/1.1.1.1.1.1.1.1/9.5');

  mainForm.mainGrid.arrayGrid([
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

  mainForm.mainGrid.arrayGrid([
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

  mainForm.mainGrid.addModifierByClue(15, cdAcross, 4, gmHorzWordBreak);
  mainForm.mainGrid.addModifierByClue(15, cdAcross, 6, gmHorzWordBreak);
  mainForm.mainGrid.addModifierByClue(27, cdAcross, 4, gmHorzWordBreak);
  mainForm.mainGrid.addModifierByClue(3, cdDown, 1, gmVertWordBreak);
  mainForm.mainGrid.addModifierByClue(4, cdAcross, 4, gmHorzHyphen);
  mainForm.mainGrid.addModifierByClue(4, cdDown, 4, gmVertHyphen);

  mainForm.mainGrid.setupGrid('5_.4-5/1.1.1.1.1.1.1.1/9.5/1...1.1=.1.1.1.1/BUTTERFINGERS../1.1.1.1...1.1.1/4.4|2|4/1.1.1.1.1.1.1.1/10.4/1.1.1...1.1.1.1/..13/1.1.1.1.1.1...1/5.9/1.1.1.1.1.1.1.1/4|5.5');

  mainForm.mainGrid.clearGrid;

  mainForm.mainGrid.readSavedGrid(extractFilePath(paramStr(0)) + 'crypticCrossword.txt', -1);

//  mainForm.clearGrid;

  application.run;
end.
