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
    framplen: longint;
    fstream: tstream;
    fxcount1: longint;
    fycount1: longint;
    fzcount1: longint;
    fxcount2: longint;
    fycount2: longint;
    fzcount2: longint;
    fxratio: double;
    fyratio: double;
    fzratio: double;
    procedure compute(const p: txyppoint; var cx, cy: longint);
    procedure move(cx, cy, cz: longint);
  public
    constructor create(astream: tstream);
    destructor destroy; override;
    procedure movex(cx: longint);
    procedure movey(cy: longint);
    procedure movez(cz: longint);
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
    property ramplen: longint read framplen write framplen;
    property xcount1: longint read fxcount1;
    property ycount1: longint read fycount1;
    property zcount1: longint read fzcount1;
    property xcount2: longint read fxcount2;
    property ycount2: longint read fycount2;
    property zcount2: longint read fzcount2;
    property xratio: double read fxratio write fxratio;
    property yratio: double read fyratio write fyratio;
    property zratio: double read fzratio write fzratio;
  end;

  procedure driverdebug;

implementation

// txypdriverengine::debug

procedure driverdebug;
var
  i, j: longint;
  offsetx: double;
  offsety: double;
  page: array[0..2, 0..2] of txyppoint;
  p: txyppoint;
begin
  page[0, 0].x := -setting.pagewidth  / 2;
  page[0, 0].y := +setting.pageheight / 2;
  page[0, 1].x := +0;
  page[0, 1].y := +setting.pageheight / 2;
  page[0, 2].x := +setting.pagewidth  / 2;
  page[0, 2].y := +setting.pageheight / 2;

  page[1, 0].x := -setting.pagewidth  / 2;
  page[1, 0].y := +0;
  page[1, 1].y := +0;
  page[1, 1].y := +0;
  page[1, 2].x := +0;
  page[1, 2].x := +setting.pagewidth  / 2;

  page[2, 0].x := -setting.pagewidth  / 2;
  page[2, 0].y := -setting.pageheight / 2;
  page[2, 1].x := +0;
  page[2, 1].y := -setting.pageheight / 2;
  page[2, 2].x := +setting.pagewidth  / 2;
  page[2, 2].y := -setting.pageheight / 2;

  with setting do
  begin
    offsetx := (pagewidth )*xfactor + xoffset;
    offsety := (pageheight)*yfactor + yoffset;
  end;
  for i := 0 to 2 do
    for j := 0 to 2 do
    begin
      p   := page[i, j];
      p.x := p.x + offsetx;
      p.y := p.y + offsety;
      {$ifopt D+}
      printdbg('DRIVER', format('POINT.X          %12.5f', [p.x]));
      printdbg('DRIVER', format('POINT.Y          %12.5f', [p.y]));
      {$endif}
    end;
end;

// txypdriverengine

constructor txypdriver.create(astream: tstream);
begin
  inherited create;
  framplen  := 0;
  fstream   := astream;
  fxcount1  := 0;
  fycount1  := 0;
  fzcount1  := 0;
  fxcount2  := 0;
  fycount2  := 0;
  fzcount2  := 0;
  fxratio   := 0;
  fyratio   := 0;
  fzratio   := 0;
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
  data: array[0..$FFFFFF] of byte absolute buffer;
  i: longint;
begin
  for i := 0 to count -1 do
  begin
    //dx
    if getbit(data[i], 0) = 1 then
    begin
      if getbit(data[i], 1) = setting.pxdir then
        dec(fxcount1)
      else
        inc(fxcount1);
    end;
    //dy
    if getbit(data[i], 2) = 1 then
    begin
      if getbit(data[i], 3) = setting.pydir then
        dec(fycount1)
      else
        inc(fycount1);
    end;
    //dz
    if getbit(data[i], 4) = 1 then
    begin
      if getbit(data[i], 5) = setting.pzdir then
        dec(fzcount1)
      else
        inc(fzcount1);
    end;
  end;
  {$ifopt D+}
  printdbg('DRIVER', format('SYNC-1 [X%10.2f] [Y%10.2f] [Z%10.2f]',
    [fxcount1*setting.pxratio,
     fycount1*setting.pyratio,
     fzcount1*setting.pzratio]));
  {$endif}
