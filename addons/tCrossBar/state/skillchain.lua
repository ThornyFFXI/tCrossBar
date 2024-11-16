local Resonation = T{
    None = 0,
    Liquefaction = 1,
    Induration = 2,
    Detonation = 3,
    Scission = 4,
    Impaction = 5,
    Reverberation = 6,
    Transfixion = 7,
    Compression = 8,
    Fusion = 9,
    Gravitation = 10,
    Distortion = 11,
    Fragmentation = 12,
    Light = 13,
    Darkness = 14,
    Light2 = 15,
    Darkness2 = 16,
    Radiance = 17,
    Umbra = 18
};
local names = T{
    'Liquefaction',
    'Induration',
    'Detonation',
    'Scission',
    'Impaction',
    'Reverberation',
    'Transfixion',
    'Compression',
    'Fusion',
    'Gravitation',
    'Distortion',
    'Fragmentation',
    'Light',
    'Darkness',
    'Light',
    'Darkness',
    'Light',
    'Darkness',
};

local possibleSkillchains = T{
    { Resonation.Light, Resonation.Light, Resonation.Light },
    { Resonation.Light, Resonation.Fragmentation, Resonation.Fusion },
    { Resonation.Light, Resonation.Fusion, Resonation.Fragmentation },
    { Resonation.Darkness, Resonation.Darkness, Resonation.Darkness },
    { Resonation.Darkness, Resonation.Distortion, Resonation.Gravitation },
    { Resonation.Darkness, Resonation.Gravitation, Resonation.Distortion },
    { Resonation.Fusion, Resonation.Liquefaction, Resonation.Impaction },
    { Resonation.Fusion, Resonation.Distortion, Resonation.Fusion },
    { Resonation.Gravitation, Resonation.Detonation, Resonation.Compression },
    { Resonation.Gravitation, Resonation.Fusion, Resonation.Gravitation },
    { Resonation.Distortion, Resonation.Transfixion, Resonation.Scission },
    { Resonation.Distortion, Resonation.Fragmentation, Resonation.Distortion },
    { Resonation.Fragmentation, Resonation.Induration, Resonation.Reverberation },
    { Resonation.Fragmentation, Resonation.Gravitation, Resonation.Fragmentation },
    { Resonation.Liquefaction, Resonation.Impaction, Resonation.Liquefaction },
    { Resonation.Liquefaction, Resonation.Scission, Resonation.Liquefaction },
    { Resonation.Scission, Resonation.Liquefaction, Resonation.Scission },
    { Resonation.Scission, Resonation.Detonation, Resonation.Scission },
    { Resonation.Reverberation, Resonation.Scission, Resonation.Reverberation },
    { Resonation.Reverberation, Resonation.Transfixion, Resonation.Reverberation },
    { Resonation.Detonation, Resonation.Scission, Resonation.Detonation },
    { Resonation.Detonation, Resonation.Impaction, Resonation.Detonation },
    { Resonation.Detonation, Resonation.Compression, Resonation.Detonation },
    { Resonation.Induration, Resonation.Reverberation, Resonation.Induration },
    { Resonation.Impaction, Resonation.Reverberation, Resonation.Impaction },
    { Resonation.Impaction, Resonation.Induration, Resonation.Impaction },
    { Resonation.Transfixion, Resonation.Compression, Resonation.Transfixion },
    { Resonation.Compression, Resonation.Transfixion, Resonation.Compression },
    { Resonation.Compression, Resonation.Induration, Resonation.Compression }   
}

local skillchainMessageIds = T{
    [288] = Resonation.Light,
    [289] = Resonation.Darkness,
    [290] = Resonation.Gravitation,
    [291] = Resonation.Fragmentation,
    [292] = Resonation.Distortion,
    [293] = Resonation.Fusion,
    [294] = Resonation.Compression,
    [295] = Resonation.Liquefaction,
    [296] = Resonation.Induration,
    [297] = Resonation.Reverberation,
    [298] = Resonation.Transfixion,
    [299] = Resonation.Scission,
    [300] = Resonation.Detonation,
    [301] = Resonation.Impaction,
    [385] = Resonation.Light,
    [386] = Resonation.Darkness,
    [387] = Resonation.Gravitation,
    [388] = Resonation.Fragmentation,
    [389] = Resonation.Distortion,
    [390] = Resonation.Fusion,
    [391] = Resonation.Compression,
    [392] = Resonation.Liquefaction,
    [393] = Resonation.Induration,
    [394] = Resonation.Reverberation,
    [395] = Resonation.Transfixion,
    [396] = Resonation.Scission,
    [397] = Resonation.Detonation,
    [398] = Resonation.Impaction,
    [767] = Resonation.Radiance,
    [768] = Resonation.Umbra,
    [769] = Resonation.Radiance,
    [770] = Resonation.Umbra
};

local weaponskillMessageIds = T{
    103, --"${actor} uses ${weapon_skill}.${lb}${target} recovers ${number} HP."
    185, --"${actor} uses ${weapon_skill}.${lb}${target} takes ${number} points of damage."
    187, --"${actor} uses ${weapon_skill}.${lb}${number} HP drained from ${target}."
    238  --"${actor} uses ${weapon_skill}.${lb}${target} recovers ${number} HP."
};

