ffi.cdef[[
    typedef struct FontInitializer_t {
        int32_t OffsetX;
        int32_t OffsetY;
        int32_t BoxWidth;
        int32_t BoxHeight;
        int32_t OutlineWidth;
        int32_t FontHeight;
        char FontFamily[256];
        uint32_t FontFlags;
        uint32_t FontAlignment;
        uint32_t FontColor;
        uint32_t OutlineColor;
    } FontInitializer_t;

    typedef struct ImageInitializer_t {
        int32_t OffsetX;
        int32_t OffsetY;
        int32_t Width;
        int32_t Height;
    } ImageInitializer_t;

    typedef struct SquareInitializer_t {
        int32_t OffsetX;
        int32_t OffsetY;
    } SquareInitializer_t;

    typedef struct EventInitializer_t {
        char UniqueIdentifier[256];
        FontInitializer_t Cost;
        FontInitializer_t Macro;
        FontInitializer_t Name;
        FontInitializer_t Recast;
        ImageInitializer_t Frame;
        ImageInitializer_t Icon;
        ImageInitializer_t Overlay;
        float IconFadeAlpha;
        char FramePath[256];
        int32_t PanelHeight;
        int32_t PanelWidth;
        int32_t SquareHeight;
        int32_t SquareWidth;
        int32_t SquareCount;
        SquareInitializer_t Squares[100];
    } EventInitializer_t;

    typedef struct AbilitySquareState_t {
        uint32_t Fade;
        char Cost[32];
        char Hotkey[32];
        char Name[32];
        char Recast[32];
        char IconImage[256];
        char OverlayImage1[256];
        char OverlayImage2[256];
        char OverlayImage3[256];
    } AbilitySquareState_t;

    typedef struct AbilitySquarePanelState_t {
        uint32_t Render;
        int32_t PositionX;
        int32_t PositionY;
        AbilitySquareState_t Squares[100];
    } AbilitySquarePanelState_t;
]];

local function lua_FontInitializerToStruct(font)
    local struct = ffi.new('FontInitializer_t');
    struct.OffsetX = font.OffsetX;
    struct.OffsetY = font.OffsetY;
    struct.BoxWidth = font.BoxWidth;
    struct.BoxHeight = font.BoxHeight;
    struct.OutlineWidth = font.OutlineWidth;
    struct.FontHeight = font.FontHeight;
    struct.FontFamily = font.FontFamily;
    struct.FontFlags = font.FontFlags;
    struct.FontAlignment = font.FontAlignment;
    struct.FontColor = font.FontColor;
    struct.OutlineColor = font.OutlineColor;
    return struct;
end

local function lua_ImageInitializerToStruct(image)
    local struct = ffi.new('ImageInitializer_t');
    struct.OffsetX = image.OffsetX;
    struct.OffsetY = image.OffsetY;
    struct.Width = image.Width;
    struct.Height = image.Height;
    return struct;
end

local function lua_SquareInitializerToStruct(square)
    local struct = ffi.new('SquareInitializer_t');
    struct.OffsetX = square.OffsetX;
    struct.OffsetY = square.OffsetY;
    return struct;
end

local function lua_EventInitializerToStruct(layout, identifier)
    local struct = ffi.new('EventInitializer_t');
    if (identifier ~= nil) then
        struct.UniqueIdentifier = identifier;
    else
        struct.UniqueIdentifier = layout.Path;
    end
    struct.Cost = lua_FontInitializerToStruct(layout.FontObjects.Cost);
    struct.Macro = lua_FontInitializerToStruct(layout.FontObjects.Macro);
    struct.Name = lua_FontInitializerToStruct(layout.FontObjects.Name);
    struct.Recast = lua_FontInitializerToStruct(layout.FontObjects.Recast);
    struct.Frame = lua_ImageInitializerToStruct(layout.ImageObjects.Frame);
    struct.Icon = lua_ImageInitializerToStruct(layout.ImageObjects.Icon);
    struct.Overlay = lua_ImageInitializerToStruct(layout.ImageObjects.Overlay);
    struct.IconFadeAlpha = layout.IconFadeAlpha;
    struct.FramePath = layout.FramePath;
    struct.PanelHeight = layout.PanelHeight;
    struct.PanelWidth = layout.PanelWidth;
    struct.SquareHeight = layout.SquareHeight;
    struct.SquareWidth = layout.SquareWidth;
    struct.SquareCount = 0;
    for _,square in ipairs(layout.Squares) do
        struct.Squares[struct.SquareCount] = lua_SquareInitializerToStruct(square);
        struct.SquareCount = struct.SquareCount + 1;
    end
    return struct;
end

