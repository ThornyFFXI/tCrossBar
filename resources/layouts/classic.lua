local theme = {
    --[[
        Path to images..
        First checks absolute path.
        Next checks: ashita/config/addons/addonname/resources/
        Finally checks: ashita/addons/addonname/resources/
    ]]--
    CrossPath = 'misc/cross.png',
    TriggerPath = 'misc/trigger.png',

    --This is checked the same way, and can contain any amount of frames.  Frames cycle back to first after last is completed.
    SkillchainAnimationPaths = T{
        'misc/crawl1.png',
        'misc/crawl2.png',
        'misc/crawl3.png',
        'misc/crawl4.png',
        'misc/crawl5.png',
        'misc/crawl6.png',
        'misc/crawl7.png'
    },

    --Display used when showing a specific macro combination, 8 button squares total.
    SingleDisplay = {
        FontObjects = {
            --[[
                OffsetX: Distance from the top left of individual square object.
                OffsetY: Distance from the top right of individual square object.
                BoxWidth: Width of the box for text to be drawn into.
                BoxHeight: Height of the box for text to be drawn into.
                OutlineWidth: Width of the text outline.
                FontHeight: Height of the font.
                FontFamily: Font Family.
                FontFlags: bitflags for font modifiers
                0x01 - Bold
                0x02 - Italic
                0x04 - Underline
                0x08 - Strikeout
                FontAlignment: Font alignment within the box
                0x00 - Left Aligned
                0x01 - Center Aligned
                0x02 - Right Aligned
                FontColor - Hex ARGB value, highest significance byte is alpha.
                OutlineColor - Hex ARGB value, highest significance byte is alpha.
            ]]--
            Cost = {
                OffsetX = 11,
                OffsetY = 31,
                BoxWidth = 40,
                BoxHeight = 9,
                OutlineWidth = 2,
                FontHeight = 9,
                FontFamily = 'Arial',
                FontFlags = 0,
                FontAlignment = 2,
                FontColor = 0xFF389609,
                OutlineColor = 0xFF000000,
            },
            Macro = {
                OffsetX = 11,
                OffsetY = 2,
                BoxWidth = 40,
                BoxHeight = 13,
                OutlineWidth = 1,
                FontHeight = 12,
                FontFamily = 'Arial',
                FontFlags = 0,
                FontAlignment = 0,
                FontColor = 0xFFFFFFFF,
                OutlineColor = 0xFF000000,
            },
            Name = {
                OffsetX = 0,
                OffsetY = 44,
                BoxWidth = 58,
                BoxHeight = 12,
                OutlineWidth = 2,
                FontHeight = 9,
                FontFamily = 'Arial',
                FontFlags = 0,
                FontAlignment = 1,
                FontColor = 0xFFFFFFFF,
                OutlineColor = 0xFF000000,
            },
            Recast = {
                OffsetX = 11,
                OffsetY = 31,
                BoxWidth = 40,
                BoxHeight = 9,
                OutlineWidth = 2,
                FontHeight = 9,
                FontFamily = 'Arial',
                FontFlags = 0,
                FontAlignment = 0,
                FontColor = 0xFFBFCC04,
                OutlineColor = 0xFF000000,
            },
        },

        ImageObjects = {
            --[[
                OffsetX: Distance from the top left of individual square object.
                OffsetY: Distance from the top right of individual square object.
                Width: Width of image to be drawn.
                Height: Height of image to be drawn.
            ]]--
            Frame = {
                OffsetX = 9,
                OffsetY = 0,
                Width = 44,
                Height = 44
            },
            Icon = {
                OffsetX = 11,
                OffsetY = 2,
                Width = 40,
                Height = 40
            },
            Overlay = {
                OffsetX = 11,
                OffsetY = 2,
                Width = 40,
                Height = 40
            },
        },

        Primitives = {
            {
                File            = 'misc/dpad.png',
                OffsetX         = 69,
                OffsetY         = 57,
                texture         = nil,
                texture_offset_x= 0.0,
                texture_offset_y= 0.0,
                border_visible  = false,
                border_color    = 0x00000000,
                border_flags    = FontBorderFlags.None,
                border_sizes    = '0,0,0,0',
                visible         = true,
                position_x      = 0,
                position_y      = 0,
                can_focus       = false,
                locked          = false,
                lockedz         = false,
                scale_x         = 1.0,
                scale_y         = 1.0,
                width           = 40,
                height          = 40,
                color           = 0xFFFFFFFF,
            },
            {
                File            = 'misc/buttons.png',
                OffsetX         = 243,
                OffsetY         = 57,
                texture         = nil,
                texture_offset_x= 0.0,
                texture_offset_y= 0.0,
                border_visible  = false,
                border_color    = 0x00000000,
                border_flags    = FontBorderFlags.None,
                border_sizes    = '0,0,0,0',
                visible         = true,
                position_x      = 0,
                position_y      = 0,
                can_focus       = false,
                locked          = false,
                lockedz         = false,
                scale_x         = 1.0,
                scale_y         = 1.0,
                width           = 40,
                height          = 40,
                color           = 0xFFFFFFFF,
            },
        },

        --Path to frame image
        FramePath = 'misc/frame.png',

        --Level of transparency to be used for icons that are faded(due to recast down, or ability cost not met).
        IconFadeAlpha = 0.5,

        --Time, in seconds, to wait between advancing frames of skillchain animation.
        SkillchainAnimationTime = 0.08,

        --Height of the full graphics object used to render all squares.  All squares *MUST* fully fit within this panel.
        PanelHeight = 168,

        --Width of the full graphics object used to render all squares.  All squares *MUST* fully fit within this panel.
        PanelWidth = 358,

        --Default position for object.  Set later in this theme using scaling lib.
        DefaultX = 0,
        DefaultY = 0,

        --Height of an individual square object.
        SquareHeight = 58,

        --Width of an individual square object.
        SquareWidth = 58,

        --[[
            Table of square objects, where each entry must be a table with attributes PositionX, PositionY.
            Objects are ordered(according to default controller layout):
                1. Dpad Up
                2. Dpad Right
                3. Dpad Down
                4. Dpad Left
                5. Button Up
                6. Button Right
                7. Button Down
                8. Button Left
            Must remain 8 objects.
        ]]--
        
        Squares = T{
            { OffsetX = 58, OffsetY = 0 },
            { OffsetX = 116, OffsetY = 55 },
            { OffsetX = 58, OffsetY = 110 },
            { OffsetX = 0, OffsetY = 55 },
            { OffsetX = 232, OffsetY = 0 },
            { OffsetX = 290, OffsetY = 55 },
            { OffsetX = 232, OffsetY = 110 },
            { OffsetX = 174, OffsetY = 55 },
        },
    },
    --Display used when showing default display, 16 button squares total.
    DoubleDisplay = {
        FontObjects = {
            --[[
                OffsetX: Distance from the top left of individual square object.
                OffsetY: Distance from the top right of individual square object.
                BoxWidth: Width of the box for text to be drawn into.
                BoxHeight: Height of the box for text to be drawn into.
                OutlineWidth: Width of the text outline.
                FontHeight: Height of the font.
                FontFamily: Font Family.
                FontFlags: bitflags for font modifiers
                0x01 - Bold
                0x02 - Italic
                0x04 - Underline
                0x08 - Strikeout
                FontAlignment: Font alignment within the box
                0x00 - Left Aligned
                0x01 - Center Aligned
                0x02 - Right Aligned
                FontColor - Hex ARGB value, highest significance byte is alpha.
                OutlineColor - Hex ARGB value, highest significance byte is alpha.
            ]]--
            Cost = {
                OffsetX = 11,
                OffsetY = 31,
                BoxWidth = 40,
                BoxHeight = 9,
                OutlineWidth = 2,
                FontHeight = 9,
                FontFamily = 'Arial',
                FontFlags = 0,
                FontAlignment = 2,
                FontColor = 0xFF389609,
                OutlineColor = 0xFF000000,
            },
            Macro = {
                OffsetX = 11,
                OffsetY = 2,
                BoxWidth = 40,
                BoxHeight = 13,
                OutlineWidth = 1,
                FontHeight = 12,
                FontFamily = 'Arial',
                FontFlags = 0,
                FontAlignment = 0,
                FontColor = 0xFFFFFFFF,
                OutlineColor = 0xFF000000,
            },
            Name = {
                OffsetX = 0,
                OffsetY = 44,
                BoxWidth = 58,
                BoxHeight = 12,
                OutlineWidth = 2,
                FontHeight = 9,
                FontFamily = 'Arial',
                FontFlags = 0,
                FontAlignment = 1,
                FontColor = 0xFFFFFFFF,
                OutlineColor = 0xFF000000,
            },
            Recast = {
                OffsetX = 11,
                OffsetY = 31,
                BoxWidth = 40,
                BoxHeight = 9,
                OutlineWidth = 2,
                FontHeight = 9,
                FontFamily = 'Arial',
                FontFlags = 0,
                FontAlignment = 0,
                FontColor = 0xFFBFCC04,
                OutlineColor = 0xFF000000,
            },
        },

        ImageObjects = {
            --[[
                OffsetX: Distance from the top left of individual square object.
                OffsetY: Distance from the top right of individual square object.
                Width: Width of image to be drawn.
                Height: Height of image to be drawn.
            ]]--
            Frame = {
                OffsetX = 9,
                OffsetY = 0,
                Width = 44,
                Height = 44
            },
            Icon = {
                OffsetX = 11,
                OffsetY = 2,
                Width = 40,
                Height = 40
            },
            Overlay = {
                OffsetX = 11,
                OffsetY = 2,
                Width = 40,
                Height = 40
            },
        },

        --[[
        Primitive objects to be drawn after drawing squares.
        File will be resolved to resources directory(config then addon).
        OffsetX and OffsetY are used for positioning.
        All other fields are carried over to ashita's primitive library.
        ]]--
        Primitives = {
            {
                File            = 'misc/dpad.png',
                OffsetX         = 69,
                OffsetY         = 57,
                texture         = nil,
                texture_offset_x= 0.0,
                texture_offset_y= 0.0,
                border_visible  = false,
                border_color    = 0x00000000,
                border_flags    = FontBorderFlags.None,
                border_sizes    = '0,0,0,0',
                visible         = true,
                position_x      = 0,
                position_y      = 0,
                can_focus       = false,
                locked          = false,
                lockedz         = false,
                scale_x         = 1.0,
                scale_y         = 1.0,
                width           = 40,
                height          = 40,
                color           = 0xFFFFFFFF,
            },
            {
                File            = 'misc/buttons.png',
                OffsetX         = 243,
                OffsetY         = 57,
                texture         = nil,
                texture_offset_x= 0.0,
                texture_offset_y= 0.0,
                border_visible  = false,
                border_color    = 0x00000000,
                border_flags    = FontBorderFlags.None,
                border_sizes    = '0,0,0,0',
                visible         = true,
                position_x      = 0,
                position_y      = 0,
                can_focus       = false,
                locked          = false,
                lockedz         = false,
                scale_x         = 1.0,
                scale_y         = 1.0,
                width           = 40,
                height          = 40,
                color           = 0xFFFFFFFF,
            },
            {
                File            = 'misc/dpad.png',
                OffsetX         = 457,
                OffsetY         = 57,
                texture         = nil,
                texture_offset_x= 0.0,
                texture_offset_y= 0.0,
                border_visible  = false,
                border_color    = 0x00000000,
                border_flags    = FontBorderFlags.None,
                border_sizes    = '0,0,0,0',
                visible         = true,
                position_x      = 0,
                position_y      = 0,
                can_focus       = false,
                locked          = false,
                lockedz         = false,
                scale_x         = 1.0,
                scale_y         = 1.0,
                width           = 40,
                height          = 40,
                color           = 0xFFFFFFFF,
            },
            {
                File            = 'misc/buttons.png',
                OffsetX         = 631,
                OffsetY         = 57,
                texture         = nil,
                texture_offset_x= 0.0,
                texture_offset_y= 0.0,
                border_visible  = false,
                border_color    = 0x00000000,
                border_flags    = FontBorderFlags.None,
                border_sizes    = '0,0,0,0',
                visible         = true,
                position_x      = 0,
                position_y      = 0,
                can_focus       = false,
                locked          = false,
                lockedz         = false,
                scale_x         = 1.0,
                scale_y         = 1.0,
                width           = 40,
                height          = 40,
                color           = 0xFFFFFFFF,
            },
        },

        --Path to frame image
        FramePath = 'misc/frame.png',

        --Level of transparency to be used for icons that are faded(due to recast down, or ability cost not met).
        IconFadeAlpha = 0.5,
        
        --Time, in seconds, to wait between advancing frames of skillchain animation.
        SkillchainAnimationTime = 0.08,

        --Height of the full graphics object used to render all squares.  All squares *MUST* fully fit within this panel.
        PanelHeight = 168,

        --Width of the full graphics object used to render all squares.  All squares *MUST* fully fit within this panel.
        PanelWidth = 746,

        --Default position for object.  Set later in this theme using scaling lib.
        DefaultX = 0,
        DefaultY = 0,

        --Height of an individual square object.
        SquareHeight = 58,

        --Width of an individual square object.
        SquareWidth = 58,


        --[[
            Table of square objects, where each entry must be a table with attributes PositionX, PositionY.
            Objects are ordered(according to default controller layout):
                1.  Dpad Up(L2)
                2.  Dpad Right(L2)
                3.  Dpad Down(L2)
                4.  Dpad Left(L2)
                5.  Button Up(L2)
                6.  Button Right(L2)
                7.  Button Down(L2)
                8.  Button Left(L2)
                9.  Dpad Up(R2)
                10. Dpad Right(R2)
                11. Dpad Down(R2)
                12. Dpad Left(R2)
                13. Button Up(R2)
                14. Button Right(R2)
                15. Button Down(R2)
                16. Button Left(R2)
            Must remain 16 objects.
        ]]--
        
        Squares = T{
            { OffsetX = 58, OffsetY = 0 },
            { OffsetX = 116, OffsetY = 55 },
            { OffsetX = 58, OffsetY = 110 },
            { OffsetX = 0, OffsetY = 55 },
            { OffsetX = 232, OffsetY = 0 },
            { OffsetX = 290, OffsetY = 55 },
            { OffsetX = 232, OffsetY = 110 },
            { OffsetX = 174, OffsetY = 55 },
            { OffsetX = 446, OffsetY = 0 },
            { OffsetX = 504, OffsetY = 55 },
            { OffsetX = 446, OffsetY = 110 },
            { OffsetX = 388, OffsetY = 55 },
            { OffsetX = 620, OffsetY = 0 },
            { OffsetX = 678, OffsetY = 55 },
            { OffsetX = 620, OffsetY = 110 },
            { OffsetX = 562, OffsetY = 55 },
        },
    },

};

local scaling = require('scaling');
if ((scaling.window.w == -1) or (scaling.window.h == -1) or (scaling.menu.w == -1) or (scaling.menu.h == -1)) then
    theme.SingleDisplay.DefaultX = 0;
    theme.SingleDisplay.DefaultY = 0;
    theme.DoubleDisplay.DefaultX = 0;
    theme.DoubleDisplay.DefaultY = 0;
else
    theme.SingleDisplay.DefaultX = (scaling.window.w - theme.SingleDisplay.PanelWidth) / 2;
    theme.SingleDisplay.DefaultY = scaling.window.h - (scaling.scale_height(136) + theme.SingleDisplay.PanelHeight);
    theme.DoubleDisplay.DefaultX = (scaling.window.w - theme.DoubleDisplay.PanelWidth) / 2;
    theme.DoubleDisplay.DefaultY = scaling.window.h - (scaling.scale_height(136) + theme.DoubleDisplay.PanelHeight);
end

return theme;