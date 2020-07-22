{
  Description: XY-Plot SVG file reader class.

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

unit xypsvgreader;

{$mode objfpc}

interface

uses
  bgrabitmap, bgrabitmaptypes, bgrasvg, bgrasvgshapes, bgrasvgtype,
  bgravectorize, classes, sysutils, xypdebug, xypmath, xyppaths;

procedure svg2paths(const afilename: string; elements: txypelementlist);

implementation

procedure element2paths(element: tsvgelement; elements: txypelementlist);
var
  bmp: tbgrabitmap;
  content: tsvgcontent;
  i: longint;
  line: txypline;
  points: arrayoftpointf;
  point: txyppoint;
  poly: txyppolygonal;
begin
  bmp := tbgrabitmap.create;
  bmp.canvas2d.fontrenderer := tbgravectorizedfontrenderer.create;
  if (element is tsvgline      ) or
     (element is tsvgrectangle ) or
     (element is tsvgcircle    ) or
     (element is tsvgellipse   ) or
     (element is tsvgpath      ) or
     (element is tsvgtext      ) then
  begin
    element.draw(bmp.canvas2d, cucustom);
    points := bmp.canvas2d.currentpath;
    for i := 0 to system.length(points) -2 do
      if (not isemptypointf(points[i  ])) and
         (not isemptypointf(points[i+1])) then
      begin
        line.p0.x := points[i    ].x;
        line.p0.y := points[i    ].y;
        line.p1.x := points[i + 1].x;
        line.p1.y := points[i + 1].y;
        if xypmath.length(line) > 0 then
          elements.add(txypelementline.create(line));
      end;
    setlength(points, 0);
  end else
  if (element is tsvgpolypoints) then
  begin
    element.draw(bmp.canvas2d, cucustom);
    points := bmp.canvas2d.currentpath;
    poly := txyppolygonal.create;
    for i := 0 to system.length(points) -1 do
      if (not isemptypointf(points[i])) then
      begin
        point.x := points[i].x;
        point.y := points[i].y;
        poly.add(point);
      end;

    if poly.count = 0 then
      poly.destroy
    else
      elements.add(txypelementpolygonal.create(poly));
    setlength(points, 0);
  end else
  if (element is tsvggroup) then
  begin
    content := tsvggroup(element).content;
    for i := 0 to content.elementcount -1 do
      if content.issvgelement[i] then
      begin
        element2paths(content.element[i], elements);
      end;
  end else
  begin
    xyplog.add(format('      LOAD::SKIP %s', [element.classname]));
  end;
  bmp.destroy;
end;

procedure svg2paths(const afilename: string; elements: txypelementlist);
var
    i: longint;
  svg: tbgrasvg;
begin
  xyplog.add(format('      LOAD::FILE %s', [afilename]));
  svg := tbgrasvg.create(afilename);
  for i := 0 to svg.content.elementcount -1 do
    if svg.content.issvgelement[i] then
    begin
      element2paths(svg.content.element[i], elements);
    end;
  svg.destroy;

  elements.mirrorx;
  elements.centertoorigin;
end;

end.

