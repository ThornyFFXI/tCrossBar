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

local DoubleDisplay = { Valid = false };

function DoubleDisplay:Destroy()
    self.Layout = nil;
    self.Elements = T{};
    self.Valid = false;
end

function DoubleDisplay:Initialize(layout)
    self.Layout = layout;
    self.PaletteDisplay = nil;
    self.Elements = T{};

    local position = gSettings.DoublePosition;
    for group = 0,1 do
        for macro = 1,8 do
            local index = (group * 8) + macro;
            local newElement = Element:New(GetButtonAlias(group + 1, macro), layout, layout.Elements[index].HotkeyLabel);
            newElement.OffsetX = layout.Elements[index].OffsetX;
            newElement.OffsetY = layout.Elements[index].OffsetY;
            newElement:SetPosition(position);
            self.Elements:append(newElement);
        end
    end

    if (self.Sprite == nil) then
        local sprite = ffi.new('ID3DXSprite*[1]');
        if (ffi.C.D3DXCreateSprite(d3d8.get_device(), sprite) == ffi.C.S_OK) then
            self.Sprite = d3d8.gc_safe_release(ffi.cast('ID3DXSprite*', sprite[0]));
        else
            Error('Failed to create Sprite in DoubleDisplay:Initialize.');
        end
    end
    
    self.Valid = (self.Sprite ~= nil);
    local obj = gdi:create_object(self.Layout.Palette, true);
    obj.OffsetX = self.Layout.Palette.OffsetX;
    obj.OffsetY = self.Layout.Palette.OffsetY;
    self.PaletteDisplay = obj;
    if (self.Layout.PalettePrev ~= nil) then
        local prevObj = gdi:create_object(self.Layout.PalettePrev, true);
        prevObj.OffsetX = self.Layout.PalettePrev.OffsetX;
        prevObj.OffsetY = self.Layout.PalettePrev.OffsetY;
        self.PalettePrevDisplay = prevObj;
    end
    if (self.Layout.PaletteNext ~= nil) then
        local nextObj = gdi:create_object(self.Layout.PaletteNext, true);
        nextObj.OffsetX = self.Layout.PaletteNext.OffsetX;
        nextObj.OffsetY = self.Layout.PaletteNext.OffsetY;
        self.PaletteNextDisplay = nextObj;
    end
    self:UpdateBindings(gBindings:GetFormattedBindings());
end

function DoubleDisplay:SetActivationTimer(macroState, macroIndex)
    local element;
    if (macroState == 1) then
        element = self.Elements[macroIndex];
    elseif (macroState == 2) then
        element = self.Elements[macroIndex + 8];
    end
    if (element ~= nil) then
        element.Activation = os.clock();
    end
end

