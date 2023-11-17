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

    if (#args > 1) and (string.lower(args[2]) == 'palette') then
        gBindings:HandleCommand(args);
        return;
    end
end);