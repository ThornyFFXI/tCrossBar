local d3d8 = require('d3d8');
local ffi = require('ffi');
local imgui = require('imgui');
local scaling = require('scaling');

local ltrtmodes = T{ 'FullDouble', 'HalfDouble', 'Single' };
local header = { 1.0, 0.75, 0.55, 1.0 };
local defaultSettings = {
    SingleLayout = 'classic',
    SingleScale = 1.0,
    DoubleLayout = 'classic',
    DoubleScale = 1.0,
    ShowDoubleDisplay = true,
    LTRTMode = 'FullDouble',
    ShowPalette = true,
    ShowSinglePalette = false,
};
local state = {};

local function PrepareLayout(layout, scale)
    do
        local tx = layout.Textures[layout.DragHandle.Texture]
        layout.DragHandle.Width = tx.Width;
        layout.DragHandle.Height = tx.Height;
    end

    for _,singleTable in ipairs(T{layout, layout.FixedObjects, layout.Elements, layout.Textures}) do
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
        for key,entry in pairs(singleTable) do
            local tx,dimensions;
            if type(entry) == 'table' then
                tx = gTextureCache:GetTexture(entry.Path);
                dimensions = { Width=entry.Width, Height=entry.Height };
            else
                tx = gTextureCache:GetTexture(entry)
                dimensions = { Width=layout.Icon.Width, Height=layout.Icon.Height };
            end

            if tx and dimensions then
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
    return layout;
end

