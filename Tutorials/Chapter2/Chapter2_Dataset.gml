// GMLiteSearch Tutorial - Chapter 2 Dataset
// 65 NPCs living in the village of Millhaven.
// Used throughout Chapter 2 to demonstrate metadata, weighted indexing, and document lifecycle.
//
// Usage:
//   var npcs = chapter2_get_npcs();
//   for (var i = 0; i < array_length(npcs); i++) {
//       var npc = npcs[i];
//       var metadata = { title: npc.name, tags: [npc.role], timestamp: current_time };
//       gmls_add_document_weighted(npc.id, npc.desc, metadata);
//   }

function chapter2_get_npcs() {
    return [
        { id: "npc_001", name: "Elder Marta Stonewell", role: "Village Elder", desc: "The wise leader of Millhaven, known for her fair judgment and deep knowledge of local history." },
        { id: "npc_002", name: "Blacksmith Gareth Ironforge", role: "Blacksmith", desc: "A burly craftsman who forges weapons and armor at the village smithy near the town square." },
        { id: "npc_003", name: "Innkeeper Wilhelmina Brew", role: "Innkeeper", desc: "Runs the Sleeping Dragon Inn, offering rooms, meals, and the latest town gossip." },
        { id: "npc_004", name: "Herbalist Fenn Willowbrook", role: "Herbalist", desc: "Gathers rare plants from the nearby forest and brews potions for travelers and villagers alike." },
        { id: "npc_005", name: "Guard Captain Roderick Vane", role: "Guard Captain", desc: "Commands the town watch and takes the safety of Millhaven's citizens very seriously." },
        { id: "npc_006", name: "Merchant Yusuf Kasrani", role: "Traveling Merchant", desc: "Sells exotic goods from distant lands, setting up his stall near the market square each week." },
        { id: "npc_007", name: "Fisherman Old Tobias", role: "Fisherman", desc: "Spends his days by the river, always willing to share fishing tips with anyone who asks." },
        { id: "npc_008", name: "Priestess Aurelia Dawnsong", role: "Temple Priestess", desc: "Tends to the village temple, offering blessings, healing, and quiet counsel to those in need." },
        { id: "npc_009", name: "Farmer Bram Oakfield", role: "Farmer", desc: "Works the fields just outside town, growing wheat and vegetables to feed the village." },
        { id: "npc_010", name: "Scholar Delphine Ashgrove", role: "Scholar", desc: "Studies ancient texts and ruins, often seeking adventurers to retrieve lost artifacts." },
        { id: "npc_011", name: "Tavern Bard Finnick Loomsworth", role: "Bard", desc: "Performs songs and stories at the Sleeping Dragon Inn, always eager to hear news from the road." },
        { id: "npc_012", name: "Woodcutter Hilde Thornback", role: "Woodcutter", desc: "Chops timber in the forest outside town, supplying wood for construction and the winter fires." },
        { id: "npc_013", name: "Alchemist Percival Grimm", role: "Alchemist", desc: "Conducts strange experiments in his cluttered shop, occasionally producing useful potions and elixirs." },
        { id: "npc_014", name: "Miner Doran Deepdelve", role: "Miner", desc: "Works the mountain mines north of town, bringing back ore, gems, and the occasional strange find." },
        { id: "npc_015", name: "Seamstress Lucia Fairweather", role: "Seamstress", desc: "Crafts and mends clothing for the villagers, keeping a small shop near the town square." },
        { id: "npc_016", name: "Stablemaster Owen Bridle", role: "Stablemaster", desc: "Cares for horses and other mounts, offering boarding and riding lessons to travelers." },
        { id: "npc_017", name: "Beekeeper Constance Hollow", role: "Beekeeper", desc: "Tends hives on the edge of town, selling honey and wax at the weekly market." },
        { id: "npc_018", name: "Mercenary Captain Drask", role: "Mercenary Captain", desc: "Leads a band of sellswords, often available for hire if the pay is right." },
        { id: "npc_019", name: "Cartographer Wren Millbrook", role: "Cartographer", desc: "Draws maps of the surrounding region, always eager to update them with fresh exploration reports." },
        { id: "npc_020", name: "Baker Nettie Doughsworth", role: "Baker", desc: "Bakes bread and pastries each morning, filling the town square with the smell of fresh dough." },
        { id: "npc_021", name: "Hunter Corin Swiftarrow", role: "Hunter", desc: "Tracks game through the nearby woods, supplying meat and furs to the village." },
        { id: "npc_022", name: "Jeweler Marisol Brightgem", role: "Jeweler", desc: "Crafts fine jewelry from gems brought in by miners, running a small shop near the temple." },
        { id: "npc_023", name: "Retired Soldier Aldric Graywall", role: "Retired Soldier", desc: "Spends his days at the tavern, telling stories of old campaigns to anyone who will listen." },
        { id: "npc_024", name: "Fortune Teller Zara Nightveil", role: "Fortune Teller", desc: "Reads cards and tea leaves in a small tent at the edge of the market, for a modest fee." },
        { id: "npc_025", name: "Carpenter Silas Woodham", role: "Carpenter", desc: "Builds and repairs furniture and structures around town, often busy with new commissions." },
        { id: "npc_026", name: "Orphanage Keeper Rosalind Hearth", role: "Orphanage Keeper", desc: "Cares for children who have lost their families, running the small orphanage near the temple." },
        { id: "npc_027", name: "Traveling Minstrel Cassian Vale", role: "Minstrel", desc: "Wanders from town to town performing music, currently staying at the Sleeping Dragon Inn." },
        { id: "npc_028", name: "Shepherd Ivo Fellowfield", role: "Shepherd", desc: "Tends flocks of sheep in the hills outside town, occasionally reporting strange wolf sightings." },
        { id: "npc_029", name: "Locksmith Reeve Turnkey", role: "Locksmith", desc: "Fixes and crafts locks for the villagers, and occasionally teaches lockpicking to trusted friends." },
        { id: "npc_030", name: "Town Crier Bess Loudly", role: "Town Crier", desc: "Announces news and notices in the town square, always the first to know what's happening." },
        { id: "npc_031", name: "Ferryman Old Cotter", role: "Ferryman", desc: "Operates the small ferry across the river, charging a modest fee for the crossing." },
        { id: "npc_032", name: "Dyer Petra Colorwash", role: "Dyer", desc: "Dyes fabric in vivid colors using pigments gathered from local plants and minerals." },
        { id: "npc_033", name: "Gravedigger Thom Bellows", role: "Gravedigger", desc: "Tends the village cemetery, and knows more about the town's history than most realize." },
        { id: "npc_034", name: "Weaver Odalys Threadwell", role: "Weaver", desc: "Weaves cloth on a large loom in her workshop, supplying fabric to the local seamstress." },
        { id: "npc_035", name: "Trapper Garrick Thistlewood", role: "Trapper", desc: "Sets traps in the forest for fur-bearing animals, often crossing paths with the local hunter." },
        { id: "npc_036", name: "Apothecary Assistant Wren Basil", role: "Apothecary Assistant", desc: "Helps the local alchemist prepare ingredients, hoping to open a shop of her own someday." },
        { id: "npc_037", name: "Retired Sailor Cap Hollis", role: "Retired Sailor", desc: "Lives near the river, telling tales of distant seas to any child who will sit still long enough." },
        { id: "npc_038", name: "Millworker Aggie Grindstone", role: "Millworker", desc: "Operates the town's grain mill, grinding wheat brought in by the local farmers." },
        { id: "npc_039", name: "Traveling Priest Father Ambrose", role: "Traveling Priest", desc: "Passes through town periodically, offering sermons and blessings at the village temple." },
        { id: "npc_040", name: "Rat Catcher Pip Snareling", role: "Rat Catcher", desc: "Keeps the town's granaries free of vermin, a job few others are willing to do." },
        { id: "npc_041", name: "Glassblower Henrik Emberglass", role: "Glassblower", desc: "Shapes molten glass into bottles and ornaments in his small workshop near the market." },
        { id: "npc_042", name: "Retired Adventurer Bryn Ashfall", role: "Retired Adventurer", desc: "Settled down after years of dungeon delving, now happy to give advice to newer adventurers." },
        { id: "npc_043", name: "Candle Maker Effie Waxworth", role: "Candle Maker", desc: "Makes candles from beeswax and tallow, selling them from a small stall near the temple." },
        { id: "npc_044", name: "Tanner Osric Hidecraft", role: "Tanner", desc: "Processes animal hides into leather, working out of a workshop near the edge of town." },
        { id: "npc_045", name: "Village Healer Maud Greenroot", role: "Healer", desc: "Treats injuries and illness using herbal remedies, working closely with the local herbalist." },
        { id: "npc_046", name: "Chandler's Boy Tam Wickley", role: "Chandler's Assistant", desc: "Helps the candle maker with deliveries, dreaming of one day running his own shop." },
        { id: "npc_047", name: "Retired Knight Sir Aldous Vane", role: "Retired Knight", desc: "Lives quietly on the edge of town, occasionally training promising young fighters." },
        { id: "npc_048", name: "Well Keeper Nan Deepwater", role: "Well Keeper", desc: "Maintains the town's wells, making sure the water supply stays clean and plentiful." },
        { id: "npc_049", name: "Basket Weaver Lena Reedcraft", role: "Basket Weaver", desc: "Weaves baskets from river reeds, sold at the market alongside other handmade goods." },
        { id: "npc_050", name: "Traveling Peddler Cosmo Trinket", role: "Peddler", desc: "Sells odds and ends from a cart, always claiming to have exactly what you need." },
        { id: "npc_051", name: "Village Idiot Willum Dabbler", role: "Village Character", desc: "Wanders the streets talking to himself, though some say his ramblings hold hidden wisdom." },
        { id: "npc_052", name: "Retired Mage Corvina Ashwhisper", role: "Retired Mage", desc: "Lives in a small cottage outside town, occasionally selling minor enchantments to travelers." },
        { id: "npc_053", name: "Toll Collector Reginald Post", role: "Toll Collector", desc: "Collects tolls at the bridge into town, keeping careful records of everyone who passes." },
        { id: "npc_054", name: "Orchard Keeper Della Appleworth", role: "Orchard Keeper", desc: "Tends the apple orchards on the edge of town, selling fresh fruit and cider each autumn." },
        { id: "npc_055", name: "Traveling Scribe Ezekiel Inkwell", role: "Scribe", desc: "Copies documents and writes letters for villagers who cannot write themselves." },
        { id: "npc_056", name: "Cheese Maker Bettina Curdle", role: "Cheese Maker", desc: "Makes cheese from the milk of local goats and cows, sold fresh at the weekly market." },
        { id: "npc_057", name: "Retired Pirate One-Eyed Sal", role: "Retired Pirate", desc: "Runs a small shop selling curiosities, with stories about her past that few fully believe." },
        { id: "npc_058", name: "Bell Ringer Absalom Chime", role: "Bell Ringer", desc: "Rings the temple bells to mark the hours, a duty he takes with unusual seriousness." },
        { id: "npc_059", name: "Traveling Tinker Gus Coglin", role: "Tinker", desc: "Repairs mechanical odds and ends, passing through town every few months on his rounds." },
        { id: "npc_060", name: "Village Watchman Fenwick Bell", role: "Watchman", desc: "Patrols the streets at night alongside the guard captain, keeping an eye out for trouble." },
        { id: "npc_061", name: "Retired Explorer Odessa Farview", role: "Retired Explorer", desc: "Has mapped distant lands in her youth, now content sharing old journals with curious scholars." },
        { id: "npc_062", name: "Stonemason Baldric Quarrystone", role: "Stonemason", desc: "Repairs the town walls and buildings, working closely with the carpenter on larger projects." },
        { id: "npc_063", name: "Traveling Healer Sister Marigold", role: "Traveling Healer", desc: "Passes through periodically offering healing services alongside the village healer." },
        { id: "npc_064", name: "Falconer Ren Skywing", role: "Falconer", desc: "Trains hunting falcons on the outskirts of town, occasionally sending messages by bird." },
        { id: "npc_065", name: "Retired Guard Marta Stillwater", role: "Retired Guard", desc: "Once served under the guard captain, now spends her days tending a small garden." }
    ];
}