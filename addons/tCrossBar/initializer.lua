--Initialize Globals..
require('helpers');
gTextureCache    = require('texturecache');
gBindings        = require('bindings');
gBindingGUI      = require('bindinggui');
gConfigGUI       = require('configgui');
gController      = require('controller');
gElementGroup    = require('elementgroup');
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
    Renderer = 'classic',
    RendererSettings = {};

    --Hide entire elements..
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

    --Behavior tab..
    TriggerDuration = 0.25,
    ClickToActivate = true,
    HideWhileZoning = true,
    HideWhileCutscene = true,
    HideWhileMap = true,
    DefaultSelectTarget = false,
    EnableDoubleTap = true,
    EnablePriority = true,
    AllowInventoryPassthrough = true,

    --Controller Tab..
    Controller = 'dualsense',
    BindMenuTimer = 1,
    TapTimer = 0.4,
};
gSettings = settings.load(defaultSettings);

local function UpdateSettings()
    local version = tonumber(addon.version);
    if (gSettings.Version ~= version) then
        if (type(gSettings.Version) ~= 'number') or (gSettings.Version < 2.0) then
            for key,val in pairs(gSettings) do
                local newVal = defaultSettings[key];
                if newVal then
                    gSettings[key] = newVal;
                else
                    gSettings[key] = nil;
                end
            end
            Message('Settings from a prior incompatible version detected.  Updating settings.')
        end

        if (gSettings.Version < 2.09) then
            if (gSettings.SwapToSingleDisplay ~= nil) then
                if (gSettings.SwapToSingleDisplay == true) then
                    gSettings.LTRTMode = 'Single';
                else
                    gSettings.LTRTMode = 'FullDouble';
                end
                gSettings.SwapToSingleDisplay = nil;
            end
        end

        if (gSettings.Version < 2.5) then
            gSettings.Renderer = 'classic';
            gSettings.RendererSettings = {};

            local defaults = {
                SingleLayout = 'classic',
                SingleScale = 1.0,
                DoubleLayout = 'classic',
                DoubleScale = 1.0,
                ShowDoubleDisplay = true,
                LTRTMode = 'FullDouble',
                ShowPalette = true,
                ShowSinglePalette = false,
            };

            local classic = {};
            for key,val in pairs(defaults) do
                if (gSettings[key] ~= nil) then
                    classic[key] = gSettings[key];
                    gSettings[key] = nil;
                else
                    classic[key] = val;
                end
            end
            gSettings.RendererSettings.classic = classic;
        end

        gSettings.Version = version;
        settings.save();
    end
end

--Create exports..
local Initializer = {};

function Initializer:ApplyController()
    gController:SetLayout(gSettings.Controller);
end

function Initializer:ApplyRenderer()
    if (gRenderer ~= nil) then
        gRenderer:Destroy();
        gRenderer = nil;
    end
    
    local name = gSettings.Renderer;
    local path = string.format('%saddons/%s/renderers/%s/main.lua', AshitaCore:GetInstallPath(), addon.name, name);
    gRenderer = LoadFile_s(path);
    if (gRenderer == nil) then
        Error('Failed to load renderer.  Please enter "/tc" to open the menu and select a valid renderer.');
        return;
    end
    
    if (gSettings.RendererSettings[name] == nil) then
        gSettings.RendererSettings[name] = {};
    end
    gTextureCache:Clear();
    gRenderer:Initialize(gSettings.RendererSettings[name]);
end

settings.register('settings', 'settings_update', function(newSettings)
    gSettings = newSettings;
    UpdateSettings();
    Initializer:ApplyController();
    Initializer:ApplyRenderer();
end);

UpdateSettings();
Initializer:ApplyController();
Initializer:ApplyRenderer();

return Initializer;