local imgui = require('imgui');
local header = { 1.0, 0.75, 0.55, 1.0 };
local activeHeader = { 0.5, 1.0, 0.5, 1.0 };

local state = {
    IsOpen = { false },
    SelectedPaletteIndex = 1,
    NewPaletteName = { '' },
    RenamePaletteName = { '' },
    ShowDeleteConfirm = false,
    DeleteTargetIndex = 0,
    RenamingPaletteIndex = 0,
};

local function RefreshPalettes()
    if (gBindings and gBindings.JobBindings and gBindings.JobBindings.Palettes) then
        local count = #gBindings.JobBindings.Palettes;
        if (state.SelectedPaletteIndex > count) then
            state.SelectedPaletteIndex = math.max(1, count);
        end
    end
end

local function AddPalette()
    local name = state.NewPaletteName[1];
    if (name == nil or name == '') then
        return;
    end
    
    name = name:gsub('^%s+', ''):gsub('%s+$', '');
    if (name == '') then
        return;
    end
    
    for _,palette in ipairs(gBindings.JobBindings.Palettes) do
        if (string.lower(palette.Name) == string.lower(name)) then
            return;
        end
    end
    
    local newPalette = { Name = name, Bindings = T{} };
    gBindings.JobBindings.Palettes:append(newPalette);
    state.SelectedPaletteIndex = #gBindings.JobBindings.Palettes;
    state.NewPaletteName[1] = '';
    
    gBindings:Save();
    gBindings:Update();
end

