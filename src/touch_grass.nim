# ========================================================================================
#
#                                   Touch Grass
#                                  by Mac Taylor
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
    name: string
    command: string
    label: string
    xalign: float32
    yalign: float32
    keybind: uint32
    circular: bool

var
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

template debug(args: varargs[untyped]) =
  when not defined(release) and not defined(danger):
    system.debugEcho(args)

include /[config, arg_parser]

# ----------------------------------------------------------------------------------------
#                                    Callbacks
# ----------------------------------------------------------------------------------------

proc onBgClick(box: EventBox, event: EventButton): bool =
  for i in 0 ..< numOfMonitors:
    if i != primaryMonitor and windows.len > i:
      destroy(windows[i])
  quit()

proc execute(command: string) =
  if command != "":
    discard execShellCmd(command)

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
    if btn.keybind == key.uint32:
      execute(btn.command)
      return true
  
  return false

# ----------------------------------------------------------------------------------------
#                                    Buttons
# ----------------------------------------------------------------------------------------

proc onBtnClick(btn: gtk.Button, i: int) =
  debug "btn click: ", i
  execute(buttons[i].command)

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
      
      var btnText = buttons[count].label
      if showBinds:
        btnText &= " [" & char(buttons[count].keybind) & "]"

      let btn = newButton(cstring(btnText))
      btn.setName(cstring(buttons[count].name))

      let child = btn.getChild()
      if child != nil:
        let label = cast[Label](child)
        label.setXalign(buttons[count].xalign)
        label.setYalign(buttons[count].yalign)

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

# ----------------------------------------------------------------------------------------
#                                    Main
# ----------------------------------------------------------------------------------------

proc appActivate(app: Application) =
  debug "appActivate"
  let windows = app.getWindows()

  # Check if already running
  if windows.len > 0:
    echo "Error: touch-grass is already running!"
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

  let provider = newCssProvider()
  try:
    discard provider.loadFromPath(cstring(cssPath))
    let screen = getDefaultScreen()
    addProviderForScreen(screen, provider, STYLE_PROVIDER_PRIORITY_USER)
  except:
    stderr.writeLine "Error: Failed to load CSS: " & getCurrentExceptionMsg()

  window.add(clickBox)
  window.showAll()
  window.setFocus(nil)

proc main() =
  let app = newApplication("org.gtk.touch-grass")
  app.connect("activate", appActivate)
  discard app.run()

main()
