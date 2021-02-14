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
  lnetcomponents, lnet, bgrapath, buttons, classes, comctrls, controls, dialogs,
  extctrls, forms, graphics, menus, spin, stdctrls, shellctrls, xmlpropstorage,
  extdlgs, dividerbevel, spinex, xypdriver, xypoptimizer, xyppaths, xypmath,
  xypsetting, xypsketcher;

type

  { tmainform }

  tmainform = class(tform)
    addresscb: TComboBox;
    aboutbtn: TBitBtn;
    sethomebtn: TBitBtn;
    twopointslb: TLabel;
    connectbtn: TBitBtn;
    portcb: tcombobox;
    progressbar: TProgressBar;
    scheduler: tidletimer;
    opendialog: topenpicturedialog;
    zoomcb: tcombobox;
    lnet: tltcpcomponent;
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
    procedure connectbtnclick(sender: tobject);
    procedure formcreate (sender: tobject);
    procedure formdestroy(sender: tobject);
    procedure formclose(sender: tobject; var closeaction: tcloseaction);
    procedure lnetreceive(asocket: tlsocket);
    procedure ltpcconnect(asocket: tlsocket);
    procedure ltpcdsisconnect(asocket: tlsocket);
    procedure ltpcerror(const msg: string; asocket: tlsocket);
    procedure propstoragerestoreproperties(sender: tobject);
    // CALIBRATION
    procedure motorbtnclick(sender: tobject);
    // IMPORT/CLEAR
    procedure importbtnclick(sender: tobject);
    procedure clearbtnclick(sender: tobject);
    // EDITING
    procedure editingcbchange(sender: tobject);
    procedure editingbtnclick(sender: tobject);
    // PAGE SIZE
    procedure pagesizebtnclick(sender: tobject);
    procedure screenclick(sender: tobject);
    procedure sethomebtnclick(sender: tobject);
    // CONTROL
    procedure startmiclick(sender: tobject);
    procedure killmiclick(sender: tobject);
    procedure movetohomemiclick(sender: tobject);
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
    streaming: boolean;
    stream: tmemorystream;
    streamsize: int64;
    streamposition: int64;
    streamcrc: byte;
    procedure streamingstart;
    procedure streamingstop;
    procedure streamingrun;

    function getzoom: double;
    procedure lockinternal(value: boolean);


    procedure onscreenthreadstart;
    procedure onscreenthreadstop;
  public
    procedure lock;
    procedure unlock;
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
  driver:       txypdriver    = nil;
  mainform:     tmainform;
  screenthread: tscreenthread = nil;

implementation

{$R *.lfm}

uses
  aboutfrm, importfrm, math, sysutils, xypdxfreader, xypsvgreader, xyputils;

const
  bufferlen = 1024;

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
begin
  // properties storage
  propstorage.filename := getclientsettingfilename(false);
  // load setting
  setting := txypsetting.create;
  setting.load(getsettingfilename(true));
  // driver stream
  stream := tmemorystream.create;
  // init driver-engine
  driver := txypdriver.create(stream);
  driver.ramplen := setting.rampkl;
  driver.xratio := setting.pxratio;
  driver.yratio := setting.pyratio;
  driver.zratio := setting.pzratio;
  driverdebug;
  // create page
  page := txypelementlist.create;
  // create screen bitmap image
  screenimage := tbgrabitmap.create(screen.width, screen.height);
  // create sheduler list
  schedulerlist := tstringlist.create;
  scheduler.enabled := false;
end;

procedure tmainform.formdestroy(sender: tobject);
begin
  scheduler.enabled := false;
  schedulerlist.destroy;
  screenimage.destroy;
  page.destroy;
  driver.destroy;
  setting.destroy;
  stream.destroy;
  propstorage.save;
end;

procedure tmainform.formclose(sender: tobject; var closeaction: tcloseaction);
begin
  closeaction := canone;
  if lnet.connected then
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
  if lnet.connected then
  begin
    if (driver.xcount1 = 0) and
       (driver.ycount1 = 0) and
       (driver.zcount1 = 0) then
    begin
      lnet.disconnect(false);
    end else
      messagedlg('XY-Plot', 'Please move the plotter to origin (Home) before disconnecting !', mterror, [mbok], 0);
  end else
  begin
    lnet.connect(addresscb.text, strtoint(portcb.text));
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
    lock;
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
    scheduler.enabled:= true;
  end;
end;

