{
  Description: XY-Plot path optimizer.

  Copyright (C) 2020 Melchiorre Caruso <melchiorrecaruso@gmail.com>

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
}

unit xypoptimizer;

{$mode objfpc}

interface

uses
  classes, sysutils, xypdebug, xypmath, xyppaths;

type
  txyppathoptimizerfitness = packed record
    inkdistance: double;
    traveldistance: double;
    penraises: longint;
  end;

  txyppathoptimizer = class(tthread)
  private
    fcleanup: double;
    flist: txypelementlist;
    fpercentage: longint;
    fsubpaths: tfplist;
    fontick: tthreadmethod;
    fonstart: tthreadmethod;
    fonstop: tthreadmethod;
    function getfirst(const p: txyppoint): longint;
    function getfitness: txyppathoptimizerfitness;
    function getlast(const p: txyppoint): longint;
    function getnext(const p: txyppoint): longint;
    function getnextsubpath(const p: txyppoint): longint;
    function isaloop(item: txypelement): boolean;
    procedure clear;
  public
    constructor create(elements: txypelementlist);
    destructor destroy; override;
    procedure execute; override;
  public
    property cleanup: double read fcleanup write fcleanup;
    property ontick:  tthreadmethod read fontick  write fontick;
    property onstart: tthreadmethod read fonstart write fonstart;
    property onstop:  tthreadmethod read fonstop  write fonstop;
    property percentage: longint read fpercentage;
  end;


implementation

const

  gap = 0.02;

// txyppathoptimizer

constructor txyppathoptimizer.create(elements: txypelementlist);
begin
  fcleanup := 0;
  flist := elements;
  fpercentage := 0;
  fsubpaths := tfplist.create;
  freeonterminate := true;
  inherited create(true);
end;

destructor txyppathoptimizer.destroy;
begin
  clear;
  fsubpaths.destroy;
  inherited destroy;
end;

procedure txyppathoptimizer.clear;
var
  i: longint;
begin
  for i := 0 to fsubpaths.count -1 do
  begin
    txypelementlist(fsubpaths[i]).destroy;
  end;
  fsubpaths.clear;
end;

function txyppathoptimizer.getfirst(const p: txyppoint): longint;
var
  i: longint;
  j: longint;
  di: double;
  dj: double = gap;
begin
  result := -1;
  for i := 0 to flist.count -1 do
  begin
    di := distance(p, flist.items[i].firstpoint);
    if di < dj then
    begin
       j :=  i;
      dj := di;
    end
  end;

  if dj < gap then
  begin
    result := j;
  end;
end;

function txyppathoptimizer.getlast(const p: txyppoint): longint;
var
  i: longint;
  j: longint;
  di: double;
  dj: double = gap;
begin
  result := -1;
  for i := 0 to flist.count -1 do
  begin
    di := distance(p, flist.items[i].lastpoint);
    if di < dj then
    begin
       j :=  i;
      dj := di;
    end
  end;

  if dj < gap then
  begin
    result := j;
  end;
end;

function txyppathoptimizer.getnext(const p: txyppoint): longint;
var
     i: longint;
  len1: double = $FFFFFFF;
  len2: double = $FFFFFFF;
  elem: txypelement;
begin
  result := -1;
  for i := 0 to flist.count -1 do
  begin
    elem := flist.items[i];

    len2 := distance(p, elem.firstpoint);
    if len1 > len2 then
    begin
      len1   := len2;
      result := i;
    end;

    len2 := distance(p, elem.lastpoint);
    if len1 > len2 then
    begin
      elem.invert;
      len1   := len2;
      result := i;
    end;

  end;
end;

function txyppathoptimizer.isaloop(item: txypelement): boolean;
begin
  result := distance(item.firstpoint, item.lastpoint) < gap;
end;

function txyppathoptimizer.getnextsubpath(const p: txyppoint): longint;
var
     i: longint;
  elem: txypelement;
 group: txypelementlist;
  len1: double = $FFFFFFF;
  len2: double = $FFFFFFF;
