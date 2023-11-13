local renderTarget;
local player = require('state.player');
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
        if (string.match(GetMenuName(), 'map')) then
            return true;
        end
    end

    if (GetInterfaceHidden()) then
        return true;
    end
    
    return false;
end

ashita.events.register('d3d_present', 'd3d_present_cb', function ()
    gController:Tick();    
    gConfigGUI:Render();
    gBindingGUI:Render();

    renderTarget = nil;
    if (gConfigGUI.ForceDisplay) then
        gConfigGUI.ForceDisplay:Render(1);
        return;
    end

    if (gBindingGUI.ForceDisplay) then
        gBindingGUI.ForceDisplay:Render(gBindingGUI.ForceState);
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
        if (gSettings.SwapToSingleDisplay == false) then
            renderTarget = gDoubleDisplay;
        end
    end

    if renderTarget then
        renderTarget:Render(macroState);
    end
end);

ashita.events.register('mouse', 'mouse_cb', function (e)
    if gConfigGUI:HandleMouse(e) then
        return;
    end

    if (renderTarget ~= nil) and (gSettings.ClickToActivate) then
        renderTarget:HandleMouse(e);
    end
end);