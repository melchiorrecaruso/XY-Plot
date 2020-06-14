{
  Description: XY-Plot element classes.

  Copyright (C) 2020 Melchiorre Caruso <melchiorrecaruso@gmail.com>

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
  bgrapath, classes, graphics, sysutils, xypdebug, xypmath;

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
  end;

  txypelementline = class(txypelement)
  private
    fline: txypline;
  public
    constructor create;
    constructor create(const aline: txypline);
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
  end;

  txypelementcircle = class(txypelement)
  private
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
  end;

  txypelementcirclearc = class(txypelement)
  private
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
  end;

  txypelementpolygonal = class(txypelement)
  private
    fpolygonal: txyppolygonal;
  public
    constructor create;
    constructor create(const apolygonal: txyppolygonal);
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
    function getpageheigth: double;
    function getpagewidth: double;
  public
    constructor create;
    destructor destroy; override;
    procedure add(element: txypelement);
    procedure delete(index: longint);
    procedure clear;
    function extract(index: longint): txypelement;
    procedure insert(index: longint; element: txypelement);
    //
    procedure centertoorigin;
    procedure invert;
    procedure mirrorx;
    procedure mirrory;
    procedure move(dx, dy: double);
    procedure rotate(value: double);
    procedure scale(value: double);
    //
    function firstpoint: txyppoint;
    function lastpoint: txyppoint;
    function length: double;
    //
    procedure updatepage;
  public
    property count: longint read getcount;
    property items[index: longint]: txypelement read getitem;
    property pageheigh: double read getpageheigth;
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
  path.beginpath;
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
  path.beginpath;
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
  path.beginpath;
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

/// txypelementpolygonal

constructor txypelementpolygonal.create;
begin
  inherited create;
end;

constructor txypelementpolygonal.create(const apolygonal: txyppolygonal);
var
  i: longint;
begin
  inherited create;
  setlength(fpolygonal, system.length(apolygonal));
  for i := 0 to high(apolygonal) do
  begin
    fpolygonal[i] := apolygonal[i];
  end;
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

procedure txypelementpolygonal.interpolate(var path:  txyppolygonal; value: double);
begin
  xypmath.interpolate(fpolygonal, path, value);
end;

procedure txypelementpolygonal.interpolate(var path: tbgrapath);
var
  i: longint;
begin
  path.beginpath;
  if system.length(fpolygonal) > 0 then
  begin
    path.moveto(fpolygonal[0].x, fpolygonal[0].y);
    for i := 1 to system.length(fpolygonal) -1 do
    begin
      path.lineto(fpolygonal[i].x, fpolygonal[i].y);
    end;
  end;
end;

function txypelementpolygonal.firstpoint: txyppoint;
begin
  result := fpolygonal[low(fpolygonal)];
end;

function txypelementpolygonal.lastpoint: txyppoint;
begin
  result := fpolygonal[high(fpolygonal)];
end;

function txypelementpolygonal.length: double;
begin
  result := xypmath.length(fpolygonal);
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
  for i := 0 to Count -1 do
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
  flist.add(element);
  fisneededupdatepage := true;
end;

function txypelementlist.getcount: longint;
begin
  result := flist.count;
end;

function txypelementlist.getitem(index: longint): txypelement;
begin
  result := txypelement(flist[index]);
end;

function txypelementlist.getpageheigth: double;
begin
  updatepage;
  result := fymax-fymin;
end;

function txypelementlist.getpagewidth: double;
begin
  updatepage;
  result := fxmax-fxmin;
end;

procedure txypelementlist.insert(index: longint; element: txypelement);
begin
  flist.insert(index, element);
  fisneededupdatepage := true;
end;

function txypelementlist.extract(index: longint): txypelement;
begin
  result := txypelement(flist[index]);
  flist.delete(index);
  fisneededupdatepage := true;
end;

procedure txypelementlist.delete(index: longint);
begin
  txypelement(flist[index]).destroy;
  flist.delete(index);
  fisneededupdatepage := true;
end;

procedure txypelementlist.move(dx, dy: double);
var
  i: longint;
begin
  for i := 0 to flist.count -1 do
  begin
    txypelement(flist[i]).move(dx, dy);
  end;
end;

procedure txypelementlist.rotate(value: double);
var
  i: longint;
begin
  for i := 0 to flist.count -1 do
  begin
    txypelement(flist[i]).rotate(value);
  end;
  fisneededupdatepage := true;
  xyplog.add(format('  DOCUMENT::ROTATE           %12.5f', [value]));
end;

procedure txypelementlist.scale(value: double);
var
  i: longint;
begin
  for i := 0 to flist.count -1 do
  begin
    txypelement(flist[i]).scale(value);
  end;
  fisneededupdatepage := true;
  xyplog.add(format('  DOCUMENT::SCALE            %12.5f', [value]));
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
  for i := 0 to flist.count -1 do
  begin
    txypelement(flist[i]).mirrorx;
  end;
end;

procedure txypelementlist.mirrory;
var
  i: longint;
begin
  for i := 0 to flist.count -1 do
  begin
    txypelement(flist[i]).mirrory;
  end;
end;

procedure txypelementlist.invert;
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

procedure txypelementlist.updatepage;
var
  i: longint;
  j: longint;
  path:  txyppolygonal = nil;
  point: txyppoint;
begin
  if fisneededupdatepage then
  begin
    fisneededupdatepage := false;
    fxmin  := + maxint;
    fxmax  := - maxint;
    fymin  := + maxint;
    fymax  := - maxint;
    for i := 0 to flist.count -1 do
    begin
      getitem(i).interpolate(path, 0.5);
      for j := 0 to high(path) do
      begin
        point := path[j];
         fxmin := min(fxmin, point.x);
         fxmax := max(fxmax, point.x);
         fymin := min(fymin, point.y);
         fymax := max(fymax, point.y);
      end;
      path := nil;
    end;
  end;
  xyplog.add(format('  DOCUMENT::PAGE WIDTH       %12.1f', [fxmax-fxmin]));
  xyplog.add(format('  DOCUMENT::PAGE HEIGTH      %12.1f', [fymax-fymin]));
end;

procedure txypelementlist.centertoorigin;
begin
  updatepage;
  move(-(fxmax+fxmin)/2, -(fymax+fymin)/2);
  xyplog.add('  DOCUMENT::MOVE ORIGIN TO CENTER');
end;

end.
