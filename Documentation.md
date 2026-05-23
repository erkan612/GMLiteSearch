# GMLS – GameMaker Lite Search

**Fast, flexible full‑text search for GameMaker**  
Built for small to medium datasets (10k‑50k+ docs) with real‑time indexing, fuzzy search, n‑grams, BM25/TF‑IDF scoring, and persistence.

---

## Features

- **Inverted index** with O(1) lookups  
- **Multiple search modes** – exact, fuzzy, prefix, hybrid, n‑gram (character‑level)  
- **Configurable scoring** – BM25 (default) or TF‑IDF  
- **Field weighting** – title (3x), tags (2x), custom metadata  
- **N‑gram indexing** for typo‑tolerant search  
- **Stop words** & minimum word length filtering  
- **Persistence** – save/load entire index to/from JSON  
- **Memory safe** – all DS maps properly cleaned  
- **Scale** – handles 50,000+ documents with good performance  

---

## Installation

1. Import the **GMLiteSearch_Core** script into your GameMaker project.
2. Call `gmls_init()` once, for example in a **Create** event or a **persistent controller** object.
3. Start adding documents and searching.

> No external DLLs or extensions – pure GML.

---

## Quick Start

```gml
// Initialize the search engine
gmls_init();

// Add a document with weighted fields (title gets 3x weight, tags 2x)
var metadata = {
    title: "The Legend of Zelda",
    tags: ["adventure", "fantasy", "Nintendo"],
    author: "Shigeru Miyamoto"
};
gmls_add_document_weighted("zelda_manual", 
    "Link must rescue Princess Zelda and defeat Ganon.", 
    metadata);

// Search with BM25 (default)
var results = gmls_search("zelda adventure", 5);
for (var i = 0; i < array_length(results); i++) {
    show_debug_message(results[i].id + " | score: " + string(results[i].score));
}

// Fuzzy search for typos
var fuzzy = gmls_fuzzy_search("zleda", 3, 0.6);

// Prefix search for autocomplete
var prefix = gmls_search_prefix("zel", 5);

// Hybrid search (exact then prefix)
var hybrid = gmls_search_hybrid("legnd", 10);

// N-gram search for character-level typos
var ngram = gmls_search_ngrams("excalibr", 5);

// Remove a document
gmls_remove_document("zelda_manual");

// Get statistics
var stats = gmls_get_stats();
show_debug_message("Docs: " + string(stats.document_count) + 
                   " | Words: " + string(stats.unique_words));

// Save index to file
var saveStr = gmls_save_to_string();
var file = file_text_open_write("search_index.json");
file_text_write_string(file, saveStr);
file_text_close(file);

// Load index from file
if (file_exists("search_index.json")) {
    file = file_text_open_read("search_index.json");
    var loadedStr = file_text_read_string(file);
    file_text_close(file);
    gmls_load_from_string(loadedStr);
}

// Clear all documents (keep config)
gmls_clear();

// Complete cleanup
gmls_cleanup();
```

---

## Configuration Examples

```gml
// Change global settings
gmls_set_config(true,   // case sensitive
                false,  // stemming (placeholder)
                2,      // minimum word length
                "bm25"); // scoring: "tfidf" or "bm25"

// Tune BM25 parameters (default: k1=1.2, b=0.75)
gmls_set_bm25_params(1.5, 0.8);

// Add custom stop words
gmls_add_stop_word("wizard");
gmls_add_stop_word("dragon");

// Direct configuration access
global.gmls.enable_ngrams = true;
global.gmls.ngram_size = 3;
global.gmls.max_doc_size = 50000;
```

---

## Document Addition Methods

```gml
// Plain document (only text is indexed)
gmls_add_document("doc1", "The quick brown fox jumps over the lazy dog");

// Enhanced – repeats title & tags twice (higher relevance)
gmls_add_document_enhanced("doc2", "Main content...", 
    { title: "My Awesome Article", tags: ["tutorial", "gamedev"] });

// Weighted – title 3x, tags 2x, others 1x (most control)
gmls_add_document_weighted("doc3", "content...", 
    { title: "Important", tags: ["guide"], author: "John", description: "A full guide" });

// Access stored document
var doc = gmls_get_document("doc3");
if (doc != undefined) {
    show_debug_message(doc.text);
    show_debug_message(doc.metadata.title);
    show_debug_message("Word count: " + string(doc.word_count));
}
```

