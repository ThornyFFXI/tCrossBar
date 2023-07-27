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

    return tostring(itemCount), (itemCount > 0);
end

function Updater:New()
    local o = {};
    setmetatable(o, self);
    self.__index = self;
    return o;
end

function Updater:Initialize(square, binding)
    self.Binding       = binding;
    self.Square        = square;
    self.StructPointer = square.StructPointer;
    self.Resource      = AshitaCore:GetResourceManager():GetAbilityById(self.Binding.Id);

    local layout = gInterface:GetSquareManager().Layout;
    self.IconImage = GetImagePath(self.Binding.Image);
    self.CrossImage = layout.CrossPath;
    self.TriggerImage = layout.TriggerPath;
    self.AnimationIndex = 1;
    self.SkillchainAnimationTime = layout.SkillchainAnimationTime;
    self.SkillchainAnimationImages = layout.SkillchainAnimationPaths;
    self.ResonanceToFile = {
        [1] = 'skillchains/liquefaction.png',
        [2] = 'skillchains/induration.png',
        [3] = 'skillchains/detonation.png',
        [4] = 'skillchains/scission.png',
        [5] = 'skillchains/impaction.png',
        [6] = 'skillchains/reverberation.png',
        [7] = 'skillchains/transfixion.png',
        [8] = 'skillchains/compression.png',
        [9] = 'skillchains/fusion.png',
        [10] = 'skillchains/gravitation.png',
        [11] = 'skillchains/distortion.png',
        [12] = 'skillchains/fragmentation.png',
        [13] = 'skillchains/light.png',
        [14] = 'skillchains/darkness.png',
        [15] = 'skillchains/light.png',
        [16] = 'skillchains/darkness.png',
        [17] = 'skillchains/radiance.png',
        [18] = 'skillchains/umbra.png',
    };
    for i = 1,18 do
        self.ResonanceToFile[i] = GetImagePath(self.ResonanceToFile[i], self.DefaultIcon);
    end
    
    --Custom
    if (self.Binding.CostOverride) then
        self.CostFunction = ItemCost:bind2(self.Binding.CostOverride);
    else
        self.CostFunction = function()
            return '', true;
        end
    end
end

function Updater:Destroy()

end

function Updater:Tick()
    local known = gPlayer:KnowsAbility(self.Resource.Id);
    local activeSkillchain = self:UpdateSkillchain();
    
    if (gSettings.ShowHotkey) and (self.Binding.ShowHotkey) then
        self.StructPointer.Hotkey = self.Square.Hotkey;
    else
        self.StructPointer.Hotkey = '';
    end

    self.StructPointer.Recast = '';
    
    if (self.IconImage == nil) then
        self.StructPointer.IconImage = '';
    else
        self.StructPointer.IconImage = self.IconImage;
    end

    if (gSettings.ShowName) and (self.Binding.ShowName) then
        self.StructPointer.Name = self.Binding.Label;
    else
        self.StructPointer.Name = '';
    end

    if (gSettings.ShowCost) and (self.Binding.ShowCost) then
        self.StructPointer.Cost = self:CostFunction();
    else
        self.StructPointer.Cost = '';
    end

    if (gSettings.ShowSkillchainIcon) and (self.Binding.ShowSkillchainIcon) then
        if (activeSkillchain) then
            self.StructPointer.IconImage = self.SkillchainIcon;
        end
    end

    if (gSettings.ShowSkillchainAnimation) and (self.Binding.ShowSkillchainAnimation) then
        if (activeSkillchain) then
            if (self.NextSkillchainImage == nil) or (os.clock() > self.NextSkillchainImage) then
                self.AnimationIndex = self.AnimationIndex + 1;
                if (self.AnimationIndex > #self.SkillchainAnimationImages) then
                    self.AnimationIndex = 1;
                end
                self.NextSkillchainImage = os.clock() + self.SkillchainAnimationTime;
            end
            self.StructPointer.OverlayImage1 = self.SkillchainAnimationImages[self.AnimationIndex];
        else
            self.StructPointer.OverlayImage1 = '';
        end
    else
        self.StructPointer.OverlayImage1 = '';
    end

    if (gSettings.ShowCross) and (self.Binding.ShowCross) then
        if known == false then
            self.StructPointer.OverlayImage2 = self.CrossImage;
        else
            self.StructPointer.OverlayImage2 = '';
        end
    end

    if (gSettings.ShowTrigger) and (self.Binding.ShowTrigger) then
        if (self.Square.Activation > os.clock()) then
            self.StructPointer.OverlayImage3 = self.TriggerImage;
        else
            self.StructPointer.OverlayImage3 = '';
        end
    end
    
    if (gSettings.ShowFade) and (self.Binding.ShowFade) and ((not known) or (AshitaCore:GetMemoryManager():GetParty():GetMemberTP(0) < 1000)) then
        self.StructPointer.Fade = 1;
    else
        self.StructPointer.Fade = 0;
    end
end

function Updater:UpdateSkillchain()
    local targetMgr = AshitaCore:GetMemoryManager():GetTarget();
    local target = targetMgr:GetTargetIndex(targetMgr:GetIsSubTargetActive());

    --Skip if no target..
    if (target == 0) then
        return false;
    end

    --Skip if target is a player..
    if (target >= 0x400) and (target < 0x700) then
        return false;
    end

    --Skip if target is a pet..
    if (target >= 0x700) and (AshitaCore:GetMemoryManager():GetEntity():GetTrustOwnerTargetIndex(target) ~= 0) then
        return false;
    end

    local resonation, skillchain = gSkillchain:GetSkillchain(target, self.Resource.Id);
    if (resonation == nil) or (resonation.WindowOpen > os.clock()) or (resonation.WindowClose < os.clock()) then
        return false;
    end


    self.SkillchainIcon = self.ResonanceToFile[skillchain];
    return true;
end

return Updater;