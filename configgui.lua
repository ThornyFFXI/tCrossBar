local header = { 1.0, 0.75, 0.55, 1.0 };
local lastPositionX, lastPositionY;
local state = {
    DragMode = 'Disabled',
    DragTarget = '',
    IsOpen = { false }
};
local validControls = T{
    { Name='Macro1', Description='Triggers the top macro of the left grouping.' },
    { Name='Macro2', Description='Triggers the right macro of the left grouping.' },
    { Name='Macro3', Description='Triggers the bottom macro of the left grouping.' },
    { Name='Macro4', Description='Triggers the left macro of the left grouping.' },
    { Name='Macro5', Description='Triggers the top macro of the right grouping.' },
    { Name='Macro6', Description='Triggers the right macro of the right grouping.' },
    { Name='Macro7', Description='Triggers the bottom macro of the right grouping.' },
    { Name='Macro8', Description='Triggers the left macro of the right grouping.' },
    { Name='ComboLeft', Description='Used to activate macro combinations.' },
    { Name='ComboRight', Description='Used to activate macro combinations.' },
    { Name='PreviousPalette', Description='Swaps to previous palette if pressed with ComboLeft held down and ComboRight released.' },
    { Name='NextPalette', Description='Swaps to next palette if pressed with ComboRight held down and ComboLeft released.' },
    { Name='BindingUp', Description='Changes to previous field in binding menu.' },
    { Name='BindingDown', Description='Changes to next field in binding menu.' },
    { Name='BindingNext', Description='Changes value forward in binding menu.' },
    { Name='BindingPrevious', Description='Changes value backwards in binding menu.' },
    { Name='BindingConfirm', Description='Confirms current settings in binding menu.' },
    { Name='BindingCancel', Description='Cancels current settings in binding menu and returns to macro select screen.' },
    { Name='BindingTab', Description='Changes tab in binding menu.' },
};

local function GetLayouts()
    local layouts = T{};
    local layoutPaths = T{
        string.format('%sconfig/addons/%s/resources/layouts/', AshitaCore:GetInstallPath(), addon.name),
        string.format('%saddons/%s/resources/layouts/', AshitaCore:GetInstallPath(), addon.name),
    };

    for _,path in ipairs(layoutPaths) do
        if not (ashita.fs.exists(path)) then
            ashita.fs.create_directory(path);
        end
        local contents = ashita.fs.get_directory(path, '.*\\.lua');
        for _,file in pairs(contents) do
            file = string.sub(file, 1, -5);
            if not layouts:contains(file) then
                layouts:append(file);
            end
        end
    end

    state.Layouts = layouts;
    state.SelectedLayout = 1;
    for index,layout in ipairs(state.Layouts) do
        if (gSettings.Layout == layout) then
            state.SelectedLayout = index;
        end
    end
end

local function GetControllers()
    local controllers = T{};
    local controllerPaths = T{
        string.format('%sconfig/addons/%s/resources/controllers/', AshitaCore:GetInstallPath(), addon.name),
        string.format('%saddons/%s/resources/controllers/', AshitaCore:GetInstallPath(), addon.name),
    };

    for _,path in ipairs(controllerPaths) do
        if not (ashita.fs.exists(path)) then
            ashita.fs.create_directory(path);
        end
        local contents = ashita.fs.get_directory(path, '.*\\.lua');
        for _,file in pairs(contents) do
            file = string.sub(file, 1, -5);
            if not controllers:contains(file) then
                controllers:append(file);
            end
        end
    end

    state.Controllers = controllers;
    state.SelectedController = 1;
    for index,controller in ipairs(state.Controllers) do
        if (gSettings.Controller == controller) then
            state.SelectedController = index;
        end
    end
end

local function CheckBox(text, member)
    if (imgui.Checkbox(string.format('%s##Config_%s', text, text), { gSettings[member] })) then
        gSettings[member] = not gSettings[member];
        settings.save();
    end
end

