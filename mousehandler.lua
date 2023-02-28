local lastPositionX, lastPositionY;
local dragActive = false;
local blockLeftClick = false;
local hitType;

ffi.cdef[[
    int16_t GetKeyState(int32_t vkey);
]]

ashita.events.register('mouse', 'mouse_cb', function (e)
    if (e.blocked) then
        return;
    end
    
    local manager = gInterface:GetSquareManager();

    if dragActive then
        local pos = gSettings.Position[gSettings.Layout][hitType];
        pos[1] = pos[1] + (e.x - lastPositionX);
        pos[2] = pos[2] + (e.y - lastPositionY);
        lastPositionX = e.x;
        lastPositionY = e.y;
        if (e.message == 514) or (bit.band(ffi.C.GetKeyState(0x10), 0x8000) == 0) or (manager == nil) or (manager:GetHidden() == true) then
            dragActive = false;
            e.blocked = true;
            blockLeftClick = false;
            settings.save();
            return;
        end
    end
    
    if (manager ~= nil) and (e.message == 513) and (manager:GetHidden() == false) then
        local hitFrame, type = manager:HitTest(e.x, e.y);
        if (hitFrame) then
            if (bit.band(ffi.C.GetKeyState(0x10), 0x8000) ~= 0) then
                e.blocked = true;
                hitType = type;
                blockLeftClick = true;
                dragActive = true;
                lastPositionX = e.x;
                lastPositionY = e.y;
                return;
            end
        end
    end

    if (blockLeftClick) and (e.message == 514) then
        e.blocked = true;
        blockLeftClick = false;
    end
end);