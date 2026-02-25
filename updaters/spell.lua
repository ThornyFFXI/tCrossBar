local Updater = {};

local inventory    = require('state.inventory');
local player       = require('state.player');
local skillchain   = require('state.skillchain');
local ninjutsuCost = T{
    [318] = T{ 2553, 2972 }, --Monomi: Ichi
    [319] = T{ 2555, 2973 }, --Aisha: Ichi
    [320] = T{ 1161, 2971 }, --Katon: Ichi
    [321] = T{ 1161, 2971 }, --Katon: Ni
    [322] = T{ 1161, 2971 }, --Katon: San
    [323] = T{ 1164, 2971 }, --Hyoton: Ichi
    [324] = T{ 1164, 2971 }, --Hyoton: Ni
    [325] = T{ 1164, 2971 }, --Hyoton: San
    [326] = T{ 1167, 2971 }, --Huton: Ichi
    [327] = T{ 1167, 2971 }, --Huton: Ni
    [328] = T{ 1167, 2971 }, --Huton: San
    [329] = T{ 1170, 2971 }, --Doton: Ichi
    [330] = T{ 1170, 2971 }, --Doton: Ni
    [331] = T{ 1170, 2971 }, --Doton: San
    [332] = T{ 1173, 2971 }, --Raiton: Ichi
    [333] = T{ 1173, 2971 }, --Raiton: Ni
    [334] = T{ 1173, 2971 }, --Raiton: San
    [335] = T{ 1176, 2971 }, --Suiton: Ichi
    [336] = T{ 1176, 2971 }, --Suiton: Ni
    [337] = T{ 1176, 2971 }, --Suiton: San
    [338] = T{ 1179, 2972 }, --Utsusemi: Ichi
    [339] = T{ 1179, 2972 }, --Utsusemi: Ni
    [340] = T{ 1179, 2972 }, --Utsusemi: San
    [341] = T{ 1182, 2973 }, --Jubaku: Ichi
    [342] = T{ 1182, 2973 }, --Jubaku: Ni
    [343] = T{ 1182, 2973 }, --Jubaku: San
    [344] = T{ 1185, 2973 }, --Hojo: Ichi
    [345] = T{ 1185, 2973 }, --Hojo: Ni
    [346] = T{ 1185, 2973 }, --Hojo: San
    [347] = T{ 1188, 2973 }, --Kurayami: Ichi
    [348] = T{ 1188, 2973 }, --Kurayami: Ni
    [349] = T{ 1188, 2973 }, --Kurayami: San
    [350] = T{ 1191, 2973 }, --Dokumori: Ichi
    [351] = T{ 1191, 2973 }, --Dokumori: Ni
    [352] = T{ 1191, 2973 }, --Dokumori: San
    [353] = T{ 1194, 2972 }, --Tonko: Ichi
    [354] = T{ 1194, 2972 }, --Tonko: Ni
    [505] = T{ 8803, 2972 }, --Gekka: Ichi
    [506] = T{ 8804, 2972 }, --Yain: Ichi
    [507] = T{ 2642, 2972 }, --Myoshu: Ichi
    [508] = T{ 2643, 2973 }, --Yurin: Ichi
    [509] = T{ 2644, 2972 }, --Kakka: Ichi
    [510] = T{ 2970, 2972 }, --Migawari: Ichi 
};

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

local function NinjutsuCost(updater, items)
    local specificTool = items[1];
    local genericTool = items[2];
    local tools = T{ specificTool };
    if (player:GetJobData().MainJob == 13) then
        tools:append(genericTool);
    end

    local itemCount = 0;
    for _,item in ipairs(tools) do
        local itemData = inventory:GetItemData(item);
        if (itemData ~= nil) then
            for _,itemEntry in ipairs(itemData.Locations) do
                if (itemEntry.Container == 0) then
                    itemCount = itemCount + inventory:GetItemTable(itemEntry.Container, itemEntry.Index).Count;
                end
            end
        end
    end

    return tostring(itemCount), (itemCount > 0);
end

