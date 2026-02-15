local d3d8     = require('d3d8');
local encoding = require('gdifonts.encoding');
local ffi      = require('ffi');
local gdi      = require('gdifonts.include');
local updaters = {
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
            AshitaCore:GetChatManager():QueueCommand(-1, encoding:UTF8_To_ShiftJIS(command));
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

function Element:New(hotkey, layout, hotkeyLabel)
    local o = {};
    setmetatable(o, self);
    self.__index = self;
    o.State = {
        Available = false,
        Ready = false,
        Cost = '',
        Hotkey = hotkey,
        HotkeyLabel = hotkeyLabel or hotkey,
        Name = '',
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
    self.Activation = os.clock();
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

function Element:HitTest(x, y)
    local hitbox = self.HitBox;
    if (x < hitbox.MinX) or (x > hitbox.MaxX) then
        return false;
    end

    return (y >= hitbox.MinY) and (y <= hitbox.MaxY);
end

local textOrder = T { 'Hotkey', 'Cost', 'Recast', 'Name' };
local d3dwhite = d3d8.D3DCOLOR_ARGB(255, 255, 255, 255);
local vec_position = ffi.new('D3DXVECTOR2', { 0, 0, });
local vec_font_scale = ffi.new('D3DXVECTOR2', { 1.0, 1.0, });

local function CreateLargeRecastObject(layout)
    local iconData = layout.Icon;
    local largeRecastSettings = {
        box_height = 0,
        box_width = 0,
        font_alignment = 1,
        font_color = 0xFFFFFFFF,
        font_family = 'Arial',
        font_flags = 1,
        font_height = math.max(18, math.floor(math.min(iconData.Width, iconData.Height) * 0.6)),
        gradient_color = 0x00000000,
        gradient_style = 0,
        outline_color = 0xFF000000,
        outline_width = 2,
    };
    local obj = gdi:create_object(largeRecastSettings, true);
    obj.OffsetX = iconData.OffsetX + (iconData.Width / 2);
    obj.OffsetY = iconData.OffsetY + (iconData.Height / 2);
    return obj;
end

function Element:Initialize()
    self.FontObjects = T{};
    for _,entry in ipairs(textOrder) do
        local data = self.Layout[entry];
        if data then
            local obj = gdi:create_object(data, true);
            obj.OffsetX = data.OffsetX;
            obj.OffsetY = data.OffsetY;
            self.FontObjects[entry] = obj;
        end
    end
    self.LargeRecastObject = CreateLargeRecastObject(self.Layout);
end

function Element:SetPosition(position)
    self.PositionX = position[1] + self.OffsetX;
    self.PositionY = position[2] + self.OffsetY;
    self.HitBox = {
        MinX = self.PositionX + self.Layout.Icon.OffsetX,
        MaxX = self.PositionX + self.Layout.Icon.OffsetX + self.Layout.Icon.Width,
        MinY = self.PositionY + self.Layout.Icon.OffsetY,
        MaxY = self.PositionY + self.Layout.Icon.OffsetY + self.Layout.Icon.Height,
    };
end

function Element:UpdateBinding(binding)
    if (self.Updater ~= nil) then
        self.Updater:Destroy();
    end

    self.Icon = nil;
    self.Binding = binding;
    local updater = updaters.Empty;
    self.State.Name = '';
    if (type(self.Binding) == 'table') then
        if (self.Binding.ActionType ~= nil) then
            local newUpdater = updaters[self.Binding.ActionType];
            if (newUpdater ~= nil) then
                updater = newUpdater;
            end
        end
        if (type(self.Binding.Label) == 'string') then
            self.State.Name = self.Binding.Label;
        end
    end

    self.Updater = updater:New();
    self.Updater:Initialize(self, self.Binding);

    if (self.Binding ~= nil) then
        local tx = gTextureCache:GetTexture(self.Binding.Image);
        local dimensions = { Width = self.Layout.Icon.Width, Height=self.Layout.Icon.Height };
        if tx and dimensions then
            local preparedTexture = {};
            preparedTexture.Texture = tx.Texture;
            preparedTexture.Rect = ffi.new('RECT', { 0, 0, tx.Width, tx.Height });
            preparedTexture.Scale = ffi.new('D3DXVECTOR2', { dimensions.Width / tx.Width, dimensions.Height / tx.Height });
            self.Icon = preparedTexture;
        end
    end
end

local vec_scale = ffi.new('D3DXVECTOR2', { 1.0, 1.0 });
function Element:RenderIcon(sprite, overrideColor, overrideScale)
    self.Updater:Tick();

    local positionX = self.PositionX;
    local positionY = self.PositionY;
    local layout = self.Layout;
    local baseColor = overrideColor or d3dwhite;

    --Draw frame first..
    if ((self.Binding) or (gSettings.ShowEmpty)) and (gSettings.ShowFrame) then
        local component = layout.Textures.Frame;
        if component then
            vec_position.x = positionX + layout.Frame.OffsetX;
            vec_position.y = positionY + layout.Frame.OffsetY;
            if (overrideScale) then
                vec_scale.x = component.Scale.x * overrideScale;
                vec_scale.y = component.Scale.y * overrideScale;
                -- Adjust position to keep centered
                local widthChange = (component.Rect.right - component.Rect.left) * (vec_scale.x - component.Scale.x);
                local heightChange = (component.Rect.bottom - component.Rect.top) * (vec_scale.y - component.Scale.y);
                vec_position.x = vec_position.x - (widthChange / 2);
                vec_position.y = vec_position.y - (heightChange / 2);
                sprite:Draw(component.Texture, component.Rect, vec_scale, nil, 0.0, vec_position, baseColor);
            else
                sprite:Draw(component.Texture, component.Rect, component.Scale, nil, 0.0, vec_position, baseColor);
            end
        end
    end

    if (self.Binding == nil) then
        return;
    end

    --Evaluate skillchain state..
    local icon = self.Icon;
    vec_position.x = positionX + layout.Icon.OffsetX;
    vec_position.y = positionY + layout.Icon.OffsetY;
    if (self.State.Skillchain ~= nil) then
        if (self.State.Skillchain.Open) then
            if (self.SkillchainAnimation == nil) then
                self.SkillchainAnimation =
                {
                    Frame = 1,
                    Time = os.clock();
                };
            elseif (os.clock() > (self.SkillchainAnimation.Time + layout.SkillchainFrameLength)) then
                self.SkillchainAnimation.Frame = self.SkillchainAnimation.Frame + 1;
                if (self.SkillchainAnimation.Frame > #layout.SkillchainFrames) then
                    self.SkillchainAnimation.Frame = 1;
                end
                self.SkillchainAnimation.Time = os.clock();
            end
        else
            self.SkillchainAnimation = nil;
        end
        
        if (gSettings.ShowSkillchainIcon) and (self.Binding.ShowSkillchainIcon) then
            icon = layout.Textures[self.State.Skillchain.Name];
        end
    else
        self.SkillchainAnimation = nil;
    end

    --Draw icon over frame..
    if icon then
        local scale = icon.Scale;
        vec_position.x = positionX + layout.Icon.OffsetX;
        vec_position.y = positionY + layout.Icon.OffsetY;
        
        if (overrideScale) then
            vec_scale.x = icon.Scale.x * overrideScale;
            vec_scale.y = icon.Scale.y * overrideScale;
            scale = vec_scale;
            -- Adjust position to keep centered
            local widthChange = (icon.Rect.right - icon.Rect.left) * (vec_scale.x - icon.Scale.x);
            local heightChange = (icon.Rect.bottom - icon.Rect.top) * (vec_scale.y - icon.Scale.y);
            vec_position.x = vec_position.x - (widthChange / 2);
            vec_position.y = vec_position.y - (heightChange / 2);
        end

        local opacity = baseColor;
        if (gSettings.ShowFade) and (self.Binding.ShowFade) and (not self.State.Ready) then
            opacity = layout.FadeOpacity;
        end
        sprite:Draw(icon.Texture, icon.Rect, scale, nil, 0.0, vec_position, opacity);
    end

    --Draw skillchain animation if applicable..
    if (self.SkillchainAnimation) and (gSettings.ShowSkillchainAnimation) and (self.Binding.ShowSkillchainAnimation) then
        local component = layout.SkillchainFrames[self.SkillchainAnimation.Frame];
        if component then
            vec_position.x = positionX + layout.Icon.OffsetX;
            vec_position.y = positionY + layout.Icon.OffsetY;
            if (overrideScale) then
                vec_scale.x = component.Scale.x * overrideScale;
                vec_scale.y = component.Scale.y * overrideScale;
                local widthChange = (component.Rect.right - component.Rect.left) * (vec_scale.x - component.Scale.x);
                local heightChange = (component.Rect.bottom - component.Rect.top) * (vec_scale.y - component.Scale.y);
                vec_position.x = vec_position.x - (widthChange / 2);
                vec_position.y = vec_position.y - (heightChange / 2);
                sprite:Draw(component.Texture, component.Rect, vec_scale, nil, 0.0, vec_position, baseColor);
            else
                sprite:Draw(component.Texture, component.Rect, component.Scale, nil, 0.0, vec_position, baseColor);
            end
        end
    end

    --Draw crossout if applicable..
    if (gSettings.ShowCross) and (self.Binding.ShowCross) and (not self.State.Available) then
        local component = layout.Textures.Cross;
        if component then
            vec_position.x = positionX + layout.Icon.OffsetX;
            vec_position.y = positionY + layout.Icon.OffsetY;
            if (overrideScale) then
                vec_scale.x = component.Scale.x * overrideScale;
                vec_scale.y = component.Scale.y * overrideScale;
                local widthChange = (component.Rect.right - component.Rect.left) * (vec_scale.x - component.Scale.x);
                local heightChange = (component.Rect.bottom - component.Rect.top) * (vec_scale.y - component.Scale.y);
                vec_position.x = vec_position.x - (widthChange / 2);
                vec_position.y = vec_position.y - (heightChange / 2);
                sprite:Draw(component.Texture, component.Rect, vec_scale, nil, 0.0, vec_position, baseColor);
            else
                sprite:Draw(component.Texture, component.Rect, component.Scale, nil, 0.0, vec_position, baseColor);
            end
        end
    end

    --Draw trigger if applicable..
    if (gSettings.ShowTrigger) and (self.Binding.ShowTrigger) and (os.clock() < (self.Activation + gSettings.TriggerDuration)) then
        local component = layout.Textures.Trigger;
        if component then
            vec_position.x = positionX + layout.Icon.OffsetX;
            vec_position.y = positionY + layout.Icon.OffsetY;
            if (overrideScale) then
                 vec_scale.x = component.Scale.x * overrideScale;
                vec_scale.y = component.Scale.y * overrideScale;
                local widthChange = (component.Rect.right - component.Rect.left) * (vec_scale.x - component.Scale.x);
                local heightChange = (component.Rect.bottom - component.Rect.top) * (vec_scale.y - component.Scale.y);
                vec_position.x = vec_position.x - (widthChange / 2);
                vec_position.y = vec_position.y - (heightChange / 2);
                sprite:Draw(component.Texture, component.Rect, vec_scale, nil, 0.0, vec_position, layout.TriggerOpacity);
            else
                sprite:Draw(component.Texture, component.Rect, component.Scale, nil, 0.0, vec_position, layout.TriggerOpacity);
            end
        end
    end
end

function Element:RenderText(sprite)
    if (self.Binding == nil) then
        return;
    end

    local positionX = self.PositionX;
    local positionY = self.PositionY;
    
    local showLargeRecast = gSettings.LargeRecast and gSettings.ShowRecast and self.Binding.ShowRecast;
    
    for _,entry in ipairs(textOrder) do
        local setting = 'Show' .. entry;
        if (gSettings[setting]) and (self.Binding[setting]) then
            if (entry == 'Recast') and showLargeRecast then
                local text = self.State.Recast;
                if (type(text) == 'string') and (text ~= '') then
                    local obj = self.LargeRecastObject;
                    obj:set_text(text);
                    local texture, rect = obj:get_texture();
                    if (texture ~= nil) then
                        vec_position.x = obj.OffsetX + positionX - (rect.right / 2);
                        vec_position.y = obj.OffsetY + positionY - (rect.bottom / 2);
                        sprite:Draw(texture, rect, vec_font_scale, nil, 0.0, vec_position, d3dwhite);
                    end
                end
            else
                local obj = self.FontObjects[entry];
                if obj then
                    local text = self.State[entry];
                    if entry == 'Hotkey' then text = self.State.HotkeyLabel; end
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
end

return Element;