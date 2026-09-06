# ========================================================================================
#
#                                   Wayout
#                              Argument Parser
#
# ========================================================================================

proc printHelp() =
  echo """Wayout:
  A lightweight logout menu for Wayland compositors.
  Copyright (C) 2026 by Mac Taylor

Usage:
  wayout [options...]

Options:
  -h, --help                       Show this help message
  -v, --version                    Show version number
  -d, --default-config             Copy default config to home dir
  -c, --config </path/to/config>   Specify a config file
  -l, --layout </path/to/layout>   Specify a layout file (deprecated)
  -S, --css </path/to/style.css>   Specify a css file
  -b, --buttons-per-row <0-x>      Set the number of buttons per row
  -V, --vertical-spacing <0-x>     Set space between button columns
  -H, --horizontal-spacing <0-x>   Set space between button rows
  -m, --margin <0-x>               Set margin all around buttons
  -T, --margin-top <0-x>           Set margin for top of buttons
  -B, --margin-bottom <0-x>        Set margin for bottom of buttons
  -L, --margin-left <0-x>          Set margin for left of buttons
  -R, --margin-right <0-x>         Set margin for right of buttons
  -s, --show-binds                 Show keybinds on buttons
"""

proc parseIntValue(key, val: string): int =
  if val == "":
    stderr.writeLine "Error: Option '-" & key & "' requires an integer value."
    quit(1)
  try:
    return parseInt(val)
  except ValueError:
    stderr.writeLine "Error: '" & val & "' is not a valid integer for option '-" & key & "'."
    quit(1)

proc processArgs(): bool =
  var p = initOptParser(
    commandLineParams(),
    shortNoVal = {'h', 'v', 'd', 's'},
    longNoVal = @["help", "version", "default-config", "show-binds"],
    mode = CliMode.LaxMode
  )

  while true:
    p.next()
    case p.kind
    of cmdEnd:
      break
    of cmdArgument:
      echo "Error: Unknown argument \nUse -h for help \n"
      quit(1)
    of cmdShortOption, cmdLongOption:
      case p.key
      of "h", "help":
        printHelp()
        return true
      of "v", "version":
        echo "wayout version: " & version
        return true
      of "d", "default-config":
        initDefaultConfig()
        return true

      # Check string values
      of "c", "config": 
        if p.val == "":
          stderr.writeLine "Error: Option '-" & p.key & "' requires a path value."
          quit(1)
        configPath = p.val
      of "l", "layout": 
        if p.val == "":
          stderr.writeLine "Error: Option '-" & p.key & "' requires a path value."
          quit(1)
        layoutPath = p.val
      of "S", "css": 
        if p.val == "":
          stderr.writeLine "Error: Option '-" & p.key & "' requires a CSS file path."
          quit(1)
        cssPath = p.val

      # Check integer values
      of "b", "buttons-per-row": buttonsPerRow = parseIntValue(p.key, p.val)
      of "V", "vertical-spacing": spacing[1] = parseIntValue(p.key, p.val)
      of "H", "horizontal-spacing": spacing[0] = parseIntValue(p.key, p.val)
      of "m", "margin":
        let val = parseIntValue(p.key, p.val)
        margins[0] = val
        margins[1] = val
        margins[2] = val
        margins[3] = val
      of "T", "margin-top": margins[0] = parseIntValue(p.key, p.val)
      of "B", "margin-bottom": margins[1] = parseIntValue(p.key, p.val)
      of "L", "margin-left": margins[2] = parseIntValue(p.key, p.val)
      of "R", "margin-right": margins[3] = parseIntValue(p.key, p.val)

      # Check bool values
      of "s", "show-binds": showBinds = true

      #[
      of "p", "protocol":
        if p.val == "":
          stderr.writeLine "Error: Option '-" & p.key & "' requires a protocol ('layer-shell' or 'xdg')."
          quit(1)
        case p.val
        of "layer-shell": protocol = true
        of "xdg": protocol = false
        else:
          stderr.writeLine p.val & " is an invalid protocol"
          quit(1)
      of "n", "no-span": noSpan = true
      of "P", "primary-monitor": primaryMonitor = parseIntValue(p.key, p.val)
      ]#

      else:
        echo "Error: Unknown option '", p.key, "'"
        echo "Use -h for help \n"
        quit(1)

  return false
