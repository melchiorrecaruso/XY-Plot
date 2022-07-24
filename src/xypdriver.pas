{
  Description: XY-Plot driver class.

  Copyright (C) 2022 Melchiorre Caruso <melchiorrecaruso@gmail.com>

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
  classes, math, sysutils, xypmath, xyppaths, xypserial, xypsetting, xyputils;

type
  txypdriver = class
  private
    fmicroseconds: int64;
    fbrakepoints: tlistlongint;
    fstream: tmemorystream;
    fsetting: txypsetting;
    frcount1: longint; // current rcount value
    fxcount1: longint; // current xcount value
    fycount1: longint; // current ycount value
    fzcount1: longint; // current zcount value
    frcount2: longint; // next    rcount value
    fxcount2: longint; // next    xcount value
    fycount2: longint; // next    ycount value
    fzcount2: longint; // next    zcount value
    procedure addbrakepoint;
    procedure createramps;
    function xcount(const p: txyppoint): longint;
    function ycount(const p: txyppoint): longint;
    procedure move(cx, cy, cz: longint);
  public
    constructor create(asetting: txypsetting; astream: tmemorystream);
    destructor destroy; override;
    procedure clearstream;
    {$ifopt D+}
    procedure debug(const filename: string);
    {$endif}
    procedure movex(acount: longint);
    procedure movey(acount: longint);
    procedure movez(acount: longint);
    procedure moveto(const apoint: txyppoint);
    procedure plot(apath: txypelementlist; pagewidth, pageheight: longint);
    procedure setoriginx;
    procedure setoriginy;
    procedure setoriginz;
    procedure setorigin;
    procedure sync(var buffer; count: longint);
    procedure sync;
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

  txypdriverstreamer = class(tthread)
  private
    fonstart: tthreadmethod;
    fonstop:  tthreadmethod;
    fontick:  tthreadmethod;
    fposition: int64;
    fremainingmillis: int64;
    fserialspeed: longint;
    fsize: int64;
    fstream: tmemorystream;
    procedure startstreaming(count: longint);
    procedure stopstreaming;
  public
    constructor create(astream: tmemorystream);
    destructor destroy; override;
    procedure execute; override;
  public
    property onstart: tthreadmethod write fonstart;
    property onstop:  tthreadmethod write fonstop;
    property ontick:  tthreadmethod write fontick;
    property position: int64 read fposition;
    property remainingmillis: int64 read fremainingmillis;
    property serialspeed: longint read fserialspeed;
    property size: int64 read fsize;
  end;

  procedure driverdebug(adriver: txypdriver);

var
  driver:         txypdriver         = nil;
  driverstreamer: txypdriverstreamer = nil;

implementation

uses
  dateutils;

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
  p0, p1, p2: txyppoint;
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
      p0 := page[i, j];
      printdbg('DRIVER', format('POINT.X          %12.5f mm', [p0.x]));
      printdbg('DRIVER', format('POINT.Y          %12.5f mm', [p0.y]));
    end;

  // getangle routine
  p0.x := 0;  p1.x := 1;  p2.x := 2;
  p0.y := 0;  p1.y := 0;  p2.y := 0;
  printdbg('DRIVER', format('ANGLE-180        %12.0f °', [radtodeg(getangle(p0, p1, p2))]));

  p0.x := 0;  p1.x := 1;  p2.x := 2;
  p0.y := 0;  p1.y := 0;  p2.y := 1.7321;
  printdbg('DRIVER', format('ANGLE-120        %12.0f °', [radtodeg(getangle(p0, p1, p2))]));

  p0.x := 0;  p1.x := 1;  p2.x := 1;
  p0.y := 0;  p1.y := 0;  p2.y := 1;
  printdbg('DRIVER', format('ANGLE-90         %12.0f °', [radtodeg(getangle(p0, p1, p2))]));

  p0.x := 0;  p1.x := 1;  p2.x := 0;
  p0.y := 0;  p1.y := 0;  p2.y := -1;
  printdbg('DRIVER', format('ANGLE-45         %12.0f °', [radtodeg(getangle(p0, p1, p2))]));
end;

// txypdriverengine

constructor txypdriver.create(asetting: txypsetting; astream: tmemorystream);
begin
  inherited create;
  fsetting     := asetting;
  fbrakepoints := tlistlongint.create;
  fstream      := astream;
  frcount1     := 1;
  fxcount1     := 0;
  fycount1     := 0;
  fzcount1     := 0;
  frcount2     := 1;
  fxcount2     := 0;
  fycount2     := 0;
  fzcount2     := 0;
end;

destructor txypdriver.destroy;
begin
  fbrakepoints.destroy;
  inherited destroy;
end;

procedure txypdriver.clearstream;
begin
  fbrakepoints.clear;
  fstream.clear;
end;

procedure txypdriver.addbrakepoint;
begin
  fbrakepoints.add(fstream.seek(0, socurrent));
end;

procedure txypdriver.setorigin;
begin
  frcount1 := 1;
  fxcount1 := 0;
  fycount1 := 0;
  fzcount1 := 0;
  frcount2 := 1;
  fxcount2 := 0;
  fycount2 := 0;
  fzcount2 := 0;
end;

procedure txypdriver.setoriginx;
begin
  frcount1 := 1;
  fxcount1 := 0;
  frcount2 := 0;
  fxcount2 := 0;
end;

procedure txypdriver.setoriginy;
begin
  frcount1 := 1;
  fycount1 := 0;
  frcount2 := 0;
  fycount2 := 0;
end;

procedure txypdriver.setoriginz;
begin
  frcount1 := 1;
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

function txypdriver.xcount(const p: txyppoint): longint;
begin
  result := round(p.x/fsetting.pxratio);
end;

function txypdriver.ycount(const p: txyppoint): longint;
begin
  result := round(p.y/fsetting.pyratio);
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

procedure txypdriver.movex(acount: longint);
begin
  if acount <> fxcount2 then
  begin
    addbrakepoint;
    move(acount, fycount2 , fzcount2);
    addbrakepoint;
  end;
end;

procedure txypdriver.movey(acount: longint);
begin
  if acount <> fycount2 then
  begin
    addbrakepoint;
    move(fxcount2, acount, fzcount2);
    addbrakepoint;
  end;
end;

procedure txypdriver.movez(acount: longint);
begin
  if acount <> fzcount2 then
  begin
    addbrakepoint;
    move(fxcount2, fycount2, acount);
    addbrakepoint;
  end;
end;

procedure txypdriver.moveto(const apoint: txyppoint);
var
 i: longint;
 item: txypelement;
 poly: txyppolygonal;
 startpoint: txyppoint;
begin
  startpoint.x := fxcount2 * fsetting.pxratio;
  startpoint.y := fycount2 * fsetting.pyratio;

  addbrakepoint;
  poly := txyppolygonal.create;
  item := txypelementline.create(startpoint, apoint);
  item.interpolate(poly, min(fsetting.pxratio, fsetting.pyratio)/10);
  for i := 0 to poly.count -1 do
  begin
    move(xcount(poly[i]), ycount(poly[i]), fzcount2);
  end;
  item.destroy;
  poly.destroy;
  addbrakepoint;
end;

procedure txypdriver.plot(apath: txypelementlist; pagewidth, pageheight: longint);
var
  i, j: longint;
  item: txypelement;
  p0: txyppoint;
  p1: txyppoint;
  p2: txyppoint;
  poly: txyppolygonal;
begin
  p0.x := -1.0;
  p0.y := -1.0;
  p1   := origin;
  poly := txyppolygonal.create;
  for i := 0 to apath.count -1 do
  begin
    item := apath.items[i];
    item.interpolate(poly, min(fsetting.pxratio, fsetting.pyratio)/10);

    for j := 0 to poly.count -1 do
    begin
      p2 := poly[j];
      if (p2.x >= 0) and (p2.x <= pagewidth ) and
         (p2.y >= 0) and (p2.y <= pageheight) then
      begin
        if (p1 <> p2) then
        begin

          if distance(p1, p2) > 0.2 then
          begin
            movez(trunc(fsetting.pzup/fsetting.pzratio));
            moveto(p2);
          end else
          begin
            movez(trunc(fsetting.pzdown/fsetting.pzratio));
            if radtodeg(getangle(p0, p1, p2)) < 165 then
            begin
              addbrakepoint;
            end;
            move(xcount(p2), ycount(p2), fzcount2);
          end;
          p0 := p1;
          p1 := p2;
        end;
      end;
    end;
    poly.clear;
  end;
  poly.destroy;
  addbrakepoint;
end;

procedure txypdriver.createramps;
var
  buffersize: longint;
  buffer: array of byte = nil;
  i, j: longint;
  index1: longint;
  index2: longint;
  offset: longint;
begin
  {$ifopt D+} printdbg('DRIVER', 'CREATE RAMPS V2'); {$endif}

  buffersize := fstream.size;
  // store data into dx, dy and dz arrays
  if (buffersize > 0) then
  begin
    setlength(buffer, buffersize);
    fstream.seek(0, sofrombeginning);
    fstream.read(buffer[0], buffersize);
    // clean ramps
    for i := 0 to buffersize -1 do
    begin
      clearbit(buffer[i], incrbit);
      clearbit(buffer[i], decrbit);
    end;
    //
    if fbrakepoints.count > 0 then
    begin
      offset := fbrakepoints[fbrakepoints.count -1] - buffersize;
      if offset > 0 then
        for i := fbrakepoints.count -1 downto 0 do
        begin
          fbrakepoints[i] := fbrakepoints[i] - offset;
          if fbrakepoints[i] < 0 then
          begin
            fbrakepoints.delete(i);
          end;
        end;
    end;
    // create ramps
    index1 := 0;
    for i := 0 to fbrakepoints.count -1 do
    begin
      index2 := fbrakepoints[i] -1;
      if index1 < index2 then
      begin
        for j := 0 to fsetting.rampkl -1 do
        begin
          if (index1 + j) < (index2 - j) then
          begin
            setbit(buffer[index1 + j], incrbit);
            setbit(buffer[index2 - j], decrbit);
          end;
        end;
        index1 := index2;
      end;
    end;
    // estimate microseconds
    i := 0;
    j := 1;
    fmicroseconds := 0;
    while i < buffersize do
    begin
      if getbit(buffer[i], incrbit) = 1 then inc(j);
      if getbit(buffer[i], decrbit) = 1 then dec(j);

      inc(fmicroseconds, round(fsetting.rampkb*(sqrt(j + 1) - sqrt(j))));
      inc(i);
    end;
    // store data into the stream
    fstream.seek(0, sofrombeginning);
    fstream.write(buffer[0], buffersize);
    fstream.seek(0, sofrombeginning);
    setlength(buffer, 0);
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

// txypdriverstreamer

constructor txypdriverstreamer.create(astream: tmemorystream);
begin
  fonstart  := nil;
  fonstop   := nil;
  fontick   := nil;
  fposition := 0;
  fsize     := astream.size;
  fstream   := astream;
  freeonterminate := true;
  inherited create(true);
end;

destructor txypdriverstreamer.destroy;
begin
  fonstart := nil;
  fonstop  := nil;
  fontick  := nil;
  fstream  := nil;
  inherited destroy;
end;

procedure txypdriverstreamer.startstreaming(count: longint);
var
  buffer: array[0..$FFFF] of byte;
begin
  fserialspeed := 0;
  fremainingmillis := driver.fmicroseconds div 1000;
  if serialstream.connected then
  begin
    serialstream.clear;
    count := fstream.read(buffer, count);
    if count > 0 then
    begin
      serialstream.send(buffer, count);
      driver.sync(buffer, count);
      inc(fposition, count);
    end;
  end;
end;

procedure txypdriverstreamer.stopstreaming;
var
  buffer: array[0..$FFFF] of byte;  
  count: int64;
  data: tmemorystream;
begin
  if terminated then
  begin
    data := tmemorystream.create;
    count := fstream.read(buffer, 4096);
    while count > 0 do
    begin
      data.write(buffer, count);
      count := fstream.read(buffer, 4096);
    end;
    fstream.clear;
    fstream.copyfrom(data, 0);
    data.destroy;
  end else
    fstream.clear;
end;

procedure txypdriverstreamer.execute;
var
 buffer: array[0..$FFFF] of byte;
 count: byte;
 i: longint;
 lastposition: int64;
 time1: tdatetime;
 time2: tdatetime;
 time4: int64;
begin
  // create ramps
  driver.createramps;
  // start data streaming
  time1 := now;
  if assigned(fonstart) then
    synchronize(fonstart);
  {$ifdef ETHERNET}
  startstreaming(1024);
  {$else}
  startstreaming(62);
  {$endif}
  lastposition := 0;
  while serialstream.connected do
  begin
    if serialstream.get(count, sizeof(count)) = sizeof(count) then
    begin
      // stopping machine process
      if terminated then
      begin
        count := fstream.read(buffer, min(count, driver.rcount1 - 1));
        for i := 0 to count -1 do
        begin
          clearbit(buffer[i], incrbit);
          setbit  (buffer[i], decrbit);
        end;
      end else
      begin
        count := fstream.read(buffer, count);
      end;
      //
      if count > 0 then
      begin
        serialstream.send(buffer, count);
        driver.sync(buffer, count);
        inc(fposition, count);
      end else
        break;
    end;
    // tick
    time2 := now;
    time4 := millisecondsbetween(time2, time1);
    if time4 > 999 then
    begin
      fremainingmillis := max(0, fremainingmillis - time4);
      fserialspeed     := fposition - lastposition;
      if assigned(fontick) then
      begin
        queue(fontick);
      end;
      lastposition := fposition;
      time1 := time2;
    end;
  end;
  stopstreaming;
  if assigned(fonstop) then
    synchronize(fonstop);
end;

end.
