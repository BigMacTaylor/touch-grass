# ========================================================================================
#
#                                   Wayout
#                                by Mac Taylor
#
# ========================================================================================

const version = "0.1.0"

import std/[os, posix]
import std/[strutils, parseopt, json]
import nim2gtk/[gtk, glib, gdk, gio]
import nim2gtk/[gobject, gtklayershell]
import parsetoml

type
  Button = object
    label: string
    action: string
    text: string
    yalign: float32
    xalign: float32
    `bind`: uint32
    circular: bool

var
  command: string = ""
  configPath: string = ""
  layoutPath: string = ""
  cssPath: string = ""
  buttons: seq[Button] = @[]
  window: gtk.Window = nil
  numButtons: int = 0
  numOfMonitors: int = 0
  windows: seq[gtk.Window] = @[]
  buttonsPerRow: int = 3
  primaryMonitor: int = -1
  margins: array[4, int] = [400, 400, 600, 600]
  spacing: array[2, int] = [0, 0]
  showBinds: bool = false

include /[config, arg_parser]

# ----------------------------------------------------------------------------------------
#                                    Callbacks
# ----------------------------------------------------------------------------------------

proc onBgClick(box: EventBox, event: EventButton): bool =
  for i in 0 ..< numOfMonitors:
    if i != primaryMonitor and windows.len > i:
      destroy(windows[i])
  quit()

proc execute(action: cstring) {.cdecl.} =
  command = $action
  destroy(window)
  for i in 0 ..< numOfMonitors:
    if i != primaryMonitor and windows.len > i:
      destroy(windows[i])
  quit()

proc onKeyPress(widget: gtk.Window; event: gdk.EventKey): bool =
  let key = event.getKeyval

  if key == gdk.KEY_Escape:
    quit()
  
  for btn in buttons:
    if btn.bind == key.uint32:
      execute(btn.action.cstring)
      return true
  
  return false

# ----------------------------------------------------------------------------------------
#                                    Buttons
# ----------------------------------------------------------------------------------------

proc onBtnClick(btn: gtk.Button, count: int) =
  echo "btn click"
  execute(buttons[count].action.cstring)

proc onBtnHover(btn: gtk.Button, event: EventCrossing): bool =
  #if not focusProtect:
  btn.grabFocus()
  return true
 
proc onBtnLeave(btn: gtk.Button, event: EventCrossing): bool =
  #if not focusProtect:
  window.setFocus(nil)
  return true

proc createButtons(container: EventBox) =
  let grid = newGrid()
  container.add(grid)
  grid.setRowSpacing(int(spacing[0]))
  grid.setColumnSpacing(int(spacing[1]))
  
  grid.setMarginTop(margins[0])
  grid.setMarginBottom(margins[1])
  grid.setMarginStart(margins[2])
  grid.setMarginEnd(margins[3])

  let numCol = if (numButtons mod buttonsPerRow) == 0: 
    (numButtons div buttonsPerRow) 
  else: 
    (numButtons div buttonsPerRow) + 1

  var count = 0
  for i in 0 ..< buttonsPerRow:
    for j in 0 ..< numCol:
      if count >= numButtons:
        break
      
      var btnText = buttons[count].text
      if showBinds:
        btnText &= " [" & char(buttons[count].bind) & "]"

      let btn = newButton(cstring(btnText))
      btn.setName(cstring(buttons[count].label))

      let label = cast[Label](btn.getChild())
      label.setYalign(buttons[count].yalign)
      label.setXalign(buttons[count].xalign)

      if buttons[count].circular:
        let context = btn.getStyleContext()
        context.addClass("circular")

      btn.connect("clicked", onBtnClick, count)
      btn.connect("enter-notify-event", onBtnHover)
      btn.connect("leave-notify-event", onBtnLeave)
      btn.setHexpand(true)
      btn.setVexpand(true)
      grid.attach(btn, i, j, 1, 1)
      
      inc count

proc loadCss(path: string) =
  if path == "":
    return

  let provider = newCssProvider()
  try:
    discard provider.loadFromPath(cstring(path))
    let screen = getDefaultScreen()
    addProviderForScreen(screen, provider, STYLE_PROVIDER_PRIORITY_USER)
  except:
    stderr.writeLine "Failed to load CSS: " & getCurrentExceptionMsg()

# ----------------------------------------------------------------------------------------
#                                    Main
# ----------------------------------------------------------------------------------------

proc appActivate(app: Application) =
  let windows = app.getWindows()

  # Check if already running
  if windows.len > 0:
    echo "Error: Wayout is already running!"
    quit(1)

  if processArgs():
    return

  # Load config from arg
  if configPath != "":
    configPath = tryFilePath(configPath)
    if not parseConfig(configPath):
      quit(3)
  elif layoutPath != "":
    layoutPath = tryFilePath(layoutPath)
    if not parseLayout(layoutPath):
      quit(3)
  else:
    # Try to find config file
    configPath = getFilePath("config.toml")
    if configPath != "":
      if not parseConfig(configPath):
        quit(3)
    else:
      # Load legacy layout file
      layoutPath = getFilePath("layout")
      if not parseLayout(layoutPath):
        quit(3)

  # Load css from arg
  if cssPath != "":
    cssPath = tryFilePath(cssPath)
  else:
    # Try to find css file
    cssPath = getFilePath("style.css")

  # Create window
  window = newApplicationWindow(app)

  # Before the window is first realized, set it up to be a layer surface.
  initForWindow(window)
  setLayer(window, Layer.overlay)
  setExclusiveZone(window, -1)

  # Anchors pin the window to specific edges of the screen
  window.setAnchor(Edge.top, true)
  window.setAnchor(Edge.left, true)
  window.setAnchor(Edge.right, true)
  window.setAnchor(Edge.bottom, true)

  # Get keyboard input
  window.setKeyboardMode(KeyboardMode.exclusive)
  window.connect("key-press-event", onKeyPress)

  # Have to create event box to handle clicks, because
  # Gtk Window wont release focus after first click. Gtk bug?
  let clickBox = newEventBox()
  clickBox.createButtons()
  clickBox.connect("button-press-event", onBgClick)
  #clickBox.connect("motion-notify-event", onBgMotion)

  loadCss(cssPath)

  window.add(clickBox)
  window.showAll()
  window.setFocus(nil)

  if command != "":
    discard execShellCmd(command)

proc main() =
  let app = newApplication("org.gtk.wayout")
  app.connect("activate", appActivate)
  discard app.run()

main()
