# Tacky Tumble

A 3D roll-up game made in Godot 4.7. You play a sticky ball of tape. Anything smaller than about 70% of your diameter sticks to you when you roll over it, and every prop you pick up makes you bigger. Reach each level's size goal before the timer runs out.

| Level | Start | Goal | Time |
|---|---|---|---|
| Kitchen Floor | 10 cm | 1 m | 4:00 |
| Backyard | 50 cm | 5 m | 5:00 |
| Downtown | 3 m | 40 m | 6:00 |

- **Stars:** you get ★ for reaching the goal, ★★ if at least 15% of the time is left, and ★★★ if at least 35% is left. Earning a star on a level unlocks the next one.
- **Tape colours:** six colours, unlocked by your total star count.
- **Bumps:** hitting a wall or a tall prop at full speed knocks your newest prop loose.
- **Free play:** after you win, choose "Keep rolling" to carry on without a timer.

All art and audio are generated in code: props are built from primitive shapes, and the sound effects and music are synthesised at startup. The project has no asset files that need a licence.

## Controls

| Action | Keyboard / mouse | Gamepad |
|---|---|---|
| Roll | WASD / arrow keys | Left stick |
| Turn camera | Mouse, Q / E | Right stick, LB / RB |
| Pause | Esc / P | Start |

## Project layout

| Path | Purpose |
|---|---|
| `scripts/game.gd` | Autoload. Holds the level definitions, save data, settings, input map and UI theme. |
| `scripts/sfx.gd` | Autoload. Procedural sound effects and music. |
| `scripts/props.gd` | Prop catalogue, authored in centimetres, plus the mesh/collider builder. |
| `scripts/level.gd` | Builds a level, places the props and runs the timed loop. |
| `scripts/ball.gd` | The tape ball: movement, pickup, growth, bump-and-drop, and the autopilot. |
| `scripts/hud.gd`, `scripts/settings_panel.gd`, `scripts/menu.gd` | UI. |

Every level is defined in centimetres. Each one has its own `cm_per_unit`, so physics always runs at a comfortable world scale, whether you're collecting crumbs or skyscrapers. `growth` sets how much of a prop's volume gets added to the ball.

## Testing

```bash
tools/autotest.sh          # every level
tools/autotest.sh 0 2      # specific levels
```

The autotest plays each level headlessly with an autopilot at a fixed 60 fps, so a full run takes a few seconds. It fails if a level can't be won or if any script error appears. Use it to check balance after changing spawn counts or `growth`.

## Screenshots

```bash
godot --path . -- --shot=menu.png --shot-at=2                          # main menu
godot --path . --fixed-fps 60 -- --autotest=1 --shot=yard.png --shot-at=60   # autopilot mid-game
```

## Exporting

Export templates for 4.7 need to be installed. `export_presets.cfg` has presets for Windows, macOS and Linux:

```bash
godot --headless --path . --export-release "Windows Desktop" build/windows/TackyTumble.exe
godot --headless --path . --export-release "macOS" build/macos/TackyTumble.zip
godot --headless --path . --export-release "Linux" build/linux/TackyTumble.x86_64
```

The macOS build is ad-hoc signed. Notarize it before you distribute it outside itch.io.

Store page copy is in `store/store_page.md`.
