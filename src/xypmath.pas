{
  Description: XY-Plot math unit.

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

unit xypmath;

{$mode objfpc}
{$modeswitch advancedrecords}

interface

uses
  classes, fgl, sysutils, math;

type
  pxyppoint = ^txyppoint;
  txyppoint = packed record
    x: double;
    y: double;
    class operator = (a, b: txyppoint): boolean;
  end;

  pxypline = ^txypline;
  txypline = packed record
    p0: txyppoint;
    p1: txyppoint;
  end;

  pxypcircle = ^txypcircle;
  txypcircle = packed record
    center: txyppoint;
    radius: double;
  end;

  pxypcirclearc = ^txypcirclearc;
  txypcirclearc = packed record
    center:     txyppoint;
    startangle: double; // angle in radiant
    endangle:   double; // angle in radiant
    radius:     double;
  end;

  txyppolygonal = specialize tfpglist<txyppoint>;

// MOVE
procedure move(var point:     txyppoint;     dx, dy: double);
procedure move(var line:      txypline;      dx, dy: double);
procedure move(var circle:    txypcircle;    dx, dy: double);
procedure move(var circlearc: txypcirclearc; dx, dy: double);
procedure move(var polygonal: txyppolygonal; dx, dy: double);

// ROTATE
procedure rotate(var point:     txyppoint;     angle: double);
procedure rotate(var line:      txypline;      angle: double);
procedure rotate(var circle:    txypcircle;    angle: double);
procedure rotate(var circlearc: txypcirclearc; angle: double);
procedure rotate(var polygonal: txyppolygonal; angle: double);

// SCALE
procedure scale(var point:     txyppoint;     factor: double);
procedure scale(var line:      txypline;      factor: double);
procedure scale(var circle:    txypcircle;    factor: double);
procedure scale(var circlearc: txypcirclearc; factor: double);
procedure scale(var polygonal: txyppolygonal; factor: double);

// MIRROR X
procedure mirrorx(var point:     txyppoint    );
procedure mirrorx(var line:      txypline     );
procedure mirrorx(var circle:    txypcircle   );
procedure mirrorx(var circlearc: txypcirclearc);
procedure mirrorx(var polygonal: txyppolygonal);

// MIRROR Y
procedure mirrory(var point:     txyppoint    );
procedure mirrory(var line:      txypline     );
procedure mirrory(var circle:    txypcircle   );
procedure mirrory(var circlearc: txypcirclearc);
procedure mirrory(var polygonal: txyppolygonal);

// INVERT
procedure invert(var line:      txypline     );
procedure invert(var circle:    txypcircle   );
procedure invert(var circlearc: txypcirclearc);
procedure invert(var polygonal: txyppolygonal);

// LENGTH
function length(const line:      txypline     ): double;
function length(const circle:    txypcircle   ): double;
function length(const circlearc: txypcirclearc): double;
function length(const polygonal: txyppolygonal): double;

// INTERPOLATE
procedure interpolate(const line:      txypline;      var path: txyppolygonal; value: double);
procedure interpolate(const circle:    txypcircle;    var path: txyppolygonal; value: double);
procedure interpolate(const circlearc: txypcirclearc; var path: txyppolygonal; value: double);
procedure interpolate(const polygonal: txyppolygonal; var path: txyppolygonal; value: double);

// ---

function distance(const p0, p1: txyppoint): double;

var
  origin: txyppoint;

implementation

class operator txyppoint.= (a, b: txyppoint): boolean;
begin
  result := samevalue(a.x, b.x, 0.2) and samevalue(a.y, b.y, 0.2);
end;

// MOVE

procedure move(var point: txyppoint; dx, dy: double);
begin
  point.x := point.x + dx;
  point.y := point.y + dy;
end;

procedure move(var line: txypline; dx, dy: double);
begin
  move(line.p0, dx, dy);
  move(line.p1, dx, dy);
end;

procedure move(var circle: txypcircle; dx, dy: double);
begin
  move(circle.center, dx, dy);
end;

procedure move(var circlearc: txypcirclearc; dx, dy: double);
begin
  move(circlearc.center, dx, dy);
end;

procedure move(var polygonal: txyppolygonal; dx, dy: double);
var
  i: longint;
  p: txyppoint;
begin
  for i := 0 to polygonal.count -1 do
  begin
    p := polygonal[i];
    move(p, dx, dy);
    polygonal[i] := p;
  end;
end;

// ROTATE

procedure rotate(var point: txyppoint; angle: double); // angle in radiant
var
  px, py: double;
  sn, cs: double;
begin
  sincos(angle, sn, cs);
  begin
    px := point.x * cs - point.y * sn;
    py := point.x * sn + point.y * cs;
  end;
  point.x := px;
  point.y := py;
end;

procedure rotate(var line: txypline; angle: double);
begin
  rotate(line.p0, angle);
  rotate(line.p1, angle);
end;

procedure rotate(var circle: txypcircle; angle: double);
begin
  rotate(circle.center, angle);
end;

procedure rotate(var circlearc: txypcirclearc; angle: double);
begin
  rotate(circlearc.center, angle);
  circlearc.startangle := circlearc.startangle + angle;
  circlearc.endangle   := circlearc.endangle   + angle;
end;

procedure rotate(var polygonal: txyppolygonal; angle: double);
var
  i: longint;
  p: txyppoint;
begin
  for i := 0 to polygonal.count -1 do
  begin
    p := polygonal[i];
    rotate(p, angle);
    polygonal[i] := p;
  end;
end;

// SCALE

procedure scale(var point: txyppoint; factor: double);
begin
  point.x := point.x * factor;
  point.y := point.y * factor;
end;

procedure scale(var line: txypline; factor: double);
begin
  scale(line.p0, factor);
  scale(line.p1, factor);
end;

procedure scale(var circle: txypcircle; factor: double);
begin
  scale(circle.center, factor);
  circle.radius := circle.radius * factor;
end;

procedure scale(var circlearc: txypcirclearc; factor: double);
begin
  scale(circlearc.center, factor);
  circlearc.radius := circlearc.radius * factor;
end;

procedure scale(var polygonal: txyppolygonal; factor: double);
var
  i: longint;
  p: txyppoint;
begin
  for i := 0 to polygonal.count -1 do
  begin
    p := polygonal[i];
    scale(p, factor);
    polygonal[i] := p;
  end;
end;

// MIRROR X

procedure mirrorx(var point: txyppoint);
begin
  point.y := -point.y;
end;

procedure mirrorx(var line: txypline);
begin
  mirrorx(line.p0);
  mirrorx(line.p1);
end;

procedure mirrorx(var circle: txypcircle);
begin
  mirrorx(circle.center);
end;

procedure mirrorx(var circlearc: txypcirclearc);
begin
  mirrorx(circlearc.center);
  circlearc.startangle := -circlearc.startangle + 2*pi;
  circlearc.endangle   := -circlearc.endangle   + 2*pi;
end;

procedure mirrorx(var polygonal: txyppolygonal);
var
  i: longint;
  p: txyppoint;
begin
  for i := 0 to polygonal.count -1 do
  begin
    p := polygonal[i];
    mirrorx(p);
    polygonal[i] := p;
  end;
end;

// MIRROR Y

procedure mirrory(var point: txyppoint);
begin
  point.x := -point.x;
end;

procedure mirrory(var line: txypline);
begin
  mirrory(line.p0);
  mirrory(line.p1);
end;

procedure mirrory(var circle: txypcircle);
begin
  mirrory(circle.center);
end;

procedure mirrory(var circlearc: txypcirclearc);
begin
  mirrory(circlearc.center);
  circlearc.startangle := -circlearc.startangle + pi;
  circlearc.endangle   := -circlearc.endangle   + pi;
end;

procedure mirrory(var polygonal: txyppolygonal);
var
  i: longint;
  p: txyppoint;
begin
  for i := 0 to polygonal.count -1 do
  begin
    p := polygonal[i];
    mirrory(p);
    polygonal[i] := p;
  end;
end;

// INVERT

procedure invert(var line: txypline);
var
  t: txyppoint;
begin
  t       := line.p0;
  line.p0 := line.p1;
  line.p1 := t;
end;

procedure invert(var circle: txypcircle);
begin
  // nothing to do
end;

procedure invert(var circlearc: txypcirclearc);
var
  t: double;
begin
  t                    := circlearc.startangle;
  circlearc.startangle := circlearc.endangle;
  circlearc.endangle   := t;
end;

procedure invert(var polygonal: txyppolygonal);
var
  i: longint;
begin
  for i := 0 to polygonal.count -1 do
  begin
    polygonal.move(i, 0);
  end;
end;

// LENGTH

function length(const line: txypline): double;
begin
  result := distance(line.p0, line.p1);
end;

function length(const circle: txypcircle): double;
const
  sweep = 2*pi;
begin
  result := sweep*circle.radius;
end;

function length(const circlearc: txypcirclearc): double;
var
  sweep: double;
begin
  sweep  := abs(circlearc.endangle-circlearc.startangle);
  result := sweep*circlearc.radius;
end;

function length(const polygonal: txyppolygonal): double;
var
  i: longint;
begin
  result := 0;
  for i := 0 to polygonal.count -2 do
  begin
    result := result + distance(polygonal[i], polygonal[i+1]);
  end;
end;

// INTERPOLATE

procedure interpolate(const line: txypline; var path: txyppolygonal; value: double);
var
  dx, dy: double;
   i,  j: longint;
       p: txyppoint;
begin
   j := max(1, round(distance(line.p0, line.p1)/value));
  dx := (line.p1.x-line.p0.x)/j;
  dy := (line.p1.y-line.p0.y)/j;

  for i := 0 to j do
  begin
    p.x := i*dx;
    p.y := i*dy;
    move(p, line.p0.x,
            line.p0.y);
    path.add(p);
  end;
end;

procedure interpolate(const circle: txypcircle; var path: txyppolygonal; value: double);
var
  i, j: longint;
    ds: double;
     p: txyppoint;
begin
   j := max(1, round(length(circle)/value));
  ds := (2*pi)/j;

  for i := 0 to j do
  begin
    p.x := circle.radius;
    p.y := 0.0;
    rotate(p, i*ds);
    move  (p, circle.center.x,
              circle.center.y);
    path.add(p);
  end;
end;

procedure interpolate(const circlearc: txypcirclearc; var path: txyppolygonal; value: double);
var
  i, j: longint;
    ds: double;
     p: txyppoint;
begin
   j := max(1, round(length(circlearc)/value));
  ds := (circlearc.endangle-circlearc.startangle)/j;

  for i := 0 to j do
  begin
    p.x := circlearc.radius;
    p.y := 0.0;
    rotate(p, circlearc.startangle+(i*ds));
    move  (p, circlearc.center.x,
              circlearc.center.y);
    path.add(p);
  end;
end;

procedure interpolate(const polygonal: txyppolygonal; var path: txyppolygonal; value: double);
var
   i: longint;
   line: txypline;
begin
  for i := 0 to polygonal.count -2 do
  begin
    line.p0 := polygonal[i];
    line.p1 := polygonal[i+1];
    interpolate(line, path, value);
  end;
end;

// ---

function distance(const p0, p1: txyppoint): double; inline;
begin
  result := sqrt(sqr(p1.x - p0.x) + sqr(p1.y - p0.y));
end;

initialization
begin
  origin.x := 0;
  origin.y := 0;
end;

end.