local immanenceMap = T{};
local immanenceResonationMap = T{
    [144] = T{ Resonation.Liquefaction }, --Fire
    [145] = T{ Resonation.Liquefaction }, --Fire II
    [146] = T{ Resonation.Liquefaction }, --Fire III
    [147] = T{ Resonation.Liquefaction }, --Fire IV
    [148] = T{ Resonation.Liquefaction }, --Fire V
    [149] = T{ Resonation.Induration }, --Blizzard
    [150] = T{ Resonation.Induration }, --Blizzard II
    [151] = T{ Resonation.Induration }, --Blizzard III
    [152] = T{ Resonation.Induration }, --Blizzard IV
    [153] = T{ Resonation.Induration }, --Blizzard V
    [154] = T{ Resonation.Detonation }, --Aero
    [155] = T{ Resonation.Detonation }, --Aero II
    [156] = T{ Resonation.Detonation }, --Aero III
    [157] = T{ Resonation.Detonation }, --Aero IV
    [158] = T{ Resonation.Detonation }, --Aero V
    [159] = T{ Resonation.Scission }, --Stone
    [160] = T{ Resonation.Scission }, --Stone II
    [161] = T{ Resonation.Scission }, --Stone III
    [162] = T{ Resonation.Scission }, --Stone IV
    [163] = T{ Resonation.Scission }, --Stone V
    [164] = T{ Resonation.Impaction }, --Thunder
    [165] = T{ Resonation.Impaction }, --Thunder II
    [166] = T{ Resonation.Impaction }, --Thunder III
    [167] = T{ Resonation.Impaction }, --Thunder IV
    [168] = T{ Resonation.Impaction }, --Thunder V
    [169] = T{ Resonation.Reverberation }, --Water
    [170] = T{ Resonation.Reverberation }, --Water II
    [171] = T{ Resonation.Reverberation }, --Water III
    [172] = T{ Resonation.Reverberation }, --Water IV
    [173] = T{ Resonation.Reverberation }, --Water V
    [278] = T{ Resonation.Scission }, --Geohelix
    [279] = T{ Resonation.Reverberation }, --Hydrohelix
    [280] = T{ Resonation.Detonation }, --Anemohelix
    [281] = T{ Resonation.Liquefaction }, --Pyrohelix
    [282] = T{ Resonation.Induration }, --Cryohelix
    [283] = T{ Resonation.Impaction }, --Ionohelix
    [284] = T{ Resonation.Compression }, --Noctohelix
    [285] = T{ Resonation.Transfixion }, --Luminohelix
    [503] = T{ Resonation.Compression } --Impact
};

local playerBuffTable = T{};
local partyBuffTable = T{};
local estimatedBuffMap = T{};
local chainAffinityResonationMap = T{
    [519] = T{ Resonation.Transfixion, Resonation.Scission }, --Screwdriver
    [527] = T{ Resonation.Detonation }, --Smite of Rage
    [529] = T{ Resonation.Liquefaction }, --Bludgeon
    [539] = T{ Resonation.Compression, Resonation.Reverberation }, --Terror Touch
    [540] = T{ Resonation.Scission, Resonation.Detonation }, --Spinal Cleave
    [543] = T{ Resonation.Induration }, --Mandibular Bite
    [545] = T{ Resonation.Compression }, --Sickle Slash
    [551] = T{ Resonation.Reverberation }, --Power Attack
    [554] = T{ Resonation.Compression, Resonation.Reverberation }, --Death Scissors
    [560] = T{ Resonation.Induration }, --Frenetic Rip
    [564] = T{ Resonation.Impaction }, --Body Slam
    [567] = T{ Resonation.Transfixion }, --Helldive
    [569] = T{ Resonation.Impaction }, --Jet Stream
    [577] = T{ Resonation.Detonation }, --Foot Kick
    [585] = T{ Resonation.Fragmentation }, --Ram Charge
    [587] = T{ Resonation.Scission }, --Claw Cyclone
    [589] = T{ Resonation.Transfixion, Resonation.Impaction }, --Dimensional Death
    [594] = T{ Resonation.Liquefaction, Resonation.Impaction }, --Uppercut
    [596] = T{ Resonation.Liquefaction }, --Pinecone Bomb
    [597] = T{ Resonation.Reverberation }, --Sprout Smack
    [599] = T{ Resonation.Compression }, --Queasyshroom
    [603] = T{ Resonation.Transfixion }, --Wild Oats
    [611] = T{ Resonation.Distortion }, --Disseverment
    [617] = T{ Resonation.Gravitation }, --Vertical Cleave
    [620] = T{ Resonation.Impaction }, --Battle Dance
    [622] = T{ Resonation.Induration }, --Grand Slam
    [623] = T{ Resonation.Impaction }, --Head Butt
    [628] = T{ Resonation.Impaction }, --Frypan
    [631] = T{ Resonation.Reverberation }, --Hydro Shot
    [638] = T{ Resonation.Transfixion }, --Feather Storm
    [640] = T{ Resonation.Reverberation }, --Tail Slap
    [641] = T{ Resonation.Detonation }, --Hysteric Barrage
    [643] = T{ Resonation.Fusion }, --Cannonball
    [650] = T{ Resonation.Induration, Resonation.Detonation }, --Seedspray
    [652] = T{ Resonation.Transfixion }, --Spiral Spin
    [653] = T{ Resonation.Liquefaction, Resonation.Impaction }, --Asuran Claws
    [654] = T{ Resonation.Fragmentation }, --Sub\-zero Smash
    [665] = T{ Resonation.Fusion }, --Final Sting
    [666] = T{ Resonation.Fusion, Resonation.Impaction }, --Goblin Rush
    [667] = T{ Resonation.Transfixion, Resonation.Scission }, --Vanity Dive
    [669] = T{ Resonation.Scission, Resonation.Detonation }, --Whirl of Rage
    [670] = T{ Resonation.Gravitation, Resonation.Transfixion }, --Benthic Typhoon
    [673] = T{ Resonation.Distortion, Resonation.Scission }, --Quad. Continuum
    [677] = T{ Resonation.Compression, Resonation.Scission }, --Empty Thrash
    [682] = T{ Resonation.Liquefaction, Resonation.Detonation }, --Delta Thrust
    [688] = T{ Resonation.Fragmentation, Resonation.Transfixion }, --Heavy Strike
    [692] = T{ Resonation.Detonation }, --Sudden Lunge
    [693] = T{ Resonation.Liquefaction, Resonation.Scission, Resonation.Impaction }, --Quadrastrike
    [697] = T{ Resonation.Gravitation }, --Amorphic Spikes
    [699] = T{ Resonation.Distortion, Resonation.Scission }, --Barbed Crescent
    [704] = T{ Resonation.Gravitation }, --Paralyzing Triad
    [706] = T{ Resonation.Fragmentation }, --Glutinous Dart
    [709] = T{ Resonation.Fusion }, --Thrashing Assault
    [714] = T{ Resonation.Gravitation, Resonation.Reverberation }, --Sinker Drill
    [723] = T{ Resonation.Fragmentation, Resonation.Distortion }, --Saurian Slide
    [740] = T{ Resonation.Light, Resonation.Fragmentation }, --Tourbillion
    [742] = T{ Resonation.Darkness, Resonation.Gravitation }, --Bilgestorm
    [743] = T{ Resonation.Darkness, Resonation.Distortion }, --Bloodrake
    [885] = T{ Resonation.Scission }, --Geohelix II
    [886] = T{ Resonation.Reverberation }, --Hydrohelix II
    [887] = T{ Resonation.Detonation }, --Anemohelix II
    [888] = T{ Resonation.Liquefaction }, --Pyrohelix II
    [889] = T{ Resonation.Induration }, --Cryohelix II
    [890] = T{ Resonation.Impaction }, --Ionohelix II
    [891] = T{ Resonation.Compression }, --Noctohelix II
    [892] = T{ Resonation.Transfixion } --Luminohelix II
};

