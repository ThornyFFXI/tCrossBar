--[[
    Alternate renderers must provide definitions of the functions:
        renderer:Destroy()
        renderer:DrawConfigGUI(isOpen)
        renderer:Initialize(settingsTable)
        renderer:Render(elements, macroState)
    
    There are no other reserved keys, and all other implementations can be done as the designer wishes.
]]--
local config = LoadFile_s(string.format('%saddons/%s/renderers/classic/config.lua', AshitaCore:GetInstallPath(), addon.name));
local d3d8 = require('d3d8');
local ffi = require('ffi');
local gdi = require('gdifonts.include');
local d3dwhite = d3d8.D3DCOLOR_ARGB(255, 255, 255, 255);
local vec_font_scale = ffi.new('D3DXVECTOR2', { 1.0, 1.0, });
local vec_position = ffi.new('D3DXVECTOR2', { 0, 0, });
local textOrder = T { 'Hotkey', 'Cost', 'Recast', 'Name' };

local renderer = {};

--[[
    This function should remove anything that would not be properly cleaned up by simply going out of scope.
]]--
function renderer:Destroy()

end

--[[
    This function will be called every frame while the renderer's config GUI is open.
    This should present an IMGUI window that allows the renderer's display to be configured.
    Any settings should be saved back to the original table passed into renderer:Initialize.
    isOpen is a table with 1 key, a boolean for whether the GUI is open.
]]--
function renderer:DrawConfigGUI(isOpen)
    config:Render(isOpen);
end

--[[
    This function will be called from outside at launch.  The settings table will be nil on first load, and should be filled in accordingly.
    You can (and should) save any changes to this table by calling (global)settings.save(), in which case they will persist.
    Any one time setup should be done here.
]]--
function renderer:Initialize(settingsTable)
    self.ElementStates = {};
    self.Settings = settingsTable;
    config:Initialize(self.Settings);
    
    local sprite = ffi.new('ID3DXSprite*[1]');
    if (ffi.C.D3DXCreateSprite(d3d8.get_device(), sprite) == ffi.C.S_OK) then
        self.Sprite = d3d8.gc_safe_release(ffi.cast('ID3DXSprite*', sprite[0]));
    else
        Error('Failed to create sprite in renderer:Initialize.');
    end
end

--[[
    This function will be called every frame to draw the onscreen display.
    Elements is a table containing 6 sub-tables at indexes 1-6, each containing 8 macros at indexes 1-8 for the corresponding macro state.
    macroState is a number corresponding to the current controller state.
    You should always call Element:Tick on each individual update prior to using it's data to render.
    Anytime you draw an element, you MUST set the table entry HitBox to contain the values X, Y, Width, Height to maintain mouse compatibilty.
    This entry will be erased every frame and must be set again every frame when drawing.
]]--
function renderer:Render(elements, macroState)
    if (config.AllowDragSingle) then
        self:RenderSingleDisplay(elements, macroState);
        return;
    end

    if (config.AllowDragDouble) then
        self:RenderDoubleDisplay(elements, macroState);
        return;
    end

    local renderFunction = self.RenderSingleDisplay;
    if (macroState == 0) then
        if (self.Settings.ShowDoubleDisplay) then
            renderFunction = self.RenderDoubleDisplay;
        else
            return;
        end
    elseif (macroState < 3) and (self.Settings.LTRTMode ~= 'Single') then
        renderFunction = self.RenderDoubleDisplay;
    end

    renderFunction(self, elements, macroState);
end

function renderer:RenderDoubleDisplay(elements, macroState)
    local sprite = self.Sprite;
    if (sprite == nil) then
        return;
    end

    local pos = self.Settings.DoublePosition;
    if (pos == nil) then
        config:ResetPosition();
        pos = self.Settings.DoublePosition;
    end

    local forceSingle = (self.Settings.LTRTMode == 'HalfDouble') and (macroState ~= 0);
    local layout = config.DoubleLayout;
    sprite:Begin();
    
    for _,object in ipairs(layout.FixedObjects) do
        local component = layout.Textures[object.Texture];
        vec_position.x = pos[1] + object.OffsetX;
        vec_position.y = pos[2] + object.OffsetY;

        local associatedState = object.AssociatedState;
        if (not forceSingle) or (associatedState == nil) or (associatedState == macroState) then
            sprite:Draw(component.Texture, component.Rect, component.Scale, nil, 0.0, vec_position, d3dwhite);
        end
    end

    
    local showPalette = self.Settings.ShowPalette;
    if (forceSingle) then
        showPalette = self.Settings.ShowSinglePalette;
    end
    
    if showPalette then
        local paletteText = gBindings:GetDisplayText();
        if (paletteText) then
            local obj = self.DoublePaletteDisplay;
            if not obj then
                obj = gdi:create_object(layout.Palette, true);
                self.DoublePaletteDisplay = obj;
            end
            obj:set_text(paletteText);
            local texture, rect = obj:get_texture();
            local posX = layout.Palette.OffsetX + pos[1];
            if (obj.settings.font_alignment == 1) then
                vec_position.x = posX - (rect.right / 2);
            elseif (obj.settings.font_alignment == 2) then
                vec_position.x = posX - rect.right;
            else
                vec_position.x = posX;;
            end
            vec_position.y = layout.Palette.OffsetY + pos[2];
            sprite:Draw(texture, rect, vec_font_scale, nil, 0.0, vec_position, d3dwhite);
        end
    end
    
    for group = 1,2 do
        if (not forceSingle) or (group == macroState) then
            for index,element in ipairs(elements[group]) do
                local position = layout.Elements[((group-1)*8)+index];
                self:RenderElement(element, layout, { X=pos[1] + position.OffsetX, Y=pos[2] + position.OffsetY });
            end
        end
    end
    
    if (config.AllowDragDouble) then
        local component = layout.Textures[layout.DragHandle.Texture];
        vec_position.x = pos[1] + layout.DragHandle.OffsetX;
        vec_position.y = pos[2] + layout.DragHandle.OffsetY;
        sprite:Draw(component.Texture, component.Rect, component.Scale, nil, 0.0, vec_position, d3dwhite);
    end

    sprite:End();
