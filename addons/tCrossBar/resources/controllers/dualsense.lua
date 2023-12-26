local state = {
    LStick = {
        Blocking = false,
        State = 'Idle',
        Horizontal = 0,
        Vertical = 0,
    },
    RStick = {
        Blocking = false,
        State = 'Idle',
        Horizontal = 0,
        Vertical = 0,
    },
    Dpad = {
        Blocking = false,
        State = 'Idle',
    },
    L2 = {
        Active = false,
        Blocking = false,
        Intensity = 0,
        Pressed = false,
    },
    R2 = {
        Active = false,
        Blocking = false,
        Intensity = 0,
        Pressed = false,
    }
};

local function HandleStick(stickName, horizontal, vertical)
    local stick = state[stickName];
    if (horizontal == nil) or (math.abs(horizontal) < 42) then
        horizontal = 0;
    end
    if (vertical == nil) or (math.abs(vertical) < 42) then
        vertical = 0;
    end
    stick.Horizontal = horizontal;
    stick.Vertical = vertical;

    local currentState = 'Idle';
    if (vertical ~= 0) then
        currentState = (vertical < 0) and 'Up' or 'Down';
        if (horizontal ~= 0) then
            currentState = currentState .. ((horizontal > 0) and 'Right' or 'Left');
        end
    elseif (horizontal ~= 0) then
        currentState = ((horizontal > 0) and 'Right' or 'Left');
    end

    if (currentState == 'Idle') then
        if (stick.State ~= 'Idle') then
            gController:Trigger(stickName .. '_' .. stick.State, false);
            local block = stick.Blocking;
            stick.Blocking = false;
            stick.State = currentState;
            return block;
        end
    elseif (currentState ~= stick.State) then
        if (stick.State ~= 'Idle') then
            gController:Trigger(stickName .. '_' .. stick.State, false);
        end
        if (gController:Trigger(stickName .. '_' .. currentState, true)) then
            stick.Blocking = true;
        end
    end

    stick.State = currentState;
    return stick.Blocking;
end

local dpadLookup = {
    [-1] = 'Idle',
    [0] = 'Up',
    [4500] = 'UpRight',
    [9000] = 'Right',
    [13500] = 'DownRight',
    [18000] = 'Down',
    [22500] = 'DownLeft',
    [27000] = 'Left',
    [31500] = 'UpLeft',
};

local function HandleDPad(buttonState)
    local currentState = dpadLookup[buttonState] or 'Idle';
    local pad = state.Dpad;

    if (currentState == 'Idle') then
        if (pad.State ~= 'Idle') then
            gController:Trigger('Dpad_' .. pad.State, false);
            local block = pad.Blocking;
            pad.Blocking = false;
            pad.State = currentState;
            return block;
        end
    elseif (currentState ~= pad.State) then
        if (pad.State ~= 'Idle') then
            gController:Trigger('Dpad_' .. pad.State, false);
        end
        if (gController:Trigger('Dpad_' .. currentState, true)) then
            pad.Blocking = true;
        end
    end

    pad.State = currentState;
    return pad.Blocking;
end

local function HandleTrigger(buttonName, intensity, pressed)
    local isActive = (intensity > 0) or (pressed);
    local button = state[buttonName];
    button.Intensity = intensity;
    button.Pressed = pressed;
    
    if (isActive == false) then
        if (button.Active) then
            gController:Trigger(buttonName, false);
            local block = button.Blocking;
            button.Blocking = false;
            button.Active = false;
            return block;
        end
    elseif (button.Active == false) then
        if gController:Trigger(buttonName, true) then
            button.Blocking = true;
        end
    end

    button.Active = isActive;
    return button.Blocking;
end

local function HandleButton(buttonName, buttonState)
    local button = state[buttonName];
    if (button == nil) then
        button = { Blocking = false, State = false };
        state[buttonName] = button;
    end

    if (buttonState == false) then
        if (button.State ~= false) then
            gController:Trigger(buttonName, false);
            local block = button.Blocking;
            button.Blocking = false;
            button.State = false;
            return block;
        end
    elseif (button.State == false) then
        if gController:Trigger(buttonName, true) then
            button.Blocking = true;
        end
    end

    button.State = buttonState;
    return button.Blocking;
end

