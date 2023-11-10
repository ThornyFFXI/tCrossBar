function Error(text)
    local color = ('\30%c'):format(68);
    local highlighted = color .. string.gsub(text, '$H', '\30\01\30\02');
    highlighted = string.gsub(highlighted, '$R', '\30\01' .. color);
    print(chat.header(addon.name) .. highlighted .. '\30\01');
end


function Message(text)
    local color = ('\30%c'):format(106);
    local highlighted = color .. string.gsub(text, '$H', '\30\01\30\02');
    highlighted = string.gsub(highlighted, '$R', '\30\01' .. color);
    print(chat.header(addon.name) .. highlighted .. '\30\01');
end

function LoadFile_s(filePath)
    if not ashita.fs.exists(filePath) then
        return nil;
    end

    local success, loadError = loadfile(filePath);
    if not success then
        Error(string.format('Failed to load resource file: $H%s', filePath));
        Error(loadError);
        return nil;
    end

    local result, output = pcall(success);
    if not result then
        Error(string.format('Failed to execute resource file: $H%s', filePath));
        Error(loadError);
        return nil;
    end

    return output;
end

--Initialize Classes..
require('state.inventory');
require('state.player');
require('state.skillchain');

--Initialize Globals..
gTextureCache    = require('texturecache');
gBindingGUI      = require('bindinggui');
gConfigGUI       = require('configgui');
gController      = require('controller');
gSingleDisplay   = require('singledisplay');
gDoubleDisplay   = require('doubledisplay');

settings         = require('settings');
local defaultSettings = T{
    Layout = 'classic',
    Scale = 1.0,
    Controller = 'dualsense',
    BindMenuTimer = 1,
    TapTimer = 0.4,
    EnableDoubleTap = true,
    EnablePriority = true,
    ShowDoubleDisplay = true,
    SwapToSingleDisplay = false,
    AllowInventoryPassthrough = true,
    Position = T{},
    ClickToActivate = true,
    ShowEmpty = true,
    ShowFrame = true,
    ShowCost = true,
    ShowCross = true,
    ShowFade = true,
    ShowName = true,
    ShowRecast = true,
    ShowHotkey = false,
    ShowSkillchainIcon = true,
    ShowSkillchainAnimation = true,
    ShowTrigger = true,
    HideWhileZoning = true,
    HideWhileCutscene = true,
    HideWhileMap = true,
    DefaultSelectTarget = false,
};

local controllerConfigFolder = string.format('%sconfig/addons/%s/resources/controllers', AshitaCore:GetInstallPath(), addon.name);
if not ashita.fs.exists(controllerConfigFolder) then
    ashita.fs.create_directory(controllerConfigFolder);
end

local layoutConfigFolder = string.format('%sconfig/addons/%s/resources/layouts', AshitaCore:GetInstallPath(), addon.name);
if not ashita.fs.exists(layoutConfigFolder) then
    ashita.fs.create_directory(layoutConfigFolder);
end

gSettings = settings.load(defaultSettings);
gController:SetLayout(gSettings.Controller);
gInterface:Initialize(gSettings.Layout);

settings.register('settings', 'settings_update', function(newSettings)
    gSettings = newSettings;
    gController:SetLayout(gSettings.Controller);
end);

return true;