end

function renderer:RenderSingleDisplay(elements, macroState)
    local sprite = self.Sprite;
    if (sprite == nil) then
        return;
    end

    local pos = self.Settings.SinglePosition;
    if (pos == nil) then
        config:ResetPosition();
        pos = self.Settings.SinglePosition;
    end

    local layout = config.SingleLayout;
    sprite:Begin();

    for _,object in ipairs(layout.FixedObjects) do
        local component = layout.Textures[object.Texture];
        vec_position.x = pos[1] + object.OffsetX;
        vec_position.y = pos[2] + object.OffsetY;
        sprite:Draw(component.Texture, component.Rect, component.Scale, nil, 0.0, vec_position, d3dwhite);
    end
    
    if (macroState == 0) then
        macroState = 1;
    end
    local group = elements[macroState];
    if group then
        for index,element in ipairs(group) do
            local position = layout.Elements[index];
            self:RenderElement(element, layout, { X=pos[1] + position.OffsetX, Y=pos[2] + position.OffsetY });
        end
    end
    
    local paletteText = gBindings:GetDisplayText();
    if (self.Settings.ShowSinglePalette) and (paletteText) then
        local obj = self.SinglePaletteDisplay;
        if not obj then
            self.SinglePaletteDisplay = gdi:create_object(layout.Palette, true);
            obj = self.SinglePaletteDisplay;
        end
        if obj then
            obj:set_text(paletteText);
            local texture, rect = obj:get_texture();
            local posX = layout.Palette.OffsetX + pos[1];
            if (obj.settings.font_alignment == 1) then
                vec_position.x = posX - (rect.right / 2);
            elseif (obj.settings.font_alignment == 2) then
                vec_position.x = posX - rect.right;
            else
                vec_position.x = posX;;
            end
            vec_position.y = layout.Palette.OffsetY + pos[2];
            sprite:Draw(texture, rect, vec_font_scale, nil, 0.0, vec_position, d3dwhite);
        end
    end
    
    if (config.AllowDragSingle) then
        local component = layout.Textures[layout.DragHandle.Texture];
        vec_position.x = pos[1] + layout.DragHandle.OffsetX;
        vec_position.y = pos[2] + layout.DragHandle.OffsetY;
        sprite:Draw(component.Texture, component.Rect, component.Scale, nil, 0.0, vec_position, d3dwhite);
    end

    sprite:End();
end