local function LoadLayout(interface, layoutName)
    interface.Layout = nil;

    --Attempt to load layout file.
    local layoutPaths = T{
        string.format('%sconfig/addons/%s/resources/layouts/%s.lua', AshitaCore:GetInstallPath(), addon.name, layoutName),
        string.format('%saddons/%s/resources/layouts/%s.lua', AshitaCore:GetInstallPath(), addon.name, layoutName),
    };

    for _,path in ipairs(layoutPaths) do
        interface.Layout = LoadFile_s(path);
        if (interface.Layout ~= nil) then
            interface.Layout.Name = layoutName;
            interface.Layout.Path = path;
            break;
        end
    end

    if (interface.Layout == nil) then
        return false;
    end
    
    interface.Layout.CrossPath = GetImagePath(interface.Layout.CrossPath);
    if (interface.Layout.CrossPath == nil) then
        interface.Layout.CrossPath = '';
    end
    interface.Layout.TriggerPath = GetImagePath(interface.Layout.TriggerPath);
    if (interface.Layout.TriggerPath == nil) then
        interface.Layout.TriggerPath = '';
    end
    local newPaths = T{};
    for _,value in ipairs(interface.Layout.SkillchainAnimationPaths) do
        local path = GetImagePath(value);
        if (path ~= nil) then
            newPaths:append(path);
        end
    end
    interface.Layout.SkillchainAnimationPaths = newPaths;

    for _,layoutType in ipairs(T{'SingleDisplay', 'DoubleDisplay'}) do
        local layout = interface.Layout[layoutType];
        layout.IconFadeAlpha = interface.Layout.IconFadeAlpha;
        
        for _,primitiveInfo in ipairs(layout.Primitives) do
            if (primitiveInfo.File ~= nil) then
                primitiveInfo.texture = GetImagePath(primitiveInfo.File);
                primitiveInfo.File = nil;
            end
        end

        layout.FramePath = GetImagePath(layout.FramePath);
        if (layout.FramePath == nil) then
            layout.FramePath = '';
        end

        --Fill in position from new layout if necessary..
        if (gSettings.Position[layoutName] == nil) then
            gSettings.Position[layoutName] = {};
        end
        if (gSettings.Position[layoutName][layoutType] == nil) then
            gSettings.Position[layoutName][layoutType] = { layout.DefaultX, layout.DefaultY };
            settings.save();
        end
    end

    return true;
end

local interface = {};
interface.SquareManager = require('square_manager');

function interface:Clear()
    self.StructPointer = nil;
end

function interface:Destroy()
    self.SquareManager:Destroy();
    
    if (self.StructPointer ~= nil) then
        AshitaCore:GetPluginManager():RaiseEvent('tRenderer_Destroy', (self.Layout.Path .. '\x00'):totable());
        self.StructPointer = nil;
    end
end

function interface:GetLayout()
    return self.Layout;
end

function interface:GetSquareManager()
    return self.SquareManager;
end

function interface:HandleEvent(e)
    if (e.name == self.EventIdentifier[1]) and (self.StructPointer[1] == nil) then        
        self.StructPointer[1] = struct.unpack('L', e.data, 1);
    end

    if (e.name == self.EventIdentifier[2]) and (self.StructPointer[1] ~= nil) and (self.StructPointer[2] == nil) then
        self.StructPointer[2] = struct.unpack('L', e.data, 1);
        self.SquareManager:Initialize(self.Layout, self.StructPointer[1], self.StructPointer[2]);
        gBindings:Update();
        gSettings.Layout = self.Layout.Name;
        settings.save();
    end
end

function interface:Initialize(layoutName)
    if (self.Initializer ~= nil) and (self.StructPointer == nil) then
        Error('Could not load layout.  Please wait for last layout to finish loading then manually apply layout via $H/tb$R.');
        return;
    end

    self.Initializer = nil;
    if (self.StructPointer ~= nil) then
        self.SquareManager:Destroy();
        AshitaCore:GetPluginManager():RaiseEvent('tRenderer_Destroy', (self.Layout.Path .. '\x00'):totable());
        self.StructPointer = nil;
    end

    if (LoadLayout(self, layoutName)) then
        self.Initializer = T{
            lua_EventInitializerToStruct(self.Layout.SingleDisplay, string.format('%s_Single', self.Layout.Path)),
            lua_EventInitializerToStruct(self.Layout.DoubleDisplay, string.format('%s_Double', self.Layout.Path))
        };
        self.EventIdentifier = {
            string.format('tRenderer_Accessor_%s_Single', self.Layout.Path),
            string.format('tRenderer_Accessor_%s_Double', self.Layout.Path)
        };

        ashita.events.register('plugin_event', 'interface_event_cb', (function (self, e)
            self:HandleEvent(e);
        end):bind1(self));
    else
        Error(string.format('Failed to load layout $H%s$R.  Please select a layout via $H/tb$R.', layoutName));
    end
end

function interface:Tick()
    if (self.Initializer == nil) then
        return;
    end

    if (self.StructPointer == nil) then
        self.StructPointer = T{};
    end

    if (self.StructPointer[1] == nil) then
        local eventStruct = ffi.string(self.Initializer[1], ffi.sizeof(self.Initializer[1])):totable();
        AshitaCore:GetPluginManager():RaiseEvent('tRenderer_Initialize', eventStruct);
        return;
    end    

    if (self.StructPointer[2] == nil) then
        local eventStruct = ffi.string(self.Initializer[2], ffi.sizeof(self.Initializer[2])):totable();
        AshitaCore:GetPluginManager():RaiseEvent('tRenderer_Initialize', eventStruct);
        return;
    end

    self.SquareManager:Tick();
end

return interface;