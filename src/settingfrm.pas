{
  Description: XY-Plot setting form.

  Copyright (C) 2020 Melchiorre Caruso <melchiorrecaruso@gmail.com>

  This source is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License as published by the Free
  Software Foundation; either version 2 of the License, or (at your option)
  any later version.

  This code is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
  details.

  A copy of the GNU General Public License is available on the World Wide Web
  at <http://www.gnu.org/copyleft/gpl.html>. You can also obtain it by writing
  to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
  MA 02111-1307, USA.
}

unit settingfrm;

{$mode objfpc}

interface

uses
  classes, sysutils, forms, controls, graphics,
  dialogs, valedit, extctrls, buttons, xypsetting;

type

  { tsettingform }

  tsettingform = class(tform)
    btnok: tbitbtn;
    closebtn: tbitbtn;
    image: timage;
    settinglist: tvaluelisteditor;
  private
  public
    procedure load(asetting: txypsetting);
    procedure save(asetting: txypsetting);
  end;

var
  settingform: tsettingform;

implementation

{$R *.lfm}

{ tsettingform }

procedure tsettingform.load(asetting: txypsetting);
begin
  settinglist.strings.clear;
  settinglist.titlecaptions.clear;
  settinglist.titlecaptions.add('KEY');
  settinglist.titlecaptions.add('VALUE');

  settinglist.insertrow('X.OFFSET', floattostr(asetting.xoffset), true);
  settinglist.insertrow('X.FACTOR', floattostr(asetting.xfactor), true);
  settinglist.insertrow('Y.OFFSET', floattostr(asetting.yoffset), true);
  settinglist.insertrow('Y.FACTOR', floattostr(asetting.yfactor), true);

  settinglist.insertrow('PULLEY-X.RATIO', floattostr(asetting.pxratio), true);
  settinglist.insertrow('PULLEY-X.DIR',   inttostr  (asetting.pxdir),   true);
  settinglist.insertrow('PULLEY-Y.RATIO', floattostr(asetting.pyratio), true);
  settinglist.insertrow('PULLEY-Y.DIR',   inttostr  (asetting.pydir),   true);
  settinglist.insertrow('SERVO-Z.VALUE-0', floattostr(asetting.servozvalue0), true);
  settinglist.insertrow('SERVO-Z.VALUE-1', floattostr(asetting.servozvalue1), true);
  settinglist.insertrow('SERVO-Z.DIR',     inttostr  (asetting.servozdir),    true);

  settinglist.insertrow('PAGE.HEIGHT', floattostr(asetting.pageheight), true);
  settinglist.insertrow('PAGE.WIDTH',  floattostr(asetting.pagewidth),  true);
  settinglist.insertrow('PAGE.DIR',    inttostr  (asetting.pagedir),    true);

  settinglist.insertrow('RAMP.KB', floattostr(asetting.rampkb), true);
  settinglist.insertrow('RAMP.KI', floattostr(asetting.rampki), true);
  settinglist.insertrow('RAMP.KL', floattostr(asetting.rampkl), true);
  settinglist.toprow := 1;
end;

procedure tsettingform.save(asetting: txypsetting);
begin
  asetting.xoffset := strtofloat(settinglist.values['X.OFFSET']);
  asetting.xfactor := strtofloat(settinglist.values['X.FACTOR']);
  asetting.yoffset := strtofloat(settinglist.values['Y.OFFSET']);
  asetting.yfactor := strtofloat(settinglist.values['Y.FACTOR']);

  asetting.pxratio := strtofloat(settinglist.values['PULLEY-X.RATIO']);
  asetting.pxdir   := strtoint  (settinglist.values['PULLEY-X.DIR']);

  asetting.pyratio := strtofloat(settinglist.values['PULLEY-Y.RATIO']);
  asetting.pydir   := strtoint  (settinglist.values['PULLEY-Y.DIR']);

  asetting.servozvalue0 := strtoint(settinglist.values['SERVO-Z.VALUE-0']);
  asetting.servozvalue1 := strtoint(settinglist.values['SERVO-Z.VALUE-1']);
  asetting.servozdir    := strtoint(settinglist.values['SERVO-Z.DIR']);

  asetting.pageheight := strtofloat(settinglist.values['PAGE.HEIGHT']);
  asetting.pagewidth  := strtofloat(settinglist.values['PAGE.WIDTH']);
  asetting.pagedir    := strtoint  (settinglist.values['PAGE.DIR']);

  asetting.rampkb := strtoint(settinglist.values['RAMP.KB']);
  asetting.rampki := strtoint(settinglist.values['RAMP.KI']);
  asetting.rampkl := strtoint(settinglist.values['RAMP.KL']);
end;

end.

