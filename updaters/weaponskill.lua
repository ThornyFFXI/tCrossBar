local Updater = {};

local inventory    = require('state.inventory');
local player       = require('state.player');
local skillchain   = require('state.skillchain');

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
        local itemData = inventory:GetItemData(item);
        if (itemData ~= nil) then
            for _,itemEntry in ipairs(itemData.Locations) do
                if (updater.Containers:contains(itemEntry.Container)) then
                    itemCount = itemCount + inventory:GetItemTable(itemEntry.Container, itemEntry.Index).Count;
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

function Updater:Initialize(element, binding)
    self.State    = element.State;
    self.Resource = AshitaCore:GetResourceManager():GetAbilityById(binding.Id);

    --Custom
    if (binding.CostOverride) then
        self.CostFunction = ItemCost:bind2(binding.CostOverride);
    else
        self.CostFunction = function()
            return '', true;
        end
    end
end

function Updater:Destroy()

end

function Updater:Tick()
    local known = player:KnowsAbility(self.Resource.Id);
    
    self.State.Available = known;
    self.State.Cost = self:CostFunction();
    self.State.Ready = (AshitaCore:GetMemoryManager():GetParty():GetMemberTP(0) >= 1000);
    self.State.Recast = '';
    self.State.Skillchain = self:UpdateSkillchain();
end

function Updater:UpdateSkillchain()
    local targetMgr = AshitaCore:GetMemoryManager():GetTarget();
    local target = targetMgr:GetTargetIndex(targetMgr:GetIsSubTargetActive());

    --Skip if no target..
    if (target == 0) then
        return;
    end

    --Skip if target is a player..
    if (target >= 0x400) and (target < 0x700) then
        return;
    end

    --Skip if target is a pet..
    if (target >= 0x700) and (AshitaCore:GetMemoryManager():GetEntity():GetTrustOwnerTargetIndex(target) ~= 0) then
        return;
    end

    local resonation, result = skillchain:GetSkillchain(target, self.Resource.Id);
    if (resonation == nil) or (resonation.WindowClose < os.clock()) then
        return;
    end

    return { Name=result, Open=(os.clock() > resonation.WindowOpen) };
end

return Updater;