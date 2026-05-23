**First Release!**

- Fuzzy search – "zleda" finds "zelda"
- Prefix search – autocomplete as user types
- Hybrid search – exact first, then prefix fallback
- N-gram search – character-level matching for typos
- Persistence – save entire index to JSON, load it back
- BM25 scoring – better relevance than simple TF-IDF
- Memory safe – all DS maps properly cleaned