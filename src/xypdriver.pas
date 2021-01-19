{
  Description: XY-Plot driver class.

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

unit xypdriver;

{$mode objfpc}

interface

uses
  classes, math, sysutils, xypdebug, xypmath, xypserial, xypsetting, xyputils;

type
  txypdriver = class(tthread)
  private
    fenabled: boolean;
    fmessage: string;
    frampkb: longint;
    frampki: longint;
    frampkl: longint;
    fpercentage: longint;
    fserial: txypserialstream;
    fsetting: txypsetting;
    fstream: tmemorystream;
    fxcount: longint;
    fxreverse: boolean;
    fycount: longint;
    fyreverse: boolean;
    fzcount: longint;
    fzreverse: boolean;
    fonerror: tthreadmethod;
    fonstart: tthreadmethod;
    fonstop: tthreadmethod;
    procedure createramps;
    procedure destroyramps;
  public
    constructor create(asetting: txypsetting; aserial: txypserialstream);
    destructor destroy; override;
    procedure init;
    procedure move(cx, cy,cz: longint);
    procedure execute; override;
  published
    property enabled: boolean read fenabled write fenabled;
    property message: string read fmessage;
    property onerror: tthreadmethod read fonerror write fonerror;
    property onstart: tthreadmethod read fonstart write fonstart;
    property onstop:  tthreadmethod read fonstop  write fonstop;
    property percentage: longint read fpercentage;
    property xcount: longint read fxcount;
    property ycount: longint read fycount;
    property zcount: longint read fzcount;
    property xreverse: boolean read fxreverse write fxreverse;
    property yreverse: boolean read fyreverse write fyreverse;
    property zreverse: boolean read fzreverse write fzreverse;
  end;

type
  txypdriverengine = class
  private
    fsetting: txypsetting;
  public
    constructor create(asetting: txypsetting);
    destructor destroy; override;
    function  calclengthx(const p: txyppoint): double;
    function  calclengthy(const p: txyppoint): double;
    procedure calclengths(const p: txyppoint; out lx, ly: double);
    procedure calcsteps(const p: txyppoint; out sx, sy: longint);
    procedure calcpoint(const lx, ly: double; out p: txyppoint);
  end;


  function serverget (serial: txypserialstream; id: byte; var value: longint): boolean;
  function serverset (serial: txypserialstream; id: byte;     value: longint): boolean;

  procedure driverenginedebug(adriverengine: txypdriverengine);

const
  server_nop       = 255;
  server_rst       = 254;

  server_getxcount = 240;
  server_getycount = 241;
  server_getzcount = 242;
  server_getrampkb = 243;
  server_getrampki = 244;

  server_setxcount = 230;
  server_setycount = 231;
  server_setzcount = 232;
  server_setrampkb = 233;
  server_setrampki = 234;

  server_movx      = 220;
  server_movy      = 221;
  server_movz      = 222;


implementation

// server get/set routines

function serverget(serial: txypserialstream; id: byte; var value: longint): boolean;
var
  cc: byte;
begin
  result := serial.connected;
  if result then
  begin
    serial.clear;
    result := (serial.write(id,    sizeof(id   )) = sizeof(id   )) and
              (serial.read (cc,    sizeof(cc   )) = sizeof(cc   )) and
              (serial.read (cc,    sizeof(cc   )) = sizeof(cc   )) and
              (serial.read (value, sizeof(value)) = sizeof(value));

    result := result and (cc = id);
  end;
end;

function serverset(serial: txypserialstream; id: byte; value: longint): boolean;
var
  cc: byte;
begin
  result := serial.connected;
  if result then
  begin
    serial.clear;
    result := (serial.write(id,    sizeof(id   )) = sizeof(id   )) and
              (serial.read (cc,    sizeof(cc   )) = sizeof(cc   )) and
              (serial.write(value, sizeof(value)) = sizeof(value)) and
              (serial.read (cc,    sizeof(cc   )) = sizeof(cc   ));

    result := result and (cc = id);
  end;
end;

// txypdriverengine

constructor txypdriverengine.create(asetting: txypsetting);
begin
  inherited create;
  fsetting  := asetting;
end;

destructor txypdriverengine.destroy;
begin
  inherited destroy;
end;

function txypdriverengine.calclengthx(const p: txyppoint): double;
begin
  result := p.x;
end;

function txypdriverengine.calclengthy(const p: txyppoint): double;

begin
  result := p.y;
end;

procedure txypdriverengine.calclengths(const p: txyppoint; out lx, ly: double);
begin
  lx := p.x;
  ly := p.y;
end;

procedure txypdriverengine.calcsteps(const p: txyppoint; out sx, sy: longint);
begin
  sx := round(p.x/fsetting.pxratio);
  sy := round(p.y/fsetting.pyratio);
end;

procedure txypdriverengine.calcpoint(const lx, ly: double; out p: txyppoint);
begin
  p.x := lx;
  p.y := ly;
end;

// txypdriverengine::debug

procedure driverenginedebug(adriverengine: txypdriverengine);
var
    i,  j: longint;
   lx, ly: double;
  offsetx: double;
  offsety: double;
     page: array[0..2, 0..2] of txyppoint;
       pp: txyppoint;
begin
  page[0, 0].x := -adriverengine.fsetting.pagewidth  / 2;
  page[0, 0].y := +adriverengine.fsetting.pageheight / 2;
  page[0, 1].x := +0;
  page[0, 1].y := +adriverengine.fsetting.pageheight / 2;
  page[0, 2].x := +adriverengine.fsetting.pagewidth  / 2;
  page[0, 2].y := +adriverengine.fsetting.pageheight / 2;

  page[1, 0].x := -adriverengine.fsetting.pagewidth  / 2;
  page[1, 0].y := +0;
  page[1, 1].y := +0;
  page[1, 1].y := +0;
  page[1, 2].x := +0;
  page[1, 2].x := +adriverengine.fsetting.pagewidth  / 2;

  page[2, 0].x := -adriverengine.fsetting.pagewidth  / 2;
  page[2, 0].y := -adriverengine.fsetting.pageheight / 2;
  page[2, 1].x := +0;
  page[2, 1].y := -adriverengine.fsetting.pageheight / 2;
  page[2, 2].x := +adriverengine.fsetting.pagewidth  / 2;
  page[2, 2].y := -adriverengine.fsetting.pageheight / 2;

  with adriverengine.fsetting do
  begin
    offsetx := (pagewidth )*xfactor + xoffset;;
    offsety := (pageheight)*yfactor + yoffset;
  end;

  for i := 0 to 2 do
    for j := 0 to 2 do
    begin
      pp   := page[i, j];
      pp.x := pp.x + offsetx;
      pp.y := pp.y + offsety;
      adriverengine.calclengths(pp, lx, ly);

      xyplog.add(format('    DRIVER::POINT.X          %12.5f   LENGTH.X  %12.5f', [pp.x, lx]));
      xyplog.add(format('    DRIVER::POINT.Y          %12.5f   LENGTH.Y  %12.5f', [pp.y, ly]));
    end;
end;

// txypdriver

constructor txypdriver.create(asetting: txypsetting; aserial: txypserialstream);
begin
  fenabled  := true;
  fmessage  := '';
  fsetting  := asetting;
  frampkb   := fsetting.rampkb;
  frampki   := fsetting.rampki;
  frampkl   := fsetting.rampkl;
  fserial   := aserial;
  fsetting  := asetting;
  fstream   := tmemorystream.create;
  fxcount   := 0;
  fxreverse := fsetting.pxdir < 0;
  fycount   := 0;
  fyreverse := fsetting.pydir < 0;
  fzcount   := 0;
  fzreverse := fsetting.pzdir < 0;

  fonerror  := nil;
  fonstart  := nil;
  fonstop   := nil;
  freeonterminate := true;
  inherited create(true);
end;

destructor txypdriver.destroy;
begin
  fserial  := nil;
  fsetting := nil;
  fstream.clear;
  fstream.destroy;
  inherited destroy;
end;

procedure txypdriver.init;
begin
  xyplog.add('    DRIVER::INIT');
  fserial.clear;
  fstream.clear;
  if (not serverget(fserial, server_getxcount, fxcount)) or
     (not serverget(fserial, server_getycount, fycount)) or
     (not serverget(fserial, server_getzcount, fzcount)) or
     (not serverset(fserial, server_setrampkb, frampkb)) or
     (not serverset(fserial, server_setrampki, frampki)) then
  begin
    fmessage := 'Unable connecting to server !';
    if assigned(fonerror) then
      synchronize(fonerror);
  end;
end;

procedure txypdriver.move(cx, cy, cz: longint);
var
  b0: byte;
  b1: byte;
  dx: longint;
  dy: longint;
  dz: longint;
  ct: longint;
begin
  if fsetting.pagedir < 0 then
  begin
    ct := cx;
    cx := cy;
    cy := ct;
  end;

  //if fxreverse then cx := -1*cx;
  //if fyreverse then cy := -1*cy;
  //if fzreverse then cz := -1*cz;

  b0 := %00000000;
  dx := (cx - fxcount);
  dy := (cy - fycount);
  dz := (cz - fzcount);
  if (dx < 0) then setbit(b0, 1);
  if (dy < 0) then setbit(b0, 3);
  if (dz < 0) then setbit(b0, 5);

  dx := abs(dx);
  dy := abs(dy);
  dz := abs(dz);
  while (dx > 0) or (dy > 0) or (dz > 0) do
  begin
    b1 := b0;
    if dx > 0 then
    begin
      setbit(b1, 0);
      dec(dx);
    end;

    if dy > 0 then
    begin
      setbit(b1, 2);
      dec(dy);
    end;

    if dz > 0 then
    begin
      setbit(b1, 4);
      dec(dz);
    end;
    fstream.write(b1, 1);
  end;
  fxcount := cx;
  fycount := cy;
  fzcount := cz;
end;

procedure txypdriver.createramps;
const
  ds    = 2;
  maxdx = 4;
  maxdy = 4;
var
  bufsize: longint;
  buf: array of byte;
  dx:  array of longint;
  dy:  array of longint;
  i, j, k, r: longint;
begin
  xyplog.add('    DRIVER::CREATE RAMPS');
  bufsize := fstream.size;
  if bufsize > 0 then
  begin
    setlength(dx,  bufsize);
    setlength(dy,  bufsize);
    setlength(buf, bufsize);
    fstream.seek(0, sofrombeginning);
    fstream.read(buf[0], bufsize);

    // store data in dx and dy arrays
    for i := 0 to bufsize -1 do
    begin
      dx[i] := 0;
      dy[i] := 0;
      for j := max(i-ds, 0) to min(i+ds, bufsize-1) do
      begin
        if getbit(buf[j], 2) = 1 then
        begin
          if getbit(buf[j], 3) = 1 then
            dec(dy[i])
          else
            inc(dy[i]);
        end;
      end;
    end;

    // update stream
    i := 0;
    j := i + 1;
    while (j < bufsize) do
    begin
      k := i;
      while (abs(dx[j] - dx[k]) <= maxdx) and
            (abs(dy[j] - dy[k]) <= maxdy) do
      begin
        if j = bufsize -1 then break;
        inc(j);

        if (j - k) > (2*frampkl) then
        begin
          k := j - frampkl;
        end;
      end;

      if j - i > 10 then
      begin
        r := min((j-i) div 2, frampkl);
        for k := (i) to (i+r-1) do
          setbit(buf[k], 6);

        for k := (j-r+1) to (j) do
          setbit(buf[k], 7);
      end;
      i := j + 1;
      j := i + 1;
    end;
    fstream.seek(0, sofrombeginning);
    fstream.write(buf[0], bufsize);
    setlength(dx,  0);
    setlength(dy,  0);
    setlength(buf, 0);
  end;
end;

procedure txypdriver.destroyramps;
begin
  // todo ...
end;

procedure txypdriver.execute;
var
  bf: array[0..55] of byte;
  bs: byte;
  i: longint;
  j: longint;
  streamsize:  int64;
  streamwrote: int64;
begin
  xyplog.add('    DRIVER::RUN ...');
  if assigned(onstart) then
    synchronize(fonstart);
  createramps;
  fpercentage := 0;
  streamwrote := 0;
  streamsize  := fstream.size;
  // waiting rst signal ...
  bs := server_rst;
  fserial.write(bs, 1);
  repeat
    bs := 0;
    fserial.read(bs, 1);
  until (bs = server_rst) or (terminated);
  // seek stream from beginning
  fstream.seek(0, sofrombeginning);
  // read bytes form stream
  bs := fstream.read(bf, sizeof(bf));
  // send bytes to server
  while (bs > 0) and (not terminated) do
  begin
    inc(streamwrote, fserial.write(bf, bs));
    fpercentage := round(100*(streamwrote/streamsize));
    // get server buffer free-space
    repeat
      bs := 0;
      fserial.read(bs, 1);
    until (bs > 0) or (terminated);
    // pause server and raise pen honder
    if (not fenabled) then
    begin
      // waiting nop signal ...
      bs := server_nop;
      fserial.write(bs, 1);
      repeat
        bs := 0;
        fserial.read(bs, 1);
      until (bs = server_nop) or (terminated);
      // move pen-holder up
      i := 0;
      j := 0;
      //if (not serverget(fserial, server_getzcount, i)) then terminate;
      //if (not serverset(fserial, server_movz,      j)) then terminate;
      // waiting ...
      //while (not fenabled) do sleep(500);
      // move pen-holder down
      //if (not serverset(fserial, server_movz,      i)) then terminate;
      // reset buffersize
      bs := sizeof(bf);
    end;
    // continue to send data ...
    bs := fstream.read(bf, bs);
  end;

  // waiting nop signal ...
  bs := server_nop;
  fserial.write(bs, 1);
  repeat
    bs := 0;
    fserial.read(bs, 1);
  until (bs = server_nop) or (terminated);
  // check server status ...
  i := -1;
  if ((not serverget(fserial, server_getxcount, i)) or (fxcount <> i)) or
     ((not serverget(fserial, server_getycount, i)) or (fycount <> i)) or
     ((not serverget(fserial, server_getzcount, i)) or (fzcount <> i)) or
     ((not serverget(fserial, server_getrampkb, i)) or (frampkb <> i)) or
     ((not serverget(fserial, server_getrampki, i)) or (frampki <> i)) then
  begin
    fmessage := 'Server syncing error !';
    if assigned(fonerror) then synchronize(fonerror);
  end;

  if assigned(fonstop) then
    synchronize(fonstop);
  writeln('    DRIVER::END');
end;

end.

