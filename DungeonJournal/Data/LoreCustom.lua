-- Lore written for this journal (summaries of established Warcraft lore) for the raids,
-- whose Adventure Guide text is not in the retail game files, and for the dungeons that were
-- rebuilt after Wrath of the Lich King. Retail Adventure Guide text (Data/Lore.lua) wins where
-- both exist.
local DJ = DungeonJournal

local instances = {
    -- Rebuilt dungeons: lore as they stand in 3.3.5a
    Ragefire = "Beneath Orgrimmar lies a network of volcanic caverns that the Horde has never fully tamed. Here the Searing Blade, a cult of demon-worshipping orcs, hides among troglodytes and fire elementals, plotting to bring the Burning Legion's corruption back into the heart of the Horde.",
    TheDeadmines = "The Deadmines were once among the richest gold mines in Stormwind's lands. When the stonemasons who rebuilt Stormwind after the First War were refused payment by the House of Nobles, they rioted and were driven out of the city. Led by Edwin VanCleef, they became the Defias Brotherhood, and in the abandoned mines beneath Moonbrook they now build a juggernaut of a warship to strike back at the kingdom.",
    ShadowfangKeep = "Shadowfang Keep was the seat of Baron Silverlaine before the Scourge swept through Lordaeron. The mad archmage Arugal, who summoned the worgen to fight the Scourge, has claimed the keep for himself. He now calls the beasts his children and holds the ruined fortress above Pyrewood Village.",
    ScarletMonasteryGraveyard = "Behind the walls of the Scarlet Monastery lies the crusade's graveyard, where the fallen are buried and heretics are interrogated. The dead do not rest easily here: restless spirits roam the crypts, while Scarlet zealots and the bloodmage Thalnos guard its halls.",
    ScarletMonasteryLibrary = "The Scarlet Crusade gathers its knowledge in the Athenaeum, a library of tomes on necromancy, the Light and the Scourge. Houndmaster Loksey patrols its halls while Arcanist Doan guards the crusade's secrets and its most valuable relics.",
    ScarletMonasteryArmory = "The armory houses the training grounds and forges of the Scarlet Crusade. Here new recruits are hardened into zealous soldiers under the watch of Herod, the crusade's champion.",
    ScarletMonasteryCathedral = "The cathedral is the heart of the Scarlet Monastery and of the crusade's fanaticism. Scarlet Commander Mograine and High Inquisitor Whitemane lead the faithful here, unaware that the crusade's Grand Crusader is a dreadlord in disguise.",
    Scholomance = "In the crypts beneath Caer Darrow, the Cult of the Damned runs Scholomance, a school of necromancy where the living are taught to serve the Scourge. The Barov family traded their land to the cult for the promise of eternal life; now Darkmaster Gandling rules the school and its instructors raise new servants for the Lich King.",
    ["Zul'Gurub"] = "Zul'Gurub was the capital of the Gurubashi trolls until the empire tore itself apart. Now the Atal'ai priests have summoned the blood god Hakkar the Soulflayer back into the world. Hakkar has bound the high priests of the Gurubashi to his will, and if he is not stopped in his temple he will spread his corruption far beyond the jungle.",
    ZulAman = "Zul'Aman is the capital of the Amani trolls of the Ghostlands, sworn enemies of the high elves for thousands of years. Zul'jin, the legendary warlord whose wars against the elves cost him an eye and an arm, has returned. With the help of Hex Lord Malacrass he is draining the power of the troll animal gods to forge an army and take his revenge.",

    -- Classic raids
    MoltenCore = "Molten Core lies at the very bottom of Blackrock Mountain, in a realm of fire and magma. Here Ragnaros the Firelord, summoned by the Dark Iron dwarves centuries ago, gathers his elemental lieutenants and prepares to burn the world above.",
    BlackwingLair = "At the top of Blackrock Spire, Nefarian, son of Deathwing, has built a laboratory where he breeds chromatic dragons, an unstable mix of every dragonflight's power, to win the war for Blackrock Mountain and rule the world. Only the strongest heroes can storm his lair and stop the black dragon's experiments.",
    TheRuinsofAhnQiraj = "Behind the Scarab Wall in Silithus, the qiraji have woken. The Ruins of Ahn'Qiraj are the outer defences of their ancient city, where General Rajaxx commands the silithid hordes and Ossirian the Unscarred guards the way to the temple.",
    TheTempleofAhnQiraj = "Deep within Ahn'Qiraj, the Old God C'Thun waits in the dark. The qiraji serve him under Emperors Vek'lor and Vek'nilash, and the temple is full of his servants. A thousand years ago the night elves and the bronze dragons sealed the qiraji away. Now the gates are open again.",

    -- Burning Crusade raids
    Karazhan = "Karazhan was the home of Medivh, the last Guardian of Tirisfal, who opened the Dark Portal for the Burning Legion. Since his death the tower in Deadwind Pass has been haunted by his memories, demons and restless spirits, and something dark stirs in its depths.",
    GruulsLair = "The gronn Gruul the Dragonkiller rules over the ogres of Blade's Edge from his lair, where the bones of the dragons he has slain litter the ground. The ogres serve him in fear, and their High King Maulgar guards the way to his master.",
    MagtheridonsLair = "Beneath Hellfire Citadel, the pit lord Magtheridon, once lord of Outland, lies chained by Illidan's forces. The fel orcs draw his blood to create more of their kind. Freeing the citadel means facing the pit lord himself.",
    SerpentshrineCavern = "Within Coilfang Reservoir, Lady Vashj, Illidan's naga lieutenant, drains the waters of Zangarmarsh to serve her master. Her Serpentshrine Cavern hides her elite naga, corrupted elementals and creatures of the deep.",
    TempestKeep = "Tempest Keep is a naaru fortress that Kael'thas Sunstrider and his blood elves seized from the naaru. In its heart, the Eye, Kael'thas commands his advisors and the phoenix Al'ar while he prepares for a power greater than Illidan's.",
    HyjalSummit = "In the Caverns of Time, the bronze dragonflight preserves the Battle of Mount Hyjal, where the night elves, humans and orcs stood together to defend the World Tree against Archimonde. The infinite dragonflight seeks to change history, so heroes must make sure the battle ends as it should.",
    BlackTemple = "The Black Temple, once the draenei's Temple of Karabor, is now Illidan Stormrage's seat of power in Shadowmoon Valley. With Akama and his broken draenei in revolt, and Maiev Shadowsong close behind, the time has come to storm the temple and confront the Betrayer.",
    SunwellPlateau = "On the Isle of Quel'Danas, Kael'thas has given the Sunwell over to the Burning Legion. Through it the demon lord Kil'jaeden is trying to enter Azeroth. The Shattered Sun Offensive must fight its way through the plateau before the Deceiver arrives.",

    -- Wrath of the Lich King raids
    NaxxramasWrath = "The necropolis of Naxxramas, seat of the lich Kel'Thuzad, now hovers over the Dragonblight. Its four quarters hold the Scourge's best: the nerubians of the Arachnid Quarter, the death knights of the Military Quarter, the plague-makers of the Plague Quarter and the abominations of the Construct Quarter.",
    ObsidianSanctum = "Beneath Wyrmrest Temple, in the Chamber of the Aspects, the black dragon Sartharion guards a clutch of twilight dragon eggs with three twilight drakes. Deathwing's flight is breeding a new and dangerous dragonflight under the noses of the other aspects.",
    TheEyeOfEternity = "Malygos, the Aspect of Magic, has gone mad. He has declared war on all mortal spellcasters and is draining the magic of Azeroth through the Nexus to keep it from those he thinks misuse it. In his domain, the Eye of Eternity, he must be stopped before the Nexus War destroys the world.",
    VaultofArchavon = "Beneath Wintergrasp Fortress lies a titan vault guarded by stone, storm, flame and ice watchers. Only the faction that holds Wintergrasp may enter and face its keepers.",
    Ulduar = "Ulduar is a titan city in the Storm Peaks, built to imprison the Old God Yogg-Saron. Its keepers, Hodir, Freya, Thorim and Mimiron, have fallen under the Old God's influence. Loken's revolt has broken the city's defences, and Algalon the Observer has been sent to judge whether Azeroth should be remade.",
    TrialoftheCrusader = "Tirion Fordring's Argent Crusade has built a coliseum in Icecrown to find champions worthy of facing the Lich King. In the Trial of the Crusader they face the beasts of Northrend, a demon lord, the champions of the opposing faction, the Lich King's val'kyr and finally the ancient nerubian king Anub'arak.",
    WrathOnyxiasLair = "Onyxia, daughter of Deathwing, once infiltrated Stormwind in human form. Defeated but not destroyed, she has regained her strength in her lair in Dustwallow Marsh, where her brood still gathers.",
    IcecrownCitadel = "Icecrown Citadel is the fortress of the Lich King, built on the glacier where the Frozen Throne lies. Its spire holds his greatest servants. Tirion Fordring and the Ashen Verdict lead the assault to the Frozen Throne itself.",
    RubySanctum = "The Ruby Sanctum, the red dragonflight's sanctuary beneath Wyrmrest Temple, has been attacked by the black dragonflight's twilight forces. Their leader Halion, a twilight dragon of terrifying power, is bridging the physical and twilight realms.",
}

