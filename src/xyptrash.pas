{
  Description: XY-Plot trash unit.

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

unit xyptrash;

{$mode objfpc}

interface

uses
  xypmath, xypnodes, xypoptimizer, xyppaths;

type
  // txyppathpreoptimizer_trash

  txyppathpreoptimizer_trash = class
  private
    fpath: txypelementlist;
    function getfirst(const p: txyppoint; var index: longint): longint;
    function getlast (const p: txyppoint; var index: longint): longint;
  public
    constructor create(path: txypelementlist);
    destructor destroy; override;
    procedure execute;
  end;

  // txyppathsaoptimizer_trash

  txyppathsaoptimizer_trash = class
  private
    fnodes: txypnodelist;
    fpath: txypelementlist;
  public
    constructor create(path: txypelementlist);
    destructor destroy; override;
    procedure execute;
  end;

  // txypsasolution_trash

  txypsasolution_trash = array of txyppoint;

  // tsimulatedannealing_trash

  tsimulatedannealing_trash = class
  private
    fcoolingrate: double;
    ftemperature: double;
    procedure createsolution(var neighboursolution: txypsasolution_trash);
    procedure copysolution(source: txypsasolution_trash; var dest: txypsasolution_trash);
    function getdistance(solution: txypsasolution_trash): longint;
    function acceptanceprobability(energy, neighbourenergy: longint; temperature: double): double;
  public
    constructor create;
    destructor destroy; override;
    procedure execute(var bestsolution: txypsasolution_trash);
  end;

implementation

// txyppathpreoptimizer_trash

constructor txyppathpreoptimizer_trash.create(path: txypelementlist);
begin
  inherited create;
  fpath := path;
end;

destructor txyppathpreoptimizer_trash.destroy;
begin
  inherited destroy;
end;

function txyppathpreoptimizer_trash.getfirst(const p: txyppoint; var index: longint): longint;
var
  i: longint;
begin
  result := 0;
  index := -1;
  for i := 0 to fpath.count -1 do
    if fpath.items[i].firstpoint = p then
    begin
      inc(result);
      index := i;
    end
end;

function txyppathpreoptimizer_trash.getlast(const p: txyppoint; var index: longint): longint;
var
  i: longint;
begin
  result := 0;
  index := -1;
  for i := 0 to fpath.count -1 do
    if fpath.items[i].lastpoint = p then
    begin
      inc(result);
      index := i;
    end
end;

procedure txyppathpreoptimizer_trash.execute;
var
  i, j, ki, kj: longint;
  elem: txypelement;
  subpath: txypelementpath;
  newpath: txypelementlist;
begin
  newpath := txypelementlist.create;
  while fpath.count > 0 do
  begin
    // create new subpath
    subpath := txypelementpath.create;
    subpath.add(fpath.extract(0));

    elem := subpath.items[0];
    repeat
      i := getfirst(elem.lastpoint, ki);
      j := getlast (elem.lastpoint, kj);
      if (i + j) = 1 then
      begin
        if i = 1 then
          elem := fpath.extract(ki)
        else
          if j = 1 then
          begin
            elem := fpath.extract(kj);
            elem.invert;
          end;
        subpath.add(elem);
      end;
    until (i + j) <> 1;

    elem := subpath.items[0];
    repeat
      i := getlast (elem.firstpoint, ki);
      j := getfirst(elem.firstpoint, kj);
      if (i + j) = 1 then
      begin
        if i = 1 then
          elem := fpath.extract(ki)
        else
          if j = 1 then
          begin
            elem := fpath.extract(kj);
            elem.invert;
          end;
        subpath.add(elem);
      end;
    until (i + j) <> 1;
    // store new subpath
    newpath.add(subpath);
  end;

  while newpath.count > 0 do
    fpath.add(newpath.extract(0));
  newpath.destroy;
end;

// txyppathsaoptimizer_trash

constructor txyppathsaoptimizer_trash.create(path: txypelementlist);
begin
  inherited create;
  fnodes := txypnodelist.create;
  fpath := path;
end;

destructor txyppathsaoptimizer_trash.destroy;
begin
  fnodes.destroy;
  inherited destroy;
end;

procedure txyppathsaoptimizer_trash.execute;
var
  i, j: longint;
  solution: txypsasolution_trash;
  preopt0: txyppathsaoptimizer_trash;
  preopt1: txyppathoptimizer;
  opt: tsimulatedannealing_trash;

  p1, p2: txyppoint;
  newpath: txypelementlist;

  a0, a1: double;
  b0, b1: double;
  c0, c1: longint;

begin
  {$ifopt D+}
  a0 := 0;
  b0 := 0;
  c0 := 0;
  debug(fpath, a0, b0, c0);
  {$endif}
  preopt0 := txyppathpreoptimizer_trash.create(fpath);
  preopt0.execute;
  preopt0.destroy;
  {$ifopt D+}
  a1 := 0;
  b1 := 0;
  c1 := 0;
  debug(fpath, a1, b1, c1);
  printdbg('OPTIMIZER', format('INK DISTANCE     %12.2f mm (%12.2f mm)', [a1, a0]));
  printdbg('OPTIMIZER', format('TRAVEL DISTANCE  %12.2f mm (%12.2f mm)', [b1, b0]));
  printdbg('OPTIMIZER', format('PEN RAISES       %12.0u    (%12.0u   )', [c1, c0]));
  {$endif}
  //
  //
  //
  {$ifopt D+}
  a0 := 0;
  b0 := 0;
  c0 := 0;
  debug(fpath, a0, b0, c0);
  {$endif}
  setlength(solution, fpath.count * 2);

  i := 0;
  for j := 0 to fpath.count -1 do
  begin
    solution[i    ] := fpath[j].firstpoint;
    solution[i + 1] := fpath[j].lastpoint;
    inc(i, 2);
  end;

  writeln('Optimizer start ... ');
  opt := tsimulatedannealing_trash.create;
  opt.execute(solution);
  opt.destroy;
  writeln('Optimizer end. ');


  writeln('Print circuit ... ');
  newpath := txypelementlist.create;

  i := 0;
  while i < system.length(solution) do
  begin
    p1 := solution[i];
    p2 := solution[i + 1];

    j := fpath.indexof(p1, p2);
    if j <> -1 then
    begin
      newpath.add(fpath.extract(j));
    end else
    begin
      j := fpath.indexof(p2, p1);
      if j <> -1 then
      begin
        fpath[j].invert;
        newpath.add(fpath.extract(j));
      end;
    end;
    inc(i, 2);
  end;
  setlength(solution, 0);

  if fpath.count > 0 then
  begin
    writeln('FATAL ERROR-4');
  end;

  while newpath.count > 0 do
  begin
    fpath.add(newpath.extract(0));
  end;
  newpath.destroy;
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

constructor tsimulatedannealing_trash.create;
begin
  inherited create;
  randomize;
  ftemperature := 50;     // set initial temp
  fcoolingrate := 0.001; // cooling rate
end;

destructor tsimulatedannealing2.destroy;
begin
  inherited destroy;
end;

function tsimulatedannealing2.acceptanceprobability(energy, neighbourenergy: longint; temperature: double): double;
begin
  // if the new solution is better, accept it
  if (neighbourenergy < energy) then
    result := 1.0
  else
    // if the new solution is worse, calculate an acceptance probability
    result := exp((energy - neighbourenergy) / temperature);
end;

procedure tsimulatedannealing2.copysolution(source: tsa2solution; var dest: tsa2solution);
begin
  system.move(source[0], dest[0], system.length(source)*sizeof(source[0]));
end;

function tsimulatedannealing2.getdistance(solution: tsa2solution): longint;
var
  i: longint;
  p: txyppoint;
  res: double = 0;
begin
  p := origin;

  i := 0;
  while i < system.length(solution) do
  begin
    if p <> solution[i] then
    begin
      res := res + distance(p, solution[i]);
    end;
    p := solution[i + 1];

    inc(i, 2);
  end;

  if p <> origin then
  begin
    res := res + distance(p, origin);
  end;
  result := trunc(res);
end;

procedure tsimulatedannealing2.createsolution(var neighboursolution: tsa2solution);
var
  city1: txyppoint;
  city2: txyppoint;
  city3: txyppoint;
  city4: txyppoint;
  cityindex1: longint;
  cityindex2: longint;
  cityindex3: longint;
  cityindex4: longint;
begin

  if random < 0.5 then
  begin
    repeat
      cityindex1 := random(system.length(neighboursolution));
    until (cityindex1 mod 2) = 0;
    cityindex2 := cityindex1 + 1;

    city1 := neighboursolution[cityindex1];
    city2 := neighboursolution[cityindex2];
    neighboursolution[cityindex1] := city2;
    neighboursolution[cityindex2] := city1;
  end else
  begin
    repeat
      cityindex1 := random(system.length(neighboursolution));
    until (cityindex1 mod 2) = 0;
    cityindex2 := cityindex1 + 1;

    repeat
      cityindex3 := random(system.length(neighboursolution));
    until (cityindex3 mod 2) = 0;
    cityindex4 := cityindex3 + 1;

    city1 := neighboursolution[cityindex1];
    city2 := neighboursolution[cityindex2];
    city3 := neighboursolution[cityindex3];
    city4 := neighboursolution[cityindex4];

    neighboursolution[cityindex1] := city3;
    neighboursolution[cityindex2] := city4;
    neighboursolution[cityindex3] := city1;
    neighboursolution[cityindex4] := city2;
  end;

end;

procedure tsimulatedannealing2.execute(var bestsolution: tsa2solution);
var
  currentenergy: longint;
  currentsolution: tsa2solution;
  neighbourenergy: longint;
  neighboursolution: tsa2solution;
  starttime: tdatetime;
begin
  // initialize intial solution
  setlength(currentsolution, system.length(bestsolution));
  copysolution(bestsolution, currentsolution);
  writeln('Current Solution = ', getdistance(currentsolution));
  // set as current best
  // setlength(bestsolution, system.length(graph));
  // copysolution(currentsolution, bestsolution);
  // set as new solution
  setlength(neighboursolution, system.length(bestsolution));
  // loop until system has cooled
  starttime := now;
  while secondsbetween(now, starttime) < 15 do
  // while ftemperature > 0 do
  begin
    // create new neighbour tour
    copysolution(currentsolution, neighboursolution);
    createsolution(neighboursolution);

    // get energy of solutions
    currentenergy := getdistance(currentsolution);
    neighbourenergy := getdistance(neighboursolution);
    // decide if we should accept the neighbour
    if acceptanceprobability(currentenergy, neighbourenergy, ftemperature) > random then
    begin
      copysolution(neighboursolution, currentsolution);
    end;
    // keep track of the best solution found
    if getdistance(currentsolution) < getdistance(bestsolution) then
    begin
      copysolution(currentsolution, bestsolution);
      writeln('Current Solution = ', getdistance(currentsolution));
      starttime := now;
    end;
    // cool system
    ftemperature := ftemperature * (1 - fcoolingrate);
  end;
  writeln('Best Solution = ', getdistance(bestsolution));
  setlength(neighboursolution, 0);
  setlength(currentsolution, 0);
end;



end.