---

## Search Results Structure

```gml
var results = gmls_search("example query", 10);
for (var i = 0; i < array_length(results); i++) {
    var res = results[i];
    
    // Available fields
    var _id = res.id;                    // Document identifier
    var _score = res.score;              // Relevance score
    var text = res.document.text;       // Full document text
    var title = res.document.metadata.title;  // Metadata title
    var tags = res.document.metadata.tags;    // Metadata tags
    var snippet = res.snippet;          // Highlighted excerpt
    var matched = res.matched_terms;    // Array of matched terms
    
    show_debug_message("ID: " + _id);
    show_debug_message("Score: " + string(_score));
    show_debug_message("Title: " + title);
    show_debug_message("Snippet: " + snippet);
    show_debug_message("Matched: " + string(matched));
}
```

---

## Real-World Example: In-Game Item Database

```gml
// Initialize at game start
gmls_init();
gmls_set_config(false, false, 2, "bm25");

// Add items from your game
var items = [
    { id: "sword1", name: "Iron Sword", desc: "A basic iron sword", type: "weapon", damage: 15 },
    { id: "sword2", name: "Steel Sword", desc: "A sharp steel blade", type: "weapon", damage: 25 },
    { id: "potion1", name: "Health Potion", desc: "Restores 50 HP", type: "consumable", heal: 50 },
    { id: "potion2", name: "Mana Potion", desc: "Restores 30 MP", type: "consumable", heal: 30 },
    { id: "armor1", name: "Leather Armor", desc: "Light protective gear", type: "armor", defense: 10 }
];

for (var i = 0; i < array_length(items); i++) {
    var it = items[i];
    gmls_add_document_weighted(it.id, it.desc, 
        { title: it.name, tags: [it.type], damage: it.damage, heal: it.heal, defense: it.defense });
}

// Search function with fallback
function search_items(query) {
    var results = gmls_search(query, 10);
    if (array_length(results) == 0) {
        results = gmls_fuzzy_search(query, 10, 0.5);
    }
    if (array_length(results) == 0 && global.gmls.enable_ngrams) {
        results = gmls_search_ngrams(query, 10);
    }
    return results;
}

// Usage in game
var found = search_items("steel blade");
for (var i = 0; i < array_length(found); i++) {
    var item = found[i].document;
    var score = found[i].score;
    show_debug_message("Found: " + item.metadata.title + 
                       " (Type: " + item.metadata.tags[0] + 
                       ", Score: " + string(score) + ")");
    
    // Access custom fields
    if (item.metadata.damage != undefined) {
        show_debug_message("  Damage: " + string(item.metadata.damage));
    }
    if (item.metadata.heal != undefined) {
        show_debug_message("  Heal: " + string(item.metadata.heal));
    }
}
```

---

## Persistence Example: Save/Load Player Notes

```gml
// Player creates notes during gameplay
function add_player_note(id, title, content) {
    gmls_add_document_weighted(id, content, 
        { title: title, tags: ["player_note"], timestamp: current_time });
}

add_player_note("note1", "Dragon Location", "The dragon lives in the eastern mountains near the old tower");
add_player_note("note2", "Quest Reminder", "Talk to the blacksmith about the enchanted sword");
add_player_note("note3", "Secret Entrance", "Behind the waterfall in the forest");

// Search player notes
function search_notes(query) {
    return gmls_search(query, 20);
}

var notes = search_notes("dragon tower");
for (var i = 0; i < array_length(notes); i++) {
    var note = notes[i];
    draw_text(10, 50 + i*60, "Title: " + note.document.metadata.title);
    draw_text(10, 70 + i*60, "Snippet: " + note.snippet);
}

// Save all notes to file
function save_all_notes() {
    var save_data = gmls_save_to_string();
    var file = file_text_open_write("player_notes.json");
    file_text_write_string(file, save_data);
    file_text_close(file);
    show_debug_message("Notes saved!");
}

// Load notes at game start
function load_all_notes() {
    if (file_exists("player_notes.json")) {
        var file = file_text_open_read("player_notes.json");
        var load_data = file_text_read_string(file);
        file_text_close(file);
        gmls_load_from_string(load_data);
        show_debug_message("Notes loaded!");
        return true;
    }
    return false;
}

// Auto-save every 5 minutes
alarm[0] = room_speed * 300; // 5 minutes
// In alarm event: save_all_notes();
```

