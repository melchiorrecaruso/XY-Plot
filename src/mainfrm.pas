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

interface

uses
  bgrabitmap, bgrasvg, bgrabitmaptypes, bgragradientscanner, bgravirtualscreen,
  bgrapath, buttons, classes, comctrls, controls, dialogs, extctrls, forms,
  graphics, menus, spin, stdctrls, shellctrls, xmlpropstorage, extdlgs,
  dividerbevel, spinex, xypdriver, xypoptimizer, xyppaths, xypserial,
  xypsetting, xypsketcher;

type

  { tmainform }

  tmainform = class(tform)
    aboutbtn: TBitBtn;
    sethomebtn: TBitBtn;
    connectbtn: TBitBtn;
    portcb: tcombobox;
    progressbar: TProgressBar;
    scheduler: tidletimer;
    opendialog: topenpicturedialog;
    zoomcb: tcombobox;
    btnimages: timagelist;
    propstorage: txmlpropstorage;
    zoomlb: tlabel;
    homebtn: tbitbtn;
    startbtn: tbitbtn;
    killbtn: tbitbtn;
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
    stepnumberedt: tspinedit;
    stepnumberlb: tlabel;
    // FORM EVENTS
    procedure formcreate (sender: tobject);
    procedure formdestroy(sender: tobject);
    procedure formclose(sender: tobject; var closeaction: tcloseaction);
    procedure propstoragerestoreproperties(sender: tobject);
    // CONNECTION
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
    procedure killmiclick(sender: tobject);
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
    // SCHEDULER EVENTS
    procedure schedulerstarttimer(sender: tobject);
    procedure schedulerstoptimer(sender: tobject);
    procedure schedulertimer(sender: tobject);
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
    stream: tmemorystream;
    streaming1: boolean;
    streaming2: boolean;
    streamposition: int64;
    streamsize: int64;
    procedure streamingstart;
    procedure streamingstop;
    procedure streamingrun(count: longint);
    procedure streamingcallback;

    function getzoom: double;
    procedure lockinternal(value: boolean);


    procedure onscreenthreadstart;
    procedure onscreenthreadstop;
  end;

  tscreenthread = class(tthread)
  private
    fonstart: tthreadmethod;
    fonstop: tthreadmethod;
    fpercentage: longint;
  public
    constructor create;
    destructor destroy; override;
    procedure execute; override;
  public
    property onstart: tthreadmethod read fonstart write fonstart;
    property onstop:  tthreadmethod read fonstop  write fonstop;
    property percentage: longint read fpercentage;
  end;

var
  driver:       txypdriver       = nil;
  mainform:     tmainform;
  screenthread: tscreenthread    = nil;
  serialstream: txypserialstream = nil;
  setting:      txypsetting;

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
  fpercentage := 0;
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

    screenimage.canvas.font.bold  := true;
    screenimage.canvas.font.size  := 12;
    screenimage.canvas.font.color := bgra(255, 0, 0);
    screenimage.canvas.textout(5, 2, pageformat);
    // updtare preview ...
    x0 := trunc((pagewidth /2)*zoom);
    y0 := trunc((pageheight/2)*zoom);

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
var
  ports: tstringlist;
begin
  defaultformatsettings.decimalseparator := '.';
  // properties storage
  propstorage.filename := getclientsettingfilename(false);
  // load setting
  setting := txypsetting.create;
  setting.load(getsettingfilename(true));
  // driver stream
  stream := tmemorystream.create;
  // init driver-engine
  driver := txypdriver.create(stream, setting);
  {$ifopt D+}
  driverdebug(driver);
  {$endif}
  // create page
  page := txypelementlist.create;
  // create screen bitmap image
  screenimage := tbgrabitmap.create(screen.width, screen.height);
  // create sheduler list
  schedulerlist := tstringlist.create;
  scheduler.enabled := false;
  // create serial stream
  serialstream := txypserialstream.create;
  serialstream.rxevent := @streamingcallback;
  // load serial ports
  ports := serialportnames;
  while ports.count > 0 do
  begin
    portcb.items.add(ports[0]);
    ports.delete(0);
  end;
  ports.destroy;
end;

procedure tmainform.formdestroy(sender: tobject);
begin
  scheduler.enabled := false;
  // destroy
  driver.destroy;
  page.destroy;
  propstorage.save;
  schedulerlist.destroy;
  screenimage.destroy;
  serialstream.destroy;
  setting.destroy;
  stream.destroy;
end;

procedure tmainform.formclose(sender: tobject; var closeaction: tcloseaction);
begin
  closeaction := canone;
  if serialstream.connected then
  begin
    messagedlg('XY-Plot', 'Please disconnect before closing window !', mterror, [mbok], 0);
  end else
  begin
    closeaction := cafree;
  end;
end;

// CONNECTION

