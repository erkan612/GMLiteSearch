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
- **Three trainable ranking models** – Linear regression, pairwise RankNet, and gradient-boosted LambdaMART, selectable and comparable side-by-side
- **7 built-in features** – BM25, term frequency, title match, freshness, popularity, etc.
- **Custom features** – Register your own feature extractors, learned alongside the built-ins
- **Model persistence** – Save/load trained models, including full LambdaMART tree ensembles

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
| Fixed ranking | Trainable ranking, linear, RankNet, or LambdaMART |
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
| Learning-to-Rank (linear / RankNet / LambdaMART) | ✅ | ❌ | ❌ |
| Spell checking | ✅ | ❌ | ❌ |
| Auto-complete | ✅ | ❌ | ❌ |
| Fuzzy matching | ✅ | ❌ | ❌ |
| Persistence | ✅ | ❌ | ❌ |
| Pure GML | ✅ | ✅ | ✅ |

---

## Memory Performance
 
Figures assume short, single-sentence documents with a handful of metadata tags, larger or more varied text will cost more per document.
 
| Stemming | N-grams | Document Method | 500 docs | 1,000 docs | 5,000 docs | 10,000 docs | 25,000 docs | 50,000 docs | Bytes/doc |
|---|---|---|---|---|---|---|---|---|---|
| on | off | Weighted Document | 100.1 MB | 202.8 MB | 1,012.2 MB | 1.98 GB | 4.95 GB | 9.90 GB | ~212,600 |
| off | off | Weighted Document | 4.6 MB | 9.0 MB | 44.8 MB | 89.6 MB | 222.3 MB | 448.2 MB | ~9,400 |
| on | on | Weighted Document | 104.2 MB | 208.4 MB | 1.02 GB | 2.03 GB | 5.09 GB | 10.17 GB | ~218,500 |
| on | off | Plain Document | 58.8 MB | 117.6 MB | 587.9 MB | 1.15 GB | 2.87 GB | 5.74 GB | ~123,300 |
| off | on | Weighted Document | 8.75 MB | 17.5 MB | 87.5 MB | 175.0 MB | 437.5 MB | 875.0 MB | ~18,400 |
| off | off | Plain Document | 1.97 MB | 3.9 MB | 19.7 MB | 39.4 MB | 98.5 MB | 197.0 MB | ~4,100 |
| on | on | Plain Document | 61.1 MB | 122.2 MB | 610.8 MB | 1.19 GB | 2.98 GB | 5.96 GB | ~128,100 |
| off | on | Plain Document | 4.24 MB | 8.5 MB | 42.4 MB | 84.8 MB | 212.0 MB | 424.0 MB | ~8,900 |
 
- **Cheapest overall** – stemming off, n-grams off, Plain Document
- **Note** – savings don't simply add up; stemming off + Plain Document together saves more than either alone would suggest

---

## Documentation

