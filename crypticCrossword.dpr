program crypticCrossword;

uses
  system.sysUtils,
  vcl.forms,
  mainUnit in 'mainUnit.pas' {MainForm};

{$R *.res}

begin
  application.initialize;
  application.mainFormOnTaskbar := TRUE;
  application.createForm(TMainForm, mainForm);
//  mainForm.setupGrid('15/1.1.1.1.1.1.1.1/15/1.1.1.1.1.1.1.1/7.7/1.1.1.1.1.1.1.1/15/.1.1.1.1.1.1./15/1.1.1.1.1.1.1.1/7.7/1.1.1.1.1.1.1.1/15/1.1.1.1.1.1.1.1/15');
//  mainForm.setupGrid('5.9/1.1.1.1.1.1.1.1/9.5/1...1.1_.1.1.1_.1/13../1.1.1.1...1.1.1/4.2-2|2|4/1.1.1.1.1.1.1.1/10.4/1.1.1...1.1.1.1=/..13/1.1.1.1.1.1...1/5.9/1.1.1.1.1.1.1.1/9.5');

//  mainForm.arrayGrid([
//    '5.9',
//    '1.1.1.1.1.1.1.1',
//    '9.5',
//    '1...1.1_.1.1.1_.1',
//    '13..',
//    '1.1.1.1...1.1.1',
//    '4.2-2|2|4',
//    '1.1.1.1.1.1.1.1',
//    '10.4',
//    '1.1.1...1.1.1.1=',
//    '..13',
//    '1.1.1.1.1.1...1',
//    '5.9',
//    '1.1.1.1.1.1.1.1',
//    '9.5'
//  ]);

  mainForm.arrayGrid([
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

  mainForm.addModifierByClue(15, cdAcross, 4, gmHorzWordBreak);
  mainForm.addModifierByClue(15, cdAcross, 6, gmHorzWordBreak);
  mainForm.addModifierByClue(27, cdAcross, 4, gmHorzWordBreak);
  mainForm.addModifierByClue(3, cdDown, 1, gmVertWordBreak);
  mainForm.addModifierByClue(4, cdAcross, 4, gmHorzHyphen);
  mainForm.addModifierByClue(4, cdDown, 4, gmVertHyphen);

  mainForm.setupGrid('5_.4-5/1.1.1.1.1.1.1.1/9.5/1...1.1=.1.1.1.1/BUTTERFINGERS../1.1.1.1...1.1.1/4.4|2|4/1.1.1.1.1.1.1.1/10.4/1.1.1...1.1.1.1/..13/1.1.1.1.1.1...1/5.9/1.1.1.1.1.1.1.1/4|5.5');

  mainForm.readSavedGrid(extractFilePath(paramStr(0)) + 'crypticCrossword.txt', 0);

  application.run;
end.
