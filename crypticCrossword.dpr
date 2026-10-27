// crypticCrossword.dpr
program crypticCrossword;

uses
  vcl.forms,
  mainUnit in 'mainUnit.pas' {MainForm};

{$R *.res}

begin
  application.initialize;
  application.mainFormOnTaskbar := TRUE;
  application.createForm(TMainForm, mainForm);
//  mainForm.setupGrid('15/1B1B1B1B1B1B1B1/15/1B1B1B1B1B1B1B1/7B7/1B1B1B1B1B1B1B1/15/B1B1B1B1B1B1B/15/1B1B1B1B1B1B1B1/7B7/1B1B1B1B1B1B1B1/15/1B1B1B1B1B1B1B1/15');
//  mainForm.setupGrid('5B9/1B1B1B1B1B1B1B1/9B5/1BBB1B1_B1B1B1_B1/13BB/1B1B1B1BBB1B1B1/4B2-2|2|4/1B1B1B1B1B1B1B1/10B4/1B1B1BBB1B1B1B1=/BB13/1B1B1B1B1B1BBB1/5B9/1B1B1B1B1B1B1B1/9B5');

//  mainForm.arrayGrid([
//    '5B9',
//    '1B1B1B1B1B1B1B1',
//    '9B5',
//    '1BBB1B1_B1B1B1_B1',
//    '13BB',
//    '1B1B1B1BBB1B1B1',
//    '4B2-2|2|4',
//    '1B1B1B1B1B1B1B1',
//    '10B4',
//    '1B1B1BBB1B1B1B1=',
//    'BB13',
//    '1B1B1B1B1B1BBB1',
//    '5B9',
//    '1B1B1B1B1B1B1B1',
//    '9B5'
//  ]);

  mainForm.arrayGrid([
    '5B9',
    '1B1B1B1B1B1B1B1',
    '9B5',
    '1BBB1B1B1B1B1B1',
    '13BB',
    '1B1B1B1BBB1B1B1',
    '4B10',
    '1B1B1B1B1B1B1B1',
    '10B4',
    '1B1B1BBB1B1B1B1',
    'BB13',
    '1B1B1B1B1B1BBB1',
    '5B9',
    '1B1B1B1B1B1B1B1',
    '9B5'
  ]);

  mainForm.addModifierByClue(15, cdAcross, 4, gmHorzWordBreak);
  mainForm.addModifierByClue(15, cdAcross, 6, gmHorzWordBreak);
  mainForm.addModifierByClue(27, cdAcross, 4, gmHorzWordBreak);
  mainForm.addModifierByClue(3, cdDown, 1, gmVertWordBreak);
  mainForm.addModifierByClue(4, cdAcross, 4, gmHorzHyphen);
  mainForm.addModifierByClue(4, cdDown, 4, gmVertHyphen);

  application.run;
end.