local function ManaCost(resource)
    local cost = resource.ManaCost;

    local buffs = AshitaCore:GetMemoryManager():GetPlayer():GetBuffs();
    for _,buff in ipairs(buffs) do
        if ((buff == 47) or (buff == 229)) then
            cost = 0;
            break;
        end
    end
    
    if cost > 0 then
        --White magic
        if (resource.Type == 1) then
            local artsMod, penuryMod;
            for _,buff in ipairs(buffs) do
                if (buff == 255) then
                    break;
                elseif (buff == 358) or (buff == 401) then
                    artsMod = 0.9;
                elseif (buff == 359) or (buff == 402) then
                    artsMod = 1.2;
                elseif (buff == 360) then
                    penuryMod = 0.5;
                end
            end
            if penuryMod then
                cost = math.ceil(cost * penuryMod);
            elseif artsMod then
                cost = math.ceil(cost * artsMod);
            end
        --Black magic
        elseif (resource.Type == 2) then
            local artsMod, penuryMod;
            for _,buff in ipairs(buffs) do
                if (buff == 255) then
                    break;
                elseif (buff == 358) or (buff == 401) then
                    artsMod = 1.2;
                elseif (buff == 359) or (buff == 402) then
                    artsMod = 0.9;
                elseif (buff == 361) then
                    penuryMod = 0.5;
                end
            end
            if penuryMod then
                cost = math.ceil(cost * penuryMod);
            elseif artsMod then
                cost = math.ceil(cost * artsMod);
            end
        end
    end

    return tostring(cost), (AshitaCore:GetMemoryManager():GetParty():GetMemberMP(0) >= cost);
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

local function CheckAddendum(updater)
    local buffs = AshitaCore:GetMemoryManager():GetPlayer():GetBuffs();
    for _,buff in ipairs(buffs) do
        if (buff == 416) then
            return true;
        end
        if (buff == updater.AddendumBuffId) then
            return true;
        end
    end

    return false;
end

local function CheckTabula(updater)
    local buffs = AshitaCore:GetMemoryManager():GetPlayer():GetBuffs();
    for _,buff in ipairs(buffs) do
        if (buff == 377) then
            return true;
        end
    end

    return false;
end

local function CheckMeteor(updater)
    local buffs = AshitaCore:GetMemoryManager():GetPlayer():GetBuffs();
    for _,buff in ipairs(buffs) do
        if (buff == 79) then
            return true;
        end
    end

    return false;
end

local function CheckUnbridled(updater)
    local buffs = AshitaCore:GetMemoryManager():GetPlayer():GetBuffs();
    for _,buff in ipairs(buffs) do
        if (buff == 485) or (buff == 505) then
            return true;
        end
    end

    return false;
end

local function GetSpellAvailableGeneric(updater)
    if not player:HasSpell(updater.Resource) then
        return false, false;
    end

    local jobData = player:GetJobData();
    if (jobData.MainJobLevel < updater.MainRequirement) and (jobData.SubJobLevel < updater.SubRequirement) then
        return false, false;
    end

    local ready = true;
    if (updater.BuffCheck) then
        ready = updater:BuffCheck();
    end

    return true, ready;
end

local function MainJobCheck(updater, jobData)
    if (jobData.MainJobLevel < updater.MainRequirement) then
        return false, false;
    end

    local addendum = true;
    if (updater.MainAddendum) then
        addendum = CheckAddendum(updater);
    end
    
    return true, addendum;
end

local function SubJobCheck(updater, jobData)
    if (jobData.SubJobLevel < updater.SubRequirement) then
        return false, false;
    end

    local addendum = true;
    if (updater.SubAddendum) then
        addendum = CheckAddendum(updater);
    end
    
    return true, addendum;
end

local function JobPointCheck(updater, jobData)
    return (player:GetJobPointTotal(jobData.MainJob) >= updater.MainRequirement), true;
end

local function GetSpellAvailable(updater)
    if not player:HasSpell(updater.Resource) then
        return false, false;
    end

    local jobData = player:GetJobData();
    local mainAvailable, mainAddendum = updater.MainJobCheck(updater, jobData);
    local subAvailable, subAddendum = SubJobCheck(updater, jobData);

    if (not mainAvailable) and (not subAvailable) then
        return false, false;
    end

    local ready = (mainAddendum or subAddendum);
    if (ready) and (updater.BuffCheck) then
        ready = updater:BuffCheck();
    end

    return true, ready;
