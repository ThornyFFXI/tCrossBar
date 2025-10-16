local imgui = require('imgui');
local controller = {
    dInputCB = false,
    xInputCB = false,
    BindMenuState = {
        Active = false,
        Pending = false,
        Timer = 0,
    },
    ComboState = {
        CurrentMode = 0,
        Left = false,
        LeftTapTimer = 0,
        Right = false,
        RightTapTimer = 0,
    },
};

local ComboMode = {
    Inactive = 0,
    LeftTrigger = 1,
    RightTrigger = 2,
    BothTriggersLeft = 3,
    BothTriggersRight = 4,
    LeftTriggerDouble = 5,
    RightTriggerDouble = 6
};

local bindCommands = {
    'BindingUp',
    'BindingDown',
    'BindingNext',
    'BindingPrevious',
    'BindingConfirm',
    'BindingCancel',
    'BindingTab'
};

local inventoryPassControls = {
    ['L2'] = true,
    ['R2'] = true,
    ['ZL'] = true,
    ['ZR'] = true
};

local inventoryPassMenus = {
    ['menu    inventor'] = true,
    ['menu    bank    '] = true,
};

local pGameMenu = ashita.memory.find('FFXiMain.dll', 0, "8B480C85C974??8B510885D274??3B05", 16, 0);
local function GetMenuName()
    local subPointer = ashita.memory.read_uint32(pGameMenu);
    local subValue = ashita.memory.read_uint32(subPointer);
    if (subValue == 0) then
        return '';
    end
    local menuHeader = ashita.memory.read_uint32(subValue + 4);
    local menuName = ashita.memory.read_string(menuHeader + 0x46, 16);
    return string.gsub(menuName, '\x00', '');
end

function controller:GetMacroState()
    return self.ComboState.CurrentMode;
end

function controller:HandleInput(e)
    local fButton = self.Layout.Buttons[e.button];
    if (type(fButton) == 'function') then
        fButton(e);
    end
end

function controller:InitializeControls()
    --Initialize any blank controls..
    local changed = false;
    if (type(gSettings.Controls) ~= 'table') then
        gSettings.Controls = {};
        changed = true;
    end
    if (gSettings.Controls[controller.Layout.Name] == nil) then
        gSettings.Controls[controller.Layout.Name] =  {};
        changed = true;
    end

    local controls = gSettings.Controls[self.Layout.Name];
    for binding,button in pairs(self.Layout.Defaults) do
        if (controls[binding] == nil) then
            controls[binding] = button;
            changed = true;
        end
    end

    if (changed) then
        settings.save();
    end
end

function controller:SetLayout(layoutName)
    gBindingGUI:Close();
    self.BindMenuState.Active = false;
    if self.dInputCB == true then
        ashita.events.unregister('dinput_button', 'dinput_button_cb');
        self.dInputCB = false;
    end

    if self.xInputCB == true then
        ashita.events.unregister('xinput_button', 'xinput_button_cb');
        self.XinputCB = false;
    end

    local controllerLayout = LoadFile_s(GetResourcePath('controllers/' .. layoutName));
    if (controllerLayout ~= nil) then
        controllerLayout.Name = layoutName;
        self.Layout = controllerLayout;
        
        if (self.Layout ~= nil) then
            self:InitializeControls();

            if (self.Layout.DirectInput == true) then
                ashita.events.register('dinput_button', 'dinput_button_cb', self.HandleInput:bind1(self));
                self.dInputCB = true;
            end
            if (self.Layout.XInput == true) then
                ashita.events.register('xinput_button', 'xinput_button_cb', self.HandleInput:bind1(self));
                self.xInputCB = true;
            end
        end
    end
end

