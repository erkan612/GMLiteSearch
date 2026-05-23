# GMLiteSearch - Raw Documentation

Complete function reference with parameters, return values, and usage examples.

---

## Core Search Functions

### gmls_init()
Initializes the search engine and all subsystems (facets, geo, LTR, snippets, query understanding).

**Parameters:** None

**Returns:** Nothing

**Example:**
```gml
gmls_init();
```

---

### gmls_cleanup()
Destroys all data structures and frees memory. Should be called when closing the game.

**Parameters:** None

**Returns:** Nothing

**Example:**
```gml
gmls_cleanup();
```

---

### gmls_clear()
Removes all documents but preserves configuration settings (stop words, n-gram settings, etc.).

**Parameters:** None

**Returns:** Nothing

**Example:**
```gml
gmls_clear();
```

---

### gmls_search(query, max_results)
Performs exact word search using BM25 (default) or TF-IDF.

**Parameters:**
- `query` (string) - Search query text
- `max_results` (int, optional) - Maximum number of results (-1 for all)

**Returns:** Array of result structs

**Example:**
```gml
var results = gmls_search("fantasy rpg", 10);
```

---

### gmls_fuzzy_search(query, max_results, threshold)
Fuzzy search using bigram similarity for typo tolerance.

**Parameters:**
- `query` (string) - Search query text
- `max_results` (int, optional) - Maximum number of results
- `threshold` (float, default: 0.6) - Minimum similarity (0-1, higher = stricter)

**Returns:** Array of result structs

**Example:**
```gml
var results = gmls_fuzzy_search("fantacy", 5, 0.6);
```

---

### gmls_search_prefix(query, max_results)
Prefix search for autocomplete functionality.

**Parameters:**
- `query` (string) - Prefix to match
- `max_results` (int, optional) - Maximum number of results

**Returns:** Array of result structs

**Example:**
```gml
var results = gmls_search_prefix("fan", 5);
```

---

### gmls_search_hybrid(query, max_results)
Exact search first, then prefix search as fallback.

**Parameters:**
- `query` (string) - Search query text
- `max_results` (int, optional) - Maximum number of results

**Returns:** Array of result structs

**Example:**
```gml
var results = gmls_search_hybrid("fantacy", 10);
```

---

### gmls_search_ngrams(query, max_results)
Character trigram search for severe typos.

**Parameters:**
- `query` (string) - Search query text
- `max_results` (int, optional) - Maximum number of results

**Returns:** Array of result structs

**Example:**
```gml
var results = gmls_search_ngrams("excalibr", 5);
```

---

### gmls_set_config(case_sensitive, enable_stemming, min_word_length, scoring)
Sets global search configuration.

**Parameters:**
- `case_sensitive` (bool) - Whether search is case sensitive
- `enable_stemming` (bool) - Enable Porter2 stemming
- `min_word_length` (int) - Minimum word length to index
- `scoring` (string) - "bm25" or "tfidf"

**Returns:** Nothing

**Example:**
```gml
gmls_set_config(false, true, 2, "bm25");
```

---

### gmls_set_bm25_params(k1, b)
Tunes BM25 scoring parameters.

**Parameters:**
- `k1` (float, default: 1.2) - Term frequency saturation
- `b` (float, default: 0.75) - Document length normalization

**Returns:** Nothing

**Example:**
```gml
gmls_set_bm25_params(1.5, 0.8);
```

---

### gmls_add_stop_word(word)
Adds a word to ignore during indexing and search.

**Parameters:**
- `word` (string) - Word to treat as stop word

**Returns:** Nothing

**Example:**
```gml
gmls_add_stop_word("wizard");
```

---

## Document Management Functions

### gmls_add_document(id, text, metadata)
Adds a basic document to the index.

**Parameters:**
- `id` (any) - Unique document identifier
- `text` (string) - Document text content
- `metadata` (struct, optional) - Additional data (title, tags, etc.)

**Returns:** bool - Success status

**Example:**
```gml
gmls_add_document("doc1", "Content here", { title: "My Doc" });
```

---

### gmls_add_document_weighted(id, text, metadata)
Adds document with weighted fields (title x3, tags x2).

**Parameters:**
- `id` (any) - Unique document identifier
- `text` (string) - Document text content
- `metadata` (struct) - Must contain title and/or tags for weighting

**Returns:** bool - Success status

