local Element = require('element');

local function GetButtonAlias(comboIndex, buttonIndex)
    local macroComboBinds = {
        [1] = 'LT',
        [2] = 'RT',
        [3] = 'LTRT',
        [4] = 'RTLT',
        [5] = 'LT2',
        [6] = 'RT2'
    };
    return string.format('%s:%d', macroComboBinds[comboIndex], buttonIndex);
end

local ElementGroup = {};

function ElementGroup:ClearHitboxes()
    for _,group in ipairs(self.Elements) do
        for _,element in ipairs(group) do
            element.HitBox = nil;
        end
    end
end

function ElementGroup:Destroy()
    self.Elements = T{};
end

function ElementGroup:GetElements()
    return self.Elements;
end

function ElementGroup:Initialize()
    self.Elements = T{};

    for state = 1,6 do
        local newState = T{};
        for macro = 1,8 do
            local newElement = Element:New(GetButtonAlias(state, macro));
            newState:append(newElement);
        end
        self.Elements[state] = newState;
    end

    self:UpdateBindings(gBindings:GetFormattedBindings());
end

function ElementGroup:UpdateBindings(bindings)
    for macroState,group in ipairs(self.Elements) do
        for index,element in ipairs(group) do
            element:UpdateBinding(bindings[GetButtonAlias(macroState, index)]);
        end
    end
end

ElementGroup:Initialize();
return ElementGroup;