// GMLiteSearch Tutorial - Chapter 3 Dataset
// 70 items from a general store's inventory: blacksmith goods, apothecary
// supplies, enchanted trinkets, general trade goods, food and provisions,
// and travel tools.
// Used throughout Chapter 3 to demonstrate fuzzy, prefix, hybrid, and n-gram search.
//
// Usage:
//   var shop_items = chapter3_get_shop_items();
//   for (var i = 0; i < array_length(shop_items); i++) {
//       var item = shop_items[i];
//       gmls_add_document_weighted(item.id, item.desc, { title: item.name, tags: [], timestamp: current_time });
//   }

function chapter3_get_shop_items() {
    return [
        { id: "shp_001", name: "Reinforced Battleaxe", desc: "A heavy battleaxe reinforced with steel plating along the blade edge." },
        { id: "shp_002", name: "Tempered Steel Dagger", desc: "A precisely balanced dagger, tempered for extra durability in combat." },
        { id: "shp_003", name: "Chainmail Hauberk", desc: "Full chainmail covering torso and arms, standard issue for town guards." },
        { id: "shp_004", name: "Blacksmith's Apron", desc: "A heavy leather apron worn while working at the forge." },
        { id: "shp_005", name: "Horseshoe Set", desc: "A matched set of four horseshoes, ready to be fitted by a farrier." },
        { id: "shp_006", name: "Warhammer Head", desc: "A replacement warhammer head, sold separately from the handle." },
        { id: "shp_007", name: "Iron Nails, Box of 100", desc: "A box containing one hundred iron nails for construction work." },
        { id: "shp_008", name: "Forge Bellows", desc: "Large leather bellows used to fan the flames of a blacksmith's forge." },
        { id: "shp_009", name: "Anvil, Small", desc: "A compact anvil suitable for a traveling smith's portable workshop." },
        { id: "shp_010", name: "Sharpening Whetstone", desc: "A fine-grained whetstone for sharpening blades and tools." },
        { id: "shp_011", name: "Resistance Tonic", desc: "A bitter tonic granting temporary resistance to poison and disease." },
        { id: "shp_012", name: "Apothecary's Mortar and Pestle", desc: "A stone mortar and pestle used for grinding herbs and minerals." },
        { id: "shp_013", name: "Dried Sage Bundle", desc: "A bundle of dried sage leaves, used in various remedies and rituals." },
        { id: "shp_014", name: "Vial of Nightshade Extract", desc: "A dangerous extract requiring careful handling, sold under license only." },
        { id: "shp_015", name: "Chamomile Tea Blend", desc: "A calming tea blend recommended for restless nights and anxious minds." },
        { id: "shp_016", name: "Willowbark Powder", desc: "Ground willowbark, traditionally used to ease pain and reduce fever." },
        { id: "shp_017", name: "Empty Glass Vials, Set of 6", desc: "Six empty glass vials, perfect for storing homemade potions and tinctures." },
        { id: "shp_018", name: "Bandage Roll", desc: "A roll of clean linen bandages for treating wounds." },
        { id: "shp_019", name: "Ointment for Burns", desc: "A soothing ointment specifically formulated for minor burns." },
        { id: "shp_020", name: "Dried Ginger Root", desc: "Dried ginger root, useful for settling an upset stomach." },
        { id: "shp_021", name: "Amulet of Minor Protection", desc: "A simple amulet offering slight resistance to physical harm." },
        { id: "shp_022", name: "Ring of Warmth", desc: "This enchanted ring keeps the wearer comfortably warm in cold weather." },
        { id: "shp_023", name: "Enchanted Traveling Cloak", desc: "A cloak enchanted to repel rain and resist tearing on long journeys." },
        { id: "shp_024", name: "Charm of Clear Sight", desc: "A small charm said to sharpen the wearer's vision in dim light." },
        { id: "shp_025", name: "Bracelet of Steady Hands", desc: "This bracelet is favored by archers and surgeons alike for its calming effect." },
        { id: "shp_026", name: "Pendant of Silent Steps", desc: "An enchanted pendant that softens the sound of the wearer's footsteps." },
        { id: "shp_027", name: "Talisman Against Nightmares", desc: "Said to grant peaceful, dreamless sleep to whoever wears it." },
        { id: "shp_028", name: "Enchanted Fishing Lure", desc: "This lure never fails to attract the attention of nearby fish." },
        { id: "shp_029", name: "Whispering Locket", desc: "A locket that carries a faint echo of the last words spoken near it." },
        { id: "shp_030", name: "Everburning Candle", desc: "This candle burns steadily without ever growing shorter." },
        { id: "shp_031", name: "Merchant's Traveling Scale", desc: "A portable scale used by merchants to weigh goods accurately." },
        { id: "shp_032", name: "Wax Sealing Kit", desc: "A kit containing wax and a stamp for sealing important letters." },
        { id: "shp_033", name: "Ink and Quill Set", desc: "A set of ink and a well-crafted quill for writing correspondence." },
        { id: "shp_034", name: "Leather Satchel", desc: "A sturdy leather satchel with several pockets for organizing belongings." },
        { id: "shp_035", name: "Waterproof Traveling Boots", desc: "Boots treated to resist water, ideal for long journeys through rain." },
        { id: "shp_036", name: "Coil of Sturdy Rope", desc: "A long coil of rope, strong enough for climbing or hauling heavy loads." },
        { id: "shp_037", name: "Wool Traveling Blanket", desc: "A thick wool blanket, warm enough for sleeping outdoors in cool weather." },
        { id: "shp_038", name: "Compact Cooking Pot", desc: "A small, lightweight cooking pot suited for travel and camping." },
        { id: "shp_039", name: "Flint and Steel Fire Starter", desc: "A reliable flint and steel set for starting campfires quickly." },
        { id: "shp_040", name: "Waxed Canvas Tent", desc: "A waterproofed canvas tent, compact enough to carry on foot." },
        { id: "shp_041", name: "Deck of Playing Cards", desc: "A standard deck of cards for games during long evenings at the tavern." },
        { id: "shp_042", name: "Carved Wooden Flute", desc: "A simple wooden flute, carved and tuned by a local craftsman." },
        { id: "shp_043", name: "Set of Dice", desc: "A set of six-sided dice, carved from polished bone." },
        { id: "shp_044", name: "Wooden Chess Set", desc: "A hand-carved chess set with pieces representing local folklore figures." },
        { id: "shp_045", name: "Small Hand Mirror", desc: "A polished hand mirror with a decorative wooden frame." },
        { id: "shp_046", name: "Beeswax Candles, Pack of 12", desc: "A pack of twelve beeswax candles, burning cleanly and evenly." },
        { id: "shp_047", name: "Woven Wicker Basket", desc: "A sturdy woven basket suitable for carrying market goods." },
        { id: "shp_048", name: "Brass Lantern", desc: "A polished brass lantern that provides steady light for hours." },
        { id: "shp_049", name: "Oil Flask for Lanterns", desc: "A refill flask of lamp oil, compatible with most standard lanterns." },
        { id: "shp_050", name: "Traveler's Cooking Skillet", desc: "A compact cast iron skillet, well suited to campfire cooking." },
        { id: "shp_051", name: "Dried Meat Rations", desc: "Preserved meat rations, ideal for long journeys away from towns." },
        { id: "shp_052", name: "Hardtack Biscuits", desc: "Dense, long-lasting biscuits favored by travelers and soldiers." },
        { id: "shp_053", name: "Wheel of Aged Cheese", desc: "A full wheel of cheese, aged for several months in a cool cellar." },
        { id: "shp_054", name: "Skin of Traveling Ale", desc: "A leather skin filled with ale, convenient for travel." },
        { id: "shp_055", name: "Bag of Dried Fruit", desc: "A mix of dried fruit, lightweight and long-lasting for travel." },
        { id: "shp_056", name: "Jar of Wild Honey", desc: "A jar of honey gathered from wild hives in the surrounding forest." },
        { id: "shp_057", name: "Fresh Baked Bread Loaf", desc: "A warm loaf of bread, best enjoyed the same day it's purchased." },
        { id: "shp_058", name: "Bottle of Table Wine", desc: "An affordable table wine, suitable for everyday meals." },
        { id: "shp_059", name: "Salted Fish Fillets", desc: "Salted and preserved fish fillets, ready to cook or eat as is." },
        { id: "shp_060", name: "Bag of Roasted Nuts", desc: "A mixed bag of roasted nuts, a popular snack for travelers." },
        { id: "shp_061", name: "Folding Shovel", desc: "A compact folding shovel useful for digging or clearing debris." },
        { id: "shp_062", name: "Fishing Rod and Tackle", desc: "A complete fishing setup including rod, line, and assorted lures." },
        { id: "shp_063", name: "Woodcutting Hatchet", desc: "A well-balanced hatchet suited for chopping firewood on the road." },
        { id: "shp_064", name: "Sturdy Walking Stick", desc: "A reinforced walking stick, useful for rough terrain or as a light weapon." },
        { id: "shp_065", name: "Waterskin, Large", desc: "A large waterskin capable of holding enough water for a full day's travel." },
        { id: "shp_066", name: "Compact Sewing Kit", desc: "A small kit with needle, thread, and spare buttons for quick repairs." },
        { id: "shp_067", name: "Portable Grindstone", desc: "A small grindstone for sharpening blades while away from a proper forge." },
        { id: "shp_068", name: "Traveling Lockpick Set", desc: "A discreet set of lockpicks, useful in a variety of situations." },
        { id: "shp_069", name: "Sturdy Backpack", desc: "A large backpack with reinforced straps for carrying heavy loads." },
        { id: "shp_070", name: "Pocket Sundial", desc: "A small sundial for estimating the time of day while traveling." }
    ];
}