function renderer:RenderElement(element, layout, position)
    element:Tick();
    
    local sprite = self.Sprite;
    local positionX = position.X;
    local positionY = position.Y;

    local state = self.ElementStates[element];
    if (state == nil) then
        self.ElementStates[element] = { FontObjects={} };
        state = self.ElementStates[element];
    end

    --Draw frame first..
    if ((element.Binding) or (gSettings.ShowEmpty)) and (gSettings.ShowFrame) then
        local component = layout.Textures.Frame;
        if component then
            vec_position.x = positionX + layout.Frame.OffsetX;
            vec_position.y = positionY + layout.Frame.OffsetY;
            sprite:Draw(component.Texture, component.Rect, component.Scale, nil, 0.0, vec_position, d3dwhite);
        end
    end

    if (element.Binding == nil) then
        return;
    end

    --Evaluate skillchain state..
    local drawIcon = true;
    vec_position.x = positionX + layout.Icon.OffsetX;
    vec_position.y = positionY + layout.Icon.OffsetY;
    if (element.State.Skillchain ~= nil) then
        if (element.State.Skillchain.Open) then
            if (state.SkillchainAnimation == nil) then
                state.SkillchainAnimation =
                {
                    Frame = 1,
                    Time = os.clock();
                };
            elseif (os.clock() > (state.SkillchainAnimation.Time + layout.SkillchainFrameLength)) then
                state.SkillchainAnimation.Frame = state.SkillchainAnimation.Frame + 1;
                if (state.SkillchainAnimation.Frame > #layout.SkillchainFrames) then
                    state.SkillchainAnimation.Frame = 1;
                end
                state.SkillchainAnimation.Time = os.clock();
            end
        else
            state.SkillchainAnimation = nil;
        end
        
        if (gSettings.ShowSkillchainIcon) and (element.Binding.ShowSkillchainIcon) then
            vec_position.x = positionX + layout.Icon.OffsetX;
            vec_position.y = positionY + layout.Icon.OffsetY;
            local opacity = d3dwhite;
            if (gSettings.ShowFade) and (element.Binding.ShowFade) and (not element.State.Ready) then
                opacity = layout.FadeOpacity;
            end
            local icon = layout.Textures[element.State.Skillchain.Name];
            sprite:Draw(icon.Texture, icon.Rect, icon.Scale, nil, 0.0, vec_position, opacity);
            drawIcon = false;
        end
    else
        self.SkillchainAnimation = nil;
    end

    --Draw icon over frame..
    if drawIcon then
        local tx = element.Texture;
        if (tx) then
            vec_position.x = positionX + layout.Icon.OffsetX;
            vec_position.y = positionY + layout.Icon.OffsetY;
            local opacity = d3dwhite;
            if (gSettings.ShowFade) and (element.Binding.ShowFade) and (not element.State.Ready) then
                opacity = layout.FadeOpacity;
            end
            
            local rect = ffi.new('RECT', { 0, 0, tx.Width, tx.Height });
            local scale = ffi.new('D3DXVECTOR2', { layout.Icon.Width / tx.Width, layout.Icon.Height / tx.Height });
            sprite:Draw(tx.Texture, rect, scale, nil, 0.0, vec_position, opacity);
        end
    end

    --Draw skillchain animation if applicable..
    if (self.SkillchainAnimation) and (gSettings.ShowSkillchainAnimation) and (element.Binding.ShowSkillchainAnimation) then
        local component = layout.SkillchainFrames[self.SkillchainAnimation.Frame];
        if component then
            vec_position.x = positionX + layout.Icon.OffsetX;
            vec_position.y = positionY + layout.Icon.OffsetY;
            sprite:Draw(component.Texture, component.Rect, component.Scale, nil, 0.0, vec_position, d3dwhite);
        end
    end

    --Draw crossout if applicable..
    if (gSettings.ShowCross) and (element.Binding.ShowCross) and (not element.State.Available) then
        local component = layout.Textures.Cross;
        if component then
            vec_position.x = positionX + layout.Icon.OffsetX;
            vec_position.y = positionY + layout.Icon.OffsetY;
            sprite:Draw(component.Texture, component.Rect, component.Scale, nil, 0.0, vec_position, d3dwhite);
        end
    end

    --Draw trigger if applicable..
    if (gSettings.ShowTrigger) and (element.Binding.ShowTrigger) and (element.State.Activated) then
        local component = layout.Textures.Trigger;
        if component then
            vec_position.x = positionX + layout.Icon.OffsetX;
            vec_position.y = positionY + layout.Icon.OffsetY;
            sprite:Draw(component.Texture, component.Rect, component.Scale, nil, 0.0, vec_position, layout.TriggerOpacity);
        end
    end
    
    --Draw text elements..
    for _,entry in ipairs(textOrder) do
        local setting = 'Show' .. entry;
        if (gSettings[setting]) and (element.Binding[setting]) then
            local obj = state.FontObjects[entry];
            if not obj then
                local data = layout[entry];
                if data then
                    obj = gdi:create_object(data, true);
                    obj.OffsetX = data.OffsetX;
                    obj.OffsetY = data.OffsetY;
                    state.FontObjects[entry] = obj;
                end
            end
            if obj then
                local text = element.State[entry];
                if (type(text) == 'string') and (text ~= '') then
                    obj:set_text(text);
                    local texture, rect = obj:get_texture();
                    if (texture ~= nil) then
                        local posX = obj.OffsetX + positionX;
                        if (obj.settings.font_alignment == 1) then
                            vec_position.x = posX - (rect.right / 2);
                        elseif (obj.settings.font_alignment == 2) then
                            vec_position.x = posX - rect.right;
                        else
                            vec_position.x = posX;;
                        end
                        vec_position.y = obj.OffsetY + positionY;
                        sprite:Draw(texture, rect, vec_font_scale, nil, 0.0, vec_position, d3dwhite);
                    end
                end
            end
        end
    end
end

return renderer;