**Example:**
```gml
gmls_add_document_weighted("doc1", "Content", { title: "Important", tags: ["guide"] });
```

---

### gmls_add_document_enhanced(id, text, metadata)
Alias for gmls_add_document_weighted().

**Parameters:** Same as gmls_add_document_weighted()

**Returns:** bool - Success status

---

### gmls_remove_document(id)
Removes a document from the index.

**Parameters:**
- `id` (any) - Document identifier

**Returns:** bool - Success status

**Example:**
```gml
gmls_remove_document("doc1");
```

---

### gmls_get_document(id)
Retrieves a document by ID.

**Parameters:**
- `id` (any) - Document identifier

**Returns:** struct or undefined

**Example:**
```gml
var doc = gmls_get_document("doc1");
if (doc != undefined) {
    show_debug_message(doc.text);
}
```

---

### gmls_get_stats()
Returns index statistics.

**Parameters:** None

**Returns:** Struct with fields:
- `document_count` (int)
- `unique_words` (int)
- `total_word_occurrences` (int)
- `ngram_count` (int)
- `stemming_enabled` (bool)

**Example:**
```gml
var stats = gmls_get_stats();
show_debug_message("Documents: " + string(stats.document_count));
```

---

## Faceted Search Functions

### gmls_add_document_faceted(id, text, facets, metadata)
Adds document with facet categories for filtering.

**Parameters:**
- `id` (any) - Unique document identifier
- `text` (string) - Document text content
- `facets` (struct) - Facet name-value pairs
- `metadata` (struct, optional) - Additional metadata

**Returns:** bool - Success status

**Example:**
```gml
var facets = { category: "rpg", platform: "pc", year: 2024 };
gmls_add_document_faceted("game1", "Epic RPG", facets, { title: "Dragon Fantasy" });
```

---

### gmls_add_facet_filter(facet_name, value)
Adds an active facet filter.

**Parameters:**
- `facet_name` (string) - Facet field name
- `value` (any) - Facet value to filter by

**Returns:** bool - Success status

**Example:**
```gml
gmls_add_facet_filter("category", "rpg");
```

---

### gmls_remove_facet_filter(facet_name, value)
Removes a specific facet filter.

**Parameters:**
- `facet_name` (string) - Facet field name
- `value` (any) - Facet value to remove

**Returns:** bool - Success status

**Example:**
```gml
gmls_remove_facet_filter("category", "rpg");
```

---

### gmls_clear_facet_filters()
Removes all active facet filters.

**Parameters:** None

**Returns:** Nothing

**Example:**
```gml
gmls_clear_facet_filters();
```

---

### gmls_get_active_filters()
Returns currently active facet filters.

**Parameters:** None

**Returns:** Struct - { facet_name: [values] }

**Example:**
```gml
var filters = gmls_get_active_filters();
```

---

### gmls_set_filter_operator(operator)
Sets logic between facet groups ("AND" or "OR").

**Parameters:**
- `operator` (string) - "AND" or "OR"

**Returns:** Nothing

**Example:**
```gml
gmls_set_filter_operator("OR");
```

---

### gmls_get_facet_counts(query, filters, facets_to_aggregate)
Gets count of documents matching each facet value.

**Parameters:**
- `query` (string) - Search query (empty for all docs)
- `filters` (array, optional) - Temporary filters {facet, value}
- `facets_to_aggregate` (array, optional) - Facet names to count

**Returns:** Struct - { facet_name: { value: count } }

**Example:**
```gml
var counts = gmls_get_facet_counts("", undefined, ["category", "platform"]);
var categories = counts[$ "category"];
```

---

### gmls_search_faceted(query, max_results, return_facets)
Searches with active facet filters applied.

**Parameters:**
- `query` (string) - Search query
- `max_results` (int, optional) - Maximum results
- `return_facets` (array, optional) - Facets to return counts for

**Returns:** Struct with fields:
- `results` (array) - Search results
- `facets` (struct) - Facet counts
- `total` (int) - Total matching documents
- `filtered_from` (int) - Original search results count

**Example:**
```gml
var result = gmls_search_faceted("fantasy", 20, ["category", "tags"]);
```

---

### gmls_add_range_facet(id, facet_name, numeric_value)
Adds numeric value for range faceting.

**Parameters:**
- `id` (any) - Document identifier
- `facet_name` (string) - Facet field name
- `numeric_value` (real) - Numeric value to bucket

**Returns:** Nothing

