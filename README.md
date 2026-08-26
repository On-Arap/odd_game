# ODD

A landscape 2D speedrun platformer. Collect every coin as fast as you can.

Hold run to move the way you face. Jump on the left (or Space). The only way to turn is a wall jump.

Maps live in `assets/maps/` as JSON grids. Ice (`I`) keeps your speed. Mud (`M`) caps it.

## Creating a new map

The map maker is a web-only editor. Run the game in a browser, then open `/mapmaker`:

```bash
flutter run -d chrome
```

Go to `http://localhost:<port>/mapmaker` (replace `<port>` with the port Flutter prints in the terminal).

### Draw the level

1. Set **Width** and **Height**, then click **Apply** to resize the grid.
2. Pick a tile from the palette, then click or drag on the grid to paint.
3. Fill in **Map id** and **Map name** — these are written into the exported JSON.

| Tile | Character | Description |
|------|-----------|-------------|
| Empty | `.` | Air |
| Solid | `#` | Snow/rock ground |
| Ice | `I` | Slippery surface |
| Mud | `M` | Slow surface |
| Player | `P` | Spawn point (exactly one) |
| Coin | `C` | Collectible (at least one) |

Every row in the grid must be the same width. The preview uses the same 16×16 sprites and autotiling as the game.

### Export the JSON

Click **Generate** to open a dialog with the finished map JSON. It is copied to your clipboard automatically — you can also copy again from the dialog.

To edit an existing map, click **Export**, paste its JSON into the text field, and click **Export** again to load it back into the editor.

### Add the map to the game

1. Save the JSON as a new file in `assets/maps/`, for example `assets/maps/06_my_level.json`.
2. Register it in `assets/maps/index.json` by adding the filename to the `levels` array:

```json
{
  "levels": [
    "01_warmup.json",
    "02_kick_turn.json",
    "03_the_shaft.json",
    "04_corridor.json",
    "05_the_fall.json",
    "06_my_level.json"
  ]
}
```

3. Hot restart the app (or stop and run again). The new map appears on the menu.

### Map rules

The game validates maps on load. A level must:

- Use `"format": 1` and `"tileSize": 16`
- Have a non-empty `"id"` and `"name"`
- Contain exactly one `P` (player spawn)
- Contain at least one `C` (coin)
- Use only `.`, `#`, `I`, `M`, `P`, and `C` in the grid

If a map fails to load, check the debug console for the exact error.
