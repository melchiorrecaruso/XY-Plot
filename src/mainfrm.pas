{
  Description: XY-Plot main form.

  Copyright (C) 2020 Melchiorre Caruso <melchiorrecaruso@gmail.com>

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
  bgrabitmap, bgrabitmaptypes, bgragradientscanner, bgravirtualscreen, bgrapath,
  buttons, classes, comctrls, controls, dialogs, extctrls, forms, graphics,
  menus, spin, stdctrls, shellctrls, xmlpropstorage, dividerbevel, spinex,
  xypdriver, xyppaths, xypmath, xypoptimizer, xypserial, xypsetting;

type
  { tmainform }

  tmainform = class(tform)
    beginbtn: tbitbtn;
    cleanupmi: tmenuitem;
    cleanupoffmi: TMenuItem;
    cleanup010mi: tmenuitem;
    cleanup025mi: tmenuitem;
    cleanup050mi: tmenuitem;
    cleanup075mi: tmenuitem;
    cleanup100mi: tmenuitem;
    cleanup125mi: tmenuitem;
    cleanup150mi: tmenuitem;
    cleanup200mi: tmenuitem;
    cleanup300mi: tmenuitem;
    cleanup400mi: tmenuitem;
    cleanup500mi: tmenuitem;
    cleanup600mi: TMenuItem;
    cleanup700mi: TMenuItem;
    cleanup800mi: TMenuItem;
    showlogmi: tmenuitem;
    progressbar: tprogressbar;
    showpentransitmi: tmenuitem;
    showreddotmi: tmenuitem;
    optimizermi: tmenuitem;
    optimizemi: tmenuitem;
    popupn2: tmenuitem;
    toolsbtn: tbitbtn;
    decstepsbtn: tbitbtn;
    setupmi: tmenuitem;
    popupn1: tmenuitem;
    incstepsbtn: tbitbtn;
    deczoombtn: tbitbtn;
    inczoombtn: tbitbtn;
    endbtn: tbitbtn;
    fitbtn: tbitbtn;
    btnimages: timagelist;
    popup: tpopupmenu;
    stepslb: tlabel;
    propstorage: txmlpropstorage;
    zoomlb: tlabel;
    nextbtn: tbitbtn;
    backbtn: tbitbtn;
    aboutbtn: tbitbtn;
    homebtn: tbitbtn;
    startbtn: tbitbtn;
    killbtn: tbitbtn;
    controlbvl: tdividerbevel;
    calibrationbvl: tdividerbevel;
    clearbtn: tbitbtn;
    pagesizecb: tcombobox;
    portbtn: tbitbtn;
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
    pendownbtn: tbitbtn;
    penupbtn: tbitbtn;
    portcb: tcombobox;
    portlb: tlabel;
    ydownbtn: tbitbtn;
    yupbtn: tbitbtn;
    savedialog: tsavedialog;
    opendialog: topendialog;
    screen: tbgravirtualscreen;
    stepnumberedt: tspinedit;
    stepnumberlb: tlabel;
    // FORM EVENTS
    procedure formcreate (sender: tobject);
    procedure formdestroy(sender: tobject);
    procedure formclose  (sender: tobject; var closeaction: tcloseaction);
    // CONNECTION
    procedure connectbtnclick(sender: tobject);
    // CALIBRATION
    procedure motorbtnclick(sender: tobject);
    procedure penbtnclick  (sender: tobject);
    // IMPORT/CLEAR
    procedure importbtnclick(sender: tobject);
    procedure clearbtnclick (sender: tobject);
    // EDITING
    procedure editingbtnclick(sender: tobject);
    // PAGE SIZE
    procedure pagesizebtnclick            (sender: tobject);
    procedure propstoragerestoreproperties(sender: tobject);
    procedure showlogmiclick              (sender: tobject);
    // CONTROL
    procedure startmiclick     (sender: tobject);
    procedure killmiclick      (sender: tobject);
    procedure movetohomemiclick(sender: tobject);
    // PREVIEW STEP BY STEP
    procedure stepsbtnclick      (sender: tobject);
    procedure changestepsbtnclick(sender: tobject);
    // ZOOM
    procedure editingcbchange   (sender: tobject);
    procedure changezoombtnclick(sender: tobject);
    procedure fitmiclick        (sender: tobject);
    // TOOLS
    procedure toolsbtnclick  (sender: tobject);
    procedure setupmiclick   (sender: tobject);
    procedure optimizemiclick(sender: tobject);
    procedure cleanupvaluemiclick (sender: tobject);
    procedure opimizermiclick      (sender: tobject);
    procedure showreddotmiclick    (sender: tobject);
    procedure showpentransitmiclick(sender: tobject);
    // ABOUT POPUP
    procedure aboutmiclick(sender: tobject);
    // VIRTUAL SCREEN EVENTS
    procedure screenredraw(sender: tobject; bitmap: tbgrabitmap);
    // MOUSE EVENTS
    procedure imagemouseup  (sender: tobject; button: tmousebutton; shift: tshiftstate; x, y: integer);
    procedure imagemousedown(sender: tobject; button: tmousebutton; shift: tshiftstate; x, y: integer);
    procedure imagemousemove(sender: tobject; shift: tshiftstate; x, y: integer);
  private
    isneededoptimize: boolean;
    mouseisdown: boolean;
    movex: longint;
    movey: longint;
    page: txypelementlist;
    pagecount: longint;
    pagesteps: longint;
    pageheight: longint;
    pagewidth: longint;
    px: longint;
    py: longint;
    screenimage: tbgrabitmap;
    zoom: double;
    procedure lockinternal(value: boolean);
    procedure onplottererror;
    procedure onplotterinit;
    procedure onplotterstart;
    procedure onplotterstop;
    procedure onplotterstopandraise;
    procedure onplottertick;
    procedure onoptimizerstart;
    procedure onoptimizerstop;
    procedure onoptimizerstopandprint;
    procedure onoptimizertick;
  public
    procedure lock;
    procedure unlock;
    procedure updatescreen;
  end;


var
  driver:       txypdriver        = nil;
  driverengine: txypdriverengine  = nil;
  mainform:     tmainform;
  optimizer:    txyppathoptimizer = nil;
  setting:      txypsetting       = nil;


implementation

{$R *.lfm}

uses
  aboutfrm, debugfrm, math, settingfrm, sysutils, xypdebug, xypsvgreader;

// FORM EVENTS

procedure tmainform.formcreate(sender: tobject);
var
  i: longint;
  list: tstringlist;
begin
  // propstorage
  propstorage.filename := getclientsettingfilename(false);
  // load setting
  setting := txypsetting.create;
  setting.load(getsettingfilename(true));
  // open serial port
  serialstream := txypserialstream.create;
  // init driver-engine
  driverengine := txypdriverengine.create(setting);
  driverenginedebug(driverengine);
  // create preview and empty page
  page := txypelementlist.create;
  screenimage := tbgrabitmap.create(screen.width, screen.height);
  // update port combobox
  list := serialportnames;
  for i := 0 to list.count -1 do
  begin
    portcb.items.add(list[i]);
  end;
  list.destroy;
  isneededoptimize := true;
  pagesizecb.itemindex := 0;
  portcb.itemindex := 0;
end;

procedure tmainform.formdestroy(sender: tobject);
begin
  driverengine.destroy;
  page.destroy;
  propstorage.save;
  screenimage.destroy;
  serialstream.destroy;
  setting.destroy;
end;

procedure tmainform.formclose(sender: tobject; var closeaction: tcloseaction);
begin
  if assigned(driver) then
  begin
    messagedlg('XY-Plot Client', 'There is an active process !', mterror, [mbok], 0);
    closeaction := canone;
  end else
    closeaction := cafree;
end;

procedure tmainform.propstoragerestoreproperties(sender: tobject);
begin
  // main form updates
  pagesizebtnclick(nil);
  fitmiclick(nil);
  changestepsbtnclick(nil);
  editingcbchange(nil);
end;

// CONNECTION

procedure tmainform.connectbtnclick(sender: tobject);
begin
  lock;
  if serialstream.connected then
  begin
    serialstream.close;
    portbtn.caption := 'Connect';
  end else
  begin
    portcb.enabled := not serialstream.open(portcb.text);
    if serialstream.connected then
    begin
      portbtn.caption := 'Disconnect';
    end else
    begin
      portbtn.caption := 'Connect';
      messagedlg('XY-Plot Client', 'Unable connecting to server !', mterror, [mbok], 0);
    end;
  end;
  unlock;
end;

// CALIBRATION

procedure tmainform.motorbtnclick(sender: tobject);
var
  cx: longint = 0;
  cy: longint = 0;
begin
  if not serialstream.connected then exit;
  if not assigned(driver) then
  begin
    lock;
    if sender = xupbtn   then cx := +stepnumberedt.value;
    if sender = xdownbtn then cx := -stepnumberedt.value;
    if sender = yupbtn   then cy := +stepnumberedt.value;
    if sender = ydownbtn then cy := -stepnumberedt.value;

    driver         := txypdriver.create(setting, serialstream);
    driver.onerror := @onplottererror;
    driver.oninit  := @onplotterinit;
    driver.onstart := @onplotterstart;
    driver.onstop  := @onplotterstop;
    driver.ontick  := @onplottertick;
    driver.init;
    driver.movez(setting.servozvalue1);
    driver.move (cx + driver.xcount,
                 cy + driver.ycount);
    driver.start;
  end;
end;

procedure tmainform.penbtnclick(sender: tobject);
begin
  if not serialstream.connected then exit;
  if not assigned(driver) then
  begin
    lock;
    driver         := txypdriver.create(setting, serialstream);
    driver.onerror := @onplottererror;
    driver.oninit  := nil;
    driver.onstart := @onplotterstart;
    driver.onstop  := @onplotterstop;
    driver.ontick  := @onplottertick;
    driver.init;
    if sender = pendownbtn then
    begin
      driver.movez(setting.servozvalue0);
    end else
    begin
      driver.movez(setting.servozvalue1);
    end;
    driver.start;
  end;
end;

// DRAWING IMPORT/CLEAR

procedure tmainform.importbtnclick(sender: tobject);
begin
  opendialog.filter := 'Supported files (*.svg)|*.svg;';
  if opendialog.execute then
  begin
    lock;
    caption := 'XY-Plot Client - ' + opendialog.filename;
    svg2paths(opendialog.filename, page);
    pagecount := page.count;
    isneededoptimize := true;
    updatescreen;
    unlock;
  end;
end;

procedure tmainform.clearbtnclick(sender: tobject);
begin
  lock;
  page.clear;
  pagecount := page.count;
  isneededoptimize := true;
  caption := 'XY-Plot Client';
  fitmiclick(sender);
  unlock;
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
  lock;
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
  updatescreen;
  unlock;
end;

// PAGE SIZE

procedure tmainform.pagesizebtnclick(sender: tobject);
begin
  lock;
  case pagesizecb.itemindex of
    0: begin pagewidth := 1189; pageheight :=  841; end; // A0-Landscape
    1: begin pagewidth :=  841; pageheight := 1189; end; // A0-Portrait
    2: begin pagewidth :=  841; pageheight :=  594; end; // A1-Landscape
    3: begin pagewidth :=  594; pageheight :=  841; end; // A1-Portrait
    4: begin pagewidth :=  594; pageheight :=  420; end; // A2-Landscape
    5: begin pagewidth :=  420; pageheight :=  594; end; // A2-Portrait
    6: begin pagewidth :=  420; pageheight :=  297; end; // A3-Landscape
    7: begin pagewidth :=  297; pageheight :=  420; end; // A3-Portrait
    8: begin pagewidth :=  297; pageheight :=  210; end; // A4-Landscape
    9: begin pagewidth :=  210; pageheight :=  297; end; // A4-Portrait
   10: begin pagewidth :=  210; pageheight :=  148; end; // A5-Landscape
   11: begin pagewidth :=  148; pageheight :=  210; end; // A5-Portrait
  else begin pagewidth :=  420; pageheight :=  297; end  // Default
  end;
  xyplog.add(format('      PAGE::WIDTH            %12.5u', [pagewidth]));
  xyplog.add(format('      PAGE::HEIGHT           %12.5u', [pageheight]));

  updatescreen;
  fitmiclick(sender);
  unlock;
end;

// CONTROL

procedure tmainform.startmiclick(sender: tobject);
var
   cx, cy: longint;
  element: txypelement;
     i, j: longint;
     path: txyppolygonal;
   point1: txyppoint;
   point2: txyppoint;
  xoffset: single;
  yoffset: single;
begin
  if not assigned(driver) then
  begin

    if isneededoptimize then
      if optimizermi.checked then
      begin
        optimizer := txyppathoptimizer.create(page);
        optimizer.onstart := @onoptimizerstart;
        optimizer.onstop  := @onoptimizerstopandprint;
        optimizer.ontick  := @onoptimizertick;
        if cleanupoffmi.checked then optimizer.cleanup := 0.00 else
        if cleanup010mi.checked then optimizer.cleanup := 0.10 else
        if cleanup025mi.checked then optimizer.cleanup := 0.25 else
        if cleanup050mi.checked then optimizer.cleanup := 0.50 else
        if cleanup075mi.checked then optimizer.cleanup := 0.75 else
        if cleanup100mi.checked then optimizer.cleanup := 1.00 else
        if cleanup125mi.checked then optimizer.cleanup := 1.25 else
        if cleanup150mi.checked then optimizer.cleanup := 1.50 else
        if cleanup200mi.checked then optimizer.cleanup := 2.00 else
        if cleanup300mi.checked then optimizer.cleanup := 3.00 else
        if cleanup400mi.checked then optimizer.cleanup := 4.00 else
        if cleanup500mi.checked then optimizer.cleanup := 5.00 else
        if cleanup600mi.checked then optimizer.cleanup := 6.00 else
        if cleanup700mi.checked then optimizer.cleanup := 7.00 else
        if cleanup800mi.checked then optimizer.cleanup := 8.00;
        optimizer.start;
        exit;
      end;

    lock;
    driver         := txypdriver.create(setting, serialstream);
    driver.onerror := @onplottererror;
    driver.oninit  := nil;
    driver.onstart := @onplotterstart;
    driver.onstop  := @onplotterstopandraise;
    driver.ontick  := @onplottertick;
    driver.init;

    xoffset := pagewidth *setting.xfactor + setting.xoffset;
    yoffset := pageheight*setting.yfactor + setting.yoffset;

    point1.x := 0;
    point1.y := 0;
    for i := 0 to page.count -1 do
    begin
      element := page.items[i];
      element.interpolate(path, 0.05);
      for j := 0 to high(path) do
      begin
        point2 := path[j];
        if (abs(point2.x) < (pagewidth /2+2)) and
           (abs(point2.y) < (pageheight/2+2)) then
        begin
          point2.x := point2.x + xoffset;
          point2.y := point2.y + yoffset;

          if distance_between_two_points(point1, point2) > 0.2 then
            driver.movez(setting.servozvalue1)
          else
            driver.movez(setting.servozvalue0);

          driverengine.calcsteps(point2, cx, cy);
          driver.move(cx, cy);
          point1 := point2;
        end;
      end;
      path := nil;
    end;
    driver.start;
  end else
  begin // if assigned(driver)
    driver.enabled := not driver.enabled;
    if driver.enabled then
    begin
      startbtn.caption    := 'Stop';
      startbtn.imageindex := 7;
    end else
    begin
      startbtn.caption    := 'Start';
      startbtn.imageindex := 6;
    end;
  end;
end;

procedure tmainform.killmiclick(sender: tobject);
begin
  if assigned(driver) then
  begin
    startbtn.enabled := false;
    killbtn .enabled := false;
    homebtn .enabled := false;
    driver.onerror   := nil;
    driver.enabled   := true;
    driver.terminate;
  end;
end;

procedure tmainform.movetohomemiclick(sender: tobject);
var
  cx, cy: longint;
begin
  if not assigned(driver) then
  begin
    lock;
    driver         := txypdriver.create(setting, serialstream);
    driver.onerror := @onplottererror;
    driver.oninit  := nil;
    driver.onstart := @onplotterstart;
    driver.onstop  := @onplotterstop;
    driver.ontick  := @onplottertick;
    driver.init;
    driver.movez(setting.servozvalue1);
    driverengine.calcsteps(setting.origin, cx, cy);
    driver.move(cx, cy);
    driver.start;
  end;
end;

// PREVIEW STEP BY STEP

procedure tmainform.changestepsbtnclick(sender: tobject);
begin
  if sender = nil then
  begin
    pagesteps := 1
  end else
  if sender = incstepsbtn then
  begin
    if pagesteps =   1 then pagesteps :=   2 else
    if pagesteps =   2 then pagesteps :=   5 else
    if pagesteps =   5 then pagesteps :=  10 else
    if pagesteps =  10 then pagesteps :=  25 else
    if pagesteps =  25 then pagesteps :=  50 else
    if pagesteps =  50 then pagesteps := 100 else
    if pagesteps = 100 then pagesteps := 250 else
    if pagesteps = 250 then pagesteps := 500;
  end else
  if sender = decstepsbtn then
  begin
    if pagesteps = 500 then pagesteps := 250 else
    if pagesteps = 250 then pagesteps := 100 else
    if pagesteps = 100 then pagesteps :=  50 else
    if pagesteps =  50 then pagesteps :=  25 else
    if pagesteps =  25 then pagesteps :=  10 else
    if pagesteps =  10 then pagesteps :=   5 else
    if pagesteps =   5 then pagesteps :=   2 else
    if pagesteps =   2 then pagesteps :=   1;
  end;
  stepslb.caption := format('Step x%d', [pagesteps]);
end;

procedure tmainform.stepsbtnclick(sender: tobject);
begin
  lock;
  if sender = beginbtn then
    pagecount := 0
  else
  if sender = backbtn then
    dec(pagecount, pagesteps)
  else
  if sender = nextbtn then
    inc(pagecount, pagesteps)
  else
    pagecount := page.count;

  pagecount := max(0, min(pagecount, page.count));
  updatescreen;
  unlock;
end;

// ZOOM BUTTONS

procedure tmainform.changezoombtnclick(sender: tobject);
var
  azoom: double;
begin
  azoom := zoom;
  if sender = inczoombtn then
  begin
    if zoom =  0.25 then zoom :=  0.50 else
    if zoom =  0.50 then zoom :=  0.75 else
    if zoom =  0.75 then zoom :=  1.00 else
    if zoom =  1.00 then zoom :=  1.25 else
    if zoom =  1.25 then zoom :=  1.50 else
    if zoom =  1.50 then zoom :=  1.75 else
    if zoom =  1.75 then zoom :=  2.00 else
    if zoom =  2.00 then zoom :=  4.00 else
    if zoom =  4.00 then zoom :=  6.00 else
    if zoom =  6.00 then zoom :=  8.00 else
    if zoom =  8.00 then zoom := 10.00;
  end else
  if sender = deczoombtn then
  begin
    if zoom = 10.00 then zoom :=  8.00 else
    if zoom =  8.00 then zoom :=  6.00 else
    if zoom =  6.00 then zoom :=  4.00 else
    if zoom =  4.00 then zoom :=  2.00 else
    if zoom =  2.00 then zoom :=  1.75 else
    if zoom =  1.75 then zoom :=  1.50 else
    if zoom =  1.50 then zoom :=  1.25 else
    if zoom =  1.25 then zoom :=  1.00 else
    if zoom =  1.00 then zoom :=  0.75 else
    if zoom =  0.75 then zoom :=  0.50 else
    if zoom =  0.50 then zoom :=  0.25;
  end;

  if zoom <> azoom then
  begin
    fitmiclick(sender);
  end;
end;

procedure tmainform.fitmiclick(sender: tobject);
begin
  if (sender = nil   ) then zoom := 1.0 else
  if (sender = fitbtn) then zoom := 1.0;
  zoomlb.caption := format('Zoom %d%%', [trunc(zoom*100)]);

  lock;
  movex := (screen.width  div 2) - trunc((pagewidth /2)*zoom);
  movey := (screen.height div 2) - trunc((pageheight/2)*zoom);
  updatescreen;
  unlock;
end;

// TOOLS POPUP

procedure tmainform.toolsbtnclick(sender: tobject);
begin
  with toolsbtn.clienttoscreen(point(0, 0)) do
  begin
    popup.popup(x + toolsbtn.width, y + toolsbtn.height + 2);
  end;
end;

procedure tmainform.setupmiclick(sender: tobject);
begin
  settingform.load(setting);
  if settingform.showmodal = mrok then
  begin
    try
      settingform.save(setting);
      setting.save(getsettingfilename(false));
    except
      setting.load(getsettingfilename(true));
      setupmiclick(sender);
    end;
  end;
end;

procedure tmainform.showlogmiclick(sender: tobject);
begin
  debugform.memo.clear;
  debugform.memo.lines.addstrings(xyplog);
  debugform.showmodal;
end;

procedure tmainform.optimizemiclick(sender: tobject);
begin
  optimizer := txyppathoptimizer.create(page);
  optimizer.ontick  := @onoptimizertick;
  optimizer.onstart := @onoptimizerstart;
  optimizer.onstop  := @onoptimizerstop;
  if cleanupoffmi.checked then optimizer.cleanup := 0.00 else
  if cleanup010mi.checked then optimizer.cleanup := 0.10 else
  if cleanup025mi.checked then optimizer.cleanup := 0.25 else
  if cleanup050mi.checked then optimizer.cleanup := 0.50 else
  if cleanup075mi.checked then optimizer.cleanup := 0.75 else
  if cleanup100mi.checked then optimizer.cleanup := 1.00 else
  if cleanup125mi.checked then optimizer.cleanup := 1.25 else
  if cleanup150mi.checked then optimizer.cleanup := 1.50 else
  if cleanup200mi.checked then optimizer.cleanup := 2.00 else
  if cleanup300mi.checked then optimizer.cleanup := 3.00 else
  if cleanup400mi.checked then optimizer.cleanup := 4.00 else
  if cleanup500mi.checked then optimizer.cleanup := 5.00 else
  if cleanup600mi.checked then optimizer.cleanup := 6.00 else
  if cleanup700mi.checked then optimizer.cleanup := 7.00 else
  if cleanup800mi.checked then optimizer.cleanup := 8.00;
  optimizer.start;
end;

procedure tmainform.cleanupvaluemiclick(sender: tobject);
var
  i: longint;
begin
  for i := 0 to cleanupmi.count -1 do
  begin
    cleanupmi.items[i].checked := false;
  end;
  tmenuitem(sender).checked:= true;
end;

procedure tmainform.opimizermiclick(sender: tobject);
begin
  optimizermi.checked := not optimizermi.checked;
end;

procedure tmainform.showreddotmiclick(sender: tobject);
begin
  showreddotmi.checked := not showreddotmi.checked;

  lock;
  updatescreen;
  unlock;
end;

procedure tmainform.showpentransitmiclick(sender: tobject);
begin
  showpentransitmi.checked := not showpentransitmi.checked;

  lock;
  updatescreen;
  unlock;
end;

// ABOUT POPUP

procedure tmainform.aboutmiclick(sender: tobject);
begin
  aboutform.showmodal;
end;

// MOUSE EVENTS

procedure tmainform.imagemousedown(sender: tobject;
  button: tmousebutton; shift: tshiftstate; x, y: integer);
var
     i: longint;
  elem: txypelement;
    p0: txyppoint;
begin
  if assigned(driver) then exit;
  (*
  if (ssctrl in shift) then
  begin
    popup.autopopup := false;
    p0.x := ((x - pagewidth /2)*zoom) - movex;
    p0.y := ((y - pageheight/2)*zoom) - movey;

    for i := 0 to page.count -1 do
    begin
      elem := page.items[i];
      if elem.hidden = false then
        if elem.ispointon(p0) then
        begin
          elem.selected := true;
        end;
    end;
  end;
  *)

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
  if assigned(driver) then exit;
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
  if assigned(driver) then exit;
  mouseisdown := false;
end;

// SCREEN EVENTS

procedure tmainform.updatescreen;
var
       a: arrayoftpointf;
       i: longint;
    elem: txypelement;
  x0, x1: longint;
  y0, y1: longint;
    path: tbgrapath;
  p0, p1: txyppoint;
begin
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
  p0 := setting.origin;
  x0 := trunc((pagewidth /2)*zoom);
  y0 := trunc((pageheight/2)*zoom);
  for i := 0 to min(pagecount, page.count) -1 do
  begin
    elem := page.items[i];
    elem.mirrorx;
    elem.scale(zoom);
    elem.move(x0, y0);
    begin
      path := tbgrapath.create;
      elem.interpolate(path);
      path.stroke(screenimage, bgra(0, 0, 0), 1.5);

      a := path.topoints;
      // draw red point
      if showreddotmi.checked then
      begin
        path.beginpath;
        path.arc(
          trunc(a[high(a)].x),
          trunc(a[high(a)].y), 1.5, 0, 2*pi);
        path.stroke(screenimage, bgra(255, 0, 0), 1.0);
        path.fill  (screenimage, bgra(255, 0, 0));
      end;
      // draw pen transit
      if showpentransitmi.checked then
      begin
        p1.x := a[low(a)].x;
        p1.y := a[low(a)].y;
        if distance_between_two_points(p0, p1) > 0.2 then
        begin
          path.beginpath;
          path.moveto(p0.x, p0.y);
          path.lineto(p1.x, p1.y);
          path.stroke(screenimage, bgra(0, 255, 0), 1.0);
          path.fill  (screenimage, bgra(0, 255, 0));
        end;
        p0.x := a[high(a)].x;
        p0.y := a[high(a)].y;
      end;
      path.destroy;
    end;
    elem.move(-x0, -y0);
    elem.scale(1/zoom);
    elem.mirrorx;
  end;
  screen.redrawbitmap;
end;

procedure tmainform.screenredraw(sender: tobject; bitmap: tbgrabitmap);
begin
  bitmap.putimage(movex, movey, screenimage, dmset);
end;

// LOCK/UNLOCK ROUTINES

procedure tmainform.lockinternal(value: boolean);
begin
  if assigned(driver) then
  begin
    // connection
    portcb         .enabled := false;
    portbtn        .enabled := false;
    // calibration
    stepnumberedt  .enabled := false;
    xupbtn         .enabled := false;
    xdownbtn       .enabled := false;
    yupbtn         .enabled := false;
    ydownbtn       .enabled := false;
    penupbtn       .enabled := false;
    pendownbtn     .enabled := false;
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
    // tools
    setupmi        .enabled := false;
    optimizemi     .enabled := false;
    optimizermi    .enabled := false;
    cleanupmi      .enabled := false;
    showreddotmi   .enabled := false;
    // about popup
    aboutbtn       .enabled := false;
    // zoom
    inczoombtn     .enabled := false;
    deczoombtn     .enabled := false;
    fitbtn         .enabled := false;
    nextbtn        .enabled := false;
    backbtn        .enabled := false;
    // steps
    beginbtn       .enabled := false;
    backbtn        .enabled := false;
    nextbtn        .enabled := false;
    endbtn         .enabled := false;
    decstepsbtn    .enabled := false;
    incstepsbtn    .enabled := false;
    // screen
    screen         .enabled := false;
  end else
  begin
    // connection
    portcb         .enabled := value and (not serialstream.connected);
    portbtn        .enabled := value;
    // calibration
    stepnumberedt  .enabled := value and serialstream.connected;
    xupbtn         .enabled := value and serialstream.connected;
    xdownbtn       .enabled := value and serialstream.connected;
    yupbtn         .enabled := value and serialstream.connected;
    ydownbtn       .enabled := value and serialstream.connected;
    penupbtn       .enabled := value and serialstream.connected;
    pendownbtn     .enabled := value and serialstream.connected;
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
    startbtn       .enabled := value and serialstream.connected;
    killbtn        .enabled := value and serialstream.connected;
    homebtn        .enabled := value and serialstream.connected;
    // tools
    setupmi        .enabled := value;
    optimizemi     .enabled := value;
    optimizermi    .enabled := value;
    cleanupmi      .enabled := value;
    showreddotmi   .enabled := value;
    // about popup
    aboutbtn       .enabled := value;
    // zoom
    inczoombtn     .enabled := value;
    deczoombtn     .enabled := value;
    fitbtn         .enabled := value;
    nextbtn        .enabled := value;
    backbtn        .enabled := value;
    // steps
    beginbtn       .enabled := value;
    backbtn        .enabled := value;
    nextbtn        .enabled := value;
    endbtn         .enabled := value;
    decstepsbtn    .enabled := value;
    incstepsbtn    .enabled := value;
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

// DRIVER THREAD EVENTS

procedure tmainform.onplotterstart;
begin
  lock;

  progressbar.position := 0;
  progressbar.visible  := true;
  startbtn.caption     := 'Stop';
  startbtn.imageindex  := 7;
  application.processmessages;
end;

procedure tmainform.onplotterstopandraise;
begin
  driver := nil;
  penbtnclick(penupbtn);
end;

procedure tmainform.onplotterstop;
begin
  driver := nil;
  unlock;

  progressbar.visible := false;
  startbtn.caption    := 'Start';
  startbtn.imageindex := 6;
  application.processmessages;
end;

procedure tmainform.onplotterinit;
var
  cx, cy, kb, ki: longint;
begin
  setting.load(getsettingfilename(true));
  // ---
  driverengine.calcsteps(setting.origin, cx,  cy);
  if not serverset(serialstream, server_setxcount, cx) then
    messagedlg('XY-Plot Client', 'Axis X syncing error !',   mterror, [mbok], 0);
  if not serverget(serialstream, server_getxcount, cx) then
    messagedlg('XY-Plot Client', 'Axis X checking error !',  mterror, [mbok], 0);
  if not serverset(serialstream, server_setycount, cy) then
    messagedlg('XY-Plot Client', 'Axis Y syncing error !',   mterror, [mbok], 0);
  if not serverget(serialstream, server_getycount, cy) then
    messagedlg('XY-Plot Client', 'Axis Y checking error !',  mterror, [mbok], 0);
//if not serverset(serialstream, server_setzcount, cz) then
//  messagedlg('XY-Plot Client', 'Axis Z syncing error !',   mterror, [mbok], 0);
//if not serverget(serialstream, server_getzcount, cz) then
//  messagedlg('XY-Plot Client', 'Axis Z checking error !',  mterror, [mbok], 0);
  kb := setting.rampkb;
  if not serverset(serialstream, server_setrampkb, kb) then
    messagedlg('XY-Plot Client', 'Ramp KB syncing error !',  mterror, [mbok], 0);
  if not serverget(serialstream, server_getrampkb, kb) then
    messagedlg('XY-Plot Client', 'Ramp KB checking error !', mterror, [mbok], 0);
  ki := setting.rampki;
  if not serverset(serialstream, server_setrampki, ki) then
    messagedlg('XY-Plot Client', 'Ramp KI syncing error !',  mterror, [mbok], 0);
  if not serverget(serialstream, server_getrampki, ki) then
    messagedlg('XY-Plot Client', 'Ramp KI checking error !', mterror, [mbok], 0);
  application.processmessages;
end;

procedure tmainform.onplottertick;
begin
  progressbar.position := driver.percentage;
  application.processmessages;
end;

procedure tmainform.onplottererror;
begin
  messagedlg('XY-Plot Client', driver.message, mterror, [mbok], 0);
  application.processmessages;
end;

// OPTIMIZER THREAD EVENTS

procedure tmainform.onoptimizerstart;
begin
  lock;
  isneededoptimize     := false;
  progressbar.position := 0;
  progressbar.visible  := true;
  application.processmessages;
end;

procedure tmainform.onoptimizerstop;
begin
  updatescreen;
  optimizer := nil;
  unlock;

  progressbar.visible := false;
  application.processmessages;
end;

procedure tmainform.onoptimizerstopandprint;
begin
  onoptimizerstop;
  startmiclick(startbtn);
end;

procedure tmainform.onoptimizertick;
begin
  progressbar.position := optimizer.percentage;
  application.processmessages;
end;


end.

