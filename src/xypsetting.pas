{
  Description: XY-Plot setting class.

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

unit xypsetting;

{$mode objfpc}

interface

uses
  dialogs, inifiles, sysutils, xypdebug, xypmath;

type
  txypsetting = class
  private
    forigin: txyppoint;
    fxoffset: double;
    fyoffset: double;
    fxfactor: double;
    fyfactor: double;
    fpageheight: double;
    fpagewidth:  double;
    fpagedir: longint;
    // pulley-x/y/z
    fpxratio: double;
    fpxdir: longint;
    fpyratio: double;
    fpydir: longint;
    fpzratio: double;
    fpzdir: longint;
    // ramps
    frampkb: longint;
    frampki: longint;
    frampkl: longint;
 public
    constructor create;
    destructor destroy; override;
    procedure load(const filename: string);
    procedure save(const filename: string);
 public
    property origin: txyppoint read forigin  write forigin;
    property xfactor: double read fxfactor write fxfactor;
    property yfactor: double read fyfactor write fyfactor;
    property xoffset: double read fxoffset write fxoffset;
    property yoffset: double read fyoffset write fyoffset;

    property pxratio: double read fpxratio write fpxratio;
    property pxdir: longint read fpxdir write fpxdir;
    property pyratio: double read fpyratio write fpyratio;
    property pydir: longint read fpydir write fpydir;
    property pzratio: double read fpzratio write fpzratio;
    property pzdir: longint read fpzdir write fpzdir;

    property rampkb: longint read frampkb write frampkb;
    property rampki: longint read frampki write frampki;
    property rampkl: longint read frampkl write frampkl;

    property pageheight: double read fpageheight write fpageheight;
    property pagewidth:  double read fpagewidth  write fpagewidth;
    property pagedir:   longint read fpagedir    write fpagedir;
 end;


function getclientsettingfilename(global: boolean): string;
function getsettingfilename(global: boolean): string;


implementation

function getclientsettingfilename(global: boolean): string;
begin
  result := includetrailingbackslash(getappconfigdir(global)) + 'xyplot.client';
end;

function getsettingfilename(global: boolean): string;
begin
  result := includetrailingbackslash(getappconfigdir(false)) + 'xyplot.ini';

  if global and (not fileexists(result)) then
  begin
    {$IFDEF MSWINDOWS}
    result := extractfilepath(paramstr(0)) + 'xyplot.ini';
    {$ELSE}
    {$IFDEF UNIX}
    result := '/opt/xyplot/xyplot.ini';
    {$ELSE}
    result := '';
    {$ENDIF}
    {$ENDIF}
  end;
end;

// txypsetting

constructor txypsetting.create;
begin
  inherited create;
end;

destructor txypsetting.destroy;
begin
  inherited destroy;
end;

procedure txypsetting.load(const filename: string);
var
  ini: tinifile;
begin
  if fileexists(filename) = false then
  begin
    messagedlg('XY-Plot Client', 'Setting file not found !', mterror, [mbok], 0);
  end else
  begin
    ini := tinifile.create(filename);
    ini.formatsettings.decimalseparator := '.';
    ini.options := [ifoformatsettingsactive];

    fxoffset := ini.readfloat('LAYOUT', 'X.OFFSET', 0);
    fyoffset := ini.readfloat('LAYOUT', 'Y.OFFSET', 0);
    fxfactor := ini.readfloat('LAYOUT', 'X.FACTOR', 0);
    fyfactor := ini.readfloat('LAYOUT', 'Y.FACTOR', 0);

    fpxratio      := ini.readfloat  ('X-AXIS', 'RATIO', 0);
    fpxdir        := ini.readinteger('X-AXIS', 'DIR',   1);
    fpyratio      := ini.readfloat  ('Y-AXIS', 'RATIO', 0);
    fpydir        := ini.readinteger('Y-AXIS', 'DIR',   1);
    fpzratio      := ini.readfloat  ('Z-AXIS', 'RATIO', 0);
    fpzdir        := ini.readinteger('Z-AXIS', 'DIR',   1);

    fpageheight := ini.readfloat  ('PAGE', 'HEIGHT', 0);
    fpagewidth  := ini.readfloat  ('PAGE', 'WIDTH',  0);
    fpagedir    := ini.readinteger('PAGE', 'DIR',    0);

    frampkb := ini.readinteger('RAMP','KB', 0);
    frampki := ini.readinteger('RAMP','KI', 0);
    frampkl := ini.readinteger('RAMP','KL', 0);

    xyplog.add(format('   SETTING::X.OFFSET         %12.5f', [fxoffset]));
    xyplog.add(format('   SETTING::Y.OFFSET         %12.5f', [fyoffset]));
    xyplog.add(format('   SETTING::X.FACTOR         %12.5f', [fxfactor]));
    xyplog.add(format('   SETTING::Y.FACTOR         %12.5f', [fyfactor]));

    xyplog.add(format('   SETTING::X.RATIO          %12.5f', [fpxratio]));
    xyplog.add(format('   SETTING::X.DIR            %12.5d', [fpxdir]));
    xyplog.add(format('   SETTING::Y.RATIO          %12.5f', [fpyratio]));
    xyplog.add(format('   SETTING::Y.DIR            %12.5d', [fpydir]));
    xyplog.add(format('   SETTING::Z.RATIO          %12.5f', [fpzratio]));
    xyplog.add(format('   SETTING::Z.DIR            %12.5d', [fpzdir]));

    xyplog.add(format('   SETTING::PAGE.MAXHEIGHT   %12.5f', [fpageheight]));
    xyplog.add(format('   SETTING::PAGE.MAXWIDTH    %12.5f', [fpagewidth]));
    xyplog.add(format('   SETTING::PAGE.DIR         %12.5d', [fpagedir]));

    xyplog.add(format('   SETTING::RAMP.KB          %12.5u', [frampkb]));
    xyplog.add(format('   SETTING::RAMP.KI          %12.5u', [frampki]));
    xyplog.add(format('   SETTING::RAMP.KL          %12.5u', [frampkl]));
    ini.destroy;
  end;
  forigin.x := 0;
  forigin.y := 0;
end;

procedure txypsetting.save(const filename: string);
var
  ini: tinifile;
begin
  ini := tinifile.create(filename);
  ini.formatsettings.decimalseparator := '.';
  ini.options := [ifoformatsettingsactive];

  ini.writefloat('LAYOUT', 'X.OFFSET', fxoffset);
  ini.writefloat('LAYOUT', 'Y.OFFSET', fyoffset);
  ini.writefloat('LAYOUT', 'X.FACTOR', fxfactor);
  ini.writefloat('LAYOUT', 'Y.FACTOR', fyfactor);

  ini.writefloat  ('X-AXIS', 'RATIO', fpxratio);
  ini.writeinteger('X-AXIS', 'DIR',   fpxdir);
  ini.writefloat  ('Y-AXIS', 'RATIO', fpyratio);
  ini.writeinteger('Y-AXIS', 'DIR',   fpydir);
  ini.writefloat  ('Z-AXIS', 'RATIO', fpzratio);
  ini.writeinteger('Z-AXIS', 'DIR',   fpzdir);

  ini.writefloat  ('PAGE', 'HEIGHT', fpageheight);
  ini.writefloat  ('PAGE', 'WIDTH',  fpagewidth);
  ini.writeinteger('PAGE', 'DIR',    fpagedir);

  ini.writeinteger('RAMP','KB', frampkb);
  ini.writeinteger('RAMP','KI', frampki);
  ini.writeinteger('RAMP','KL', frampkl);
  ini.destroy;
end;

end.