function controller:Tick()
    local isComboPressed = (self.ComboState.Left == true) and (self.ComboState.Right == true) and (self.ComboState.PrevPalette == true) and (self.ComboState.NextPalette == true);

    if isComboPressed == true then
        if (self.BindMenuState.Pending == false) then
            self.BindMenuState.Pending = true;
            self.BindMenuState.Timer = os.clock() + gSettings.BindMenuTimer;
        elseif (self.BindMenuState.Timer ~= nil) and (os.clock() > self.BindMenuState.Timer) then
            if (gBindingGUI:GetActive()) then
                gBindingGUI:Close();
                self.BindMenuState.Active = false;
            elseif (not self.BindMenuState.Active) then
                if (gSingleDisplay) then
                    self.BindMenuState.Active = true;
                else
                    Error('Cannot open bind menu without a valid single display.  Please enter "/tc" to open the menu and select a valid layout.')
                end
            else
                self.BindMenuState.Active = false;
            end
            self.BindMenuState.Timer = nil;
        end
    else
        self.BindMenuState.Pending = false;
    end

    if (self.BindMenuState.Active == true) and (gBindingGUI:GetActive() == false) then
        if (imgui.Begin(string.format('%s v%s Binding', addon.name, addon.version), { true }, ImGuiWindowFlags_AlwaysAutoResize)) then
            imgui.Text('Press any macro combination to bind to it.');
            imgui.Text('Hold binding menu key combination to close this menu.');
            imgui.End();
        end
    end
end

function controller:Trigger(button, pressed)
    local controls = gSettings.Controls[self.Layout.Name];

    if (gSettings.AllowInventoryPassthrough == true) then
        if inventoryPassControls[button] == true and inventoryPassMenus[GetMenuName()] == true then
            return false;
        end
    end

    --Combo buttons are always monitored.
    if (button == controls.ComboLeft) then
        if (pressed == true) then
            if (not self.ComboState.Right) then
                if (os.clock() < self.ComboState.LeftTapTimer) and (gSettings.EnableDoubleTap) then
                    self.ComboState.CurrentMode = ComboMode.LeftTriggerDouble;
                else
                    self.ComboState.CurrentMode = ComboMode.LeftTrigger;
                end
            else
                if (gSettings.EnablePriority) then
                    self.ComboState.CurrentMode = ComboMode.BothTriggersRight;
                else
                    self.ComboState.CurrentMode = ComboMode.BothTriggersLeft;
                end
            end
            self.ComboState.Left = true;
            self.ComboState.LeftTapTimer = os.clock() + gSettings.TapTimer;
        else
            if (self.ComboState.Right) then
                self.ComboState.CurrentMode = ComboMode.RightTrigger;
            else
                self.ComboState.CurrentMode = ComboMode.Inactive;
            end
            self.ComboState.Left = false;
        end
        return true;
    elseif (button == controls.ComboRight) then
        if (pressed == true) then
            if (not self.ComboState.Left) then
                if (os.clock() < self.ComboState.RightTapTimer) and (gSettings.EnableDoubleTap) then
                    self.ComboState.CurrentMode = ComboMode.RightTriggerDouble;
                else
                    self.ComboState.CurrentMode = ComboMode.RightTrigger;
                end
            else
                self.ComboState.CurrentMode = ComboMode.BothTriggersLeft;
            end
            self.ComboState.Right = true;
            self.ComboState.RightTapTimer = os.clock() + gSettings.TapTimer;
        else
            if (self.ComboState.Left) then
                self.ComboState.CurrentMode = ComboMode.LeftTrigger;
            else
                self.ComboState.CurrentMode = ComboMode.Inactive;
            end
            self.ComboState.Right = false;
        end
        return true;
    end
    
    if (button == controls.PreviousPalette) then
        self.ComboState.PrevPalette = pressed;
        if (pressed == true) and (self:GetMacroState() == 1) then
            gBindings:PreviousPalette();
        end
        if (self:GetMacroState() ~= 0) then
            return true;
        end
        
    elseif (button == controls.NextPalette) then
        self.ComboState.NextPalette = pressed;
        if (pressed == true) and (self:GetMacroState() == 2) then
            gBindings:NextPalette();
        end
        if (self:GetMacroState() ~= 0) then
            return true;
        end
    end

    --Don't trigger macros while binding GUI is active..
    if (gBindingGUI:GetActive()) then
        for _,command in ipairs(bindCommands) do
            if (button == controls[command]) then
                gBindingGUI:HandleButton(command, pressed);
                return true;
            end
        end
    elseif (self:GetMacroState() ~= 0) and (pressed == true) then
        for i = 1,8 do
            local str = string.format('Macro%d', i);
            if (button == controls[str]) then
                if (self.BindMenuState.Active == true) and (gBindingGUI:GetActive() == false) then
                    gBindingGUI:Show(self:GetMacroState(), i);
                    return true;
                else
                    gSingleDisplay:Activate(self:GetMacroState(), i);
                    return true;
                end
            end
        end

    end
end

return controller;