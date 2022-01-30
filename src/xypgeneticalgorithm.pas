{
  Description: XY-Plot genetic optimizer class.

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

unit xypgeneticalgorithm;

{$mode objfpc}

interface

uses
  classes, math, sysutils, xypmath, xyputils;

type
  // tperson class

  tperson = class(tobject)
  public
    cost: double;
    genome: txyppolygonal;
    population: longint;
    procedure gen_genome0;
    procedure gen_genome1;
    procedure gen_genome2;
    procedure gen_genome3;
    procedure gen_genome4;
  public
    constructor create; overload;
    constructor create(parent0, parent1: tperson); overload;
    destructor destroy; override;
    procedure marktorecalculate;
    function isequal(person: tperson): boolean;
    procedure calculatecost;
  end;

  // tpopulation class

  tpopulation = class(tlist)
  public
    constructor create;overload;
    destructor destroy; override;
    procedure add(p: tperson);
    procedure marktorecalculate;
    function hasperson(person: tperson): boolean;
  end;

  // tpopulations class

  tpopulations = class(tlist)
  public
    currentage: longint;
    currentpopulation: longint;
    improvements: longint;
  public
    constructor create; overload;
    destructor destroy; override;
    procedure live;
    procedure marktorecalculate;
  end;

  // toptimizer class

  txyppathoptimizer3 = class
  private
    fworld: tpopulations;
  public
    constructor create;
    destructor destroy; override;
    procedure execute;
  end;

var
  body: txyppolygonal;
  bestbody: txyppolygonal;
  bestcost: double = 999999999;

implementation

var
  mutationprobability: double;

  /// tperson

  constructor tperson.create;
  begin
    genome := txyppolygonal.create;
    case random(5) of
      0: gen_genome0;
      1: gen_genome1;
      2: gen_genome2;
      3: gen_genome3;
      4: gen_genome4;
    end;
    cost := 0;
  end;

  procedure tperson.gen_genome0;
  var
    i, j: longint;
    clone: txyppolygonal;
  begin
    clone:= txyppolygonal.create;
    for i := 0 to body.count -1 do
      clone.add(body[i]);

    while clone.count > 0 do
    begin
      cost := 999999999;

      for i := 1 to clone.count -1 do
      begin
        if distance(clone[0], clone[i]) < cost then
        begin
          cost := distance(clone[0], clone[i]);
          j    := i;
        end;
      end;

      genome.add(clone[0]);
      genome.add(clone[j]);
      clone.delete(j);
      clone.delete(0);
    end;
    clone.destroy;
  end;

  procedure tperson.gen_genome1;
  var
    i, j: longint;
    clone: txyppolygonal;
  begin
    clone:= txyppolygonal.create;
    for i := 0 to body.count -1 do
      clone.add(body[i]);

    while clone.count > 0 do
    begin
      cost := 999999999;

      for i := 0 to clone.count -2 do
      begin
        if distance(clone[clone.count -1], clone[i]) < cost then
        begin
          cost := distance(clone[clone.count -1], clone[i]);
          j    := i;
        end;
      end;

      genome.add(clone[clone.count -1]);
      genome.add(clone[j]);
      clone.delete(clone.count -1);
      clone.delete(j);
    end;
    clone.destroy;
  end;

  procedure tperson.gen_genome2;
  var
    i, j: longint;
    clone: txyppolygonal;
    p: txyppoint;
  begin
    clone:= txyppolygonal.create;
    for i := 0 to body.count -1 do
      clone.add(body[i]);

    p.x := 0;
    p.y := 0;
    while clone.count > 0 do
    begin
      cost := 999999999;

      for i := 0 to clone.count -1 do
      begin
        if distance(p, clone[i]) < cost then
        begin
          cost := distance(p, clone[i]);
          j    := i;
        end;
      end;
      p := clone[j];

      genome.add(p);
      clone.delete(j);
    end;
    clone.destroy;
  end;

  procedure tperson.gen_genome3;
  var
    i, j, k: longint;
    clone: txyppolygonal;
  begin
    clone:= txyppolygonal.create;
    for i := 0 to body.count -1 do
      clone.add(body[i]);

    while clone.count > 0 do
    begin
      cost := 999999999;

      k := random(clone.count);
      for i := 0 to k - 1 do
      begin
        if distance(clone[k], clone[i]) < cost then
        begin
          cost := distance(clone[k], clone[i]);
          j    := i;
        end;
      end;

      for i := k + 1 to clone.count -1 do
      begin
        if distance(clone[k], clone[i]) < cost then
        begin
          cost := distance(clone[k], clone[i]);
          j    := i;
        end;
      end;

      genome.add(clone[k]);
      genome.add(clone[j]);
      clone.delete(max(k, j));
      clone.delete(min(k, j));
    end;
    clone.destroy;
  end;

  procedure tperson.gen_genome4;
  var
    i: longint;
    clone: txyppolygonal;
  begin
    clone:= txyppolygonal.create;
    for i := 0 to body.count -1 do
      clone.add(body[i]);

    while clone.count > 0 do
    begin
      i := random(clone.count);
      genome.add(clone[i]);
      clone.delete(i);
    end;
    clone.destroy;
  end;

  constructor tperson.create(parent0, parent1: tperson);
  var
    gene0: longint;
    gene1: longint;

    point0: txyppoint;
    point1: txyppoint;

    parents: array[0..1] of tperson;
    parentindex: longint;

  begin
    genome := txyppolygonal.create;

    parents[0]  := parent0;
    parents[1]  := parent1;
    parentindex := random(2);
    for gene0 := 0 to parents[parentindex].genome.count -1 do
      genome.add(parents[parentindex].genome[gene0]);

    // Mutation
    for gene0 := 0 to genome.count -1 do
      if random < mutationprobability then
      begin
        gene1 := trunc(random * genome.count);
               point0 := genome[gene0];
               point1 := genome[gene1];
        genome[gene0] := point1;
        genome[gene1] := point0;
      end;

    cost := 0;
  end;

  destructor tperson.destroy;
  begin
    genome.destroy;
    inherited destroy;
  end;

  procedure tperson.marktorecalculate;
  begin
    cost := 0;
  end;

  function tperson.isequal(person: tperson): boolean;
  var
    i: longint;
  begin
    result := false;
    for i := 0 to genome.count -1 do
    begin
      if genome[i] <> person.genome[i] then exit;
    end;
    result := true;
  end;

  procedure tperson.calculatecost;
  var
    i: longint;
  begin
    i := 0;
    while i < genome.count do
    begin
      cost := cost + distance(genome[i], genome[i + 1]);
      inc(i, 2);
    end;
  end;

  /// tpopulation

  constructor tpopulation.create;
  begin
    inherited create;
  end;

  procedure tpopulation.add(p: tperson);
  var
    i: longint;
  begin
    i := 0;
    while (i < count) and (tperson(items[i]).cost < p.cost) do
    begin
      inc(i);
    end;
    insert(i, p);
  end;

  procedure tpopulation.marktorecalculate;
  begin
    while count > 1 do
    begin
      tperson(extract(last)).destroy;
    end;
    if count > 0 then tperson(first).marktorecalculate;
  end;

  destructor tpopulation.destroy;
  begin
    while count > 0 do
    begin
      tperson(extract(first)).destroy;
    end;
    inherited destroy;
  end;

  function tpopulation.hasperson(person: tperson): boolean;
  var
    i: longint;
  begin
    result := true;
    for i := 0 to count -1 do
    begin
      if person.isequal(tperson(items[i])) then exit;
    end;
    result := false;
  end;

  /// tpopulations

  constructor tpopulations.create;
  begin
    inherited create;
    currentpopulation := 0;
    currentage        := 0;
    improvements      := 0;
    while count < 15 do
    begin
      add(tpopulation.create);
    end;
  end;

  procedure tpopulations.live;
  var
    fullsize: longint;
    halfsize: longint;
    population1: tpopulation;
    population2: tpopulation;
    parent1: tperson;
    parent2: tperson;
    person: tperson;
  var
    i, j: longint;
  begin
    fullsize := 1;
    halfsize := 1;

    if currentage mod 2000 = 0 then
    begin
      for i := 0 to count -1 do
      begin
        tpopulation(items[i]).marktorecalculate;
      end;
      inc(currentage);
    end;

    population1 := tpopulation(items[currentpopulation]);

    if population1.count = 0 then
    begin
      person := tperson.create;
      //writeln('generate random creature ...');
    end else
      if tperson(population1.first).cost = 0 then
      begin
        person := tperson(population1.extract(population1.first));
        //writeln('recalculate creature estimation ...');
      end else
      begin
        repeat
          repeat
            population2 := tpopulation(items[max(0, min(currentpopulation + random(3) -1, count -1))]);
          until population2.count > 0;
          parent1 := tperson(population1.items[random(population1.count)]);
          parent2 := tperson(population2.items[random(population2.count)]);
        until parent1 <> parent2;

        repeat
          person := tperson.create(parent1, parent2);
          if population1.hasperson(person) then
          begin
            freeandnil(person);
            mutationprobability := mutationprobability + (0.0001 / body.count);
          end else
          begin
            mutationprobability := mutationprobability - (0.0001 / body.count);
          end;
        until person <> nil;
        //writeln('creatures optimization ...');
      end;

    begin
      person.population := currentpopulation + 1;
      person.calculatecost;
    end;

    begin
      if population1.count > 0 then
      begin
        if tperson(population1.first).cost > 0 then inc(currentage);
        if tperson(population1.first).cost > person.cost then inc(improvements);
      end;
      population1.add(person);

      if population1.count > 0 then
      begin
        bestcost := min(bestcost, tperson(population1.first).cost);
      end;

      if (population1.count > fullsize) and (tperson(population1.first).cost > 0) then
      begin
        while population1.count > halfsize do
        begin
          tperson(population1.extract(population1.last)).destroy;
        end;
      end;
    end;

    if currentpopulation = 14 then
    begin
      writeln(format('%10d turn, %5d jumps (%2.1f%%), %8.0f mm',
        [currentage, improvements, improvements / (currentage + 1) * 100, bestcost]));
    end;
    currentpopulation := (currentpopulation + 1) mod 15;
  end;

  procedure tpopulations.marktorecalculate;
  var
    i: longint;
  begin
    for i := 0 to count -1 do
    begin
      tpopulation(items[i]).marktorecalculate;
    end;
    currentpopulation := 0;
    currentage        := 0;
    improvements      := 0;
  end;

  destructor  tpopulations.destroy;
  begin
    while count > 0 do
    begin
      tpopulation(extract(first)).free;
    end;
    inherited destroy;
  end;

  /// txyppathoptimizer3

  constructor txyppathoptimizer3.create;
  begin
    inherited create;
    randomize;

    fworld   := tpopulations.create;
  end;

  destructor txyppathoptimizer3.destroy;
  begin
    body.destroy;
    fworld.free;
    inherited destroy;
  end;

  procedure txyppathoptimizer3.execute;
  begin
    bestcost := 99999999;
    mutationprobability := 0.8 / body.count;

    writeln('optimization start... ', mutationprobability:0:5);
    while fworld.currentage < 1000000 do
    begin

      //writeln('CurrentAge = ', fworld.currentage);
      //writeln('CurrentPopulation = ', fworld.currentpopulation + 1);
      //writeln('Improvements = ', (fworld.improvements / (fworld.currentage + 1) * 100):0:0);

      fworld.live;
    end;

    writeln('optimization end.');
  end;

end.

