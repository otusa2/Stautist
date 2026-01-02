local addonName, addonTable = ...
-- Global reference not needed here, we just modify the table
if not Stautist then return end

Stautist.BossDB = {}

-- ============================================================================
-- CLASSIC ERA (VANILLA)
-- ============================================================================

-- [Molten Core]
Stautist.BossDB[409] = { name = "Molten Core", type = "raid", tier = "Classic", textureID = 409, end_boss_id = 11502,
    bosses = {
        [12118]="Lucifron", [11982]="Magmadar", [12259]="Gehennas",
        [12057]="Garr", [12264]="Shazzrah", [12056]="Baron Geddon",
        [12098]="Sulfuron Harbinger", [11988]="Golemagg the Incinerator",
        [12018]="Majordomo Executus", [11502]="Ragnaros"
    }
}

-- [Blackwing Lair]
Stautist.BossDB[469] = { name = "Blackwing Lair", type = "raid", tier = "Classic", textureID = 469, end_boss_id = 11583,
    bosses = {
        [12435]="Razorgore the Untamed", [13020]="Vaelastrasz the Corrupt",
        [12017]="Broodlord Lashlayer", [11983]="Firemaw",
        [14601]="Ebonroc", [11981]="Flamegor",
        [14020]="Chromaggus", [11583]="Nefarian"
    }
}

