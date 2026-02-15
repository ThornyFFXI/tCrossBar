# AGENTS.md

## Project Overview

tCrossBar is an Ashita addon for Final Fantasy XI that provides a controller-based cross-bar UI for macro binding and visualization. It is written in Lua and runs within the Ashita addon runtime environment.

## Build/Lint/Test Commands

This is an Ashita game addon - there are no traditional build, lint, or test commands. Development workflow:

- **Testing**: Load the addon in Ashita with `/addon load tCrossBar` and test in-game
- **Reload after changes**: `/addon reload tCrossBar`
- **Deployment**: Copy `addons/tCrossBar` folder to your Ashita installation's addons directory

For local development sync, a Python helper script is provided:
```bash
python update_game_addon.py
```
This copies the addon to a configured Ashita installation path.

## Code Style Guidelines

### Lua Style

- **Lua version**: Targets Lua 5.1/LuaJIT environment within Ashita
- **Indentation**: 4 spaces, no tabs
- **Line length**: No strict limit, but keep lines readable
- **Comments**: No comments in production code (self-documenting code preferred)
- **Semicolons**: Not used at end of statements

### Module Pattern

All modules follow the same pattern:

```lua
local Module = {};

function Module:MethodName(args)
    -- implementation
end

return Module;
```

For object-oriented patterns with inheritance:

```lua
function Module:New()
    local o = {};
    setmetatable(o, self);
    self.__index = self;
    return o;
end
```

### Imports

Imports are placed at the top of each file:

```lua
local d3d8 = require('d3d8');
local ffi = require('ffi');
local chat = require('chat');
local gdi = require('gdifonts.include');
local ModuleName = require('path.to.module');
```

- Use `local` for all require statements
- Module paths use dots for directory separators
- Standard library modules: `d3d8`, `ffi`, `jit`
- Ashita modules: `chat`, `common`, `imgui`
- Project modules: Use relative paths like `updaters.spell`, `state.player`

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Modules/Classes | PascalCase | `SingleDisplay`, `TextureCache` |
| Functions/Methods | PascalCase for public | `function Module:Initialize()` |
| Local functions | camelCase | `local function getSpellRecast()` |
| Local variables | camelCase | `local spellCostDisplay` |
| Constants | PascalCase | `ComboMode = { Inactive = 0, ... }` |
| Global state | g-prefix + PascalCase | `gSettings`, `gBindings`, `gController` |
| Boolean variables | descriptive names with is/has prefixes | `isComboPressed`, `dragActive` |
| Tables | PascalCase for types | `T{}`, `{ Name = "Base", Bindings = T{} }` |

### Tables

Use Ashita's `T{}` for table literals when using table methods:

```lua
local items = T{ 1, 2, 3 };
items:append(4);
if items:contains(value) then
    -- ...
end
```

For regular tables without method needs:

```lua
local config = { Width = 100, Height = 50 };
```

### Types and Nil Handling

- Always check for nil before using values
- Use early returns for nil/guard clauses:

```lua
function Module:GetElementByMacro(macroState, macroIndex)
    if (self.Valid == false) then
        return;
    end
    local group = self.ElementGroups[macroState];
    if (group ~= nil) then
        local element = group[macroIndex];
        if (element ~= nil) then
            return element;
        end
    end
end
```

- Prefer explicit nil checks: `if (value == nil)` or `if (value ~= nil)`
- For boolean checks: `if (self.Valid == false)` is preferred over `if not self.Valid`

### Parentheses Style

- Conditions in `if` statements are wrapped in parentheses:

```lua
if (condition) then
    -- ...
elseif (otherCondition) then
    -- ...
end
```

- Function calls with single string/table argument use parentheses:

```lua
require('module');
func('string');
```

### Error Handling

Use the provided `Error()` and `Message()` functions for user-facing output:

```lua
function Error(text)
    -- Prints error message with red highlighting
end

function Message(text)
    -- Prints info message with green highlighting
end
```