**Example:**
```gml
gmls_add_range_facet("game1", "price", 59.99);
```

---

### gmls_get_range_facet_counts(facet_name, min, max, bucket_size)
Gets bucket counts for numeric range facet.

**Parameters:**
- `facet_name` (string) - Facet field name
- `min` (real) - Minimum value
- `max` (real) - Maximum value
- `bucket_size` (real) - Size of each bucket

**Returns:** Struct - { "min-max": count }

**Example:**
```gml
var price_buckets = gmls_get_range_facet_counts("price", 0, 100, 20);
```

---

## Geospatial Functions

### gmls_add_geolocation(doc_id, lat, lng, geohash_precision)
Adds real-world coordinates to a document.

**Parameters:**
- `doc_id` (any) - Document identifier
- `lat` (real) - Latitude
- `lng` (real) - Longitude
- `geohash_precision` (int, default: 6) - Geohash length (1-12)

**Returns:** bool - Success status

**Example:**
```gml
gmls_add_geolocation("shop1", 40.7128, -74.0060, 6);
```

---

### gmls_add_location_2d(doc_id, x, y)
Adds 2D game world coordinates.

**Parameters:**
- `doc_id` (any) - Document identifier
- `x` (real) - X coordinate
- `y` (real) - Y coordinate

**Returns:** bool - Success status

**Example:**
```gml
gmls_add_location_2d("npc1", 150, 200);
```

---

### gmls_add_location_3d(doc_id, x, y, z)
Adds 3D game world coordinates.

**Parameters:**
- `doc_id` (any) - Document identifier
- `x` (real) - X coordinate
- `y` (real) - Y coordinate
- `z` (real) - Z coordinate

**Returns:** bool - Success status

**Example:**
```gml
gmls_add_location_3d("island1", 500, 300, 100);
```

---

### gmls_add_location_grid(doc_id, x, y, cell_size)
Adds grid-optimized location for large worlds.

**Parameters:**
- `doc_id` (any) - Document identifier
- `x` (real) - X coordinate
- `y` (real) - Y coordinate
- `cell_size` (real, default: 100) - Grid cell size

**Returns:** bool - Success status

**Example:**
```gml
gmls_add_location_grid("city1", 1000, 2000, 200);
```

---

### gmls_search_nearby(lat, lng, radius, unit, query, max_results)
Searches within radius of real-world coordinates.

**Parameters:**
- `lat` (real) - Center latitude
- `lng` (real) - Center longitude
- `radius` (real) - Search radius
- `unit` (string, default: "km") - "km" or "mi"
- `query` (string, default: "") - Text filter
- `max_results` (int, optional) - Maximum results

**Returns:** Array of result structs with added fields:
- `distance` (real)
- `distance_unit` (string)
- `location` (struct with lat, lng)

**Example:**
```gml
var nearby = gmls_search_nearby(40.7130, -74.0065, 0.5, "km", "pizza", 10);
```

---

### gmls_search_nearby_2d(x, y, radius, query, max_results)
Searches within radius of 2D game coordinates.

**Parameters:**
- `x` (real) - Center X coordinate
- `y` (real) - Center Y coordinate
- `radius` (real) - Search radius in game units
- `query` (string, default: "") - Text filter
- `max_results` (int, optional) - Maximum results

**Returns:** Array of result structs with added fields:
- `distance` (real)
- `position` (struct with x, y)

**Example:**
```gml
var nearby = gmls_search_nearby_2d(155, 205, 50, "merchant", 10);
```

---

### gmls_search_nearby_3d(x, y, z, radius, query, max_results)
Searches within radius of 3D game coordinates.

**Parameters:**
- `x` (real) - Center X coordinate
- `y` (real) - Center Y coordinate
- `z` (real) - Center Z coordinate
- `radius` (real) - Search radius in game units
- `query` (string, default: "") - Text filter
- `max_results` (int, optional) - Maximum results

**Returns:** Array of result structs with added fields:
- `distance` (real)
- `position` (struct with x, y, z)

**Example:**
```gml
var nearby = gmls_search_nearby_3d(510, 305, 95, 30, "", 10);
```

---

### gmls_search_nearby_grid(x, y, radius, cell_size, query, max_results)
Grid-optimized search for large worlds.

**Parameters:**
- `x` (real) - Center X coordinate
- `y` (real) - Center Y coordinate
- `radius` (real) - Search radius in game units
- `cell_size` (real) - Grid cell size (should match add call)
- `query` (string, default: "") - Text filter
- `max_results` (int, optional) - Maximum results

