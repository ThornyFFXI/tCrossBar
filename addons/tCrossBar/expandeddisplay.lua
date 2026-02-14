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

local ExpandedDisplay = { Valid = false };

function ExpandedDisplay:Destroy()
    self.Layout = nil;
    self.Elements = T{};
    self.Valid = false;
end

function ExpandedDisplay:Initialize(layout)
    self.Layout = layout;
    self.Elements = T{};

    local position = gSettings.ExpandedPosition;
    -- LT2 elements (combo index 5) go into slots 1-8
    -- RT2 elements (combo index 6) go into slots 9-16
    for group = 0,1 do
        for macro = 1,8 do
            local index = (group * 8) + macro;
            local comboIndex = group + 5; -- 5 = LT2, 6 = RT2
            local newElement = Element:New(GetButtonAlias(comboIndex, macro), layout, layout.Elements[index].HotkeyLabel);
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
            Error('Failed to create Sprite in ExpandedDisplay:Initialize.');
        end
    end
    
    self.Valid = (self.Sprite ~= nil);
    self:UpdateBindings(gBindings:GetFormattedBindings());
end

function ExpandedDisplay:SetActivationTimer(macroState, macroIndex)
    local element;
    if (macroState == 5) then
        element = self.Elements[macroIndex];
    elseif (macroState == 6) then
        element = self.Elements[macroIndex + 8];
    end
    if (element ~= nil) then
        element.Activation = os.clock();
    end
end

local d3dwhite = d3d8.D3DCOLOR_ARGB(255, 255, 255, 255);
local d3ddim = d3d8.D3DCOLOR_ARGB(100, 255, 255, 255);
local vec_position = ffi.new('D3DXVECTOR2', { 0, 0, });
local highlightScale = 1.25;
function ExpandedDisplay:Render(highlightState)
    if (self.Valid == false) then
        return;
    end

    local pos = gSettings.ExpandedPosition;
    local sprite = self.Sprite;
    sprite:Begin();

    -- Determine which half is highlighted (nil = none, 5 = left/LT2, 6 = right/RT2)
    local leftHighlighted = (highlightState == 5);
    local rightHighlighted = (highlightState == 6);
    local hasHighlight = (highlightState == 5) or (highlightState == 6);

    -- Render fixed objects (dpad/buttons center icons)
    for _,object in ipairs(self.Layout.FixedObjects) do
        local component = self.Layout.Textures[object.Texture];
        if component then
            local objColor = d3dwhite;
            local isLeft = (object.AssociatedState == 1) or (object.AssociatedState == nil and object.OffsetX < self.Layout.Panel.Width / 2);
            
            -- Default to dimmed if no highlight, or if highlighted but not active side
            local isActive = (hasHighlight and ((isLeft and leftHighlighted) or (not isLeft and rightHighlighted)));
            if not isActive and gSettings.DimInactive then
                objColor = d3ddim;
            end

            vec_position.x = pos[1] + object.OffsetX;
            vec_position.y = pos[2] + object.OffsetY;
            sprite:Draw(component.Texture, component.Rect, component.Scale, nil, 0.0, vec_position, objColor);
        end
    end

    -- Render elements with highlight support
    -- Elements 1-8 = LT2 (left half), 9-16 = RT2 (right half)
    for i, element in ipairs(self.Elements) do
        local isLeft = (i <= 8);
        local isActive = (hasHighlight and ((isLeft and leftHighlighted) or (not isLeft and rightHighlighted)));
        local isDimmed = not isActive;
        
        local scaleOverride = nil;
        if isActive then
            scaleOverride = highlightScale;
        end

        local colorOverride = nil;
        if isDimmed and gSettings.DimInactive then
            colorOverride = d3ddim;
        end

        element:RenderIcon(sprite, colorOverride, scaleOverride);
    end

    for i, element in ipairs(self.Elements) do
        local isLeft = (i <= 8);
        local isActive = (hasHighlight and ((isLeft and leftHighlighted) or (not isLeft and rightHighlighted)));
        local isDimmed = not isActive;
        if (not isDimmed) or (not gSettings.DimInactive) then
            element:RenderText(sprite);
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
function ExpandedDisplay:DragTest(e)
    local handle = self.Layout.DragHandle;
    local pos = gSettings.ExpandedPosition;
    local minX = pos[1] + handle.OffsetX;
    local maxX = minX + handle.Width;
    if (e.x < minX) or (e.x > maxX) then
        return false;
    end

    local minY = pos[2] + handle.OffsetY;
    local maxY = minY + handle.Height;
    return (e.y >= minY) and (e.y <= maxY);
end

function ExpandedDisplay:HandleMouse(e)
    if (self.Valid == false) then
        return;
    end

    if dragActive then
        local pos = gSettings.ExpandedPosition;
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
                gSingleDisplay:Activate(6, element - 8);
            else
                gSingleDisplay:Activate(5, element);
            end
            e.blocked = true;
        end
    end
end

function ExpandedDisplay:HitTest(x, y)
    if (self.Valid == false) then
        return;
    end

    local pos = gSettings.ExpandedPosition;
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

function ExpandedDisplay:UpdateBindings(bindings)
    if (self.Valid == false) then
        return;
    end

    for i = 1,8 do
        self.Elements[i]:UpdateBinding(bindings[GetButtonAlias(5, i)]);
        self.Elements[i + 8]:UpdateBinding(bindings[GetButtonAlias(6, i)]);
    end
end

function ExpandedDisplay:UpdatePosition()
    if (self.Valid == false) then
        return;
    end

    local position = gSettings.ExpandedPosition;

    for _,element in ipairs(self.Elements) do
        element:SetPosition(position);
    end
end

return ExpandedDisplay;
