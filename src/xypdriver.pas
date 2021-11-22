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
    frcount1: longint;
    fxcount1: longint;
    fycount1: longint;
    fzcount1: longint;
    frcount2: longint;
    fxcount2: longint;
    fycount2: longint;
    fzcount2: longint;
    procedure compute(const p: txyppoint; var cx, cy: longint);
  public
    constructor create(astream: tstream; asetting: txypsetting);
    destructor destroy; override;
    {$ifopt D+}
    procedure debug(const filename: string);
    {$endif}
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
    property rcount1: longint read frcount1;
    property xcount1: longint read fxcount1;
    property ycount1: longint read fycount1;
    property zcount1: longint read fzcount1;
    property rcount2: longint read frcount2;
    property xcount2: longint read fxcount2;
    property ycount2: longint read fycount2;
    property zcount2: longint read fzcount2;
  end;

  procedure driverdebug(adriver: txypdriver);

implementation

const
  incrbit = 0; // bit0 -> decrease internal main-loop time
  decrbit = 1; // bit1 -> increase internal main-loop time
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
  end;

  for i := 0 to 2 do
    for j := 0 to 2 do
    begin
      p := page[i, j];
      printdbg('DRIVER', format('POINT.X          %12.5f mm', [p.x]));
      printdbg('DRIVER', format('POINT.Y          %12.5f mm', [p.y]));
    end;
end;

// txypdriverengine

constructor txypdriver.create(astream: tstream; asetting: txypsetting);
begin
  inherited create;
  fsetting  := asetting;
  fstream   := astream;
  frcount1  := 0;
  fxcount1  := 0;
  fycount1  := 0;
  fzcount1  := 0;
  frcount2  := 0;
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
  frcount1 := 0;
  fxcount1 := 0;
  fycount1 := 0;
  fzcount1 := 0;
  frcount2 := 0;
  fxcount2 := 0;
  fycount2 := 0;
  fzcount2 := 0;
end;

procedure txypdriver.setoriginx;
begin
  frcount1 := 0;
  fxcount1 := 0;
  frcount2 := 0;
  fxcount2 := 0;
end;

procedure txypdriver.setoriginy;
begin
  frcount1 := 0;
  fycount1 := 0;
  frcount2 := 0;
  fycount2 := 0;
end;

procedure txypdriver.setoriginz;
begin
  frcount1 := 0;
  fzcount1 := 0;
  frcount2 := 0;
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
    //dr
    if getbit(data[i], incrbit) = 1 then inc(frcount1);
    if getbit(data[i], decrbit) = 1 then dec(frcount1);
  end;
end;

procedure txypdriver.sync;
begin
  frcount2 := frcount1;
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
begin
  p1.x := 0;
  p1.y := 0;
  poly := txyppolygonal.create;

  for i := 0 to path.count -1 do
  begin
    item := path.items[i];
    item.interpolate(poly, min(fsetting.pxratio, fsetting.pyratio)/10);
    for j := 0 to poly.count -1 do
    begin
      p2 := poly[j];
      if (trunc(p2.x) <= pagewidth ) or
         (trunc(p2.y) <= pageheight) then
      begin
        compute(p2, xcount, ycount);
        if distance(p1, p2) > 0.2 then
          move(fxcount2, fycount2, trunc(fsetting.pzup/fsetting.pzratio/10))
        else
          move(fxcount2, fycount2, trunc(fsetting.pzdown/fsetting.pzratio/10));
        move(xcount, ycount, fzcount2);
        p1 := p2;
      end;
    end;
    poly.clear;
  end;
  poly.destroy;
end;

procedure txypdriver.createramps;
const
  dstp  = 2;
  dmax  = 4;
var
  bfsize: longint;
  bf: array of byte;
  dx: array of longint;
  dy: array of longint;
  dz: array of longint;
  i, j, k: longint;