procedure tmainform.clearbtnclick(sender: tobject);
begin
  caption := 'XY-Plot';
  page.clear;
  // start scheduler
  schedulerlist.add('screen.update');
  scheduler.enabled:= true;
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
  scheduler.enabled:= true;
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
  printdbg('PAGE', format('WIDTH            %12.5u', [pagewidth]));
  printdbg('PAGE', format('HEIGHT           %12.5u', [pageheight]));
  {$endif}
  changezoombtnclick(zoomcb);
end;

procedure tmainform.screenclick(Sender: TObject);
begin

end;

// CONTROL

procedure tmainform.startmiclick(sender: tobject);
begin
  if streaming then
  begin
    scheduler.enabled := not scheduler.enabled;
    if scheduler.enabled then
    begin
      startbtn.caption    := 'Stop';
      startbtn.imageindex := 7;
      streamingrun;
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
  if streaming then
  begin
    // connection
    addresscb      .enabled := false;
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
    addresscb      .enabled := value and (lnet.connected = false);
    connectbtn     .enabled := value;
    // calibration
    stepnumberedt  .enabled := value and (lnet.connected);
    xupbtn         .enabled := value and (lnet.connected);
    xdownbtn       .enabled := value and (lnet.connected);
    yupbtn         .enabled := value and (lnet.connected);
    ydownbtn       .enabled := value and (lnet.connected);
    zupbtn         .enabled := value and (lnet.connected);
    zdownbtn       .enabled := value and (lnet.connected);
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
    startbtn       .enabled := value and (lnet.connected);
    killbtn        .enabled := value and (lnet.connected);
    homebtn        .enabled := value and (lnet.connected);
    sethomebtn     .enabled := value and (lnet.connected);
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

procedure tmainform.lock;
begin
  lockinternal(false);
end;

procedure tmainform.unlock;
begin
  lockinternal(true);
end;

// SCREEN THREAD EVENTS

procedure tmainform.onscreenthreadstart;
begin

end;

procedure tmainform.onscreenthreadstop;
begin
  screenthread := nil;
end;

// SCHEDULER

procedure tmainform.schedulerstarttimer(sender: tobject);
begin
  lock;
  progressbar.position := 100;
  progressbar.visible  := schedulerlist.count <> 0;
end;

procedure tmainform.schedulerstoptimer(sender: tobject);
begin
  progressbar.visible := schedulerlist.count <> 0;
  unlock;
end;

procedure tmainform.schedulertimer(sender: tobject);
begin
  if streaming then
  begin
    progressbar.position := (100 * streamposition) div streamsize;
  end else
  if assigned(screenthread) then
  begin
    progressbar.position := screenthread.percentage;
  end else
  if schedulerlist.count > 0 then
  begin
    if ('screen.update' = schedulerlist[0]) then
    begin
      screenthread         := tscreenthread.create;
      screenthread.onstart := @onscreenthreadstart;
      screenthread.onstop  := @onscreenthreadstop;
      screenthread.start;
      lock;
    end else
    if ('screen.fit' = schedulerlist[0]) then
    begin
      movex := (screen.width  div 2) - trunc((pagewidth /2)*getzoom);
      movey := (screen.height div 2) - trunc((pageheight/2)*getzoom);
      screen.redrawbitmap;
    end else
    if ('driver.start' = schedulerlist[0]) then
    begin
      {$ifopt D+} printdbg('DRIVER', 'START'); {$endif}
      stream.clear;
      driver.sync;
      driver.move(page, pagewidth, pageheight);
      driver.movez(+trunc(1/setting.pzratio));
      driver.movex(0);
      driver.movey(0);
      driver.movez(0);
      driver.createramps;
      streamingstart;
    end else
    if ('driver.setorigin' = schedulerlist[0]) then
    begin
      {$ifopt D+} printdbg('DRIVER', 'SET ORIGIN'); {$endif}
      stream.clear;
      driver.setorigin;
    end else
    if ('driver.movetoorigin' = schedulerlist[0]) then
    begin
      {$ifopt D+} printdbg('DRIVER', 'MOVE TO ORIGIN'); {$endif}
      stream.clear;
      driver.sync;
      driver.movez(+trunc(1/setting.pzratio));
      driver.movex(0);
      driver.movey(0);
      driver.movez(0);
      driver.createramps;
      streamingstart;
    end else
    if pos('driver.move', schedulerlist[0]) = 1 then
    begin
      {$ifopt D+} printdbg('DRIVER', 'MOVE'); {$endif}
      stream.clear;
      driver.sync;
      if (schedulerlist[0] = 'driver.movex+') then
        driver.movex(driver.xcount2 + round(stepnumberedt.value/driver.xratio));

      if (schedulerlist[0] = 'driver.movex-') then
        driver.movex(driver.xcount2 - round(stepnumberedt.value/driver.xratio));

      if (schedulerlist[0] = 'driver.movey+') then
        driver.movey(driver.ycount2 + round(stepnumberedt.value/driver.yratio));

      if (schedulerlist[0] = 'driver.movey-') then
        driver.movey(driver.ycount2 - round(stepnumberedt.value/driver.yratio));

      if (schedulerlist[0] = 'driver.movez+') then
        driver.movez(driver.zcount2 + round(stepnumberedt.value/driver.zratio));

      if (schedulerlist[0] = 'driver.movez-') then
        driver.movez(driver.zcount2 - round(stepnumberedt.value/driver.zratio));
      driver.createramps;
      streamingstart;
    end;
    schedulerlist.delete(0);
  end else
  begin
    scheduler.enabled := false;
  end;
