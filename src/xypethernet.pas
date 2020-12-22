{
  Description: XY-Plot ethernet class.

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

unit xypethernet;

{$mode objfpc} {$H+}

interface

uses
  {$IFDEF UNIX} baseunix, unix, {$ENDIF} classes, dateutils, lnet, sysutils;

type
  txypethernetstream = class
  private
    fconnected: boolean;
    fnet: tltcp;
    fip: string;
    fport: longint;
    procedure ondisconnect(asocket: tlsocket);
    procedure onerror(const msg: string; asocket: tlsocket);
    procedure onreceive(asocket: tlsocket);
  public
    constructor create;
    destructor destroy; override;
    function connect(const aip: string; aport: longint): boolean;
    function read (var buffer; count: longint): longint;
    function write(var buffer; count: longint): longint;
    function connected: boolean;
    procedure disconnect;
  public
    property ip:   string  read fip   write fip;
    property port: longint read fport write fport;
  end;

  function serialportnames: tstringlist;

var
  ethernetstream: txypethernetstream = nil;


implementation

// txypserialstream

constructor txypethernetstream.create;
begin
  inherited create;
  fconnected := false;
  fnet := tltcp.create(nil);
  fnet.onerror := @onerror;
  fnet.onreceive := @onreceive;
  fnet.ondisconnect := @ondisconnect;
  fnet.timeout := 1000;
  fip := '';
  fport := 8888;
end;

destructor txypethernetstream.destroy;
begin
  disconnect;
  inherited destroy;
end;

function txypethernetstream.connect(const aip: string; aport: longint): boolean;
begin
  if fconnected then disconnect;





end;

procedure txypethernetstream.disconnect;
begin
  if fconnected then
  begin
    fconnected := false;
    fnet.disconnect(false);
  end;
end;

function txypethernetstream.read(var buffer; count: longint): longint;
var
  d: array[0..maxint-1] of byte absolute buffer;
begin
  result := fnet.get(d[0], count);
end;

function txypethernetstream.write(var buffer; count: longint): longint;
begin
  result := fnet.send(buffer, count);
end;

function txypethernetstream.connected: boolean;
begin
  result := fconnected;
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