procedure tmainform.connectbtnclick(sender: tobject);
begin
  if serialstream.connected then
  begin
    if (driver.xcount1 = 0) and
       (driver.ycount1 = 0) and
       (driver.zcount1 = 0) then
    begin
      {$ifopt D+} printdbg('TCP', 'DISCONNECTED'); {$endif}
      connectbtn.caption := 'Connect';
      serialstream.close;
      lockinternal(true);
    end else
      messagedlg('XY-Plot', 'Please move the plotter to origin (Home) before disconnecting !', mterror, [mbok], 0);
  end else
    serialstream.open(portcb.text);
    if serialstream.connected then
    begin
      {$ifopt D+} printdbg('TCP', 'CONNECTED'); {$endif}
      connectbtn.caption := 'Disconnect';
      lockinternal(true);
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
  scheduler.enabled := true;
end;

procedure tmainform.movetohomemiclick(sender: tobject);
begin
  schedulerlist.add('driver.movetoorigin');
  scheduler.enabled := true;
end;

procedure tmainform.sethomebtnclick(sender: tobject);
begin
  schedulerlist.add('driver.setorigin');
  scheduler.enabled := true;
end;

// DRAWING IMPORT/CLEAR

procedure tmainform.importbtnclick(sender: tobject);
var
  bit: tbgrabitmap;
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
        case (importform.methodcb.itemindex + 1) of
          1: sk := txypsketchersquare.create(bit);
          2: sk := txypsketcherroundedsquare.create(bit);
          3: sk := txypsketchertriangular.create(bit);
        else sk := txypsketchersquare.create(bit);
        end;
        sk.patternheight := trunc(importform.patternpxse.value);
        sk.patternwidth  := trunc(importform.patternpxse.value);
        sk.pageheight    := importform.patternmmse.value*(bit.height/bit.width);
        sk.pagewidth     := importform.patternmmse.value;
        sk.dotsize       := importform.dotsizese.value;
        sk.update(page);
        sk.destroy;
        bit.destroy;
      end;
    end;
    // start scheduler
    schedulerlist.add('screen.update');
    scheduler.enabled := true;
  end;
end;

procedure tmainform.clearbtnclick(sender: tobject);
begin
  caption := 'XY-Plot';
  page.clear;
  // start scheduler
  schedulerlist.add('screen.update');
  scheduler.enabled := true;
end;

// DRAWING EDITING

procedure tmainform.editingcbchange(sender: tobject);
begin
  editingedt.enabled := editingbtn.enabled;
  if sender = editingcb then
    case editingcb.itemindex of
      0: editingedt.value   := 1.0;   // SCALE
      1: editingedt.value   := 0.0;   // X-OFFSET
      2: editingedt.value   := 0.0;   // Y-OFFSET
      3: editingedt.enabled := false; // X-MIRROR
      4: editingedt.enabled := false; // Y-MIRROR
      5: editingedt.value   := 90.0;  // ROTATE
      6: editingedt.enabled := false; // MOVE TO ORIGIN
    end;
end;

procedure tmainform.editingbtnclick(sender: tobject);
begin
  case editingcb.itemindex of
    0: page.scale(editingedt.value   );         // SCALE
    1: page.move (editingedt.value, 0);         // X-OFFSET
    2: page.move (0, editingedt.value);         // Y-OFFSET
    3: page.mirrorx;                            // X-MIRROR
    4: page.mirrory;                            // Y-MIRROR
    5: page.rotate(degtorad(editingedt.value)); // ROTATE
    6: page.centertoorigin;                     // MOVE TO ORIGIN
  end;
  page.updatepage;
  // start scheduler
  schedulerlist.add('screen.update');
  scheduler.enabled := true;
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
  if streaming1 then
  begin
    streaming2 := not streaming2;
    if streaming2 then
    begin
      startbtn.caption    := 'Stop';
      startbtn.imageindex := 7;
      streamingrun(64);
    end else
    begin
      startbtn.caption    := 'Start';
      startbtn.imageindex := 6;
    end;

  end else
  begin
    schedulerlist.add('driver.start');
    scheduler.enabled := true;
  end;
end;

procedure tmainform.killmiclick(sender: tobject);
begin
  streamingstop;
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
    scheduler.enabled := true;
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
  if streaming1 then
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
    editingedt     .enabled := false;
    editingbtn     .enabled := false;
    // page sizing
    pagesizecb     .enabled := false;
    // control
    startbtn       .enabled := true;
    killbtn        .enabled := true;
    homebtn        .enabled := false;
    sethomebtn     .enabled := false;
    // about popup
    aboutbtn       .enabled := false;
    // zoom
    zoomcb         .enabled := false;
    // screen
    screen         .enabled := false;
  end else
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
    editingedt     .enabled := value;
    editingbtn     .enabled := value;
    // page sizing
    pagesizecb     .enabled := value;
    // control
    startbtn       .enabled := value and (serialstream.connected);
    killbtn        .enabled := value and (serialstream.connected);
    homebtn        .enabled := value and (serialstream.connected);
    sethomebtn     .enabled := value and (serialstream.connected);
    // about popup
    aboutbtn       .enabled := value;
    // zoom
    zoomcb         .enabled := value;
    // screen
    screen         .enabled := value;
  end;
  editingcbchange(nil);
  application.processmessages;
