{
  Description: XY-Plot simulated annealing optimizer class.

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

unit xypsimulatedannealing;

{$mode objfpc}

interface

uses
  classes, dateutils, sysutils, xypmath;

type
  // tsimulatedannealingsolution

  tsimulatedannealingsolution = array of txyppoint;

  // tsimulatedannealing

  tsimulatedannealing = class
  private
    fcoolingrate: double;
    fexecutiontime: longint;
    finitialtemperature: double;
    function getenergy(solution: tsimulatedannealingsolution): single; virtual abstract;
    procedure getsolution(solution: tsimulatedannealingsolution); virtual abstract;
    procedure copysolution(source, dest: tsimulatedannealingsolution);
    function acceptanceprobability(const energy, neighbourenergy, temperature: double): double;
  public
    constructor create;
    destructor destroy; override;
    procedure execute(bestsolution: tsimulatedannealingsolution);
  published
    property coolingrate: double read fcoolingrate write fcoolingrate;
    property initialtemperature: double read finitialtemperature write finitialtemperature;
    property executiontime: longint read fexecutiontime write fexecutiontime;
  end;

  // tsimulatedannealing4tsp

  tsimulatedannealing4tsp = class(tsimulatedannealing)
  private
    function getenergy(solution: tsimulatedannealingsolution): single; override;
    procedure getsolution(solution: tsimulatedannealingsolution); override;
  end;

  // tsimulatedannealing4oddnodes

  tsimulatedannealing4oddnodes = class(tsimulatedannealing)
  private
    function getenergy(solution: tsimulatedannealingsolution): single; override;
    procedure getsolution(solution: tsimulatedannealingsolution); override;
  end;


implementation

// tsimulatedannealing

constructor tsimulatedannealing.create;
begin
  inherited create;
  fcoolingrate := 0.001; // cooling rate
  fexecutiontime := 10; // seconds
  finitialtemperature := 10; // set initial temp
end;

destructor tsimulatedannealing.destroy;
begin
  inherited destroy;
end;

function tsimulatedannealing.acceptanceprobability(const energy, neighbourenergy, temperature: double): double;
begin
  // if the new solution is better, accept it
  if (neighbourenergy < energy) then
    result := 1.0
  else
    // if the new solution is worse, calculate an acceptance probability
    result := exp((energy - neighbourenergy) / temperature);
end;

procedure tsimulatedannealing.copysolution(source, dest: tsimulatedannealingsolution);
begin
  system.move(source[0], dest[0], system.length(source)*sizeof(source[0]));
end;

(*
procedure tsimulatedannealing.createsolution(var solution: tintegervector);
var
  cost: double;
  data: tintegerlist;
  i, j, k: longint;
begin
  data:= tintegerlist.create;
  for i := 0 to high(foddgraph) do data.add(i);
  (*
  j := 0;
  while data.count > 0 do
  begin
    i := random(data.count -1);
    solution[j]     := data[i];
    solution[j + 1] := data[i + 1];

    data.delete(i + 1);
    data.delete(i);
    inc(j, 2);
  end;
  *)

  k := 0;
  while data.count > 0 do
  begin
    cost := 999999999;
    for i := 1 to data.count -1 do
    begin
      if foddgraph[data[0]][data[i]] < cost then
      begin
        cost := foddgraph[data[0]][data[i]];
        j    := i;
      end;
    end;

    solution[k]     := data[0];
    solution[k + 1] := data[j];
    data.delete(j);
    data.delete(0);
    inc(k, 2);
  end;

  data.destroy;
end;
*)

procedure tsimulatedannealing.execute(bestsolution: tsimulatedannealingsolution);
var
  bestenergy: single;
  currentenergy: single;
  currentsolution: tsimulatedannealingsolution = nil;
  neighbourenergy: single;
  neighboursolution: tsimulatedannealingsolution = nil;
  starttime: tdatetime;
  temperature: double;
begin
  // initialize temperature
  temperature := finitialtemperature;
  // initialize current solution
  setlength(currentsolution, system.length(bestsolution));
  copysolution(bestsolution, currentsolution);
  // initalize best solution
  bestenergy := getenergy(bestsolution);
  // initialize neighboursolution
  setlength(neighboursolution, system.length(bestsolution));
  // loop until system has cooled
  starttime := now;
  while secondsbetween(now, starttime) < fexecutiontime do
  begin
    // create new neighbour solution
    copysolution(currentsolution, neighboursolution);
    getsolution(neighboursolution);
    // get bestenergy of solutions
    currentenergy := getenergy(currentsolution);
    neighbourenergy := getenergy(neighboursolution);
    // decide if we should accept the neighbour
    if acceptanceprobability(currentenergy, neighbourenergy, temperature) > random then
    begin
      copysolution(neighboursolution, currentsolution);
    end;
    // keep track of the best bestsolution found
    currentenergy := getenergy(currentsolution);
    bestenergy := getenergy(bestsolution);
    if currentenergy < bestenergy then
    begin
      copysolution(currentsolution, bestsolution);
      writeln('CurrentSolution = ', currentenergy:0:2);
      starttime := now;
    end;
    // cool system
    temperature := temperature * (1 - fcoolingrate);
  end;
  setlength(neighboursolution, 0);
  setlength(currentsolution, 0);
end;

// tsimulatedannealing4tsp

function tsimulatedannealing4tsp.getenergy(solution: tsimulatedannealingsolution): single;
var
  i: longint = 0;
begin
  result := distance(origin, solution[0]);
  for i := 0 to high(solution) -1 do
  begin
    result := result + distance(solution[i], solution[i + 1]);
  end;
  result := result + distance(solution[high(solution)], origin);
end;

procedure tsimulatedannealing4tsp.getsolution(solution: tsimulatedannealingsolution);
var
  index1: longint;
  index2: longint;
  point1: txyppoint;
  point2: txyppoint;
begin
  index1 := random(system.length(solution));
  index2 := random(system.length(solution));
  point1 := solution[index1];
  point2 := solution[index2];
  solution[index1] := point2;
  solution[index2] := point1;
end;

// tsimulatedannealing4oddnodes

function tsimulatedannealing4oddnodes.getenergy(solution: tsimulatedannealingsolution): single;
var
  i: longint = 0;
begin
  result := 0;
  while i < system.length(solution) do
  begin
    result := result + distance(solution[i], solution[i + 1]);
    inc(i, 2);
  end;
end;

procedure tsimulatedannealing4oddnodes.getsolution(solution: tsimulatedannealingsolution);
var
  index1: longint;
  index2: longint;
  point1: txyppoint;
  point2: txyppoint;
begin
  index1 := random(system.length(solution));
  index2 := random(system.length(solution));
  point1 := solution[index1];
  point2 := solution[index2];
  solution[index1] := point2;
  solution[index2] := point1;
end;


end.

