{
  Description: XY-Plot utils unit.

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

unit xyputils;

{$mode objfpc}

interface

uses
  fgl, classes, sysutils;

type
  tintegerlist = specialize tfpglist<integer>;
  tdoublelist  = specialize tfpglist<double>;
  tsinglelist  = specialize tfpglist<single>;

function  crc8(var buffer; count: longint): byte;
procedure clearbit(var value: byte; index: longint);
procedure setbit(var value: byte; index: longint);
procedure putbit(var value: byte; index: longint; state: boolean);
function  getbit(value: byte; index: longint): byte;

procedure printdbg(const s1, s2: string);

function parseaddresses(const s: string): string;
function parseport(const s: string): longint;

function seconds2str(value: longint): string;
function millis2str(value: longint): string;

procedure sleepmicroseconds(microseconds: longword);


implementation

uses
  {$IFDEF UNIX} baseunix, unix; {$ENDIF}
  {$IFDEF MSWINDOWS} windows; {$ENDIF}

const
  crc8_table: array[0.. 255] of byte = (
    0,  94, 188, 226,  97,  63, 221, 131, 194, 156, 126,  32, 163, 253,  31,  65,
  157, 195,  33, 127, 252, 162,  64,  30,  95,   1, 227, 189,  62,  96, 130, 220,
   35, 125, 159, 193,  66,  28, 254, 160, 225, 191,  93,   3, 128, 222,  60,  98,
  190, 224,   2,  92, 223, 129,  99,  61, 124,  34, 192, 158,  29,  67, 161, 255,
   70,  24, 250, 164,  39, 121, 155, 197, 132, 218,  56, 102, 229, 187,  89,   7,
  219, 133, 103,  57, 186, 228,   6,  88,  25,  71, 165, 251, 120,  38, 196, 154,
  101,  59, 217, 135,   4,  90, 184, 230, 167, 249,  27,  69, 198, 152, 122,  36,
  248, 166,  68,  26, 153, 199,  37, 123,  58, 100, 134, 216,  91,   5, 231, 185,
  140, 210,  48, 110, 237, 179,  81,  15,  78,  16, 242, 172,  47, 113, 147, 205,
   17,  79, 173, 243, 112,  46, 204, 146, 211, 141, 111,  49, 178, 236,  14,  80,
  175, 241,  19,  77, 206, 144, 114,  44, 109,  51, 209, 143,  12,  82, 176, 238,
   50, 108, 142, 208,  83,  13, 239, 177, 240, 174,  76,  18, 145, 207,  45, 115,
  202, 148, 118,  40, 171, 245,  23,  73,   8,  86, 180, 234, 105,  55, 213, 139,
   87,   9, 235, 181,  54, 104, 138, 212, 149, 203,  41, 119, 244, 170,  72,  22,
  233, 183,  85,  11, 136, 214,  52, 106,  43, 117, 151, 201,  74,  20, 246, 168,
  116,  42, 200, 150,  21,  75, 169, 247, 182, 232,  10,  84, 215, 137, 107,  53);

function crc8(var buffer; count: longint): byte;
var
  data: array[0.. $FFFF] of byte absolute buffer;
  i: longint;
begin
  result := 0;
  for i := 0 to count -1 do
  begin
   result := (crc8_table[(result xor data[i])]);
  end;
end;

procedure clearbit(var value: byte; index: longint);
begin
  value := value and ((byte(1) shl index) xor high(byte));
end;

procedure setbit(var value: byte; index: longint);
begin
  value:=  value or (byte(1) shl index);
end;

procedure putbit(var value: byte; index: longint; state: boolean);
begin
  value := (value and ((byte(1) shl index) xor high(byte))) or (byte(state) shl index);
end;

function getbit(value: byte; index: longint): byte;
begin
  result := (value shr index) and (byte(1));
end;

{$IFDEF UNIX}

procedure sleepmicroseconds(microseconds: longword);
var
  res: longint;
  timeout: ttimespec;
  timeoutresult: ttimespec;
begin
  timeout.tv_sec := (microseconds div 1000000);
  timeout.tv_nsec := 1000*(microseconds mod 1000000);
  repeat
    res := fpnanosleep(@timeout, @timeoutresult);
    timeout := timeoutresult;
  until (res <> -1) or (fpgeterrno <> esyseintr);
end;

{$ENDIF}

{$IFDEF MSWINDOWS}

procedure sleepmicroseconds(microseconds: longword);
var
  start, stop, freq: int64;
begin
  queryperformancecounter(start);
  queryperformancefrequency(freq);
  stop := start + (microseconds*freq) div 1000000;
  while (start > stop) do
  begin
    queryperformancecounter(start);
  end;
end;

{$ENDIF}

function parseaddresses(const s: string): string;
begin
  result := '';
  if pos(':', s) > 1 then
  begin
    result := copy(s, 1, pos(':', s) -1);
  end;
end;

function parseport(const s: string): longint;
begin
  result := 0;
  if pos(':', s) > 1 then
  begin
    trystrtoint(copy(s, pos(':', s) + 1, length(s) - pos(':', s)), result);
  end;
end;

function seconds2str(value: longint): string;
begin
  result := format(' %2.2u:%2.2u:%2.2u',
    [(value div 3600), ((value mod 3600) div 60), ((value mod 3600) mod 60)]);
end;

function millis2str(value: longint): string;
begin
  result := seconds2str(value div 1000);
end;

procedure printdbg(const s1, s2: string);
begin
  writeln(format('%0:10s::%s', [s1, s2]));
end;

end.

