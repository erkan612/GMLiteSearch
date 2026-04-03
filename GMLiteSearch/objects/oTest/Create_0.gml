// Initialize once
gmls_init();

// Add documents (weighted for title/tags)
gmls_add_document_weighted("doc1", "The quick brown fox jumps over the lazy dog", 
    { title: "Fox Story", tags: ["animal", "fable"] });

// Search with BM25 (default)
var results = gmls_search("brown fox", 10);
for (var i = 0; i < array_length(results); i++) {
    show_debug_message(results[i].id + " score:" + string(results[i].score));
}

// Switch to TF‑IDF
gmls_set_config(false, false, 2, "tfidf");

// Fuzzy search
var fuzzy = gmls_fuzzy_search("broun focks", 5, 0.6);