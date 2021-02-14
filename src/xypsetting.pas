{
  Description: XY-Plot setting class.

  Copyright (C) 2021 Melchiorre Caruso <melchiorrecaruso@gmail.com>

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
  inifiles, sysutils, xypmath, xyputils;

type
  txypsetting = class
  private
    forigin: txyppoint;
    fxoffset: double;
    fyoffset: double;
    fxfactor: double;
    fyfactor: double;
    fpageheight: double;
    fpagewidth: double;
    fpagelandscape: longint;
    // pulley-x/y/z
    fpxratio: double;
    fpyratio: double;
    fpzratio: double;
    // ramps
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
    property pyratio: double read fpyratio write fpyratio;
    property pzratio: double read fpzratio write fpzratio;

    property rampkl: longint read frampkl write frampkl;

    property pageheight: double read fpageheight write fpageheight;
    property pagewidth:  double read fpagewidth  write fpagewidth;
    property pagelangscape: longint read fpagelandscape write fpagelandscape;
 end;


function getclientsettingfilename(global: boolean): string;
function getsettingfilename(global: boolean): string;


var
  setting: txypsetting;

implementation

function getclientsettingfilename(global: boolean): string;
begin
  forcedirectories(getappconfigdir(global));
  begin
    result := includetrailingbackslash(getappconfigdir(global)) + 'xyplot.client';
  end;
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
    save(filename);
  end;

  if fileexists(filename) then
  begin
    ini := tinifile.create(filename);
    ini.formatsettings.decimalseparator := '.';
    ini.options := [ifoformatsettingsactive];

    fxoffset := ini.readfloat('LAYOUT', 'X.OFFSET', 0);
    fyoffset := ini.readfloat('LAYOUT', 'Y.OFFSET', 0);
    fxfactor := ini.readfloat('LAYOUT', 'X.FACTOR', 0);
    fyfactor := ini.readfloat('LAYOUT', 'Y.FACTOR', 0);

    fpxratio := ini.readfloat  ('X-AXIS', 'RATIO', 0);
    fpyratio := ini.readfloat  ('Y-AXIS', 'RATIO', 0);
    fpzratio := ini.readfloat  ('Z-AXIS', 'RATIO', 0);

    fpageheight    := ini.readfloat  ('PAGE', 'HEIGHT',    0);
    fpagewidth     := ini.readfloat  ('PAGE', 'WIDTH',     0);
    fpagelandscape := ini.readinteger('PAGE', 'LANDSCAPE', 0);

    frampkl := ini.readinteger('RAMP','KL', 0);

    {$ifopt D+}
    printdbg('SETTING', format('X.OFFSET         %12.5f', [fxoffset]));
    printdbg('SETTING', format('Y.OFFSET         %12.5f', [fyoffset]));
    printdbg('SETTING', format('X.FACTOR         %12.5f', [fxfactor]));
    printdbg('SETTING', format('Y.FACTOR         %12.5f', [fyfactor]));

    printdbg('SETTING', format('X.RATIO          %12.5f', [fpxratio]));
    printdbg('SETTING', format('Y.RATIO          %12.5f', [fpyratio]));
    printdbg('SETTING', format('Z.RATIO          %12.5f', [fpzratio]));

    printdbg('SETTING', format('PAGE.MAXHEIGHT   %12.5f', [fpageheight]));
    printdbg('SETTING', format('PAGE.MAXWIDTH    %12.5f', [fpagewidth ]));
    printdbg('SETTING', format('PAGE.LANDSCAPE   %12.5d', [fpagelandscape]));

    printdbg('SETTING', format('RAMP.KL          %12.5u', [frampkl]));
    {$endif}

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
  ini.writefloat  ('Y-AXIS', 'RATIO', fpyratio);
  ini.writefloat  ('Z-AXIS', 'RATIO', fpzratio);

  ini.writefloat  ('PAGE', 'HEIGHT', fpageheight);
  ini.writefloat  ('PAGE', 'WIDTH', fpagewidth);
  ini.writeinteger('PAGE', 'LANDSCAPE', fpagelandscape);

  ini.writeinteger('RAMP','KL', frampkl);
  ini.destroy;
end;

end.

