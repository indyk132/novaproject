<div align="center">

# Nova

A **runtime** developer tool for the **Roblox Game Engine** to monitor and
intercept incoming and outgoing network traffic with beautiful opinionated UI.

```lua
loadstring(game:HttpGet("YOUR_HOSTED_URL/Nova.luau"))()
```

</div>

## Features

- Beautiful opinionated dark UI
- Incoming & Outgoing Event **monitoring**
  - Actors support*
  - \_\_index hooking
  - UnreliableRemoteEvent Support
- Incoming & Outgoing Event **interception**
  - Block events
  - Replay events
- Pagination Implementation (prevents lag)
- Copy Calling and Intercept code
- File Logs
- Session Export to HTML
- Built-in Anticheat Bypass (Adonis, etc.)
- DPI Scaling (50%-150%)
- Executor Support Detection

> *Actors are supported even on executors that lack the `run_on_actor` function. As long as the `setfflag` and `getfflag` functions are available in the executor's environment.

## Keybinds

| Key | Action |
|-----|--------|
| Right Shift | Toggle UI visibility |

## Development

### Prerequisites

- [Rokit](https://github.com/rojo-rbx/rokit) - Toolchain manager
- [Rojo](https://github.com/rojo-rbx/rojo) - Roblox project sync
- [Lune](https://lune-org.github.io/docs) - Luau runtime

### Setup

1. Clone this repository
2. Run `rokit install` to install all dependencies
3. Open in VSCode and install recommended extensions

### Bundling

1. Open Powershell and `cd` to this repository
2. Run `rokit install` to install dependencies
3. Press `CTRL + SHIFT + B` in VSCode or run:
   ```
   lune run Build bundle header=Build/Header.luau
   ```
4. The bundled file will be in `Distribution/Script.luau`

## Project Structure

```
Nova/
├── default.project.json     # Rojo project config
├── rokit.toml               # Toolchain dependencies
├── Build/
│   ├── init.luau            # Wax bundler script
│   ├── Header.luau          # Output header
│   └── DarkLua.json         # Minification config
└── Src/
    ├── init.client.luau     # Entry point
    ├── ExecutorSupport.luau # Executor compatibility checks
    ├── Window.luau          # Main UI
    ├── Spy/
    │   ├── Init.luau        # Spy initialization
    │   ├── Actors/          # Actor VM support
    │   └── Hooks/Default/
    │       ├── Outgoing.luau # Outgoing hook (__namecall, functions)
    │       └── Incoming.luau # Incoming hook (OnClientEvent)
    └── Utils/
        ├── Log.luau         # Log entry management
        ├── SaveManager.luau # Settings persistence
        ├── Connect.luau     # Connection management
        ├── Hooking.luau     # Hook utilities
        ├── Pagination.luau  # Pagination logic
        ├── FileLog.luau     # File logging
        ├── CodeGen/         # Code generation
        ├── Serializer/      # LuaEncode (table serializer)
        ├── Anticheats/      # Anticheat detection & bypass
        └── UI/              # UI components
            ├── Interface.luau   # Element creation
            ├── Icons.luau       # Lucide icons
            ├── Sonner.luau      # Toast notifications
            ├── Drag.luau        # Draggable frames
            ├── Resize.luau      # Resizable frames
            ├── Helper.luau      # UI utilities
            ├── Highlighter.luau # Syntax highlighting
            └── ImageFetch.luau  # Image caching
```

## License

Apache License 2.0
