local square    = require('square');
local primitives = require('primitives');
local structOffset = 12;
local structWidth = 1156;

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

local SquareManager = {};
SquareManager.Squares = T{};

function SquareManager:Initialize(layout, singleStruct, doubleStruct)
    self.SingleStruct = ffi.cast('AbilitySquarePanelState_t*', singleStruct);
    self.DoubleStruct = ffi.cast('AbilitySquarePanelState_t*', doubleStruct);
    self.Layout = layout;
    self.Hidden = false;

    self.SinglePrimitives = T{};
    for _,primitiveInfo in ipairs(layout.SingleDisplay.Primitives) do
        local prim = {
            Object = primitives.new(primitiveInfo),
            OffsetX = primitiveInfo.OffsetX,
            OffsetY = primitiveInfo.OffsetY,
        };
        self.SinglePrimitives:append(prim);
    end

    self.DoublePrimitives = T{};
    for _,primitiveInfo in ipairs(layout.DoubleDisplay.Primitives) do
        local prim = {
            Object = primitives.new(primitiveInfo),
            OffsetX = primitiveInfo.OffsetX,
            OffsetY = primitiveInfo.OffsetY,
        };
        self.DoublePrimitives:append(prim);
    end

    self.Squares = T{
        [1] = {},
        [2] = {},
    };


    local count = 0;
    self.DefaultSquares = T{};
    for _,squareInfo in ipairs(layout.DoubleDisplay.Squares) do
        local buttonIndex = (count < 8) and (count + 1) or (count - 7);
        local tableIndex = (count < 8) and 1 or 2;
        
        local singlePointer = ffi.cast('AbilitySquareState_t*', singleStruct + structOffset + (structWidth * (buttonIndex - 1)));
        local doublePointer = ffi.cast('AbilitySquareState_t*', doubleStruct + structOffset + (structWidth * count));

        local newSquare = square:New(doublePointer, GetButtonAlias(tableIndex, buttonIndex));
        newSquare.SinglePointer = singlePointer;
        newSquare.DoublePointer = doublePointer;

        count = count + 1;
        newSquare.MinX = squareInfo.OffsetX + layout.DoubleDisplay.ImageObjects.Frame.OffsetX;
        newSquare.MaxX = newSquare.MinX + layout.DoubleDisplay.ImageObjects.Frame.Width;
        newSquare.MinY = squareInfo.OffsetY + layout.DoubleDisplay.ImageObjects.Frame.OffsetY;
        newSquare.MaxY = newSquare.MinY + layout.DoubleDisplay.ImageObjects.Frame.Height;
        self.Squares[tableIndex][buttonIndex] = newSquare;
    end
    for i = 3,6 do
        self.Squares[i] = T{};
        count = 0;
        for _,squareInfo in ipairs(layout.SingleDisplay.Squares) do
            local buttonIndex = count + 1;
            local singlePointer = ffi.cast('AbilitySquareState_t*', singleStruct + structOffset + (structWidth * count));
            local newSquare = square:New(singlePointer, GetButtonAlias(i, buttonIndex));
            newSquare.MinX = squareInfo.OffsetX + layout.SingleDisplay.ImageObjects.Frame.OffsetX;
            newSquare.MaxX = newSquare.MinX + layout.SingleDisplay.ImageObjects.Frame.Width;
            newSquare.MinY = squareInfo.OffsetY + layout.SingleDisplay.ImageObjects.Frame.OffsetY;
            newSquare.MaxY = newSquare.MinY + layout.SingleDisplay.ImageObjects.Frame.Height;
            self.Squares[i][buttonIndex] = newSquare;
            count = count + 1;
        end
    end
end

function SquareManager:GetSquareByButton(macroState, macroIndex)
    local squareSet = self.Squares[macroState];
    if (squareSet ~= nil) then
        local square = squareSet[macroIndex];
        if (square ~= nil) then
            return square;
        end
    end
end

function SquareManager:Activate(macroState, button)
    local square = self:GetSquareByButton(macroState, button);
    if square then
        square:Activate();
    end
end

function SquareManager:Destroy()
    for _,squareSet in ipairs(self.Squares) do
        for _,square in ipairs(squareSet) do
            square:Destroy();
        end
    end
    
    if (type(self.SinglePrimitives) == 'table') then
        for _,primitive in ipairs(self.SinglePrimitives) do
            primitive.Object:destroy();
        end
        self.SinglePrimitives = nil;
    end
    if (type(self.DoublePrimitives) == 'table') then
        for _,primitive in ipairs(self.DoublePrimitives) do
            primitive.Object:destroy();
        end
        self.DoublePrimitives = nil;
    end

    self.SingleStruct = nil;
    self.DoubleStruct = nil;
