# GMLiteSearch

**Lightweight full-text search engine for GameMaker**

A pure GML framework that brings enterprise-grade search capabilities to your GameMaker projects. No external DLLs or extensions.

---

## Overview

GMLiteSearch is a complete search solution for GameMaker, designed for small to medium datasets (10k-50k+ documents) with real-time indexing and advanced search features.

---

## Features at a Glance

### Core Search
- **BM25 & TF-IDF scoring** – Industry-standard relevance algorithms
- **Fuzzy search** – Handles typos and misspellings
- **Prefix search** – Autocomplete suggestions
- **Hybrid search** – Exact matching with prefix fallback
- **N-gram search** – Character-level matching for severe typos

### Faceted Search
- **Multi-field filtering** – Category, tags, platform, price, etc.
- **Aggregation counts** – Show how many results per facet value
- **Range facets** – Numeric and date ranges
- **AND/OR operators** – Flexible filter logic

### Geospatial Search
- **Real-world coordinates** – Latitude/longitude with radius and box search
- **Game coordinates** – 2D, 3D, and grid-optimized for open worlds
- **Geohash support** – Efficient proximity indexing
- **Distance calculation** – Haversine for real world, Euclidean for game space

### Learning-to-Rank (LTR)
- **Trainable relevance** – Model learns from user clicks
- **7 built-in features** – BM25, term frequency, title match, freshness, popularity, etc.
- **Custom features** – Register your own feature extractors
- **Model persistence** – Save/load trained models

### Query Understanding
- **Spell checking** – Automatic correction of typos
- **Auto-complete** – Real-time suggestions as user types
- **Related queries** – Based on click behavior and term similarity
- **Popular queries** – Track most searched terms

### Snippet Generation
- **Context-aware excerpts** – Shows relevant text around matches
- **Term highlighting** – Customizable markers around matched terms
- **Multiple strategies** – Best fragment, surrounding, or balanced
- **Candidate generation** – Multiple snippet options for UI selection

### Developer Tools
- **Score explanation** – Understand why a document ranked where it did
- **Performance profiling** – Measure query execution time
- **Index inspection** – Health checks and statistics
- **Benchmark suite** – Automated performance testing

### Persistence
- **JSON export/import** – Save and load entire search index
- **Model persistence** – Save trained LTR models
- **Quick start/load** – Minimal setup for saved indexes

---

## Performance

| Dataset Size | Memory Estimate | Recommended Settings |
|--------------|-----------------|----------------------|
| < 1,000 docs | 10-30 MB | All features enabled |
| 1,000 - 10,000 | 30-100 MB | Disable n-grams |
| 10,000 - 50,000 | 100-300 MB | Increase min word length, disable n-grams |
| > 50,000 | 300+ MB | Use grid optimization, consider sharding |

---

## Use Cases

### RPG Games
- **Item database** – Search weapons, armor, potions by name, type, stats
- **Quest log** – Find quests by keywords, rewards, locations
- **NPC dialogue** – Search through dialogue trees for keywords
- **Location search** – Find NPCs, shops, dungeons near player position

### Strategy Games
- **Unit library** – Search units by name, class, abilities
- **Tech tree** – Find technologies by name, prerequisites, era
- **Resource management** – Filter buildings by type, cost, production

### Adventure/Puzzle Games
- **Inventory search** – Find items by name, description, use
- **Clue database** – Search through collected clues
- **Journal entries** – Find lore entries by keywords

### Content Management
- **Mod support** – Search through user-generated content
- **Localization** – Multi-language string searching
- **Asset management** – Find sprites, sounds, animations by tags

---

## Why GMLiteSearch?

| Traditional Approach | GMLiteSearch |
|---------------------|---------------|
| Linear text search (O(n)) | Inverted index (O(log n)) |
| No relevance scoring | BM25/TF-IDF scoring |
| No filtering | Faceted search with aggregations |
| No location support | Geospatial queries (real-world + game coords) |
| Fixed ranking | Learning-to-Rank from user clicks |
| No typo tolerance | Fuzzy and n-gram search |
| Manual snippet generation | Automatic context-aware snippets |

---

## Quick Comparison

| Feature | GMLiteSearch | ds_map manual search | GML built-in |
|---------|--------------|---------------------|--------------|
| Full-text search | ✅ | ❌ | ❌ |
| Relevance scoring | ✅ | ❌ | ❌ |
| Faceted filters | ✅ | ❌ | ❌ |
| Geospatial | ✅ | ❌ | ❌ |
| Learning-to-Rank | ✅ | ❌ | ❌ |
| Spell checking | ✅ | ❌ | ❌ |
| Auto-complete | ✅ | ❌ | ❌ |
| Fuzzy matching | ✅ | ❌ | ❌ |
| Persistence | ✅ | ❌ | ❌ |
| Pure GML | ✅ | ✅ | ✅ |

---

## Documentation

- **[Getting Started](GettingStarted.md)** – First time setup and basic usage
- **[Full Documentation](Documentation.md)** – Complete API reference and advanced topics

---

## License

MIT License – Free for commercial and non-commercial use
