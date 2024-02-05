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
    self.State.Cost = -1;
    self.State.Ready = true;
    self.State.Recast = -1;
    self.State.Skillchain = nil;
end

return Updater;