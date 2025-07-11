local renderTarget;
local player = require('state.player');
local pGameMenu = ashita.memory.find('FFXiMain.dll', 0, "8B480C85C974??8B510885D274??3B05", 16, 0);
local pEventSystem = ashita.memory.find('FFXiMain.dll', 0, "A0????????84C0741AA1????????85C0741166A1????????663B05????????0F94C0C3", 0, 0);
local pInterfaceHidden = ashita.memory.find('FFXiMain.dll', 0, "8B4424046A016A0050B9????????E8????????F6D81BC040C3", 0, 0);
local pChatExpanded = ashita.memory.find('FFXiMain.dll', 0, '83EC??B9????????E8????????0FBF4C24??84C0', 0x04, 0);

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

--Credit: Loonsie / 
local function GetChatExpanded()
    local ptr = ashita.memory.read_uint32(pChatExpanded);
    if (ptr == 0) then
        return false;
    end

    return (ashita.memory.read_uint8(ptr + 0xF1) ~= 0);
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

local altMaps = T{
    ['menu    cnqframe'] = true,
    ['menu    scanlist'] = true,
};
local function ShouldHide()
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
        local activeMenu = GetMenuName();
        if (string.sub(activeMenu, 1, 11) == 'menu    map') or (altMaps[activeMenu]) then
            return true;
        end
    end
    
    if (gSettings.HideWhileChat) then
        if (GetChatExpanded()) then
            return true;
        end
    end

    if (GetInterfaceHidden()) then
        return true;
    end
    
    return false;
end

ashita.events.register('d3d_present', 'd3d_present_cb', function ()
    player:UpdateBLUSpells();
    gController:Tick();    
    gConfigGUI:Render();
    gBindingGUI:Render();

    renderTarget = nil;
    if (gConfigGUI.ForceDisplay) then
        gConfigGUI.ForceDisplay:Render(1);
        renderTarget = gConfigGUI.ForceDisplay;
        return;
    end

    if (gBindingGUI.ForceDisplay) then
        gBindingGUI.ForceDisplay:Render(gBindingGUI.ForceState);
        renderTarget = gBindingGUI.ForceDisplay;
        return;
    end

    if (ShouldHide()) then
        return;
    end
    
    renderTarget = gSingleDisplay;
    local macroState = gController:GetMacroState();
    if (macroState == 0) then
        if (gSettings.ShowDoubleDisplay) then
            renderTarget = gDoubleDisplay;
        end
    elseif (macroState < 3) then
        if (gSettings.LTRTMode == 'FullDouble') then
            renderTarget = gDoubleDisplay;
        elseif (gSettings.LTRTMode == 'HalfDouble') then
            gDoubleDisplay:Render(macroState, true);
            return;
        end
    end

    renderTarget:Render(macroState);
end);

local mouseDown;
ashita.events.register('mouse', 'mouse_cb', function (e)
    if (renderTarget ~= nil) then
        renderTarget:HandleMouse(e);
    end

    if (e.message == 513) then
        if (e.blocked == true) then
            mouseDown = true;
        end
    end

    if (e.message == 514) then
        if mouseDown then
            e.blocked = true;
            mouseDown = false;
        end
    end
end);