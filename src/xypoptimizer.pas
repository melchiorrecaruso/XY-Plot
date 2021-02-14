{
  Description: XY-Plot path optimizer.

  Copyright (C) 2021 Melchiorre Caruso <melchiorrecaruso@gmail.com>

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
  txyppathoptimizer = class
  private
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
  end;


implementation

const
  gap = 0.02;

// txyppathoptimizer

constructor txyppathoptimizer.create(path: txypelementlist);
begin
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
  j: longint;
  di: double;
  dj: double = gap;
begin
  result := -1;
  for i := 0 to fpath.count -1 do
  begin
    di := distance(p, fpath.items[i].firstpoint);
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
  for i := 0 to fpath.count -1 do
  begin
    di := distance(p, fpath.items[i].lastpoint);
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
  last: txyppoint;
  subpath: txypelementlist;
  totalcount: longint;
begin
  last.x := 0;
  last.y := 0;
  totalcount := fpath.count;
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
    last := subpath.items[subpath.count-1].lastpoint;
    while subpath.count > 0 do
    begin
      fpath.add(subpath.extract(0));
    end;
    subpath.destroy;
    fsubpaths.delete(i);
  end;
end;

end.

