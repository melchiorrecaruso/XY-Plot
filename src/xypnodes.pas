{
  Description: XY-Plot node classes.

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

unit xypnodes;

{$mode objfpc}

interface

uses
  classes, sysutils, xypmath;

type
  // txypnodelist

  txypnodelist = class
  private
    flist: txyppolygonal;
    function getcount: longint;
    function getitem(index: longint): txyppoint;
  public
    constructor create;
    destructor destroy; override;
    procedure add(node: txyppoint);
    function indexof(node: txyppoint): longint;
    procedure clear;
  public
    property count: longint read getcount;
    property item[index: longint]: txyppoint read getitem; default;

  end;

implementation

// txypnodelist

function comparenode(const p1, p2: txyppoint): longint;
begin
  if p1 = p2 then
    result := 0
  else
    if p1.x > p2.x then
      result := 1
    else
      if p1.x < p2.x then
        result := -1
      else
        if p1.y > p2.y then
           result := 1
        else
          if p1.y < p2.y then
            result := -1
          else
            writeln('ERROR-KKK');
end;

constructor txypnodelist.create;
begin
  inherited create;
  flist := txyppolygonal.Create;
end;

destructor txypnodelist.destroy;
begin
  inherited destroy;
  flist.destroy;
end;

procedure txypnodelist.add(node: txyppoint);
begin
  flist.add(node);
end;

function txypnodelist.indexof(node: txyppoint): longint;
var
  i: longint;
begin
  result := -1;
  for i := 0 to flist.count -1 do
    if node = flist[i] then
    begin
      result := i;
      exit;
    end;
end;

function txypnodelist.getcount: longint;
begin
  result := flist.count;
end;

function txypnodelist.getitem(index: longint): txyppoint;
begin
  result := flist[index];
end;

procedure txypnodelist.clear;
begin
  flist.clear;
end;

end.

