# GMLiteSearch - Full Documentation

---

## Table of Contents

1. [Core Search](#core-search)
2. [Faceted Search](#faceted-search)
3. [Geospatial Search](#geospatial-search)
4. [Learning-to-Rank](#learning-to-rank)
5. [Advanced Snippets](#advanced-snippets)
6. [Query Understanding](#query-understanding)
7. [Developer Tools](#developer-tools)
8. [API Reference](#api-reference)
9. [Configuration](#configuration)
10. [Performance Tuning](#performance-tuning)

---

## Core Search

### Search Methods

| Method | Description | Use Case |
|--------|-------------|----------|
| `gmls_search()` | BM25 or TF-IDF exact word search | Primary search |
| `gmls_fuzzy_search()` | Bigram similarity matching | Typos, misspellings |
| `gmls_search_prefix()` | String prefix matching | Autocomplete |
| `gmls_search_hybrid()` | Exact then prefix fallback | General purpose |
| `gmls_search_ngrams()` | Character trigram matching | Severe typos |

### Basic Usage

```gml
// BM25 search (default)
var results = gmls_search("fantasy rpg", 10);

// TF-IDF search
gmls_set_config(false, true, 2, "tfidf");
var tfidf_results = gmls_search("fantasy rpg", 10);

// Fuzzy search (threshold 0-1, higher = stricter)
var fuzzy = gmls_fuzzy_search("fantacy", 5, 0.6);

// Prefix search
var prefix = gmls_search_prefix("fan", 5);

// Hybrid (exact first, then prefix)
var hybrid = gmls_search_hybrid("fantacy", 10);

// N-gram (character-level)
var ngram = gmls_search_ngrams("excalibr", 5);
```

### Result Structure

```gml
{
    id: "doc_id",
    score: 1.88,
    document: { text: "...", metadata: {...}, word_count: 15 },
    matched_terms: ["fantasy", "rpg"],
    snippet: "... excerpt ..."
}
```

---

## Faceted Search

### Overview

Faceted search allows filtering results by categories, tags, or any metadata field with aggregation counts.

### Adding Faceted Documents

```gml
var facets = {
    category: "rpg",
    tags: ["fantasy", "dragons", "magic"],
    platform: "pc",
    price: 59.99,
    year: 2024
};

gmls_add_document_faceted("game1", "Epic fantasy RPG", facets, 
    { title: "Dragon Fantasy" });
```

### Managing Filters

```gml
// Add filters
gmls_add_facet_filter("category", "rpg");
gmls_add_facet_filter("platform", "pc");

// Remove filter
gmls_remove_facet_filter("platform", "pc");

// Clear all filters
gmls_clear_facet_filters();

// Get active filters
var active = gmls_get_active_filters();
// Returns: { category: ["rpg"], platform: ["pc"] }

// Set operator (AND = all must match, OR = any)
gmls_set_filter_operator("OR");
```

### Getting Facet Counts

```gml
// Get counts for specific facets
var counts = gmls_get_facet_counts("", undefined, ["category", "platform"]);
var categories = counts[$ "category"];
// categories: { rpg: 5, action: 3, adventure: 2 }

// With query filtering
var filtered_counts = gmls_get_facet_counts("fantasy", undefined, ["category"]);
```

### Range Facets (Numeric/Date)

```gml
// Add numeric value for range faceting
gmls_add_range_facet("game1", "price", 59.99);

// Get bucket counts
var price_buckets = gmls_get_range_facet_counts("price", 0, 100, 20);
// Returns: { "0-20": 2, "20-40": 5, "40-60": 8, "60-80": 3, "80-100": 1 }
```

### Searching with Facets

```gml
// Apply filters first
gmls_add_facet_filter("category", "rpg");

// Search with facet results
var result = gmls_search_faceted("fantasy", 20, ["category", "tags"]);
show_debug_message("Total: " + string(result.total));
show_debug_message("Filtered from: " + string(result.filtered_from));

// Access facet counts from search
var facet_counts = result.facets;
var category_counts = facet_counts[$ "category"];

// Access results
for (var i = 0; i < array_length(result.results); i++) {
    show_debug_message(result.results[i].document.metadata.title);
}
```

---

## Geospatial Search

### Real-World Coordinates (Lat/Lng)

```gml
// Add geolocation
gmls_add_geolocation("place1", 40.7128, -74.0060, 6); // precision 6 = ~1.2km

// Radius search
var nearby = gmls_search_nearby(40.7130, -74.0065, 0.5, "km", "pizza", 10);

// Get nearest N
var nearest = gmls_get_nearest(40.7130, -74.0065, 5);

// Bounding box
var box = gmls_search_box(40.70, -74.02, 40.72, -74.00, "coffee");

// Geohash search
var geohash_results = gmls_search_by_geohash("dr5re", "", 20);

// Geohash utilities
var neighbors = gmls_geohash_neighbors("dr5re");
var decoded = _gmls_decode_geohash("dr5re");

// Get statistics
var geo_stats = gmls_get_geo_stats();
show_debug_message("Center: " + string(geo_stats.center.lat) + ", " + string(geo_stats.center.lng));
```

### Game Coordinates (2D)

```gml
// Add 2D location
gmls_add_location_2d("npc1", 150, 200);

// Search nearby
var player = { x: 155, y: 205 };
var nearby = gmls_search_nearby_2d(player.x, player.y, 50, "merchant", 10);

// Result includes distance in game units
for (var i = 0; i < array_length(nearby); i++) {
    show_debug_message(nearby[i].document.metadata.title + 
                       " | " + string(nearby[i].distance) + " units");
}
```

### Game Coordinates (3D)

```gml
// Add 3D location
gmls_add_location_3d("floating_island", 500, 300, 100);

// Search in 3D space
var player = { x: 510, y: 305, z: 95 };
var nearby = gmls_search_nearby_3d(player.x, player.y, player.z, 30, "", 10);
```

### Grid Optimization (Large Worlds)

```gml
// Add with grid optimization (cell size = 200 units)
gmls_add_location_grid("city1", 1000, 2000, 200);

// Search using grid (much faster for large datasets)
var results = gmls_search_nearby_grid(1200, 2100, 400, 200, "shop", 20);

// Results include cell information
for (var i = 0; i < array_length(results); i++) {
    show_debug_message(results[i].document.metadata.title + 
                       " | cell: " + results[i].cell);
}
```

---

## Learning-to-Rank

### Overview

LTR trains a linear model that learns optimal feature weights from user feedback.

### Features Used

| Feature | Description |
|---------|-------------|
| `bm25_score` | Traditional relevance score |
| `term_frequency` | How often query terms appear |
| `doc_length_norm` | Normalized document length |
| `title_match` | Query terms in title |
| `term_coverage` | % of query terms found |
| `freshness` | Newer documents get higher scores |
| `popularity` | CTR (clicks/impressions) |

### Basic Workflow

```gml
// 1. Enable LTR
gmls_enable_ltr(true);

// 2. Add training examples
gmls_add_training_example("fantasy rpg", "game1", 1.0);  // highly relevant
gmls_add_training_example("fantasy rpg", "game2", 0.3);  // low relevance
gmls_add_training_example("action games", "game3", 0.9); // medium-high

// 3. Train model
var log = gmls_train_linear_model(100, 0.005);
for (var i = 0; i < array_length(log); i++) {
    show_debug_message(log[i]);
}

// 4. Record user clicks
gmls_record_click("game1");
gmls_record_click_from_result(0); // first result from last search

// 5. Search with LTR
var results = gmls_search_ltr("fantasy", 10);
for (var i = 0; i < array_length(results); i++) {
    show_debug_message(results[i].document.metadata.title + 
                       " | LTR: " + string(results[i].ltr_score) +
                       " | BM25: " + string(results[i].original_score));
}
```

### Managing Models

```gml
// Get feature weights
var stats = gmls_get_ltr_stats();
var weights = stats.feature_weights;
var names = variable_struct_get_names(weights);
for (var i = 0; i < array_length(names); i++) {
    show_debug_message(names[i] + ": " + string(weights[$ names[i]]));
}

// Save model
var model_json = gmls_save_ltr_model();

// Load model later
gmls_load_ltr_model(model_json);

// Evaluate model (requires test/train split)
var evaluation = gmls_evaluate_model(0.2);
show_debug_message("RMSE: " + string(evaluation.rmse));
```

### Custom Features

```gml
// Register custom feature extractor
function my_custom_feature(_doc_id, _query, _doc) {
    // Return a number (e.g., 0-1)
    return 0.5;
}

gmls_register_feature_extractor("my_feature", my_custom_feature);

// Set its weight
gmls_set_feature_weight("my_feature", 0.3);
```

---

## Advanced Snippets

### Overview

Generates context-aware excerpts with term highlighting and multiple strategies.

### Strategies

| Strategy | Description | Best For |
|----------|-------------|----------|
| `best_fragment` | Selects highest-scoring text windows | General use |
| `surrounding` | Takes context around best match | Short queries |
| `balanced` | Combines multiple relevant sentences | Longer documents |

### Configuration

```gml
gmls_configure_snippets({
    highlight_start: "[",
    highlight_end: "]",
    strategy: "best_fragment",
    default_length: 200,
    fragment_count: 2,
    fragment_separator: " ... ",
    boost_title: true,
    boost_exact_phrase: 1.5
});
```

### Usage

```gml
// Search with snippets automatically
var results = gmls_search_with_snippets("dragons magic", 10);
for (var i = 0; i < array_length(results); i++) {
    show_debug_message("Title: " + results[i].highlighted_title);
    show_debug_message("Snippet: " + results[i].snippet);
}

// Generate snippet for specific document
var snippet = gmls_generate_advanced_snippet("doc1", "dragons", 
    { default_length: 150, highlight_start: "★", highlight_end: "★" });

// Get multiple candidates for UI selection
var candidates = gmls_get_snippet_candidates("doc1", "magic spells", 3);
for (var i = 0; i < array_length(candidates); i++) {
    show_debug_message(candidates[i].text);
}
```

---

## Query Understanding

### Overview

Provides spell checking, auto-complete, and related query suggestions based on user behavior.

### Auto-Complete

```gml
// Get suggestions as user types
var suggestions = gmls_get_suggestions("fan", 5);
// Returns: ["fantasy", "fantasy rpg", "fantasy games"]

// Configure
global.gmls.suggestions_enabled = true;
global.gmls.max_suggestions = 5;
global.gmls.min_prefix_length = 2;
```

### Spell Checking

```gml
// Single word
var corrected = gmls_spell_check("fantacy");
// Returns: "fantasy"

// Full query
var correction = gmls_correct_query("fantacy rpg magik");
// Returns: { original: "fantacy rpg magik", corrected: "fantasy rpg magic", changed: true }

// Disable auto-correct
global.gmls.auto_correct_enabled = false;
```

### Search with Understanding

```gml
var result = gmls_search_with_understanding("fantacy rpg", 10);
show_debug_message("Original: " + result.original_query);
show_debug_message("Corrected: " + result.corrected_query);
show_debug_message("Was corrected: " + string(result.was_corrected));
show_debug_message("Results: " + string(result.result_count));
show_debug_message("Suggestions: " + string_join(result.suggestions, ", "));
show_debug_message("Related: " + string_join(result.related_queries, ", "));
```

### Tracking & Analytics

```gml
// Log user searches (for popularity)
gmls_log_query("zelda guide", 5, 0);

// Get popular queries
var popular = gmls_get_popular_queries(10);
for (var i = 0; i < array_length(popular); i++) {
    show_debug_message(string(i+1) + ". " + popular[i]);
}

// Get related queries (based on click behavior)
var related = gmls_get_related_queries("fantasy rpg", 3);

// Get query statistics
var qstats = gmls_get_query_stats();
show_debug_message("Total queries: " + string(qstats.total_queries));
show_debug_message("Unique queries: " + string(qstats.unique_queries));
show_debug_message("Dictionary size: " + string(qstats.dictionary_size));
```

---

## Developer Tools

### Explain Score

```gml
var explanation = gmls_explain_score("fantasy rpg", "game1", true);
// Outputs detailed breakdown:
// - Term contributions
// - IDF values
// - BM25/TF-IDF calculations
// - Document statistics
```

### Profile Search

```gml
var profile = gmls_profile_search("complex query", 20);
show_debug_message("Average: " + string(profile.average_ms) + "ms");
show_debug_message("Min: " + string(profile.min_ms) + "ms");
show_debug_message("Max: " + string(profile.max_ms) + "ms");
show_debug_message("Std Dev: " + string(profile.std_dev) + "ms");
show_debug_message("QPS: " + string(profile.qps));
```

### Inspect Index

```gml
var inspection = gmls_inspect_index({ 
    show_top_terms: 20, 
    show_sample_docs: 5,
    show_ngrams: false 
});
// Shows: term distribution, sample documents, health checks
```

### Benchmark

```gml
var benchmark = gmls_benchmark(50);
// Runs tests on actual query terms, provides recommendations
```

### Debug Term

```gml
gmls_debug_term("dragon");
// Shows: document frequency, IDF, sample documents containing term
```

### Analyze Query

```gml
var analysis = gmls_analyze_query("The quick brown fox");
show_debug_message("Terms: " + string_join(analysis.terms, ", "));
show_debug_message("Stop words removed: " + string_join(analysis.stop_words_removed, ", "));
```

---

## API Reference

### Initialization & Cleanup

| Function | Description |
|----------|-------------|
| `gmls_init()` | Initialize search engine |
| `gmls_clear()` | Remove documents, keep config |
| `gmls_cleanup()` | Full memory cleanup |

### Document Management

| Function | Description |
|----------|-------------|
| `gmls_add_document(id, text, [metadata])` | Basic add |
| `gmls_add_document_enhanced(id, text, [metadata])` | Title & tags x2 |
| `gmls_add_document_weighted(id, text, [metadata])` | Title x3, tags x2 |
| `gmls_add_document_faceted(id, text, facets, [metadata])` | Add with facets |
| `gmls_remove_document(id)` | Remove by ID |
| `gmls_get_document(id)` | Retrieve document |
| `gmls_get_stats()` | Get index statistics |

### Search Methods

| Function | Description |
|----------|-------------|
| `gmls_search(query, max_results)` | BM25/TF-IDF search |
| `gmls_fuzzy_search(query, max_results, threshold)` | Fuzzy matching |
| `gmls_search_prefix(query, max_results)` | Prefix search |
| `gmls_search_hybrid(query, max_results)` | Exact then prefix |
| `gmls_search_ngrams(query, max_results)` | Character n-gram |
| `gmls_search_faceted(query, max_results, return_facets)` | Faceted search |
| `gmls_search_ltr(query, max_results)` | LTR search |

### Geospatial

| Function | Description |
|----------|-------------|
| `gmls_add_geolocation(id, lat, lng, precision)` | Real-world coords |
| `gmls_add_location_2d(id, x, y)` | 2D game coords |
| `gmls_add_location_3d(id, x, y, z)` | 3D game coords |
| `gmls_add_location_grid(id, x, y, cell_size)` | Grid optimization |
| `gmls_search_nearby(lat, lng, radius, unit, query, max)` | Radius search |
| `gmls_search_nearby_2d(x, y, radius, query, max)` | 2D radius |
| `gmls_search_nearby_3d(x, y, z, radius, query, max)` | 3D radius |
| `gmls_search_nearby_grid(x, y, radius, cell_size, query, max)` | Grid search |
| `gmls_search_box(min_lat, min_lng, max_lat, max_lng, query, max)` | Bounding box |
| `gmls_get_nearest(lat, lng, limit, query)` | Get nearest N |
| `gmls_get_geo_stats()` | Geo statistics |

### Faceted Search

| Function | Description |
|----------|-------------|
| `gmls_add_facet_filter(facet_name, value)` | Add filter |
| `gmls_remove_facet_filter(facet_name, value)` | Remove filter |
| `gmls_clear_facet_filters()` | Clear all filters |
| `gmls_get_active_filters()` | Get current filters |
| `gmls_set_filter_operator(operator)` | "AND" or "OR" |
| `gmls_get_facet_counts(query, filters, facets)` | Get facet counts |
| `gmls_add_range_facet(id, facet_name, numeric_value)` | Add numeric facet |
| `gmls_get_range_facet_counts(facet_name, min, max, bucket_size)` | Range counts |

### Learning-to-Rank

| Function | Description |
|----------|-------------|
| `gmls_enable_ltr(enabled)` | Enable/disable LTR |
| `gmls_add_training_example(query, doc_id, relevance)` | Add training data |
| `gmls_train_linear_model(iterations, learning_rate)` | Train model |
| `gmls_record_click(doc_id)` | Record click |
| `gmls_record_click_from_result(index)` | Click from last results |
| `gmls_get_ltr_stats()` | Get LTR statistics |
| `gmls_save_ltr_model()` | Export model |
| `gmls_load_ltr_model(json)` | Import model |
| `gmls_evaluate_model(test_ratio)` | Evaluate model |
| `gmls_set_feature_weight(feature_name, weight)` | Set feature weight |
| `gmls_register_feature_extractor(feature_name, script)` | Custom feature |

### Snippets

| Function | Description |
|----------|-------------|
| `gmls_configure_snippets(config)` | Configure snippet settings |
| `gmls_generate_advanced_snippet(doc_id, query, options)` | Generate snippet |
| `gmls_search_with_snippets(query, max_results, options)` | Search with snippets |
| `gmls_get_snippet_candidates(doc_id, query, max)` | Get multiple candidates |

### Query Understanding

| Function | Description |
|----------|-------------|
| `gmls_get_suggestions(prefix, max)` | Auto-complete |
| `gmls_spell_check(word)` | Correct single word |
| `gmls_correct_query(query)` | Correct full query |
| `gmls_search_with_understanding(query, max_results)` | Search with understanding |
| `gmls_log_query(query, result_count, selected_index)` | Log user search |
| `gmls_get_popular_queries(limit)` | Get popular queries |
| `gmls_get_related_queries(query, max)` | Get related queries |
| `gmls_get_query_stats()` | Query statistics |
| `gmls_record_click_with_query(query, doc_id)` | Record click with query |

### Configuration

| Function | Description |
|----------|-------------|
| `gmls_set_config(case_sensitive, stemming, min_word_len, scoring)` | Global settings |
| `gmls_set_bm25_params(k1, b)` | BM25 parameters |
| `gmls_add_stop_word(word)` | Add stop word |

### Persistence

| Function | Description |
|----------|-------------|
| `gmls_save_to_string()` | Export index to JSON |
| `gmls_load_from_string(json)` | Import index from JSON |

### Developer Tools

| Function | Description |
|----------|-------------|
| `gmls_explain_score(query, doc_id, verbose)` | Explain relevance |
| `gmls_profile_search(query, iterations)` | Performance profile |
| `gmls_inspect_index(options)` | Index inspection |
| `gmls_benchmark(iterations)` | Run benchmark |
| `gmls_debug_term(term)` | Debug term |
| `gmls_analyze_query(query)` | Analyze query |
| `gmls_assert_search(query, expected_min, test_name)` | Assertion test |
| `gmls_clear_query_history()` | Clear query history |
| `gmls_get_query_history()` | Get query history |

---

## Configuration

### Global Settings

```gml
// Direct access
global.gmls.case_sensitive = false;
global.gmls.enable_stemming = true;
global.gmls.min_word_length = 2;
global.gmls.scoring = "bm25";  // or "tfidf"
global.gmls.enable_ngrams = true;
global.gmls.ngram_size = 3;
global.gmls.max_doc_size = 50000;

// Or using helper
gmls_set_config(false, true, 2, "bm25");
```

### BM25 Parameters

```gml
// Default: k1 = 1.2, b = 0.75
// Higher k1 = more term frequency impact
// Higher b = more document length normalization

gmls_set_bm25_params(1.5, 0.8);
```

### Snippet Configuration

```gml
gmls_configure_snippets({
    highlight_start: "<mark>",
    highlight_end: "</mark>",
    strategy: "best_fragment",  // "best_fragment", "surrounding", "balanced"
    default_length: 200,
    fragment_count: 2,
    fragment_separator: " ... ",
    boost_title: true,
    boost_exact_phrase: 1.5
});
```

### Query Understanding Settings

```gml
global.gmls.suggestions_enabled = true;
global.gmls.auto_correct_enabled = true;
global.gmls.max_suggestions = 5;
global.gmls.min_prefix_length = 2;
```

---

## Performance Tuning

### Dataset Size Recommendations

| Dataset Size | Recommendations |
|--------------|-----------------|
| < 1,000 docs | Enable all features |
| 1,000 - 10,000 | Disable n-grams for speed |
| 10,000 - 50,000 | Increase min_word_length to 3, disable n-grams |
| > 50,000 | Use grid optimization, consider sharding |

### Speed Optimizations

```gml
// Disable expensive features
global.gmls.enable_ngrams = false;
global.gmls.enable_stemming = false;

// Increase minimum word length
global.gmls.min_word_length = 3;

// Reduce document size limit
global.gmls.max_doc_size = 20000;

// Use faster search methods
var results = gmls_search_prefix("short", 10);
var hybrid = gmls_search_hybrid("query", 10);
```

### Memory Optimizations

```gml
// Clear caches periodically
gmls_clear_idf_cache();
gmls_clear_geo_cache();
_gmls_invalidate_suggestion_cache();

// Save and reload to defragment
var saved = gmls_save_to_string();
gmls_cleanup();
gmls_init();
gmls_load_from_string(saved);
```

### Grid Optimization for Large Worlds

```gml
// Use appropriate cell size based on search radius
// Cell size should be ~2x typical search radius

var cell_size = 200;  // for typical 100 unit search radius
gmls_add_location_grid("entity", x, y, cell_size);
var results = gmls_search_nearby_grid(player_x, player_y, 100, cell_size);
```

---

## Troubleshooting

### Common Issues

| Problem | Solution |
|---------|----------|
| No search results | Check case sensitivity, stop words, min_word_length |
| Poor relevance | Enable LTR or tune BM25 parameters |
| Slow search | Disable n-grams, increase min_word_length |
| Memory high | Reduce max_doc_size, disable n-grams |
| LTR not improving | Add more training examples (100+) |
| Spell check not working | Build dictionary from index terms after adding documents |

### Debug Checklist

```gml
// 1. Check index stats
var stats = gmls_get_stats();
show_debug_message("Documents: " + string(stats.document_count));

// 2. Verify document exists
var doc = gmls_get_document("my_id");
show_debug_message(doc != undefined);

// 3. Analyze query
var analysis = gmls_analyze_query("my query");

// 4. Check term index
gmls_debug_term("myterm");

// 5. Profile performance
gmls_profile_search("my query", 10);
```

---

## License

MIT License - see header in GMLiteSearch_Core.gml