local layout = {
    --Enable the input method used for this controller only.
    DirectInput = true,
    XInput = false,
    
    --List of all button names available in this layout.
    --Buttons must be triggered in the event handlers with identical names.
    ButtonMap = {
        'Square',
        'Cross',
        'Circle',
        'Triangle',
        'L1',
        'R1',
        'L2',
        'R2',
        'L3',
        'R3',
        'Dpad_Up',
        'Dpad_UpRight',
        'Dpad_Right',
        'Dpad_DownRight',
        'Dpad_Down',
        'Dpad_DownLeft',
        'Dpad_Left',
        'Dpad_UpLeft',
        'LStick_Up',
        'LStick_UpRight',
        'LStick_Right',
        'LStick_DownRight',
        'LStick_Down',
        'LStick_DownLeft',
        'LStick_Left',
        'LStick_UpLeft',
        'RStick_Up',
        'RStick_UpRight',
        'RStick_Right',
        'RStick_DownRight',
        'RStick_Down',
        'RStick_DownLeft',
        'RStick_Left',
        'RStick_UpLeft',
        'Create',
        'Options',
        'Touchpad',
        'Playstation',
        'Microphone',
    },

    --Default controls until user configures bindings.  Must exact match strings in ButtonMap.    
    Defaults = {
        Macro1 = 'Dpad_Up',
        Macro2 = 'Dpad_Right',
        Macro3 = 'Dpad_Down',
        Macro4 = 'Dpad_Left',
        Macro5 = 'Triangle',
        Macro6 = 'Circle',
        Macro7 = 'Cross',
        Macro8 = 'Square',
        ComboLeft = 'L2',
        ComboRight = 'R2',
        PreviousPalette = 'L1',
        NextPalette = 'R1',
        BindingUp = 'Dpad_Up',
        BindingDown = 'Dpad_Down',
        BindingNext = 'Dpad_Right',
        BindingPrevious = 'Dpad_Left',
        BindingConfirm = 'Circle',
        BindingCancel = 'Cross',
        BindingTab = 'Triangle',
    },

    --[[
        Key is the directinput offset, which is the same value used in event callback as 'button'.
        Value is a function that handles the event for that button.  Function should handle blocking
        and forward the resolved button name to addon.
    ]]
    Buttons = {
        --Horizontal L-Stick Movement
        [0] = function(e)
            if HandleStick('LStick', e.state, state.LStick.Vertical) then
                e.blocked = true;
            end
        end,

        --Vertical L-Stick Movement
        [4] = function(e)
            if HandleStick('LStick', state.LStick.Horizontal, e.state) then
                e.blocked = true;
            end
        end,
        
        --Horizontal R-Stick Movement
        [8] = function(e)
            if HandleStick('RStick', e.state, state.RStick.Vertical) then
                e.blocked = true;
            end
        end,
        
        --L2 intensity
        [12] = function(e)
            if HandleTrigger('L2', e.state, state.L2.Pressed) then
                e.blocked = true;
            end
        end,

        --R2 intensity
        [16] = function(e)
            if HandleTrigger('R2', e.state, state.R2.Pressed) then
                e.blocked = true;
            end
        end,

        --Vertical R-Stick Movement
        [20] = function(e)
            if HandleStick('RStick', state.RStick.Horizontal, e.state) then
                e.blocked = true;
            end
        end,
        
        [32] = function(e)
            if HandleDPad(e.state) then
                e.blocked = true;
            end
        end,

        [48] = function(e)
            if HandleButton('Square', e.state == 128) then
                e.blocked = true;
            end
        end,

        [49] = function(e)
            if HandleButton('Cross', e.state == 128) then
                e.blocked = true;
            end
        end,

        [50] = function(e)
            if HandleButton('Circle', e.state == 128) then
                e.blocked = true;
            end
        end,

        [51] = function(e)
            if HandleButton('Triangle', e.state == 128) then
                e.blocked = true;
            end
        end,

        [52] = function(e)
            if HandleButton('L1', e.state == 128) then
                e.blocked = true;
            end
        end,

        [53] = function(e)
            if HandleButton('R1', e.state == 128) then
                e.blocked = true;
            end
        end,

        [54] = function(e)
            if HandleTrigger('L2', state.L2.Intensity, (e.state == 128)) then
                e.blocked = true;
            end
        end,

        [55] = function(e)
            if HandleTrigger('R2', state.R2.Intensity, (e.state == 128)) then
                e.blocked = true;
            end
        end,

        [56] = function(e)
            if HandleButton('Create', e.state == 128) then
                e.blocked = true;
            end
        end,

        [57] = function(e)
            if HandleButton('Options', e.state == 128) then
                e.blocked = true;
            end
        end,

        [58] = function(e)
            if HandleButton('L3', e.state == 128) then
                e.blocked = true;
            end
        end,

        [59] = function(e)
            if HandleButton('R3', e.state == 128) then
                e.blocked = true;
            end
        end,

        [60] = function(e)
            if HandleButton('Playstation', e.state == 128) then
                e.blocked = true;
            end
        end,

        [61] = function(e)
            if HandleButton('Touchpad', e.state == 128) then
                e.blocked = true;
            end
        end,

        [62] = function(e)
            if HandleButton('Microphone', e.state == 128) then
                e.blocked = true;
            end
        end,
    },
};

return layout;