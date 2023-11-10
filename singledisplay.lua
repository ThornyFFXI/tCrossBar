local d3d8 = require('d3d8');
local element = require('element');
local ffi = require('ffi');
local player = require('state.player');
--Thanks to Velyn for the event system and interface hidden signatures!
local pGameMenu = ashita.memory.find('FFXiMain.dll', 0, "8B480C85C974??8B510885D274??3B05", 16, 0);
local pEventSystem = ashita.memory.find('FFXiMain.dll', 0, "A0????????84C0741AA1????????85C0741166A1????????663B05????????0F94C0C3", 0, 0);
local pInterfaceHidden = ashita.memory.find('FFXiMain.dll', 0, "8B4424046A016A0050B9????????E8????????F6D81BC040C3", 0, 0);

local function GetMenuName()
    local subPointer = ashita.memory.read_uint32(pGameMenu);
    local subValue = ashita.memory.read_uint32(subPointer);
    if (subValue == 0) then
        return '';
    end
    local menuHeader = ashita.memory.read_uint32(subValue + 4);
    local menuName = ashita.memory.read_string(menuHeader + 0x46, 16);
    return string.gsub(menuName, '\x00', '');
end

local function GetEventSystemActive()
    if (pEventSystem == 0) then
        return false;
    end
    local ptr = ashita.memory.read_uint32(pEventSystem + 1);
    if (ptr == 0) then
        return false;
    end

    return (ashita.memory.read_uint8(ptr) == 1);

end

local function GetInterfaceHidden()
    if (pEventSystem == 0) then
        return false;
    end
    local ptr = ashita.memory.read_uint32(pInterfaceHidden + 10);
    if (ptr == 0) then
        return false;
    end

    return (ashita.memory.read_uint8(ptr + 0xB4) == 1);
end

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

local SingleDisplay = {};

function SingleDisplay:Initialize(layout, scale)
    self.Layout = layout;

    --Prescale offsets and hitboxes..
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
            end        
        end    
    end
    
    --Prepare textures for efficient rendering..
    for _,singleTable in ipairs(T{layout.SkillchainFrames, layout.Textures}) do
        for key,path in pairs(singleTable) do
            local tx = gTextureCache:GetTexture(path);
            if tx then
                local dimensions = GetDimensions(key);

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

    self.ElementGroups = T{};

    for group = 1,6 do
        self.ElementGroups[group] = T{};
        for macro = 1,8 do
            local newElement = element:New(GetButtonAlias(group, macro), layout);
            newElement.OffsetX = layout.Elements[macro].OffsetX;
            newElement.OffsetY = layout.Elements[macro].OffsetY;
            newElement:SetPosition(gSettings.Position[gSettings.Layout].SingleDisplay);
            self.ElementGroups[group]:append(newElement);
        end
    end

    if (self.Sprite == nil) then
        local sprite = ffi.new('ID3DXSprite*[1]');
        if (ffi.C.D3DXCreateSprite(d3d8.get_device(), self.Sprite) == ffi.C.S_OK) then
            self.Sprite = d3d8.gc_safe_release(ffi.cast('ID3DXSprite*', sprite[0]));
        else
            Error('Failed to create Sprite in SingleDisplay:Initialize.');
        end
    end
end

function SingleDisplay:Destroy()
    self.Layout = nil;
    self.ElementGroups = T{};
end

function SingleDisplay:GetElementByMacro(macroState, macroIndex)
    local group = self.ElementGroups[macroState];
    if (group ~= nil) then
        local element = group[macroIndex];
        if (element ~= nil) then
            return element;
        end
    end
end

function SingleDisplay:Activate(macroState, macroIndex)
    local element = self:GetElementByMacro(macroState, macroIndex);
    if element then
        element:Activate();
    end
end

local function GetHidden()
    if (gSettings.HideWhileZoning) then
        if (player:GetLoggedIn() == false) then
            return true;
        end
    end

    if (gSettings.HideWhileCutscene) then
        if (GetEventSystemActive()) then
            return true;
        end
    end

    if (gSettings.HideWhileMap) then
        if (string.match(GetMenuName(), 'map')) then
            return true;
        end
    end

    if (GetInterfaceHidden()) then
        return true;
    end
    
    return false;
end

local d3dwhite = d3d8.D3DCOLOR_ARGB(255, 255, 255, 255);
local vec_position = ffi.new('D3DXVECTOR2', { 0, 0, });
function SingleDisplay:Render(macroState)
    if GetHidden() or (self.Sprite == nil) or (macroState == 0) then
        return;
    end

    local pos = gSettings.Position[gSettings.Layout].SingleDisplay;
    local sprite = self.Sprite;
    sprite:Begin();

    for _,object in ipairs(self.Layout.FixedObjects) do
        local component = self.Layout.Textures[object.Texture];
        vec_position.x = pos[1] + object.OffsetX;
        vec_position.y = pos[2] + object.OffsetY;
        sprite:Draw(object.Texture, object.Rect, object.Scale, nil, 0.0, vec_position, d3dwhite);
    end

    local group = self.ElementGroups[macroState];
    if group then
        for _,element in ipairs(group) do
            element:Render(sprite);
        end
    end
    sprite:End();
end

function SingleDisplay:HitTest(x, y)
    local pos = gSettings.Position[gSettings.Layout].SingleDisplay;
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
    for macroState,group in ipairs(self.ElementGroups) do
        for macroIndex,element in ipairs(group) do
            element:UpdateBinding(bindings[GetButtonAlias(macroState, macroIndex)]);
        end
    end
end

return SingleDisplay;