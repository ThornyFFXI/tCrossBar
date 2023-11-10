--[[
* Addons - Copyright (c) 2021 Ashita Development Team
* Contact: https://www.ashitaxi.com/
* Contact: https://discord.gg/Ashita
*
* This file is part of Ashita.
*
* Ashita is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* Ashita is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with Ashita.  If not, see <https://www.gnu.org/licenses/>.
--]]

addon.name      = 'tCrossBar';
addon.author    = 'Thorny';
addon.version   = '1.09';
addon.desc      = 'Creates a controller scheme for activating macros, and provides visual aids for your macroed abilities.';
addon.link      = 'https://ashitaxi.com/';

require('common');
local gdi        = require('gdifonts.include');
gInitializer     = require('initializer');
local clickTarget;

function Error(text)
    local color = ('\30%c'):format(68);
    local highlighted = color .. string.gsub(text, '$H', '\30\01\30\02');
    highlighted = string.gsub(highlighted, '$R', '\30\01' .. color);
    print(chat.header(addon.name) .. highlighted .. '\30\01');
end


function Message(text)
    local color = ('\30%c'):format(106);
    local highlighted = color .. string.gsub(text, '$H', '\30\01\30\02');
    highlighted = string.gsub(highlighted, '$R', '\30\01' .. color);
    print(chat.header(addon.name) .. highlighted .. '\30\01');
end

ashita.events.register('load', 'load_cb', function ()
    gdi:set_auto_render(false);
    require('initialize');
end);

--[[
* event: unload
* desc : Event called when the addon is being unloaded.
--]]
ashita.events.register('unload', 'unload_cb', function ()
    gdi:destroy_interface();
end);

ashita.events.register('command', 'command_cb', function (e)
    local args = e.command:args();
    if (#args == 0 or string.lower(args[1]) ~= '/tc') then
        return;
    end
    e.blocked = true;

    if (#args == 1) then
        gConfigGUI:Show();
        return;
    end

    if (#args > 1) and (string.lower(args[2]) == 'activate') then
        if (#args > 2) then
            local macroIndex = tonumber(args[3]);
            gInterface:GetSquareManager():Activate(macroIndex);
        end
        return;
    end
    
    if (#args > 1) and (string.lower(args[2]) == 'palette') then
        gBindings:HandleCommand(args);
        return;
    end
end);

ashita.events.register('d3d_present', 'd3d_present_cb', function ()
    gController:Tick();
    
    --Returns a display type if in drag mode.
    local renderTarget = gConfigGUI:Render();

    --Returns a macro type if in binding mode.
    local macroState   = gBindingGUI:Render();

    if (renderTarget == nil) then
        renderTarget = gSingleDisplay;
        macroState = macroState or gController:GetMacroState();
        if (macroState == 0) then
            if (gSettings.ShowDoubleDisplay) then
                renderTarget = gDoubleDisplay;
            end
        elseif (macroState < 3) then
            if (gSettings.SwapToSingleDisplay == false) then
                renderTarget = gDoubleDisplay;
            end
        end
        clickTarget = renderTarget;
    else
        clickTarget = nil;
    end

    renderTarget:Render();
end);

ashita.events.register('mouse', 'mouse_cb', function (e)
    if gConfigGUI:HandleMouse(e) then
        return;
    end

    clickTarget:HandleMouse(e);
end);