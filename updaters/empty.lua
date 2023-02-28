local Updater = {};

function Updater:New()
    local o = {};
    setmetatable(o, self);
    self.__index = self;
    return o;
end

function Updater:Initialize(square, binding)
    self.Binding       = binding;
    self.Square        = square;
    self.StructPointer = square.StructPointer;

end

function Updater:Destroy()

end

function Updater:Tick()
    if (gSettings.ShowHotkey) then
        self.StructPointer.Hotkey = self.Square.Hotkey;
    else
        self.StructPointer.Hotkey = '';
    end

    self.StructPointer.Fade = 0;
    self.StructPointer.Cost = '';
    self.StructPointer.Name = '';
    self.StructPointer.Recast = '';
    self.StructPointer.OverlayImage1 = '';
    self.StructPointer.OverlayImage2 = '';
    self.StructPointer.OverlayImage3 = '';
    self.StructPointer.IconImage = '';
end

return Updater;