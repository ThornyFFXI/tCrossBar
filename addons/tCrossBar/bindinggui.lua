local imgui = require('imgui');
local header = { 1.0, 0.75, 0.55, 1.0 };
local activeHeader = { 0.5, 1.0, 0.5, 1.0 };

local macroStateText = {
    [1] = 'Left Trigger',
    [2] = 'Right Trigger',
    [3] = 'Both Triggers (Left First)',
    [4] = 'Both Triggers (Right First)',
    [5] = 'Left Trigger (Double Tap)',
    [6] = 'Right Trigger (Double Tap)'
};

local buttonText = {
    'Left Grouping, Top Square',
    'Left Grouping, Right Square',
    'Left Grouping, Bottom Square',
    'Left Grouping, Left Square',
    'Right Grouping, Top Square',
    'Right Grouping, Right Square',
    'Right Grouping, Bottom Square',
    'Right Grouping, Left Square'
};

local macroComboBinds = {
    [1] = 'LT',
    [2] = 'RT',
    [3] = 'LTRT',
    [4] = 'RTLT',
    [5] = 'LT2',
    [6] = 'RT2'
};

local state = {
    IsOpen = { false },
    MacroState = 0,
    MacroButton = 0,
    Hotkey = nil,
    RepeatButton = nil,
    RepeatTime = 0,
    RepeatDelay = 0.3,
    ForceDisplay = nil,
    ForceState = 0,
};

local function GetMacroStateText(macroState)
    if (macroState == 3) and (gSettings.EnableDoubleTap == false) then
        return 'Both Triggers';
    end
    return macroStateText[macroState];
end

local function AttemptBind(hotkey, binding)
    if (binding == nil) then
        if (state.Indices and state.Indices.Scope == 1) then
            gBindings:BindGlobal(hotkey, nil);
        elseif (state.Indices and state.Indices.Scope == 2) then
            gBindings:BindJob(hotkey, nil);
        else
            gBindings:BindPalette(hotkey, nil);
        end
        return true;
    end
    
    local scope = binding.Scope or 3;
    if (scope == 1) then
        gBindings:BindGlobal(hotkey, binding);
    elseif (scope == 2) then
        gBindings:BindJob(hotkey, binding);
    else
        gBindings:BindPalette(hotkey, binding);
    end
    return true;
end

local exposed = {};

function exposed:Close()
    state.IsOpen[1] = false;
    state.MacroState = 0;
    state.MacroButton = 0;
    state.Hotkey = nil;
    gMacroEditor:Close();
end

function exposed:GetActive()
    return (state.IsOpen[1] == true) or gMacroEditor:GetActive();
end

function exposed:GetMacroState()
    if (state.IsOpen[1] == true) then
        return state.MacroState;
    end
    return 0;
end

function exposed:HandleButton(button, pressed)
    if (not pressed) then
        if (button == state.RepeatButton) then
            state.RepeatButton = nil;
        end
        return;
    end
    
    if (gMacroEditor:GetActive()) then
        return;
    end
    
    if (button == state.RepeatButton) then
        if (state.RepeatDelay > 0.05) then
            state.RepeatDelay = state.RepeatDelay - 0.05;
        end
        state.RepeatTime = os.clock();
    else
        state.RepeatButton = button;
        state.RepeatTime = os.clock();
        state.RepeatDelay = 0.3;
    end
    
    if (button == 'BindingConfirm') then
        if (state.Hotkey) then
            local square = gSingleDisplay:GetElementByMacro(state.MacroState, state.MacroButton);
            if square then
                AttemptBind(state.Hotkey, square.Binding);
            end
        end
        self:Close();
    end
    
    if (button == 'BindingCancel') then
        self:Close();
    end
end

function exposed:Render()
    if (state.RepeatButton ~= nil) and (os.clock() > (state.RepeatTime + state.RepeatDelay)) then
        self:HandleButton(state.RepeatButton, true);
    end
    
    if (state.IsOpen[1] == false) then
        self.ForceDisplay = nil;
    else
        self.ForceDisplay = gSingleDisplay;
        self.ForceState = state.MacroState;
    end
end

function exposed:Show(macroState, macroButton)
    local square = gSingleDisplay:GetElementByMacro(macroState, macroButton);
    if square == nil then
        state.IsOpen[1] = false;
        return;
    end

    local hotkey = string.format('%s:%s', macroComboBinds[macroState], macroButton);
    state.IsOpen[1] = true;
    state.MacroState = macroState;
    state.MacroButton = macroButton;
    state.Hotkey = hotkey;
    
    local binding = square.Binding;
    local initialScope = 3;
    if (binding and binding.Scope) then
        initialScope = binding.Scope;
    end
    
    gMacroEditor:Show(hotkey, binding, function(hk, newBinding)
        AttemptBind(hk, newBinding);
        self:Close();
    end, function()
        self:Close();
    end, { showScope = true, initialScope = initialScope });
end

function exposed:UpdatePalette()
    if (state.MacroState > 0) then
        self:Show(state.MacroState, state.MacroButton);
    end
end

return exposed;