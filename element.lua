local d3d = require('d3d8');
local ffi = require('ffi');
local gdi = require('gdifonts.include');
local updaters     = {
    ['Ability']     = require('updaters.ability'),
    ['Command']     = require('updaters.command'),
    ['Empty']       = require('updaters.empty'),
    ['Item']        = require('updaters.item'),
    ['Spell']       = require('updaters.spell'),
    ['Trust']       = require('updaters.trust'),
    ['Weaponskill'] = require('updaters.weaponskill'),
};

local function DoMacro(macro)
    for _,line in ipairs(macro) do
        local command, waitTime;
        if (string.sub(line, 1, 6) == '/wait ') then
            waitTime = tonumber(string.sub(line, 7));
        else
            command = line;
            local waitStart, waitEnd = string.find(line, ' <wait %d*%.?%d+>');
            if (waitStart ~= nil) and (waitEnd == string.len(line)) then
                waitTime = tonumber(string.match(line, ' <wait (%d*%.?%d+)>'));
                if (type(waitTime) == 'number') then
                    command = string.sub(line, 1, waitStart - 1);
                end
            end
        end

        if command then
            AshitaCore:GetChatManager():QueueCommand(-1, command);
        end
        
        if type(waitTime) == 'number' then
            if (waitTime < 0.1) then
                coroutine.sleepf(1);
            else
                coroutine.sleep(waitTime);
            end
        end
    end
end

local Element = {};

function Element:New(hotkey, layout)
    local o = {};
    setmetatable(o, self);
    self.__index = self;
    o.State = {
        Available = false,
        Ready = false,
        Cost = '',
        Hotkey = hotkey,
        Label = '',
        Recast = '',
        Skillchain = nil,
    };
    local updater = updaters.Empty;
    o.Activation = 0;
    o.Layout = layout;
    o:Initialize();
    o.Updater = updater:New();
    o.Updater:Initialize(o);
    return o;
end

function Element:Activate()
    self.Activation = os.clock() + 0.25;
    if (self.Binding ~= nil) then
        local macroContainer = T{};
        for _,entry in ipairs(self.Binding.Macro) do
            macroContainer:append(entry);
        end
        DoMacro:bind1(macroContainer):oncef(0);
    end
end

function Element:Bind()
    gBindingGUI:Show(self.Hotkey, self.Binding);
end

function Element:Destroy()
    self.Updater:Destroy();
end

local textOrder = T { 'Hotkey', 'Cost', 'Recast', 'Name' };
local d3dwhite = d3d.D3DCOLOR_ARGB(255, 255, 255, 255);
local vec_position = ffi.new('D3DXVECTOR2', { 0, 0, });
local vec_font_scale = ffi.new('D3DXVECTOR2', { 1.0, 1.0, });
function Element:Initialize()
    self.FontObjects = T{};
    for _,entry in ipairs(textOrder) do
        local data = self.Layout.Element[entry];
        if data then
            local obj = gdi:create_object(data, true);
            obj:set_font_height(math.floor(data.font_height * gSettings.Scale));
            obj.OffsetX = data.OffsetX * gSettings.Scale;
            obj.OffsetY = data.OffsetY * gSettings.Scale;
            self.FontObjects[entry] = obj;
        end
    end
end

function Element:UpdateBinding(binding)
    if (binding == self.Binding) then
        return;
    end

    if (self.Updater ~= nil) then
        self.Updater:Destroy();
    end

    self.Binding = binding;
    local updater = updaters.Empty;
    self.State.Label = '';
    if (type(self.Binding) == 'table') then
        if (self.Binding.ActionType ~= nil) then
            local newUpdater = updaters[self.Binding.ActionType];
            if (newUpdater ~= nil) then
                updater = newUpdater;
            end
        end
        if (type(self.Binding.Label) == 'string') then
            self.State.Label = self.Binding.Label;
        end
    end

    self.Updater = updater:New();
    self.Updater:Initialize(self, self.Binding);
end