local function GetLayouts()
    local layouts = T{};
    local layoutPaths = T{
        string.format('%sconfig/addons/%s/resources/layouts/classic/', AshitaCore:GetInstallPath(), addon.name),
        string.format('%saddons/%s/resources/layouts/classic/', AshitaCore:GetInstallPath(), addon.name),
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
end

local config = {};

function config:Initialize(currentSettings)
    self.Settings = currentSettings;
    for key,val in pairs(defaultSettings) do
        if (self.Settings[key] == nil) then
            self.Settings[key] = val;
        end
    end

    GetLayouts();
    self:LoadLayouts();
end

function config:LoadLayouts()
    self.SingleCache = LoadFile_s(GetResourcePath('layouts/classic/' .. self.Settings.SingleLayout)).Single;
    self.DoubleCache = LoadFile_s(GetResourcePath('layouts/classic/' .. self.Settings.DoubleLayout)).Double;
    self:Rescale();
end

function config:Rescale()
    if (self.SingleCache) then
        self.SingleLayout = PrepareLayout(self.SingleCache:copy(true), self.Settings.SingleScale);
    else
        self.SingleLayout = nil;
        Error('Failed to load or prepare single layout.  Please enter "/tc" to open the menu, click "Renderer Settings", and select a valid layout.');
    end

    if (self.DoubleCache) then
        self.DoubleLayout = PrepareLayout(self.DoubleCache:copy(true), self.Settings.DoubleScale);
    else
        self.DoubleLayout = nil;
        Error('Failed to load double layout.  Please enter "/tc" to open the menu and select a valid layout.');
    end
    self:ResetPosition();
end

function config:Render(isOpen)
    if (imgui.Begin('Classic Renderer Config', isOpen, ImGuiWindowFlags_AlwaysAutoResize)) then

        imgui.TextColored(header, 'Single Layout');
        if (imgui.BeginCombo('##ClassictCrossBarSingleLayoutSelectConfig', self.Settings.SingleLayout, ImGuiComboFlags_None)) then
            for _,layout in ipairs(state.Layouts) do
                if (imgui.Selectable(layout, layout == self.Settings.SingleLayout)) then
                    if (self.Settings.SingleLayout ~= layout) then
                        self.Settings.SingleLayout = layout;
                        self:LoadLayouts(); --This will save when it calls ResetPosition.
                    end
                end
            end
            imgui.EndCombo();
        end
        local buffer = { self.Settings.SingleScale };
        if (imgui.SliderFloat('##ClassicSingleScale', buffer, 0.5, 3, '%.2f', ImGuiSliderFlags_AlwaysClamp)) then
            self.Settings.SingleScale = buffer[1];
            self:Rescale(); --This will save when it calls ResetPosition.
        end
        local buttonName = string.format('%s##ClassicMoveToggleSingle', (self.AllowDragSingle == true) and 'End Drag' or 'Allow Drag');
        if (imgui.Button(buttonName)) then
            self.AllowDragSingle = not self.AllowDragSingle;
        end
        imgui.ShowHelp('Allows you to drag the single display.', true);
        
        imgui.TextColored(header, 'Double Layout');
        if (imgui.BeginCombo('##ClassictCrossBarDoubleLayoutSelectConfig', self.Settings.DoubleLayout, ImGuiComboFlags_None)) then
            for _,layout in ipairs(state.Layouts) do
                if (imgui.Selectable(layout, layout == self.Settings.DoubleLayout)) then
                    if (self.Settings.DoubleLayout ~= layout) then
                        self.Settings.DoubleLayout = layout;
                        self:LoadLayouts(); --This will save when it calls ResetPosition.
                    end
                end
            end
            imgui.EndCombo();
        end
        local buffer = { self.Settings.DoubleScale };
        if (imgui.SliderFloat('##ClassicDoubleScale', buffer, 0.5, 3, '%.2f', ImGuiSliderFlags_AlwaysClamp)) then
            self.Settings.DoubleScale = buffer[1];
            self:Rescale(); --This will save when it calls ResetPosition.
        end
        buttonName = string.format('%s##ClassicMoveToggleDouble', (self.AllowDragDouble == true) and 'End Drag' or 'Allow Drag');
        if (imgui.Button(buttonName)) then
            self.AllowDragDouble = not self.AllowDragDouble;
        end
        imgui.ShowHelp('Allows you to drag the double display.', true);

        imgui.TextColored(header, 'All Layouts');
        if (imgui.Button('Refresh')) then
            GetLayouts();
        end
        imgui.ShowHelp('Reloads available layouts from disk.', true);
        if (imgui.Button('Reset Position')) then
            self:ResetPosition(); --This will save.
        end
        imgui.ShowHelp('Resets all layouts to default position.', true);
        
        imgui.TextColored(header, 'LT-RT Display');
        imgui.ShowHelp('Determines what should be displayed when using the single LT or single RT macro.');
        if (imgui.BeginCombo('##ClassictCrossBarLTRTMode', self.Settings.LTRTMode, ImGuiComboFlags_None)) then
            for _,text in ipairs(ltrtmodes) do
                if (imgui.Selectable(text, self.Settings.LTRTMode == text)) then
                    self.Settings.LTRTMode = text;
                    settings.save();
                end
            end
            imgui.EndCombo();
        end
        
        if imgui.Checkbox('Always Show Double##ClassictCrossBarShowDoubleDisplay', { self.Settings.ShowDoubleDisplay }) then
            self.Settings.ShowDoubleDisplay = not self.Settings.ShowDoubleDisplay;
            settings.save();
        end
        imgui.ShowHelp('When enabled, your L2 and R2 macros will be shown together while no combo keys are pressed.');
    end
end

function config:ResetPosition()
    if ((scaling.window.w == -1) or (scaling.window.h == -1) or (scaling.menu.w == -1) or (scaling.menu.h == -1)) then
        self.Settings.SinglePosition = { 0, 0 };
        self.Settings.DoublePosition = { 0, 0 };
    else
        local single = {};
        single[1] = (scaling.window.w - self.SingleLayout.Panel.Width) / 2;
        single[2] = scaling.window.h - (scaling.scale_height(136) + self.SingleLayout.Panel.Height);
        self.Settings.SinglePosition = single;

        local double = {};
        double[1] = (scaling.window.w - self.DoubleLayout.Panel.Width) / 2;
        double[2] = scaling.window.h - (scaling.scale_height(136) + self.DoubleLayout.Panel.Height);
        self.Settings.DoublePosition = double;
    end
    settings.save();
end

return config;