local function ControllerBindingCombo(member, helpText)
    imgui.TextColored(header, member);
    local controls = gSettings.Controls[gSettings.Controller];
    if (imgui.BeginCombo('##tCrossBarControlsSelect' .. member, controls[member], ImGuiComboFlags_None)) then
        for _,control in ipairs(gController.Layout.ButtonMap) do
            if (imgui.Selectable(control, control == controls[member])) then
                controls[member] = control;
            end
        end
        imgui.EndCombo();
    end
    imgui.ShowHelp(helpText);
end

local function HitTest(layout, e)
    local minX = gSettings.Position[gSettings.Layout][state.DragTarget]

end

local exposed = {};

function exposed:HandleMouse(e)
    if (state.IsOpen[1] == false) or (state.DragMode == 'Disabled') then
        return false;
    end
    
    if state.DragMode == 'Active' then
        local pos = state.DragTarget:GetPosition();
        local newX = pos[1] + (e.x - lastPositionX);
        local newY = pos[2] + (e.y - lastPositionY);
        state.DragTarget:SetPosition(newX, newY);
        lastPositionX = e.x;
        lastPositionY = e.y;
        if (e.message == 514) or (bit.band(ffi.C.GetKeyState(0x10), 0x8000) == 0) then
            state.DragMode = 'Disabled';
            e.blocked = true;
        end
        return true;
    end

    if (state.DragMode == 'Pending') then
        if e.message == 513 then
            if state.DragTarget:HitTest(e.x, e.y) then
                state.DragMode = 'Active';
                lastPositionX = e.x;
                lastPositionY = e.y;
                e.blocked = true;
            end
        end
        return true;
    end

    return false;
end

