local d3d8 = require('d3d8');
local Element = require('element');
local ffi = require('ffi');
local gdi = require('gdifonts.include');

local function GetButtonAlias(comboIndex, buttonIndex)
    local macroComboBinds = {
        [1] = 'LT',
        [2] = 'RT',
        [3] = 'LTRT',
        [4] = 'RTLT',
        [5] = 'LT2',
        [6] = 'RT2'
    };
    return string.format('%s:%d', macroComboBinds[comboIndex], buttonIndex);
end

local SingleDisplay = { Valid = false };

function SingleDisplay:Destroy()
    self.Layout = nil;
    self.ElementGroups = T{};
    self.Valid = false;
end

function SingleDisplay:Initialize(layout)
    self.Layout = layout;
    self.ElementGroups = T{};

    local position = gSettings.SinglePosition;

    for group = 1,6 do
        self.ElementGroups[group] = T{};
        for macro = 1,8 do
            local newElement = Element:New(GetButtonAlias(group, macro), layout);
            newElement.OffsetX = layout.Elements[macro].OffsetX;
            newElement.OffsetY = layout.Elements[macro].OffsetY;
            newElement:SetPosition(position);
            self.ElementGroups[group]:append(newElement);
        end
    end

    if (self.Sprite == nil) then
        local sprite = ffi.new('ID3DXSprite*[1]');
        if (ffi.C.D3DXCreateSprite(d3d8.get_device(), sprite) == ffi.C.S_OK) then
            self.Sprite = d3d8.gc_safe_release(ffi.cast('ID3DXSprite*', sprite[0]));
        else
            Error('Failed to create Sprite in SingleDisplay:Initialize.');
        end
    end
    
    self.Valid = (self.Sprite ~= nil);
    local obj = gdi:create_object(self.Layout.Palette, true);
    obj.OffsetX = self.Layout.Palette.OffsetX;
    obj.OffsetY = self.Layout.Palette.OffsetY;
    self.PaletteDisplay = obj;
    self:UpdateBindings(gBindings:GetFormattedBindings());
end

function SingleDisplay:GetElementByMacro(macroState, macroIndex)
    if (self.Valid == false) then
        return;
    end

    local group = self.ElementGroups[macroState];
    if (group ~= nil) then
        local element = group[macroIndex];
        if (element ~= nil) then
            return element;
        end
    end
end

function SingleDisplay:Activate(macroState, macroIndex)
    if (self.Valid == false) then
        return;
    end

    local element = self:GetElementByMacro(macroState, macroIndex);
    if element then
        element:Activate();
        gDoubleDisplay:SetActivationTimer(macroState, macroIndex);
    end
end

local d3dwhite = d3d8.D3DCOLOR_ARGB(255, 255, 255, 255);
local vec_font_scale = ffi.new('D3DXVECTOR2', { 1.0, 1.0, });
local vec_position = ffi.new('D3DXVECTOR2', { 0, 0, });
function SingleDisplay:Render(macroState)
    if (self.Valid == false) or (macroState == 0) then
        return;
    end
    self.LastRenderState = macroState;

    local pos = gSettings.SinglePosition;
    local sprite = self.Sprite;
    sprite:Begin();

    for _,object in ipairs(self.Layout.FixedObjects) do
        local component = self.Layout.Textures[object.Texture];
        vec_position.x = pos[1] + object.OffsetX;
        vec_position.y = pos[2] + object.OffsetY;
        sprite:Draw(component.Texture, component.Rect, component.Scale, nil, 0.0, vec_position, d3dwhite);
    end

    local group = self.ElementGroups[macroState];
    if group then
        for _,element in ipairs(group) do
            element:RenderIcon(sprite);
        end
        for _,element in ipairs(group) do
            element:RenderText(sprite);
        end
    end
    
    local paletteText = gBindings:GetDisplayText();
    if (gSettings.ShowSinglePalette) and (paletteText) then
        local obj = self.PaletteDisplay;
        if obj then
            obj:set_text(paletteText);
            local texture, rect = obj:get_texture();
            local posX = obj.OffsetX + pos[1];
            if (obj.settings.font_alignment == 1) then
                vec_position.x = posX - (rect.right / 2);
            elseif (obj.settings.font_alignment == 2) then
                vec_position.x = posX - rect.right;
            else
                vec_position.x = posX;;
            end
            vec_position.y = obj.OffsetY + pos[2];
            sprite:Draw(texture, rect, vec_font_scale, nil, 0.0, vec_position, d3dwhite);
        end
    end
    
    if (self.AllowDrag) then
        local component = self.Layout.Textures[self.Layout.DragHandle.Texture];
        vec_position.x = pos[1] + self.Layout.DragHandle.OffsetX;
        vec_position.y = pos[2] + self.Layout.DragHandle.OffsetY;
        sprite:Draw(component.Texture, component.Rect, component.Scale, nil, 0.0, vec_position, d3dwhite);
    end

    sprite:End();
