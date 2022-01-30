{
  Description: XY-Plot path optimizer class.

  Copyright (C) 2022 Melchiorre Caruso <melchiorrecaruso@gmail.com>

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

unit xyppathoptimizer;

{$mode objfpc}

interface

uses
  classes, sysutils, xypmath, xyppaths, xyputils;

type
  txyppathoptimizer = class
  private
    fcleanup: double;
    fpath: txypelementlist;
    fsubpaths: tfplist;
    function getfirst(const p: txyppoint): longint;
    function getlast(const p: txyppoint): longint;
    function getnext(const p: txyppoint): longint;
    function getnextsubpath(const p: txyppoint): longint;
    function isaloop(item: txypelement): boolean;
    procedure clear;
  public
    constructor create(path: txypelementlist);
    destructor destroy; override;
    procedure execute;
  public
    property cleanup: double read fcleanup write fcleanup;
  end;

  procedure debug(path: txypelementlist; var inkdist, traveldist: double; var raises: longint);

implementation

procedure debug(path: txypelementlist; var inkdist, traveldist: double; var raises: longint);
var
  i: longint;
  p: txyppoint;
  elem: txypelement;
begin
  p := origin;
  for i := 0 to path.count -1 do
  begin
    elem := path.items[i];
    if p <> elem.firstpoint then
    begin
      inc(raises);
      traveldist := traveldist + distance(p, elem.firstpoint);
    end;
    inkdist := inkdist + elem.length;
    p := elem.lastpoint;
  end;
  if p <> origin then
  begin
    inc(raises);
    traveldist := traveldist + distance(p, origin);
  end;
end;

// txyppathoptimizer

constructor txyppathoptimizer.create(path: txypelementlist);
begin
  fcleanup  := 0;
  fpath     := path;
  fsubpaths := tfplist.create;
  inherited create;
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
begin
  result := -1;
  for i := 0 to fpath.count -1 do
    if fpath.items[i].firstpoint = p then
    begin
      result := i;
      exit;
    end
end;

function txyppathoptimizer.getlast(const p: txyppoint): longint;
var
  i: longint;
begin
  result := -1;
  for i := 0 to fpath.count -1 do
    if fpath.items[i].lastpoint = p then
    begin
      result :=  i;
      exit;
    end
end;

function txyppathoptimizer.getnext(const p: txyppoint): longint;
var
     i: longint;
  len1: double = maxint;
  len2: double = maxint;
  elem: txypelement;
begin
  result := -1;
  for i := 0 to fpath.count -1 do
  begin
    elem := fpath.items[i];

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
  result := item.firstpoint = item.lastpoint;
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
  last: txyppoint;
  a0, a1: double;
  b0, b1: double;
  c0, c1: longint;
  subpath: txypelementlist;
begin
  {$ifopt D+}
  a0 := 0;
  b0 := 0;
  c0 := 0;
  debug(fpath, a0, b0, c0);
  {$endif}
  last.x := 0;
  last.y := 0;
  while fpath.count > 0 do
  begin
    // create new subpath
    subpath := txypelementlist.create;
    subpath.add(fpath.extract(getnext(last)));

    if not isaloop(subpath.items[0]) then
    begin
      elem := subpath.items[0];
      repeat
        i := getfirst(elem.lastpoint);
        if i = -1 then
        begin
          i := getlast(elem.lastpoint);
          if i <> -1 then fpath.items[i].invert;
        end;

        if i <> -1 then
        begin
          elem := fpath.extract(i);
          subpath.add(elem);
        end;
      until i = -1;

      elem := subpath.items[0];
      repeat
        i := getlast(elem.firstpoint);
        if i = -1 then
        begin
          i := getfirst(elem.firstpoint);
          if i <> -1 then fpath.items[i].invert;
        end;

        if i <> -1 then
        begin
          elem := fpath.extract(i);
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
        fpath.add(subpath.extract(0));
      end;
    end;
    subpath.destroy;
    fsubpaths.delete(i);
  end;
  {$ifopt D+}
  a1 := 0;
  b1 := 0;
  c1 := 0;
  debug(fpath, a1, b1, c1);
  printdbg('OPTIMIZER', format('INK DISTANCE     %12.2f mm (%12.2f mm)', [a1, a0]));
  printdbg('OPTIMIZER', format('TRAVEL DISTANCE  %12.2f mm (%12.2f mm)', [b1, b0]));
  printdbg('OPTIMIZER', format('PEN RAISES       %12.0u    (%12.0u   )', [c1, c0]));
  {$endif}
end;

end.

