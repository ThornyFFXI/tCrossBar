local header = { 1.0, 0.75, 0.55, 1.0 };
local imgui = require('imgui');
local scaling = require('scaling');
local state = {
    IsOpen = { false }
};
local ltrtmodes = T{
    'FullDouble',
    'HalfDouble',
    'Single'
}
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

local function GetDefaultPosition(layout)
    if ((scaling.window.w == -1) or (scaling.window.h == -1) or (scaling.menu.w == -1) or (scaling.menu.h == -1)) then
        return { 0, 0 };
    else
        --Centered horizontally, vertically just above chat log.
        return {
            (scaling.window.w - layout.Panel.Width) / 2,
            scaling.window.h - (scaling.scale_height(136) + layout.Panel.Height)
        };
    end
end

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
    state.SingleLayout = 1;
    state.SingleScale = { gSettings.SingleScale };
    state.DoubleLayout = 1;
    state.DoubleScale = { gSettings.DoubleScale };
    for index,layout in ipairs(state.Layouts) do
        if (gSettings.SingleLayout == layout) then
            state.SingleLayout = index;
        end
        if (gSettings.DoubleLayout == layout) then
            state.DoubleLayout = index;
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

local exposed = {};

function exposed:Render()
    if (state.IsOpen[1]) then
        if (imgui.Begin(string.format('%s v%s Configuration', addon.name, addon.version), state.IsOpen, ImGuiWindowFlags_AlwaysAutoResize)) then
            if imgui.BeginTabBar('##tCrossBarConfigTabBar', ImGuiTabBarFlags_NoCloseWithMiddleMouseButton) then
                if imgui.BeginTabItem('Layouts##tCrossbarConfigLayoutsTab', 0, state.ForceTab and 6 or 4) then
                    state.ForceTab = nil;
                    imgui.TextColored(header, 'Single Layout');
                    if (imgui.BeginCombo('##tCrossBarSingleLayoutSelectConfig', state.Layouts[state.SingleLayout], ImGuiComboFlags_None)) then
                        for index,layout in ipairs(state.Layouts) do
                            if (imgui.Selectable(layout, index == state.SingleLayout)) then
                                state.SingleLayout = index;
                            end
                        end
                        imgui.EndCombo();
                    end
                    imgui.SliderFloat('##SingleScale', state.SingleScale, 0.5, 3, '%.2f', ImGuiSliderFlags_AlwaysClamp);
                    if (gSingleDisplay.Valid) then
                        local button = string.format('%s##MoveToggleSingle', (state.DragTarget == gSingleDisplay) and 'End Drag' or 'Allow Drag');
                        if (imgui.Button(button)) then
                            if (state.DragTarget == gSingleDisplay) then
                                state.DragTarget.AllowDrag = false;
                                state.DragTarget = nil;
                            else
                                if (state.DragTarget ~= nil) then
                                    state.DragTarget.AllowDrag = false;
                                end
                                state.DragTarget = gSingleDisplay;
                                state.DragTarget.AllowDrag = true;
                            end
                        end
                        imgui.ShowHelp('Allows you to drag the single display.', true);
                        imgui.SameLine();
                        if (imgui.Button('Reset##ResetSingle')) then
                            gSettings.SinglePosition = GetDefaultPosition(gSingleDisplay.Layout);
                            gSingleDisplay:UpdatePosition();
                            settings.save();
                        end
                        imgui.ShowHelp('Resets single display to default position.', true);
                        imgui.SameLine();
                    end
                    if (imgui.Button('Apply##ApplySingle')) then
                        local layout = state.Layouts[state.SingleLayout];
                        if (layout == nil) then
                            Error('You must select a valid layout to apply it.');
                        else
                            gSettings.SingleLayout = layout;
                            gSettings.SingleScale = state.SingleScale[1];
                            gInitializer:ApplyLayout();
                            gSettings.SinglePosition = GetDefaultPosition(gSingleDisplay.Layout);
                            gSingleDisplay:UpdatePosition();
                            gBindings:Update();
                            settings.save();
                        end
                    end
                    imgui.ShowHelp('Applies the selected layout to your single display.', true);
                    
                    imgui.TextColored(header, 'Double Layout');
                    if (imgui.BeginCombo('##tCrossBarDoubleLayoutSelectConfig', state.Layouts[state.DoubleLayout], ImGuiComboFlags_None)) then
                        for index,layout in ipairs(state.Layouts) do
                            if (imgui.Selectable(layout, index == state.DoubleLayout)) then
                                state.DoubleLayout = index;
                            end
                        end
                        imgui.EndCombo();
                    end
                    imgui.SliderFloat('##DoubleScale', state.DoubleScale, 0.5, 3, '%.2f', ImGuiSliderFlags_AlwaysClamp);
                    if (gDoubleDisplay.Valid) then
                        local button = string.format('%s##MoveToggleDouble', (state.DragTarget == gDoubleDisplay) and 'End Drag' or 'Allow Drag');
                        if (imgui.Button(button)) then
                            if (state.DragTarget == gDoubleDisplay) then
                                state.DragTarget.AllowDrag = false;
                                state.DragTarget = nil;
                            else
                                if (state.DragTarget ~= nil) then
                                    state.DragTarget.AllowDrag = false;
                                end
                                state.DragTarget = gDoubleDisplay;
                                state.DragTarget.AllowDrag = true;
                            end
                        end
                        imgui.ShowHelp('Allows you to drag the double display.', true);
                        imgui.SameLine();
                        if (imgui.Button('Reset##ResetDouble')) then
                            gSettings.DoublePosition = GetDefaultPosition(gDoubleDisplay.Layout);
                            gDoubleDisplay:UpdatePosition();
                            settings.save();
                        end
                        imgui.ShowHelp('Resets double display to default position.', true);
                        imgui.SameLine();
                    end
                    if (imgui.Button('Apply##ApplyDouble')) then
                        local layout = state.Layouts[state.DoubleLayout];
                        if (layout == nil) then
                            Error('You must select a valid layout to apply it.');
                        else
                            gSettings.DoubleLayout = layout;
                            gSettings.DoubleScale = state.DoubleScale[1];
                            gInitializer:ApplyLayout();
                            gSettings.DoublePosition = GetDefaultPosition(gDoubleDisplay.Layout);
                            gDoubleDisplay:UpdatePosition();
                            gBindings:Update();
                            settings.save();
                        end
                    end
                    imgui.ShowHelp('Applies the selected layout to your double display.', true);
                    imgui.TextColored(header, 'Layout Files');
                    if (imgui.Button('Refresh')) then
                        GetLayouts();
                    end
                    imgui.ShowHelp('Reloads available layouts from disk.', true);
                    imgui.EndTabItem();
                end
                
                if imgui.BeginTabItem('Components##tCrossbarConfigComponentsTab') then
                    imgui.BeginGroup();
                    CheckBox('Empty', 'ShowEmpty');
                    imgui.ShowHelp('Display empty macro elements.');
                    CheckBox('Frame', 'ShowFrame');
                    imgui.ShowHelp('Display frame for macro elements.');
                    CheckBox('Cost', 'ShowCost');
                    imgui.ShowHelp('Display action cost indicators.');
                    CheckBox('Trigger', 'ShowTrigger');
                    imgui.ShowHelp('Shows an overlay when you activate an action.');
                    CheckBox('SC Icon', 'ShowSkillchainIcon');
                    imgui.ShowHelp('Overrides weaponskill icons when a skillchain would be formed.');
                    CheckBox('SC Animation', 'ShowSkillchainAnimation');
                    imgui.ShowHelp('Animates a border around weaponskill icons when a skillchain would be formed.');
                    imgui.EndGroup();
                    imgui.SameLine();
                    imgui.BeginGroup();
                    CheckBox('Cross', 'ShowCross');
                    imgui.ShowHelp('Displays a X over actions you don\'t currently know.');
                    CheckBox('Fade', 'ShowFade');
                    imgui.ShowHelp('Fades the icon for actions where cooldown is not 0 or cost is not met.');
                    CheckBox('Recast', 'ShowRecast');
                    imgui.ShowHelp('Shows action recast timers.');
                    CheckBox('Hotkey', 'ShowHotkey');
                    imgui.ShowHelp('Shows hotkey labels.');
                    CheckBox('Name', 'ShowName');
                    imgui.ShowHelp('Shows action names.');
                    CheckBox('Palette(Single)', 'ShowSinglePalette');
                    imgui.ShowHelp('Shows selected palette on single display.');
                    CheckBox('Palette(Double)', 'ShowPalette');
                    imgui.ShowHelp('Shows selected palette on double display.');
                    imgui.EndGroup();
                    imgui.EndTabItem();
                end
                
                if imgui.BeginTabItem('Behavior##tCrossbarConfigBehaviorTab') then
                    imgui.TextColored(header, 'Macro Elements');
                    CheckBox('Clickable', 'ClickToActivate');
                    imgui.ShowHelp('Makes macros activate when their icon is left clicked.');
                    imgui.TextColored(header, 'Trigger Duration');
                    local buff = { gSettings.TriggerDuration };
                    if imgui.SliderFloat('##TriggerDurationSlider', buff, 0.01, 1.5, '%.2f', ImGuiSliderFlags_AlwaysClamp) then
                        gSettings.TriggerDuration = buff[1];
                        settings.save();
                    end
                    imgui.ShowHelp('Determines how long the activation flash occurs for when ShowTrigger is enabled.')
                    imgui.TextColored(header, 'Hide UI');
                    CheckBox('While Zoning', 'HideWhileZoning');
                    imgui.ShowHelp('Hides UI while you are zoning or on title screen.');
                    CheckBox('During Cutscenes', 'HideWhileCutscene');
                    imgui.ShowHelp('Hides UI while the game event system is active.');
                    CheckBox('While Map Open', 'HideWhileMap');
                    imgui.ShowHelp('Hides UI while the map is the topmost menu.');
                    CheckBox('While Chat Expanded', 'HideWhileChat');
                    imgui.ShowHelp('Hides UI while the chat window is expanded.');
                    imgui.TextColored(header, 'Combo Behavior');
                    CheckBox('Combo Priority', 'EnablePriority');
                    imgui.ShowHelp('When enabled, pressing LR then R2 will be a seperate set from pressing R2 then L2.  When disabled, order won\'t matter.');
                    CheckBox('Double Tap', 'EnableDoubleTap');
                    imgui.ShowHelp('When enabled, a quick double tap then hold of L2 or R2 will produce a seperate macro set from single taps.');
                    CheckBox('Always Show Double', 'ShowDoubleDisplay');
                    imgui.ShowHelp('When enabled, your L2 and R2 macros will be shown together while no combo keys are pressed.');
                    imgui.TextColored(header, 'Binding Menu');
                    CheckBox('Default To <st>', 'DefaultSelectTarget');
                    imgui.ShowHelp('When enabled, new bindings that can target anything besides yourself will default to <st>.');
                    imgui.TextColored(header, 'LT-RT Display');
                    imgui.ShowHelp('Determines what should be displayed when using the single LT or single RT macro.');
                    if (imgui.BeginCombo('##tCrossBarLTRTMode', gSettings.LTRTMode, ImGuiComboFlags_None)) then
                        for _,text in ipairs(ltrtmodes) do
                            if (imgui.Selectable(text, gSettings.LTRTMode == text)) then
                                gSettings.LTRTMode = text;
                                settings.save();
                            end
                        end
                        imgui.EndCombo();
                    end

                    imgui.EndTabItem();
                end
                
                if imgui.BeginTabItem('Controller##tCrossbarControlseTab') then
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
                    CheckBox('Inventory Passthrough', 'AllowInventoryPassthrough');
                    imgui.ShowHelp('When enabled, L2/R2/ZL/ZR will be passed to the game when inventory is the topmost menu.');
                    imgui.TextColored(header, 'Bind Menu Timer');
                    local buff = { gSettings.BindMenuTimer };
                    if imgui.SliderFloat('##BindMenuDurationSlider', buff, 0.1, 1.5, '%.2f', ImGuiSliderFlags_AlwaysClamp) then
                        gSettings.BindMenuTimer = buff[1];
                        settings.save();
                    end
                    imgui.ShowHelp('Determines how long the activation combo must be pressed to open or close binding menu.')
                    imgui.TextColored(header, 'Double Tap Timer');
                    local buff = { gSettings.TapTimer };
                    if imgui.SliderFloat('##TapTimerSlider', buff, 0.1, 1.5, '%.2f', ImGuiSliderFlags_AlwaysClamp) then
                        gSettings.TapTimer = buff[1];
                        settings.save();
                    end
                    imgui.ShowHelp('Determines how long you have to double tap L2 or R2 when double tap mode is enabled.')
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
    end

    if state.IsOpen[1] then
        self.ForceDisplay = state.DragTarget;
    else
        self.ForceDisplay = nil;
        if (state.DragTarget ~= nil) then
            state.DragTarget.AllowDrag = false;
            state.DragTarget = nil;
        end
    end
end

function exposed:Show()
    GetControllers();
    GetLayouts();
    state.ForceTab = true;
    state.IsOpen = { true };
    state.DragTarget = nil;
end

return exposed;