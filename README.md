# Zentle

Zentle is a minimalist note-taking app focused on speed. \
Note: This project is in a very early WIP stage. If it doesn't break, it's probably a bug.  \
WEB DEMO: https://bin-h.itch.io/zentle
<br> <br>
<img width="1280" height="720" alt="front" src="https://github.com/user-attachments/assets/4f24fde3-63ed-476d-ab89-4a9fe5960048" />

### Features

#### Tools (shortcut)

Pen (q)

- draw and hold to begin shape recognition. If a shape is recognized it can then be modified
  
  <img width="150" height="200" alt="rect_shape" src="https://github.com/user-attachments/assets/621e6dc8-6de3-4ad9-9ede-d09600926457" />
  <img width="150" height="200" alt="circ_shape" src="https://github.com/user-attachments/assets/9ac306b9-9e06-4123-a1f1-b390fd3abe00" />

Hand (h) - for panning


Select (s)

- press Ctrl while scaling and moving to snap to the grid
- hold Ctrl while making a box selection to only select objects that are inside the box

Text (t)

- surround the text with \_\_...\_\_ to underline, with \*\*...\*\* to bold
- insert inline LaTex expressions inside \$ ... \$ blocks (Not available in the web demo)

  <img width="334" height="125" alt="lat_rescaled" src="https://github.com/user-attachments/assets/f05a8610-3fc8-4414-ab24-096d9cd10212" />


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

To define a new theme, create a new section that begins with "theme\_" (e.g \[theme_gruvbox\]) \
Each theme has 6 colors (main_text, critical, important, quote, meta, success) + the background and grid colors.

#### File saving

Files are currently saved in a binary format and cannot be exported
