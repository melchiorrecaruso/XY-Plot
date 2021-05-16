{
  Description: XY-Plot filler class.

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

unit xypfiller;

{$mode objfpc}

interface

uses
  bgrabitmap, bgrabitmaptypes, classes, graphics,
  sysutils, xypmath, xyppaths, xypoptimizer;

type
  txypfiller = class
  private
    fbitmap: tbgrabitmap;
    fdotsize: single;
    procedure optimize(page: txypelementlist);
  public
    constructor create(abitmap: tbgrabitmap; adotsize: single);
    destructor destroy; override;
    procedure update(page: txypelementlist);
  public

  end;


implementation

constructor txypfiller.create(abitmap: tbgrabitmap; adotsize: single);
begin
  inherited create;
  fbitmap := abitmap;
  fdotsize := adotsize;
end;

destructor txypfiller.destroy;
begin
  inherited destroy;
end;

procedure txypfiller.optimize(page: txypelementlist);
var
  elem: txypelement;
  opt: txyppathoptimizer;
  p: txyppoint;
  poly: txyppolygonal;
  res: txypelementlist;
begin
  opt := txyppathoptimizer.create(page);
  opt.execute;
  opt.destroy;

  p.x := $FFFFFFF;
  p.y := $FFFFFFF;
  poly := txyppolygonal.create;
  res := txypelementlist.create;
  while page.count > 0 do
  begin
    elem := page.extract(0);

    if distance(p, elem.firstpoint) > (1.5*fdotsize) then
      if poly.count > 0 then
      begin
        res.add(txypelementpolygonal.create(poly));
        poly := txyppolygonal.create;
      end;

    poly.add(elem.firstpoint);
    poly.add(elem.lastpoint);
    p := elem.lastpoint;
    elem.destroy;
  end;

  if poly.count > 0 then
  begin
    res.add(txypelementpolygonal.create(poly));
    poly := txyppolygonal.create;
  end;

  while res.count > 0 do
  begin
    page.add(res.extract(0));
  end;
  poly.destroy;
  res.destroy;
end;

procedure txypfiller.update(page: txypelementlist);
var
  i: longint;
  j: longint;
  l: txypline;
  n: longint;
begin
  n := 0;
  j := 0;
  while j < fbitmap.height do
  begin
    i := 0;
    while i < fbitmap.width do
    begin

      if fpcolortotcolor(fbitmap.colors[i, j]) <> clwhite then
      begin

        if n = 0 then
        begin
          l.p0.x := (i)*fdotsize;
          l.p0.y := (j)*fdotsize;
          n := 1;
        end else
        if n > 0 then
        begin
          l.p1.x := (i)*fdotsize;
          l.p1.y := (j)*fdotsize;
          n := n + 1;
        end;

      end else
      if fpcolortotcolor(fbitmap.colors[i, j]) = clwhite then
      begin
        if n > 1 then
        begin
          page.add(txypelementline.create(l));
        end;
        n := 0;
      end;
      i := i + 1;
    end;

    if n > 1 then
    begin
      page.add(txypelementline.create(l));
    end;
    n := 0;
    j := j + 1;
  end;

  if page.count > 0 then
    optimize(page);
end;

end.