local function DeletePalette(index)
    local count = #gBindings.JobBindings.Palettes;
    if (count <= 1) then
        return;
    end
    
    table.remove(gBindings.JobBindings.Palettes, index);
    
    if (state.SelectedPaletteIndex > #gBindings.JobBindings.Palettes) then
        state.SelectedPaletteIndex = #gBindings.JobBindings.Palettes;
    end
    
    if (gBindings.ActivePaletteIndex == index) then
        gBindings.ActivePaletteIndex = 1;
        gBindings.ActivePalette = gBindings.JobBindings.Palettes[1];
    elseif (gBindings.ActivePaletteIndex > index) then
        gBindings.ActivePaletteIndex = gBindings.ActivePaletteIndex - 1;
        gBindings.ActivePalette = gBindings.JobBindings.Palettes[gBindings.ActivePaletteIndex];
    end
    
    gBindings:Save();
    gBindings:Update();
end

local function RenamePalette(index, newName)
    if (newName == nil or newName == '') then
        return;
    end
    
    newName = newName:gsub('^%s+', ''):gsub('%s+$', '');
    if (newName == '') then
        return;
    end
    
    local lowerNew = string.lower(newName);
    for _,palette in ipairs(gBindings.JobBindings.Palettes) do
        if (palette ~= gBindings.JobBindings.Palettes[index] and string.lower(palette.Name) == lowerNew) then
            return;
        end
    end
    
    gBindings.JobBindings.Palettes[index].Name = newName;
    
    gBindings:Save();
end

local function DeleteMacro(hotkey)
    local palette = gBindings.JobBindings.Palettes[state.SelectedPaletteIndex];
    if (palette and palette.Bindings[hotkey]) then
        palette.Bindings[hotkey] = nil;
        
        gBindings:Save();
        gBindings:Update();
    end
end

local macroComboBinds = {
    [1] = 'LT',
    [2] = 'RT',
    [3] = 'LTRT',
    [4] = 'RTLT',
    [5] = 'LT2',
    [6] = 'RT2'
};

local macroButtons = {
    'Top',
    'Right',
    'Bottom',
    'Left'
};

local function GetMacroStateFromHotkey(hotkey)
    local parts = hotkey:split(':');
    if (#parts ~= 2) then
        return 1, 'Top';
    end
    
    local combo = parts[1];
    local button = parts[2];
    
    local macroState = 1;
    for i, cb in ipairs(macroComboBinds) do
        if (cb == combo) then
            macroState = i;
            break;
        end
    end
    
    local macroButton = 'Top';
    for _, mb in ipairs(macroButtons) do
        if (mb == button) then
            macroButton = mb;
            break;
        end
    end
    
    return macroState, macroButton;
end

local exposed = {};

function exposed:Render()
    RefreshPalettes();
    
    if (not gBindings or not gBindings.JobBindings or not gBindings.JobBindings.Palettes) then
        imgui.Text('No character loaded. Please wait for character selection.');
        return;
    end
    
    local availX, availY = imgui.GetContentRegionAvail();
    
    imgui.BeginChild('PaletteManagerChild', { 0, 0 }, ImGuiChildFlags_Borders);
    
    local palettes = gBindings.JobBindings.Palettes;
    local paletteCount = palettes and #palettes or 0;
    
    imgui.TextColored(header, 'Palettes');
    
    imgui.BeginGroup();
    if (imgui.Button('Add', { 50, 0 })) then
        state.NewPaletteName[1] = '';
    end
    imgui.ShowHelp('Creates a new palette.', true);
    imgui.SameLine();
    imgui.PushItemWidth(120);
    imgui.InputText('##NewPaletteName', state.NewPaletteName, 32);
    imgui.PopItemWidth();
    imgui.SameLine();
    if (imgui.Button('Create', { 50, 0 })) then
        AddPalette();
    end
    imgui.SameLine();
    if (imgui.Button('Rename', { 55, 0 })) then
        if (palettes and palettes[state.SelectedPaletteIndex]) then
            state.RenamingPaletteIndex = state.SelectedPaletteIndex;
            state.RenamePaletteName[1] = palettes[state.SelectedPaletteIndex].Name;
        end
    end
    imgui.ShowHelp('Rename the selected palette (or right-click).', true);
    imgui.SameLine();
    local canDelete = paletteCount > 1;
    if (not canDelete) then
        imgui.PushStyleVar(ImGuiStyleVar_Alpha, 0.5);
    end
    if (imgui.Button('Delete', { 55, 0 })) then
        if (canDelete) then
            state.ShowDeleteConfirm = true;
            state.DeleteTargetIndex = state.SelectedPaletteIndex;
        end
    end
    if (not canDelete) then
        imgui.PopStyleVar();
    end
    imgui.ShowHelp(canDelete and 'Delete the selected palette.' or 'Cannot delete the last palette.', true);
    if (state.SelectedPaletteIndex ~= gBindings.ActivePaletteIndex) then
        imgui.SameLine();
        if (imgui.Button('Set Active', { 70, 0 }) and palettes and palettes[state.SelectedPaletteIndex]) then
            gBindings.ActivePaletteIndex = state.SelectedPaletteIndex;
            gBindings.ActivePalette = palettes[state.SelectedPaletteIndex];
            gBindings:Update();
        end
        imgui.ShowHelp('Set this palette as the active palette.', true);
    end
    imgui.EndGroup();
    
    imgui.Separator();
    
    local panelHeight = availY - 80;
    
    imgui.Columns(2, 'PaletteColumns', false);
    
    imgui.BeginGroup();
    imgui.TextColored(header, 'Palette List');
    imgui.BeginChild('PaletteListChild', { -1, panelHeight }, ImGuiChildFlags_Borders);
    
    for index, palette in ipairs(palettes) do
        local isSelected = (index == state.SelectedPaletteIndex);
        local isActive = (index == gBindings.ActivePaletteIndex);
        local label = palette.Name;
        if (isActive) then
            label = label .. ' *';
        end
        
        if (state.RenamingPaletteIndex == index) then
            imgui.PushID('Rename_' .. index);
            if (imgui.InputText('##RenamePalette', state.RenamePaletteName, 32, ImGuiInputTextFlags_EnterReturnsTrue)) then
                RenamePalette(index, state.RenamePaletteName[1]);
                state.RenamingPaletteIndex = 0;
                state.RenamePaletteName[1] = '';
            end
            imgui.PopID();
        else
            if (imgui.Selectable(label, isSelected, ImGuiSelectableFlags_AllowDoubleClick)) then
                state.SelectedPaletteIndex = index;
            end
            if (imgui.IsItemClicked(1)) then
                state.RenamingPaletteIndex = index;
                state.RenamePaletteName[1] = palette.Name;
            end
        end
    end
    
    imgui.EndChild();
    imgui.EndGroup();
    
    imgui.NextColumn();
    
    imgui.BeginGroup();
    local currentPalette = palettes and palettes[state.SelectedPaletteIndex];
    if (currentPalette) then
        imgui.TextColored(header, string.format('Macros in "%s"', currentPalette.Name));
        imgui.BeginChild('MacroListChild', { -1, panelHeight - 100 }, ImGuiChildFlags_Borders);
        
        if (imgui.BeginTable('MacrosTable', 4, bit.bor(ImGuiTableFlags_Borders, ImGuiTableFlags_Resizable, ImGuiTableFlags_ScrollY, ImGuiTableFlags_RowBg))) then
            imgui.TableSetupColumn('Hotkey', ImGuiTableColumnFlags_WidthFixed, 90);
            imgui.TableSetupColumn('Type', ImGuiTableColumnFlags_WidthFixed, 80);
            imgui.TableSetupColumn('Label', ImGuiTableColumnFlags_WidthStretch);
            imgui.TableSetupColumn('Actions', ImGuiTableColumnFlags_WidthFixed, 70);
            imgui.TableHeadersRow();
            
            local bindings = currentPalette.Bindings;
            local sortedHotkeys = {};
            for hotkey, _ in pairs(bindings) do
                table.insert(sortedHotkeys, hotkey);
            end
            table.sort(sortedHotkeys);
            
            for _, hotkey in ipairs(sortedHotkeys) do
                local binding = bindings[hotkey];
                if (binding) then
                    imgui.TableNextRow();
                    imgui.TableSetColumnIndex(0);
                    imgui.Text(hotkey);
                    imgui.TableSetColumnIndex(1);
                    imgui.Text(binding.ActionType or 'Unknown');
                    imgui.TableSetColumnIndex(2);
                    imgui.Text(binding.Label or '');
                    imgui.TableSetColumnIndex(3);
                    
                    if (imgui.Button(string.format('Edit##Edit_%s', hotkey))) then
                        local macroState, macroButton = GetMacroStateFromHotkey(hotkey);
                        gBindingGUI:Show(macroState, macroButton);
                    end
                    imgui.SameLine();
                    if (imgui.Button(string.format('X##Delete_%s', hotkey))) then
                        DeleteMacro(hotkey);
                    end
                end
            end
            
            imgui.EndTable();
        end
        
        imgui.EndChild();
        
        imgui.TextColored(header, 'Available Slots');
        imgui.BeginChild('AvailableSlotsChild', { -1, 80 }, ImGuiChildFlags_Borders);
        
        local usedSlots = {};
        for hotkey, _ in pairs(currentPalette.Bindings or {}) do
            usedSlots[hotkey] = true;
        end
        
        local slotIndex = 1;
        for macroState = 1, 6 do
            for macroButtonIdx = 1, 4 do
                local hotkey = string.format('%s:%s', macroComboBinds[macroState], macroButtons[macroButtonIdx]);
                if (not usedSlots[hotkey]) then
                    if (imgui.Button(string.format('Add##Add_%s', hotkey))) then
                        gBindingGUI:Show(macroState, macroButtons[macroButtonIdx]);
                    end
                    imgui.SameLine();
                    imgui.Text(string.format('%s:%s', macroComboBinds[macroState], macroButtons[macroButtonIdx]));
                    slotIndex = slotIndex + 1;
                    if (slotIndex > 6) then
                        break;
                    end
                end
            end
            if (slotIndex > 6) then
                break;
            end
        end
        
        imgui.EndChild();
    else
        imgui.Text('No palette selected.');
    end
    imgui.EndGroup();
    
    imgui.Columns(1);
    
    imgui.EndChild();
    
    if (state.ShowDeleteConfirm) then
        imgui.OpenPopup('Delete Palette?');
    end
    
    if (imgui.BeginPopupModal('Delete Palette?', nil, ImGuiWindowFlags_AlwaysAutoResize)) then
        imgui.Text('Are you sure you want to delete this palette?');
        imgui.Text('This action cannot be undone.');
        
        imgui.Text('--------------------------------------------------');
        
        if (imgui.Button('Cancel##CancelDelete', { 80, 0 })) then
            state.ShowDeleteConfirm = false;
            state.DeleteTargetIndex = 0;
            imgui.CloseCurrentPopup();
        end
        imgui.SameLine();
        if (imgui.Button('Delete##ConfirmDelete', { 80, 0 })) then
            DeletePalette(state.DeleteTargetIndex);
            state.ShowDeleteConfirm = false;
            state.DeleteTargetIndex = 0;
            imgui.CloseCurrentPopup();
        end
        
        imgui.EndPopup();
    end
end

function exposed:Show()
    RefreshPalettes();
    state.IsOpen = { true };
    state.NewPaletteName = { '' };
    state.RenamePaletteName = { '' };
    state.ShowDeleteConfirm = false;
    state.DeleteTargetIndex = 0;
    state.RenamingPaletteIndex = 0;
end

return exposed;