**Returns:** Array of result structs with added fields:
- `distance` (real)
- `position` (struct with x, y)
- `cell` (string) - Cell identifier

**Example:**
```gml
var results = gmls_search_nearby_grid(1200, 2100, 400, 200, "shop", 20);
```

---

### gmls_search_box(min_lat, min_lng, max_lat, max_lng, query, max_results)
Searches within bounding box.

**Parameters:**
- `min_lat`, `min_lng`, `max_lat`, `max_lng` (real) - Box coordinates
- `query` (string, default: "") - Text filter
- `max_results` (int, optional) - Maximum results

**Returns:** Array of result structs

**Example:**
```gml
var results = gmls_search_box(40.70, -74.02, 40.72, -74.00, "coffee", 20);
```

---

### gmls_search_by_geohash(geohash_prefix, query, max_results)
Searches by geohash prefix.

**Parameters:**
- `geohash_prefix` (string) - Geohash prefix to match
- `query` (string, default: "") - Text filter
- `max_results` (int, optional) - Maximum results

**Returns:** Array of result structs

**Example:**
```gml
var results = gmls_search_by_geohash("dr5re", "", 20);
```

---

### gmls_get_nearest(lat, lng, limit, query)
Returns N closest locations.

**Parameters:**
- `lat` (real) - Center latitude
- `lng` (real) - Center longitude
- `limit` (int, default: 5) - Number of results
- `query` (string, default: "") - Text filter

**Returns:** Array of result structs sorted by distance

**Example:**
```gml
var nearest = gmls_get_nearest(40.7130, -74.0065, 5);
```

---

### gmls_get_geo_stats()
Returns geospatial statistics.

**Parameters:** None

**Returns:** Struct with fields:
- `total_locations` (int)
- `center` (struct with lat, lng)
- `bounds` (struct with min_lat, max_lat, min_lng, max_lng)
- `has_data` (bool)

**Example:**
```gml
var stats = gmls_get_geo_stats();
```

---

### gmls_clear_geo_cache()
Clears geospatial query cache.

**Parameters:** None

**Returns:** Nothing

**Example:**
```gml
gmls_clear_geo_cache();
```

---

### gmls_geohash_neighbors(geohash)
Returns 8 neighboring geohashes.

**Parameters:**
- `geohash` (string) - Geohash string

**Returns:** Array of 8 geohash strings

**Example:**
```gml
var neighbors = gmls_geohash_neighbors("dr5re");
```

---

## Learning-to-Rank Functions

### gmls_enable_ltr(enabled)
Enables or disables LTR ranking.

**Parameters:**
- `enabled` (bool) - Enable LTR

**Returns:** Nothing

**Example:**
```gml
gmls_enable_ltr(true);
```

---

### gmls_add_training_example(query, doc_id, relevance_score)
Adds training data for LTR model.

**Parameters:**
- `query` (string) - Search query
- `doc_id` (any) - Document identifier
- `relevance_score` (float) - Relevance (0-1, higher = more relevant)

**Returns:** bool - Success status

**Example:**
```gml
gmls_add_training_example("fantasy rpg", "game1", 1.0);
```

---

### gmls_train_linear_model(iterations, learning_rate)
Trains the linear ranking model.

**Parameters:**
- `iterations` (int, default: 200) - Training iterations
- `learning_rate` (float, default: 0.001) - Step size

**Returns:** Array of log strings

**Example:**
```gml
var log = gmls_train_linear_model(100, 0.005);
for (var i = 0; i < array_length(log); i++) {
    show_debug_message(log[i]);
}
```

---

### gmls_record_click(doc_id)
Records a click on a document (increases popularity).

**Parameters:**
- `doc_id` (any) - Document identifier

**Returns:** Nothing

**Example:**
```gml
gmls_record_click("game1");
```

---

### gmls_record_click_from_result(result_index)
Records click on result from last search.

**Parameters:**
- `result_index` (int) - Index in last_results array

**Returns:** Nothing

**Example:**
```gml
gmls_record_click_from_result(0);
```

---

### gmls_search_ltr(query, max_results)
Searches using LTR ranking.

**Parameters:**
- `query` (string) - Search query
- `max_results` (int, optional) - Maximum results