local bosses = {
    -- Ragefire Chasm
    ["Ragefire#1"] = "Taragaman is a demon kept in the depths of Ragefire Chasm by the Searing Blade, a fearsome guardian of the cult's lair.",
    ["Ragefire#2"] = "The warlock Jergosh leads the Searing Blade's rituals and is ready to call on the Legion's power to defend the cult.",
    -- The Deadmines
    ["TheDeadmines#1"] = "Rhahk'Zor is the ogre foreman who keeps the Defias laborers working in the mines.",
    ["TheDeadmines#3"] = "Sneed's Shredder is driven by the Defias lumbermaster Sneed and saws timber for the juggernaut in the mines.",
    ["TheDeadmines#5"] = "Gilnid the Smelter melts down the ore that the Defias use to build their ship.",
    ["TheDeadmines#6"] = "Mr. Smite is the first mate of Edwin VanCleef's ship, as tough as he is loyal to his boss.",
    ["TheDeadmines#7"] = "Captain Greenskin commands the Defias pirates who sail the juggernaut.",
    ["TheDeadmines#8"] = "Edwin VanCleef was the stonemason who led the rebuilding of Stormwind. When the nobles refused to pay, he formed the Defias Brotherhood. He now commands it from his ship in the mines.",
    ["TheDeadmines#9"] = "Cookie runs the galley on VanCleef's ship and swings a ladle with surprising force.",
    -- Shadowfang Keep
    ["ShadowfangKeep#4"] = "Baron Silverlaine was lord of the keep before the Scourge came. His ghost still haunts his halls.",
    ["ShadowfangKeep#5"] = "Commander Springvale, once a paladin of the Silver Hand, now serves Arugal and the darkness that has claimed the keep.",
    ["ShadowfangKeep#9"] = "Fenrus the Devourer is one of the largest and most savage of Arugal's worgen.",
    ["ShadowfangKeep#10"] = "Wolf Master Nandos commands Arugal's worgen packs from the keep's courtyard.",
    ["ShadowfangKeep#11"] = "Archmage Arugal of the Kirin Tor summoned the worgen to fight the Scourge, but lost control of them and his own sanity. He now calls the beasts his children and rules the keep from its highest tower.",
    -- Scarlet Monastery
    ["ScarletMonasteryGraveyard#1"] = "Interrogator Vishas gets confessions out of the crusade's prisoners, guilty or not.",
    ["ScarletMonasteryGraveyard#5"] = "The bloodmage Thalnos died in the crusade's service, and his tormented spirit now guards the graveyard.",
    ["ScarletMonasteryLibrary#1"] = "Houndmaster Loksey and his dogs patrol the halls of the library.",
    ["ScarletMonasteryLibrary#2"] = "Arcanist Doan is the crusade's master of magic and keeper of the library's secrets.",
    ["ScarletMonasteryArmory#1"] = "Herod, the Scarlet Champion, trains the crusade's soldiers and is a fierce warrior in his own right.",
    ["ScarletMonasteryCathedral#1"] = "High Inquisitor Fairbanks once served the Scarlet Crusade faithfully. Now he lies forgotten in the cathedral.",
    ["ScarletMonasteryCathedral#2"] = "Scarlet Commander Mograine leads the crusade's forces in the monastery, the son of Alexandros Mograine, the Ashbringer.",
    ["ScarletMonasteryCathedral#3"] = "High Inquisitor Whitemane is the crusade's most powerful priestess, able to raise her fallen allies.",
    -- Scholomance
    ["Scholomance#2"] = "Kirtonos the Herald is a monstrous winged servant of the school's masters who answers the call of a blood offering.",
    ["Scholomance#3"] = "Jandice Barov, one of the Barov heirs, gave up her life to the Scourge and now teaches illusion magic at the school.",
    ["Scholomance#4"] = "Rattlegore is a giant made of bones, built by the school's necromancers.",
    ["Scholomance#8"] = "Ras Frostwhisper is a lich who teaches the dark arts at Scholomance.",
    ["Scholomance#13"] = "Lord Alexei Barov sold his family's lands to the Cult of the Damned in return for eternal life, and serves the school as an undead lord.",
    ["Scholomance#14"] = "Lady Illucia Barov, like her husband, gave herself to the Scourge and now haunts the halls of the school.",
    ["Scholomance#15"] = "Darkmaster Gandling is the headmaster of Scholomance, one of Kel'Thuzad's most powerful servants.",

    -- Molten Core
    ["MoltenCore#1"] = "Lucifron, a flamewalker lieutenant of Ragnaros, guards the entrance of the Molten Core with his protectors.",
    ["MoltenCore#2"] = "Magmadar is the oldest and largest core hound, a beast that scorches the ground and terrifies its enemies.",
    ["MoltenCore#3"] = "Gehennas, a flamewalker lieutenant of Ragnaros, curses those who would disturb his master.",
    ["MoltenCore#4"] = "Garr is a giant fire elemental surrounded by firesworn servants.",
    ["MoltenCore#5"] = "Shazzrah is a flamewalker magus, master of arcane and fire magic.",
    ["MoltenCore#6"] = "Baron Geddon, a lord of the fire elementals, turns his enemies into living bombs.",
    ["MoltenCore#7"] = "Golemagg the Incinerator is a giant of molten stone who commands the core ragers.",
    ["MoltenCore#8"] = "Sulfuron Harbinger, Ragnaros' herald, leads the flamewalker priests.",
    ["MoltenCore#9"] = "Majordomo Executus is the steward of Ragnaros. He alone can summon the Firelord.",
    ["MoltenCore#10"] = "Ragnaros the Firelord was summoned into Blackrock Mountain by the Dark Iron dwarves during the War of the Three Hammers. Now he reigns from Molten Core.",
    -- Blackwing Lair
    ["BlackwingLair#1"] = "Razorgore the Untamed is a black dragon who guards the eggs in Nefarian's brood chamber.",
    ["BlackwingLair#2"] = "Vaelastrasz, once a red dragon consort of Alexstrasza, was captured by Nefarian and corrupted. Part of him still struggles against his master.",
    ["BlackwingLair#3"] = "Broodlord Lashlayer guards the dragonkin of the lair.",
    ["BlackwingLair#4"] = "Firemaw is one of Nefarian's black drakes.",
    ["BlackwingLair#5"] = "Ebonroc is one of Nefarian's black drakes.",
    ["BlackwingLair#6"] = "Flamegor is one of Nefarian's black drakes.",
    ["BlackwingLair#7"] = "Chromaggus is a monstrous two-headed result of Nefarian's chromatic experiments.",
    ["BlackwingLair#8"] = "Nefarian, son of Deathwing, rules Blackwing Lair in the guise of Lord Victor Nefarius. His chromatic dragons are the key to his plans for conquering Azeroth.",
    -- Zul'Gurub
    ["Zul'Gurub#1"] = "High Priestess Jeklik, servant of the bat god Hir'eek, was the first of the Gurubashi priests bound to Hakkar.",
    ["Zul'Gurub#2"] = "High Priest Venoxis channels the power of the snake god Hethiss.",
    ["Zul'Gurub#3"] = "High Priestess Mar'li serves the spider goddess Shadra.",
    ["Zul'Gurub#4"] = "Bloodlord Mandokir rides a raptor and executes Hakkar's enemies.",
    ["Zul'Gurub#9"] = "Gahz'ranka is a huge sea creature that lives in Zul'Gurub's waters.",
    ["Zul'Gurub#10"] = "High Priest Thekal serves the tiger god Shirvallah and can take on his form.",
    ["Zul'Gurub#11"] = "High Priestess Arlokk serves the panther god Bethekk.",
    ["Zul'Gurub#12"] = "Jin'do the Hexxer is Hakkar's most loyal servant, a master of hexes and shadow magic.",
    ["Zul'Gurub#13"] = "Hakkar the Soulflayer is the blood god of the Gurubashi trolls. Summoned again by the Atal'ai, he wants to break free and spread his corruption across the world.",
    -- Ruins of Ahn'Qiraj
    ["TheRuinsofAhnQiraj#1"] = "Kurinnaxx is a giant silithid sandstalker guarding the entrance to the ruins.",
    ["TheRuinsofAhnQiraj#2"] = "General Rajaxx commands the qiraji army in the ruins, sending wave after wave of soldiers against intruders.",
    ["TheRuinsofAhnQiraj#3"] = "Moam is a construct of obsidian that drains mana from its enemies.",
    ["TheRuinsofAhnQiraj#4"] = "Buru the Gorger is a huge silithid that guards a nest of eggs.",
    ["TheRuinsofAhnQiraj#5"] = "Ayamiss the Hunter is a giant flying silithid wasp.",
    ["TheRuinsofAhnQiraj#6"] = "Ossirian the Unscarred is the general of the qiraji, protected by crystals of power.",
    -- Temple of Ahn'Qiraj
    ["TheTempleofAhnQiraj#1"] = "The Prophet Skeram speaks for C'Thun and is a master of illusions.",
    ["TheTempleofAhnQiraj#2"] = "Lord Kri, Princess Yauj and Vem are the qiraji royal family, three bugs who fight as one.",
    ["TheTempleofAhnQiraj#3"] = "Battleguard Sartura is the protector of the temple.",
    ["TheTempleofAhnQiraj#4"] = "Fankriss the Unyielding is a giant silithid that commands the temple's hives.",
    ["TheTempleofAhnQiraj#5"] = "Viscidus is a gigantic poisonous ooze.",
    ["TheTempleofAhnQiraj#6"] = "Princess Huhuran is a giant silithid wasp.",
    ["TheTempleofAhnQiraj#7"] = "Emperors Vek'lor and Vek'nilash are the twin rulers of the qiraji, servants of C'Thun.",
    ["TheTempleofAhnQiraj#8"] = "Ouro is a huge sandworm that tunnels beneath the temple.",
    ["TheTempleofAhnQiraj#9"] = "C'Thun is an Old God, imprisoned by the titans beneath Ahn'Qiraj. From there he commands the qiraji and plots to free himself.",

    -- Karazhan
    ["Karazhan#1"] = "Attumen the Huntsman and his steed Midnight hunt in the stables of Karazhan.",
    ["Karazhan#5"] = "Moroes is the steward of Karazhan. He still runs the tower's endless banquet.",
    ["Karazhan#6"] = "The Maiden of Virtue punishes any who disturb the tower.",
    ["Karazhan#7"] = "The opera house still performs Medivh's favourite plays. Tonight's show: the Wizard of Oz.",
    ["Karazhan#8"] = "The opera house still performs Medivh's favourite plays. Tonight's show: the Big Bad Wolf.",
    ["Karazhan#9"] = "The opera house still performs Medivh's favourite plays. Tonight's show: Romulo and Julianne.",
    ["Karazhan#10"] = "The Curator is an arcane golem that guards the tower's menagerie.",
    ["Karazhan#11"] = "Terestian Illhoof is a demon who has made his home in the tower's library.",
    ["Karazhan#12"] = "The Shade of Aran is the ghost of Medivh's father, the mage Nielas Aran.",
    ["Karazhan#13"] = "Netherspite is a nether dragon that draws power from the tower's ley lines.",
    ["Karazhan#14"] = "A game of chess in which the pieces are living beings.",
    ["Karazhan#15"] = "Prince Malchezaar is an eredar demon lord who has taken over the top of the tower.",
    ["Karazhan#16"] = "Nightbane is the corrupted remains of the dragon Arcanagos, killed by Medivh.",
    -- Zul'Aman
    ["ZulAman#1"] = "Akil'zon is the eagle avatar of the Amani, empowered by Zul'jin.",
    ["ZulAman#2"] = "Nalorakk is the bear avatar of the Amani, empowered by Zul'jin.",
    ["ZulAman#3"] = "Jan'alai is the dragonhawk avatar of the Amani, empowered by Zul'jin.",
    ["ZulAman#4"] = "Halazzi is the lynx avatar of the Amani, empowered by Zul'jin.",
    ["ZulAman#5"] = "Hex Lord Malacrass drains the power of the Amani gods and gives it to Zul'jin.",
    ["ZulAman#6"] = "Zul'jin is the legendary warlord of the Amani trolls, sworn enemy of the high elves.",
    -- Gruul's Lair
    ["GruulsLair#1"] = "High King Maulgar, king of the ogres of Blade's Edge, guards the way to his master Gruul with his council.",
    ["GruulsLair#2"] = "Gruul the Dragonkiller is the gronn lord of Blade's Edge, famed for killing dragons.",
    -- Magtheridon's Lair
    ["MagtheridonsLair#1"] = "Magtheridon, a pit lord, ruled Outland until Illidan captured him. Now his blood fuels the fel orcs of Hellfire Citadel.",
    -- Serpentshrine Cavern
    ["SerpentshrineCavern#1"] = "Hydross the Unstable is a water elemental corrupted by Lady Vashj.",
    ["SerpentshrineCavern#2"] = "The Lurker Below is a huge creature lurking in Serpentshrine's waters.",
    ["SerpentshrineCavern#3"] = "Leotheras the Blind is one of Illidan's demon hunters, locked in a struggle with the demon within him.",
    ["SerpentshrineCavern#4"] = "Fathom-Lord Karathress commands Vashj's naga.",
    ["SerpentshrineCavern#5"] = "Morogrim Tidewalker is a giant sea creature that commands the waters.",
    ["SerpentshrineCavern#6"] = "Lady Vashj, leader of the naga, serves Illidan and drains the waters of Zangarmarsh to strengthen his armies.",
    -- Tempest Keep
    ["TempestKeep#1"] = "Al'ar is a phoenix god who serves Kael'thas.",
    ["TempestKeep#2"] = "The Void Reaver is a giant arcane construct guarding Tempest Keep.",
    ["TempestKeep#3"] = "High Astromancer Solarian is a blood elf mage who studies the stars for Kael'thas.",
    ["TempestKeep#4"] = "Kael'thas Sunstrider, prince of the blood elves, rules Tempest Keep with his four advisors.",
    -- Hyjal Summit
    ["HyjalSummit#1"] = "Rage Winterchill is a lich who leads the Scourge against the humans of Hyjal.",
    ["HyjalSummit#2"] = "Anetheron is a dreadlord who leads the Legion's forces against the humans of Hyjal.",
    ["HyjalSummit#3"] = "Kaz'rogal is a doom guard who leads the Legion's forces against the orcs of Hyjal.",
    ["HyjalSummit#4"] = "Azgalor is a pit lord who leads the Legion's forces against the orcs of Hyjal.",
    ["HyjalSummit#5"] = "Archimonde the Defiler, one of the leaders of the Burning Legion, wants to destroy the World Tree.",
    -- Black Temple
    ["BlackTemple#1"] = "High Warlord Naj'entus guards the temple's waters.",
    ["BlackTemple#2"] = "Supremus is a giant infernal that guards the temple.",
    ["BlackTemple#3"] = "The Shade of Akama is the spirit of the broken leader, imprisoned by Illidan.",
    ["BlackTemple#4"] = "Gurtogg Bloodboil is a fel orc leader in the service of Illidan.",
    ["BlackTemple#5"] = "The Reliquary of Souls holds the tormented souls of the draenei.",
    ["BlackTemple#6"] = "Teron Gorefiend, the first death knight, has returned to serve Illidan.",
    ["BlackTemple#7"] = "Mother Shahraz is a shivarra demon who leads Illidan's demons.",
    ["BlackTemple#8"] = "The Illidari Council: Gathios the Shatterer, High Nethermancer Zerevor, Lady Malande and Veras Darkshadow.",
    ["BlackTemple#9"] = "Illidan Stormrage, the Betrayer, rules Outland from the Black Temple.",
    -- Sunwell Plateau
    ["SunwellPlateau#1"] = "Kalecgos, a blue dragon, is trying to break free from Sathrovarr the Corruptor's control.",
    ["SunwellPlateau#2"] = "Brutallus is a pit lord who guards the way to the Sunwell.",
    ["SunwellPlateau#3"] = "Felmyst is the corrupted remains of Madrigosa, a blue dragon killed by Brutallus.",
    ["SunwellPlateau#4"] = "The Eredar Twins, Lady Sacrolash and Grand Warlock Alythess, guard the Sunwell.",
    ["SunwellPlateau#5"] = "M'uru is a naaru, captured by Kael'thas and used to power the Sunwell.",
    ["SunwellPlateau#6"] = "Kil'jaeden the Deceiver, leader of the Burning Legion, is trying to enter Azeroth through the Sunwell.",

    -- Naxxramas
    ["NaxxramasWrath#1"] = "Anub'Rekhan is a nerubian crypt lord who serves Kel'Thuzad.",
    ["NaxxramasWrath#2"] = "Grand Widow Faerlina leads the Cult of the Damned in the Arachnid Quarter.",
    ["NaxxramasWrath#3"] = "Maexxna is a giant spider in the Arachnid Quarter.",
    ["NaxxramasWrath#4"] = "Noth the Plaguebringer is a necromancer who spreads the plague.",
    ["NaxxramasWrath#5"] = "Heigan the Unclean is a plague-maker of the Plague Quarter.",
    ["NaxxramasWrath#6"] = "Loatheb is a giant fungal creature in the Plague Quarter.",
    ["NaxxramasWrath#7"] = "Instructor Razuvious trains the death knights of the Military Quarter.",
    ["NaxxramasWrath#8"] = "Gothik the Harvester is a necromancer who raises the dead in the Military Quarter.",
    ["NaxxramasWrath#9"] = "The Four Horsemen are the Lich King's mightiest death knights.",
    ["NaxxramasWrath#11"] = "Grobbulus is an abomination that injects its enemies with mutagens.",
    ["NaxxramasWrath#12"] = "Gluth is a giant plague hound that devours zombies.",
    ["NaxxramasWrath#13"] = "Thaddius is a giant abomination, powered by Stalagg and Feugen.",
    ["NaxxramasWrath#14"] = "Sapphiron is a frost wyrm, a blue dragon raised by the Scourge.",
    ["NaxxramasWrath#15"] = "Kel'Thuzad is the lich who rules Naxxramas in the name of the Lich King.",
    -- Obsidian Sanctum
    ["ObsidianSanctum#1"] = "Sartharion, the Onyx Guardian, is a black dragon guarding the twilight eggs.",
    -- Eye of Eternity
    ["TheEyeOfEternity#1"] = "Malygos is the Aspect of Magic, driven mad by Deathwing.",
    -- Vault of Archavon
    ["VaultofArchavon#1"] = "Archavon the Stone Watcher is a titan construct.",
    ["VaultofArchavon#2"] = "Emalon the Storm Watcher is a titan construct.",
    ["VaultofArchavon#3"] = "Koralon the Flame Watcher is a titan construct.",
    ["VaultofArchavon#4"] = "Toravon the Ice Watcher is a titan construct.",
    -- Trial of the Crusader
    ["TrialoftheCrusader#1"] = "Gormok the Impaler, Acidmaw, Dreadscale and Icehowl are Northrend's most dangerous beasts.",
    ["TrialoftheCrusader#2"] = "Lord Jaraxxus is an eredar lord of the Burning Legion, summoned by Wilfred Fizzlebang.",
    ["TrialoftheCrusader#3"] = "The champions of the opposing faction.",
    ["TrialoftheCrusader#4"] = "Fjola Lightbane and Eydis Darkbane are val'kyr twins, servants of the Lich King.",
    ["TrialoftheCrusader#5"] = "Anub'arak is the ancient nerubian king, raised by the Lich King.",
    -- Onyxia's Lair
    ["WrathOnyxiasLair#1"] = "Onyxia is the daughter of Deathwing and the brood mother of the black dragonflight.",
    -- Icecrown Citadel
    ["IcecrownCitadel#1"] = "Lord Marrowgar is a giant made of bones who guards the citadel's entrance.",
    ["IcecrownCitadel#2"] = "Lady Deathwhisper leads the Cult of the Damned.",
    ["IcecrownCitadel#3"] = "An airship battle between the Alliance and Horde fleets.",
    ["IcecrownCitadel#4"] = "Deathbringer Saurfang is the son of High Overlord Saurfang, raised as a death knight.",
    ["IcecrownCitadel#5"] = "Festergut is an abomination created by Professor Putricide.",
    ["IcecrownCitadel#6"] = "Rotface is an abomination created by Professor Putricide.",
    ["IcecrownCitadel#7"] = "Professor Putricide is the Scourge's chief plague-maker.",
    ["IcecrownCitadel#8"] = "The Blood Prince Council: Princes Keleseth, Taldaram and Valanar.",
    ["IcecrownCitadel#9"] = "Blood-Queen Lana'thel is the leader of the San'layn vampires.",
    ["IcecrownCitadel#10"] = "Valithria Dreamwalker is a green dragon held captive by the Scourge.",
    ["IcecrownCitadel#11"] = "Sindragosa was the consort of Malygos, now a frost wyrm in the service of the Lich King.",
    ["IcecrownCitadel#12"] = "The Lich King, Arthas Menethil, rules the Scourge from the Frozen Throne.",
    -- Ruby Sanctum
    ["RubySanctum#1"] = "Halion, the Twilight Destroyer, is a powerful twilight dragon who leads the assault on the Ruby Sanctum.",
}

-- Data/Lore.lua (retail Adventure Guide text) takes priority.
for k, v in pairs(instances) do
    if v and not DJ.Lore.instances[k] then DJ.Lore.instances[k] = v end
end
for k, v in pairs(bosses) do
    if not DJ.Lore.bosses[k] then DJ.Lore.bosses[k] = v end
end