end

function Updater:New()
    local o = {};
    setmetatable(o, self);
    self.__index = self;
    return o;
end

function Updater:Initialize(element, binding)
    self.State = element.State;
    self.Resource      = AshitaCore:GetResourceManager():GetSpellById(binding.Id);

    --Set cost and recast function for charge-based abilities.

    local ninjutsu = ninjutsuCost[binding.Id];
    
    --Custom
    if (binding.CostOverride) then
        self.CostFunction = ItemCost:bind2(binding.CostOverride);
    elseif (ninjutsu ~= nil) then
        self.CostFunction = NinjutsuCost:bind2(ninjutsu);
    elseif (self.Resource.ManaCost < 1) then
        self.CostFunction = function()
            return '', true;
        end
    else
        self.CostFunction = ManaCost:bind1(self.Resource);
    end

    local jobData = player:GetJobData();
    
    --Set impossible requirement..
    self.MainRequirement = 999;
    self.SubRequirement  = 999;
    self.GetSpellAvailable = GetSpellAvailableGeneric;

    if bit.band(bit.rshift(self.Resource.JobPointMask, jobData.MainJob), 1) == 1 then
        self.MainJobCheck = JobPointCheck;
        self.MainRequirement = self.Resource.LevelRequired[jobData.MainJob + 1];
        self.MainAddendum = false; --Nothing requires addendum and JP..
    else
        self.MainJobCheck = MainJobCheck;
        self.MainRequirement = self.Resource.LevelRequired[jobData.MainJob + 1];
        if (self.MainRequirement == -1) then
            self.MainRequirement = 999;
        end
        if ((jobData.MainJob == 20) and (bit.band(bit.rshift(self.Resource.Requirements, 2), 1) == 1)) then
            self.MainAddendum = true;
            self.AddendumBuffId = (self.Resource.Type == 1) and 401 or 402;
        else
            self.MainAddendum = false;
        end
    end
    
    if bit.band(bit.rshift(self.Resource.JobPointMask, jobData.SubJob), 1) == 0 then
        self.SubRequirement = self.Resource.LevelRequired[jobData.SubJob + 1];
        if (self.SubRequirement == -1) then
            self.SubRequirement = 999;
        end
        if ((jobData.SubJob == 20) and (bit.band(bit.rshift(self.Resource.Requirements, 2), 1) == 1)) then
            self.SubAddendum = true;
            self.AddendumBuffId = (self.Resource.Type == 1) and 401 or 402;
        else
            self.SubAddendum = false;
        end
    end

    if (bit.band(bit.rshift(self.Resource.Requirements, 4), 1) == 1) then
        self.BuffCheck = CheckMeteor;
    elseif (bit.band(bit.rshift(self.Resource.Requirements, 3), 1) == 1) then
        self.BuffCheck = CheckTabula;
    elseif (T{ 736, 737, 738, 739, 740, 741, 742, 743, 744, 745, 746, 747, 748749, 750, 751, 752, 753 }:contains(self.Resource.Index)) then
        self.BuffCheck = CheckUnbridled;
    end
end

function Updater:Destroy()

end

function Updater:Tick()
    --RecastReady will hold number of charges for charged abilities.
    local recastReady, recastDisplay  = GetSpellRecast(self.Resource);
    local spellKnown, spellAvailable  = GetSpellAvailable(self);
    local spellCostDisplay, costMet   = self:CostFunction();
    
    self.State.Available = spellKnown;
    self.State.Cost = spellCostDisplay;
    self.State.Ready = ((costMet == true) and (recastReady == true) and (spellAvailable == true));
    if (recastDisplay ~= nil) then
        self.State.Recast = recastDisplay;
    else
        self.State.Recast = '';
    end
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

    local resonation, result = skillchain:GetSkillchainBySpell(target, self.Resource.Index);
    if (resonation == nil) or (resonation.WindowClose < os.clock()) then
        return;
    end

    return { Name=result, Open=(os.clock() > resonation.WindowOpen) };
end

return Updater;