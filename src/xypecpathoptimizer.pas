{
  Description: XY-Plot Eulerian cycles path optimizer class.

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

unit xypecpathoptimizer;

{$mode objfpc}

interface

uses
  classes, fgl, sysutils, xypmath, xypnodes, xyppaths, xyputils,
  xypsimulatedannealing, xypgeneticalgorithm, xyppathoptimizer;

type
  // txyppathpresaoptimizer

  txyppathpresaoptimizer = class
  private
    fpath: txypelementlist;
  public
    constructor create(path: txypelementlist);
    destructor destroy; override;
    procedure execute;
  end;

  // txypgraphoptimizer

  txypgraphoptimizer = class
  private
    fadj: array of tlistlongint;
    fcircuit: tlistlongint;
    fgraph: tbooleanmatrix;
    fnodes: txypnodelist;
    fpath: txypelementlist;
    procedure hierholzer(source: longint);
    procedure dijktra(source, dest: longint);
    procedure make_graph_eulerian;
    procedure make_circuit(source: longint);
    procedure clear;
  public
    constructor create(path: txypelementlist);
    destructor destroy; override;
    procedure execute(start: txyppoint);
  end;

  // txyppathoptimizer2

  txyppathoptimizer2 = class
  private
    fpath: txypelementlist;
    fsubpaths: array of txypelementlist;
    function nearpoint(const point: txyppoint; elements: txypelementlist): txyppoint;
  public
    constructor create(path: txypelementlist);
    destructor destroy; override;
    procedure execute;
  end;


implementation

type
  txypelementhiddenline = class(txypelementline);

// txyppathpresaoptimizer

constructor txyppathpresaoptimizer.create(path: txypelementlist);
begin
  inherited create;
  fpath := path;
end;

destructor txyppathpresaoptimizer.destroy;
begin
  inherited destroy;
end;

procedure txyppathpresaoptimizer.execute;
var
  i, j, k: longint;
  elem: txypelement;
  poly: txyppolygonal;
begin
  // explode polygonal
  {$ifopt D+} printdbg('ECP-OPT', 'Explode polygonal'); {$endif}
  for i := fpath.count -1 downto 0 do
  begin
    if fpath[i] is txypelementpolygonal then
    begin
      poly := txypelementpolygonal(fpath[i]).fpolygonal;
      for j := 0 to poly.count -2 do
      begin
        fpath.add(txypelementline.create(poly[j], poly[j + 1]));
      end;
      fpath.delete(i);
    end;
  end;
  // split circles in arcs
  {$ifopt D+} printdbg('ECP-OPT', 'Split circles in arcs'); {$endif}
  i := fpath.count -1;
  while i > -1  do
  begin
    if fpath[i] is txypelementcircle then
    begin
      fpath.split(i);
    end;
    dec(i);
  end;
  i := fpath.count -1;
  while i > -1 do
  begin
    if fpath[i] is txypelementcirclearc then
      if fpath[i].firstpoint = fpath[i].lastpoint then
      begin
        fpath.split(i);
      end;
    dec(i);
  end;
  // delete single point element
  {$ifopt D+} printdbg('ECP-OPT', 'Delete single point element'); {$endif}
  for i := fpath.count -1 downto 0 do
    if fpath[i].firstpoint = fpath[i].lastpoint then
    begin
      fpath.delete(i);
    end;
  // split elements with same first and last points
  {$ifopt D+} printdbg('ECP-OPT', 'Split elements with same first and last points'); {$endif}
  i := fpath.count -1;
  while i > -1  do
  begin
    elem := fpath.extract(i);

    k := -1;
    for j := 0 to fpath.count -1 do
    begin
      if (elem.firstpoint = fpath[j].firstpoint) and
         (elem.lastpoint  = fpath[j].lastpoint ) then
      begin
        k := j;
        break;
      end;

      if (elem.firstpoint = fpath[j].lastpoint ) and
         (elem.lastpoint  = fpath[j].firstpoint) then
      begin
        k := j;
        break;
      end;
    end;

    fpath.add(elem);
    if k <> -1 then
    begin
      fpath.split(fpath.count -1);
    end;
    dec(i);
  end;
end;

// txypgraphoptimizer

constructor txypgraphoptimizer.create(path: txypelementlist);
begin
  inherited create;
  fcircuit := tlistlongint.create;
  fnodes   := txypnodelist.create;
  fpath    := path;
end;

destructor txypgraphoptimizer.destroy;
begin
  clear;
  fcircuit.destroy;
  fnodes.destroy;
  inherited destroy;
end;

procedure txypgraphoptimizer.clear;
begin
  fcircuit.clear;
  fnodes.clear;
end;

procedure txypgraphoptimizer.dijktra(source, dest: longint);
var
  i, j: longint;
  m: double;
  v: tbooleanvector;
  d: tsinglevector;
  p: tlongintvector;
begin
  setlength(v, system.length(fgraph));
  setlength(d, system.length(fgraph));
  setlength(p, system.length(fgraph));
  for i := 0 to high(fgraph) do
  begin
    d[i] := maxint;
    v[i] := false;
    p[i] := 0;
  end;
  d[source] := 0;

  repeat
    m := maxint;
    for i := 0 to high(fgraph) do
      if v[i] = false then
        if d[i] <= m then
        begin
          m := d[i];
          j := i;
        end;

    if m <> maxint then
    begin
      v[j] := true;
      for i := 0 to high(fgraph) do
        if fgraph[i][j] = true then
          if d[i] > d[j] + distance(fnodes[i], fnodes[j]) then
          begin
            d[i] := d[j] + distance(fnodes[i], fnodes[j]);
            p[i] := j;
          end;
    end;

  until m = maxint;

  // add arcs
  j := dest;
  repeat
     fpath.add(txypelementline.create(fnodes[j], fnodes[p[j]]));
     fgraph[j][p[j]] := true;
     fgraph[p[j]][j] := true;
     j := p[j];
  until j = source;
  setlength(v, 0);
  setlength(d, 0);
  setlength(p, 0);
end;

procedure txypgraphoptimizer.hierholzer(source: longint);
var
  curr_path: tlistlongint;
  curr_v: longint;
  next_v: longint;
begin
  curr_path := tlistlongint.create;
  // Maintain a stack to keep vertices
  // We can start from any vertex
  curr_path.add(source);
  // list to store final circuit
  while curr_path.count > 0 do
  begin
    curr_v := curr_path[curr_path.count -1];
    // If there's remaining edge in adjacency list
    // of the current vertex
    if fadj[curr_v].count > 0 then
    begin
      // Find and remove the next vertex that is
      // adjacent to the current vertex
      next_v := fadj[curr_v][0];
      fadj[curr_v].delete(0);
      fadj[next_v].delete(fadj[next_v].indexof(curr_v));
      // Push the new vertex to the stack
      curr_path.add(next_v);
    end else
    // back-track to find remaining circuit
    begin
      // Remove the current vertex and
      // put it in the circuit
      fcircuit.add(curr_v);
      curr_path.delete(curr_path.count -1);
    end;
  end;
  curr_path.destroy;
end;

procedure txypgraphoptimizer.make_graph_eulerian;
var
  i, j, k: longint;
  oddnodes: tlistlongint;
  opt: tsimulatedannealing4oddnodes;
  solution: tsimulatedannealingsolution = nil;
begin
  {$ifopt D+} printdbg('ECP-OPT', 'Create node list'); {$endif}
  for k := 0 to fpath.count -1 do
  begin
    if fnodes.indexof(fpath[k].firstpoint) = -1 then
      fnodes.add(fpath[k].firstpoint);

    if fnodes.indexof(fpath[k].lastpoint) = -1 then
      fnodes.add(fpath[k].lastpoint);
  end;
  {$ifopt D+} printdbg('ECP-OPT', 'Create graph ' + inttostr(fnodes.count) + ' nodes'); {$endif}
  system.setlength(fgraph, fnodes.count, fnodes.count);
  for i := 0 to high(fgraph) do
    for j := 0 to high(fgraph) do fgraph[i][j] := false;

  for k := fpath.count -1 downto 0 do
  begin
    i := fnodes.indexof(fpath[k].firstpoint);
    j := fnodes.indexof(fpath[k].lastpoint);

    if (i = -1) or (j = -1) then
    begin
      {$ifopt D+} printdbg('ECP-OPT', 'FATAL ERROR-1'); {$endif}
      fpath.delete(k);
    end else
      if (i = j) then
      begin
        {$ifopt D+} printdbg('ECP-OPT', 'FATAL ERROR-2'); {$endif}
        fpath.delete(k);
      end else
      begin
        fgraph[i][j] := true;
        fgraph[j][i] := true;
      end;
  end;
  {$ifopt D+} printdbg('ECP-OPT', 'Finding odd degree nodes in subgraph'); {$endif}
  oddnodes := tlistlongint.create;
  for i := 0 to high(fgraph) do
    oddnodes.add(0);

  for i := 0 to high(fgraph) do
    for j := 0 to high(fgraph) do
      if fgraph[i][j] = true then
        begin
          oddnodes[i] := oddnodes[i] + 1;
        end;

  i := oddnodes.count -1;
  while i > -1 do
  begin
    if (oddnodes[i] mod 2) = 0 then
      oddnodes.delete(i)
    else
      oddnodes[i] := i;
    dec(i);
  end;
  {$ifopt D+} printdbg('ECP-OPT', 'Odd degree nodes = ' + inttostr(oddnodes.count)); {$endif}
  if oddnodes.count > 2 then
  begin
    {$ifopt D+} printdbg('ECP-OPT', 'Create an array for odd nodes'); {$endif}
    setlength(solution, oddnodes.count);
    for i := 0 to high(solution) do
      solution[i] := fnodes[oddnodes[i]];

    {$ifopt D+} printdbg('ECP-OPT', 'Start optimization'); {$endif}
    opt := tsimulatedannealing4oddnodes.create;
    opt.initialtemperature := 100;
    opt.coolingrate := 0.001;
    opt.executiontime := 10;
    opt.execute(solution);
    opt.destroy;
    {$ifopt D+} printdbg('ECP-OPT', 'End optimization'); {$endif}
    {$ifopt D+} printdbg('ECP-OPT', 'Add new archs in subpath'); {$endif}
    k := 0;
    while k < system.length(solution) do
    begin
      i := fnodes.indexof(solution[k]);
      j := fnodes.indexof(solution[k + 1]);
      fpath.add(txypelementhiddenline.create(fnodes[i], fnodes[j]));
      fgraph[i][j] := true;
      fgraph[j][i] := true;
      //dijktra(i, j);
      inc(k, 2);
    end;
    setlength(solution, 0);
  end else
  begin
    if oddnodes.count = 2 then
    begin
      {$ifopt D+} printdbg('ECP-OPT', 'Add new arch in subpath'); {$endif}
      i := fnodes.indexof(fnodes[oddnodes[0]]);
      j := fnodes.indexof(fnodes[oddnodes[1]]);
      fpath.add(txypelementhiddenline.create(fnodes[i], fnodes[j]));
      fgraph[i][j] := true;
      fgraph[j][i] := true;
      //dijktra(i, j);
    end;
  end;
  oddnodes.destroy;
  setlength(fgraph, 0, 0);
end;

procedure txypgraphoptimizer.make_circuit(source: longint);
var
  i, j, k, m: longint;
  newpath: txypelementlist;
  point: txyppoint;
begin
  {$ifopt D+} printdbg('ECP-OPT', 'Create graph adjacency list ...'); {$endif}
  setlength(fadj, fnodes.count);
  for i := 0 to high(fadj) do
    fadj[i] := tlistlongint.create;

  for k := 0 to fpath.count -1 do
  begin
    i := fnodes.indexof(fpath[k].firstpoint);
    j := fnodes.indexof(fpath[k].lastpoint);
    fadj[i].add(j);
    fadj[j].add(i);
  end;
  {$ifopt D+} printdbg('ECP-OPT', 'Hierholzer Algorithm for subpath'); {$endif}
  hierholzer(source);
  {$ifopt D+} printdbg('ECP-OPT', 'Destroy graph adjacency list'); {$endif}
  for i := 0 to high(fadj) do
  begin
    fadj[i].destroy;
  end;
  setlength(fadj, 0);
  {$ifopt D+} printdbg('ECP-OPT', 'Print Circuit: ' + inttostr(fcircuit.count)); {$endif}

  newpath := txypelementlist.create;
  for k := 0 to fcircuit.count -2 do
  begin
    i := fcircuit[k];
    j := fcircuit[k + 1];

    m := fpath.indexof(fnodes[i], fnodes[j]);
    if m <> -1 then
    begin
      newpath.add(fpath.extract(m));
    end else
    begin
      m := fpath.indexof(fnodes[j], fnodes[i]);
      if m <> -1 then
      begin
        fpath[m].invert;
        newpath.add(fpath.extract(m));
      end;
    end;
  end;

  for i := 0 to fpath.count -1 do
  begin
    point := fpath[i].firstpoint;
    writeln('ERROR-4');
    writeln('[',point.x:0:2,', ', point.y:0:2,']');

    point := fpath[i].lastpoint;
    writeln('[',point.x:0:2,', ', point.y:0:2,']');
  end;
  fpath.clear;

  while newpath.count > 0 do
  begin
    if newpath[0] is txypelementhiddenline then
      newpath.extract(0)
    else
      fpath.add(newpath.extract(0));
  end;
  newpath.destroy;
end;

procedure txypgraphoptimizer.execute(start: txyppoint);
var
  i: longint;
  preopt: txyppathpresaoptimizer;
begin
  preopt := txyppathpresaoptimizer.create(fpath);
  preopt.execute;
  preopt.destroy;

  make_graph_eulerian;
  i := fnodes.indexof(start);
  if i <> -1 then
  begin
    make_circuit(i);
  end;
end;

// txyppathoptimizer2

constructor txyppathoptimizer2.create(path: txypelementlist);
begin
  inherited create;
  fpath := path;
end;

destructor txyppathoptimizer2.destroy;
begin
  inherited destroy;
end;

function txyppathoptimizer2.nearpoint(const point: txyppoint; elements: txypelementlist): txyppoint;
var
  i: longint;
  dist1: single;
  dist2: single;
begin
  dist1 := maxint;
  for i := 0 to elements.count -1 do
  begin
    dist2 := distance(point, elements[i].firstpoint);
    if dist2 < dist1 then
    begin
      dist1  := dist2;
      result := elements[i].firstpoint;
    end;

    dist2 := distance(point, elements[i].lastpoint);
    if dist2 < dist1 then
    begin
      dist1  := dist2;
      result := elements[i].lastpoint;
    end;
  end;
end;

procedure txyppathoptimizer2.execute;
var
  i, j, k: longint;

  a0, a1: double;
  b0, b1: double;
  c0, c1: longint;

  midpoint: txyppoint;
  newpaths: tlist;
  opt: tsimulatedannealing4tsp;
  opt2: txypgraphoptimizer;
  solution: tsimulatedannealingsolution = nil;
  subpath: txypelementlist;
begin
  writeln('k-Chinese Postman Problem Solver');
  {$ifopt D+}
  a0 := 0;
  b0 := 0;
  c0 := 0;
  debug(fpath, a0, b0, c0);
  {$endif}
  {$ifopt D+} printdbg('ECP-OPT', 'Calculate graphs mid-point'); {$endif}
  midpoint.x := 0;
  midpoint.y := 0;
  for i := 0 to fpath.count -1 do
  begin
    midpoint.x := midpoint.x + fpath[i].firstpoint.x + fpath[i].lastpoint.x;
    midpoint.y := midpoint.y + fpath[i].firstpoint.y + fpath[i].lastpoint.y;
  end;
  midpoint.x := midpoint.x / (fpath.count *2);
  midpoint.y := midpoint.y / (fpath.count *2);
  {$ifopt D+} printdbg('ECP-OPT', 'Create subpaths ...'); {$endif}
  newpaths := tlist.create;
  while fpath.count > 0 do
  begin
    subpath := txypelementlist.create;
    subpath.add(fpath.extract(0));
    newpaths.add(subpath);

    i := 0;
    while i < subpath.count do
    begin
      j := fpath.indexof(subpath[i].firstpoint);
      if j <> -1 then
      begin
        subpath.add(fpath.extract(j));
      end;

      j := fpath.indexof(subpath[i].lastpoint);
      if j <> -1 then
      begin
        subpath.add(fpath.extract(j));
      end;

      inc(i);
    end;
  end;
  {$ifopt D+} printdbg('ECP-OPT', 'Subgraphs are = ' + inttostr(newpaths.count)); {$endif}


  {$ifopt D+} printdbg('ECP-OPT', 'Find walk on subpaths'); {$endif}
  setlength(solution, newpaths.count);
  for i := 0 to high(solution) do
  begin
    solution[i] := nearpoint(midpoint, txypelementlist(newpaths[i]));
  end;
  {$ifopt D+} printdbg('ECP-OPT', 'Optimize walk on subpaths'); {$endif}
  opt := tsimulatedannealing4tsp.create;
  opt.initialtemperature := 100;
  opt.coolingrate := 0.001;
  opt.executiontime := 10;
  opt.execute(solution);
  opt.destroy;
  {$ifopt D+} printdbg('ECP-OPT', 'Create circuit...'); {$endif}
  for i := 0 to high(solution) do
  begin
    {$ifopt D+} printdbg('ECP-OPT', '------------------------------'); {$endif}
    for j := 0 to newpaths.count -1 do
    begin
      subpath := txypelementlist(newpaths[j]);

      k := subpath.indexof(solution[i]);
      if k <> -1 then
      begin
        opt2 := txypgraphoptimizer.create(subpath);
        opt2.execute(solution[i]);
        opt2.destroy;
        while subpath.count > 0 do
        begin
          fpath.add(subpath.extract(0));
        end;
        break;
      end;
    end;
  end;
  //
  setlength(solution, 0);
  for i := 0 to newpaths.count -1 do
    txypelementlist(newpaths[i]).destroy;
  newpaths.destroy;
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

