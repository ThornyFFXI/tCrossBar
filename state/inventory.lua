--[[
    This library stores item counts and locations as a state, which makes querying them much more efficient.
    This is necessary because querying item counts by parsing the entire inventory takes an obscene amount of resources.
    Side note, this also allows inventory query while zoning.

    Performance Test(20x tomahawk binding, 1 minute, total frames):
    Querying containers(inventory, all wardrobes) directly - 7063 frames
    Rendering a 0 without querying inventory - 25,558 frames
    Querying via this library - 25792 frames
]]--

local inventory = {
    PlayerName = '',
    PlayerId = 0,
    Containers = T{},
    Items = T{},
};
for i = 0,17 do
    inventory.Containers[i] = {};
end

local function AddItem(container, index, itemTable)
    local itemState = inventory.Items[itemTable.Id];
    if (itemState == nil) then
        inventory.Items[itemTable.Id] = {
            Count = itemTable.Count,
            Locations = T{ { Container = container, Index = index } },
        };
    else
        itemState.Count = itemState.Count + itemTable.Id;
        itemState.Locations:append({ Container = container, Index = index });
    end
    inventory.Containers[container][index] = itemTable;
end

local function RemoveItem(container, index)
    local item = inventory.Containers[container][index];
    if item ~= nil then
        local itemState = inventory.Items[item.Id];
        if itemState ~= nil then
            itemState.Count = itemState.Count - item.Count;
            local newTable = T{};
            for _,entry in ipairs(itemState.Locations) do
                if (entry.Container ~= container) or (entry.Index ~= index) then
                    newTable:append(entry);
                end
            end
            itemState.Locations = newTable;
        end
    end
    inventory.Containers[container][index] = nil;
end

--Initialize from memory if ingame
local playerIndex = AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(0);
if playerIndex ~= 0 then
    local entity = AshitaCore:GetMemoryManager():GetEntity();
    local flags = entity:GetRenderFlags0(playerIndex);
    if (bit.band(flags, 0x200) == 0x200) and (bit.band(flags, 0x4000) == 0) then
        inventory.PlayerName = entity:GetName(playerIndex);
        inventory.PlayerId = entity:GetServerId(playerIndex);

        local function MakeItemTable(container, item)
            local newItem = {
                Container = container,
                Id = item.Id,
                Index = item.Index,
                Count = item.Count,
                Flags = item.Flags,
                Price = item.Price,
                Extra = item.Extra
            };
            return newItem;
        end
        
        local invMgr = AshitaCore:GetMemoryManager():GetInventory();
        for i = 0,17 do
            for j = 0,80 do
                local item = invMgr:GetContainerItem(i, j);
                if item.Id ~= 0 and item.Count ~= 0 then
                    AddItem(i, j, MakeItemTable(i, item));
                end
            end
        end
    end
end