local weaponskillResonationMap = T{
    [1] = T{ Resonation.Impaction }, --Combo
    [2] = T{ Resonation.Reverberation, Resonation.Impaction }, --Shoulder Tackle
    [3] = T{ Resonation.Compression }, --One Inch Punch
    [4] = T{ Resonation.Detonation }, --Backhand Blow
    [5] = T{ Resonation.Impaction }, --Raging Fists
    [6] = T{ Resonation.Liquefaction, Resonation.Impaction }, --Spinning Attack
    [7] = T{ Resonation.Transfixion, Resonation.Impaction }, --Howling Fist
    [8] = T{ Resonation.Fragmentation }, --Dragon Kick
    [9] = T{ Resonation.Gravitation, Resonation.Liquefaction }, --Asuran Fists
    [10] = T{ Resonation.Light, Resonation.Fusion }, --Final Heaven
    [11] = T{ Resonation.Fusion, Resonation.Transfixion }, --Ascetic's Fury
    [12] = T{ Resonation.Gravitation, Resonation.Liquefaction }, --Stringing Pummel
    [13] = T{ Resonation.Induration, Resonation.Detonation, Resonation.Impaction }, --Tornado Kick
    [14] = T{ Resonation.Light, Resonation.Fragmentation }, --Victory Smite
    [15] = T{ Resonation.Fusion, Resonation.Reverberation }, --Shijin Spiral
    [16] = T{ Resonation.Scission }, --Wasp Sting
    [17] = T{ Resonation.Scission }, --Viper Bite
    [18] = T{ Resonation.Reverberation }, --Shadowstitch
    [19] = T{ Resonation.Detonation }, --Gust Slash
    [20] = T{ Resonation.Detonation, Resonation.Impaction }, --Cyclone
    [23] = T{ Resonation.Scission, Resonation.Detonation }, --Dancing Edge
    [24] = T{ Resonation.Fragmentation }, --Shark Bite
    [25] = T{ Resonation.Gravitation, Resonation.Transfixion }, --Evisceration
    [26] = T{ Resonation.Darkness, Resonation.Gravitation }, --Mercy Stroke
    [27] = T{ Resonation.Fusion, Resonation.Compression }, --Mandalic Stab
    [28] = T{ Resonation.Fragmentation, Resonation.Distortion }, --Mordant Rime
    [29] = T{ Resonation.Distortion, Resonation.Scission }, --Pyrrhic Kleos
    [30] = T{ Resonation.Scission, Resonation.Detonation, Resonation.Impaction }, --Aeolian Edge
    [31] = T{ Resonation.Darkness, Resonation.Distortion }, --Rudra's Storm
    [32] = T{ Resonation.Scission }, --Fast Blade
    [33] = T{ Resonation.Liquefaction }, --Burning Blade
    [34] = T{ Resonation.Liquefaction, Resonation.Detonation }, --Red Lotus Blade
    [35] = T{ Resonation.Impaction }, --Flat Blade
    [36] = T{ Resonation.Scission }, --Shining Blade
    [37] = T{ Resonation.Scission }, --Seraph Blade
    [38] = T{ Resonation.Reverberation, Resonation.Impaction }, --Circle Blade
    [40] = T{ Resonation.Scission, Resonation.Impaction }, --Vorpal Blade
    [41] = T{ Resonation.Gravitation }, --Swift Blade
    [42] = T{ Resonation.Fragmentation, Resonation.Scission }, --Savage Blade
    [43] = T{ Resonation.Light, Resonation.Fusion }, --Knights of Round
    [44] = T{ Resonation.Fragmentation, Resonation.Distortion }, --Death Blossom
    [45] = T{ Resonation.Fusion, Resonation.Reverberation }, --Atonement
    [46] = T{ Resonation.Distortion, Resonation.Scission }, --Expiacion
    [48] = T{ Resonation.Scission }, --Hard Slash
    [49] = T{ Resonation.Transfixion }, --Power Slash
    [50] = T{ Resonation.Induration }, --Frostbite
    [51] = T{ Resonation.Induration, Resonation.Detonation }, --Freezebite
    [52] = T{ Resonation.Reverberation }, --Shockwave
    [53] = T{ Resonation.Scission }, --Crescent Moon
    [54] = T{ Resonation.Scission, Resonation.Impaction }, --Sickle Moon
    [55] = T{ Resonation.Fragmentation }, --Spinning Slash
    [56] = T{ Resonation.Fragmentation, Resonation.Distortion }, --Ground Strike
    [57] = T{ Resonation.Light, Resonation.Fusion }, --Scourge
    [58] = T{ Resonation.Induration, Resonation.Detonation, Resonation.Impaction }, --Herculean Slash
    [59] = T{ Resonation.Light, Resonation.Distortion }, --Torcleaver
    [60] = T{ Resonation.Fragmentation, Resonation.Scission }, --Resolution
    [61] = T{ Resonation.Light, Resonation.Fragmentation }, --Dimidiation
    [62] = T{ Resonation.Detonation, Resonation.Compression, Resonation.Distortion }, --Fimbulvetr    
    [64] = T{ Resonation.Detonation, Resonation.Impaction }, --Raging Axe
    [65] = T{ Resonation.Induration, Resonation.Reverberation }, --Smash Axe
    [66] = T{ Resonation.Detonation }, --Gale Axe
    [67] = T{ Resonation.Scission, Resonation.Impaction }, --Avalanche Axe
    [68] = T{ Resonation.Liquefaction, Resonation.Scission, Resonation.Impaction }, --Spinning Axe
    [69] = T{ Resonation.Scission }, --Rampage
    [70] = T{ Resonation.Scission, Resonation.Impaction }, --Calamity
    [71] = T{ Resonation.Fusion }, --Mistral Axe
    [72] = T{ Resonation.Fusion, Resonation.Reverberation }, --Decimation
    [73] = T{ Resonation.Darkness, Resonation.Gravitation }, --Onslaught
    [74] = T{ Resonation.Gravitation, Resonation.Reverberation }, --Primal Rend
    [75] = T{ Resonation.Scission, Resonation.Detonation }, --Bora Axe
    [76] = T{ Resonation.Darkness, Resonation.Fragmentation }, --Cloudsplitter
    [77] = T{ Resonation.Distortion, Resonation.Detonation }, --Ruinator
    [78] = T{ Resonation.Liquefaction, Resonation.Impaction, Resonation.Fragmentation }, --Blitz
    [80] = T{ Resonation.Impaction }, --Shield Break
    [81] = T{ Resonation.Scission }, --Iron Tempest
    [82] = T{ Resonation.Reverberation, Resonation.Scission }, --Sturmwind
    [83] = T{ Resonation.Impaction }, --Armor Break
    [84] = T{ Resonation.Compression }, --Keen Edge
    [85] = T{ Resonation.Impaction }, --Weapon Break
    [86] = T{ Resonation.Induration, Resonation.Reverberation }, --Raging Rush
    [87] = T{ Resonation.Distortion }, --Full Break
    [88] = T{ Resonation.Distortion, Resonation.Detonation }, --Steel Cyclone
    [89] = T{ Resonation.Light, Resonation.Fusion }, --Metatron Torment
    [90] = T{ Resonation.Fragmentation, Resonation.Scission }, --King's Justice
    [91] = T{ Resonation.Scission, Resonation.Detonation, Resonation.Impaction }, --Fell Cleave
    [92] = T{ Resonation.Light, Resonation.Fragmentation }, --Ukko's Fury
    [93] = T{ Resonation.Fusion, Resonation.Compression }, --Upheaval
    [94] = T{ Resonation.Transfixion, Resonation.Scission, Resonation.Gravitation }, --Disaster
    [96] = T{ Resonation.Scission }, --Slice
    [97] = T{ Resonation.Reverberation }, --Dark Harvest
    [98] = T{ Resonation.Induration, Resonation.Reverberation }, --Shadow of Death
    [99] = T{ Resonation.Compression, Resonation.Scission }, --Nightmare Scythe
    [100] = T{ Resonation.Reverberation, Resonation.Scission }, --Spinning Scythe
    [101] = T{ Resonation.Transfixion, Resonation.Scission }, --Vorpal Scythe
    [102] = T{ Resonation.Induration }, --Guillotine
    [103] = T{ Resonation.Distortion }, --Cross Reaper
    [104] = T{ Resonation.Distortion, Resonation.Scission }, --Spiral Hell
    [105] = T{ Resonation.Darkness, Resonation.Gravitation }, --Catastrophe
    [106] = T{ Resonation.Fusion, Resonation.Compression }, --Insurgency
    [107] = T{ Resonation.Compression, Resonation.Reverberation }, --Infernal Scythe
    [108] = T{ Resonation.Darkness, Resonation.Distortion }, --Quietus
    [109] = T{ Resonation.Gravitation, Resonation.Reverberation }, --Entropy
    [110] = T{ Resonation.Induration, Resonation.Reverberation, Resonation.Fusion }, --Origin
    [112] = T{ Resonation.Transfixion }, --Double Thrust
    [113] = T{ Resonation.Transfixion, Resonation.Impaction }, --Thunder Thrust
    [114] = T{ Resonation.Transfixion, Resonation.Impaction }, --Raiden Thrust
    [115] = T{ Resonation.Impaction }, --Leg Sweep
    [116] = T{ Resonation.Compression }, --Penta Thrust
    [117] = T{ Resonation.Reverberation, Resonation.Transfixion }, --Vorpal Thrust
    [118] = T{ Resonation.Transfixion, Resonation.Impaction }, --Skewer
    [119] = T{ Resonation.Fusion }, --Wheeling Thrust
    [120] = T{ Resonation.Gravitation, Resonation.Induration }, --Impulse Drive
    [121] = T{ Resonation.Light, Resonation.Distortion }, --Geirskogul
    [122] = T{ Resonation.Fusion, Resonation.Transfixion }, --Drakesbane
    [123] = T{ Resonation.Transfixion, Resonation.Scission }, --Sonic Thrust
    [124] = T{ Resonation.Light, Resonation.Fragmentation }, --Camlann's Torment
    [125] = T{ Resonation.Gravitation, Resonation.Transfixion }, --Stardiver
    [126] = T{ Resonation.Transfixion, Resonation.Scission, Resonation.Gravitation }, --Diarmuid
    [128] = T{ Resonation.Transfixion }, --Blade: Rin
    [129] = T{ Resonation.Scission }, --Blade: Retsu
    [130] = T{ Resonation.Reverberation }, --Blade: Teki
    [131] = T{ Resonation.Induration, Resonation.Detonation }, --Blade: To
    [132] = T{ Resonation.Transfixion, Resonation.Impaction }, --Blade: Chi
    [133] = T{ Resonation.Compression }, --Blade: Ei
    [134] = T{ Resonation.Detonation, Resonation.Impaction }, --Blade: Jin
    [135] = T{ Resonation.Gravitation }, --Blade: Ten
    [136] = T{ Resonation.Gravitation, Resonation.Transfixion }, --Blade: Ku
    [137] = T{ Resonation.Darkness, Resonation.Fragmentation }, --Blade: Metsu
    [138] = T{ Resonation.Fragmentation, Resonation.Compression }, --Blade: Kamu
    [139] = T{ Resonation.Reverberation, Resonation.Scission }, --Blade: Yu
    [140] = T{ Resonation.Darkness, Resonation.Gravitation }, --Blade: Hi
    [141] = T{ Resonation.Fusion, Resonation.Impaction }, --Blade: Shun
    [142] = T{ Resonation.Induration, Resonation.Reverberation, Resonation.Fusion }, --Zesho Meppo
    [144] = T{ Resonation.Transfixion, Resonation.Scission }, --Tachi: Enpi
    [145] = T{ Resonation.Induration }, --Tachi: Hobaku
    [146] = T{ Resonation.Transfixion, Resonation.Impaction }, --Tachi: Goten
    [147] = T{ Resonation.Liquefaction }, --Tachi: Kagero
    [148] = T{ Resonation.Scission, Resonation.Detonation }, --Tachi: Jinpu
    [149] = T{ Resonation.Reverberation, Resonation.Impaction }, --Tachi: Koki
    [150] = T{ Resonation.Induration, Resonation.Detonation }, --Tachi: Yukikaze
    [151] = T{ Resonation.Distortion, Resonation.Reverberation }, --Tachi: Gekko
    [152] = T{ Resonation.Fusion, Resonation.Compression }, --Tachi: Kasha
    [153] = T{ Resonation.Light, Resonation.Fragmentation }, --Tachi: Kaiten
    [154] = T{ Resonation.Gravitation, Resonation.Induration }, --Tachi: Rana
    [155] = T{ Resonation.Compression, Resonation.Scission }, --Tachi: Ageha
    [156] = T{ Resonation.Light, Resonation.Distortion }, --Tachi: Fudo
    [157] = T{ Resonation.Fragmentation, Resonation.Compression }, --Tachi: Shoha
    [158] = T{ Resonation.Fusion }, --Tachi: Suikawari
    [159] = T{ Resonation.Detonation, Resonation.Compression, Resonation.Distortion }, --Tachi: Mumei
    [160] = T{ Resonation.Impaction }, --Shining Strike
    [161] = T{ Resonation.Impaction }, --Seraph Strike
    [162] = T{ Resonation.Reverberation }, --Brainshaker
    [165] = T{ Resonation.Induration, Resonation.Reverberation }, --Skullbreaker
    [166] = T{ Resonation.Detonation, Resonation.Impaction }, --True Strike
    [167] = T{ Resonation.Impaction }, --Judgment
    [168] = T{ Resonation.Fusion }, --Hexa Strike
    [169] = T{ Resonation.Fragmentation, Resonation.Compression }, --Black Halo
    [170] = T{ Resonation.Light, Resonation.Fragmentation }, --Randgrith
    [172] = T{ Resonation.Induration, Resonation.Reverberation }, --Flash Nova
    [174] = T{ Resonation.Fusion, Resonation.Impaction }, --Realmrazer
    [175] = T{ Resonation.Darkness, Resonation.Fragmentation }, --Exudation
    [176] = T{ Resonation.Impaction }, --Heavy Swing
    [177] = T{ Resonation.Impaction }, --Rock Crusher
    [178] = T{ Resonation.Detonation, Resonation.Impaction }, --Earth Crusher
    [179] = T{ Resonation.Compression, Resonation.Reverberation }, --Starburst
    [180] = T{ Resonation.Compression, Resonation.Reverberation }, --Sunburst
    [181] = T{ Resonation.Detonation }, --Shell Crusher
    [182] = T{ Resonation.Liquefaction, Resonation.Impaction }, --Full Swing
    [184] = T{ Resonation.Gravitation, Resonation.Reverberation }, --Retribution
    [185] = T{ Resonation.Darkness, Resonation.Distortion }, --Gate of Tartarus
    [186] = T{ Resonation.Fragmentation, Resonation.Distortion }, --Vidohunir
    [187] = T{ Resonation.Fusion, Resonation.Reverberation }, --Garland of Bliss
    [188] = T{ Resonation.Gravitation, Resonation.Transfixion }, --Omniscience
    [189] = T{ Resonation.Compression, Resonation.Reverberation }, --Cataclysm
    [191] = T{ Resonation.Gravitation, Resonation.Induration }, --Shattersoul
    [192] = T{ Resonation.Liquefaction, Resonation.Transfixion }, --Flaming Arrow
    [193] = T{ Resonation.Reverberation, Resonation.Transfixion }, --Piercing Arrow
    [194] = T{ Resonation.Liquefaction, Resonation.Transfixion }, --Dulling Arrow
    [196] = T{ Resonation.Reverberation, Resonation.Transfixion, Resonation.Detonation }, --Sidewinder
    [197] = T{ Resonation.Induration, Resonation.Transfixion }, --Blast Arrow
    [198] = T{ Resonation.Fusion }, --Arching Arrow
    [199] = T{ Resonation.Fusion, Resonation.Transfixion }, --Empyreal Arrow
    [200] = T{ Resonation.Light, Resonation.Distortion }, --Namas Arrow
    [201] = T{ Resonation.Reverberation, Resonation.Transfixion }, --Refulgent Arrow
    [202] = T{ Resonation.Light, Resonation.Fusion }, --Jishnu's Radiance
    [203] = T{ Resonation.Fragmentation, Resonation.Transfixion }, --Apex Arrow
    [204] = T{ Resonation.Transfixion, Resonation.Scission, Resonation.Gravitation }, --Sarv
    [208] = T{ Resonation.Liquefaction, Resonation.Transfixion }, --Hot Shot
    [209] = T{ Resonation.Reverberation, Resonation.Transfixion }, --Split Shot
    [210] = T{ Resonation.Liquefaction, Resonation.Transfixion }, --Sniper Shot
    [212] = T{ Resonation.Reverberation, Resonation.Transfixion, Resonation.Detonation }, --Slug Shot
    [213] = T{ Resonation.Induration, Resonation.Transfixion }, --Blast Shot
    [214] = T{ Resonation.Fusion }, --Heavy Shot
    [215] = T{ Resonation.Fusion, Resonation.Transfixion }, --Detonator
    [216] = T{ Resonation.Darkness, Resonation.Fragmentation }, --Coronach
    [217] = T{ Resonation.Fragmentation, Resonation.Scission }, --Trueflight
    [218] = T{ Resonation.Gravitation, Resonation.Transfixion }, --Leaden Salute
    [219] = T{ Resonation.Induration, Resonation.Detonation, Resonation.Impaction }, --Numbing Shot
    [220] = T{ Resonation.Darkness, Resonation.Gravitation }, --Wildfire
    [221] = T{ Resonation.Fusion, Resonation.Reverberation }, --Last Stand
    [222] = T{ Resonation.Induration, Resonation.Reverberation, Resonation.Fusion }, --Terminus
    [224] = T{ Resonation.Fragmentation, Resonation.Scission }, --Exenterator
    [225] = T{ Resonation.Light, Resonation.Distortion }, --Chant du Cygne
    [226] = T{ Resonation.Gravitation, Resonation.Scission }, --Requiescat
    [227] = T{ Resonation.Light }, --Knights of Rotund
    [228] = T{ Resonation.Light }, --Final Paradise
    [229] = T{ Resonation.Fusion }, --Fast Blade II
    [230] = T{ Resonation.Distortion }, --Dragon Blow
    [231] = T{ Resonation.Detonation, Resonation.Compression, Resonation.Distortion }, --Maru Kala
    [232] = T{ Resonation.Liquefaction, Resonation.Impaction, Resonation.Fragmentation }, --Ruthless Stroke
    [233] = T{ Resonation.Detonation, Resonation.Compression, Resonation.Distortion }, --Imperator
    [234] = T{ Resonation.Transfixion, Resonation.Scission, Resonation.Gravitation }, --Dagda
    [235] = T{ Resonation.Induration, Resonation.Reverberation, Resonation.Fusion }, --Oshala
    [238] = T{ Resonation.Light, Resonation.Fragmentation }, --Uriel Blade
    [239] = T{ Resonation.Light, Resonation.Fusion } --Glory Slash
};

