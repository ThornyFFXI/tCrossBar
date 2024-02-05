local encoding = require('gdifonts.encoding');
local updaters = {
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
            AshitaCore:GetChatManager():QueueCommand(-1, encoding:UTF8_To_ShiftJIS(command));
        end
        
        if type(waitTime) == 'number' then
            if (waitTime < 0.1) then
                coroutine.sleepf(1);
            else
                coroutine.sleep(waitTime);
            end
        end
    end
end

local Element = {};

function Element:New(hotkey)
    local o = {};
    setmetatable(o, self);
    self.__index = self;
    o.State = {
        Available = false,
        Ready = false,
        Cost = -1,
        Hotkey = hotkey,
        Name = '',
        Recast = -1,
        Skillchain = nil,
    };
    local updater = updaters.Empty;
    o.Activation = 0;
    o.Updater = updater:New();
    o.Updater:Initialize(o);
    return o;
end

function Element:Activate()
    self.Activation = os.clock();
    if (self.Binding ~= nil) then
        local macroContainer = T{};
        for _,entry in ipairs(self.Binding.Macro) do
            macroContainer:append(entry);
        end
        DoMacro:bind1(macroContainer):oncef(0);
    end
end

function Element:Bind()
    gBindingGUI:Show(self.Hotkey, self.Binding);
end

function Element:Destroy()
    self.Updater:Destroy();
end

function Element:HitTest(x, y)
    local hitbox = self.HitBox;
    if (hitbox == nil) then
        return false;
    end

    if (x < hitbox.X) or (x < hitbox.Y) then
        return false;
    end
    if (x > (hitbox.X + hitbox.Width)) then
        return false;
    end
    return (y < (hitbox.Y + hitbox.Height));
end

function Element:Tick()
    self.Updater:Tick();
    self.State.Activated = ((self.Activation + gSettings.TriggerDuration) > os.clock());
end

function Element:UpdateBinding(binding)
    if (self.Updater ~= nil) then
        self.Updater:Destroy();
    end

    self.Binding = binding;
    local updater = updaters.Empty;
    self.State.Name = '';
    if (type(self.Binding) == 'table') then
        if (self.Binding.ActionType ~= nil) then
            local newUpdater = updaters[self.Binding.ActionType];
            if (newUpdater ~= nil) then
                updater = newUpdater;
            end
        end
        if (type(self.Binding.Label) == 'string') then
            self.State.Name = self.Binding.Label;
        end
    end

    self.Updater = updater:New();
    self.Updater:Initialize(self, self.Binding);

    if (self.Binding) then
        self.Texture = gTextureCache:GetTexture(self.Binding.Image);
    else
        self.Texture = nil;
    end
end

return Element;