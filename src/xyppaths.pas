{
  Description: XY-Plot path element classes.

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

unit xyppaths;

{$mode objfpc}

interface

uses
  bgrapath, classes, graphics, sysutils, xypmath, xyputils;

type
  txypelement = class(tobject)
  public
    constructor create;
    destructor destroy; override;
    procedure invert; virtual; abstract;
    procedure move(dx, dy: double); virtual; abstract;
    procedure rotate(angle: double); virtual; abstract;
    procedure scale(value: double); virtual; abstract;
    procedure mirrorx; virtual; abstract;
    procedure mirrory; virtual; abstract;
    procedure interpolate(var path: txyppolygonal; value: double); virtual abstract;
    procedure interpolate(var path: tbgrapath); virtual abstract;
    function firstpoint: txyppoint; virtual abstract;
    function lastpoint: txyppoint; virtual abstract;
    function length: double; virtual abstract;
    function section: rawbytestring; virtual abstract;
  end;

  txypelementline = class(txypelement)
  private
    fline: txypline;
  public
    constructor create;
    constructor create(const aline: txypline);
    constructor create(const p0, p1: txyppoint);
    procedure invert; override;
    procedure move(dx, dy: double); override;
    procedure rotate(angle: double); override;
    procedure scale(value: double); override;
    procedure mirrorx; override;
    procedure mirrory; override;
    procedure interpolate(var path: txyppolygonal; value: double); override;
    procedure interpolate(var path: tbgrapath); override;
    function firstpoint: txyppoint; override;
    function lastpoint: txyppoint; override;
    function length: double; override;
    function section: rawbytestring; override;
  end;

  txypelementcircle = class(txypelement)
  public
    fcircle: txypcircle;
  public
    constructor create;
    constructor create(const acircle: txypcircle);
    procedure invert; override;
    procedure move(dx, dy: double); override;
    procedure rotate(angle: double); override;
    procedure scale(value: double); override;
    procedure mirrorx; override;
    procedure mirrory; override;
    procedure interpolate(var path: txyppolygonal; value: double); override;
    procedure interpolate(var path: tbgrapath); override;
    function firstpoint: txyppoint; override;
    function lastpoint: txyppoint; override;
    function length: double; override;
    function section: rawbytestring; override;
  end;

  txypelementcirclearc = class(txypelement)
  public
    fcirclearc: txypcirclearc;
  public
    constructor create;
    constructor create(const acirclearc: txypcirclearc);
    procedure invert; override;
    procedure move(dx, dy: double); override;
    procedure rotate(angle: double); override;
    procedure scale(value: double); override;
    procedure mirrorx; override;
    procedure mirrory; override;
    procedure interpolate(var path: txyppolygonal; value: double); override;
    procedure interpolate(var path: tbgrapath); override;
    function firstpoint: txyppoint; override;
    function lastpoint: txyppoint; override;
    function length: double; override;
    function section: rawbytestring; override;
  end;

  txypelementpolygonal = class(txypelement)
  public
    fpolygonal: txyppolygonal;
  public
    constructor create;
    constructor create(apolygonal: txyppolygonal);
    destructor destroy; override;
    procedure invert; override;
    procedure move(dx, dy: double); override;
    procedure rotate(angle: double); override;
    procedure scale(value: double); override;
    procedure mirrorx; override;
    procedure mirrory; override;
    procedure interpolate(var path: txyppolygonal; value: double); override;
    procedure interpolate(var path: tbgrapath); override;
    function firstpoint: txyppoint; override;
    function lastpoint: txyppoint; override;
    function length: double; override;
    function section: rawbytestring; override;
  end;

  txypelementpath = class(txypelement)
  private
    flist: tfplist;
    function getcount: longint;
    function getitem(index: longint): txypelement;
  public
    constructor create;
    destructor destroy; override;
    procedure add(element: txypelement);
    procedure insert(index: longint; element: txypelement);
    procedure invert; override;
    procedure move(dx, dy: double); override;
    procedure rotate(angle: double); override;
    procedure scale(value: double); override;
    procedure mirrorx; override;
    procedure mirrory; override;
    procedure interpolate(var path: txyppolygonal; value: double); override;
    procedure interpolate(var path: tbgrapath); override;
    function firstpoint: txyppoint; override;
    function lastpoint: txyppoint; override;
    function length: double; override;
    function section: rawbytestring; override;
  public
    property count: longint read getcount;
    property items[index: longint]: txypelement read getitem; default;
  end;

  txypelementlist = class
  private
    fisneededupdatepage: boolean;
    flist: tfplist;
    fxmax: double;
    fxmin: double;
    fymin: double;
    fymax: double;
    function getcount: longint;
    function getitem(index: longint): txypelement;
    function getpagebottom: double;
    function getpageleft: double;
    function getpageheight: double;
    function getpagewidth: double;
  public
    constructor create;
    destructor destroy; override;
    procedure add(element: txypelement);
    procedure delete(index: longint);
    procedure clear;
    function extract(index: longint): txypelement;
    procedure insert(index: longint; element: txypelement);
    function indexof(const firstpoint, lastpoint: txyppoint): longint; overload;
    function indexof(const point: txyppoint): longint; overload;
    procedure split(index: longint);
    //
    procedure invert;
    procedure mirrorx;
    procedure mirrory;
    procedure move(dx, dy: double);
    procedure movetoorigin;
    procedure rotate(value: double);
    procedure scale(value: double);
    //
    function firstpoint: txyppoint;
    function lastpoint: txyppoint;
    function length: double;
    //
    procedure updatepage;
    //
    procedure savetosvg(const filename: string);
  public
    property count: longint read getcount;
    property items[index: longint]: txypelement read getitem; default;
    property pagebottom: double read getpagebottom;
    property pageleft: double read getpageleft;
    property pageheight: double read getpageheight;
    property pagewidth: double read getpagewidth;
  end;


implementation

uses
  math;

/// txypelement

constructor txypelement.create;
begin
  inherited create;
end;

destructor txypelement.destroy;
begin
  inherited destroy;
end;

/// txypelementline

constructor txypelementline.create;
begin
  inherited create;
end;

constructor txypelementline.create(const aline: txypline);
begin
  inherited create;
  fline := aline;
end;

constructor txypelementline.create(const p0, p1: txyppoint);
begin
  inherited create;
  fline.p0 := p0;
  fline.p1 := p1;
end;

procedure txypelementline.invert;
begin
  xypmath.invert(fline);
end;

procedure txypelementline.move(dx, dy: double);
begin
  xypmath.move(fline, dx, dy);
end;

procedure txypelementline.rotate(angle: double);
begin
  xypmath.rotate(fline, angle);
end;

procedure txypelementline.scale(value: double);
begin
  xypmath.scale(fline, value);
end;

procedure txypelementline.mirrorx;
begin
  xypmath.mirrorx(fline);
end;

procedure txypelementline.mirrory;
begin
  xypmath.mirrory(fline);
end;

procedure txypelementline.interpolate(var path: txyppolygonal; value: double);
begin
  xypmath.interpolate(fline, path, value);
end;

procedure txypelementline.interpolate(var path: tbgrapath);
begin
  path.moveto(fline.p0.x, fline.p0.y);
  path.lineto(fline.p1.x, fline.p1.y);
end;

function txypelementline.firstpoint: txyppoint;
begin
  result := fline.p0;
end;

function txypelementline.lastpoint: txyppoint;
begin
  result := fline.p1;
end;

function txypelementline.length: double;
begin
  result := xypmath.length(fline);
end;

function txypelementline.section: rawbytestring;
const
  c = '<line x1="%1.2f" y1="%1.2f" x2="%1.2f" y2="%1.2f" stroke="black" />' + lineending;
begin
  result := format(c, [fline.p0.x, fline.p0.y, fline.p1.x, fline.p1.y]);
end;

/// txypelementcircle

constructor txypelementcircle.create;
begin
  inherited create;
end;

constructor txypelementcircle.create(const acircle: txypcircle);
begin
  inherited create;
  fcircle := acircle;
end;

procedure txypelementcircle.invert;
begin
  xypmath.invert(fcircle);
end;

procedure txypelementcircle.move(dx, dy: double);
begin
  xypmath.move(fcircle, dx, dy);
end;

procedure txypelementcircle.rotate(angle: double);
begin
  xypmath.rotate(fcircle, angle);
end;

procedure txypelementcircle.scale(value: double);
begin
  xypmath.scale(fcircle, value);
end;

procedure txypelementcircle.mirrorx;
begin
  xypmath.mirrorx(fcircle);
end;

procedure txypelementcircle.mirrory;
begin
  xypmath.mirrory(fcircle);
end;

procedure txypelementcircle.interpolate(var path: txyppolygonal; value: double);
begin
  xypmath.interpolate(fcircle, path, value);
end;

procedure txypelementcircle.interpolate(var path: tbgrapath);
begin
  path.arc(fcircle.center.x,
           fcircle.center.y,
           fcircle.radius,0, 2*pi);
end;

function txypelementcircle.firstpoint: txyppoint;
begin
  result.x := fcircle.center.x + fcircle.radius;
  result.y := fcircle.center.y;
end;

function txypelementcircle.lastpoint: txyppoint;
begin
  result := firstpoint;
end;

function txypelementcircle.length: double;
begin
  result := xypmath.length(fcircle);
end;

function txypelementcircle.section: rawbytestring;
const
  c = '<circle cx="%1.2f" cy="%1.2f" r="%1.2f" stroke="black" />' + lineending;
begin
  result := format(c, [fcircle.center.x, fcircle.center.y, fcircle.radius]);
end;

/// txypelementcirclearc

constructor txypelementcirclearc.create;
begin
  inherited create;
end;

constructor txypelementcirclearc.create(const acirclearc: txypcirclearc);
begin
  inherited create;
  fcirclearc := acirclearc;
end;

procedure txypelementcirclearc.invert;
begin
  xypmath.invert(fcirclearc);
end;

procedure txypelementcirclearc.move(dx, dy: double);
begin
  xypmath.move(fcirclearc, dx, dy);
end;

procedure txypelementcirclearc.rotate(angle: double);
begin
  xypmath.rotate(fcirclearc, angle);
end;

procedure txypelementcirclearc.scale(value: double);
begin
  xypmath.scale(fcirclearc, value);
end;

procedure txypelementcirclearc.mirrorx;
begin
  xypmath.mirrorx(fcirclearc);
end;

procedure txypelementcirclearc.mirrory;
begin
  xypmath.mirrory(fcirclearc);
end;

procedure txypelementcirclearc.interpolate(var path: txyppolygonal; value: double);
begin
  xypmath.interpolate(fcirclearc, path, value);
end;

procedure txypelementcirclearc.interpolate(var path: tbgrapath);
begin
  path.arc(
    fcirclearc.center.x,
    fcirclearc.center.y,
    fcirclearc.radius,
    fcirclearc.startangle,
    fcirclearc.endangle,
    fcirclearc.startangle >
    fcirclearc.endangle);
end;

function txypelementcirclearc.firstpoint: txyppoint;
begin
  result.x := fcirclearc.radius;
  result.y := 0;
  xypmath.rotate(result, fcirclearc.startangle);
  xypmath.move  (result, fcirclearc.center.x,
                         fcirclearc.center.y);
end;

function txypelementcirclearc.lastpoint: txyppoint;
begin
  result.x := fcirclearc.radius;
  result.y := 0;
  xypmath.rotate(result, fcirclearc.endangle);
  xypmath.move  (result, fcirclearc.center.x,
                         fcirclearc.center.y);
end;

function txypelementcirclearc.length: double;
begin
  result := xypmath.length(fcirclearc);
end;

function txypelementcirclearc.section: rawbytestring;
const
  c = '<path d="M%1.2f %1.2f A%1.2f %1.2f %1.2f %1.2f %d %1.2f %1.2f' +
      '"fill:none; stroke:black; stroke-width:1.5mm" />' + lineending;
begin
  result := format(c, [
    firstpoint.x,
    firstpoint.y,
    fcirclearc.radius,
    fcirclearc.radius,
    0,
    fcirclearc.endangle > fcirclearc.startangle,
    0,
    lastpoint.x,
    lastpoint.y]);
end;

/// txypelementpolygonal

constructor txypelementpolygonal.create;
begin
  inherited create;
  fpolygonal := txyppolygonal.create;
end;

constructor txypelementpolygonal.create(apolygonal: txyppolygonal);
begin
  inherited create;
  fpolygonal := apolygonal;
end;

destructor txypelementpolygonal.destroy;
begin
  fpolygonal.destroy;
  inherited destroy;
end;

procedure txypelementpolygonal.invert;
begin
  xypmath.invert(fpolygonal);
end;

procedure txypelementpolygonal.move(dx, dy: double);
begin
  xypmath.move(fpolygonal, dx, dy);
end;

procedure txypelementpolygonal.rotate(angle: double);
begin
  xypmath.rotate(fpolygonal, angle);
end;

procedure txypelementpolygonal.scale(value: double);
begin
  xypmath.scale(fpolygonal, value);
end;

procedure txypelementpolygonal.mirrorx;
begin
  xypmath.mirrorx(fpolygonal);
end;

procedure txypelementpolygonal.mirrory;
begin
  xypmath.mirrory(fpolygonal);
end;

procedure txypelementpolygonal.interpolate(var path: txyppolygonal; value: double);
begin
  xypmath.interpolate(fpolygonal, path, value);
end;

procedure txypelementpolygonal.interpolate(var path: tbgrapath);
var
  i: longint;
begin
  if fpolygonal.count > 0 then
  begin
    path.moveto(fpolygonal[0].x, fpolygonal[0].y);
    for i := 1 to fpolygonal.count -1 do
    begin
      path.lineto(fpolygonal[i].x, fpolygonal[i].y);
    end;
  end;
end;

function txypelementpolygonal.firstpoint: txyppoint;
begin
  result := fpolygonal.first;
end;

function txypelementpolygonal.lastpoint: txyppoint;
begin
  result := fpolygonal.last;
end;

function txypelementpolygonal.length: double;
begin
  result := xypmath.length(fpolygonal);
end;

function txypelementpolygonal.section: rawbytestring;
var
  i: longint;
begin
  result := '<polygon points="';
  for i := 0 to fpolygonal.count -1 do
  begin
    result := result + format('%1.2f,%1.2f ', [
      fpolygonal.items[i].x,
      fpolygonal.items[i].y]);
  end;
  result := result + '"style="fill:none; stroke:black; stroke-width:1.5mm" />' + lineending;
end;

/// txypelementpath

constructor txypelementpath.create;
begin
  inherited create;
  flist := tfplist.create;
end;

destructor txypelementpath.destroy;
var
  i: longint;
begin
  for i := 0 to flist.count -1 do
  begin
    txypelement(flist[i]).destroy;
  end;
  flist.destroy;
  inherited destroy;
end;

procedure txypelementpath.add(element: txypelement);
begin
  flist.add(element);
end;

procedure txypelementpath.insert(index: longint; element: txypelement);
begin
  flist.insert(index, element);
end;

procedure txypelementpath.invert;
var
  i, cnt: longint;
begin
  cnt := flist.count -1;
  for i := 0 to cnt do
  begin
    txypelement(flist[0]).invert;
    flist.move(0, cnt-i);
  end;
end;

procedure txypelementpath.move(dx, dy: double);
var
  i: longint;
begin
  for i := 0 to flist.count -1 do
  begin
    txypelement(flist[i]).move(dx, dy);
  end;
end;

procedure txypelementpath.rotate(angle: double);
var
  i: longint;
begin
  for i := 0 to flist.count -1 do
  begin
    txypelement(flist[i]).rotate(angle);
  end;
end;

procedure txypelementpath.scale(value: double);
var
  i: longint;
begin
  for i := 0 to flist.count -1 do
  begin
    txypelement(flist[i]).scale(value);
  end;
end;

procedure txypelementpath.mirrorx;
var
  i: longint;
begin
  for i := 0 to flist.count -1 do
  begin
    txypelement(flist[i]).mirrorx;
  end;
end;

procedure txypelementpath.mirrory;
var
  i: longint;
begin
  for i := 0 to flist.count -1 do
  begin
    txypelement(flist[i]).mirrory;
  end;
end;

procedure txypelementpath.interpolate(var path: txyppolygonal; value: double);
var
  i: longint;
begin
  for i := 0 to flist.count -1 do
  begin
    txypelement(flist[i]).interpolate(path, value);
  end;
end;

procedure txypelementpath.interpolate(var path: tbgrapath);
var
  i: longint;
begin
  for i := 0 to flist.count -1 do
  begin
    txypelement(flist[i]).interpolate(path);
  end;
end;

function txypelementpath.firstpoint: txyppoint;
begin
  result := txypelement(flist.first).firstpoint;
end;

function txypelementpath.lastpoint: txyppoint;
begin
  result := txypelement(flist.last).lastpoint;
end;

function txypelementpath.length: double;
var
  i: longint;
begin
  result := 0;
  for i := 0 to flist.count -1 do
  begin
    result := result + txypelement(flist[i]).length;
  end;
end;

function txypelementpath.section: rawbytestring;
var
  i: longint;
begin
  result := '';
  for i := 0 to flist.count -1 do
  begin
    result := result + txypelement(flist[i]).section;
  end;
end;

function txypelementpath.getcount: longint;
begin
  result := flist.count;
end;

function txypelementpath.getitem(index: longint): txypelement;
begin
  result := txypelement(flist[index]);
end;

/// tvpelementslist

constructor txypelementlist.create;
begin
  inherited create;
  fisneededupdatepage := false;
  flist := tfplist.create;
  fxmax := 0;
  fxmin := 0;
  fymax := 0;
  fymin := 0;
end;

destructor txypelementlist.destroy;
begin
  clear;
  flist.destroy;
  inherited destroy;
end;

procedure txypelementlist.clear;
var
  i: longint;
begin
  fisneededupdatepage := false;
  for i := 0 to count -1 do
  begin
    txypelement(flist[i]).destroy;
  end;
  flist.clear;
  fxmax := 0;
  fxmin := 0;
  fymax := 0;
  fymin := 0;
end;

procedure txypelementlist.add(element: txypelement);
begin
  fisneededupdatepage := true;
  flist.add(element);
end;

procedure txypelementlist.insert(index: longint; element: txypelement);
begin
  fisneededupdatepage := true;
  flist.insert(index, element);
end;

function txypelementlist.indexof(const firstpoint, lastpoint: txyppoint): longint;
var
  i: longint;
  elem: txypelement;
begin
  result := -1;
  for i := 0 to flist.count -1 do
  begin
    elem := txypelement(flist[i]);
    if (elem.firstpoint = firstpoint) and
       (elem.lastpoint  = lastpoint ) then
    begin
      result := i;
      exit;
    end;
  end;
end;

function txypelementlist.indexof(const point: txyppoint): longint;
var
  i: longint;
  elem: txypelement;
begin
  result := -1;
  for i := 0 to flist.count -1 do
  begin
    elem := txypelement(flist[i]);
    if (elem.firstpoint = point) or
       (elem.lastpoint  = point) then
    begin
      result := i;
      exit;
    end;
  end;
end;

procedure txypelementlist.split(index: longint);
var
  elem: txypelement;
  newelem: txypelement;
  newpoint: txyppoint;
  newarc: txypcirclearc;
  newarcswap: double;
begin
  fisneededupdatepage := true;
  elem := txypelement(flist[index]);
  if (elem is txypelementline) then
  begin
    newpoint.x := (elem.firstpoint.x + elem.lastpoint.x) / 2;
    newpoint.y := (elem.firstpoint.y + elem.lastpoint.y) / 2;

    newelem := txypelementline.create;
    txypelementline(newelem).fline.p0 := newpoint;
    txypelementline(newelem).fline.p1 := elem.lastpoint;
    txypelementline(elem).fline.p1 := newpoint;
  end else
    if (elem is txypelementcircle) then
    begin
      newarc.center := txypelementcircle(elem).fcircle.center;
      newarc.radius := txypelementcircle(elem).fcircle.radius;
      newarc.startangle := 0;
      newarc.endangle   := pi;
      flist.add(txypelementcirclearc.create(newarc));

      newarc.startangle := pi;
      newarc.endangle   := pi * 2;
      flist.add(txypelementcirclearc.create(newarc));

      delete(index);
    end else
      if (elem is txypelementcirclearc) then
      begin
        newarc            := txypelementcirclearc(elem).fcirclearc;
        newarcswap        := newarc.endangle - newarc.startangle;
        newarc.endangle   := newarc.startangle + newarcswap / 2;
        flist.add(txypelementcirclearc.create(newarc));

        newarc.startangle := newarc.endangle;
        newarc.endangle   := newarc.startangle + newarcswap / 2;
        flist.add(txypelementcirclearc.create(newarc));

        delete(index);
      end;
end;

function txypelementlist.extract(index: longint): txypelement;
begin
  fisneededupdatepage := true;
  result := txypelement(flist[index]);
  flist.delete(index);
end;

procedure txypelementlist.delete(index: longint);
begin
  fisneededupdatepage := true;
  txypelement(flist[index]).destroy;
  flist.delete(index);
end;

procedure txypelementlist.move(dx, dy: double);
var
  i: longint;
begin
  fisneededupdatepage := true;
  for i := 0 to flist.count -1 do
  begin
    txypelement(flist[i]).move(dx, dy);
  end;
end;

procedure txypelementlist.rotate(value: double);
var
  i: longint;
begin
  fisneededupdatepage := true;
  for i := 0 to flist.count -1 do
  begin
    txypelement(flist[i]).rotate(value);
  end;
end;

procedure txypelementlist.scale(value: double);
var
  i: longint;
begin
  fisneededupdatepage := true;
  for i := 0 to flist.count -1 do
  begin
    txypelement(flist[i]).scale(value);
  end;
end;

function txypelementlist.firstpoint: txyppoint;
begin
  result := getitem(0).firstpoint;
end;

function txypelementlist.lastpoint: txyppoint;
begin
  result := getitem(flist.count -1).lastpoint;
end;

function txypelementlist.length: double;
var
  i: longint;
begin
  result := 0;
  for i := 0 to flist.count -1 do
  begin
    result := result + getitem(i).length;
  end;
end;

procedure txypelementlist.mirrorx;
var
  i: longint;
begin
  fisneededupdatepage := true;
  for i := 0 to flist.count -1 do
  begin
    txypelement(flist[i]).mirrorx;
  end;
end;

procedure txypelementlist.mirrory;
var
  i: longint;
begin
  fisneededupdatepage := true;
  for i := 0 to flist.count -1 do
  begin
    txypelement(flist[i]).mirrory;
  end;
end;

procedure txypelementlist.invert;
var
  i, cnt: longint;
begin
  fisneededupdatepage := true;
  cnt := flist.count -1;
  for i := 0 to cnt do
  begin
    txypelement(flist[0]).invert;
    flist.move(0, cnt-i);
  end;
end;

procedure txypelementlist.updatepage;
var
  i: longint;
  j: longint;
  path:  txyppolygonal;
  point: txyppoint;
begin
  if fisneededupdatepage then
  begin
    fisneededupdatepage := false;
    if flist.count > 0 then
    begin
      fxmin := + maxint;
      fxmax := - maxint;
      fymin := + maxint;
      fymax := - maxint;
      path := txyppolygonal.create;
      for i := 0 to flist.count -1 do
      begin
        getitem(i).interpolate(path, 0.5);
        for j := 0 to path.count -1 do
        begin
          point := path[j];
          fxmin := min(fxmin, point.x);
          fxmax := max(fxmax, point.x);
          fymin := min(fymin, point.y);
          fymax := max(fymax, point.y);
        end;
        path.clear;
      end;
      path.destroy;
    end else
    begin
      fxmin := 0;
      fxmax := 0;
      fymin := 0;
      fymax := 0;
    end;
  end;
  {$ifopt D+}
  printdbg('IMAGE', format('WIDTH              %10.2f mm', [abs(fxmax-fxmin)]));
  printdbg('IMAGE', format('HEIGHT             %10.2f mm', [abs(fymax-fymin)]));
  {$endif}
end;

procedure txypelementlist.movetoorigin;
begin
  updatepage;
  move(-fxmin, -fymin);
end;

procedure txypelementlist.savetosvg(const filename: string);
var
  i: longint;
  strm: tstringlist;
begin
  strm := tstringlist.create;
  strm.add('<?xml version="1.0" encoding="UTF-8" ?>');
  strm.add('<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">');
  strm.add(format('<svg width="%1.2f" height="%1.2f" xmlns="http://www.w3.org/2000/svg">', [pagewidth, pageheight]));
  for i := 0 to flist.count -1 do
  begin
    strm.add(getitem(i).section);
  end;
  strm.add('</svg>');
  strm.savetofile(filename);
  strm.destroy;
end;

function txypelementlist.getpagebottom: double;
begin
  updatepage;
  result := fymin;
end;

function txypelementlist.getpageleft: double;
begin
  updatepage;
  result := fxmin;
end;

function txypelementlist.getpageheight: double;
begin
  updatepage;
  result := fymax-fymin;
end;

function txypelementlist.getpagewidth: double;
begin
  updatepage;
  result := fxmax-fxmin;
end;

function txypelementlist.getcount: longint;
begin
  result := flist.count;
end;

function txypelementlist.getitem(index: longint): txypelement;
begin
  result := txypelement(flist[index]);
end;

end.
