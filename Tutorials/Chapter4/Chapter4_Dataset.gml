// GMLiteSearch Tutorial - Chapter 4 Dataset
// 75 games for a game marketplace/storefront, spanning 9 categories,
// 3 platforms, and a real price spread from $2.99 to $59.99.
// Used throughout Chapter 4 to demonstrate faceted search, AND/OR filter
// logic, tag filtering, and range facets.
//
// Usage:
//   var games = chapter4_get_games();
//   for (var i = 0; i < array_length(games); i++) {
//       var g = games[i];
//       var facets = { category: g.category, tags: g.tags, platform: g.platform, price: g.price };
//       var metadata = { title: g.name, tags: g.tags, timestamp: current_time };
//       gmls_add_document_faceted(g.id, g.desc, facets, metadata);
//   }

function chapter4_get_games() {
    return [
        { id: "gm_001", name: "Dragon's Reckoning", desc: "Epic open-world RPG with dragon companions and a branching story.", category: "rpg", tags: ["fantasy", "open-world", "story-rich"], platform: "pc", price: 59.99 },
        { id: "gm_002", name: "Shattered Kingdoms", desc: "Tactical RPG where every battle decision reshapes the political map.", category: "rpg", tags: ["tactical", "fantasy", "strategy"], platform: "pc", price: 39.99 },
        { id: "gm_003", name: "Wanderer's Requiem", desc: "A slow, melancholic RPG about a traveler searching for a lost home.", category: "rpg", tags: ["story-rich", "atmospheric"], platform: "console", price: 24.99 },
        { id: "gm_004", name: "Ironclad Legends", desc: "Classic dungeon-crawling RPG with deep character customization.", category: "rpg", tags: ["dungeon-crawler", "fantasy", "character-customization"], platform: "pc", price: 29.99 },
        { id: "gm_005", name: "Starlit Pilgrimage", desc: "Sci-fi RPG exploring alien ruins across a dying galaxy.", category: "rpg", tags: ["sci-fi", "exploration", "story-rich"], platform: "console", price: 49.99 },
        { id: "gm_006", name: "Ashfall Chronicles", desc: "Post-apocalyptic RPG with survival mechanics and a moral choice system.", category: "rpg", tags: ["post-apocalyptic", "survival", "choices-matter"], platform: "pc", price: 44.99 },
        { id: "gm_007", name: "Mistveil Tactics", desc: "Turn-based tactical RPG set in a cursed, fog-covered kingdom.", category: "rpg", tags: ["tactical", "fantasy", "turn-based"], platform: "mobile", price: 9.99 },
        { id: "gm_008", name: "Copper & Steam", desc: "Steampunk RPG featuring airship exploration and clockwork companions.", category: "rpg", tags: ["steampunk", "exploration", "story-rich"], platform: "pc", price: 34.99 },
        { id: "gm_009", name: "Neon Vendetta", desc: "Fast-paced cyberpunk shooter with wall-running and slow-motion combat.", category: "action", tags: ["cyberpunk", "shooter", "fast-paced"], platform: "pc", price: 49.99 },
        { id: "gm_010", name: "Crimson Talon", desc: "Brutal hack-and-slash game with a blood-soaked revenge storyline.", category: "action", tags: ["hack-and-slash", "story-rich"], platform: "console", price: 39.99 },
        { id: "gm_011", name: "Void Runner", desc: "High-speed sci-fi platformer with precision movement mechanics.", category: "action", tags: ["sci-fi", "platformer", "fast-paced"], platform: "pc", price: 19.99 },
        { id: "gm_012", name: "Ironfist Arena", desc: "Competitive fighting game with a roster of over thirty unique characters.", category: "action", tags: ["fighting", "competitive", "multiplayer"], platform: "console", price: 59.99 },
        { id: "gm_013", name: "Shadow Protocol", desc: "Stealth-action game blending assassination missions with open-ended level design.", category: "action", tags: ["stealth", "open-world"], platform: "pc", price: 44.99 },
        { id: "gm_014", name: "Blitzwing", desc: "Arcade-style aerial combat game with fast rounds and simple controls.", category: "action", tags: ["arcade", "fast-paced", "multiplayer"], platform: "mobile", price: 4.99 },
        { id: "gm_015", name: "Doom Cradle", desc: "Classic-inspired boomer shooter with relentless enemy waves.", category: "action", tags: ["shooter", "fast-paced", "retro"], platform: "pc", price: 24.99 },
        { id: "gm_016", name: "Empire of Ash", desc: "Grand strategy game spanning centuries of conquest and diplomacy.", category: "strategy", tags: ["4x", "historical", "diplomacy"], platform: "pc", price: 49.99 },
        { id: "gm_017", name: "Hex Command", desc: "Turn-based tactical strategy on hexagonal battlefields.", category: "strategy", tags: ["turn-based", "tactical"], platform: "pc", price: 29.99 },
        { id: "gm_018", name: "Colony Zero", desc: "City-building strategy game set on a hostile alien world.", category: "strategy", tags: ["city-builder", "sci-fi", "survival"], platform: "pc", price: 34.99 },
        { id: "gm_019", name: "Warlord's Gambit", desc: "Real-time strategy game with base-building and large-scale battles.", category: "strategy", tags: ["real-time", "base-building", "multiplayer"], platform: "pc", price: 39.99 },
        { id: "gm_020", name: "Silent Ledger", desc: "Economic strategy game about running a merchant trading empire.", category: "strategy", tags: ["economy", "historical"], platform: "pc", price: 19.99 },
        { id: "gm_021", name: "Frostline Defense", desc: "Tower-defense strategy game set in a slowly freezing world.", category: "strategy", tags: ["tower-defense", "survival"], platform: "mobile", price: 6.99 },
        { id: "gm_022", name: "Dominion's Edge", desc: "4X strategy game about expanding across a procedurally generated galaxy.", category: "strategy", tags: ["4x", "sci-fi", "exploration"], platform: "pc", price: 44.99 },
        { id: "gm_023", name: "Lanternfall", desc: "Atmospheric adventure game exploring a village shrouded in eternal dusk.", category: "adventure", tags: ["atmospheric", "exploration", "story-rich"], platform: "pc", price: 24.99 },
        { id: "gm_024", name: "The Cartographer's Curse", desc: "Puzzle-adventure game about mapping a shifting, impossible mansion.", category: "adventure", tags: ["puzzle", "atmospheric", "mystery"], platform: "pc", price: 19.99 },
        { id: "gm_025", name: "Driftwood Bay", desc: "Relaxing narrative adventure about rebuilding a coastal fishing town.", category: "adventure", tags: ["cozy", "story-rich", "relaxing"], platform: "console", price: 14.99 },
        { id: "gm_026", name: "Echoes of Marrow Hollow", desc: "Horror-adventure game investigating a town's disturbing history.", category: "adventure", tags: ["horror", "mystery", "atmospheric"], platform: "pc", price: 29.99 },
        { id: "gm_027", name: "Paperbound", desc: "Whimsical adventure game where the world is made of folded paper.", category: "adventure", tags: ["puzzle", "whimsical", "cozy"], platform: "mobile", price: 7.99 },
        { id: "gm_028", name: "Salt & Sail", desc: "Open-ended sailing adventure exploring a scattered archipelago.", category: "adventure", tags: ["exploration", "open-world", "relaxing"], platform: "pc", price: 34.99 },
        { id: "gm_029", name: "Quantum Fold", desc: "Mind-bending puzzle game manipulating space and dimension.", category: "puzzle", tags: ["puzzle", "sci-fi", "mind-bending"], platform: "pc", price: 14.99 },
        { id: "gm_030", name: "Loop Garden", desc: "Relaxing puzzle game about growing plants through repeating time loops.", category: "puzzle", tags: ["puzzle", "cozy", "relaxing"], platform: "mobile", price: 3.99 },
        { id: "gm_031", name: "Cipher Row", desc: "Logic-driven puzzle game built entirely around cryptography.", category: "puzzle", tags: ["puzzle", "logic"], platform: "pc", price: 9.99 },
        { id: "gm_032", name: "Glasswork", desc: "Delicate physics puzzle game about balancing fragile structures.", category: "puzzle", tags: ["puzzle", "physics"], platform: "pc", price: 12.99 },
        { id: "gm_033", name: "Nine Doors", desc: "Escape-room style puzzle game with an unsettling narrative twist.", category: "puzzle", tags: ["puzzle", "mystery", "atmospheric"], platform: "console", price: 17.99 },
        { id: "gm_034", name: "Harvest Ledger", desc: "Detailed farming simulation with a full seasonal economy.", category: "simulation", tags: ["farming", "economy", "relaxing"], platform: "pc", price: 24.99 },
        { id: "gm_035", name: "Skyline Transit", desc: "City transportation simulation managing buses, trains, and traffic.", category: "simulation", tags: ["city-builder", "management"], platform: "pc", price: 29.99 },
        { id: "gm_036", name: "Deepdock Shipwright", desc: "Detailed ship-building and repair simulation set in a busy harbor.", category: "simulation", tags: ["building", "management"], platform: "pc", price: 19.99 },
        { id: "gm_037", name: "Little Bakery", desc: "Cozy bakery management simulation with a relaxed pace.", category: "simulation", tags: ["cozy", "management", "relaxing"], platform: "mobile", price: 5.99 },
        { id: "gm_038", name: "Terra Nova Ecology", desc: "Ecosystem simulation balancing predator and prey populations.", category: "simulation", tags: ["ecology", "sandbox"], platform: "pc", price: 22.99 },
        { id: "gm_039", name: "Velocity Circuit", desc: "Arcade racing game with over-the-top stunts and drift mechanics.", category: "racing", tags: ["arcade", "multiplayer", "fast-paced"], platform: "console", price: 39.99 },
        { id: "gm_040", name: "Grand Prix Legacy", desc: "Realistic racing simulation with detailed car tuning.", category: "racing", tags: ["simulation", "competitive"], platform: "pc", price: 49.99 },
        { id: "gm_041", name: "Rally Break", desc: "Off-road rally racing across muddy, unpredictable terrain.", category: "racing", tags: ["arcade", "off-road"], platform: "console", price: 34.99 },
        { id: "gm_042", name: "Kart Riot", desc: "Chaotic kart racing with power-ups and party multiplayer.", category: "racing", tags: ["arcade", "multiplayer", "party"], platform: "console", price: 44.99 },
        { id: "gm_043", name: "Hollow Signal", desc: "First-person horror game set in an abandoned radio station.", category: "horror", tags: ["horror", "atmospheric", "first-person"], platform: "pc", price: 19.99 },
        { id: "gm_044", name: "The Drowning Choir", desc: "Psychological horror game exploring guilt through surreal imagery.", category: "horror", tags: ["horror", "psychological", "story-rich"], platform: "pc", price: 24.99 },
        { id: "gm_045", name: "Rustbelt Nights", desc: "Survival horror game scavenging a collapsed industrial city.", category: "horror", tags: ["horror", "survival", "atmospheric"], platform: "console", price: 29.99 },
        { id: "gm_046", name: "Whispering Static", desc: "Found-footage style horror game investigating a haunted broadcast tower.", category: "horror", tags: ["horror", "mystery", "atmospheric"], platform: "pc", price: 14.99 },
        { id: "gm_047", name: "Tumble Party", desc: "Chaotic couch multiplayer party game with physics-based obstacles.", category: "party", tags: ["party", "multiplayer", "physics"], platform: "console", price: 24.99 },
        { id: "gm_048", name: "Board & Banter", desc: "Collection of digital board and card games for online friend groups.", category: "party", tags: ["party", "multiplayer", "card-game"], platform: "mobile", price: 6.99 },
        { id: "gm_049", name: "Trivia Uprising", desc: "Fast-paced trivia party game supporting large online groups.", category: "party", tags: ["party", "multiplayer", "trivia"], platform: "mobile", price: 2.99 },
        { id: "gm_050", name: "Verdant Oath", desc: "Nature-themed RPG about restoring a dying forest kingdom.", category: "rpg", tags: ["fantasy", "exploration", "nature"], platform: "console", price: 39.99 },
        { id: "gm_051", name: "Bonecarver's Path", desc: "Grim RPG following a wandering mercenary through a war-torn land.", category: "rpg", tags: ["fantasy", "story-rich", "dark"], platform: "pc", price: 44.99 },
        { id: "gm_052", name: "Lantern of the Deep", desc: "Underwater exploration RPG uncovering a sunken civilization.", category: "rpg", tags: ["exploration", "story-rich", "underwater"], platform: "console", price: 34.99 },
        { id: "gm_053", name: "Ashen Throne", desc: "Medieval grand strategy focused on succession and internal politics.", category: "strategy", tags: ["historical", "diplomacy", "4x"], platform: "pc", price: 39.99 },
        { id: "gm_054", name: "Nightfall Garrison", desc: "Cooperative tower-defense strategy for up to four players.", category: "strategy", tags: ["tower-defense", "multiplayer", "cooperative"], platform: "pc", price: 17.99 },
        { id: "gm_055", name: "Steelbound", desc: "Mech combat action game with fully destructible environments.", category: "action", tags: ["mech", "shooter", "destruction"], platform: "console", price: 54.99 },
        { id: "gm_056", name: "Riftwalker", desc: "Fast-paced action platformer set across shifting parallel dimensions.", category: "action", tags: ["platformer", "fast-paced", "sci-fi"], platform: "pc", price: 22.99 },
        { id: "gm_057", name: "Quiet Orchard", desc: "Meditative simulation game tending a small mountain orchard.", category: "simulation", tags: ["relaxing", "cozy", "farming"], platform: "mobile", price: 4.99 },
        { id: "gm_058", name: "Bramblewatch", desc: "Cozy adventure game exploring a forest full of gentle mysteries.", category: "adventure", tags: ["cozy", "exploration", "atmospheric"], platform: "pc", price: 16.99 },
        { id: "gm_059", name: "Ferrous Heart", desc: "Industrial-themed puzzle game about routing power through machinery.", category: "puzzle", tags: ["puzzle", "logic", "industrial"], platform: "pc", price: 11.99 },
        { id: "gm_060", name: "Grit & Gasoline", desc: "Demolition derby racing game with heavily customizable vehicles.", category: "racing", tags: ["arcade", "destruction", "multiplayer"], platform: "console", price: 29.99 },
        { id: "gm_061", name: "Pale Harvest", desc: "Slow-burn horror game set during an unnervingly quiet harvest season.", category: "horror", tags: ["horror", "atmospheric", "psychological"], platform: "pc", price: 18.99 },
        { id: "gm_062", name: "Fable Deck", desc: "Card-battler party game themed around retelling classic fairy tales.", category: "party", tags: ["party", "card-game", "multiplayer"], platform: "mobile", price: 5.99 },
        { id: "gm_063", name: "Copperlight Vale", desc: "Cozy RPG about running a small shop in a magical valley town.", category: "rpg", tags: ["cozy", "fantasy", "shop-management"], platform: "pc", price: 27.99 },
        { id: "gm_064", name: "Ninestone Pact", desc: "Tactical strategy game about forging alliances between rival clans.", category: "strategy", tags: ["tactical", "diplomacy", "fantasy"], platform: "pc", price: 32.99 },
        { id: "gm_065", name: "Voltframe", desc: "High-speed action game piloting an electrified prototype vehicle.", category: "action", tags: ["fast-paced", "sci-fi", "vehicle"], platform: "console", price: 46.99 },
        { id: "gm_066", name: "Thistledown Manor", desc: "Puzzle-adventure game restoring a crumbling manor room by room.", category: "adventure", tags: ["puzzle", "cozy", "restoration"], platform: "pc", price: 21.99 },
        { id: "gm_067", name: "Emberlight Tactics", desc: "Fire-themed tactical RPG with a strong emphasis on positioning.", category: "rpg", tags: ["tactical", "fantasy", "turn-based"], platform: "console", price: 41.99 },
        { id: "gm_068", name: "Static Frontier", desc: "Survival simulation on a remote, signal-jammed research outpost.", category: "simulation", tags: ["survival", "sci-fi", "sandbox"], platform: "pc", price: 26.99 },
        { id: "gm_069", name: "Glimmerroot", desc: "Whimsical puzzle-platformer about guiding glowing spirits through a forest.", category: "puzzle", tags: ["puzzle", "platformer", "whimsical"], platform: "mobile", price: 3.99 },
        { id: "gm_070", name: "Ashen Roads", desc: "Post-apocalyptic racing game scavenging fuel across a wasteland.", category: "racing", tags: ["post-apocalyptic", "arcade", "survival"], platform: "pc", price: 23.99 },
        { id: "gm_071", name: "Nightjar Hollow", desc: "Atmospheric horror game set in a fog-drenched, birdless forest.", category: "horror", tags: ["horror", "atmospheric", "exploration"], platform: "pc", price: 15.99 },
        { id: "gm_072", name: "Partycrasher", desc: "Absurd multiplayer party game about sabotaging your friends' plans.", category: "party", tags: ["party", "multiplayer", "comedy"], platform: "console", price: 9.99 },
        { id: "gm_073", name: "Wyrmroot Saga", desc: "Long-form fantasy RPG following three generations of one family.", category: "rpg", tags: ["fantasy", "story-rich", "generational"], platform: "pc", price: 54.99 },
        { id: "gm_074", name: "Cascade Protocol", desc: "Strategy game managing cascading failures in a collapsing space station.", category: "strategy", tags: ["sci-fi", "management", "tense"], platform: "pc", price: 28.99 },
        { id: "gm_075", name: "Hollowmere", desc: "Adventure game about draining and exploring an ancient, cursed lakebed.", category: "adventure", tags: ["exploration", "atmospheric", "mystery"], platform: "console", price: 33.99 }
    ];
}