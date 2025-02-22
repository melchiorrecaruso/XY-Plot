{
  Description: XY-Plot about form.

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

unit aboutfrm;

{$mode objfpc}

interface

uses
  classes, controls, dialogs, extctrls, fileutil, forms,
  graphics, lclintf, lresources, stdctrls, sysutils;

type

  { taboutform }

  taboutform = class(tform)
    aboutcopyrigthlb: tlabel;
    aboutdescriptionlb: tlabel;
    aboutimage: timage;
    aboutlicenselb: tlabel;
    aboutlinklb: tlabel;
    aboutnamelb: tlabel;
    aboutversionlb: tlabel;
    procedure aboutlinklbclick(sender: tobject);
    procedure aboutlinklbmouseleave(sender: tobject);
    procedure aboutlinklbmousemove(sender: tobject;
      shift: tshiftstate; x, y: integer);
  private
  public
  end;

var
  aboutform: taboutform;

implementation

{$R *.lfm}

{ taboutform }

procedure taboutform.aboutlinklbclick(sender: tobject);
begin
  openurl('https://github.com/melchiorrecaruso/xy-plot');
end;

procedure taboutform.aboutlinklbmouseleave(sender: tobject);
begin
  aboutlinklb.font.color := cldefault;
end;

procedure taboutform.aboutlinklbmousemove(sender: tobject; shift: tshiftstate; x, y: integer);
begin
  aboutlinklb.font.color := clblue;
end;

end.

