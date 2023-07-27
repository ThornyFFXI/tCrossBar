local Updater = {};

local function ItemCost(updater, items)
    local containers = updater.Containers;
    if (updater.Containers == nil) then
        containers = T{ 0 };
        local useTemporary = false;
        local useWardrobes = false;
        for _,itemId in ipairs(items) do
            local resource = AshitaCore:GetResourceManager():GetItemById(itemId);
            if (bit.band(resource.Flags, 0x800) ~= 0) then
                useWardrobes = true;
            else
                useTemporary = true;
            end
        end
        if (useWardrobes) then
            containers = T { 0, 8, 10, 11, 12, 13, 14, 15, 16 };
        end
        if (useTemporary) then
            containers:append(3);
        end
        updater.Containers = containers;
    end

    local itemCount = 0;
    for _,item in ipairs(items) do
        local itemData = gInventory:GetItemData(item);
        if (itemData ~= nil) then
            for _,itemEntry in ipairs(itemData.Locations) do
                if (updater.Containers:contains(itemEntry.Container)) then
                    itemCount = itemCount + gInventory:GetItemTable(itemEntry.Container, itemEntry.Index).Count;
                end
            end
        end
    end

    return tostring(itemCount), (itemCount > 0);
end

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

    local layout = gInterface:GetSquareManager().Layout;
    self.IconImage = GetImagePath(self.Binding.Image);
    self.CrossImage = layout.CrossPath;
    self.TriggerImage = layout.TriggerPath;
    
    --Custom
    if (self.Binding.CostOverride) then
        self.CostFunction = ItemCost:bind2(self.Binding.CostOverride);
    else
        self.CostFunction = function()
            return '', true;
        end
    end
end

function Updater:Destroy()

end

function Updater:Tick()
    if (gSettings.ShowHotkey) and (self.Binding.ShowHotkey) then
        self.StructPointer.Hotkey = self.Square.Hotkey;
    else
        self.StructPointer.Hotkey = '';
    end

    self.StructPointer.Recast = '';
    self.StructPointer.OverlayImage1 = '';
    self.StructPointer.OverlayImage2 = '';
    self.StructPointer.Fade = 0;
    self.StructPointer.Recast = '';
    
    if (self.IconImage == nil) then
        self.StructPointer.IconImage = '';
    else
        self.StructPointer.IconImage = self.IconImage;
    end

    if (gSettings.ShowName) and (self.Binding.ShowName) then
        self.StructPointer.Name = self.Binding.Label;
    else
        self.StructPointer.Name = '';
    end

    if (gSettings.ShowCost) and (self.Binding.ShowCost) then
        self.StructPointer.Cost = self:CostFunction();
    end

    if (gSettings.ShowTrigger) and (self.Binding.ShowTrigger) then
        if (self.Square.Activation > os.clock()) then
            self.StructPointer.OverlayImage3 = self.TriggerImage;
        else
            self.StructPointer.OverlayImage3 = '';
        end
    end
end

return Updater;