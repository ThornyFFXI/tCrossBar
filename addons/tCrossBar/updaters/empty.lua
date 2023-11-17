local Updater = {};

function Updater:New()
    local o = {};
    setmetatable(o, self);
    self.__index = self;
    return o;
end

function Updater:Initialize(element, binding)
    self.State = element.State;
end

function Updater:Destroy()

end

function Updater:Tick()
    self.State.Available = true;
    self.State.Cost = '';
    self.State.Ready = true;
    self.State.Recast = '';
    self.State.Skillchain = nil;
end

return Updater;