function exposed:Render()
    if (state.IsOpen[1]) then
        if (imgui.Begin(string.format('%s v%s Configuration', addon.name, addon.version), state.IsOpen, ImGuiWindowFlags_AlwaysAutoResize)) then
            imgui.BeginGroup();
            if imgui.BeginTabBar('##tCrossBarConfigTabBar', ImGuiTabBarFlags_NoCloseWithMiddleMouseButton) then
                if imgui.BeginTabItem('Appearance##tCrossbarConfigAppearanceTab', 0, state.ForceTab and 6 or 4) then
                    state.ForceTab = nil;
                    imgui.TextColored(header, 'Layout');
                    if (imgui.BeginCombo('##tCrossBarLayoutSelectConfig', state.Layouts[state.SelectedLayout], ImGuiComboFlags_None)) then
                        for index,layout in ipairs(state.Layouts) do
                            if (imgui.Selectable(layout, index == state.SelectedLayout)) then
                                state.SelectedLayout = index;
                            end
                        end
                        imgui.EndCombo();
                    end
                    if (imgui.Button('Refresh')) then
                        GetLayouts();
                    end
                    imgui.ShowHelp('Reloads available layouts from disk.', true);
                    imgui.SameLine();
                    if (imgui.Button('Apply')) then
                        local layout = state.Layouts[state.SelectedLayout];
                        if (layout == nil) then
                            print(chat.header(addon.name) .. chat.error('You must select a valid layout to apply it.'));
                        else
                            gInterface:Initialize(layout);
                        end
                    end
                    imgui.ShowHelp('Applies the selected layout to your display.', true);
                    CheckBox('Clickable', 'ClickToActivate');
                    imgui.ShowHelp('Makes macros activate when their icon is left clicked.');
                    imgui.TextColored(header, 'Components');
                    imgui.BeginGroup();
                    CheckBox('Cost', 'ShowCost');
                    imgui.ShowHelp('Display action cost indicators.');
                    CheckBox('Cross', 'ShowCross');
                    imgui.ShowHelp('Displays a X over actions you don\'t currently know.');
                    CheckBox('Fade', 'ShowFade');
                    imgui.ShowHelp('Fades the icon for actions where cooldown is not 0 or cost is not met.');
                    CheckBox('Recast', 'ShowRecast');
                    imgui.ShowHelp('Shows action recast timers.');
                    CheckBox('Hotkey', 'ShowHotkey');
                    imgui.ShowHelp('Shows hotkey labels.');
                    imgui.EndGroup();
                    imgui.SameLine();
                    imgui.BeginGroup();
                    CheckBox('Name', 'ShowName');
                    imgui.ShowHelp('Shows action names.');
                    CheckBox('Trigger', 'ShowTrigger');
                    imgui.ShowHelp('Shows an overlay when you activate an action.');
                    CheckBox('SC Icon', 'ShowSkillchainIcon');
                    imgui.ShowHelp('Overrides weaponskill icons when a skillchain would be formed.');
                    CheckBox('SC Animation', 'ShowSkillchainAnimation');
                    imgui.ShowHelp('Animates a border around weaponskill icons when a skillchain would be formed.');                
                    imgui.EndGroup();
                    imgui.TextColored(header, 'Hide UI');
                    CheckBox('While Zoning', 'HideWhileZoning');
                    imgui.ShowHelp('Hides UI while you are zoning or on title screen.');
                    CheckBox('During Cutscenes', 'HideWhileCutscene');
                    imgui.ShowHelp('Hides UI while the game event system is active.');
                    CheckBox('While Map Open', 'HideWhileMap');
                    imgui.ShowHelp('Hides UI while the map is the topmost menu.');                    
                    imgui.EndTabItem();
                end
                if imgui.BeginTabItem('Controller##tCrossbarControlsAppearanceTab') then
                    imgui.TextColored(header, 'Device Mapping');
                    if (imgui.BeginCombo('##tCrossBarControllerSelectConfig', state.Controllers[state.SelectedController], ImGuiComboFlags_None)) then
                        for index,controller in ipairs(state.Controllers) do
                            if (imgui.Selectable(controller, index == state.SelectedController)) then
                                state.SelectedController = index;
                            end
                        end
                        imgui.EndCombo();
                    end
                    if (imgui.Button('Refresh')) then
                        GetControllers();
                    end
                    imgui.ShowHelp('Reloads available device mappings from disk.', true);
                    imgui.SameLine();
                    if (imgui.Button('Apply')) then
                        local controller = state.Controllers[state.SelectedController];
                        if (controller == nil) then
                            print(chat.header(addon.name) .. chat.error('You must select a valid controller to apply it.'));
                        else
                            gSettings.Controller = controller;
                            gController:SetLayout(controller);
                            settings.save();
                        end
                    end
                    imgui.ShowHelp('Loads the selected device mapping.', true);
                    CheckBox('Combo Priority', 'EnablePriority');
                    imgui.ShowHelp('When enabled, pressing LR then R2 will be a seperate set from pressing R2 then L2.  When disabled, order won\'t matter.');
                    CheckBox('Double Tap', 'EnableDoubleTap');
                    imgui.ShowHelp('When enabled, a quick double tap then hold of L2 or R2 will produce a seperate macro set from single taps.');
                    CheckBox('Always Show Double', 'ShowDoubleDisplay');
                    imgui.ShowHelp('When enabled, your L2 and R2 macros will be shown together while no combo keys are pressed.');
                    CheckBox('Condense To Single', 'SwapToSingleDisplay');
                    imgui.ShowHelp('When enabled, pressing L2 or R2 will show only the relevant set instead of both sets.');
                    CheckBox('Inventory Passthrough', 'AllowInventoryPassthrough');
                    imgui.ShowHelp('When enabled, L2/R2/ZL/ZR will be passed to the game when inventory is the topmost menu.');
                    CheckBox('Default To <st>', 'DefaultSelectTarget');
                    imgui.ShowHelp('When enabled, new bindings that can target anything besides yourself will default to <st>.');
                    imgui.EndTabItem();
                end                
                if imgui.BeginTabItem('Binding##tCrossbarControlsBindingTab') then
                    imgui.BeginChild('##tCrossbarControllerBindingChild', { 258, 350 });
                    for _,control in ipairs(validControls) do
                        ControllerBindingCombo(control.Name, control.Description);
                    end
                    imgui.EndChild();
                    imgui.EndTabItem();
                end
                
                imgui.EndTabBar();
            end
            imgui.End();
        end

        if (state.DragMode ~= 'Disabled') then
            return state.DragTarget;
        end
    end
end

function exposed:Show()
    GetControllers();
    GetLayouts();
    state.ForceTab = true;
    state.IsOpen = { true };
    state.DragMode = 'Disabled';
end

return exposed;