**Returns:** Array of result structs with added fields:
- `ltr_score` (float) - LTR score
- `original_score` (float) - Original BM25 score

**Example:**
```gml
var results = gmls_search_ltr("fantasy", 10);
```

---

### gmls_get_ltr_stats()
Returns LTR statistics.

**Parameters:** None

**Returns:** Struct with fields:
- `enabled` (bool)
- `model` (string)
- `training_examples` (int)
- `feature_weights` (struct)
- `total_clicks` (int)
- `total_impressions` (int)

**Example:**
```gml
var stats = gmls_get_ltr_stats();
var weights = stats.feature_weights;
```

---

### gmls_save_ltr_model()
Exports LTR model to JSON.

**Parameters:** None

**Returns:** string - JSON representation of model

**Example:**
```gml
var model_json = gmls_save_ltr_model();
```

---

### gmls_load_ltr_model(json)
Imports LTR model from JSON.

**Parameters:**
- `json` (string) - JSON model data

**Returns:** bool - Success status

**Example:**
```gml
gmls_load_ltr_model(model_json);
```

---

### gmls_evaluate_model(test_ratio)
Evaluates LTR model on test data.

**Parameters:**
- `test_ratio` (float, default: 0.2) - Portion of data for testing

**Returns:** Struct with fields:
- `error` (bool)
- `test_samples` (int)
- `mse` (float) - Mean squared error
- `mae` (float) - Mean absolute error
- `rmse` (float) - Root mean squared error

**Example:**
```gml
var eval = gmls_evaluate_model(0.2);
show_debug_message("RMSE: " + string(eval.rmse));
```

---

### gmls_set_feature_weight(feature_name, weight)
Sets weight for a specific feature.

**Parameters:**
- `feature_name` (string) - Feature name
- `weight` (float) - New weight value

**Returns:** Nothing

**Example:**
```gml
gmls_set_feature_weight("title_match", 1.5);
```

---

### gmls_register_feature_extractor(feature_name, script)
Registers a custom feature extractor function.

**Parameters:**
- `feature_name` (string) - Feature name
- `script` (script/function) - Function that returns a float

**Returns:** Nothing

**Example:**
```gml
function my_feature(doc_id, query, doc) {
    return 0.5;
}
gmls_register_feature_extractor("my_feature", my_feature);
```

---

## Snippet Functions

### gmls_configure_snippets(config)
Configures snippet generation settings.

**Parameters:**
- `config` (struct) with fields:
  - `highlight_start` (string) - Opening marker
  - `highlight_end` (string) - Closing marker
  - `strategy` (string) - "best_fragment", "surrounding", or "balanced"
  - `default_length` (int) - Maximum snippet length
  - `fragment_count` (int) - Number of fragments
  - `fragment_separator` (string) - Between fragments
  - `boost_title` (bool) - Boost title matches
  - `boost_exact_phrase` (float) - Phrase match multiplier

**Returns:** Nothing

**Example:**
```gml
gmls_configure_snippets({
    highlight_start: "[",
    highlight_end: "]",
    strategy: "best_fragment",
    default_length: 200
});
```

---

### gmls_generate_advanced_snippet(doc_id, query, options)
Generates highlighted snippet for a document.

**Parameters:**
- `doc_id` (any) - Document identifier
- `query` (string) - Search query
- `options` (struct, optional) - Override snippet config

**Returns:** string - Highlighted snippet

**Example:**
```gml
var snippet = gmls_generate_advanced_snippet("doc1", "dragons", 
    { default_length: 150 });
```

---

### gmls_search_with_snippets(query, max_results, snippet_options)
Searches and generates snippets automatically.

**Parameters:**
- `query` (string) - Search query
- `max_results` (int, optional) - Maximum results
- `snippet_options` (struct, optional) - Override snippet config

**Returns:** Array of result structs with added fields:
- `snippet` (string) - Highlighted snippet
- `highlighted_title` (string) - Title with highlights

**Example:**
```gml
var results = gmls_search_with_snippets("magic dragons", 10);
```

---

### gmls_get_snippet_candidates(doc_id, query, max_candidates)
Returns multiple snippet candidates for UI selection.

**Parameters:**
- `doc_id` (any) - Document identifier
- `query` (string) - Search query
- `max_candidates` (int, default: 3) - Number of candidates

**Returns:** Array of candidate structs with fields:
- `text` (string) - Snippet text
- `position` (int) - Start position
- `term` (string) - Matched term

