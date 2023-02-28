local updaters     = {
    ['Ability']     = require('updaters.ability'),
    ['Command']     = require('updaters.command'),
    ['Empty']       = require('updaters.empty'),
    ['Item']        = require('updaters.item'),
    ['Spell']       = require('updaters.spell'),
    ['Trust']       = require('updaters.trust'),
    ['Weaponskill'] = require('updaters.weaponskill'),
};

local function DoMacro(macro)
    for _,line in ipairs(macro) do
        if (string.sub(line, 1, 6) == '/wait ') then
            local waitTime = tonumber(string.sub(line, 7));
            if type(waitTime) == 'number' then
                if (waitTime < 0.1) then
                    coroutine.sleepf(1);
                else
                    coroutine.sleep(waitTime);
                end
            end
        else
            AshitaCore:GetChatManager():QueueCommand(-1, line);
        end
    end
end

local Square = {};

function Square:New(structPointer, hotkey)
    local o = {};
    setmetatable(o, self);
    self.__index = self;
    o.StructPointer = structPointer;
    local updater = updaters.Empty;
    o.Activation = 0;
    o.Hotkey = hotkey;
    o.Updater = updater:New();
    o.Updater:Initialize(o);
    return o;
end

function Square:Activate()
    self.Activation = os.clock() + 0.25;
    if (self.Binding ~= nil) then
        DoMacro:bind1(self.Binding.Macro):oncef(0);
    end
end

function Square:Bind()
    gBindingGUI:Show(self.Hotkey, self.Binding);
end

function Square:Destroy()
    self.Updater:Destroy();
end

function Square:Update()
    self.Updater:Tick();
end

function Square:UpdateBinding(binding)
    if (binding == self.Binding) then
        return;
    end

    if (self.Updater ~= nil) then
        self.Updater:Destroy();
    end

    self.Binding = binding;
    local updater = updaters.Empty;
    if (type(self.Binding) == 'table') and (self.Binding.ActionType ~= nil) then
        local newUpdater = updaters[self.Binding.ActionType];
        if (newUpdater ~= nil) then
            updater = newUpdater;
        end
    end

    self.Updater = updater:New();
    self.Updater:Initialize(self, self.Binding);
end

return Square;