function Element:Render(sprite)
    if (self.Binding == nil) and (gSettings.ShowEmpty == false) then
        return;
    end

    self.Updater:Tick();

    local positionX = self.PositionX;
    local positionY = self.PositionY;
    local layout = self.Layout;

    --Draw frame first..
    if (gSettings.ShowFrame) then
        local component = layout.Frame;
        if component then
            vec_position.x = positionX + component.OffsetX;
            vec_position.y = positionY + component.OffsetY;
            sprite:Draw(component.Texture, component.Rect, component.Scale, nil, 0.0, vec_position, d3dwhite);
        end
    end

    --Evaluate skillchain state..
    local icon = self.Icon;
    vec_position.x = positionX + layout.Icon.OffsetX;
    vec_position.y = positionY + layout.Icon.OffsetY;
    if (self.Skillchain ~= nil) then
        if (self.SkillchainAnimation == nil) then
            self.SkillchainAnimation =
            {
                Frame = 1,
                Time = os.clock();
            };
        elseif (os.clock() > (self.SkillchainAnimation.Time + layout.Skillchain.FrameDelay)) then
            self.SkillchainAnimation.Frame = self.SkillchainAnimation.Frame + 1;
            if (self.SkillchainAnimation.Frame > #layout.Skillchain.Frames) then
                self.SkillchainAnimation.Frame = 1;
            end
            self.SkillchainAnimation.Time = os.clock();
        end
        
        if (gSettings.ShowSkillchainIcon) and (self.Binding.ShowSkillchainIcon) then
            icon = layout.SkillchainIcons[self.Skillchain.Name];
        end
    else
        self.SkillchainAnimation = nil;
    end

    --Draw icon over frame..
    if icon then
        vec_position.x = positionX + layout.Icon.OffsetX;
        vec_position.y = positionY + layout.Icon.OffsetY;
        local opacity = d3dwhite;
        if (gSettings.ShowFade) and (self.Binding.ShowFade) and (not self.State.Ready) then
            opacity = layout.Icon.FadeOpacity;
        end
        sprite:Draw(icon.Texture, icon.Rect, icon.Scale, nil, 0.0, vec_position, opacity);
    end

    --Draw skillchain animation if applicable..
    if (self.SkillchainAnimation) and (gSettings.ShowSkillchainAnimation) and (self.Binding.ShowSkillchainAnimation) then
        local component = layout.Skillchain.Frames[self.SkillchainAnimation.Frame];
        if component then
            vec_position.x = positionX + layout.Skillchain.OffsetX;
            vec_position.y = positionY + layout.Skillchain.OffsetY;
            sprite:Draw(component.Texture, component.Rect, component.Scale, nil, 0.0, vec_position, d3dwhite);
        end
    end

    --Draw crossout if applicable..
    if (gSettings.ShowCross) and (self.Binding.ShowCross) and (not self.State.Available) then
        local component = layout.Cross;
        if component then
            vec_position.x = positionX + component.OffsetX;
            vec_position.y = positionY + component.OffsetY;
            sprite:Draw(component.Texture, component.Rect, component.Scale, nil, 0.0, vec_position, d3dwhite);
        end
    end

    --Draw text elements..
    for _,entry in ipairs(textOrder) do
        local setting = 'Show' .. entry;
        if (gSettings[setting]) and (self.Binding[setting]) then
            local obj = self.FontObjects[entry];
            if obj then
                local text = self.State[entry];
                if (type(text) == 'string') and (text ~= '') then
                    obj:set_text(text);
                    local texture, rect = obj:get_texture();
                    if (texture ~= nil) then
                        local posX = obj.OffsetX + positionX;
                        if (obj.settings.font_alignment == 1) then
                            vec_position.x = posX - (rect.right / 2);
                        elseif (obj.settings.font_alignment == 2) then
                            vec_position.x = posX - rect.right;
                        else
                            vec_position.x = posX;;
                        end
                        vec_position.y = obj.OffsetY + positionY;
                        sprite:Draw(texture, rect, vec_font_scale, nil, 0.0, vec_position, d3dwhite);
                    end
                end
            end
        end
    end
end

return Element;