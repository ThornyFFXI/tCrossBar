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
};

local function HandleStick(stickName, horizontal, vertical)
    local stick = state[stickName];
    if (horizontal == nil) or (math.abs(horizontal) < 10837) then
        horizontal = 0;
    end
    if (vertical == nil) or (math.abs(vertical) < 10837) then
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

local offset = 32;
if (ashita.interface_version ~= nil) then
    offset = 16;
end

local layout = {
    --Enable the input method used for this controller only.
    DirectInput = false,
    XInput = true,
    
    --List of all button names available in this layout.
    --Buttons must be triggered in the event handlers with identical names.
    ButtonMap = {
        'A',
        'B',
        'X',
        'Y',
        'L1',
        'R1',
        'L2',
        'R2',
        'L3',
        'R3',
        'Dpad_Up',
        'Dpad_Right',
        'Dpad_Down',
        'Dpad_Left',
        'Menu',
        'View',
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
    },

    --Default controls until user configures bindings.  Must exact match strings in ButtonMap.    
    Defaults = {
        Macro1 = 'Dpad_Up',
        Macro2 = 'Dpad_Right',
        Macro3 = 'Dpad_Down',
        Macro4 = 'Dpad_Left',
        Macro5 = 'Y',
        Macro6 = 'B',
        Macro7 = 'A',
        Macro8 = 'X',
        ComboLeft = 'L2',
        ComboRight = 'R2',
        PreviousPalette = 'L1',
        NextPalette = 'R1',
        BindingUp = 'Dpad_Up',
        BindingDown = 'Dpad_Down',
        BindingNext = 'Dpad_Right',
        BindingPrevious = 'Dpad_Left',
        BindingConfirm = 'A',
        BindingCancel = 'B',
        BindingTab = 'Y',
    },

    --[[
        Key is the value used in event callback as 'button'.
        Value is a function that handles the event for that button.  Function should handle blocking
        and forward the resolved button name to addon.
    ]]
    Buttons = {
        --Dpad Up
        [0] = function(e)
            if HandleButton('Dpad_Up', e.state == 1) then
                e.blocked = true;
            end
        end,
        
        --Dpad Down
        [1] = function(e)
            if HandleButton('Dpad_Down', e.state == 1) then
                e.blocked = true;
            end
        end,
        
        --Dpad Left
        [2] = function(e)
            if HandleButton('Dpad_Left', e.state == 1) then
                e.blocked = true;
            end
        end,
        
        --Dpad Right
        [3] = function(e)
            if HandleButton('Dpad_Right', e.state == 1) then
                e.blocked = true;
            end
        end,
        
        --Menu
        [4] = function(e)
            if HandleButton('Menu', e.state == 1) then
                e.blocked = true;
            end
        end,
        
        --View
        [5] = function(e)
            if HandleButton('View', e.state == 1) then
                e.blocked = true;
            end
        end,
        
        --L3
        [6] = function(e)
            if HandleButton('L3', e.state == 1) then
                e.blocked = true;
            end
        end,
        
        --R3
        [7] = function(e)
            if HandleButton('R3', e.state == 1) then
                e.blocked = true;
            end
        end,
        
        --L1
        [8] = function(e)
            if HandleButton('L1', e.state == 1) then
                e.blocked = true;
            end
        end,
        
        --R1
        [9] = function(e)
            if HandleButton('R1', e.state == 1) then
                e.blocked = true;
            end
        end,
        
        --A
        [12] = function(e)
            if HandleButton('A', e.state == 1) then
                e.blocked = true;
            end
        end,
        
        --B
        [13] = function(e)
            if HandleButton('B', e.state == 1) then
                e.blocked = true;
            end
        end,
        
        --X
        [14] = function(e)
            if HandleButton('X', e.state == 1) then
                e.blocked = true;
            end
        end,
        
        --Y
        [15] = function(e)
            if HandleButton('Y', e.state == 1) then
                e.blocked = true;
            end
        end,

        --L2
        [offset] = function(e)
            if HandleButton('L2', e.state > 0) then
                e.blocked = true;
            end
        end,
        
        --R2
        [offset+1] = function(e)
            if HandleButton('R2', e.state > 0) then
                e.blocked = true;
            end
        end,

        --Horizontal L-Stick Movement
        [offset+2] = function(e)
            if HandleStick('LStick', e.state, state.LStick.Vertical) then
                e.blocked = true;
            end
        end,
        
        --Vertical L-Stick Movement
        [offset+3] = function(e)
            if HandleStick('LStick', state.LStick.Horizontal, e.state) then
                e.blocked = true;
            end
        end,

        --Horizontal R-Stick Movement
        [offset+4] = function(e)
            if HandleStick('RStick', e.state, state.RStick.Vertical) then
                e.blocked = true;
            end
        end,
        
        --Vertical R-Stick Movement
        [offset+5] = function(e)
            if HandleStick('RStick', state.RStick.Horizontal, e.state) then
                e.blocked = true;
            end
        end,
    },
};

return layout;