begin
  {$ifopt D+}
  printdbg('DRIVER', 'CREATE RAMPS');
  {$endif}
  bfsize := fstream.size;
  if bfsize > 0 then
  begin
    setlength(bf, bfsize);
    setlength(dx, bfsize);
    setlength(dy, bfsize);
    setlength(dz, bfsize);
    fstream.seek(0, sofrombeginning);
    fstream.read(bf[0], bfsize);
    // store data in dx, dy and dz arrays
    for i := 0 to bfsize -1 do
    begin
      dx[i] := 0;
      dy[i] := 0;
      dz[i] := 0;
      for j := max(i-dstp, 0) to min(i+dstp, bfsize-1) do
      begin
        //dx
        if getbit(bf[j], xstpbit) = 1 then
        begin
          if getbit(bf[j], xdirbit) = fsetting.pxdir then
            inc(dx[i])
          else
            dec(dx[i]);
        end;
        //dy
        if getbit(bf[j], ystpbit) = 1 then
        begin
          if getbit(bf[j], ydirbit) = fsetting.pydir then
            inc(dy[i])
          else
            dec(dy[i]);
        end;
        //dz
        if getbit(bf[j], zstpbit) = 1 then
        begin
          if getbit(bf[j], zdirbit) = fsetting.pzdir then
            inc(dz[i])
          else
            dec(dz[i]);
        end;
      end;
    end;
    // update buffer stream
    i := dmax;
    j := i + 1;
    while (j < bfsize) do
    begin

      while (j < bfsize) and (abs(dx[j] - dx[i]) <= dmax) and
                             (abs(dy[j] - dy[i]) <= dmax) and
                             (abs(dz[j] - dz[i]) <= dmax) do inc(j);

      for k := 0 to fsetting.rampkl -1 do
        if (i + k) < (j - k) then
        begin
          setbit(bf[i + k - dmax], incrbit);
          setbit(bf[j - k - dmax], decrbit);
        end;

      i := j + 1;
      j := i + 1;
    end;
    // overwrite stream
    fstream.seek(0, sofrombeginning);
    fstream.write(bf[0], bfsize);
    setlength(bf, 0);
    setlength(dx, 0);
    setlength(dy, 0);
    setlength(dz, 0);
  end;
end;

procedure txypdriver.destroyramps;
var
  bfsize: longint;
  bf: array of byte;
  i: longint;
begin
  {$ifopt D+}
  printdbg('DRIVER', 'DESTROY RAMPS');
  {$endif}
  bfsize := fstream.size;
  if bfsize > 0 then
  begin
    setlength(bf, bfsize);
    fstream.seek(0, sofrombeginning);
    fstream.read(bf[0], bfsize);
    // clear ramps
    for i := 0 to bfsize -1 do
    begin
      clearbit(bf[i], incrbit);
      clearbit(bf[i], decrbit);
    end;
    // overwrite stream
    fstream.seek(0, sofrombeginning);
    fstream.write(bf[0], bfsize);
    setlength(bf, 0);
  end;
end;

{$ifopt D+}

procedure txypdriver.debug(const filename: string);
var
  bits: byte;
  x: int64 = 0;
  y: int64 = 0;
  s: int64 = 0;
  t: int64 = 0;
  elemlist: txypelementlist;
  elempoly1: txypelementpolygonal;
  elempoly2: txypelementpolygonal;
  elempoly3: txypelementpolygonal;
  point: txyppoint;
  poly1: txyppolygonal;
  poly2: txyppolygonal;
  poly3: txyppolygonal;
begin
  poly1 := txyppolygonal.create;
  poly2 := txyppolygonal.create;
  poly3 := txyppolygonal.create;
  fstream.seek(0, sofrombeginning);
  while fstream.read(bits, sizeof(bits)) = sizeof(bits) do
  begin
    //x
    if getbit(bits, xstpbit) = 1 then
    begin
      if getbit(bits, xdirbit) = fsetting.pxdir then
        inc(x)
      else
        dec(x);
    end;
    //y
    if getbit(bits, ystpbit) = 1 then
    begin
      if getbit(bits, ydirbit) = fsetting.pydir then
        inc(y)
      else
        dec(y);
      end;

    point.x := t;
    point.y := x;
    poly1.add(point);
    point.y := y;
    poly2.add(point);
    point.y := s;
    poly3.add(point);

    // speed
    if getbit(bits, incrbit) = 1 then inc(s);
    if getbit(bits, decrbit) = 1 then dec(s);

    inc(t);
  end;
  fstream.seek(0, sofrombeginning);

  elempoly1 := txypelementpolygonal.create(poly1);
  elempoly2 := txypelementpolygonal.create(poly2);
  elempoly3 := txypelementpolygonal.create(poly3);
  elemlist := txypelementlist.create;
  elemlist.add(elempoly1);
  elemlist.add(elempoly2);
  elemlist.add(elempoly3);
  elemlist.updatepage;
  elemlist.savetosvg(filename);
  elemlist.destroy;
end;

{$endif}

end.