end;

// SCREEN THREAD EVENTS

procedure tmainform.onscreenthreadstart;
begin

end;

procedure tmainform.onscreenthreadstop;
begin
  screenthread := nil;
  scheduling := false;
end;

// SCHEDULER

procedure tmainform.schedulerstarttimer(sender: tobject);
begin
  lockinternal(false);
  progressbar.position := 100;
  progressbar.visible  := schedulerlist.count <> 0;
end;

procedure tmainform.schedulerstoptimer(sender: tobject);
begin
  progressbar.visible := schedulerlist.count <> 0;
  lockinternal(true);
end;

procedure tmainform.schedulertimer(sender: tobject);
begin
  if scheduling then
  begin
    if streaming1 then
      progressbar.position := (100 * streamposition) div streamsize;
    if assigned(screenthread) then
      progressbar.position := screenthread.percentage;
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
      stream.clear;
      driver.sync;
      driver.move(page, pagewidth, pageheight);
      driver.movez(trunc(setting.pzup/setting.pzratio));
      driver.movex(0);
      driver.movey(0);
      driver.movez(0);
      driver.createramps;
      streamingstart;
    end else
    if ('driver.setorigin' = schedulerlist[0]) then
    begin
      {$ifopt D+} printdbg('DRIVER', 'SET ORIGIN'); {$endif}
      //scheduling := true;
      //stream.clear;
      driver.setorigin;
    end else
    if ('driver.movetoorigin' = schedulerlist[0]) then
    begin
      {$ifopt D+} printdbg('DRIVER', 'MOVE TO ORIGIN'); {$endif}
      scheduling := true;
      stream.clear;
      driver.sync;
      driver.movez(trunc(setting.pzup/setting.pzratio));
      driver.movex(0);
      driver.movey(0);
      driver.movez(0);
      driver.createramps;
      streamingstart;
    end else
    if pos('driver.move', schedulerlist[0]) = 1 then
    begin
      {$ifopt D+} printdbg('DRIVER', 'MOVE'); {$endif}
      scheduling := true;
      stream.clear;
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
      driver.createramps;
      streamingstart;
    end;

    schedulerlist.delete(0);
  end else
  begin
    scheduler.enabled := false;
  end;
end;

// seria streaming

procedure tmainform.streamingstart;
begin
  startbtn.caption := 'Stop';
  startbtn.imageindex := 7;
  {$ifopt D+}
  printdbg('TCP', 'STREAMING.START');
  printdbg('DRIVER', format('SYNC [X%10.2f] [Y%10.2f] [Z%10.2f]',
    [driver.xcount1*setting.pxratio,
     driver.ycount1*setting.pyratio,
     driver.zcount1*setting.pzratio]));
  {$endif}
  if stream.size > 0 then
  begin
    streaming1 := true;
    streaming2 := true;
    streamposition := 0;
    streamsize := stream.size;
    stream.seek(0, sofrombeginning);
    lockinternal(false);
    // start streaming
    streamingrun(80);
  end else
    streamingstop;
end;

procedure tmainform.streamingstop;
begin
  streaming1 := false;
  streaming2 := false;
  streamposition := 0;
  streamsize := 0;
  stream.clear;
  {$ifopt D+}
  printdbg('DRIVER', format('SYNC [X%10.2f] [Y%10.2f] [Z%10.2f]',
    [driver.xcount1*setting.pxratio,
     driver.ycount1*setting.pyratio,
     driver.zcount1*setting.pzratio]));
  printdbg('TCP', 'STREAMING.STOP');
  {$endif}
  // ---
  startbtn.caption := 'Start';
  startbtn.imageindex := 6;
  scheduling := false;
  lockinternal(true);
end;

procedure tmainform.streamingrun(count: longint);
var
  buffer: array[0..$FFFF] of byte;
begin
  count := stream.read(buffer, count);
  if count > 0 then
  begin
    serialstream.write(buffer, count);
    driver.sync(buffer, count);
    {$ifopt D+}
    printdbg('DRIVER', format('SYNC [X%10.2f] [Y%10.2f] [Z%10.2f]',
      [driver.xcount1*setting.pxratio,
       driver.ycount1*setting.pyratio,
       driver.zcount1*setting.pzratio]));
    {$endif}
  end;
end;

procedure tmainform.streamingcallback;
var
  count: byte;
begin
  while serialstream.read(count, sizeof(count)) = sizeof(count) do
  begin
    inc(streamposition, count);
    if streamposition < streamsize then
    begin
      if streaming2 then
        streamingrun(count);
    end else
      streamingstop;
  end;
end;

end.

