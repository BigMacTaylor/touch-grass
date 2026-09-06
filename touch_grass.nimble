# Package

version       = "0.1.0"
author        = "Mac Taylor"
description   = "Lightweight logout menu for Sway / Wayland."
license       = "MIT"
srcDir        = "src"
bin           = @["touch_grass=touch-grass"]

# Dependencies
requires "nim >= 2.2.4"
requires "https://github.com/BigMacTaylor/nim2gtk.git"
requires "parsetoml"

# Foreign Dependencies
foreignDeps  = @["libgtk-3-0", "libgtk-layer-shell0"]

task install, "Custom install task":
  exec "nim c -d:release -d:strip --opt:speed --threads:off -o:bin/touch-grass src/touch_grass.nim"
