# Getting Started with GMLiteSearch

---

## Step 1: Initialize

Call `gmls_init()` once at game start, preferably in a persistent controller object.

```gml
// Create event of obj_search_controller
gmls_init();
```

---

## Step 2: Add Documents

Each document needs a unique ID, text content, and optional metadata.

```gml
// Basic document
gmls_add_document("sword_001", "Iron sword with 15 damage", 
    { title: "Iron Sword", type: "weapon" });

// Weighted document (title boosted 3x, tags boosted 2x)
gmls_add_document_weighted("potion_001", "Restores 50 HP", 
    { title: "Health Potion", tags: ["consumable", "healing"] });

// Faceted document (for filtering)
var facets = { category: "weapon", rarity: "common", price: 100 };
gmls_add_document_faceted("sword_002", "Steel sword with 25 damage", facets,
    { title: "Steel Sword" });
```

---

## Step 3: Search

```gml
// Basic search
var results = gmls_search("iron sword", 10);
for (var i = 0; i < array_length(results); i++) {
    show_debug_message(results[i].document.metadata.title + 
                       " - score: " + string(results[i].score));
}

// Fuzzy search (handles typos)
var fuzzy = gmls_fuzzy_search("irn swrod", 5, 0.6);

// Prefix search (autocomplete)
var prefix = gmls_search_prefix("iro", 5);
```

---

## Step 4: Add Filters (Faceted Search)

```gml
// Add facet filters
gmls_add_facet_filter("category", "weapon");
gmls_add_facet_filter("rarity", "common");

// Search with filters
var filtered = gmls_search_faceted("sword", 20);

// Get facet counts for UI
var counts = gmls_get_facet_counts("", undefined, ["category", "rarity"]);
show_debug_message("Weapons: " + string(counts[$ "category"][$ "weapon"]));
```

---

## Step 5: Add Location (Geospatial)

```gml
// Real-world coordinates
gmls_add_geolocation("shop_001", 40.7128, -74.0060, 6);

// Game world coordinates (2D)
gmls_add_location_2d("chest_001", 150, 200);

// Search nearby
var player_x = 155;
var player_y = 205;
var nearby = gmls_search_nearby_2d(player_x, player_y, 50, "", 10);
for (var i = 0; i < array_length(nearby); i++) {
    show_debug_message(nearby[i].document.metadata.title + 
                       " | " + string(nearby[i].distance) + " units");
}
```

---

## Step 6: Enable Learning-to-Rank (Optional)

```gml
// Enable LTR
gmls_enable_ltr(true);

// Add training examples (query, doc_id, relevance 0-1)
gmls_add_training_example("sword", "sword_001", 1.0);
gmls_add_training_example("sword", "sword_002", 0.8);
gmls_add_training_example("potion", "potion_001", 0.9);

// Train the model
gmls_train_linear_model(100, 0.005);

// Record user clicks (improves popularity)
gmls_record_click("sword_001");

// Search with LTR
var ltr_results = gmls_search_ltr("sword", 10);
```

---

## Step 7: Save & Load

```gml
// Save index
var save_str = gmls_save_to_string();
var file = file_text_open_write("search_index.json");
file_text_write_string(file, save_str);
file_text_close(file);

// Load index
if (file_exists("search_index.json")) {
    file = file_text_open_read("search_index.json");
    var load_str = file_text_read_string(file);
    file_text_close(file);
    gmls_load_from_string(load_str);
}
```

---

## Step 8: Clean Up

```gml
// Clear all documents (keep configuration)
gmls_clear();

// Complete cleanup (free all memory)
gmls_cleanup();
```

---

## Next Steps

- Read the [Full Documentation](Documentation.md) for all features
- Explore the demo code in the repository
- Check the API reference for advanced options

---

## Common Issues

| Issue | Solution |
|-------|----------|
| No search results | Check case sensitivity, stemming, and stop words |
| Poor relevance | Tune BM25 parameters or enable LTR |
| Slow performance | Disable n-grams for large datasets, increase min_word_length |
| Memory high | Reduce max_doc_size, disable n-grams |
