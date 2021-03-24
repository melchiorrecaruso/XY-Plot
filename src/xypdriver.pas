{
  Description: XY-Plot driver class.

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

unit xypdriver;

{$mode objfpc}

interface

uses
  classes, math, sysutils, xypmath, xyppaths, xypsetting, xyputils;

type
  txypdriver = class
  private
    fsetting: txypsetting;
    fstream:  tstream;
    fxcount1: longint;
    fycount1: longint;
    fzcount1: longint;
    fxcount2: longint;
    fycount2: longint;
    fzcount2: longint;
    procedure compute(const p: txyppoint; var cx, cy: longint);
  public
    constructor create(astream: tstream; asetting: txypsetting);
    destructor destroy; override;
    procedure movex(cx: longint);
    procedure movey(cy: longint);
    procedure movez(cz: longint);
    procedure move(cx, cy, cz: longint);
    procedure move(path: txypelementlist; pagewidth, pageheight: longint);
    procedure setoriginx;
    procedure setoriginy;
    procedure setoriginz;
    procedure setorigin;
    procedure sync(var buffer; count: longint);
    procedure sync;
    procedure createramps;
    procedure destroyramps;
  published
    property xcount1: longint read fxcount1;
    property ycount1: longint read fycount1;
    property zcount1: longint read fzcount1;
    property xcount2: longint read fxcount2;
    property ycount2: longint read fycount2;
    property zcount2: longint read fzcount2;
  end;

  procedure driverdebug(adriver: txypdriver);

implementation

const
  incrbit = 0; // bit0 -> increase internal main-loop time
  decrbit = 1; // bit1 -> decrease internal main-loop time
  xstpbit = 2; // bit2 -> x-motor stp
  ystpbit = 3; // bit3 -> y-motor stp
  zstpbit = 4; // bit4 -> z-motor stp
  xdirbit = 5; // bit5 -> x-motor dir
  ydirbit = 6; // bit6 -> y-motor dir
  zdirbit = 7; // bit7 -> z-motor dir

// txypdriverengine::debug

procedure driverdebug(adriver: txypdriver);
var
  i, j: longint;
  offsetx: double;
  offsety: double;
  page: array[0..2, 0..2] of txyppoint;
  p: txyppoint;
begin
  with adriver.fsetting do
  begin
    page[0, 0].x := -pagewidth  / 2;
    page[0, 0].y := +pageheight / 2;
    page[0, 1].x := +0;
    page[0, 1].y := +pageheight / 2;
    page[0, 2].x := +pagewidth  / 2;
    page[0, 2].y := +pageheight / 2;

    page[1, 0].x := -pagewidth  / 2;
    page[1, 0].y := +0;
    page[1, 1].y := +0;
    page[1, 1].y := +0;
    page[1, 2].x := +0;
    page[1, 2].x := +pagewidth  / 2;

    page[2, 0].x := -pagewidth  / 2;
    page[2, 0].y := -pageheight / 2;
    page[2, 1].x := +0;
    page[2, 1].y := -pageheight / 2;
    page[2, 2].x := +pagewidth  / 2;
    page[2, 2].y := -pageheight / 2;

    offsetx := (pagewidth )*xfactor + xoffset;
    offsety := (pageheight)*yfactor + yoffset;
  end;

  for i := 0 to 2 do
  begin
    for j := 0 to 2 do
    begin
      p   := page[i, j];
      p.x := p.x + offsetx;
      p.y := p.y + offsety;
      printdbg('DRIVER', format('POINT.X          %12.5f mm', [p.x]));
      printdbg('DRIVER', format('POINT.Y          %12.5f mm', [p.y]));
    end;
  end;
end;

// txypdriverengine

constructor txypdriver.create(astream: tstream; asetting: txypsetting);
begin
  inherited create;
  fsetting  := asetting;
  fstream   := astream;
  fxcount1  := 0;
  fycount1  := 0;
  fzcount1  := 0;
  fxcount2  := 0;
  fycount2  := 0;
  fzcount2  := 0;
end;

destructor txypdriver.destroy;
begin
  inherited destroy;
end;

procedure txypdriver.setorigin;
begin
  fxcount1 := 0;
  fycount1 := 0;
  fzcount1 := 0;
  fxcount2 := 0;
  fycount2 := 0;
  fzcount2 := 0;
end;

procedure txypdriver.setoriginx;
begin
  fxcount1 := 0;
  fxcount2 := 0;
end;

procedure txypdriver.setoriginy;
begin
  fycount1 := 0;
  fycount2 := 0;
end;

procedure txypdriver.setoriginz;
begin
  fzcount1 := 0;
  fzcount2 := 0;
end;

procedure txypdriver.sync(var buffer; count: longint);
var
  data: array[0..$FFFF] of byte absolute buffer;
  i: longint;
begin
  for i := 0 to count -1 do
  begin
    //dx
    if getbit(data[i], xstpbit) = 1 then
    begin
      if getbit(data[i], xdirbit) = fsetting.pxdir then
        inc(fxcount1)
      else
        dec(fxcount1);
    end;
    //dy
    if getbit(data[i], ystpbit) = 1 then
    begin
      if getbit(data[i], ydirbit) = fsetting.pydir then
        inc(fycount1)
      else
        dec(fycount1);
    end;
    //dz
    if getbit(data[i], zstpbit) = 1 then
    begin
      if getbit(data[i], zdirbit) = fsetting.pzdir then
        inc(fzcount1)
      else
        dec(fzcount1);
    end;
  end;
end;

procedure txypdriver.sync;
begin
  fxcount2 := fxcount1;
  fycount2 := fycount1;
  fzcount2 := fzcount1;
end;

procedure txypdriver.compute(const p: txyppoint; var cx, cy: longint);
begin
  cx := round(p.x/fsetting.pxratio);
  cy := round(p.y/fsetting.pyratio);
end;

procedure txypdriver.move(cx, cy, cz: longint);
var
  b0: byte;
  b1: byte;
  dx: longint;
  dy: longint;
  dz: longint;
begin
  b0 := %00000000;
  dx := (cx - fxcount2);
  dy := (cy - fycount2);
  dz := (cz - fzcount2);
  // dx
  if fsetting.pxdir = 1 then
  begin
    if (dx > 0) then setbit(b0, xdirbit);
  end else
    if (dx < 0) then setbit(b0, xdirbit);
  //dy
  if fsetting.pydir = 1 then
  begin
    if (dy > 0) then setbit(b0, ydirbit);
  end else
    if (dy < 0) then setbit(b0, ydirbit);
  //dz
  if fsetting.pzdir = 1 then
  begin
    if (dz > 0) then setbit(b0, zdirbit);
  end else
    if (dz < 0) then setbit(b0, zdirbit);

  dx := abs(dx);
  dy := abs(dy);
  dz := abs(dz);
  while (dx > 0) or (dy > 0) or (dz > 0) do
  begin
    b1 := b0;
    if dx > 0 then
    begin
      setbit(b1, xstpbit);
      dec(dx);
    end;

    if dy > 0 then
    begin
      setbit(b1, ystpbit);
      dec(dy);
    end;

    if dz > 0 then
    begin
      setbit(b1, zstpbit);
      dec(dz);
    end;
    fstream.write(b1, sizeof(b1));
  end;
  fxcount2 := cx;
  fycount2 := cy;
  fzcount2 := cz;
end;

procedure txypdriver.movex(cx: longint);
begin
  move(cx, fycount2 , fzcount2);
end;

procedure txypdriver.movey(cy: longint);
begin
  move(fxcount2, cy, fzcount2);
end;

procedure txypdriver.movez(cz: longint);
begin
  move(fxcount2, fycount2, cz);
end;

procedure txypdriver.move(path: txypelementlist; pagewidth, pageheight: longint);
var
  i, j: longint;
  item: txypelement;
  p1, p2: txyppoint;
  poly: txyppolygonal;
  xcount: longint;
  ycount: longint;
  xoffset: double;
  yoffset: double;
begin
  p1.x := 0;
  p1.y := 0;
  poly := txyppolygonal.create;
  xoffset := pagewidth *fsetting.xfactor + fsetting.xoffset;
  yoffset := pageheight*fsetting.yfactor + fsetting.yoffset;
  for i := 0 to path.count -1 do
  begin
    item := path.items[i];
    item.interpolate(poly, min(fsetting.pxratio, fsetting.pyratio)/10);
    for j := 0 to poly.count -1 do
    begin
      p2 := poly[j];
      if (abs(p2.x) < (pagewidth /2)) and
         (abs(p2.y) < (pageheight/2)) then
      begin
        p2.x := p2.x + xoffset;
        p2.y := p2.y + yoffset;
        compute(p2, xcount, ycount);
        if distance(p1, p2) > 0.2 then
          move(fxcount2, fycount2, trunc(fsetting.pzup/fsetting.pzratio))
        else
          move(fxcount2, fycount2, trunc(fsetting.pzdown/fsetting.pzratio));
        move(xcount, ycount, fzcount2);
      end;
      p1 := p2;
    end;
    poly.clear;
  end;
  poly.destroy;
end;

procedure txypdriver.createramps;
const
  dstp  = 2;
  maxdx = 4;
  maxdy = 4;
  maxdz = 4;
var
  bufsize: longint;
  buf: array of byte;
   dx: array of longint;
   dy: array of longint;
   dz: array of longint;
  i, j, k, r: longint;
begin
  {$ifopt D+} printdbg('DRIVER', 'CREATE RAMPS'); {$endif}
  bufsize := fstream.size;
  if bufsize > 0 then
  begin
    setlength(dx, bufsize);
    setlength(dy, bufsize);
    setlength(dz, bufsize);
    setlength(buf, bufsize);
    fstream.seek(0, sofrombeginning);
    fstream.read(buf[0], bufsize);
    // store data in dx, dy and dz arrays
    for i := 0 to bufsize -1 do
    begin
      dx[i] := 0;
      dy[i] := 0;
      dz[i] := 0;
      for j := max(i-dstp, 0) to min(i+dstp, bufsize-1) do
      begin
        //dx
        if getbit(buf[j], xstpbit) = 1 then
        begin
          if getbit(buf[j], xdirbit) = fsetting.pxdir then
            inc(dx[i])
          else
            dec(dx[i]);
        end;
        //dy
        if getbit(buf[j], ystpbit) = 1 then
        begin
          if getbit(buf[j], ydirbit) = fsetting.pydir then
            inc(dy[i])
          else
            dec(dy[i]);
        end;
        //dz
        if getbit(buf[j], zstpbit) = 1 then
        begin
          if getbit(buf[j], zdirbit) = fsetting.pzdir then
            inc(dz[i])
          else
            dec(dz[i]);
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
            (abs(dy[j] - dy[k]) <= maxdy) and
            (abs(dz[j] - dz[k]) <= maxdz) do
      begin
        if j = bufsize -1 then break;
        inc(j);

        if (j - k) > (2*fsetting.rampkl) then
        begin
          k := j - fsetting.rampkl;
        end;
      end;

      if j - i > 10 then
      begin
        r := min((j-i) div 2, fsetting.rampkl);
        for k := (i) to (i+r-1) do
          setbit(buf[k], incrbit);

        for k := (j-r+1) to (j) do
          setbit(buf[k], decrbit);
      end;
      i := j + 1;
      j := i + 1;
    end;
    // overwrite stream
    fstream.seek(0, sofrombeginning);
    fstream.write(buf[0], bufsize);
    setlength(buf, 0);
    setlength(dx, 0);
    setlength(dy, 0);
    setlength(dz, 0);
  end;
  fstream.seek(0, sofrombeginning);
end;

procedure txypdriver.destroyramps;
var
  bufsize: longint;
  buf: array of byte;
  i: longint;
begin
  {$ifopt D+} printdbg('DRIVER', 'DESTROY RAMPS'); {$endif}
  bufsize := fstream.size;
  if bufsize > 0 then
  begin
    setlength(buf, bufsize);
    fstream.seek(0, sofrombeginning);
    fstream.read(buf[0], bufsize);
    // clear ramps
    for i := 0 to bufsize -1 do
    begin
      clearbit(buf[i], incrbit);
      clearbit(buf[i], decrbit);
    end;
    // overwrite stream
    fstream.seek(0, sofrombeginning);
    fstream.write(buf[0], bufsize);
    setlength(buf, 0);
  end;
  fstream.seek(0, sofrombeginning);
end;

end.