---

## Performance Optimization Examples

```gml
// For small datasets (< 1000 docs) - use any mode
global.gmls.enable_ngrams = true;  // Keep typo tolerance
gmls_set_config(false, false, 2, "bm25");

// For medium datasets (1k - 10k docs)
global.gmls.enable_ngrams = false; // Disable for speed
gmls_set_config(false, false, 2, "bm25");
gmls_set_bm25_params(1.2, 0.75);

// For large datasets (10k - 50k+ docs)
global.gmls.enable_ngrams = false;
gmls_set_config(false, false, 3, "bm25"); // Increase min word length
gmls_set_bm25_params(1.2, 0.75);
global.gmls.max_doc_size = 20000; // Limit document size

// Use hybrid search for better UX
function smart_search(query, max_results) {
    if (string_length(query) <= 3) {
        return gmls_search_prefix(query, max_results);
    } else {
        return gmls_search(query, max_results);
    }
}

// Cache results for repeated queries
var last_query = "";
var last_results = [];
function cached_search(query, max_results) {
    if (query == last_query) {
        return last_results;
    }
    last_query = query;
    last_results = gmls_search(query, max_results);
    return last_results;
}
```

---

## Complete API Reference

# Initialization & Cleanup
| **Function** | **Description** |
|---|---|
| gmls_init() | Initialize the search engine |
| gmls_clear() | Remove all the documents and keep the config |
| gmls_cleanup() | Destroy everything and free the memory |

# Document Management
| **Function** | **Description** |
|---|---|
| gmls_add_document(id, text, [metadata]) | Basic add |
| gmls_add_document_enhanced(id, text, [metadata]) | Title & tags x2 |
| gmls_add_document_weighted(id, text, [metadata]) | Title x3 & tags x2 |
| gmls_remove_document(id) | Remove by ID |
| gmls_get_document(id) | Retrieve document |

# Search Methods
| **Function** | **Description** |
|---|---|
| gmls_search(query, max_results) | Exact word search |
| gmls_fuzzy_search(query, max_results, threshold) | Fuzzy (0-1 threshold) |
| gmls_search_prefix(query, max_results) | Prefix/autocomplete |
| gmls_search_hybrid(query, max_results) | Exact then prefix |
| gmls_search_ngrams(query, max_results) | Character n-gram |

# Configuration
| **Function** | **Description** |
|---|---|
| gmls_set_config(case_sensitive, stemming, min_word_len, scoring) | Set config/settings |
| gmls_set_bm25_params(k1, b) | Set bm25 params/settings |
| gmls_add_stop_word(word) | Add custom stop word |

# Utilities
| **Function** | **Description** |
|---|---|
| gmls_get_stats() | Returns document_count, unique_words, etc. |
| gmls_save_to_string() | Export index as JSON |
| gmls_load_from_string(json) | Import index from JSON |

---

## Statistics Object Structure

```gml
var stats = gmls_get_stats();
if (stats != undefined) {
    show_debug_message("=== GMLiteSearch Stats ===");
    show_debug_message("Documents: " + string(stats.document_count));
    show_debug_message("Unique words: " + string(stats.unique_words));
    show_debug_message("Total word occurrences: " + string(stats.total_word_occurrences));
    show_debug_message("N-gram count: " + string(stats.ngram_count));
    
    // Performance indicators
    var avg_words_per_doc = stats.total_word_occurrences / max(1, stats.document_count);
    show_debug_message("Avg words/doc: " + string(avg_words_per_doc));
    var index_efficiency = stats.unique_words / max(1, stats.total_word_occurrences);
    show_debug_message("Index density: " + string(index_efficiency));
}
```

---

## Important Notes

- **Multi-byte characters** (UTF-8 beyond ASCII) are partially supported  
- **Real-time updates** are fully supported – add/remove documents anytime  
- **Memory usage** grows with unique words and documents  
- For **50k+ documents**, expect 200-300 MB RAM usage  
- **Persistence** uses JSON – large indexes produce long strings, consider compression for production