local resonationMap = T{};

local function GetIndexFromId(id)
    local entMgr = AshitaCore:GetMemoryManager():GetEntity();
    
    --Shortcut for monsters/static npcs..
    if (bit.band(id, 0x1000000) ~= 0) then
        local index = bit.band(id, 0xFFF);
        if (index >= 0x900) then
            index = index - 0x100;
        end

        if (index < 0x900) and (entMgr:GetServerId(index) == id) then
            return index;
        end
    end

    for i = 1,0x8FF do
        if entMgr:GetServerId(i) == id then
            return i;
        end
    end

    return 0;

end

local function GetBuffs(userId)
    if (userId == AshitaCore:GetMemoryManager():GetParty():GetMemberServerId(0)) then
        return playerBuffTable;
    end
    local partyBuffData = partyBuffTable[userId];
    if partyBuffData then
        return partyBuffData;
    end
    local outTable = T{};
    local estimatedBuffData = estimatedBuffMap[userId];
    if estimatedBuffData then
        for buffId,timer in pairs(estimatedBuffData) do
            if (timer > os.clock()) then
                outTable:append(buffId);
            end
        end
    end
    return outTable;
end

local function GetSpellResonation(actionPacket)
    local elements = immanenceResonationMap[actionPacket.Id];
    if (elements) then
        local buffs = GetBuffs(actionPacket.UserId);
        if (buffs:contains(170)) then
            local estimatedMap = estimatedBuffMap[actionPacket.UserId];
            if estimatedMap then
                estimatedMap[170] = os.clock() + 1;
            end
            return elements;
        end
    end
    
    elements = chainAffinityResonationMap[actionPacket.Id];
    if elements then
        local buffs = GetBuffs(actionPacket.UserId);
        if (buffs:contains(163)) then
            return elements;
        elseif (buffs:contains(164)) then
            local estimatedMap = estimatedBuffMap[actionPacket.UserId];
            if estimatedMap then
                estimatedMap[164] = os.clock() + 1;
            end
            return elements;
        end
    end