begin
  result := -1;
  for i := 0 to fsubpaths.count -1 do
  begin
    group := txypelementlist(fsubpaths.items[i]);
    elem  := group.items[0];

    len2 := distance(p, elem.firstpoint);
    if len1 > len2 then
    begin
      len1   := len2;
      result := i;
    end;

    elem := group.items[group.count-1];

    len2 := distance(p, elem.lastpoint);
    if len1 > len2 then
    begin
      group.invert;
      len1   := len2;
      result := i;
    end;
  end;
end;

procedure txyppathoptimizer.execute;
var
  i: longint;
  elem: txypelement;
  fitness0: txyppathoptimizerfitness;
  fitness1: txyppathoptimizerfitness;
  last: txyppoint;
  subpath: txypelementlist;
  totalcount: longint;
begin
  if assigned(fonstart) then
    synchronize(fonstart);
  fitness0 := getfitness;

  last.x := 0;
  last.y := 0;
  totalcount := flist.count;
  while flist.count > 0 do
  begin
    fpercentage := round(100*(1-(flist.count/totalcount)));
    if assigned(fontick) then
      synchronize(fontick);
    // create new subpath
    subpath := txypelementlist.create;
    subpath.add(flist.extract(getnext(last)));

    if not isaloop(subpath.items[0]) then
    begin
      elem := subpath.items[0];
      repeat
        i := getfirst(elem.lastpoint);
        if i = -1 then
        begin
          i := getlast(elem.lastpoint);
          if i <> -1 then flist.items[i].invert;
        end;

        if i <> -1 then
        begin
          elem := flist.extract(i);
          subpath.add(elem);
        end;
      until i = -1;

      elem := subpath.items[0];
      repeat
        i := getlast(elem.firstpoint);
        if i = -1 then
        begin
          i := getfirst(elem.firstpoint);
          if i <> -1 then flist.items[i].invert;
        end;

        if i <> -1 then
        begin
          elem := flist.extract(i);
          subpath.insert(0, elem);
        end;
      until i = -1;
    end;
    // store new subpath
    fsubpaths.add(subpath);
  end;
  // reorder subpaths
  while fsubpaths.count > 0 do
  begin
    i := getnextsubpath(last);
    subpath := txypelementlist(fsubpaths[i]);
    if subpath.length > fcleanup then
    begin
      last := subpath.items[subpath.count-1].lastpoint;
      while subpath.count > 0 do
      begin
        flist.add(subpath.extract(0));
      end;
    end;
    subpath.destroy;
    fsubpaths.delete(i);
  end;
  fitness1 := getfitness;

  xyplog.add(format(' OPTIMIZER::INK DISTANCE     %12.2f  (%12.2f)', [fitness1.inkdistance,    fitness0.inkdistance]));
  xyplog.add(format(' OPTIMIZER::TRAVEL DISTANCE  %12.2f  (%12.2f)', [fitness1.traveldistance, fitness0.traveldistance]));
  xyplog.add(format(' OPTIMIZER::PEN RAISES       %12.0u  (%12.0u)', [fitness1.penraises,      fitness0.penraises]));
  if assigned(fonstop) then
    synchronize(fonstop);
end;

function txyppathoptimizer.getfitness: txyppathoptimizerfitness;
var
  i: longint;
  p: txyppoint;
  elem: txypelement;
begin
  fillbyte(result, sizeof(result), 0);

  p.x := 0;
  p.y := 0;
  for i := 0 to flist.count -1 do
  begin
    elem := flist.items[i];
    if distance(p, elem.firstpoint) >= 0.2 then
    begin
      result.traveldistance := result.traveldistance +
        distance(p, elem.firstpoint);
      inc(result.penraises);
    end;
    result.inkdistance := result.inkdistance + elem.length;
    p := elem.lastpoint;
  end;
end;

end.