**Example:**
```gml
var candidates = gmls_get_snippet_candidates("doc1", "magic spells", 3);
```

---

## Query Understanding Functions

### gmls_get_suggestions(prefix, max)
Returns autocomplete suggestions.

**Parameters:**
- `prefix` (string) - Partial query text
- `max` (int, optional) - Maximum suggestions

**Returns:** Array of suggestion strings

**Example:**
```gml
var suggestions = gmls_get_suggestions("fan", 5);
```

---

### gmls_spell_check(word)
Corrects a misspelled word.

**Parameters:**
- `word` (string) - Word to check

**Returns:** string - Corrected word

**Example:**
```gml
var corrected = gmls_spell_check("fantacy");
```

---

### gmls_correct_query(query)
Corrects an entire search query.

**Parameters:**
- `query` (string) - Query to correct

**Returns:** Struct with fields:
- `original` (string)
- `corrected` (string)
- `changed` (bool)

**Example:**
```gml
var result = gmls_correct_query("fantacy rpg");
```

---

### gmls_search_with_understanding(query, max_results)
Searches with automatic spell correction and suggestions.

**Parameters:**
- `query` (string) - Search query
- `max_results` (int, optional) - Maximum results

**Returns:** Struct with fields:
- `original_query` (string)
- `corrected_query` (string)
- `was_corrected` (bool)
- `results` (array)
- `suggestions` (array)
- `related_queries` (array)
- `result_count` (int)

**Example:**
```gml
var result = gmls_search_with_understanding("fantacy rpg", 10);
```

---

### gmls_log_query(query, result_count, selected_index)
Logs a user search for popularity tracking.

**Parameters:**
- `query` (string) - Search query
- `result_count` (int) - Number of results
- `selected_index` (int, default: -1) - Which result was clicked

**Returns:** Nothing

**Example:**
```gml
gmls_log_query("zelda guide", 5, 0);
```

---

### gmls_record_click_with_query(query, doc_id)
Records click with query context.

**Parameters:**
- `query` (string) - Search query
- `doc_id` (any) - Document clicked

**Returns:** Nothing

**Example:**
```gml
gmls_record_click_with_query("sword", "sword1");
```

---

### gmls_get_popular_queries(limit)
Returns most frequent queries.

**Parameters:**
- `limit` (int, default: 10) - Number of queries

**Returns:** Array of query strings

**Example:**
```gml
var popular = gmls_get_popular_queries(10);
```

---

### gmls_get_related_queries(query, max)
Returns queries related to the given query.

**Parameters:**
- `query` (string) - Base query
- `max` (int, default: 5) - Maximum results

**Returns:** Array of query strings

**Example:**
```gml
var related = gmls_get_related_queries("fantasy rpg", 3);
```

---

### gmls_get_query_stats()
Returns query understanding statistics.

**Parameters:** None

**Returns:** Struct with fields:
- `total_queries` (int)
- `unique_queries` (int)
- `dictionary_size` (int)
- `suggestions_enabled` (bool)
- `auto_correct_enabled` (bool)

**Example:**
```gml
var stats = gmls_get_query_stats();
```

---

### gmls_clear_query_history()
Clears all logged query history.

**Parameters:** None

**Returns:** Nothing

**Example:**
```gml
gmls_clear_query_history();
```

---

### gmls_get_query_history()
Returns array of logged queries.

**Parameters:** None

**Returns:** Array of query log structs

**Example:**
```gml
var history = gmls_get_query_history();
```

---

## Persistence Functions

### gmls_save_to_string()
Exports entire search index to JSON.

**Parameters:** None

**Returns:** string - JSON representation

**Example:**
```gml
var save_str = gmls_save_to_string();
var file = file_text_open_write("index.json");
file_text_write_string(file, save_str);
file_text_close(file);
```

---

### gmls_load_from_string(json)
Imports search index from JSON.

**Parameters:**
- `json` (string) - JSON data

**Returns:** bool - Success status

**Example:**
```gml
if (file_exists("index.json")) {
    var file = file_text_open_read("index.json");
    var load_str = file_text_read_string(file);
    file_text_close(file);
    gmls_load_from_string(load_str);
}
```

---

## Developer Tools Functions

### gmls_explain_score(query, doc_id, verbose)
Explains why a document received its score.

**Parameters:**
- `query` (string) - Search query
- `doc_id` (any) - Document identifier
- `verbose` (bool, default: true) - Print detailed output