end

local function HandleActionPacket(actionPacket)
    --Weaponskill
    if (actionPacket.Type == 3) then
        for _,target in pairs(actionPacket.Targets) do
            local targetIndex = GetIndexFromId(target.Id);
            if (targetIndex ~= 0) then
                for _,action in pairs(target.Actions) do
                    local skillchain;
                    if (action.AdditionalEffect ~= nil) then
                        skillchain = skillchainMessageIds[action.AdditionalEffect.Message];
                    end
                    if skillchain == Resonation.None then
                        resonationMap[targetIndex] = nil;
                    elseif skillchain then
                        local resonation = resonationMap[targetIndex];
                        if resonation and ((os.clock() + 1) > resonation.WindowOpen) and ((os.clock() - 1) < resonation.WindowClose) then
                            resonation.Depth = resonation.Depth + 1;
                            if ((skillchain == Resonation.Light) and (resonation.Attributes:contains(Resonation.Light))) then
                                resonation.Attributes = T{ Resonation.Light2 };
                            elseif ((skillchain == Resonation.Darkness) and (resonation.Attributes:contains(Resonation.Darkness))) then
                                resonation.Attributes = T{ Resonation.Darkness2 };
                            else
                                resonation.Attributes = T{ skillchain };
                            end
                            resonation.WindowOpen = os.clock() + 3.5;
                            resonation.WindowClose = os.clock() + (9.8 - resonation.Depth);
                        else
                            resonation = T{};
                            resonation.Depth = 1;
                            resonation.Attributes = T{ skillchain };
                            resonation.WindowOpen = os.clock() + 3.5;
                            resonation.WindowClose = os.clock() + (9.8 - resonation.Depth);
                            resonationMap[targetIndex] = resonation;
                        end
                    
                    elseif weaponskillMessageIds:contains(action.Message) then
                        local attributes = weaponskillResonationMap[actionPacket.Id];
                        if attributes then
                            local resonation = T{};
                            resonation.Depth = 0;
                            resonation.Attributes = attributes;
                            resonation.WindowOpen = os.clock() + 3.5;
                            resonation.WindowClose = os.clock() + (9.8 - resonation.Depth);
                            resonationMap[targetIndex] = resonation;
                        end
                    end
                end
            end
        end

    --Spell
    elseif (actionPacket.Type == 4) then
        for _,target in pairs(actionPacket.Targets) do
            local targetIndex = GetIndexFromId(target.Id);
            if (targetIndex ~= 0) then
                for _,action in pairs(target.Actions) do
                    local skillchain;
                    if (action.AdditionalEffect ~= nil) then
                        skillchain = skillchainMessageIds[action.AdditionalEffect.Message];
                    end
                    if skillchain == Resonation.None then
                        resonationMap[targetIndex] = nil;
                    elseif skillchain then
                        local resonation = resonationMap[targetIndex];
                        if resonation and ((os.clock() + 1) > resonation.WindowOpen) and ((os.clock() - 1) < resonation.WindowClose) then
                            resonation.Depth = resonation.Depth + 1;
                            if ((skillchain == Resonation.Light) and (resonation.Attributes:contains(Resonation.Light))) then
                                resonation.Attributes = T{ Resonation.Light2 };
                            elseif ((skillchain == Resonation.Darkness) and (resonation.Attributes:contains(Resonation.Darkness))) then
                                resonation.Attributes = T{ Resonation.Darkness2 };
                            else
                                resonation.Attributes = T{ skillchain };
                            end
                            resonation.WindowOpen = os.clock() + 3.5;
                            resonation.WindowClose = os.clock() + (9.8 - resonation.Depth);
                        else
                            resonation = T{};
                            resonation.Depth = 1;
                            resonation.Attributes = T{ skillchain };
                            resonation.WindowOpen = os.clock() + 3.5;
                            resonation.WindowClose = os.clock() + (9.8 - resonation.Depth);
                            resonationMap[targetIndex] = resonation;
                        end
                    else
                        local elements = GetSpellResonation(actionPacket);
                        if elements then
                            local resonation = T{};
                            resonation.Depth = 1;
                            resonation.Attributes = elements;
                            resonation.WindowOpen = os.clock() + 3.5;
                            resonation.WindowClose = os.clock() + (9.8 - resonation.Depth);
                            resonationMap[targetIndex] = resonation;
                        end
                    end
                end
            end
        end

    --JA
    elseif (actionPacket.Type == 6) then
        --Azure Lore
        if (actionPacket.Id == 93) then
            local member = estimatedBuffMap[actionPacket.UserId];
            if (member == nil) then
                member = T{};
                estimatedBuffMap[actionPacket.UserId] = member;
            end
            member[163] = os.clock() + 30;

        --Chain Affinity
        elseif (actionPacket.Id == 94) then
            local member = estimatedBuffMap[actionPacket.UserId];
            if (member == nil) then
                member = T{};
                estimatedBuffMap[actionPacket.UserId] = member;
            end
            member[164] = os.clock() + 30;

        --Immanence
        elseif (actionPacket.Id == 317) then
            local member = estimatedBuffMap[actionPacket.UserId];
            if (member == nil) then
                member = T{};
                estimatedBuffMap[actionPacket.UserId] = member;
            end
            member[170] = os.clock() + 60;
        end
    end
