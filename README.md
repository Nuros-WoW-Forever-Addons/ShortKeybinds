# ShortKeybinds

**ShortKeybinds** is a lightweight, standalone World of Warcraft addon designed to format and shorten keybind text on default action bar buttons without replacing or breaking the standard Blizzard action bar interface.

---

## 🚀 Features

- 🔢 **Numpad Shortening**: Converts long numpad bindings like `Num Pad 1` -> `N1`, `Num Pad 9` -> `N9`, `Num Pad 0` -> `N0`.
- ⌨️ **Modifier Shortening**: Converts `SHIFT-` -> `S-`, `CTRL-` -> `C-`, `ALT-` -> `A-`, `META-` -> `M-` (e.g., `SHIFT-Num Pad 1` -> `S-N1`, `ALT-CTRL-Num Pad 1` -> `A-C-N1`).
- 🎯 **Numpad Operators & Special Keys**:
  - `Clear` (Numpad 5 without NumLock) -> `Clr`
  - `Num Pad /` -> `N/`
  - `Num Pad *` -> `N*`
  - `Num Pad -` -> `N-`
  - `Num Pad +` -> `N+`
  - `Num Pad .` -> `N.`
  - `Num Pad Enter` -> `NEnt`
- 🖱️ **Mouse & Utility Keys**: Shortens `MouseButton4` -> `M4`, `WheelUp` -> `MwU`, `WheelDown` -> `MwD`, `Spacebar` -> `Spc`, `Page Up` -> `PgUp`, `Insert` -> `Ins`, `Delete` -> `Del`.
- 🎨 **In-Game Options UI**: Graphical panel (`/skb`) with live keybind preview, toggle switches, custom Numpad Clear replacement text, and font size configuration.
- 🔒 **Blizzard Action Bar Safety**: Hooks directly into Blizzard's native `ActionButton_UpdateHotKey` so it automatically stays in sync when changing keybinds, switching specs, stance bars, or action bar pages.

---

## 🛠️ Installation

Copy the `ShortKeybinds` folder into your World of Warcraft `Interface/AddOns/` directory:

```text
World of Warcraft/Interface/AddOns/ShortKeybinds/
├── ShortKeybinds.toc
├── Core.lua
├── OptionsUI.lua
└── README.md
```

Then start or reload World of Warcraft (`/reload`).

---

## 💻 Slash Commands

| Command | Description |
|---|---|
| `/skb` or `/shortkeybinds` | Open the graphical Options UI window |
| `/skb toggle` | Toggle keybind shortening on/off |
| `/skb dash` | Toggle modifier dash separator (`S-N1` vs `SN1`) |
| `/skb hide` | Toggle hiding hotkey text completely |
| `/skb font <size>` | Set custom hotkey font size (8 - 24pt) |
| `/skb reset` | Reset all settings to default |
