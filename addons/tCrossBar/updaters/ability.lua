local Updater = {};

local inventory            = require('state.inventory');
local player               = require('state.player');
local AbilityRecastPointer = ashita.memory.find('FFXiMain.dll', 0, '894124E9????????8B46??6A006A00508BCEE8', 0x19, 0);
AbilityRecastPointer       = ashita.memory.read_uint32(AbilityRecastPointer);

local function GetAbilityTimerData(id)
    for i = 1,31 do
        local compId = ashita.memory.read_uint8(AbilityRecastPointer + (i * 8) + 3);
        if (compId == id) then
            return {
                Modifier = ashita.memory.read_int16(AbilityRecastPointer + (i * 8) + 4);
                Recast = ashita.memory.read_uint32(AbilityRecastPointer + (i * 4) + 0xF8);
            };
        end
    end
    
    return {
        Modifier = 0,
        Recast = 0
    };
end

local function GetMaxStratagems()
    -- Determine the players SCH level..
    local player = AshitaCore:GetMemoryManager():GetPlayer();
    local lvl = player:GetMainJobLevel();
    if (player:GetMainJob() ~= 20) then
        if (player:GetSubJob() == 20) then
            lvl = player:GetSubJobLevel();
        else
            return 0;
        end
    end

    -- Calculate max number of stratagems..
    return math.floor((lvl - 10) / 20) + 1;
end

local function GetRecastTimer(timerId)
    local mmRecast  = AshitaCore:GetMemoryManager():GetRecast();

    if (timerId == 0) then
        return mmRecast:GetAbilityTimer(0);
    end

    for x = 1, 31 do
        local id = mmRecast:GetAbilityTimerId(x);
        local timer = mmRecast:GetAbilityTimer(x);

        if (id == timerId) then
            return timer;
        end
    end

    return 0;
end
--[[
    Cost functions return a number to display, and a bool for whether it's met.  -1 indicates hidden.
    Recast functions return 
]]--

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

    return itemCount, (itemCount > 0);
end

local function ChargeCost(updater, recastReady)
    return recastReady, (recastReady > 0);
end

local function FinishingMoveCost(updater, minimumMoves)
    local finishingMoves = 0;

    local player = AshitaCore:GetMemoryManager():GetPlayer()
    local buffs = player:GetBuffs();
    local moveMap = {
        [381] = 1,
        [382] = 2,
        [383] = 3,
        [384] = 4,
        [385] = 5,
        [588] = 6
    };
    for i=1,32 do
        local count = moveMap[buffs[i]];
        if count ~= nil then
            finishingMoves = count;
        end
    end

    return finishingMoves, (finishingMoves >= minimumMoves);
end

local function RuneEnchantmentCost(updater)
    local runeCount = 0;

    local player = AshitaCore:GetMemoryManager():GetPlayer()
    local buffs = player:GetBuffs();
    for i=1,32 do
        local buff = buffs[i];
        if (buff > 522) and (buff < 531) then
            runeCount = runeCount + 1;
        end
    end

    return runeCount, (runeCount > 0);
end


--This call returns two values.
--First value is true/false for whether ability can be used based on current recast, to be used for dimming icons.
--Second value is time until recast is ready.
local function GetRecastData(resource)
    local timer = GetRecastTimer(resource.RecastTimerId);
    if (timer == 0) then
        return true, -1;
    else
        return false, timer / 60;
    end
end


--Each of these calls returns two values.
--First value is number of charges available.
--Second value is time until next charge (-1 if recast zero)
local function GetStratagemData()
    local maxCount = GetMaxStratagems();
    if (maxCount == 0) then
        return 0, -1;
    end

    local data = GetAbilityTimerData(231);
    if (data.Recast == 0) then
        return maxCount, -1;
    end
    
    local baseRecast = 60 * (240 + data.Modifier);
    local chargeValue = baseRecast / maxCount;
    local remainingCharges = math.floor((baseRecast - data.Recast) / chargeValue);
    local timeUntilNextCharge = math.fmod(data.Recast, chargeValue);
    return remainingCharges, timeUntilNextCharge / 60;