**Returns:** Struct with explanation data

**Example:**
```gml
var explanation = gmls_explain_score("fantasy rpg", "game1", true);
```

---

### gmls_profile_search(query, iterations)
Measures search performance.

**Parameters:**
- `query` (string) - Search query
- `iterations` (int, default: 10) - Number of test runs

**Returns:** Struct with timing statistics

**Example:**
```gml
var profile = gmls_profile_search("complex query", 20);
show_debug_message("Average: " + string(profile.average_ms) + "ms");
```

---

### gmls_inspect_index(options)
Performs health check on index.

**Parameters:**
- `options` (struct, optional) with fields:
  - `show_top_terms` (int, default: 20)
  - `show_sample_docs` (int, default: 5)
  - `show_ngrams` (bool, default: false)

**Returns:** Struct with inspection data

**Example:**
```gml
var inspection = gmls_inspect_index({ show_top_terms: 10 });
```

---

### gmls_benchmark(iterations)
Runs benchmark suite on index.

**Parameters:**
- `iterations` (int, default: 100) - Iterations per query

**Returns:** Struct with benchmark results

**Example:**
```gml
var benchmark = gmls_benchmark(50);
```

---

### gmls_debug_term(term)
Debug output for a specific term.

**Parameters:**
- `term` (string) - Term to debug

**Returns:** Nothing (prints to console)

**Example:**
```gml
gmls_debug_term("dragon");
```

---

### gmls_analyze_query(query)
Analyzes how a query will be processed.

**Parameters:**
- `query` (string) - Query to analyze

**Returns:** Struct with fields:
- `original` (string)
- `terms` (array)
- `stop_words_removed` (array)

**Example:**
```gml
var analysis = gmls_analyze_query("The quick brown fox");
```

---

### gmls_assert_search(query, expected_min_results, test_name)
Asserts minimum results for testing.

**Parameters:**
- `query` (string) - Search query
- `expected_min_results` (int) - Minimum expected results
- `test_name` (string, default: "Untitled Test") - Test identifier

**Returns:** Struct with test results

**Example:**
```gml
var test = gmls_assert_search("fantasy", 2, "Fantasy search test");
```

---

## Result Struct Reference

All search functions return an array of result structs with the following fields:

| Field | Type | Description |
|-------|------|-------------|
| `id` | any | Document identifier |
| `score` | float | Relevance score |
| `document` | struct | Full document object |
| `document.text` | string | Document text |
| `document.metadata` | struct | User metadata |
| `document.word_count` | int | Number of words |
| `matched_terms` | array | Query terms found |
| `snippet` | string | Excerpt preview |

**Additional fields for LTR search:**
| Field | Type | Description |
|-------|------|-------------|
| `ltr_score` | float | LTR model score |
| `original_score` | float | Original BM25 score |

**Additional fields for geospatial search:**
| Field | Type | Description |
|-------|------|-------------|
| `distance` | float | Distance from center |
| `distance_unit` | string | "km" or "mi" for real-world, "units" for game coords |
| `location` | struct | Coordinates (lat/lng or x/y/z) |
| `geohash` | string | Geohash (real-world only) |
| `position` | struct | X,Y for 2D; X,Y,Z for 3D |
| `cell` | string | Cell ID (grid search only) |

**Additional fields for snippet search:**
| Field | Type | Description |
|-------|------|-------------|
| `highlighted_title` | string | Title with highlight markers |

---

## Global Configuration Struct

Access via `global.gmls`:

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `case_sensitive` | bool | false | Case sensitivity |
| `enable_stemming` | bool | true | Porter2 stemming |
| `min_word_length` | int | 2 | Minimum word length |
| `scoring` | string | "bm25" | "bm25" or "tfidf" |
| `bm25_k1` | float | 1.2 | BM25 term saturation |
| `bm25_b` | float | 0.75 | BM25 length norm |
| `enable_ngrams` | bool | true | Character trigrams |
| `ngram_size` | int | 3 | N-gram length |
| `max_doc_size` | int | 50000 | Max characters per doc |
| `ltr_enabled` | bool | false | LTR active |
| `suggestions_enabled` | bool | true | Auto-complete |
| `auto_correct_enabled` | bool | true | Spell checking |
| `max_suggestions` | int | 5 | Suggestions limit |
| `min_prefix_length` | int | 2 | Min chars for suggestions |
