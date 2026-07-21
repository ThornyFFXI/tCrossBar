local encoding = require('gdifonts.encoding');

local macros = {};
macros.Pending = T{};

local DoMacro;

-- Set up domacro function..
do
    local subTargetTypes = T{
        ["<st>"] = { Mode=3, Flags=799 },
        ["<stpc>"] = { Mode=4, Flags=525 },
        ["<stnpc>"] = { Mode=5, Flags=18 },
        ["<stpt>"] = { Mode=6 },
        ["<stal>"] = { Mode=7 },
    }

    local function GetStPartyIndex()
        local ptr = AshitaCore:GetPointerManager():Get('party');
        ptr = ashita.memory.read_uint32(ptr);
        ptr = ashita.memory.read_uint32(ptr);
        local isActive = (ashita.memory.read_uint32(ptr + 0x54) ~= 0);
        if isActive then
            return ashita.memory.read_uint8(ptr + 0x50);
        else
            return nil;
        end
    end

    local function IsSubTargetActive(type)
        if type.Flags == nil then
            return (GetStPartyIndex() ~= nil);
        end

        local targetMgr = AshitaCore:GetMemoryManager():GetTarget();
        return (targetMgr:GetSubTargetFlags() == type.Flags);
    end

    -- Handle waiting for a <st> command to resolve..
    local function WaitForSubtarget(type)
        local timeout = os.clock() + 3

        -- Wait for subtarget to be active..
        while (not IsSubTargetActive(type)) do
            if (os.clock() > timeout) then
                return;
            end
            coroutine.sleepf(1);
        end

        -- Wait until no longer active..
        while (IsSubTargetActive(type)) do
            coroutine.sleepf(1);
        end
        
        -- Wait one extra frame to avoid race conditions..
        coroutine.sleepf(1);
    end

    -- Execution coroutine for a single macro(macro)
    DoMacro = function(macro)
        for index,line in ipairs(macro.Contents) do
            local command, waitTime;
            if (string.sub(line, 1, 6) == '/wait ') then
                waitTime = tonumber(string.sub(line, 7));
            else
                command = line;
                local waitStart, waitEnd = string.find(line, ' <wait %d*%.?%d+>');
                if (waitStart ~= nil) and (waitEnd == string.len(line)) then
                    waitTime = tonumber(string.match(line, ' <wait (%d*%.?%d+)>'));
                    if (type(waitTime) == 'number') then
                        command = string.sub(line, 1, waitStart - 1);
                    end
                end
            end


            if command then
                -- Sub in <lastst> if present..
                if macro.LastST then
                    command = command:gsub("<lastst>", macro.LastST);
                end

                -- Send command..
                AshitaCore:GetChatManager():QueueCommand(-1, encoding:UTF8_To_ShiftJIS(command));

                if index ~= #macro.Contents then
                    -- Attempt to resolve subtarget type..
                    for subTargetType,value in pairs(subTargetTypes) do
                        if string.find(command, subTargetType, 1, true) then
                            macro.PendingSubTarget = value.Mode;
                            macro.LastST = nil;
                            WaitForSubtarget(value);
                        end
                    end
                end
            end
            
            if index ~= #macro.Contents then
                if type(waitTime) == 'number' then
                    if (waitTime < 0.1) then
                        coroutine.sleepf(1);
                    else
                        coroutine.sleep(waitTime);
                    end
                end
            end
        end
        macro.Completed = true;
    end
end

-- Cancel all pending macros
function macros:Abort()
    local killed = false;
    for _,activeMacro in ipairs(self.Pending) do
        if activeMacro.Completed ~= true then
            activeMacro.Coroutine:kill();
            killed = true;
        end
    end
    self.Pending = T{};
    return killed;
end

-- Take a table of commands and begin macro execution
function macros:Execute(macro)
    if gSettings.MacroInterrupt == true then
        -- Clear all existing macros if interrupt mode is on..
        self:Abort();
    else
        -- Remove entries that have completed..
        self.Pending = self.Pending:filteri(function(macro) return macro.Completed ~= true end);
    end
    
    local newMacro = {};
    newMacro.Contents = T(macro):copy(true);
    newMacro.Coroutine = ashita.tasks.once(DoMacro:bind1(newMacro));
    self.Pending:append(newMacro);
end

-- Track commands to observe lastst selections..
ashita.events.register('command', 'st_monitoring', function (e)
    for _,macro in ipairs(macros.Pending) do
        if (e.mode == macro.PendingSubTarget) then
            -- Matches trailing numbers.. will nil the value if no match, which is fine.
            macro.LastST = e.command:match("(%d+)%s*$");
        end
    end
end);

return macros;