end

ashita.events.register('packet_in', 'skillchain_handleincomingpacket', function (e)
    if (e.id == 0x00A) then
        resonationMap = T{};
    elseif (e.id == 0x28) then
        local bitData;
        local bitOffset;
        local function UnpackBits(length)
            local value = ashita.bits.unpack_be(bitData, 0, bitOffset, length);
            bitOffset = bitOffset + length;
            return value;
        end
    
        local actionPacket = T{};
        bitData = e.data_raw;
        bitOffset = 40;
        actionPacket.UserId = UnpackBits(32);
        local targetCount = UnpackBits(6);
        bitOffset = bitOffset + 4;
        actionPacket.Type = UnpackBits(4);
        actionPacket.Id = UnpackBits(32);
        actionPacket.Recast = UnpackBits(32);

        --Save a little bit of processing for packets that won't relate to SC..
        if (T{3, 4, 6}:contains(actionPacket.Type) == false) then
            return;
        end
    
        actionPacket.Targets = T{};
        for i = 1,targetCount do
            local target = T{};
            target.Id = UnpackBits(32);
            local actionCount = UnpackBits(4);
            target.Actions = T{};
            for j = 1,actionCount do
                local action = T{};
                action.Reaction = UnpackBits(5);
                action.Animation = UnpackBits(12);
                action.SpecialEffect = UnpackBits(7);
                action.Knockback = UnpackBits(3);
                action.Param = UnpackBits(17);
                action.Message = UnpackBits(10);
                action.Flags = UnpackBits(31);

                local hasAdditionalEffect = (UnpackBits(1) == 1);
                if hasAdditionalEffect then
                    local additionalEffect = T{};
                    additionalEffect.Damage = UnpackBits(10);
                    additionalEffect.Param = UnpackBits(17);
                    additionalEffect.Message = UnpackBits(10);
                    action.AdditionalEffect = additionalEffect;
                end

                local hasSpikesEffect = (UnpackBits(1) == 1);
                if hasSpikesEffect then
                    local spikesEffect = T{};
                    spikesEffect.Damage = UnpackBits(10);
                    spikesEffect.Param = UnpackBits(14);
                    spikesEffect.Message = UnpackBits(10);
                    action.SpikesEffect = spikesEffect;
                end

                target.Actions:append(action);
            end
            actionPacket.Targets:append(target);
        end

        if (#actionPacket.Targets > 0) then
            HandleActionPacket(actionPacket);
        end
    elseif (e.id == 0x63) and (struct.unpack('B', e.data, 0x04 + 1) == 9) then
        playerBuffTable = T{};
        for i = 1,32 do
            local buff = struct.unpack('H', e.data, 0x06 + (i * 2) + 1);
            if buff ~= 0xFF then
                playerBuffTable:append(buff);
            end
        end
    elseif (e.id == 0x076) then
        partyBuffTable = T{};
        for i = 0,4 do
            local memberOffset = 0x04 + (0x30 * i) + 1;
            local memberId = struct.unpack('L', e.data, memberOffset);
            if memberId > 0 then
                local buffs = T{};
                local empty = false;
                for j = 0,31 do
                    if empty then
                        buffs[j + 1] = -1;
                    else
                        local highBits = bit.lshift(ashita.bits.unpack_be(e.data_raw, memberOffset + 7, j * 2, 2), 8);
                        local lowBits = struct.unpack('B', e.data, memberOffset + 0x10 + j);
                        local buff = highBits + lowBits;
                        if (buff == 255) then
                            buffs[j + 1] = -1;
                            empty = true;
                        else
                            buffs[j + 1] = buff;
                        end
                    end
                end
                partyBuffTable[memberId] = buffs;
            end
        end
    end
end);

local exposed = T{};

function exposed:GetSkillchain(targetIndex, weaponskillId)
    local resonation = resonationMap[targetIndex];
    if not resonation then
        return;
    end
    if (os.clock() > resonation.WindowClose) then
        resonationMap[targetIndex] = nil;
        return;
    end

    local wsAttributes = weaponskillResonationMap[weaponskillId];
    if not wsAttributes then
        return;
    end

    for _,sc in ipairs(possibleSkillchains) do
        if (resonation.Attributes:contains(sc[2])) then
            if wsAttributes:contains(sc[3]) then
                return resonation, names[sc[1]];
            end
        end
    end

    return;
end

function exposed:GetSkillchainBySpell(targetIndex, spellId)
    local buffId;
    local spellAttributes = immanenceResonationMap[spellId];
    if spellAttributes then
        buffId = T{470};
    else
        spellAttributes = chainAffinityResonationMap[spellId];
        if spellAttributes then
            buffId = T{ 163, 164 };
        end
    end
    if not buffId then
        return;
    end
    
    local buffActive = false;
    for _,buff in ipairs(playerBuffTable) do
        if buffId:contains(buff) then
            buffActive = true;
            break;
        end
    end

    if not buffActive then
        return;
    end

    local resonation = resonationMap[targetIndex];
    if not resonation then
        return;
    end
    if (os.clock() > resonation.WindowClose) then
        resonationMap[targetIndex] = nil;
        return;
    end

    for _,sc in ipairs(possibleSkillchains) do
        if (resonation.Attributes:contains(sc[2])) then
            if spellAttributes:contains(sc[3]) then
                return resonation, names[sc[1]];
            end
        end
    end
end

return exposed;