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
  inifiles, sysutils, xyputils;

type
  txypsetting = class
  private
    // page
    fpageheight: double;
    fpagewidth: double;
    // pulley-x/y/z
    fpxratio: double;
    fpyratio: double;
    fpzratio: double;
    fpxdir: longint;
    fpydir: longint;
    fpzdir: longint;
    fpzdown: double;
    fpzup: double;
    // ramps
    frampkl: longint;
 public
    constructor create;
    destructor destroy; override;
    procedure load(const filename: string);
    procedure save(const filename: string);
 public
    property pxratio: double read fpxratio write fpxratio;
    property pyratio: double read fpyratio write fpyratio;
    property pzratio: double read fpzratio write fpzratio;
    property pxdir: longint read fpxdir write fpxdir;
    property pydir: longint read fpydir write fpydir;
    property pzdir: longint read fpzdir write fpzdir;
    property pzdown: double read fpzdown write fpzdown;
    property pzup: double read fpzup write fpzup;

    property rampkl: longint read frampkl write frampkl;

    property pageheight: double read fpageheight write fpageheight;
    property pagewidth:  double read fpagewidth  write fpagewidth;
 end;


function getclientsettingfilename(global: boolean): string;
function getsettingfilename(global: boolean): string;

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
  forcedirectories(getappconfigdir(global));
  begin
    result := includetrailingbackslash(getappconfigdir(false)) + 'xyplot.server';
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

    fpageheight := ini.readfloat  ('PAGE', 'HEIGHT',  0);
    fpagewidth  := ini.readfloat  ('PAGE', 'WIDTH',   0);

    fpxratio    := ini.readfloat  ('X-AXIS', 'RATIO', 0);
    fpyratio    := ini.readfloat  ('Y-AXIS', 'RATIO', 0);
    fpzratio    := ini.readfloat  ('Z-AXIS', 'RATIO', 0);
    fpxdir      := ini.readinteger('X-AXIS', 'DIR',   0);
    fpydir      := ini.readinteger('Y-AXIS', 'DIR',   0);
    fpzdir      := ini.readinteger('Z-AXIS', 'DIR',   0);
    fpzdown     := ini.readfloat  ('Z-AXIS', 'DOWN',  0);
    fpzup       := ini.readfloat  ('Z-AXIS', 'UP',    0);

    frampkl     := ini.readinteger('RAMP',  'KL',     0);
    {$ifopt D+}
    printdbg('SETTING', format('PAGE.MAXHEIGHT   %12.5f mm', [fpageheight]));
    printdbg('SETTING', format('PAGE.MAXWIDTH    %12.5f mm', [fpagewidth ]));

    printdbg('SETTING', format('X.RATIO          %12.5f mm/step', [fpxratio]));
    printdbg('SETTING', format('Y.RATIO          %12.5f mm/step', [fpyratio]));
    printdbg('SETTING', format('Z.RATIO          %12.5f mm/step', [fpzratio]));
    printdbg('SETTING', format('X.DIR            %12.5d ', [fpxdir]));
    printdbg('SETTING', format('Y.DIR            %12.5d ', [fpydir]));
    printdbg('SETTING', format('Z.DIR            %12.5d ', [fpzdir]));
    printdbg('SETTING', format('Z.DOWN           %12.5f mm', [fpzdown]));
    printdbg('SETTING', format('Z.UP             %12.5f mm', [fpzup]));

    printdbg('SETTING', format('RAMP.KL          %12.5u', [frampkl]));
    {$endif}
    ini.destroy;
  end;
end;

procedure txypsetting.save(const filename: string);
var
  ini: tinifile;
begin
  ini := tinifile.create(filename);
  ini.formatsettings.decimalseparator := '.';
  ini.options := [ifoformatsettingsactive];

  ini.writefloat  ('PAGE', 'HEIGHT',  fpageheight);
  ini.writefloat  ('PAGE', 'WIDTH',   fpagewidth);

  ini.writefloat  ('X-AXIS', 'RATIO', fpxratio);
  ini.writefloat  ('Y-AXIS', 'RATIO', fpyratio);
  ini.writefloat  ('Z-AXIS', 'RATIO', fpzratio);
  ini.writeinteger('X-AXIS', 'DIR',   fpxdir);
  ini.writeinteger('Y-AXIS', 'DIR',   fpydir);
  ini.writeinteger('Z-AXIS', 'DIR',   fpzdir);
  ini.writefloat  ('Z-AXIS', 'DOWN',  fpzdown);
  ini.writefloat  ('Z-AXIS', 'UP',    fpzup);

  ini.writeinteger('RAMP', 'KL',      frampkl);
  ini.destroy;
end;

end.