Usage:
```lua
if (args[4] == nil) then
    Error('Command Syntax: $H/tc palette add [name]$R.');
    return;
end
Message('Created palette!');
```

- `$H` and `$R` are highlighting markers for error/message text
- Always return early after reporting errors

### File Safety

When loading files, use safe patterns:

```lua
function LoadFile_s(filePath)
    if (filePath == nil) then
        return nil;
    end
    if not ashita.fs.exists(filePath) then
        return nil;
    end
    local success, loadError = loadfile(filePath);
    if not success then
        Error(string.format('Failed to load resource file: $H%s', filePath));
        return nil;
    end
    local result, output = pcall(success);
    if not result then
        Error(string.format('Failed to execute resource file: $H%s', filePath));
        return nil;
    end
    return output;
end
```

### Event Registration

Register events using Ashita's event system:

```lua
ashita.events.register('load', 'load_cb', function()
    -- initialization
end);

ashita.events.register('command', 'command_cb', function(e)
    -- command handling
end);

ashita.events.register('packet_in', 'packet_handler', function(e)
    -- packet handling
end);
```

### FFI and Direct3D

When using FFI for Direct3D operations:

```lua
local d3d8 = require('d3d8');
local ffi = require('ffi');

-- Create sprite
local sprite = ffi.new('ID3DXSprite*[1]');
if (ffi.C.D3DXCreateSprite(d3d8.get_device(), sprite) == ffi.C.S_OK) then
    self.Sprite = d3d8.gc_safe_release(ffi.cast('ID3DXSprite*', sprite[0]));
end

-- Use predefined color constants
local d3dwhite = d3d8.D3DCOLOR_ARGB(255, 255, 255, 255);
```

### Settings and Persistence

Use Ashita's settings system:

```lua
-- Settings are auto-loaded/saved
gSettings = settings.load();
-- After modifications:
settings.save();
```

### Partial Function Application

Use `bind1` and `bind2` for partial application:

```lua
self.CostFunction = ManaCost:bind1(self.Resource);
self.CostFunction = ItemCost:bind2(binding.CostOverride);
```

### Coroutine Usage

For delayed execution:

```lua
coroutine.sleep(waitTime);
coroutine.sleepf(frames);
DoMacro:bind1(macroContainer):oncef(0);
```

## Project Structure

```
addons/tCrossBar/
  tCrossBar.lua          -- Entry point, defines addon metadata
  controller.lua         -- Controller input handling
  bindings.lua           -- Binding storage and lookup
  element.lua            -- Base UI element
  singledisplay.lua      -- Single panel display
  doubledisplay.lua      -- Double panel display
  expandeddisplay.lua    -- Expanded display mode
  texturecache.lua       -- Texture caching
  helpers.lua            -- Utility functions
  commands.lua           -- Slash command handling
  callbacks.lua          -- Event callbacks
  initializer.lua        -- Initialization
  bindinggui.lua         -- Binding UI
  configgui.lua          -- Configuration UI
  interface.lua          -- Interface glue code
  updaters/              -- Per-action-type state updaters
    ability.lua
    command.lua
    empty.lua
    item.lua
    spell.lua
    trust.lua
    weaponskill.lua
  state/                 -- Game state tracking
    player.lua
    inventory.lua
    skillchain.lua
  resources/             -- Static resources
    controllers/         -- Controller profiles
    layouts/             -- UI layouts
    spells/              -- Spell icons
    abilities/           -- Ability icons
    wsmap.lua            -- Weaponskill icon mappings
  gdifonts/              -- Font rendering helpers
```

## Key Global Variables

These are initialized by the addon and available globally:

- `gSettings` - User settings
- `gBindings` - Binding manager
- `gController` - Controller handler
- `gSingleDisplay` - Single display instance
- `gDoubleDisplay` - Double display instance
- `gExpandedDisplay` - Expanded display instance
- `gTextureCache` - Texture cache instance
- `gBindingGUI` - Binding GUI instance
- `gConfigGUI` - Configuration GUI instance
- `gInitializer` - Initializer module
