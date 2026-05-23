## **What's New**

### Faceted Search
- **Multi-field filtering** - Filter results by category, tags, platform, price, or any custom field
- **Aggregation counts** - Show number of results per facet value (like e-commerce filters)
- **Range facets** - Numeric and date range bucketing (price: 0-20, 20-50, 50+)
- **AND/OR operators** - Flexible filter logic between facet groups
- **Real-time filter management** - Add, remove, and clear filters dynamically

### Geospatial Search
- **Real-world coordinates** - Latitude/longitude with Haversine distance calculation
- **Game coordinates** - 2D and 3D position search for open world games
- **Grid optimization** - Cell-based indexing for large worlds with 10,000+ entities
- **Geohash support** - Efficient proximity indexing with neighbor calculation
- **Radius and box search** - Find locations within distance or bounding area

### Learning-to-Rank (LTR)
- **Trainable relevance model** - Linear model that learns from user clicks
- **7 built-in features** - BM25 score, term frequency, title match, term coverage, freshness, popularity, document length
- **Custom features** - Register your own feature extractor functions
- **Click tracking** - Record user clicks and impressions for popularity boosting
- **Model persistence** - Save trained models to JSON and reload them

### Advanced Snippets
- **Context-aware excerpts** - Generates snippets around matched terms
- **Three strategies** - Best fragment, surrounding context, or balanced multi-sentence
- **Term highlighting** - Customizable markers around matched words and phrases
- **Phrase detection** - Quoted strings are boosted and highlighted as units
- **Multiple candidates** - Generate several snippet options for UI selection

### Query Understanding
- **Auto-complete** - Real-time suggestions as user types, based on popular queries and index terms
- **Spell checking** - Levenshtein distance correction learned from user queries
- **Query correction** - Automatic fixing of entire search queries
- **Related queries** - Suggestions based on click behavior and term similarity
- **Popular queries tracking** - Log and retrieve most frequent searches

### Developer Tools
- **Score explanation** - Detailed breakdown of why a document received its score
- **Performance profiling** - Measure query execution time with statistics
- **Index inspection** - Health checks, term distribution, and sample documents
- **Benchmark suite** - Automated performance testing with recommendations
- **Term debugging** - Inspect index entries for specific words

### Persistence Enhancements
- **Full index export/import** - Save entire search state to JSON
- **LTR model persistence** - Save and load trained ranking models
- **Quick recovery** - Load saved indexes at game start