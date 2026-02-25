local Updater = {};

local inventory   = require('state.inventory');
local vanaOffset  = 0x3C307D70;
local timePointer = ashita.memory.find('FFXiMain.dll', 0, '8B0D????????8B410C8B49108D04808D04808D04808D04C1C3', 2, 0);

local function GetTimeUTC()
    local ptr = ashita.memory.read_uint32(timePointer);
    ptr = ashita.memory.read_uint32(ptr);
    return ashita.memory.read_uint32(ptr + 0x0C);
end

--Item timer is in full seconds not frames.
local function RecastToString(timer)
    if (timer < 1) then
        return nil;
    end

    if (timer >= 3600) then
        local h = math.floor(timer / (3600));
        local m = math.floor(timer / 60);
        return string.format('%i:%02i', h, m);
    elseif (timer >= 60) then
        local m = math.floor(timer / 60);
        local s = math.fmod(timer, 60);
        return string.format('%i:%02i', m, s);
    else
        return string.format('%i', timer);
    end
end

local function GetItemRecast(itemId)
    local containers = T{ 0, 3 };
    local itemCount = 0;
    local itemData = inventory:GetItemData(itemId);
    if (itemData ~= nil) then
        for _,itemEntry in ipairs(itemData.Locations) do
            if (containers:contains(itemEntry.Container)) then
                itemCount = itemCount + inventory:GetItemTable(itemEntry.Container, itemEntry.Index).Count;
            end
        end
    end

    return itemCount;
end

local function GetEquipmentRecast(itemResource)
    local containers = T{ 0, 8, 10, 11, 12, 13, 14, 15, 16 };
    local itemCount = 0;
    local itemData = inventory:GetItemData(itemResource.Id);
    local lowestRecast = -1;
    if (itemData ~= nil) then
        local currentTime = GetTimeUTC();
        for _,itemEntry in ipairs(itemData.Locations) do
            if (containers:contains(itemEntry.Container)) then
                local item = inventory:GetItemTable(itemEntry.Container, itemEntry.Index);
                local useTime = (struct.unpack('L', item.Extra, 5) + vanaOffset) - currentTime;
                if (useTime < 0) then
                    useTime = 0;
                elseif (useTime == 0) then
                    useTime = 1;
                end

                local equipTime;
                if (item.Flags == 5) then
                    equipTime = (struct.unpack('L', item.Extra, 9) + vanaOffset) - currentTime;
                    if (equipTime < 0) then
                        equipTime = 0;
                    elseif (equipTime == 0) then
                        equipTime = 1;
                    end
                else
                    equipTime = itemResource.CastDelay;
                end

                local recast = math.max(useTime, equipTime);
                if (lowestRecast == -1) or (recast < lowestRecast) then
                    lowestRecast = recast;
                end

                itemCount = itemCount + item.Count;
            end
        end
    end

    return itemCount, RecastToString(lowestRecast);
end


function Updater:New()
    local o = {};
    setmetatable(o, self);
    self.__index = self;
    return o;
end

function Updater:Initialize(element, binding)
    self.State = element.State;
    self.Resource      = AshitaCore:GetResourceManager():GetItemById(binding.Id);

    if (bit.band(self.Resource.Flags, 0x800) ~= 0) then
        self.RecastFunction = GetEquipmentRecast:bind1(self.Resource);
    else
        self.RecastFunction = GetItemRecast:bind1(self.Resource.Id);
    end
end

function Updater:Destroy()

end

function Updater:Tick()
    local count, recastTimer = self.RecastFunction();
    
    self.State.Available = true;
    if (bit.band(self.Resource.Flags, 0x800) == 0) then
        self.State.Cost = tostring(count);
    else
        self.State.Cost = '';
    end
    self.State.Ready = (count > 0) and (recastTimer == nil);
    if (recastTimer ~= nil) then
        self.State.Recast = recastTimer;
    else
        self.State.Recast = '';
    end
    self.State.Skillchain = nil;
end

return Updater;