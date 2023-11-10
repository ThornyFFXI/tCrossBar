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
local gdi = require('gdifonts.include');

ashita.events.register('load', 'load_cb', function ()
    gdi:set_auto_render(false);
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

    gBindingGUI:Render();
    
    gConfigGUI:Render();
    
    if (gInterface ~= nil) then
        gInterface:Tick();
    end
end);