local d3dwhite = d3d8.D3DCOLOR_ARGB(255, 255, 255, 255);
local d3ddim = d3d8.D3DCOLOR_ARGB(100, 255, 255, 255);
local vec_font_scale = ffi.new('D3DXVECTOR2', { 1.0, 1.0, });
local vec_position = ffi.new('D3DXVECTOR2', { 0, 0, });
local highlightScale = 1.25;
function DoubleDisplay:Render(macroState, forceSingle, dimState)
    if (self.Valid == false) then
        return;
    end

    local pos = gSettings.DoublePosition;
    local sprite = self.Sprite;
    sprite:Begin();

    -- Determine opacity and scale for each side based on dimState
    -- dimState: 0=All Full, 1=LT Full/RT Dim, 2=RT Full/LT Dim, -1=All Dim
    local leftOpacity = d3dwhite;
    local rightOpacity = d3dwhite;
    local leftScale = nil;
    local rightScale = nil;
    
    if (dimState == 1) then
        if (gSettings.DimInactive) then rightOpacity = d3ddim; end
        leftScale = highlightScale;
    elseif (dimState == 2) then
        if (gSettings.DimInactive) then leftOpacity = d3ddim; end
        rightScale = highlightScale;
    elseif (dimState == -1) then
        if (gSettings.DimInactive) then
            leftOpacity = d3ddim;
            rightOpacity = d3ddim;
        end
    end

    for _,object in ipairs(self.Layout.FixedObjects) do
        local component = self.Layout.Textures[object.Texture];
        vec_position.x = pos[1] + object.OffsetX;
        vec_position.y = pos[2] + object.OffsetY;

        local associatedState = object.AssociatedState;
        if (not forceSingle) or (associatedState == nil) or (associatedState == macroState) then
            -- Determine if object belongs to Left or Right side for dimming
            -- Heuristic: AssociatedState 1=Left, 2=Right. If nil, check OffsetX vs center
            local isLeft = (associatedState == 1) or (associatedState == nil and object.OffsetX < self.Layout.Panel.Width / 2);
            local objColor = isLeft and leftOpacity or rightOpacity;
            -- Scale isn't applied to fixed objects by default in this logic, only elements. 
            -- But if we wanted to scale the frame/dpad? Maybe too complex layout-wise. 
            sprite:Draw(component.Texture, component.Rect, component.Scale, nil, 0.0, vec_position, objColor);
        end
    end

    local renderElements = T{};
    if (macroState == 1) or (not forceSingle) then
        for i = 1,8 do
            renderElements:append({ Element = self.Elements[i], Opacity = leftOpacity, Scale = leftScale });
        end
    end
    if (macroState == 2) or (not forceSingle) then
        for i = 9,16 do
            renderElements:append({ Element = self.Elements[i], Opacity = rightOpacity, Scale = rightScale });
        end  
    end

    for _,item in ipairs(renderElements) do
        item.Element:RenderIcon(sprite, item.Opacity, item.Scale);
    end

    local showPalette = gSettings.ShowPalette;
    if (forceSingle) then
        showPalette = gSettings.ShowSinglePalette;
    end
    
    if showPalette then
        local paletteText = gBindings:GetDisplayText();
        if (paletteText) then
            local obj = self.PaletteDisplay;
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
        local prevObj = self.PalettePrevDisplay;
        if prevObj then
            local prevName = gBindings:GetPreviousPaletteName();
            if prevName then
                prevObj:set_text(prevName);
                local texture, rect = prevObj:get_texture();
                local posX = prevObj.OffsetX + pos[1];
                if (prevObj.settings.font_alignment == 1) then
                    vec_position.x = posX - (rect.right / 2);
                elseif (prevObj.settings.font_alignment == 2) then
                    vec_position.x = posX - rect.right;
                else
                    vec_position.x = posX;
                end
                vec_position.y = prevObj.OffsetY + pos[2];
                sprite:Draw(texture, rect, vec_font_scale, nil, 0.0, vec_position, d3dwhite);
            end
        end
        local nextObj = self.PaletteNextDisplay;
        if nextObj then
            local nextName = gBindings:GetNextPaletteName();
            if nextName then
                nextObj:set_text(nextName);
                local texture, rect = nextObj:get_texture();
                local posX = nextObj.OffsetX + pos[1];
                if (nextObj.settings.font_alignment == 1) then
                    vec_position.x = posX - (rect.right / 2);
                elseif (nextObj.settings.font_alignment == 2) then
                    vec_position.x = posX - rect.right;
                else
                    vec_position.x = posX;
                end
                vec_position.y = nextObj.OffsetY + pos[2];
                sprite:Draw(texture, rect, vec_font_scale, nil, 0.0, vec_position, d3dwhite);
            end
        end
    end
    
    for _,item in ipairs(renderElements) do
        -- Only render text if not dimmed (optional, user didn't specify, but safer for cleaner look)
        if (item.Opacity == d3dwhite) then
            item.Element:RenderText(sprite);
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
function DoubleDisplay:DragTest(e)
    local handle = self.Layout.DragHandle;
    local pos = gSettings.DoublePosition;
    local minX = pos[1] + handle.OffsetX;
    local maxX = minX + handle.Width;
    if (e.x < minX) or (e.x > maxX) then
        return false;
    end

    local minY = pos[2] + handle.OffsetY;
    local maxY = minY + handle.Height;
    return (e.y >= minY) and (e.y <= maxY);
end

function DoubleDisplay:HandleMouse(e)
    if (self.Valid == false) then
        return;
    end

    if dragActive then
        local pos = gSettings.DoublePosition;
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

    --Direct back to single display for activation..
    if (e.message == 513)  and (gSettings.ClickToActivate) then
        local hit, element = self:HitTest(e.x, e.y);
        if element ~= nil then
            if (element > 8) then
                gSingleDisplay:Activate(2, element - 8);
            else
                gSingleDisplay:Activate(1, element);
            end
            e.blocked = true;
        end
    end
end

function DoubleDisplay:HitTest(x, y)
    if (self.Valid == false) then
        return;
    end

    local pos = gSettings.DoublePosition;
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
    for index,element in ipairs(self.Elements) do
        if (element:HitTest(x, y)) then
            selectedElement = index;
        end
    end

    return true, selectedElement;
end

function DoubleDisplay:UpdateBindings(bindings)
    if (self.Valid == false) then
        return;
    end

    for i = 1,8 do
        self.Elements[i]:UpdateBinding(bindings[GetButtonAlias(1, i)]);
        self.Elements[i + 8]:UpdateBinding(bindings[GetButtonAlias(2, i)]);
    end
end

function DoubleDisplay:UpdatePosition()
    if (self.Valid == false) then
        return;
    end

    local position = gSettings.DoublePosition;

    for _,element in ipairs(self.Elements) do
        element:SetPosition(position);
    end
end

return DoubleDisplay;