end

function SquareManager:GetHidden()
    if (self.SingleStruct == nil) or (self.DoubleStruct == nil) then
        return true;
    end

    if (gSettings.HideWithoutCombo) then
        if (gController:GetMacroState() == 0) then
            return true
        end
    end

    if (gSettings.HideWhileZoning) then
        if (gPlayer:GetLoggedIn() == false) then
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

function SquareManager:HidePrimitives(primitives)
    for _,primitive in ipairs(primitives) do
        primitive.Object.visible = false;
    end
end

function SquareManager:HitTest(x, y)
    local pos, width, height, type;
    if (self.DoubleDisplay == true) then
        pos = gSettings.Position[gSettings.Layout].DoubleDisplay;
        width = self.Layout.DoubleDisplay.PanelWidth;
        height = self.Layout.DoubleDisplay.PanelHeight;
        type = 'DoubleDisplay';
    elseif (self.SingleDisplay == true) then
        pos = gSettings.Position[gSettings.Layout].SingleDisplay;
        width = self.Layout.SingleDisplay.PanelWidth;
        height = self.Layout.SingleDisplay.PanelHeight;
        type = 'SingleDisplay';
    end

    if (pos ~= nil) then
        if (x >= pos[1]) and (y >= pos[2]) then
            local offsetX = x - pos[1];
            local offsetY = y - pos[2];
            if (offsetX < width) and (offsetY < height) then
                return true, type;
            end
        end
    end
    
    return false;
end

function SquareManager:Tick()
    self.SingleDisplay = false;
    self.DoubleDisplay = false;

    if (self.SingleStruct == nil) or (self.DoubleStruct == nil) or (self:GetHidden()) then
        self:HidePrimitives(self.SinglePrimitives);
        self:HidePrimitives(self.DoublePrimitives);
        return;
    end


    local macroState = gController:GetMacroState();
    if (gBindingGUI:GetActive()) then
        macroState = gBindingGUI:GetMacroState();
    end

    if (macroState == 0) then
        if (gSettings.ShowDoubleDisplay) then
            self.DoubleDisplay = true;
        end
    elseif (macroState < 3) and (gSettings.ShowDoubleDisplay) and (gSettings.SwapToSingleDisplay == false) then
        self.DoubleDisplay = true;
    else
        self.SingleDisplay = true;
    end

    if (self.SingleDisplay) then
        for _,squareClass in ipairs(self.Squares[macroState]) do
            if (macroState < 3) then
                squareClass.StructPointer = squareClass.SinglePointer;
                squareClass.Updater.StructPointer = squareClass.SinglePointer;
            end
            squareClass:Update();
        end
        local pos = gSettings.Position[gSettings.Layout].SingleDisplay;
        self.SingleStruct.PositionX = pos[1];
        self.SingleStruct.PositionY = pos[2];
        self.SingleStruct.Render = 1;
        self:HidePrimitives(self.DoublePrimitives);
        self:UpdatePrimitives(self.SinglePrimitives, pos);
    elseif (self.DoubleDisplay) then
        for _,tableIndex in ipairs(T{1, 2}) do
            for _,squareClass in ipairs(self.Squares[tableIndex]) do
                squareClass.StructPointer = squareClass.DoublePointer;
                squareClass.Updater.StructPointer = squareClass.DoublePointer;
                squareClass:Update();
            end
        end
        local pos = gSettings.Position[gSettings.Layout].DoubleDisplay;
        self.DoubleStruct.PositionX = pos[1];
        self.DoubleStruct.PositionY = pos[2];
        self.DoubleStruct.Render = 1;
        self:HidePrimitives(self.SinglePrimitives);
        self:UpdatePrimitives(self.DoublePrimitives, pos);
    else
        self:HidePrimitives(self.SinglePrimitives);
        self:HidePrimitives(self.DoublePrimitives);
    end
end

function SquareManager:UpdateBindings(bindings)
    for comboKey,squareSet in ipairs(self.Squares) do
        for buttonKey,square in ipairs(squareSet) do
            square:UpdateBinding(bindings[GetButtonAlias(comboKey, buttonKey)]);
        end
    end
end

function SquareManager:UpdatePrimitives(primitives, position)
    for _,primitive in ipairs(primitives) do
        primitive.Object.position_x = position[1] + primitive.OffsetX;
        primitive.Object.position_y = position[2] + primitive.OffsetY;
        primitive.Object.visible = true;
    end
end

return SquareManager;