- **[Getting Started](GettingStarted.md)** – First time setup and basic usage
- **[Full Documentation](Documentation.md)** – Complete API reference and advanced topics
- **[Tutorials](https://github.com/erkan612/GMLiteSearch/tree/main/Tutorials)** – Ten-chapter tutorials teaching GMLiteSearch from ground up to three-model machine-learning ranking system trained on your own data

---

## References

**Relevance scoring (BM25 & TF-IDF)**
Spärck Jones, K. (1972) "[A statistical interpretation of term specificity and its application in retrieval](https://www.emerald.com/jd/article/28/1/11/218980)", Journal of Documentation, 28(1), 11–21
Robertson, S. E. and Walker, S. (1994) "[Some Simple Effective Approximations to the 2-Poisson Model for Probabilistic Weighted Retrieval](http://www.staff.city.ac.uk/~sb317/papers/robertson_walker_sigir94.pdf)", SIGIR '94, 232–241
Robertson, S. and Zaragoza, H. (2009) "[The Probabilistic Relevance Framework: BM25 and Beyond](https://dl.acm.org/doi/10.1561/1500000019)", Foundations and Trends in Information Retrieval, 3(4), 333–389
Robertson, S., Zaragoza, H. and Taylor, M. (2004) "[Simple BM25 Extension to Multiple Weighted Fields](https://dl.acm.org/doi/10.1145/1031171.1031181)", CIKM '04

**Stemming**
Porter, M. F. (1980) "[An algorithm for suffix stripping](https://www.emerald.com/insight/content/doi/10.1108/eb046814/full/html)", Program, 14(3), 130–137
"[The English (Porter2) stemming algorithm](https://snowballstem.org/algorithms/english/stemmer.html)", Snowball

**Fuzzy matching & n-gram search**
Jaccard, P. (1912) "[The Distribution of the Flora in the Alpine Zone](https://nph.onlinelibrary.wiley.com/doi/10.1111/j.1469-8137.1912.tb05611.x)", New Phytologist, 11(2), 37–50
Kondrak, G. (2005) "[N-Gram Similarity and Distance](https://webdocs.cs.ualberta.ca/~kondrak/papers/spire05.pdf)", SPIRE 2005

**Spell correction**
Levenshtein, V. I. (1965; English translation 1966) "[Binary codes capable of correcting deletions, insertions and reversals](https://nymity.ch/sybilhunting/pdf/Levenshtein1966a.pdf)", Soviet Physics Doklady, 10(8), 707–710
Wagner, R. A. and Fischer, M. J. (1974) "[The String-to-String Correction Problem](https://dl.acm.org/doi/10.1145/321796.321811)", Journal of the ACM, 21(1), 168–173

**Faceted search**
Yee, K-P., Swearingen, K., Li, K. and Hearst, M. (2003) "[Faceted Metadata for Image Search and Browsing](https://dl.acm.org/doi/10.1145/642611.642681)", CHI '03

**Date/time handling**
ISO 8601:2019 "[Date and time, Representations for information interchange](https://www.iso.org/iso-8601-date-and-time-format.html)", ISO

**Geospatial search**
Sinnott, R. W. (1984) "[Virtues of the Haversine](https://babel.hathitrust.org/cgi/pt?id=uc1.b3342444&seq=444)", Sky and Telescope, 68(2), 159
Morton, G. M. (1966) "[A Computer Oriented Geodetic Data Base and a New Technique in File Sequencing](http://web.cs.ucla.edu/~weiwang/paper/computerdb.pdf)", IBM Technical Report
Niemeyer, G. (2008) "[Geohash](https://en.wikipedia.org/wiki/Geohash)"

**Learning-to-Rank, linear model**
Cauchy, A-L. (1847) "Méthode générale pour la résolution des systèmes d'équations simultanées", Comptes Rendus de l'Académie des Sciences, 25, 536–538
Liu, T-Y. (2009) "[Learning to Rank for Information Retrieval](https://www.nowpublishers.com/article/Details/INR-016)", Foundations and Trends in Information Retrieval, 3(3), 225–331

**Learning-to-Rank, RankNet**
Burges, C., Shaked, T., Renshaw, E., Lazier, A., Deeds, M., Hamilton, N. and Hullender, G. (2005) "[Learning to Rank using Gradient Descent](https://icml.cc/Conferences/2015/wp-content/uploads/2015/06/icml_ranking.pdf)", ICML '05, 89–96

**Learning-to-Rank, LambdaMART, gradient boosting, and NDCG**
Breiman, L., Friedman, J. H., Olshen, R. A. and Stone, C. J. (1984) "Classification and Regression Trees", Wadsworth
Friedman, J. H. (2001) "[Greedy Function Approximation: A Gradient Boosting Machine](https://www.jstor.org/stable/2699986)", The Annals of Statistics, 29(5), 1189–1232
Järvelin, K. and Kekäläinen, J. (2002) "[Cumulated Gain-Based Evaluation of IR Techniques](https://dl.acm.org/doi/10.1145/582415.582418)", ACM Transactions on Information Systems, 20(4), 422–446
Burges, C. J. C. (2010) "[From RankNet to LambdaRank to LambdaMART: An Overview](https://www.microsoft.com/en-us/research/publication/from-ranknet-to-lambdarank-to-lambdamart-an-overview/)", Microsoft Research Technical Report MSR-TR-2010-82
Wu, Q., Burges, C. J. C., Svore, K. M. and Gao, J. (2010) "[Adapting Boosting for Information Retrieval Measures](https://www.microsoft.com/en-us/research/publication/adapting-boosting-information-retrieval-measures/)", Information Retrieval, 13(3), 254–270
