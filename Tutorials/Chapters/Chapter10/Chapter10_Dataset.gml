// GMLiteSearch Tutorial - Chapter 10 Dataset
// 8 RPG games used in the LambdaMART training example, each with a
// popularity value used to build tiered relevance for the worked example.
//
// Usage (index documents):
//   var games = chapter10_get_games();
//   gmls_init();
//   for (var i = 0; i < array_length(games); i++) {
//       var g = games[i];
//       var facets = { category: g.category, tags: g.tags };
//       var metadata = { title: g.name, tags: g.tags, timestamp: current_time };
//       gmls_add_document_faceted(g.id, g.desc, facets, metadata);
//   }
//
// Usage (build LambdaMART training samples - matches the chapter's worked
// example: 20 query sessions, each randomly selecting 4 of these 8 games,
// ranked by popularity into relevance tiers 3,2,1,0):
//
//   IMPORTANT: shuffle the (doc_id, relevance) pairs within each session
//   before building samples - inserting them already in relevance order
//   can cause a misleadingly perfect 'Initial avg NDCG', as explained in
//   the chapter. This is a lesson about building HONEST test data, not a
//   framework requirement, but it matters for reproducing the chapter's
//   real, honest results rather than an artificially inflated one.

function chapter10_get_games() {
    return [
        { id: "gm_001", name: "Dragon's Reckoning", desc: "Epic open-world RPG with dragon companions and a branching story.", category: "rpg", tags: ["fantasy", "open-world", "story-rich"], popularity: 95 },
        { id: "gm_002", name: "Shattered Kingdoms", desc: "Tactical RPG where every battle decision reshapes the political map.", category: "rpg", tags: ["tactical", "fantasy", "strategy"], popularity: 78 },
        { id: "gm_005", name: "Starlit Pilgrimage", desc: "Sci-fi RPG exploring alien ruins across a dying galaxy.", category: "rpg", tags: ["sci-fi", "exploration", "story-rich"], popularity: 65 },
        { id: "gm_006", name: "Ashfall Chronicles", desc: "Post-apocalyptic RPG with survival mechanics and a moral choice system.", category: "rpg", tags: ["post-apocalyptic", "survival", "choices-matter"], popularity: 71 },
        { id: "gm_050", name: "Verdant Oath", desc: "Nature-themed RPG about restoring a dying forest kingdom.", category: "rpg", tags: ["fantasy", "exploration", "nature"], popularity: 60 },
        { id: "gm_063", name: "Copperlight Vale", desc: "Cozy RPG about running a small shop in a magical valley town.", category: "rpg", tags: ["cozy", "fantasy", "shop-management"], popularity: 82 },
        { id: "gm_067", name: "Emberlight Tactics", desc: "Fire-themed tactical RPG with a strong emphasis on positioning.", category: "rpg", tags: ["tactical", "fantasy", "turn-based"], popularity: 55 },
        { id: "gm_073", name: "Wyrmroot Saga", desc: "Long-form fantasy RPG following three generations of one family.", category: "rpg", tags: ["fantasy", "story-rich", "generational"], popularity: 90 }
    ];
}