--Initialize Globals..
require('helpers');
gTextureCache    = require('texturecache');
gBindings        = require('bindings');
gBindingGUI      = require('bindinggui');
gConfigGUI       = require('configgui');
gController      = require('controller');
gSingleDisplay   = require('singledisplay');
gDoubleDisplay   = require('doubledisplay');
settings         = require('settings');

local d3d8       = require('d3d8');
local ffi        = require('ffi');
local scaling    = require('scaling');

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
    --Layouts tab..
    SingleLayout = 'classicsingle',
    SingleScale = 1.0,
    DoubleLayout = 'classicdouble',
    DoubleScale = 1.0,
    TriggerDuration = 0.25,
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
    ClickToActivate = true,
    HideWhileZoning = true,
    HideWhileCutscene = true,
    HideWhileMap = true,
    DefaultSelectTarget = false,
    EnableDoubleTap = true,
    EnablePriority = true,
    ShowDoubleDisplay = true,
    SwapToSingleDisplay = false,
    AllowInventoryPassthrough = true,

    --Controller Tab..
    Controller = 'dualsense',
    BindMenuTimer = 1,
    TapTimer = 0.4,

    --No Tab..
    Position = T{},
};
gSettings = settings.load(defaultSettings);

--Gets target dimensions of texture from layout table..
local function GetDimensions(layout, key)
    for _,entry in ipairs(layout.FixedObjects) do
        if (key == entry.Texture) then
            return { Width=entry.Width, Height=entry.Height };
        end
    end

    if (key == 'Frame') then
        return { Width=layout.Frame.Width, Height=layout.Frame.Height };
    end
    
    return { Width=layout.Icon.Width, Height=layout.Icon.Height };
end

--Creates textures, assigns 
local function PrepareLayout(layout, scale)
    for _,singleTable in ipairs(T{layout, layout.FixedObjects, layout.Elements}) do
        for _,tableEntry in pairs(singleTable) do
            if (type(tableEntry) == 'table') then
                if (tableEntry.OffsetX ~= nil) then
                    tableEntry.OffsetX = tableEntry.OffsetX * scale;
                    tableEntry.OffsetY = tableEntry.OffsetY * scale;
                end
                if (tableEntry.Width ~= nil) then
                    tableEntry.Width = tableEntry.Width * scale;
                    tableEntry.Height = tableEntry.Height * scale;
                end
                if (tableEntry.font_height ~= nil) then
                    tableEntry.font_height = math.max(5, math.floor(tableEntry.font_height * scale));
                end
                if (tableEntry.outline_width ~= nil) then
                    tableEntry.outline_width = math.min(3, math.max(1, math.floor(tableEntry.outline_width * scale)));
                end
            end
        end
    end
    
    --Prepare textures for efficient rendering..
    for _,singleTable in ipairs(T{layout.SkillchainFrames, layout.Textures}) do
        for key,path in pairs(singleTable) do
            local tx = gTextureCache:GetTexture(path);
            if tx then
                --Get target dimensions and prepare a RECT and scale vector for rendering at that size..
                local dimensions = GetDimensions(layout, key);

                local preparedTexture = {};
                preparedTexture.Texture = tx.Texture;
                preparedTexture.Rect = ffi.new('RECT', { 0, 0, tx.Width, tx.Height });
                preparedTexture.Scale = ffi.new('D3DXVECTOR2', { dimensions.Width / tx.Width, dimensions.Height / tx.Height });
                singleTable[key] = preparedTexture;
            else
                singleTable[key] = nil;
            end
        end
    end

    layout.FadeOpacity = d3d8.D3DCOLOR_ARGB(layout.FadeOpacity, 255, 255, 255);
    layout.TriggerOpacity = d3d8.D3DCOLOR_ARGB(layout.TriggerOpacity, 255, 255, 255);
end

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

--Create exports..
local Initializer = {};

function Initializer:ApplyController()
    gController:SetLayout(gSettings.Controller);
end

function Initializer:ApplyLayout()
    gSingleDisplay:Destroy();
    gDoubleDisplay:Destroy();

    local singleLayout = LoadFile_s(GetResourcePath('layouts/' .. gSettings.SingleLayout));
    if singleLayout then
        PrepareLayout(singleLayout, gSettings.SingleScale);
        local position = gSettings.Position[gSettings.SingleLayout];
        if position == nil then
            gSettings.Position[gSettings.SingleLayout] = GetDefaultPosition(singleLayout);
            settings.save();
        end
        gSingleDisplay:Initialize(singleLayout);
    else
        Error('Failed to load single layout.');
    end

    local doubleLayout = LoadFile_s(GetResourcePath('layouts/' .. gSettings.DoubleLayout));
    if doubleLayout then
        PrepareLayout(doubleLayout, gSettings.DoubleScale);
        local position = gSettings.Position[gSettings.DoubleLayout];
        if position == nil then
            gSettings.Position[gSettings.DoubleLayout] = GetDefaultPosition(doubleLayout);
            settings.save();
        end
        gDoubleDisplay:Initialize(doubleLayout);
    else
        Error('Failed to load double layout.');
    end
    
    gTextureCache:Clear();
end

settings.register('settings', 'settings_update', function(newSettings)
    gSettings = newSettings;
    Initializer:ApplyController();
    Initializer:ApplyLayout();
end);

Initializer:ApplyController();
Initializer:ApplyLayout();

return Initializer;