end

local dragPosition = { 0, 0 };
local dragActive = false;
function SingleDisplay:DragTest(e)
    local handle = self.Layout.DragHandle;
    local pos = gSettings.SinglePosition;
    local minX = pos[1] + handle.OffsetX;
    local maxX = minX + handle.Width;
    if (e.x < minX) or (e.x > maxX) then
        return false;
    end

    local minY = pos[2] + handle.OffsetY;
    local maxY = minY + handle.Height;
    return (e.y >= minY) and (e.y <= maxY);
end

function SingleDisplay:HandleMouse(e)
    if (self.Valid == false) then
        return;
    end

    if dragActive then
        local pos = gSettings.SinglePosition;
        pos[1] = pos[1] + (e.x - dragPosition[1]);
        pos[2] = pos[2] + (e.y - dragPosition[2]);
        dragPosition[1] = e.x;
        dragPosition[2] = e.y;
        self:UpdatePosition();
        if (e.message == 514) or (not self.AllowDrag) then
            dragActive = false;
            settings.save();
        end
    elseif (self.AllowDrag) and (e.message == 513) and self:DragTest(e) then
        dragActive = true;
        dragPosition[1] = e.x;
        dragPosition[2] = e.y;
        e.blocked = true;
        return;
    end

    if (e.message == 513) and (gSettings.ClickToActivate) then
        local hit, element = self:HitTest(e.x, e.y);
        if element ~= nil then
            local group = self.ElementGroups[self.LastRenderState];
            if group ~= nil then
                element = group[element];
                if element then
                    element:Activate();
                    e.blocked = true;
                end
            end
        end
    end
end

function SingleDisplay:HitTest(x, y)
    if (self.Valid == false) then
        return;
    end

    local pos = gSettings.SinglePosition;
    if (x < pos[1]) or (y < pos[2]) then
        return false;
    end

    if (x > (pos[1] + self.Layout.Panel.Width)) then
        return false;
    end

    if (y > (pos[2] + self.Layout.Panel.Height)) then
        return false;
    end

    local selectedElement = 0;
    local group = self.ElementGroups[1];
    if group then
        for index,element in ipairs(group) do
            if (element:HitTest(x, y)) then
                selectedElement = index;
            end
        end
    end

    return true, selectedElement;
end

function SingleDisplay:UpdateBindings(bindings)
    if (self.Valid == false) then
        return;
    end

    for macroState,group in ipairs(self.ElementGroups) do
        for macroIndex,element in ipairs(group) do
            element:UpdateBinding(bindings[GetButtonAlias(macroState, macroIndex)]);
        end
    end
end

function SingleDisplay:UpdatePosition()
    if (self.Valid == false) then
        return;
    end
    
    local position = gSettings.SinglePosition;

    for _,group in ipairs(self.ElementGroups) do
        for _,element in ipairs(group) do
            element:SetPosition(position);
        end
    end
end

return SingleDisplay;