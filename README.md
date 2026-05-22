# Zentle

Zentle is a minimalist note-taking app focused on speed. \
Note: This project is in a very early WIP stage. If it doesn't break, it's probably a bug.  \
WEB DEMO: https://bin-h.itch.io/zentle
<br> <br>
<img width="1280" height="720" alt="front1" src="https://github.com/user-attachments/assets/d6e807a2-b46b-4348-b449-2b8fc3a90f7c" />

---
## Index
* [Quick start](#quick-start)
* [Features](#features)
* [Saving and Exporting](#saving-and-exporting)

---

### Quick Start

Install the latest .NET version of Godot: https://godotengine.org/download.
Make sure to have the .NET SDK installed on your system.

Download the source code and run the project.

---

### Features

#### Tools (shortcut)

_Pen (q)_

- draw and hold to begin shape recognition. If a shape is recognized it can then be modified
- hold Ctrl + Shift to use [Ink Spells](#ink-spells)
  
  <img width="150" height="200" alt="rect_shape" src="https://github.com/user-attachments/assets/621e6dc8-6de3-4ad9-9ede-d09600926457" />
  <img width="150" height="200" alt="circ_shape" src="https://github.com/user-attachments/assets/9ac306b9-9e06-4123-a1f1-b390fd3abe00" />

_Hand (h)_ - for panning


_Select (s)_

- press Ctrl while scaling and moving to snap to the grid and shift to keep proportions
- hold Ctrl while making a box selection to only select objects that are inside the box
- hold down the Select tool button (or press r), to use [Export Regions](#saving-and-exporting)

_Text (t)_

- surround the text with \_\_...\_\_ to underline, with \*\*...\*\* to bold
- insert inline LaTex expressions inside \$ ... \$ blocks (Not available in the web demo)

  <img width="334" height="125" alt="lat_rescaled" src="https://github.com/user-attachments/assets/f05a8610-3fc8-4414-ab24-096d9cd10212" />

LaTex is rendered through [CSharpMath](https://github.com/verybadcat/CSharpMath)

#### Themes

Press **Ctrl + Shift + t** (just Y in the web demo) to open the theme selector. The listed themes are loaded from the config file.


https://github.com/user-attachments/assets/dcf0cc23-09bf-4745-bc5b-e673d74939aa


#### Config File (settings.cfg)

- on linux: ~/.local/share/zentle/
- on windows: %APPDATA%\zentle\

Created when first opened
(e.g settings.cfg)

```
[theme_default]

main_text="#c9c1b1ff"
critical="#eb9486ff"
important="#cc506bff"
quote="#b8b8f3ff"
meta="#2274a5ff"
success="#65b085ff"
background_color="#212121ff"
grid_color="#2c2c2cff"

[editor]

sq_size=100
ctrl_to_zoom=false
current_theme="theme_default"
realtime_move_scale=true
grid_weight=2
...

```

To define a new theme, create a new section that begins with "theme\_" (e.g. \[theme_gruvbox\]) \
Each theme has 6 colors (main_text, critical, important, quote, meta, success) + the background and grid colors.

---

### Ink Spells

_Ink Spells_ are useful when you have to draw certain objects regularly (e.g. Logic Gates, Cartesian planes, ...) \
Each _Spell_ needs to be saved in it's own file (centered to the origin). \
For example, let's say we want to add a XOR gate into the notes when we write "XOR". \
1) Create and save a file (e.g. xor.zentle) containing a drawn version of the port.
2) Go to Options > Ink Spells and press the "+" button
3) Set the _trigger_ to "XOR" and select the previously saved file
4) When Zentle is presented with new letters inside a trigger, it will request you to write them once on the box to the right.
5) Use _spells_ while using the pen by holding down Ctrl + Shift

---

### Saving and Exporting

#### Saving
Files are saved in a binary format (_.zentle_) that uses the Zstandard compression method.

#### Exporting
Zentle supports PDF and SVG export through [SkiaSharp](https://github.com/mono/skiasharp).
To export notes, you need to use _Export Regions_ to define the areas you want to output.
Each _Export Region_ contains a __Title__ and a __Export on/off__ state. The latter is used to determin whether the _Region_ is included in the exported file or not. 

You can _Select_ a _Region_ (to Scale/Move) only by selecting it's edges.

To change export order and create the final output, navigate to the _Options > Export_ tab (Ctrl + Shift + t or from the File menu).

