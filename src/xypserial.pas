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
  {$IFDEF UNIX} baseunix, unix, {$ENDIF} classes,
  dateutils, serial, sysutils, xyputils;

type
  txypserialstream = class
  private
    fbaudrate: longint;
    fbits:     longint;
    fflags:    tserialflags;
    fhandle:   longint;
    fparity:   tparitytype;
    frxindex:  longint;
    frxcount:  longint;
    frxbuffer: array[0..31] of byte;
    frxevent:  tthreadmethod;
    fstopbits: longint;
    ftimeout:  longint;
    procedure fill;
  public
    constructor create;
    destructor destroy; override;
    function open(const device: string): boolean;
    function read (var buffer; count: longint): longint;
    function write(var buffer; count: longint): longint;
    function connected: boolean;
    procedure clear;
    procedure close;
  public
    property baudrate: longint       read fbaudrate write fbaudrate;
    property bits:     longint       read fbits     write fbits;
    property flags:    tserialflags  read fflags    write fflags;
    property parity:   tparitytype   read fparity   write fparity;
    property rxevent:  tthreadmethod read frxevent  write frxevent;
    property stopbits: longint       read fstopbits write fstopbits;
  end;

  txypserialmonitor = class(tthread)
  private
    fserial: txypserialstream;
  public
    constructor create(aserial: txypserialstream);
    procedure execute; override;
  public

  end;

function serialportnames: tstringlist;

implementation

// txypserialmonitor

constructor txypserialmonitor.create(aserial: txypserialstream);
begin
  fserial := aserial;
  freeonterminate := true;
  inherited create(true);
end;

procedure txypserialmonitor.execute;
begin
  while assigned(fserial) do
  begin
    if fserial.connected then
    begin
      if fserial.frxindex < fserial.frxcount then
      begin
        if assigned(fserial.frxevent) then
          synchronize(fserial.frxevent);
      end else
        fserial.fill;
    end else
      sleep(5);
  end;
end;

// txypserialstream

constructor txypserialstream.create;
var
  monitor: txypserialmonitor;
begin
  inherited create;
  fbits     := 8;
  fbaudrate := 115200;
  fflags    := [];
  fhandle   := -1;
  fparity   := noneparity;
  frxindex  := 0;
  frxcount  := 0;
  frxevent  := nil;
  fstopbits := 1;
  ftimeout  := 5;
   monitor  := txypserialmonitor.create(self);
   monitor.start;
end;

destructor txypserialstream.destroy;
begin
  close;
  inherited destroy;
end;

function txypserialstream.open(const device: string): boolean;
begin
  close;
  fhandle := seropen(device);
  result  := connected;
  if result then
  begin
    sersetparams(fhandle, fbaudrate, fbits, noneparity, fstopbits, fflags);
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

procedure txypserialstream.close;
begin
  if connected then
  begin
    sersync       (fhandle);
    serflushoutput(fhandle);
    serclose      (fhandle);
  end;
  fhandle := -1;
end;

procedure txypserialstream.fill;
begin
  frxindex := 0;
  frxcount := serreadtimeout(fhandle, frxbuffer[0], sizeof(frxbuffer), 5);
end;

function txypserialstream.read(var buffer; count: longint): longint;
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

function txypserialstream.write(var buffer; count: longint): longint;
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
  i: longint;
begin
  result := tstringlist.create;
  for i := 0 to 12 do
  begin
    result.add('COM' + inttostr(i));
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

