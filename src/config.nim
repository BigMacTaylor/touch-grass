# ========================================================================================
#
#                                   Touch Grass
#                                     Config
#
# ========================================================================================

func getConfigDir(): string =
  # Get XDG_CONFIG_HOME or default "~/.config"
  let dir = getEnv("XDG_CONFIG_HOME", os.getHomeDir() / ".config")
  return dir / "touch-grass"

proc tryFilePath(filePath: string): string =
  let configDir = getConfigDir()

  if fileExists(filePath):
    return filePath
  elif fileExists(configDir / filePath):
    return configDir / filePath
  else:
    stderr.writeLine "Error: Failed to open " & filePath

proc getFilePath(fileName: string): string =
  let configDir = getConfigDir()

  let lookupPaths = [
    configDir / fileName,
    "/etc/touch-grass" / fileName,
    "/usr/local/etc/touch-grass" / fileName
  ]

  for path in lookupPaths:
    if fileExists(path):
      return path

  stderr.writeLine "Error: Failed to find " & fileName

  return ""

proc initDefaultConfig() =
  var defaultConfig = ""
  let lookupPaths = [
    "/etc/touch-grass/config.toml",
    "/usr/local/etc/touch-grass/config.toml"
  ]

  for path in lookupPaths:
    if fileExists(path):
      defaultConfig = path
      continue

  if defaultConfig == "":
    return

  let targetDir = getConfigDir()

  if fileExists(targetDir / "config.toml"):
    return

  # Create directory if missing
  createDir(targetDir)
  copyFileToDir(defaultConfig, targetDir)

# ----------------------------------------------------------------------------------------
#                                    Parse Layout
# ----------------------------------------------------------------------------------------

proc getBraceContent(input: string): string =
  #var result = ""
  var insideBrace = false

  for ch in input:
    if ch == '{':
      result.add(ch)
      insideBrace = true
      continue
    elif ch == '}':
      result.add(ch)
      insideBrace = false
      continue

    if insideBrace:
      result.add(ch)

  return result

proc parseLayout(layoutFile: string): bool =
  try:
    # Read the file and strip any leading/trailing empty space
    let rawContent = readFile(layoutFile).strip()
    if rawContent.len == 0:
      return true

    # Clean up whitespace
    let bracedObjects = rawContent.getBraceContent()

    # Split the file at the boundary between objects "}{"
    let rawObjects = bracedObjects.split("}{")

    for rawObj in rawObjects:
      # Restore the braces stripped away by split()
      var jsonObj = rawObj
      if not jsonObj.startsWith("{"): jsonObj = "{" & jsonObj
      if not jsonObj.endsWith("}"): jsonObj = jsonObj & "}"
      
      # Parse the specific standalone object safely
      let item = parseJson(jsonObj)
      
      var btn: Button
      btn.label = item["label"].getStr()
      btn.action = item["action"].getStr()
      btn.text = item["text"].getStr()
      btn.yalign = 0.9'f32
      btn.xalign = 0.5'f32
      btn.circular = false
      
      if item.hasKey("keybind"):
        let kb = item["keybind"].getStr()
        if kb.len == 1:
          btn.bind = uint32(kb[0])
      
      if item.hasKey("height"):
        btn.yalign = float32(item["height"].getFloat())
      
      if item.hasKey("width"):
        btn.xalign = float32(item["width"].getFloat())
      
      if item.hasKey("circular"):
        btn.circular = item["circular"].getBool()

      buttons.add(btn)
    
    numButtons = buttons.len
    return true
  except:
    stderr.writeLine "Failed to parse layout file: " & getCurrentExceptionMsg()
    return false

# ----------------------------------------------------------------------------------------
#                                    Parse Config
# ----------------------------------------------------------------------------------------

proc parseConfig(configFile: string): bool =
  let config =
    try:
      parsetoml.parseFile(configFile)
    except:
      echo "Error: Failed to parse configuration file"
      return false

  # Get Window Settings
  if config.hasKey("Window"):
    let winTable = config["Window"]
    buttonsPerRow = winTable.getOrDefault("buttons_per_row").getInt(buttonsPerRow)
    spacing[1] = winTable.getOrDefault("column_spacing").getInt(spacing[1])
    spacing[0] = winTable.getOrDefault("row_spacing").getInt(spacing[0])
    if winTable.hasKey("margin_all"):
      let val = winTable.getOrDefault("margin_all").getInt(230)
      margins[0] = val
      margins[1] = val
      margins[2] = val
      margins[3] = val
    else:
      margins[0] = winTable.getOrDefault("margin_top").getInt(margins[0])
      margins[1] = winTable.getOrDefault("margin_bottom").getInt(margins[1])
      margins[2] = winTable.getOrDefault("margin_left").getInt(margins[2])
      margins[3] = winTable.getOrDefault("margin_right").getInt(margins[3])

    showBinds = winTable.getOrDefault("show_binds").getBool(showBinds)

  # Get Buttons
  if not config.hasKey("Button"):
    return true

  let btnElems = config["Button"].getElems()
  for elem in btnElems:
    var btn: Button
    btn.label = elem["label"].getStr()
    btn.action = elem["action"].getStr()
    btn.text = elem["text"].getStr()
    btn.yalign = 0.9'f32
    btn.xalign = 0.5'f32
    btn.circular = false

    if elem.hasKey("keybind"):
      let kb = elem["keybind"].getStr()
      if kb.len == 1:
        btn.bind = uint32(kb[0])

    if elem.hasKey("height"):
      btn.yalign = float32(elem["height"].getFloat())

    if elem.hasKey("width"):
      btn.yalign = float32(elem["width"].getFloat())

    if elem.hasKey("circular"):
      btn.circular = elem["circular"].getBool()

    buttons.add(btn)

  numButtons = buttons.len
  return true