end;

// network streaming

procedure tmainform.streamingstart;
begin
  streamposition := 0;
  streamsize := stream.size;
  stream.seek(0, sofrombeginning);
  if streamsize > 0 then
  begin
    {$ifopt D+} printdbg('TCP', 'STREAMING.START'); {$endif}
    startbtn.caption    := 'Stop';
    startbtn.imageindex := 7;
    // ---
    streaming := true;
    {$ifopt D+}
    printdbg('DRIVER', format('STATUS [CX-1 %10d -> CX-2 %10d]', [driver.xcount1, driver.xcount2]));
    printdbg('DRIVER', format('STATUS [CY-1 %10d -> CY-2 %10d]', [driver.ycount1, driver.ycount2]));
    printdbg('DRIVER', format('STATUS [CZ-1 %10d -> CZ-2 %10d]', [driver.zcount1, driver.zcount2]));
    {$endif}
    streamingrun;
    lock;
  end;
end;

procedure tmainform.streamingstop;
begin
  startbtn.caption    := 'Start';
  startbtn.imageindex := 6;
  // ---
  stream.clear;
  streamsize := 0;
  streamposition := 0;
  streaming := false;
  {$ifopt D+}
  printdbg('DRIVER', format('CHECK  [CX-1 %10d -> CX-2 %10d]', [driver.xcount1, driver.xcount2]));
  printdbg('DRIVER', format('CHECK  [CY-1 %10d -> CY-2 %10d]', [driver.ycount1, driver.ycount2]));
  printdbg('DRIVER', format('CHECK  [CZ-1 %10d -> CZ-2 %10d]', [driver.zcount1, driver.zcount2]));
  printdbg('TCP', 'STREAMING.STOP');
  {$endif}
  if (driver.xcount1 <> driver.xcount2) or
     (driver.ycount1 <> driver.ycount2) or
     (driver.zcount1 <> driver.zcount2) then
  begin
    messagedlg('XY-Plot', 'Syncing Error !', mterror, [mbok], 0);
  end;
  unlock;
end;

procedure tmainform.streamingrun;
var
  buffer: array[0..bufferlen -1] of byte;
begin
  fillbyte(buffer, sizeof(buffer), 0);
  if (stream.read(buffer, sizeof(buffer)) > 0) then
  begin
    lnet.send        (buffer, sizeof(buffer));
    driver.sync      (buffer, sizeof(buffer));
    streamcrc := crc8(buffer, sizeof(buffer));
  end;
end;

// network connection

procedure tmainform.ltpcconnect(asocket: tlsocket);
begin
  {$ifopt D+} printdbg('TCP', 'CONNECTED'); {$endif}
  connectbtn.caption := 'Disconnect';
  unlock;
end;

procedure tmainform.ltpcdsisconnect(asocket: tlsocket);
begin
  {$ifopt D+} printdbg('TCP', 'DISCONNECTED'); {$endif}
  connectbtn.caption := 'Connect';
  unlock;
end;

procedure tmainform.ltpcerror(const msg: string; asocket: tlsocket);
begin
  {$ifopt D+} printdbg('TCP', format('ERROR (%s)', [msg])); {$endif}
end;

procedure tmainform.lnetreceive(asocket: tlsocket);
var
  crc: byte;
begin
  if lnet.get(crc, sizeof(crc)) = sizeof(crc) then
  begin
    if (crc = streamcrc) then
    begin
      inc(streamposition, bufferlen);
      if streamposition < streamsize then
      begin
        if scheduler.enabled then streamingrun;
      end else
        streamingstop;
    end else
    begin
      streamingstop;
      {$ifopt D+} printdbg('TCP', 'ERROR (CRC STREAMING)'); {$endif}
    end;
  end;
end;

end.

