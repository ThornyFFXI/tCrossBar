--Initialize Classes..
require('state.inventory');
require('state.player');
require('state.skillchain');

--Initialize Globals..
require('helpers');
gTextureCache    = require('texturecache');
gBindingGUI      = require('bindinggui');
gConfigGUI       = require('configgui');
gController      = require('controller');
gSingleDisplay   = require('singledisplay');
gDoubleDisplay   = require('doubledisplay');
settings         = require('settings');

--Create directories..
local controllerConfigFolder = string.format('%sconfig/addons/%s/resources/controllers', AshitaCore:GetInstallPath(), addon.name);
if not ashita.fs.exists(controllerConfigFolder) then
    ashita.fs.create_directory(controllerConfigFolder);
end
local layoutConfigFolder = string.format('%sconfig/addons/%s/resources/layouts', AshitaCore:GetInstallPath(), addon.name);
if not ashita.fs.exists(layoutConfigFolder) then
    ashita.fs.create_directory(layoutConfigFolder);
end

--Initialize settings..
local defaultSettings = T{
    Layout = 'classic',
    SingleScale = 1.0,
    DoubleScale = 1.0,
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
gSettings = settings.load(defaultSettings);

--Create exports..
local Initializer = {};

function Initializer:ApplyController()
    local controllerLayout = LoadFile_s(GetResourcePath('controllers/' .. gSettings.Controller));
    gController:SetLayout(controllerLayout);
end

function Initializer:ApplyLayout()
    gSingleDisplay:Destroy();
    gDoubleDisplay:Destroy();
    local graphicsLayout = LoadFile_s(GetResourcePath('layouts/' .. gSettings.Layout));
    if graphicsLayout then
        gSingleDisplay:Initialize(graphicsLayout.SingleDisplay, gSettings.SingleScale);
        gDoubleDisplay:Initialize(graphicsLayout.DoubleDisplay, gSettings.DoubleScale);
    end
end

settings.register('settings', 'settings_update', function(newSettings)
    gSettings = newSettings;
    Initializer:ApplyController();
    Initializer:ApplyLayout();
end);

Initializer:ApplyController();
Initializer:ApplyLayout();

return Initializer;