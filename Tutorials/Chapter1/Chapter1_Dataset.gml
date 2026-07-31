// GMLiteSearch Tutorial - Chapter 1 Dataset
// 55 fantasy RPG items spanning weapons, armor, potions, scrolls, and misc items.
// Used throughout Chapter 1 to demonstrate gmls_add_document and gmls_search.
//
// Usage:
//   var items = chapter1_get_items();
//   for (var i = 0; i < array_length(items); i++) {
//       gmls_add_document(items[i].id, items[i].name + ". " + items[i].desc);
//   }

function chapter1_get_items() {
    return [
        { id: "itm_001", name: "Iron Longsword", desc: "A sturdy iron longsword favored by town guards. Balanced and reliable, though nothing special." },
        { id: "itm_002", name: "Flametongue Blade", desc: "This enchanted sword bursts into flame when drawn, dealing extra fire damage to enemies." },
        { id: "itm_003", name: "Frostbite Rapier", desc: "A thin, quick blade infused with frost magic. Slows enemies on hit." },
        { id: "itm_004", name: "Rusty Shortsword", desc: "An old, worn shortsword. Better than nothing, but barely." },
        { id: "itm_005", name: "Dragonfang Katana", desc: "Forged from the fang of an ancient dragon, this katana cuts through armor with ease." },
        { id: "itm_006", name: "Silver Blessed Sword", desc: "A sword blessed by temple priests, silver-forged to be especially effective against undead creatures." },
        { id: "itm_007", name: "Twin Fang Daggers", desc: "A matched pair of curved daggers, ideal for quick strikes and backstabs." },
        { id: "itm_008", name: "Ceremonial Officer's Saber", desc: "An ornate saber carried by military officers. More decorative than deadly, but still sharp." },
        { id: "itm_009", name: "Warhammer of the Mountain", desc: "A massive two-handed warhammer capable of shattering stone and bone alike." },
        { id: "itm_010", name: "Goblin Cleaver Axe", desc: "A crude but effective axe used by orc warbands. Deals heavy damage to smaller foes." },
        { id: "itm_011", name: "Thunderstrike Maul", desc: "This enchanted maul crackles with lightning, stunning enemies on a critical hit." },
        { id: "itm_012", name: "Wooden Training Club", desc: "A simple wooden club used to train new recruits. Deals minimal damage." },
        { id: "itm_013", name: "Battle-Worn Battleaxe", desc: "A double-bladed battleaxe that has seen many campaigns. Heavy and slow, but powerful." },
        { id: "itm_014", name: "Longbow of the Forest Ranger", desc: "A finely crafted longbow made from ancient yew wood, favored by rangers and scouts." },
        { id: "itm_015", name: "Crossbow of Piercing", desc: "This crossbow fires bolts that ignore a portion of enemy armor." },
        { id: "itm_016", name: "Elven Hunting Bow", desc: "A lightweight bow crafted by elven artisans, prized for its accuracy at long range." },
        { id: "itm_017", name: "Repeating Hand Crossbow", desc: "A compact crossbow that fires multiple bolts in quick succession before reloading." },
        { id: "itm_018", name: "Staff of Arcane Fire", desc: "A wizard's staff imbued with raw fire magic, channeling powerful flame spells." },
        { id: "itm_019", name: "Novice Apprentice Wand", desc: "A basic wand given to apprentice mages just beginning their magical studies." },
        { id: "itm_020", name: "Staff of Frozen Tides", desc: "This staff summons freezing water and ice, effective against fire-based enemies." },
        { id: "itm_021", name: "Wand of Healing Light", desc: "A gentle wand that channels restorative light magic to heal wounds." },
        { id: "itm_022", name: "Plate Armor of the Vanguard", desc: "Heavy plate armor worn by frontline soldiers. Excellent physical protection but slows movement." },
        { id: "itm_023", name: "Dragonscale Chestplate", desc: "Armor crafted from the scales of a slain dragon, offering resistance to fire damage." },
        { id: "itm_024", name: "Rusted Iron Cuirass", desc: "An old, rusted breastplate. Provides basic protection but is showing its age." },
        { id: "itm_025", name: "Knight's Ceremonial Plate", desc: "Ornate plate armor worn during royal ceremonies. Surprisingly durable despite its polish." },
        { id: "itm_026", name: "Leather Scout Armor", desc: "Lightweight leather armor designed for scouts and rangers who need to move quickly and quietly." },
        { id: "itm_027", name: "Shadowweave Cloak", desc: "A dark, enchanted cloak that helps the wearer blend into shadows, ideal for stealth." },
        { id: "itm_028", name: "Traveler's Worn Tunic", desc: "A simple, well-worn tunic favored by traders and travelers on long journeys." },
        { id: "itm_029", name: "Elven Silk Robes", desc: "Elegant robes woven from enchanted silk, offering little physical defense but boosting magical power." },
        { id: "itm_030", name: "Archmage's Ceremonial Robes", desc: "Ornate robes worn by high-ranking mages, imbued with powerful protective enchantments." },
        { id: "itm_031", name: "Novice Mage Robes", desc: "Simple robes given to students at the mage academy. Offers minor magical resistance." },
        { id: "itm_032", name: "Robes of the Frost Warden", desc: "Enchanted robes that grant resistance to cold damage, worn by guardians of icy regions." },
        { id: "itm_033", name: "Minor Healing Potion", desc: "A small vial of red liquid that restores a modest amount of health when consumed." },
        { id: "itm_034", name: "Greater Healing Potion", desc: "A potent healing draught that restores a large amount of health instantly." },
        { id: "itm_035", name: "Potion of Fire Resistance", desc: "This potion grants temporary resistance to fire damage, useful against dragons and flame enemies." },
        { id: "itm_036", name: "Potion of Swift Feet", desc: "Drinking this potion temporarily increases the drinker's movement speed." },
        { id: "itm_037", name: "Antidote Vial", desc: "A bitter tonic that cures most forms of poison and venom." },
        { id: "itm_038", name: "Potion of Mana Restoration", desc: "This blue liquid restores a portion of the drinker's magical energy reserves." },
        { id: "itm_039", name: "Elixir of Giant Strength", desc: "A rare elixir that temporarily grants the strength of a giant, increasing carrying capacity and damage." },
        { id: "itm_040", name: "Potion of Invisibility", desc: "This shimmering potion renders the drinker invisible for a short duration." },
        { id: "itm_041", name: "Scroll of Fireball", desc: "A magical scroll that, when read, unleashes a single powerful fireball spell." },
        { id: "itm_042", name: "Scroll of Teleportation", desc: "Reading this scroll instantly teleports the user a short distance away." },
        { id: "itm_043", name: "Ancient Spellbook of Frost", desc: "A weathered tome containing forgotten ice magic, useful for mages seeking new spells." },
        { id: "itm_044", name: "Merchant's Trading Ledger", desc: "A dusty ledger filled with records of old trade routes and merchant contacts." },
        { id: "itm_045", name: "Scroll of Protection", desc: "This scroll grants the reader temporary magical protection from harm." },
        { id: "itm_046", name: "Rusty Old Key", desc: "A small, rusted key of unknown origin. It might open something important somewhere." },
        { id: "itm_047", name: "Golden Royal Seal", desc: "An ornate golden seal bearing the crest of the royal family, used to authenticate official documents." },
        { id: "itm_048", name: "Mysterious Glowing Orb", desc: "A strange orb that pulses with a faint, unexplained light. Its purpose is unclear." },
        { id: "itm_049", name: "Traveler's Worn Map", desc: "A hand-drawn map showing trade routes and points of interest across the region." },
        { id: "itm_050", name: "Silver Wedding Ring", desc: "A simple silver ring, likely a keepsake of great sentimental value to its original owner." },
        { id: "itm_051", name: "Dwarven Forge Hammer", desc: "A specialized hammer used by dwarven smiths to forge exceptional weapons and armor." },
        { id: "itm_052", name: "Fisherman's Lucky Charm", desc: "A small trinket said to bring good luck to fishermen. Probably just superstition." },
        { id: "itm_053", name: "Bag of Holding", desc: "An enchanted bag with far more storage space inside than its size would suggest." },
        { id: "itm_054", name: "Torch", desc: "A simple wooden torch, essential for lighting the way through dark caves and dungeons." },
        { id: "itm_055", name: "Rope, 50 feet", desc: "A sturdy 50-foot length of rope, useful for climbing, tying, or rescuing companions." }
    ];
}