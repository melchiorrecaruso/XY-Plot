{
  Description: XY-Plot main form.

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

unit mainfrm;

{$mode objfpc}

{*$DEFINE ETHERNET}

interface

uses
  bgrabitmap, bgrasvg, bgrabitmaptypes, bgragradientscanner, bgravirtualscreen,
  bgrapath, buttons, classes, comctrls, controls, dateutils, dialogs, extctrls,
  forms, graphics, menus, spin, stdctrls, shellctrls, xmlpropstorage, extdlgs,
  dividerbevel, spinex, xypdriver, xypfiller, xypoptimizer, xyppaths, xypserial,
  xypsetting, xypsketcher;

type

  { tmainform }

  tmainform = class(tform)
    aboutbtn: tbitbtn;
    sethomebtn: tbitbtn;
    connectbtn: tbitbtn;
    portcb: tcombobox;
    schedulertimer: tidletimer;
    opendialog: topenpicturedialog;
    stepnumberedt: tfloatspinedit;
    zoomcb: tcombobox;
    btnimages: timagelist;
    propstorage: txmlpropstorage;
    zoomlb: tlabel;
    homebtn: tbitbtn;
    startbtn: tbitbtn;
    controlbvl: tdividerbevel;
    calibrationbvl: tdividerbevel;
    clearbtn: tbitbtn;
    pagesizecb: tcombobox;
    connectionbvl: tdividerbevel;
    controlpnl: tpanel;
    drawingbvl: tdividerbevel;
    editingbvl: tdividerbevel;
    importbtn: tbitbtn;
    pagesizelb: tlabel;
    xdownbtn: tbitbtn;
    xupbtn: tbitbtn;
    mainformbevel: tbevel;
    editingbtn: tbitbtn;
    editingcb: tcombobox;
    editinhlb: tlabel;
    editingedt: tfloatspinedit;
    editingvaluelb: tlabel;
    pagesizebvl: tdividerbevel;
    zdownbtn: tbitbtn;
    zupbtn: tbitbtn;
    addresslb: tlabel;
    ydownbtn: tbitbtn;
    yupbtn: tbitbtn;
    savedialog: tsavedialog;
    screen: tbgravirtualscreen;
    stepnumberlb: tlabel;
    // FORM EVENTS
    procedure formcreate (sender: tobject);
    procedure formdestroy(sender: tobject);
    procedure formclose(sender: tobject; var closeaction: tcloseaction);
    procedure propstoragerestoreproperties(sender: tobject);
    // CONNECTION
    procedure portcbgetitems(sender: tobject);
    procedure connectbtnclick(sender: tobject);
    // CALIBRATION
    procedure motorbtnclick(sender: tobject);
    procedure movetohomemiclick(sender: tobject);
    procedure sethomebtnclick(sender: tobject);
    // IMPORT/CLEAR
    procedure importbtnclick(sender: tobject);
    procedure clearbtnclick(sender: tobject);
    // EDITING
    procedure editingcbchange(sender: tobject);
    procedure editingbtnclick(sender: tobject);
    // PAGE SIZE
    procedure pagesizebtnclick(sender: tobject);
    // CONTROL
    procedure startmiclick(sender: tobject);
    // ZOOM
    procedure changezoombtnclick(sender: tobject);
    // ABOUT POPUP
    procedure aboutmiclick(sender: tobject);
    // VIRTUAL SCREEN EVENTS
    procedure screenredraw(sender: tobject; bitmap: tbgrabitmap);
    // MOUSE EVENTS
    procedure imagemouseup  (sender: tobject; button: tmousebutton; shift: tshiftstate; x, y: integer);
    procedure imagemousedown(sender: tobject; button: tmousebutton; shift: tshiftstate; x, y: integer);
    procedure imagemousemove(sender: tobject; shift: tshiftstate; x, y: integer);
    // schedulertimer EVENTS
    procedure schedulerstart(sender: tobject);
    procedure schedulerstop(sender: tobject);
    procedure schedulertick(sender: tobject);
  private
    mouseisdown: boolean;
    movex: longint;
    movey: longint;
    page: txypelementlist;
    pageheight: longint;
    pagewidth: longint;
    pageformat: string;
    px: longint;
    py: longint;
    screenimage: tbgrabitmap;
    schedulerlist: tstringlist;
    scheduling: boolean;
    {$ifdef ETHERNET}
    procedure streamingonconnect(asocket: tlsocket);
    procedure streamingondisconnect(asocket: tlsocket);
    procedure streamingonreceive(asocket: tlsocket);
    {$else}
    procedure streamingonconnect;
    procedure streamingondisconnect;
    {$endif}
    procedure streamingonstart;
    procedure streamingonstop;
    procedure streamingontick;
    // ---
    procedure onscreenthreadstart;
    procedure onscreenthreadstop;
    procedure lockinternal(value: boolean);
    function getzoom: double;
  end;

  tscreenthread = class(tthread)
  private
    fonstart: tthreadmethod;
    fonstop: tthreadmethod;
  public
    constructor create;
    destructor destroy; override;
    procedure execute; override;
  public
    property onstart: tthreadmethod read fonstart write fonstart;
    property onstop:  tthreadmethod read fonstop  write fonstop;
  end;

var
  mainform: tmainform;
  screenthread: tscreenthread = nil;
  setting: txypsetting;
  stream: tmemorystream;

implementation

{$R *.lfm}

uses
  aboutfrm, importfrm, math, sysutils, xypdxfreader, xypsvgreader, xyputils;

// SCREEN THREAD

constructor tscreenthread.create;
begin
  freeonterminate := true;
  inherited create(true);
end;

destructor tscreenthread.destroy;
begin
  inherited destroy;
end;

procedure tscreenthread.execute;
var
  i: longint;
  elem: txypelement;
  x0, x1: longint;
  y0, y1: longint;
  path: tbgrapath;
  zoom: double;
begin
  if assigned(fonstart) then
    synchronize(fonstart);

  with mainform do
  begin
    zoom := getzoom;
    screenimage.setsize(trunc(pagewidth*zoom), trunc(pageheight*zoom));

    x0 := 0;
    y0 := 0;
    x1 := screenimage.width;
    y1 := screenimage.height;
    screenimage.fillrect(x0, y0, x1, y1, bgra(255, 255, 255), dmset);

    x0 := 0;
    y0 := 0;
    x1 := x0+trunc(pagewidth *zoom);
    y1 := y0+trunc(pageheight*zoom);
    screenimage.fillrect(x0, y0, x1, y1, bgra(255,   0,   0), dmset);

    x0 := 1;
    y0 := 1;
    x1 := x0+trunc(pagewidth *zoom)-2;
    y1 := y0+trunc(pageheight*zoom)-2;
    screenimage.fillrect(x0, y0, x1, y1, bgra(255, 255, 255), dmset);

    // updtare preview ...
    x0 := 0;
    y0 := trunc(pageheight*zoom);

    path := tbgrapath.create;
    for i := 0 to page.count -1 do
    begin
      elem := page.items[i];
      elem.mirrorx;
      elem.scale(zoom);
      elem.move(x0, y0);
      begin
        path.beginpath;
        elem.interpolate(path);
        path.stroke(screenimage, bgra(0, 0, 0), 1.5);
      end;
      elem.move(-x0, -y0);
      elem.scale(1/zoom);
      elem.mirrorx;
    end;
    path.destroy;
    screen.redrawbitmap;
  end;
  if assigned(fonstop) then
    synchronize(fonstop);
end;

// FORM EVENTS

procedure tmainform.formcreate(sender: tobject);
begin
  defaultformatsettings.decimalseparator := '.';
  // initialize properties storage
  propstorage.filename := getclientsettingfilename(false);
  // create serial stream
  {$ifdef ETHERNET}
  serialstream := tltcpcomponent.create(nil);
  {$else}
  serialstream := txypserialstream.create;
  {$endif}
  serialstream.onconnect    := @streamingonconnect;
  serialstream.ondisconnect := @streamingondisconnect;
  // create setting loader
  setting := txypsetting.create;
  setting.load(getsettingfilename(true));
  // create memory stream
  stream := tmemorystream.create;
  // create driver
  driver := txypdriver.create(setting, stream);
  {$ifopt D+}
  driverdebug(driver);
  {$endif}
  // create page
  page := txypelementlist.create;
  // create screen bitmap image
  screenimage := tbgrabitmap.create(screen.width, screen.height);
  // create sheduler list
  schedulerlist := tstringlist.create;
  schedulertimer.enabled := false;
end;

procedure tmainform.formdestroy(sender: tobject);
begin
  schedulertimer.enabled := false;
  // destroy
  driver.destroy;
  page.destroy;
  propstorage.save;
  serialstream.destroy;
  setting.destroy;
  schedulerlist.destroy;
  screenimage.destroy;
  stream.destroy;
end;

procedure tmainform.formclose(sender: tobject; var closeaction: tcloseaction);
begin
  closeaction := canone;
  if schedulertimer.enabled then
  begin
    messagedlg('XY-Plot', 'Please wait for the last operation to finish !', mterror, [mbok], 0);
  end else
  begin
    if serialstream.connected then
      messagedlg('XY-Plot', 'Please disconnect before closing window !', mterror, [mbok], 0)
    else
      closeaction := cafree;
  end;
end;

// CONNECTION

procedure tmainform.portcbgetitems(Sender: TObject);
var
  ports: tstringlist;
begin
  {$ifdef ETHERNET}

  {$else}
  portcb.items.clear;
  ports := serialportnames;
  while ports.count > 0 do
  begin
    portcb.items.add(ports[0]);
    ports.delete(0);
  end;
  ports.destroy;
  {$endif}
end;

procedure tmainform.connectbtnclick(sender: tobject);
begin
  if serialstream.connected then
  begin
    if (driver.xcount1 = 0) and
       (driver.ycount1 = 0) and
       (driver.zcount1 = 0) then
    begin
      {$ifdef ETHERNET}
      serialstream.disconnect(false);
      {$else}
      serialstream.disconnect;
      {$endif}
    end else
      messagedlg('XY-Plot', 'Please move the plotter to origin (Home) before disconnecting !', mterror, [mbok], 0);
  end else
  begin
    {$ifdef ETHERNET}
    serialstream.connect(portcb.text, 8888);
    {$else}
    serialstream.connect(portcb.text)
    {$endif}
  end;
end;

procedure tmainform.propstoragerestoreproperties(sender: tobject);
begin
  // main form updates
  pagesizebtnclick(nil);
  editingcbchange(nil);
  changezoombtnclick(zoomcb);
end;

// CALIBRATION

procedure tmainform.motorbtnclick(sender: tobject);
begin
  if sender = xupbtn   then schedulerlist.add('driver.movex+');
  if sender = xdownbtn then schedulerlist.add('driver.movex-');
  if sender = yupbtn   then schedulerlist.add('driver.movey+');
  if sender = ydownbtn then schedulerlist.add('driver.movey-');
  if sender = zupbtn   then schedulerlist.add('driver.movez+');
  if sender = zdownbtn then schedulerlist.add('driver.movez-');
  schedulertimer.enabled := true;
end;

procedure tmainform.movetohomemiclick(sender: tobject);
begin
  schedulerlist.add('driver.movetoorigin');
  schedulertimer.enabled := true;
end;

procedure tmainform.sethomebtnclick(sender: tobject);
begin
  schedulerlist.add('driver.setorigin');
  schedulertimer.enabled := true;
end;

// DRAWING IMPORT/CLEAR

procedure tmainform.importbtnclick(sender: tobject);
var
  bit: tbgrabitmap;
  filler: txypfiller;
  opt: txyppathoptimizer;
  sk:  txypsketcher;
begin
  if opendialog.execute then
  begin
    lockinternal(false);
    caption := 'XY-Plot - ' + opendialog.filename;
    if opendialog.filterindex = 1 then
    begin
      svg2paths(opendialog.filename, page);
      // optimize
      opt := txyppathoptimizer.create(page);
      opt.execute;
      opt.destroy;
    end else
    if opendialog.filterindex = 2 then
    begin
      dxf2paths(opendialog.filename, page);
      // optimize
      opt := txyppathoptimizer.create(page);
      opt.execute;
      opt.destroy;
    end else
    if opendialog.filterindex = 3 then
    begin
      if importform.showmodal = mrok then
      begin
        bit := tbgrabitmap.create;
        bit.loadfromfile(opendialog.filename);
        if importform.methodcb.itemindex < 3 then
        begin
          case (importform.methodcb.itemindex) of
            0: sk := txypsketchersquare.create(bit);
            1: sk := txypsketcherroundedsquare.create(bit);
            2: sk := txypsketchertriangular.create(bit);
          else sk := txypsketchersquare.create(bit);
          end;
          sk.patternheight := trunc(importform.patternpxse.value);
          sk.patternwidth  := trunc(importform.patternpxse.value);
          sk.pageheight    := importform.patternmmse.value*(bit.height/bit.width);
          sk.pagewidth     := importform.patternmmse.value;
          sk.dotsize       := importform.dotsizese.value;
          sk.update(page);
          sk.destroy;
        end else
          if importform.methodcb.itemindex = 3 then
          begin
            filler := txypfiller.create(bit, importform.dotsizese.value);
            filler.update(page);
            filler.destroy;
          end;

        bit.destroy;
      end;
    end;
    // start schedulertimer
    schedulerlist.add('screen.update');
    schedulertimer.enabled := true;
  end;
end;

procedure tmainform.clearbtnclick(sender: tobject);
begin
  caption := 'XY-Plot';
  page.clear;
  // start schedulertimer
  schedulerlist.add('screen.update');
  schedulertimer.enabled := true;
end;

// DRAWING EDITING

procedure tmainform.editingcbchange(sender: tobject);
begin
  if sender = editingcb then
  begin
    case editingcb.itemindex of
      0: editingedt.value   := 1.0;   // SCALE
      1: editingedt.value   := 0.0;   // X-OFFSET
      2: editingedt.value   := 0.0;   // Y-OFFSET
      3: editingedt.value   := 0.0;   // X-MIRROR
      4: editingedt.value   := 0.0;   // Y-MIRROR
      5: editingedt.value   := 0.0;   // ROTATE
      6: editingedt.value   := 0.0;   // MOVE TO CENTER
      7: editingedt.value   := 0.0;   // MOVE TO ORIGIN
      8: editingedt.value   := 0.0;   // FIT
    end;
  end;

  case editingcb.itemindex of
    0: editingedt.enabled  := editingbtn.enabled;   // SCALE
    1: editingedt.enabled  := editingbtn.enabled;   // X-OFFSET
    2: editingedt.enabled  := editingbtn.enabled;   // Y-OFFSET
    3: editingedt.enabled  := false;                // X-MIRROR
    4: editingedt.enabled  := false;                // Y-MIRROR
    5: editingedt.enabled  := editingbtn.enabled;   // ROTATE
    6: editingedt.enabled  := false;                // MOVE TO CENTER
    7: editingedt.enabled  := false;                // MOVE TO ORIGIN
    8: editingedt.enabled  := false;                // FIT
  end;
end;

procedure tmainform.editingbtnclick(sender: tobject);
begin
  page.updatepage;
  case editingcb.itemindex of
    0: begin                                        // SCALE
        if editingedt.value > 0 then
          page.scale(editingedt.value);
       end;
    1: page.move (editingedt.value, 0);             // X-OFFSET
    2: page.move (0, editingedt.value);             // Y-OFFSET
    3: page.mirrorx;                                // X-MIRROR
    4: page.mirrory;                                // Y-MIRROR
    5: page.rotate(degtorad(editingedt.value));     // ROTATE
    6: begin                                        // MOVE TO CENTER
         page.movetoorigin;
         page.move((pagewidth  - page.pagewidth )/2,
                   (pageheight - page.pageheight)/2);
       end;
    7: page.movetoorigin;                           // MOVE TO ORIGIN
    8: begin                                        // FIT
         if (page.pagewidth  > 1) and (pagewidth  > 1) and
            (page.pageheight > 1) and (pageheight > 1) then
         begin
           if (pagewidth/page.pagewidth) < (pageheight/page.pageheight) then
             page.scale(pagewidth/page.pagewidth)
           else
             page.scale(pageheight/page.pageheight);
           //RE-FIT
           page.movetoorigin;
           page.move((pagewidth  - page.pagewidth )/2,
                     (pageheight - page.pageheight)/2);
         end;
       end;
  end;
  page.updatepage;
  // start schedulertimer
  schedulerlist.add('screen.update');
  schedulertimer.enabled := true;
end;

// PAGE SIZE

procedure tmainform.pagesizebtnclick(sender: tobject);
begin
  case pagesizecb.itemindex of
    0: begin pagewidth := 1189; pageheight :=  841; pageformat := 'A0'; end; // A0-Landscape
    1: begin pagewidth :=  841; pageheight := 1189; pageformat := 'A0'; end; // A0-Portrait
    2: begin pagewidth :=  841; pageheight :=  594; pageformat := 'A1'; end; // A1-Landscape
    3: begin pagewidth :=  594; pageheight :=  841; pageformat := 'A1'; end; // A1-Portrait
    4: begin pagewidth :=  594; pageheight :=  420; pageformat := 'A2'; end; // A2-Landscape
    5: begin pagewidth :=  420; pageheight :=  594; pageformat := 'A2'; end; // A2-Portrait
    6: begin pagewidth :=  420; pageheight :=  297; pageformat := 'A3'; end; // A3-Landscape
    7: begin pagewidth :=  297; pageheight :=  420; pageformat := 'A3'; end; // A3-Portrait
    8: begin pagewidth :=  297; pageheight :=  210; pageformat := 'A4'; end; // A4-Landscape
    9: begin pagewidth :=  210; pageheight :=  297; pageformat := 'A4'; end; // A4-Portrait
   10: begin pagewidth :=  210; pageheight :=  148; pageformat := 'A5'; end; // A5-Landscape
   11: begin pagewidth :=  148; pageheight :=  210; pageformat := 'A5'; end; // A5-Portrait
  else begin pagewidth :=  420; pageheight :=  297; pageformat := 'A3'; end  // Default
  end;
  {$ifopt D+}
  printdbg('PAGE', format('WIDTH            %12.5u mm', [pagewidth]));
  printdbg('PAGE', format('HEIGHT           %12.5u mm', [pageheight]));
  {$endif}
  changezoombtnclick(zoomcb);
end;

// CONTROL

procedure tmainform.startmiclick(sender: tobject);
begin
  if assigned(driverstreamer) then
  begin
    driverstreamer.terminate;
  end else
  begin
    if stream.size = 0 then
      schedulerlist.add('driver.start')
    else
    begin
      schedulerlist.add('driver.restart');
    end;
    schedulertimer.enabled := true;
  end;
end;

// ZOOM BUTTONS

function tmainform.getzoom: double;
var
  s: string;
begin
  s := zoomcb.items[zoomcb.itemindex];
  while pos('%', s) > 0 do delete(s, pos('%', s), 1);
  while pos(' ', s) > 0 do delete(s, pos(' ', s), 1);
  result := strtoint(s)/100;
end;

procedure tmainform.changezoombtnclick(sender: tobject);
begin
  if (sender = zoomcb) then
  begin
    schedulerlist.add('screen.update');
    schedulerlist.add('screen.fit');
    schedulertimer.enabled := true;
  end;
end;

// ABOUT POPUP

procedure tmainform.aboutmiclick(sender: tobject);
begin
  aboutform.showmodal;
end;

// MOUSE EVENTS

procedure tmainform.imagemousedown(sender: tobject; button: tmousebutton;
  shift: tshiftstate; x, y: integer);
begin
  if button = mbleft then
  begin
    mouseisdown := true;
    px := x - movex;
    py := y - movey;
  end;
end;

procedure tmainform.imagemousemove(sender: tobject;
  shift: tshiftstate; x, y: integer);
begin
  if mouseisdown then
  begin
    movex := x - px;
    movey := y - py;
    screen.redrawbitmap;
  end;
end;

procedure tmainform.imagemouseup(sender: tobject;
  button: tmousebutton; shift: tshiftstate; x, y: integer);
begin
  mouseisdown := false;
end;

procedure tmainform.screenredraw(sender: tobject; bitmap: tbgrabitmap);
begin
  bitmap.putimage(movex, movey, screenimage, dmset);
end;

// LOCK/UNLOCK ROUTINES

procedure tmainform.lockinternal(value: boolean);
begin
  if assigned(driverstreamer) then
  begin
    // connection
    portcb         .enabled := false;
    connectbtn     .enabled := false;
    // calibration
    stepnumberedt  .enabled := false;
    xupbtn         .enabled := false;
    xdownbtn       .enabled := false;
    yupbtn         .enabled := false;
    ydownbtn       .enabled := false;
    zupbtn         .enabled := false;
    zdownbtn       .enabled := false;
    // drawing
    importbtn      .enabled := false;
    clearbtn       .enabled := false;
    // drawing editing
    editingcb      .enabled := false;
    editingbtn     .enabled := false;
    // page sizing
    pagesizecb     .enabled := false;
    // control
    startbtn       .enabled := true;
    homebtn        .enabled := false;
    sethomebtn     .enabled := false;
    // about popup
    aboutbtn       .enabled := false;
    // zoom
    zoomcb         .enabled := false;
    // screen
    screen         .enabled := false;
  end else
  if stream.size = 0 then
  begin
    // connection
    portcb         .enabled := value and (serialstream.connected = false);
    connectbtn     .enabled := value;
    // calibration
    stepnumberedt  .enabled := value and (serialstream.connected);
    xupbtn         .enabled := value and (serialstream.connected);
    xdownbtn       .enabled := value and (serialstream.connected);
    yupbtn         .enabled := value and (serialstream.connected);
    ydownbtn       .enabled := value and (serialstream.connected);
    zupbtn         .enabled := value and (serialstream.connected);
    zdownbtn       .enabled := value and (serialstream.connected);
    // drawing
    importbtn      .enabled := value;
    clearbtn       .enabled := value;
    // drawing editing
    editingcb      .enabled := value;
    editingbtn     .enabled := value;
    // page sizing
    pagesizecb     .enabled := value;
    // control
    startbtn       .enabled := value and (serialstream.connected);
    homebtn        .enabled := value and (serialstream.connected);
    sethomebtn     .enabled := value and (serialstream.connected);
    // about popup
    aboutbtn       .enabled := value;
    // zoom
    zoomcb         .enabled := value;
    // screen
    screen         .enabled := value;
  end else
  begin
    // control
    startbtn       .enabled := true and (serialstream.connected);
    homebtn        .enabled := true and (serialstream.connected);
  end;
  editingcbchange(nil);
  application.processmessages;
end;

// SCREEN THREAD EVENTS

procedure tmainform.onscreenthreadstart;
begin
  // nothing to do
end;

procedure tmainform.onscreenthreadstop;
begin
  screenthread := nil;
  scheduling := false;
end;

// SCHEDULER TIMER

procedure tmainform.schedulerstart(sender: tobject);
begin
  lockinternal(false);
end;

procedure tmainform.schedulerstop(sender: tobject);
begin
  lockinternal(true);
end;

procedure tmainform.schedulertick(sender: tobject);
begin
  if scheduling then
  begin
    // nothing to do
  end else
  if schedulerlist.count > 0 then
  begin
    if ('screen.update' = schedulerlist[0]) then
    begin
      scheduling := true;
      screenthread := tscreenthread.create;
      screenthread.onstart := @onscreenthreadstart;
      screenthread.onstop  := @onscreenthreadstop;
      screenthread.start;
      lockinternal(false);
    end else
    if ('screen.fit' = schedulerlist[0]) then
    begin
      scheduling := true;
      movex := (screen.width  div 2) - trunc((pagewidth /2)*getzoom);
      movey := (screen.height div 2) - trunc((pageheight/2)*getzoom);
      screen.redrawbitmap;
      scheduling := false;
    end else
    if ('driver.start' = schedulerlist[0]) then
    begin
      {$ifopt D+} printdbg('DRIVER', 'START'); {$endif}
      scheduling := true;
      driver.clearstream;
      driver.sync;
      driver.move(page, pagewidth, pageheight);
      driver.movez(trunc(setting.pzup/setting.pzratio));
      driver.move(0, 0, trunc(setting.pzup/setting.pzratio));
      driver.movez(0);
      driverstreamer := txypdriverstreamer.create(stream);
      driverstreamer.onstart := @streamingonstart;
      driverstreamer.onstop  := @streamingonstop;
      driverstreamer.ontick  := @streamingontick;
      driverstreamer.start;
    end else
    if ('driver.restart' = schedulerlist[0]) then
    begin
      {$ifopt D+} printdbg('DRIVER', 'RESTART'); {$endif}
      scheduling := true;
      driverstreamer := txypdriverstreamer.create(stream);
      driverstreamer.onstart := @streamingonstart;
      driverstreamer.onstop  := @streamingonstop;
      driverstreamer.ontick  := @streamingontick;
      driverstreamer.start;
    end else
    if ('driver.setorigin' = schedulerlist[0]) then
    begin
      {$ifopt D+} printdbg('DRIVER', 'SET ORIGIN'); {$endif}
      driver.setorigin;
    end else
    if ('driver.movetoorigin' = schedulerlist[0]) then
    begin
      {$ifopt D+} printdbg('DRIVER', 'MOVE TO ORIGIN'); {$endif}
      scheduling := true;
      driver.clearstream;
      driver.sync;
      driver.movez(trunc(setting.pzup/setting.pzratio));
      driver.move(0, 0, trunc(setting.pzup/setting.pzratio));
      driver.movez(0);
      driverstreamer := txypdriverstreamer.create(stream);
      driverstreamer.onstart := @streamingonstart;
      driverstreamer.onstop  := @streamingonstop;
      driverstreamer.ontick  := @streamingontick;
      driverstreamer.start;
    end else
    if pos('driver.move', schedulerlist[0]) = 1 then
    begin
      {$ifopt D+} printdbg('DRIVER', 'MOVE'); {$endif}
      scheduling := true;
      driver.clearstream;
      driver.sync;
      if (schedulerlist[0] = 'driver.movex+') then
        driver.movex(driver.xcount2 + round(stepnumberedt.value/setting.pxratio));

      if (schedulerlist[0] = 'driver.movex-') then
        driver.movex(driver.xcount2 - round(stepnumberedt.value/setting.pxratio));

      if (schedulerlist[0] = 'driver.movey+') then
        driver.movey(driver.ycount2 + round(stepnumberedt.value/setting.pyratio));

      if (schedulerlist[0] = 'driver.movey-') then
        driver.movey(driver.ycount2 - round(stepnumberedt.value/setting.pyratio));

      if (schedulerlist[0] = 'driver.movez+') then
        driver.movez(driver.zcount2 + round(stepnumberedt.value/setting.pzratio));

      if (schedulerlist[0] = 'driver.movez-') then
        driver.movez(driver.zcount2 - round(stepnumberedt.value/setting.pzratio));

      driverstreamer := txypdriverstreamer.create(stream);
      driverstreamer.onstart := @streamingonstart;
      driverstreamer.onstop  := @streamingonstop;
      driverstreamer.ontick  := @streamingontick;
      driverstreamer.start;
    end;

    schedulerlist.delete(0);
  end else
  begin
    schedulertimer.enabled := false;
  end;
end;

// serial streaming

procedure tmainform.streamingonstart;
begin
  startbtn.caption := 'Stop';
  startbtn.imageindex := 7;
  {$ifopt D+}
  printdbg('STREAMING', 'START');
  printdbg('DRIVER', format('SYNC [X%10.2f] [Y%10.2f] [Z%10.2f] [R%4d]',
    [driver.xcount1*setting.pxratio,
     driver.ycount1*setting.pyratio,
     driver.zcount1*setting.pzratio,
     driver.rcount1]));
  {$endif}
  lockinternal(false);
end;

procedure tmainform.streamingonstop;
begin
  caption := 'XY-Plot';
  {$ifopt D+}
  if driver.rcount1 <> 1 then
  begin
    printdbg('STREAMING', 'ERROR');
  end;
  {$endif}
  driverstreamer := nil;
  {$ifopt D+}
  printdbg('DRIVER', format('SYNC [X%10.2f] [Y%10.2f] [Z%10.2f] [R%4d]',
    [driver.xcount1*setting.pxratio,
     driver.ycount1*setting.pyratio,
     driver.zcount1*setting.pzratio,
     driver.rcount1]));
  printdbg('STREAMING', 'STOP');
  {$endif}
  startbtn.caption := 'Start';
  startbtn.imageindex := 6;
  scheduling := false;
  lockinternal(true);
end;

procedure tmainform.streamingontick;
var
  ratio: int64;
begin
  {$ifopt D+}
  printdbg('DRIVER', format('SYNC [X%10.2f] [Y%10.2f] [Z%10.2f] [R%4d]',
    [driver.xcount1*setting.pxratio,
     driver.ycount1*setting.pyratio,
     driver.zcount1*setting.pzratio,
     driver.rcount1]));
  {$endif}
  try
    ratio := (100 * driverstreamer.position) div driverstreamer.size;
    caption := format('XY-Plot | Progress %u%% | Serial Speed %u kB/sec | Remaining time %s',
      [ratio, driverstreamer.serialspeed, millis2str(driverstreamer.remainingmillis)]);
  except
    caption := ('XY-Plot | Progress ---% | Serial Speed ---kB/sec | Remaining time ---s');
  end;
end;

{$ifdef ETHERNET}
procedure tmainform.streamingonconnect(asocket: tlsocket);
{$else}
procedure tmainform.streamingonconnect;
{$endif}
begin
  {$ifopt D+}
  printdbg('STREAMING', 'CONNECTED');
  {$endif}
  connectbtn.caption := 'Disconnect';
  lockinternal(true);
end;

{$ifdef ETHERNET}
procedure tmainform.streamingondisconnect(asocket: tlsocket);
{$else}
procedure tmainform.streamingondisconnect;
{$endif}
begin
  {$ifopt D+}
  printdbg('STREAMING', 'DISCONNECTED');
  {$endif}
  connectbtn.caption := 'Connect';
  lockinternal(true);
end;

end.