-- [Temple of Ahn'Qiraj (AQ40)]
Stautist.BossDB[531] = { name = "Temple of Ahn'Qiraj", type = "raid", tier = "Classic", textureID = 531, end_boss_id = 15727,
    bosses = {
        [15263]="The Prophet Skeram", [15543]="Princess Yauj", [15544]="Lord Kri", [15511]="Vem",
        [15516]="Battleguard Sartura", [15510]="Fankriss the Unyielding",
        [15299]="Viscidus", [15509]="Princess Huhuran",
        [15276]="Emperor Vek'lor", [15275]="Emperor Vek'nilash",
        [15517]="Ouro", [15727]="C'Thun"
    }
}

-- [Ruins of Ahn'Qiraj (AQ20)]
Stautist.BossDB[509] = { name = "Ruins of Ahn'Qiraj", type = "raid", tier = "Classic", textureID = 509, end_boss_id = 15339,
    bosses = {
        [15348]="Kurinnaxx", [15341]="General Rajaxx", [15340]="Moam",
        [15370]="Buru the Gorger", [15369]="Ayamiss the Hunter", [15339]="Ossirian the Unscarred"
    }
}

-- [Zul'Gurub] (Classic Version on 3.3.5a)
Stautist.BossDB[309] = { name = "Zul'Gurub", type = "raid", tier = "Classic", textureID = 309, end_boss_id = 14834,
    bosses = {
        [14517]="High Priestess Jeklik", [14507]="High Priest Venoxis",
        [14510]="High Priestess Mar'li", [14509]="High Priest Thekal",
        [14515]="High Priestess Arlokk", [11382]="Bloodlord Mandokir",
        [15083]="Gahz'ranka", [15114]="Grilek", [15085]="Hazza'rah", [15084]="Renataki", [15082]="Wushoolay", -- Edge of Madness
        [14505]="Jin'do the Hexxer", [14834]="Hakkar"
    }
}

-- [Classic Dungeons]
Stautist.BossDB[389] = { 
    name = "Ragefire Chasm", 
    type = "dungeon", 
    tier="Classic", 
    textureID = 389,
    end_boss_id = 11520, 
    bosses = { 
        [11520]="Taragaman the Hungerer", 
        [11518]="Jergosh the Invoker", 
        [11519]="Bazzalan", 
        [11517]="Oggleflint" 
    } 
}
Stautist.BossDB[36]  = { name = "Deadmines", type = "dungeon", tier="Classic", textureID = 36, end_boss_id = 639, bosses = { [644]="Rhahk'Zor", [642]="Sneed", [643]="Gilnid", [645]="Mr. Smite", [647]="Cookie", [639]="VanCleef" } }
Stautist.BossDB[43]  = { name = "Wailing Caverns", type = "dungeon", tier="Classic", textureID = 43, end_boss_id = 3654, bosses = { [3654]="Mutanus", [3675]="Kresh", [3653]="Naralex Event" } }
Stautist.BossDB[33]  = { name = "Shadowfang Keep", type = "dungeon", tier="Classic", textureID = 33, end_boss_id = 4275, bosses = { [3887]="Baron Silverlaine", [4275]="Archmage Arugal" } }
Stautist.BossDB[48]  = { name = "Blackfathom Deeps", type = "dungeon", tier="Classic", textureID = 48, end_boss_id = 4825, bosses = { [4831]="Lady Sarevess", [4829]="Gelihast", [4825]="Aku'mai" } }
Stautist.BossDB[34]  = { name = "The Stockade", type = "dungeon", tier="Classic", textureID = 34, end_boss_id = 1716, bosses = { [1716]="Bazil Thredd" } }
Stautist.BossDB[90]  = { name = "Gnomeregan", type = "dungeon", tier="Classic", textureID = 90, end_boss_id = 7800, bosses = { [6235]="Crowd Pummeler", [7800]="Mekgineer Thermaplugg" } }
Stautist.BossDB[47]  = { name = "Razorfen Kraul", type = "dungeon", tier="Classic", textureID = 47, end_boss_id = 4421, bosses = { [4421]="Charlga Razorflank" } }
Stautist.BossDB[129] = { name = "Razorfen Downs", type = "dungeon", tier="Classic", textureID = 129, end_boss_id = 7358, bosses = { [7358]="Amnennar the Coldbringer" } }
Stautist.BossDB[70]  = { name = "Uldaman", type = "dungeon", tier="Classic", textureID = 70, end_boss_id = 6910, bosses = { [7228]="Ironaya", [6910]="Archaedas" } }
Stautist.BossDB[209] = { name = "Zul'Farrak", type = "dungeon", tier="Classic", textureID = 209, end_boss_id = 7796, bosses = { [7273]="Ghaz'rilla", [7796]="Chief Ukorz Sandscalp" } }
Stautist.BossDB[349] = { name = "Maraudon", type = "dungeon", tier="Classic", textureID = 349, end_boss_id = 12201, bosses = { [12201]="Princess Theradras", [12203]="Rotgrip", [13596]="Celebras" } }
Stautist.BossDB[109] = { name = "Sunken Temple", type = "dungeon", tier="Classic", textureID = 109, end_boss_id = 5709, bosses = { [5709]="Shade of Eranikus", [8443]="Avatar of Hakkar" } }
Stautist.BossDB[230] = { name = "Blackrock Depths", type = "dungeon", tier="Classic", textureID = 230, end_boss_id = 9019, bosses = { [9019]="Emperor Dagran Thaurissan", [9018]="Gerstahn", [9056]="Argelmach", [9938]="Magmus" } }
Stautist.BossDB[229] = { name = "Blackrock Spire", type = "dungeon", tier="Classic", textureID = 229, end_boss_id = 10363, bosses = { [9568]="Overlord Wyrmthalak", [9736]="Quartermaster Zigris", [10363]="General Drakkisath", [10429]="Warchief Rend Blackhand", [10899]="The Beast" } }
Stautist.BossDB[429] = { name = "Dire Maul", type = "dungeon", tier="Classic", textureID = 429, end_boss_id = 11501, bosses = { [11492]="Alzzin the Wildshaper", [11501]="King Gordok", [11489]="Immol'thar", [11496]="Prince Tortheldrin" } }
Stautist.BossDB[289] = { name = "Scholomance", type = "dungeon", tier="Classic", textureID = 289, end_boss_id = 1853, bosses = { [10506]="Kirtonos the Herald", [10433]="Jandice Barov", [10508]="Ras Frostwhisper", [1853]="Darkmaster Gandling" } }
Stautist.BossDB[329] = { name = "Stratholme", type = "dungeon", tier="Classic", textureID = 329, end_boss_id = 10439, bosses = { [10444]="Timmy the Cruel", [10808]="Timmy?", [10997]="Cannon Master Willey", [10813]="Balnazzar", [10439]="Baron Rivendare" } }
Stautist.BossDB[189] = { name = "Scarlet Monastery", type = "dungeon", tier="Classic", textureID = 189, end_boss_id = 3977, bosses = { [6487]="Arcanist Doan", [3975]="Herod", [3977]="Whitemane", [4542]="Mograine" } }


-- ============================================================================
-- THE BURNING CRUSADE (TBC)
-- ============================================================================

-- [Karazhan]
Stautist.BossDB[532] = { name = "Karazhan", type = "raid", tier = "TBC", textureID = 532, end_boss_id = 15690,
    bosses = {
        [16152]="Attumen the Huntsman", 
        [15687]="Moroes", 
        [16457]="Maiden of Virtue",
        
        -- Opera Event (Linked by 'encounter="opera"')
        -- Julianne acts as the default "Opera Event" placeholder
        [16812]={ name="Opera Event", encounter="opera", order=4 }, 
        [17535]={ name="Romulo", encounter="opera", order=4 },
        [17521]={ name="The Big Bad Wolf", encounter="opera", order=4 },
        [18168]={ name="The Crone", encounter="opera", order=4 }, -- Wizard of Oz

        [15691]="The Curator", 
        [15688]="Terestian Illhoof", 
        [15689]="Shade of Aran",
        [15690]="Prince Malchezaar", 
        [17225]="Nightbane", 
        [15685]="Netherspite"
    }
}

-- [Gruul's Lair]
Stautist.BossDB[565] = { name = "Gruul's Lair", type = "raid", tier = "TBC", textureID = 565, end_boss_id = 19044,
    bosses = { [18831]="High King Maulgar", [19044]="Gruul the Dragonkiller" }
}

-- [Magtheridon's Lair]
Stautist.BossDB[544] = { name = "Magtheridon's Lair", type = "raid", tier = "TBC", textureID = 544, end_boss_id = 17257,
    bosses = { [17257]="Magtheridon" }
}

-- [Serpentshrine Cavern]
Stautist.BossDB[548] = { name = "Serpentshrine Cavern", type = "raid", tier = "TBC", textureID = 548, end_boss_id = 21212,
    bosses = {
        [21216]="Hydross the Unstable", [21217]="The Lurker Below", [21215]="Leotheras the Blind",
        [21214]="Fathom-Lord Karathress", [21213]="Morogrim Tidewalker", [21212]="Lady Vashj"
    }
}

-- [Tempest Keep]
Stautist.BossDB[550] = { name = "Tempest Keep", type = "raid", tier = "TBC", textureID = 550, end_boss_id = 19622,
    bosses = { [19514]="Al'ar", [19516]="Void Reaver", [18805]="High Astromancer Solarian", [19622]="Kael'thas Sunstrider" }
}

-- [Battle for Mount Hyjal]
Stautist.BossDB[534] = { name = "Mount Hyjal", type = "raid", tier = "TBC", textureID = 534, end_boss_id = 17968,
    bosses = { [17767]="Rage Winterchill", [17808]="Anetheron", [17888]="Kaz'rogal", [17842]="Azgalor", [17968]="Archimonde" }
}

-- [Black Temple]
Stautist.BossDB[564] = { name = "Black Temple", type = "raid", tier = "TBC", textureID = 564, end_boss_id = 22917,
    bosses = {
        [22887]="High Warlord Naj'entus", [22898]="Supremus", [22841]="Shade of Akama",
        [22871]="Teron Gorefiend", [22948]="Gurtogg Bloodboil", [22856]="Reliquary of Souls",
        [22947]="Mother Shahraz", [22917]="Illidan Stormrage",
        [22949]="Gathios the Shatterer" -- Council
    }
}

-- [Sunwell Plateau]
Stautist.BossDB[580] = { name = "Sunwell Plateau", type = "raid", tier = "TBC", textureID = 580, end_boss_id = 25315,
    bosses = {
        [24850]="Kalecgos", [24882]="Brutallus", [25038]="Felmyst",
        [25165]="Lady Sacrolash", [25166]="Grand Warlock Alythess", -- Twins
        [25741]="M'uru", [25315]="Kil'jaeden"
    }
}

-- [Zul'Aman]
Stautist.BossDB[568] = { name = "Zul'Aman", type = "raid", tier = "TBC", textureID = 568, end_boss_id = 23863,
    bosses = {
        [23574]="Akil'zon", [23576]="Nalorakk", [23578]="Jan'alai", [23577]="Halazzi",
        [24239]="Hex Lord Malacrass", [23863]="Zul'jin"
    }
}

-- [TBC Dungeons]
Stautist.BossDB[540] = { 
    name = "Shattered Halls", type = "dungeon", tier="TBC", textureID = 540, end_boss_id = 16808, 
    bosses = { 
        [16807] = { name = "Grand Warlock Nethekurse", order = 1 },
        [24891] = { name = "Blood Guard Porung", order = 2, heroicOnly = true }, -- Added Heroic Only
        [16809] = { name = "Warbringer O'mrogg", order = 3 },
        [16808] = { name = "Warchief Kargath Bladefist", order = 4 } 
    } 
}
Stautist.BossDB[542] = { name = "Blood Furnace", type = "dungeon", tier="TBC", textureID = 542, end_boss_id = 17377, bosses = { [17381]="The Maker", [17380]="Broggok", [17377]="Keli'dan the Breaker" } }
Stautist.BossDB[543] = { name = "Hellfire Ramparts", type = "dungeon", tier="TBC", textureID = 543, end_boss_id = 17537, bosses = { [17306]="Watchkeeper Gargolmar", [17308]="Omor the Unscarred", [17537]="Vazruden" } }
Stautist.BossDB[555] = { name = "Shadow Labyrinth", type = "dungeon", tier="TBC", textureID = 555, end_boss_id = 18708, bosses = { [18731]="Ambassador Hellmaw", [18667]="Blackheart the Inciter", [18732]="Grandmaster Vorpil", [18708]="Murmur" } }
Stautist.BossDB[556] = { name = "Sethekk Halls", type = "dungeon", tier="TBC", textureID = 556, end_boss_id = 18473, bosses = { [18472]="Darkweaver Syth", [18473]="Talon King Ikiss", [23035]="Anzu" } }
Stautist.BossDB[557] = { name = "Mana-Tombs", type = "dungeon", tier="TBC", textureID = 557, end_boss_id = 18344, bosses = { [18341]="Pandemonius", [18343]="Tavarok", [18344]="Nexus-Prince Shaffar" } }
Stautist.BossDB[558] = { name = "Auchenai Crypts", type = "dungeon", tier="TBC", textureID = 558, end_boss_id = 18373, bosses = { [18371]="Shirrak the Dead Watcher", [18373]="Exarch Maladaar" } }
Stautist.BossDB[560] = { name = "Old Hillsbrad", type = "dungeon", tier="TBC", textureID = 560, end_boss_id = 18096, bosses = { [17848]="Lieutenant Drake", [17862]="Captain Skarloc", [18096]="Epoch Hunter" } }
Stautist.BossDB[269] = { name = "Black Morass", type = "dungeon", tier="TBC", textureID = 269, end_boss_id = 17881, bosses = { [17879]="Chrono Lord Deja", [17880]="Temporus", [17881]="Aeonus" } }
Stautist.BossDB[545] = { name = "Steamvault", type = "dungeon", tier="TBC", textureID = 545, end_boss_id = 17798, bosses = { [17797]="Hydromancer Thespia", [17796]="Mekgineer Steamrigger", [17798]="Warlord Kalithresh" } }
Stautist.BossDB[546] = { name = "Underbog", type = "dungeon", tier="TBC", textureID = 546, end_boss_id = 17882, bosses = { [17770]="Hungarfen", [18105]="Ghaz'an", [17826]="Swamplord Musel'ek", [17882]="The Black Stalker" } }
Stautist.BossDB[547] = { name = "Slave Pens", type = "dungeon", tier="TBC", textureID = 547, end_boss_id = 17942, bosses = { [17941]="Mennu the Betrayer", [17991]="Rokmar the Crackler", [17942]="Quagmirran" } }
Stautist.BossDB[552] = { name = "The Arcatraz", type = "dungeon", tier="TBC", textureID = 552, end_boss_id = 20912, bosses = { [20870]="Zereketh", [20886]="Wrath-Scryer Soccothrates", [20885]="Dalliah the Doomsayer", [20912]="Harbinger Skyriss" } }
Stautist.BossDB[553] = { name = "The Botanica", type = "dungeon", tier="TBC", textureID = 553, end_boss_id = 17977, bosses = { [17976]="Commander Sarannis", [17975]="High Botanist Freywinn", [17978]="Thorngrin the Tender", [17980]="Laj", [17977]="Warp Splinter" } }
Stautist.BossDB[554] = { name = "The Mechanar", type = "dungeon", tier="TBC", textureID = 554, end_boss_id = 19220, bosses = { [19219]="Mechano-Lord Capacitus", [19221]="Nethermancer Sepethrea", [19220]="Pathaleon the Calculator" } }
Stautist.BossDB[585] = { name = "Magisters' Terrace", type = "dungeon", tier="TBC", textureID = 585, end_boss_id = 24664, bosses = { [24723]="Selin Fireheart", [24744]="Vexallus", [24560]="Priestess Delrissa", [24664]="Kael'thas Sunstrider" } }


-- ============================================================================
-- WRATH OF THE LICH KING (WotLK)
-- ============================================================================

-- [Icecrown Citadel]
Stautist.BossDB[631] = { name = "Icecrown Citadel", type = "raid", tier = "WotLK", textureID = 631, end_boss_id = 36597,
    bosses = {
        [36612] = { name = "Lord Marrowgar", order = 1 },
        [36855] = { name = "Lady Deathwhisper", order = 2 },
        [36948] = { name = "Gunship Battle", encounter = "gunship", order = 3 },
        [36939] = { name = "Gunship Battle", encounter = "gunship", order = 3 },
        [37813] = { name = "Deathbringer Saurfang", order = 4 },
        [36626] = { name = "Festergut", order = 5 },
        [36627] = { name = "Rotface", order = 6 },
        [36678] = { name = "Professor Putricide", order = 7 },
        [37970] = { name = "Blood Prince Council", order = 8 },
        [37955] = { name = "Blood-Queen Lana'thel", order = 9 },
        [36789] = { name = "Valithria Dreamwalker", order = 10 },
        [36853] = { name = "Sindragosa", order = 11 },
        [36597] = { name = "The Lich King", order = 12 }
    }
}

-- [Ulduar]
Stautist.BossDB[603] = { name = "Ulduar", type = "raid", tier = "WotLK", textureID = 603, end_boss_id = 33288,
    bosses = {
        [33113]="Flame Leviathan", [33118]="Ignis the Furnace Master", [33186]="Razorscale",
        [33293]="XT-002 Deconstructor", [32867]="Assembly of Iron", [32906]="Kologarn",
        [33515]="Auriaya", [32845]="Hodir", [32865]="Thorim", [32901]="Freya",
        [33350]="Mimiron", [33271]="General Vezax", [33288]="Yogg-Saron", [32871]="Algalon the Observer"
    }
}

-- [Trial of the Crusader]
Stautist.BossDB[649] = { name = "Trial of the Crusader", type = "raid", tier = "WotLK", textureID = 649, end_boss_id = 34564,
    bosses = {
        [34797]="Northrend Beasts", [34780]="Lord Jaraxxus", 
        [34461]="Faction Champions", -- Horde
        [34451]="Faction Champions", -- Alliance
        [34496]="Twin Val'kyr", [34564]="Anub'arak"
    }
}

-- [Naxxramas]
Stautist.BossDB[533] = { name = "Naxxramas", type = "raid", tier = "WotLK", textureID = 533, end_boss_id = 15990,
    bosses = {
        -- Spider Wing
        [15956] = { name = "Anub'Rekhan", order = 1 },
        [15953] = { name = "Grand Widow Faerlina", order = 2 },
        [15952] = { name = "Maexxna", order = 3 },
        -- Plague Wing
        [15954] = { name = "Noth the Plaguebringer", order = 4 },
        [15936] = { name = "Heigan the Unclean", order = 5 },
        [16011] = { name = "Loatheb", order = 6 },
        -- Military Wing
        [16061] = { name = "Instructor Razuvious", order = 7 },
        [16060] = { name = "Gothik the Harvester", order = 8 },
        [16064] = { name = "Four Horsemen", order = 9 },
        -- Construct Wing
        [16028] = { name = "Patchwerk", order = 10 },
        [15931] = { name = "Grobbulus", order = 11 },
        [15932] = { name = "Gluth", order = 12 },
        [15928] = { name = "Thaddius", order = 13 },
        -- Frost Wyrm Lair
        [15989] = { name = "Sapphiron", order = 14 },
        [15990] = { name = "Kel'Thuzad", order = 15 }
    }
}

-- [The Ruby Sanctum]
Stautist.BossDB[724] = { name = "The Ruby Sanctum", type = "raid", tier = "WotLK", textureID = 724, end_boss_id = 39863,
    bosses = { [39863]="Halion", [39746]="Zarithrian", [39747]="Saviana", [39751]="Baltharus" }
}

-- [Onyxia's Lair] (WotLK Level 80 Version)
Stautist.BossDB[249] = { name = "Onyxia's Lair", type = "raid", tier = "WotLK", textureID = 249, end_boss_id = 10184,
    bosses = { [10184]="Onyxia" }
}

-- [The Eye of Eternity]
Stautist.BossDB[529] = { name = "The Eye of Eternity", type = "raid", tier = "WotLK", textureID = 529, end_boss_id = 28859,
    bosses = { [28859]="Malygos" }
}

-- [The Obsidian Sanctum]
Stautist.BossDB[615] = { name = "The Obsidian Sanctum", type = "raid", tier = "WotLK", textureID = 615, end_boss_id = 28860,
    bosses = { [28860]="Sartharion", [30449]="Shadron", [30452]="Tenebron", [30451]="Vesperon" }
}

-- [Vault of Archavon]
Stautist.BossDB[624] = { name = "Vault of Archavon", type = "raid", tier = "WotLK", textureID = 624, end_boss_id = 38433,
    bosses = { [31125]="Archavon", [33993]="Emalon", [35013]="Koralon", [38433]="Toravon" }
}

-- [WotLK Dungeons]
Stautist.BossDB[601] = { name = "Azjol-Nerub", type = "dungeon", tier="WotLK", textureID = 601, end_boss_id = 29120, bosses = { [28684]="Krik'thir", [28921]="Hadronox", [29120]="Anub'arak" } }
Stautist.BossDB[619] = { name = "Ahn'kahet", type = "dungeon", tier="WotLK", textureID = 619, end_boss_id = 29311, bosses = { [29309]="Elder Nadox", [29308]="Prince Taldaram", [29310]="Jedoga", [29311]="Herald Volazj", [30258]="Amanitar" } }
Stautist.BossDB[600] = { name = "Drak'Tharon Keep", type = "dungeon", tier="WotLK", textureID = 600, end_boss_id = 26632, bosses = { [26630]="Trollgore", [26631]="Novos", [27483]="King Dred", [26632]="The Prophet Tharon'ja" } }
Stautist.BossDB[604] = { 
    name = "Gundrak", type = "dungeon", tier="WotLK", textureID = 604, end_boss_id = 29306, 
    bosses = { 
        [29304] = { name = "Slad'ran", order = 1 },
        [29305] = { name = "Moorabi", order = 2 },
        [29307] = { name = "Drakkari Colossus", order = 3 },
        [29932] = { name = "Eck the Ferocious", order = 3.5, heroicOnly = true }, -- Added Heroic Only
        [29306] = { name = "Gal'darah", order = 4 }
    } 
}
Stautist.BossDB[602] = { name = "Halls of Lightning", type = "dungeon", tier="WotLK", textureID = 602, end_boss_id = 28923, bosses = { [28586]="General Bjarngrim", [28587]="Volkhan", [28546]="Ionar", [28923]="Loken" } }
Stautist.BossDB[599] = { name = "Halls of Stone", type = "dungeon", tier="WotLK", textureID = 599, end_boss_id = 27978, bosses = { [27975]="Maiden of Grief", [27977]="Krystallus", [27978]="Sjonnir The Ironshaper" } }
Stautist.BossDB[576] = { name = "The Nexus", type = "dungeon", tier="WotLK", textureID = 576, end_boss_id = 26723, bosses = { [26731]="Grand Magus Telestra", [26763]="Anomalus", [26794]="Ormorok", [26723]="Keristrasza" } }
Stautist.BossDB[578] = { name = "The Oculus", type = "dungeon", tier="WotLK", textureID = 578, end_boss_id = 27656, bosses = { [27654]="Drakos", [27447]="Varos", [27655]="Mage-Lord Urom", [27656]="Ley-Guardian Eregos" } }
Stautist.BossDB[574] = { name = "Utgarde Keep", type = "dungeon", tier="WotLK", textureID = 574, end_boss_id = 23980, bosses = { [23953]="Prince Keleseth", [24201]="Dalronn", [23980]="Ingvar the Plunderer" } }
Stautist.BossDB[575] = { name = "Utgarde Pinnacle", type = "dungeon", tier="WotLK", textureID = 575, end_boss_id = 26861, bosses = { [26668]="Svala Sorrowgrave", [26546]="Gortok", [26687]="Skadi", [26861]="King Ymiron" } }
Stautist.BossDB[595] = { name = "Culling of Stratholme", type = "dungeon", tier="WotLK", textureID = 595, end_boss_id = 26521, bosses = { [26532]="Meathook", [26529]="Salramm", [26530]="Chrono-Lord Epoch", [26521]="Mal'Ganis" } }
-- Violet Hold (Wave based, Cyanigosa is the end boss)
Stautist.BossDB[608] = { 
    name = "Violet Hold", type = "dungeon", tier="WotLK", textureID = 608, end_boss_id = 31134, 
    bosses = { 
        [900001] = { name="Portal Boss 1", encounter="vh_1", order=1 },
        [900002] = { name="Portal Boss 2", encounter="vh_2", order=2 },
        [31134]  = { name="Cyanigosa", order=3, heroicOnly = true }, -- Added Heroic Only per request

        -- Random Pool
        [29315] = { name="Erekem", hidden=true },
        [29316] = { name="Moragg", hidden=true },
        [29313] = { name="Ichoron", hidden=true },
        [29312] = { name="Xevozz", hidden=true },
        [29314] = { name="Lavanthor", hidden=true },
        [29266] = { name="Zuramat the Obliterator", hidden=true },
    } 
}
Stautist.BossDB[650] = { name = "Trial of the Champion", type = "dungeon", tier="WotLK", textureID = 650, end_boss_id = 35451, 
    bosses = { 
        [34566]="Grand Champions", 
        
        -- Argent Confessor (Linked by 'encounter="confessor"')
        [35119]={ name="Eadric the Pure", encounter="confessor", order=2 },
        [34928]={ name="Confessor Paletress", encounter="confessor", order=2 },
        
        [35451]="The Black Knight" 
    } 
}
Stautist.BossDB[632] = { name = "Forge of Souls", type = "dungeon", tier="WotLK", textureID = 632, end_boss_id = 36502, bosses = { [36497]="Bronjahm", [36502]="Devourer of Souls" } }
Stautist.BossDB[658] = { name = "Pit of Saron", type = "dungeon", tier="WotLK", textureID = 658, end_boss_id = 36658, bosses = { [36494]="Forgemaster Garfrost", [36477]="Krick and Ick", [36658]="Scourgelord Tyrannus" } }
Stautist.BossDB[668] = { name = "Halls of Reflection", type = "dungeon", tier="WotLK", textureID = 668, end_boss_id = 38113, bosses = { [38112]="Falric", [38113]="Marwyn", [37069]="The Lich King (Escape)" } }

-- ============================================================================
-- INITIALIZATION LOGIC
-- ============================================================================

Stautist.NPC_TO_ZONE = {}

function Stautist:LoadBossDatabase(silent)
    local count = 0
    local zones = 0
    for zoneID, data in pairs(self.BossDB) do
        zones = zones + 1
        for npcID, name in pairs(data.bosses) do
            self.NPC_TO_ZONE[npcID] = zoneID
            count = count + 1
        end
    end
    if not silent then
        self:Print("Database initialized: " .. count .. " bosses across " .. zones .. " zones.")
    end
end