function GetImagePath(image, default)
    if (string.sub(image, 1, 5) == 'ITEM:') then
        return image;
    end
    
    if (string.sub(image, 1, 7) == 'STATUS:') then
        return image;
    end
    
    local potentialPaths = T{
        image,
        string.format('%sconfig/addons/%s/resources/%s', AshitaCore:GetInstallPath(), addon.name, image),
        string.format('%saddons/%s/resources/%s', AshitaCore:GetInstallPath(), addon.name, image),
        default or '',
        string.format('%sconfig/addons/%s/resources/misc/unknown.png', AshitaCore:GetInstallPath(), addon.name),
        string.format('%saddons/%s/resources/misc/unknown.png', AshitaCore:GetInstallPath(), addon.name),
    };

    for _,path in ipairs(potentialPaths) do
        if (path ~= '') and (ashita.fs.exists(path)) then
            return path;
        end
    end

    return nil;
end

function GetResourcePath(resource)
    local potentialPaths = T{
        resource,
        string.format('%sconfig/addons/%s/resources/%s', AshitaCore:GetInstallPath(), addon.name, resource),
        string.format('%sconfig/addons/%s/resources/%s.lua', AshitaCore:GetInstallPath(), addon.name, resource),
        string.format('%saddons/%s/resources/%s', AshitaCore:GetInstallPath(), addon.name, resource),
        string.format('%saddons/%s/resources/%s.lua', AshitaCore:GetInstallPath(), addon.name, resource)
    };

    for _,path in ipairs(potentialPaths) do
        if (path ~= '') and (ashita.fs.exists(path)) then
            return path;
        end
    end
end

function LoadFile_s(filePath)
    if (filePath == nil) then
        return nil;
    end
    
    if not ashita.fs.exists(filePath) then
        return nil;
    end

    local success, loadError = loadfile(filePath);
    if not success then
        Error(string.format('Failed to load resource file: $H%s', filePath));
        Error(loadError);
        return nil;
    end

    local result, output = pcall(success);
    if not result then
        Error(string.format('Failed to execute resource file: $H%s', filePath));
        Error(loadError);
        return nil;
    end

    return output;
end