end

local function GetQuickDrawData()
    local data = GetAbilityTimerData(195);
    if (data.Recast == 0) then
        return 2, -1;
    end
    
    local baseRecast = 60 * (120 + data.Modifier);
    local chargeValue = baseRecast / 2;
    local remainingCharges = math.floor((baseRecast - data.Recast) / chargeValue);
    local timeUntilNextCharge = math.fmod(data.Recast, chargeValue);
    return remainingCharges, timeUntilNextCharge / 60;
end

local function GetReadyData()
    local data = GetAbilityTimerData(102);
    if (data.Recast == 0) then
        return 3, -1;
    end

    local baseRecast = 60 * (90 + data.Modifier);
    local chargeValue = baseRecast / 3;
    local remainingCharges = math.floor((baseRecast - data.Recast) / chargeValue);
    local timeUntilNextCharge = math.fmod(data.Recast, chargeValue);
    return remainingCharges, timeUntilNextCharge / 60;
end

function Updater:New()
    local o = {};
    setmetatable(o, self);
    self.__index = self;
    return o;
end

function Updater:Initialize(element, binding)
    self.Resource      = AshitaCore:GetResourceManager():GetAbilityById(binding.Id);
    self.State         = element.State;
    
    --Set cost and recast function for charge-based abilities.
    if (self.Resource.RecastTimerId == 102) then
        self.RecastFunction = GetReadyData;
        self.CostFunction = ChargeCost;
    elseif (self.Resource.RecastTimerId == 195) then
        self.RecastFunction = GetQuickDrawData;
        self.CostFunction = ChargeCost;
    elseif (self.Resource.RecastTimerId == 231) then
        self.RecastFunction = GetStratagemData;
        self.CostFunction = ChargeCost;
    else
        self.RecastFunction = GetRecastData;
        if (self.Resource.ManaCost > 0) then
            self.CostFunction = (function(a)
                return a, (AshitaCore:GetMemoryManager():GetParty():GetMemberMP(0) >= a);
            end):bind1(self.Resource.ManaCost);
        elseif (self.Resource.TPCost < 1) then
            self.CostFunction = function()
                return -1, true;
            end
        else
            self.CostFunction = (function(a)
                return a, (AshitaCore:GetMemoryManager():GetParty():GetMemberTP(0) >= a);
            end):bind1(self.Resource.TPCost);
        end
    end

    --Other cost overrides.
    local flourishes = T{
        [716] = 1,
        [717] = 1,
        [718] = 1,
        [719] = 1,
        [720] = 1,
        [721] = 2,
        [776] = 1,
        [825] = 2,
        [826] = 3
    };
    local flourish = flourishes[binding.Id];

    --Custom (for use with jugs and such)
    if (binding.CostOverride) then
        self.CostFunction = ItemCost:bind2(binding.CostOverride);

    --Angon
    elseif (binding.Id == 682) then
        self.CostFunction = ItemCost:bind2(T{18259});

    --Tomahawk
    elseif (binding.Id == 662) then
        self.CostFunction = ItemCost:bind2(T{18258});

    --Finishing Moves
    elseif flourish ~= nil then
        self.CostFunction = FinishingMoveCost:bind2(flourish);

    --Rune Enchantment
    elseif T{ 856, 878, 880, 881, 883, 884, 885, 887, 888 }:contains(binding.Id) then
        self.CostFunction = RuneEnchantmentCost;
    end
end

function Updater:Destroy()

end

function Updater:Tick()
    --RecastReady will hold number of charges for charged abilities.
    local recastReady, recastDisplay  = self.RecastFunction(self.Resource);
    local abilityAvailable            = player:KnowsAbility(self.Resource.Id);
    local abilityCostDisplay, costMet = self:CostFunction(recastReady);
    if (type(recastReady) == 'number') then
        recastReady = (recastReady > 0);
    end

    self.State.Available = abilityAvailable;
    self.State.Cost = abilityCostDisplay;
    self.State.Ready = (costMet == true) and (recastReady == true);
    self.State.Recast = recastDisplay;
    self.State.Skillchain = nil;
end

return Updater;