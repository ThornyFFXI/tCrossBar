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

    if (#args > 1) and (string.lower(args[2]) == 'bindmode') then        
        if (gBindingGUI:GetActive()) then
            gBindingGUI:Close();
            gController.BindMenuState.Active = false;
        elseif (not gController.BindMenuState.Active) then
            if (gSingleDisplay) then
                gController.BindMenuState.Active = true;
            else
                Error('Cannot open bind menu without a valid single display.  Please enter "/tc" to open the menu and select a valid layout.')
            end            
        else
            gController.BindMenuState.Active = false;
        end
    end

    if (#args > 1) and (string.lower(args[2]) == 'palette') then
        gBindings:HandleCommand(args);
        return;
    end
end);