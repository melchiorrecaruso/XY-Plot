{
  Description: XY-Plot serial class.

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

unit xypserial;

{$mode objfpc}

interface

uses
  classes, dateutils, lnet, lnetcomponents, serial, sysutils,
  {$IFDEF UNIX} baseunix, unix, {$ENDIF}
  {$IFDEF MSWINDOWS} registry, windows, {$ENDIF} xyputils;

type

  txypserialstream = class
  private
    fbaudrate: longint;
    fbits: longint;
    fflags: tserialflags;
    fhandle: longint;
    fonconnect: tthreadmethod;
    fondisconnect: tthreadmethod;
    fparity: tparitytype;
    frxindex: longint;
    frxcount: longint;
    frxbuffer: array[0..31] of byte;
    fstopbits: longint;
    ftimeout: longint;
    procedure fill;
  public
    constructor create;
    destructor destroy; override;
    function connect(const port: string): boolean;
    function connected: boolean;
    procedure disconnect;
    procedure clear;
    function available: longint;
    function get (var buffer; count: longint): longint;
    function send(var buffer; count: longint): longint;
  public
    property baudrate: longint       read fbaudrate write fbaudrate;
    property bits:     longint       read fbits     write fbits;
    property flags:    tserialflags  read fflags    write fflags;
    property parity:   tparitytype   read fparity   write fparity;
    property stopbits: longint       read fstopbits write fstopbits;

    property onconnect: tthreadmethod read fonconnect write fonconnect;
    property ondisconnect: tthreadmethod read fondisconnect write fondisconnect;
  end;

function serialportnames: tstringlist;

var
  {$ifdef ETHERNET}
  serialstream: tltcpcomponent   = nil;
  {$else}
  serialstream: txypserialstream = nil;
  {$endif}

implementation

// txypserialstream

constructor txypserialstream.create;
begin
  inherited create;
  fbits := 8;
  fbaudrate := 115200;
  fflags := [];
  fhandle := 0;
  fparity := noneparity;
  frxindex := 0;
  frxcount:= 0;
  fonconnect := nil;
  fondisconnect := nil;
  fstopbits := 1;
  ftimeout := 5;
end;

destructor txypserialstream.destroy;
begin
  disconnect;
  inherited destroy;
end;

function txypserialstream.connect(const port: string): boolean;
begin
  disconnect;
  {$IFDEF MSWINDOWS}
  fhandle := seropen('\\.\\' + port);
  {$ELSE}
  fhandle := seropen(port);
  {$ENDIF}
  result  := connected;
  if result then
  begin
    sersetparams(fhandle, fbaudrate, fbits, noneparity, fstopbits, fflags);
    if assigned(fonconnect) then
    begin
      fonconnect;
    end;
    clear;
  end;
end;

procedure txypserialstream.clear;
var
  cc: byte;
begin
  if connected then
  begin
    serflushinput (fhandle);
    serflushoutput(fhandle);
    while serreadtimeout(fhandle, cc, 50) > 0 do;
  end;
end;

procedure txypserialstream.disconnect;
begin
  if connected then
  begin
    sersync       (fhandle);
    serflushoutput(fhandle);
    serclose      (fhandle);
  end;
  fhandle := -1;
  if assigned(fondisconnect) then
  begin
    fondisconnect;
  end;
end;

function txypserialstream.available: longint;
begin
  if frxindex = frxcount then fill;
  result := frxcount - frxindex;
end;

procedure txypserialstream.fill;
begin
  frxindex := 0;
  frxcount := serreadtimeout(fhandle, frxbuffer[0], sizeof(frxbuffer), 5);
end;

function txypserialstream.get(var buffer; count: longint): longint;
var
  data: array[0..$FFFF] of byte absolute buffer;
begin
  result := 0;
  while result < count do
  begin
    if frxindex < frxcount then
    begin
      data[result] := frxbuffer[frxindex];
      inc(frxindex);
      inc(result);
    end else
    begin
      fill;
      if frxindex = frxcount then exit;
    end;
  end;
end;

function txypserialstream.send(var buffer; count: longint): longint;
begin
  result := serwrite(fhandle, buffer, count);
end;

function txypserialstream.connected: boolean;
begin
  result := fhandle > 0;
end;

{$IFDEF MSWINDOWS}
function serialportnames: tstringlist;
var
  i: integer;
  l: tstringlist;
  reg: tregistry;
begin
  l := tstringlist.create;
  reg := tregistry.create;
  result := tstringlist.create;
  try
    reg.rootkey := hkey_local_machine;
    if reg.openkeyreadonly('HARDWARE\DEVICEMAP\SERIALCOMM') then
    begin
      reg.getvaluenames(l);
      for i := 0 to l.count -1 do
      begin
        result.add(reg.readstring(l[i]));
      end;
    end;
  finally
    l.destroy;
    reg.destroy;
  end;
end;
{$ENDIF}

{$IFDEF UNIX}
function serialportnames: tstringlist;
var
  i: longint;
begin
  result := tstringlist.create;
  for i := 0 to 12 do
  begin
    result.add('/dev/ttyACM' + inttostr(i));
  end;
end;
{$ENDIF}

end.