end;

procedure txypdriver.sync;
begin
  fxcount2 := fxcount1;
  fycount2 := fycount1;
  fzcount2 := fzcount1;
end;

procedure txypdriver.compute(const p: txyppoint; var cx, cy: longint);
begin
  cx := round(p.x/fxratio);
  cy := round(p.y/fyratio);
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
  if setting.pxdir = 1 then
  begin
    if (dx < 0) then setbit(b0, 1);
  end else
    if (dx > 0) then setbit(b0, 1);
  //dy
  if setting.pydir = 1 then
  begin
    if (dy < 0) then setbit(b0, 3);
  end else
    if (dy > 0) then setbit(b0, 3);
  //dz
  if setting.pzdir = 1 then
  begin
    if (dz < 0) then setbit(b0, 5);
  end else
    if (dz > 0) then setbit(b0, 5);

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
  xcnt: longint;
  ycnt: longint;
  xoffset: double;
  yoffset: double;
begin
  p1.x := 0;
  p1.y := 0;
  poly := txyppolygonal.create;
  xoffset := pagewidth *setting.xfactor + setting.xoffset;
  yoffset := pageheight*setting.yfactor + setting.yoffset;
  for i := 0 to path.count -1 do
  begin
    item := path.items[i];
    item.interpolate(poly, max(setting.pxratio, setting.pyratio)/4);
    for j := 0 to poly.count -1 do
    begin
      p2 := poly[j];
      if (abs(p2.x) < (pagewidth /2)) and
         (abs(p2.y) < (pageheight/2)) then
      begin
        p2.x := p2.x + xoffset;
        p2.y := p2.y + yoffset;
        compute(p2, xcnt, ycnt);
        if distance(p1, p2) >= 0.2 then
          move(fxcount2, fycount2, trunc(setting.pzup/setting.pzratio))
        else
          move(fxcount2, fycount2, trunc(setting.pzdown/setting.pzratio));
        move(xcnt, ycnt, fzcount2);
      end;
      p1 := p2;
    end;
    poly.clear;
  end;
  poly.destroy;
end;

procedure txypdriver.createramps;
const
  ds    = 2;
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
  fstream.seek(0, sofrombeginning);
  bufsize := fstream.size;
  if bufsize > 0 then
  begin
    setlength(dx,  bufsize);
    setlength(dy,  bufsize);
    setlength(dz,  bufsize);
    setlength(buf, bufsize);
    fstream.seek(0, sofrombeginning);
    fstream.read(buf[0], bufsize);
    // store data in dx and dy arrays
    for i := 0 to bufsize -1 do
    begin
      dx[i] := 0;
      dy[i] := 0;
      dz[i] := 0;
      for j := max(i-ds, 0) to min(i+ds, bufsize-1) do
      begin
        //dx
        if getbit(buf[j], 0) = 1 then
        begin
          if getbit(buf[j], 1) = setting.pxdir then
            dec(dx[i])
          else
            inc(dx[i]);
        end;
        //dy
        if getbit(buf[j], 2) = 1 then
        begin
          if getbit(buf[j], 3) = setting.pydir then
            dec(dy[i])
          else
            inc(dy[i]);
        end;
        //dz
        if getbit(buf[j], 4) = 1 then
        begin
          if getbit(buf[j], 5) = setting.pzdir then
            dec(dz[i])
          else
            inc(dz[i]);
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

        if (j - k) > (2*framplen) then
        begin
          k := j - framplen;
        end;
      end;

      if j - i > 10 then
      begin
        r := min((j-i) div 2, framplen);
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
    setlength(dz,  0);
    setlength(buf, 0);
  end;
end;

procedure txypdriver.destroyramps;
begin
  // todo ...
end;

end.

