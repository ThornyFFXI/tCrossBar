local header = { 1.0, 0.75, 0.55, 1.0 };
local imgui = require('imgui');
local state = {
    IsOpen = { false },
    RenderConfigIsOpen = { false },
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

local function GetRenderers()
    local renderers = T{};
    do
        local path = string.format('%saddons/%s/renderers/', AshitaCore:GetInstallPath(), addon.name);    
        local contents = ashita.fs.get_directory(path);
        for _,entry in pairs(contents) do
            local full = string.format('%s%s', path, entry);
            if (ashita.fs.status(full).is_directory) then
                renderers:append(entry);
            end
        end
    end

    state.Renderers = renderers;
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
end

local function CheckBox(text, member)
    if (imgui.Checkbox(string.format('%s##Config_%s_%s', text, text, member), { gSettings[member] })) then
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
                if imgui.BeginTabItem('Appearance##tCrossbarConfigAppearanceTab', 0, state.ForceTab and 6 or 4) then
                    state.ForceTab = nil;
                    imgui.TextColored(header, 'Renderer');
                    if (imgui.BeginCombo('##tCrossBarSingleLayoutSelectRenderer', gSettings.Renderer, ImGuiComboFlags_None)) then
                        for _,renderer in ipairs(state.Renderers) do
                            if (imgui.Selectable(renderer, gSettings.Renderer == renderer)) then
                                if (gSettings.Renderer ~= renderer) then
                                    gSettings.Renderer = renderer;
                                    gInitializer:ApplyRenderer();
                                    settings.save();
                                end
                            end
                        end
                        imgui.EndCombo();
                    end
                    if (imgui.Button('Renderer Settings')) then
                        state.RenderConfigIsOpen = { true };
                    end
                    imgui.TextColored(header, 'Components');
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
                    imgui.TextColored(header, 'Binding Menu');
                    CheckBox('Default To <st>', 'DefaultSelectTarget');
                    imgui.ShowHelp('When enabled, new bindings that can target anything besides yourself will default to <st>.');
                    imgui.EndTabItem();
                end
                
                if imgui.BeginTabItem('Controller##tCrossbarControlseTab') then
                    imgui.TextColored(header, 'Device Mapping');
                    if (imgui.BeginCombo('##tCrossBarControllerSelectConfig', gSettings.Controller, ImGuiComboFlags_None)) then
                        for _,controller in ipairs(state.Controllers) do
                            if (imgui.Selectable(controller, controller == gSettings.Controller)) then
                                if (gSettings.Controller ~= controller) then
                                    gSettings.Controller = controller;
                                    gController:SetLayout(controller);
                                    settings.save();
                                end
                            end
                        end
                        imgui.EndCombo();
                    end
                    if (imgui.Button('Refresh')) then
                        GetControllers();
                    end
                    imgui.ShowHelp('Reloads available device mappings from disk.', true);
                    imgui.TextColored(header, 'Bind Menu Timer');
                    local buff = { gSettings.BindMenuTimer };
                    if imgui.SliderFloat('##BindMenuDurationSlider', buff, 0.1, 1.5, '%.2f', ImGuiSliderFlags_AlwaysClamp) then
                        gSettings.BindMenuTimer = buff[1];
                        settings.save();
                    end
                    imgui.ShowHelp('Determines how long the activation combo must be pressed to open or close binding menu.')
                    imgui.TextColored(header, 'Double Tap');
                    CheckBox('Enabled', 'EnableDoubleTap');
                    imgui.ShowHelp('When enabled, a quick double tap then hold of L2 or R2 will produce a seperate macro set from single taps.');
                    local buff = { gSettings.TapTimer };
                    if imgui.SliderFloat('##TapTimerSlider', buff, 0.1, 1.5, '%.2f', ImGuiSliderFlags_AlwaysClamp) then
                        gSettings.TapTimer = buff[1];
                        settings.save();
                    end
                    imgui.ShowHelp('Determines how long you have to double tap L2 or R2 when double tap mode is enabled.');
                    imgui.TextColored(header, 'Trigger Priority');
                    CheckBox('Enabled', 'EnablePriority');
                    imgui.ShowHelp('When enabled, pressing LR then R2 will be a seperate set from pressing R2 then L2.  When disabled, order won\'t matter.');
                    imgui.TextColored(header, 'Inventory Passthrough');
                    CheckBox('Enabled', 'AllowInventoryPassthrough');
                    imgui.ShowHelp('When enabled, L2/R2/ZL/ZR will be passed to the game when inventory is the topmost menu.');
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

    if state.IsOpen[1] == false then
        state.RenderConfigIsOpen = { false };
    end

    if (state.RenderConfigIsOpen[1]) then
        gRenderer:DrawConfigGUI(state.RenderConfigIsOpen);
    end
end

function exposed:Show()
    GetControllers();
    GetRenderers();
    state.ForceTab = true;
    state.IsOpen = { true };
    state.RenderConfigIsOpen = { false };
    state.DragTarget = nil;
end

return exposed;