local player = require('state.player');
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

    return itemCount, (itemCount > 0);
end

local function GetSpellRecast(resource)
    local timer = AshitaCore:GetMemoryManager():GetRecast():GetSpellTimer(resource.Index);
    if (timer == 0) then
        return true, -1;
    else
        return false, timer / 60;
    end
end

function Updater:New()
    local o = {};
    setmetatable(o, self);
    self.__index = self;
    return o;
end

function Updater:Initialize(element, binding)
    self.State    = element.State;
    self.Resource = AshitaCore:GetResourceManager():GetSpellById(binding.Id);
    
    if (binding.CostOverride) then
        self.CostFunction = ItemCost:bind2(binding.CostOverride);
    else
        self.CostFunction = function()
            return -1, true;
        end
    end
end

function Updater:Destroy()

end

function Updater:Tick()
    --RecastReady will hold number of charges for charged abilities.
    local recastReady, recastDisplay  = GetSpellRecast(self.Resource);
    local spellKnown                  = player:HasSpell(self.Resource)
    local spellCostDisplay, costMet   = self:CostFunction();

    self.State.Available = spellKnown;
    self.State.Cost = spellCostDisplay;
    self.State.Ready = ((costMet == true) and (recastReady == true));
    self.State.Recast = recastDisplay;
    self.State.Skillchain = nil;
end

return Updater;