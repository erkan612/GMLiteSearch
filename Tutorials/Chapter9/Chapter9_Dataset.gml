// GMLiteSearch Tutorial - Chapter 9 Dataset
// The SAME 14 games and 16 training examples from Chapter 8 (for direct
// continuity - RankNet trains on identical data to compare against the
// linear model), plus player_ratings data for the custom feature extractor example.
//
// Usage (index documents + add training examples): same pattern as Chapter 8.
//   var games = chapter9_get_games();
//   gmls_init();
//   for (var i = 0; i < array_length(games); i++) {
//       var g = games[i];
//       var facets = { category: g.category, tags: g.tags, platform: g.platform, price: g.price };
//       var metadata = { title: g.name, tags: g.tags, timestamp: current_time };
//       gmls_add_document_faceted(g.id, g.desc, facets, metadata);
//   }
//   gmls_enable_ltr(true);
//   var examples = chapter9_get_training_examples();
//   for (var i = 0; i < array_length(examples); i++) {
//       var ex = examples[i];
//       gmls_add_training_example(ex.query, ex.doc_id, ex.relevance);
//   }
//
// Usage (player ratings, for the custom feature extractor section):
//   var ratings = chapter9_get_player_ratings();
//   global.game_ratings = ds_map_create();
//   for (var i = 0; i < array_length(ratings); i++) {
//       ds_map_add(global.game_ratings, ratings[i].doc_id, ratings[i].rating);
//   }

function chapter9_get_games() {
    return [
        { id: "gm_001", name: "Dragon's Reckoning", desc: "Epic open-world RPG with dragon companions and a branching story.", category: "rpg", tags: ["fantasy", "open-world", "story-rich"], platform: "pc", price: 59.99 },
        { id: "gm_002", name: "Shattered Kingdoms", desc: "Tactical RPG where every battle decision reshapes the political map.", category: "rpg", tags: ["tactical", "fantasy", "strategy"], platform: "pc", price: 39.99 },
        { id: "gm_005", name: "Starlit Pilgrimage", desc: "Sci-fi RPG exploring alien ruins across a dying galaxy.", category: "rpg", tags: ["sci-fi", "exploration", "story-rich"], platform: "console", price: 49.99 },
        { id: "gm_006", name: "Ashfall Chronicles", desc: "Post-apocalyptic RPG with survival mechanics and a moral choice system.", category: "rpg", tags: ["post-apocalyptic", "survival", "choices-matter"], platform: "pc", price: 44.99 },
        { id: "gm_012", name: "Ironfist Arena", desc: "Competitive fighting game with a roster of over thirty unique characters.", category: "action", tags: ["fighting", "competitive", "multiplayer"], platform: "console", price: 59.99 },
        { id: "gm_016", name: "Empire of Ash", desc: "Grand strategy game spanning centuries of conquest and diplomacy.", category: "strategy", tags: ["4x", "historical", "diplomacy"], platform: "pc", price: 49.99 },
        { id: "gm_034", name: "Harvest Ledger", desc: "Detailed farming simulation with a full seasonal economy.", category: "simulation", tags: ["farming", "economy", "relaxing"], platform: "pc", price: 24.99 },
        { id: "gm_037", name: "Little Bakery", desc: "Cozy bakery management simulation with a relaxed pace.", category: "simulation", tags: ["cozy", "management", "relaxing"], platform: "mobile", price: 5.99 },
        { id: "gm_039", name: "Velocity Circuit", desc: "Arcade racing game with over-the-top stunts and drift mechanics.", category: "racing", tags: ["arcade", "multiplayer", "fast-paced"], platform: "console", price: 39.99 },
        { id: "gm_050", name: "Verdant Oath", desc: "Nature-themed RPG about restoring a dying forest kingdom.", category: "rpg", tags: ["fantasy", "exploration", "nature"], platform: "console", price: 39.99 },
        { id: "gm_057", name: "Quiet Orchard", desc: "Meditative simulation game tending a small mountain orchard.", category: "simulation", tags: ["relaxing", "cozy", "farming"], platform: "mobile", price: 4.99 },
        { id: "gm_063", name: "Copperlight Vale", desc: "Cozy RPG about running a small shop in a magical valley town.", category: "rpg", tags: ["cozy", "fantasy", "shop-management"], platform: "pc", price: 27.99 },
        { id: "gm_064", name: "Ninestone Pact", desc: "Tactical strategy game about forging alliances between rival clans.", category: "strategy", tags: ["tactical", "diplomacy", "fantasy"], platform: "pc", price: 32.99 },
        { id: "gm_073", name: "Wyrmroot Saga", desc: "Long-form fantasy RPG following three generations of one family.", category: "rpg", tags: ["fantasy", "story-rich", "generational"], platform: "pc", price: 54.99 }
    ];
}

function chapter9_get_training_examples() {
    return [
        { query: "fantasy rpg", doc_id: "gm_001", relevance: 1.0 },
        { query: "fantasy rpg", doc_id: "gm_002", relevance: 1.0 },
        { query: "fantasy rpg", doc_id: "gm_050", relevance: 1.0 },
        { query: "fantasy rpg", doc_id: "gm_073", relevance: 1.0 },
        { query: "fantasy rpg", doc_id: "gm_005", relevance: 0.67 },
        { query: "fantasy rpg", doc_id: "gm_006", relevance: 0.67 },
        { query: "fantasy rpg", doc_id: "gm_064", relevance: 0.67 },
        { query: "fantasy rpg", doc_id: "gm_039", relevance: 0.0 },
        { query: "cozy relaxing", doc_id: "gm_037", relevance: 1.0 },
        { query: "cozy relaxing", doc_id: "gm_057", relevance: 1.0 },
        { query: "cozy relaxing", doc_id: "gm_063", relevance: 0.67 },
        { query: "cozy relaxing", doc_id: "gm_034", relevance: 0.67 },
        { query: "cozy relaxing", doc_id: "gm_012", relevance: 0.0 },
        { query: "strategy diplomacy", doc_id: "gm_016", relevance: 1.0 },
        { query: "strategy diplomacy", doc_id: "gm_064", relevance: 0.67 },
        { query: "strategy diplomacy", doc_id: "gm_039", relevance: 0.0 }
    ];
}

function chapter9_get_player_ratings() {
    return [
        { doc_id: "gm_001", rating: 4.8 },
        { doc_id: "gm_002", rating: 4.3 },
        { doc_id: "gm_005", rating: 3.9 },
        { doc_id: "gm_006", rating: 4.1 },
        { doc_id: "gm_012", rating: 4.0 },
        { doc_id: "gm_016", rating: 4.5 },
        { doc_id: "gm_034", rating: 3.7 },
        { doc_id: "gm_037", rating: 4.4 },
        { doc_id: "gm_039", rating: 3.8 },
        { doc_id: "gm_050", rating: 4.2 },
        { doc_id: "gm_057", rating: 4.6 },
        { doc_id: "gm_063", rating: 4.7 },
        { doc_id: "gm_064", rating: 3.6 },
        { doc_id: "gm_073", rating: 4.9 }
    ];
}