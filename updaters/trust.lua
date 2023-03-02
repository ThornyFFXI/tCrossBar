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

local function RecastToString(timer)
    if (timer == 0) then
        return nil;
    end
    if (timer >= 216000) then
        local h = math.floor(timer / (216000));
        local m = math.floor(math.fmod(timer, 216000) / 3600);
        return string.format('%i:%02i', h, m);
    elseif (timer >= 3600) then
        local m = math.floor(timer / 3600);
        local s = math.floor(math.fmod(timer, 3600) / 60);
        return string.format('%i:%02i', m, s);
    else
        if (timer < 60) then
            return '1';
        else
            return string.format('%i', math.floor(timer / 60));
        end
    end
end

local function GetSpellRecast(resource)
    local timer = AshitaCore:GetMemoryManager():GetRecast():GetSpellTimer(resource.Index);
    return (timer == 0), RecastToString(timer);
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
    self.Resource      = AshitaCore:GetResourceManager():GetSpellById(self.Binding.Id);

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
    --RecastReady will hold number of charges for charged abilities.
    local recastReady, recastDisplay  = GetSpellRecast(self.Resource);
    local spellKnown                  = gPlayer:KnowsSpell(self.Resource.Index)
    local spellCostDisplay, costMet   = self:CostFunction();    

    if (gSettings.ShowHotkey) and (self.Binding.ShowHotkey) then
        self.StructPointer.Hotkey = self.Square.Hotkey;
    else
        self.StructPointer.Hotkey = '';
    end

    self.StructPointer.OverlayImage1 = '';
    
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
        self.StructPointer.Cost = spellCostDisplay;
    else
        self.StructPointer.Cost = '';
    end
    
    if (gSettings.ShowRecast) and (self.Binding.ShowRecast) and (recastDisplay ~= nil) then
        self.StructPointer.Recast = recastDisplay;
    else
        self.StructPointer.Recast = '';
    end

    if (gSettings.ShowCross) and (self.Binding.ShowCross) then
        if spellKnown == false then
            self.StructPointer.OverlayImage2 = self.CrossImage;
        else
            self.StructPointer.OverlayImage2 = '';
        end
    end

    if (gSettings.ShowTrigger) and (self.Binding.ShowTrigger) then
        if (self.Square.Activation > os.clock()) then
            self.StructPointer.OverlayImage3 = self.TriggerImage;
        else
            self.StructPointer.OverlayImage3 = '';
        end
    end
    
    if (gSettings.ShowFade) and (self.Binding.ShowFade) and ((costMet == false) or (recastReady == false)) then
        self.StructPointer.Fade = 1;
    else
        self.StructPointer.Fade = 0;
    end
end

return Updater;