ashita.events.register('packet_in', 'inventory_tracker_handleincomingpacket', function (e)
    if (e.id == 0x00A) then
        local id = struct.unpack('L', e.data, 0x04 + 1);
        local name = struct.unpack('c16', e.data, 0x84 + 1);
        local i,j = string.find(name, '\0');
        if (i ~= nil) then
            name = string.sub(name, 1, i - 1);
        end

        --Full clear if player changed.
        if (id ~= inventory.PlayerId) or (name ~= inventory.PlayerName) then
            inventory = {
                PlayerName = name,
                PlayerId = id,
                Containers = T{},
                Items = T{},
            };
            for i = 0,17 do
                inventory.Containers[i] = {};
            end

        --Clear temporary and recycle bin regardless..
        else
            for i = 1,81 do
                RemoveItem(3, i);
                RemoveItem(17, i);
            end
        end
    elseif (e.id == 0x1E) then
        local count = struct.unpack('L', e.data, 0x04 + 1);
        local container = struct.unpack('B', e.data, 0x08 + 1);
        local index = struct.unpack('B', e.data, 0x09 + 1);
        local flags = struct.unpack('B', e.data, 0x0A + 1);
        local itemTable = inventory.Containers[container][index];

        --0x1E only updates items, if we don't already have the item we can't update it.
        if itemTable == nil then return; end

        if (count ~= itemTable.Count) then
            if (count == 0) then
                RemoveItem(container, index);
                return;
            end

            --Update count..
            local itemEntry = inventory.Items[itemTable.Id];
            itemEntry.Count = itemEntry.Count + (count - itemTable.Count);
            itemTable.Count = count;
        end

        --Update flags..
        itemTable.Flags = flags;

    elseif (e.id == 0x1F) then
        local count = struct.unpack('L', e.data, 0x04 + 1);
        local id = struct.unpack('H', e.data, 0x08 + 1);
        local container = struct.unpack('B', e.data, 0x0A + 1);
        local index = struct.unpack('B', e.data, 0x0B + 1);
        local flags = struct.unpack('B', e.data, 0x0C + 1);
        local itemTable = inventory.Containers[container][index];

        --Clear old item entirely if ID changed..
        if (itemTable ~= nil) and (id ~= itemTable.Id) then
            RemoveItem(container, index);
            itemTable = nil;
        end

        --Add new item if slot was empty or ID changed..
        if (itemTable == nil) then
            local itemTable = {};
            itemTable.Id = id;
            itemTable.Index = index;
            itemTable.Count = count;
            itemTable.Flags = flags;
            itemTable.Container = container;
            itemTable.Price = 0;
            itemTable.Extra = '\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00';
            AddItem(container, index, itemTable);
            return;
        end

        --Update item if it already existed and ID didn't change..        
        if (count ~= itemTable.Count) then
            if (count == 0) then
                RemoveItem(container, index);
                return;
            end

            --Update count..
            local itemEntry = inventory.Items[itemTable.Id];
            itemEntry.Count = itemEntry.Count + (count - itemTable.Count);
            itemTable.Count = count;
        end

        --Update flags..
        itemTable.Flags = flags;

    elseif (e.id == 0x20) then        
        local index = struct.unpack('B', e.data, 0x0F + 1);
        local container = struct.unpack('B', e.data, 0x0E + 1);
        local count = struct.unpack('L', e.data, 0x04 + 1);
        local price = struct.unpack('L', e.data, 0x08 + 1);
        local id = struct.unpack('H', e.data, 0x0C + 1);
        local flags = struct.unpack('B', e.data, 0x10 + 1);
        local extra = struct.unpack('c24', e.data, 0x11 + 1) .. '\x00\x00\x00\x00';
        local itemTable = inventory.Containers[container][index];

        --Clear old item entirely if ID changed..
        if (itemTable ~= nil) and (id ~= itemTable.Id) then
            RemoveItem(container, index);
            itemTable = nil;
        end

        --Add new item if slot was empty or ID changed..
        if (itemTable == nil) then
            local itemTable = {};
            itemTable.Id = id;
            itemTable.Index = index;
            itemTable.Count = count;
            itemTable.Flags = flags;
            itemTable.Container = container;
            itemTable.Price = 0;
            itemTable.Extra = extra;
            AddItem(container, index, itemTable);
            return;
        end

        --Update item if it already existed and ID didn't change..        
        if (count ~= itemTable.Count) then
            if (count == 0) then
                RemoveItem(container, index);
                return;
            end

            --Update count..
            local itemEntry = inventory.Items[itemTable.Id];
            itemEntry.Count = itemEntry.Count + (count - itemTable.Count);
            itemTable.Count = count;
        end
        
        --Update remaining data..
        itemTable.Flags = flags;
        itemTable.Price = price;
        itemTable.Extra  = extra;
    end
end);

local exposed = {};

function exposed:GetItemData(itemId)
    return inventory.Items[itemId];
end

function exposed:GetItemTable(container, index)
    return inventory.Containers[container][index];
end

return exposed;