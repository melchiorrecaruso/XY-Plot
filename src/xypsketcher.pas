{
  Description: XY-Plot sketcher class.

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

unit xypsketcher;

{$mode objfpc}

interface

uses
  classes, bgrabitmap, math, fpimage, sysutils, xypmath, xyppaths;

type
  txypsketcher = class
  private
    fbitmap: tbgrabitmap;
    fdotsize: double;
    fpageheight: double;
    fpagewidth: double;
    fpatternheight: longint;
    fpatternwidth: longint;
    function getdarkness(x, y, width, heigth: longint): double;
  public
    constructor create(bit: tbgrabitmap);
    destructor destroy; override;
    procedure update(page: txypelementlist); virtual abstract;
  public
    property dotsize: double read fdotsize  write fdotsize;
    property pageheight: double read fpageheight write fpageheight;
    property pagewidth: double read fpagewidth write fpagewidth;
    property patternheight: longint read fpatternheight write fpatternheight;
    property patternwidth: longint read fpatternwidth write fpatternwidth;
  end;

  txypsketchersquare = class(txypsketcher)
  private
    function step1(n, width, heigth: double): txypelementlist; virtual;
  public
    procedure update(page: txypelementlist); override;
  end;

  txypsketcherroundedsquare = class(txypsketchersquare)
  private
    function step1(n, width, heigth: double): txypelementlist; override;
    function step2(elements: txypelementlist; radius: double): txypelementlist;
  end;

  txypsketchertriangular = class(txypsketcher)
  private
    function step1(n, width, heigth: double): txypelementlist; virtual;
  public
    procedure update(page: txypelementlist); override;
  end;


implementation

// txypsketcher

constructor txypsketcher.create(bit: tbgrabitmap);
begin
  inherited create;
  fbitmap := bit;
  fdotsize := 0.5;
  fpageheight := 100;
  fpagewidth := 100;
  fpatternheight := 10;
  fpatternwidth := 10;
end;

destructor txypsketcher.destroy;
begin
  inherited destroy;
end;

function txypsketcher.getdarkness(x, y, width, heigth: longint): double;
var
  i: longint;
  j: longint;
  c: tfpcolor;
begin
  result := 0;
  for j := 0 to heigth -1 do
    for i := 0 to width -1 do
    begin
      c := fbitmap.colors[x+i, y+j];
      result := result + c.blue;
      result := result + c.green;
      result := result + c.red;
    end;
  result := 1 - result/(3*$FFFF*(width*heigth));
end;

// txypsketchersquare

function txypsketchersquare.step1(n, width, heigth: double): txypelementlist;
var
  line: txypline;
begin
  result := txypelementlist.create;
  if n > 0 then
  begin
    line.p0.x := 0;
    line.p0.y := 0;
    line.p1.x := width/(n*2);
    line.p1.y := 0;
    result.add(txypelementline.create(line));

    while line.p1.x < width do
    begin
      if line.p1.x - line.p0.x > 0  then
      begin
        line.p0 := line.p1;
        if line.p1.y = 0 then
          line.p1.y := line.p1.y + heigth
        else
          line.p1.y := 0
      end else
      begin
        line.p0   := line.p1;
        line.p1.x := line.p1.x + width/n;
        if line.p1.x > width then
          line.p1.x := width;
      end;
      result.add(txypelementline.create(line));
    end;
  end else
  begin
    line.p0.x := 0;
    line.p0.y := 0;
    line.p1.x := width;
    line.p1.y := 0;
    result.add(txypelementline.create(line));
  end;
end;

procedure txypsketchersquare.update(page: txypelementlist);
var
   i, j, k: longint;
    nw, nh: longint;
    pw, ph: double;
      dark: double;
     list1: txypelementlist;
     list2: txypelementlist;
        mx: boolean;
      path: txypelementpath;
begin
  list1 := txypelementlist.create;
  nw := (fbitmap.width  div fpatternwidth);
  nh := (fbitmap.height div fpatternheight);
  pw := fpagewidth/nw;
  ph := fpageheight/nh;
  mx := false;

  j := 0;
  while j < nh do
  begin
    i := 0;
    while i < nw do
    begin
      dark  := getdarkness(
        fpatternwidth*i, fpatternheight*j,
        fpatternwidth,   fpatternheight);

      list2 := step1(round((pw/dotsize)*dark), pw, ph);

      if mx then
      begin
        list2.mirrorx;
        list2.move(0, ph);
      end;
      mx := list2.items[list2.count -1].lastpoint.y > 0;

      for k := 0 to list2.count -1 do
      begin
        list2.items[k].move(pw*i, ph*j);
      end;
      while list2.count > 0 do
        list1.add(list2.extract(0));
      list2.destroy;
      inc(i);
    end;
    // save path to page
    if list1.count > 0 then
    begin
      path := txypelementpath.create;
      while list1.count > 0 do
      begin
        path.add(list1.extract(0))
      end;
      page.add(path);
    end;
    inc(j);
  end;
  list1.destroy;
  page.mirrorx;
  page.centertoorigin;
end;

// txypsketcherroundedsquare

function txypsketcherroundedsquare.step1(n, width, heigth: double): txypelementlist;
begin
  if n > 0 then
    result := step2(inherited step1(n, width, heigth), width/(2*n))
  else
    result :=       inherited step1(n, width, heigth)
end;

function txypsketcherroundedsquare.step2(elements: txypelementlist; radius: double): txypelementlist;
var
   i: longint;
  l0: txypline;
  l1: txypline;
  a0: txypcirclearc;
begin
  result := txypelementlist.create;

  if elements.count = 1 then
  begin
    result.add(elements.extract(0));
  end else
  begin
    l0.p0 := txypelementline(elements.items[0]).firstpoint;
    l0.p1 := txypelementline(elements.items[0]).lastpoint;

    for i := 1 to elements.count -1 do
    begin
      l1.p0 := txypelementline(elements.items[i]).firstpoint;
      l1.p1 := txypelementline(elements.items[i]).lastpoint;

      if (l0.p1.y = 0) and
         (l1.p1.y > 0) then // left-bottom corner
      begin
        a0.radius     := radius;
        a0.center.x   := l0.p1.x - radius;
        a0.center.y   := l0.p1.y + radius;
        a0.startangle := pi*3/2;
        a0.endangle   := pi*2;
        l0.p1.x       := a0.center.x;
        l1.p0.y       := a0.center.y;
        result.add(txypelementcirclearc.create(a0));
      end else
      if (l0.p1.y > 0) and
         (l1.p1.y > 0) then // left-top corner
      begin
        a0.radius     := radius;
        a0.center.x   := l0.p1.x + radius;
        a0.center.y   := l0.p1.y - radius;
        a0.startangle := pi;
        a0.endangle   := pi/2;
        l1.p0.x       := a0.center.x;
        l0.p1.y       := a0.center.y;
        result.add(txypelementline.create(l0));
        result.add(txypelementcirclearc.create(a0));
      end else
      if (l0.p1.y > 0) and
         (l1.p1.y = 0) then // right-top corner
      begin
        a0.radius     := radius;
        a0.center.x   := l0.p1.x - radius;
        a0.center.y   := l0.p1.y - radius;
        a0.startangle := pi/2;
        a0.endangle   := 0;
        l0.p1.x       := a0.center.x;
        l1.p0.y       := a0.center.y;
        result.add(txypelementcirclearc.create(a0));
      end else
      if (l0.p1.y = 0) and
         (l1.p1.y = 0) then // right-bottom corner
      begin
        a0.radius     := radius;
        a0.center.x   := l0.p1.x + radius;
        a0.center.y   := l0.p1.y + radius;
        a0.startangle := pi;
        a0.endangle   := pi*3/2;
        l1.p0.x       := a0.center.x;
        l0.p1.y       := a0.center.y;
        result.add(txypelementline.create(l0));
        result.add(txypelementcirclearc.create(a0));
      end;

      l0 := l1;
    end;
  end;
  elements.destroy;
end;

// txypsketchertriangular

function txypsketchertriangular.step1(n, width, heigth: double): txypelementlist;
var
  line: txypline;
begin
  result := txypelementlist.create;
  if n > 0 then
  begin
    line.p0.x := 0;
    line.p0.y := 0;
    line.p1.x := width/(n*2);
    line.p1.y := heigth;
    result.add(txypelementline.create(line));

    while line.p1.x < width do
    begin
      if line.p1.y > line.p0.y then
      begin
        line.p0   := line.p1;
        line.p1.x := min(line.p1.x + width/(n), width);
        line.p1.y := 0;
      end else
      begin
        line.p0   := line.p1;
        line.p1.x := min(line.p1.x + width/(n), width);
        line.p1.y := heigth;
      end;
      result.add(txypelementline.create(line));
    end;
  end else
  begin
    line.p0.x := 0;
    line.p0.y := 0;
    line.p1.x := width;
    line.p1.y := 0;
    result.add(txypelementline.create(line));
  end;
end;

procedure txypsketchertriangular.update(page: txypelementlist);
var
  i, j, k: longint;
   nw, nh: longint;
   pw, ph: double;
     dark: double;
    list1: txypelementlist;
    list2: txypelementlist;
       mx: boolean;
     path: txypelementpath;
begin
  list1 := txypelementlist.create;
  nw := (fbitmap.width  div fpatternwidth);
  nh := (fbitmap.height div fpatternheight);
  pw := fpagewidth/nw;
  ph := fpageheight/nh;
  mx := false;

  j := 0;
  while j < nh do
  begin
    i := 0;
    while i < nw do
    begin
      dark  := getdarkness(
        fpatternwidth*i, fpatternheight*j,
        fpatternwidth,   fpatternheight);

      list2 := step1(round((pw/dotsize)*dark), pw, ph);

      if mx then
      begin
        list2.mirrorx;
        list2.move(0, ph);
      end;
      mx := list2.items[list2.count -1].lastpoint.y > 0;

      for k := 0 to list2.count -1 do
      begin
        list2.items[k].move(pw*i, ph*j);
      end;
      while list2.count > 0 do
        list1.add(list2.extract(0));
      list2.destroy;
      inc(i);
    end;
    // save path to page
    if list1.count > 0 then
    begin
      path := txypelementpath.create;
      while list1.count > 0 do
      begin
        path.add(list1.extract(0));
      end;
      page.add(path);
    end;
    inc(j);
  end;
  list1.destroy;
  page.mirrorx;
  page.centertoorigin;
end;


end.

