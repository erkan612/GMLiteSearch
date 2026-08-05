# GMLiteSearch Tutorials

Welcome. This is a ten-chapter series that teaches GMLiteSearch from the ground up, starting with what a search engine actually is and why you'd want one, and ending with a full, three-model machine-learning ranking system trained on your own data.

## Who this is for

If you've never built or used a search system before, you're in the right place. Each chapter explains the underlying *concept* before showing the code, what an inverted index is, what "relevance" means, what it means for a machine to "learn" a ranking, not just a list of function signatures. If you already know some of this from experience elsewhere, feel free to skip ahead; every chapter is self-contained enough to jump into directly, though later chapters do build on ideas introduced earlier.

The chapters get progressively harder. Chapter 1 assumes nothing. Chapter 10 assumes you've followed along and picked up the ideas from everything before it, decision trees, gradient boosting, and NDCG are genuinely demanding material, and we take our time with them.

## What is GMLiteSearch?

GMLiteSearch is a pure GML search engine framework for GameMaker, no external DLLs, no extensions. It brings the kind of search capability you'd expect from a real, production search system (an inverted index, BM25 relevance scoring, faceted filtering, geospatial queries, typo tolerance, and trainable machine-learning ranking) into a form any GameMaker project can use directly.

It's designed for small to medium datasets, item databases, quest logs, NPC directories, in-game marketplaces, lore compendiums, anywhere a player needs to *find* something rather than browse a short, fixed list.

## How to use these tutorials

Each chapter comes with everything you need to follow along directly in GameMaker:

- **A `ChapterN.md` file**, the chapter itself, with explanations, diagrams, and complete code examples.
- **A `ChapterN_Dataset.gml` file**, the full, complete dataset used throughout that chapter, ready to paste into a script and use immediately. Every number and example quoted in the chapter text was checked against this exact data.
- **A handful of `.svg` diagrams** per chapter, referenced directly in the chapter text, illustrating the concepts that are easier to see than to describe in words alone.

Every chapter uses its own dataset, chosen to fit what that chapter is teaching, a weapons-and-potions inventory for Chapter 1's basics, a village of NPCs for Chapter 2's metadata lessons, a full game marketplace for the faceted search and machine-learning chapters. Nothing is shared or reused arbitrarily; if two chapters use similar data, it's because one is a direct, deliberate extension of the other (Chapter 5's dates extend Chapter 4's marketplace; Chapter 9's RankNet trains on the exact same data as Chapter 8's linear model, specifically so you can compare them fairly).

## The chapters

### [Chapter 1: What Is a Search Engine, Anyway?](Chapters/Chapter1/Chapter1.md)
The gentlest possible starting point. What problem does a search engine actually solve, and why can't you just check every document one by one? Learn what an inverted index is, why it makes search fast, and what "relevance" means, then build your first working index and run your first searches.

### [Chapter 2: Documents, Metadata, and Why Structure Matters](Chapters/Chapter2/Chapter2.md)
Not every part of a document deserves equal weight. Learn what metadata is, how weighted indexing makes titles count more than body text (and exactly how that mechanism actually works, down to the literal text repetition behind it), and the full lifecycle of a document, adding, removing, and the "no update function, just remove and re-add" pattern.

### [Chapter 3: Typos, Prefixes, and Making Search Forgiving](Chapters/Chapter3/Chapter3.md)
Real players don't type perfectly. This chapter covers fuzzy search (and precisely what it's good and bad at, missing letters versus transposed letters behave very differently), prefix search for autocomplete, hybrid search, and character-level n-gram search for severe typos. Includes an honest look at where each mode's forgiveness actually runs out.

### [Chapter 4: Filtering, Faceted Search Explained](Chapters/Chapter4/Chapter4.md)
Filtering and searching are different problems that work beautifully together. Learn what a facet is, how to filter by category, tags, platform, and price, and, critically, the precise two-level logic behind combining multiple filters (values within one facet always combine with OR; different facets combine according to your AND/OR setting). This distinction trips people up more than anything else in faceted search, so we go slowly.

### [Chapter 5: Working With Time, Date Facets and Time-Based Queries](Chapters/Chapter5/Chapter5.md)
"Show me what's new" is a deceptively hard question. Covers date filtering with explicit ranges and convenient presets, the exact inclusive-start/exclusive-end boundary rule, the difference between rolling-window and calendar-aligned presets, and date histograms for visualizing a collection's shape over time. Includes a real, verified limitation in how automatic date bucketing behaves.

### [Chapter 6: Location-Aware Search, Geospatial Concepts](Chapters/Chapter6/Chapter6.md)
A genuinely different kind of search. Covers both real-world coordinates (latitude/longitude, using the curvature-aware Haversine formula) and game-world coordinates (arbitrary x/y/z units, using straightforward Euclidean distance), and explains precisely why these two systems need different math. Includes a from-scratch explanation of geohashing, verified with real encode/decode round-trips.

### [Chapter 7: Making Results Readable, Snippets and Query Understanding](Chapters/Chapter7/Chapter7.md)
Finding the right document isn't the same as presenting it usefully. Covers snippet generation (three different strategies, with an honest look at two real, confirmed quirks in how highlighting currently behaves), spell-checking with true edit distance, autocomplete suggestions, and related-query recommendations built from real usage signals.

### [Chapter 8: Teaching the Machine, Introduction to Learning-to-Rank](Chapters/Chapter8/Chapter8.md)
The start of a three-chapter arc into trainable, machine-learned ranking, genuinely the most conceptually significant material in the series. Starts from first principles: what does it mean for a machine to "learn" anything, explained with a plain-language analogy before any code. Builds your first trainable ranking model using gradient descent, explained precisely rather than just named.

### [Chapter 9: Beyond Regression, RankNet and Custom Signals](Chapters/Chapter9/Chapter9.md)
Predicting an exact number and getting the ranking order right are genuinely different goals. This chapter introduces RankNet, which learns directly from pairwise comparisons instead of absolute predictions, and covers custom feature extractors, letting you teach the model about signals specific to your own game, like player ratings, that GMLiteSearch has no built-in way to know about.

### [Chapter 10: Decision Trees, Boosting, and LambdaMART](Chapters/Chapter10/Chapter10.md)
The final chapter, and the most demanding one. Builds decision trees and gradient boosting from scratch using a plain-language example before any code, introduces NDCG (a ranking-quality metric with a deliberate, mathematically precise bias toward getting the top of a list right), and combines everything into LambdaMART, the most powerful ranking model GMLiteSearch offers. Closes with a tour of the framework's developer and debugging tools.

## Where to go from here

If you're new to GMLiteSearch, start at Chapter 1 and work through in order, the series is built to be read that way, with each chapter assuming you have the concepts from everything before it. If you're looking for something specific, the [API Reference](https://github.com/erkan612/GMLiteSearch/blob/main/RawDocumentation.md) has every function documented directly, without the surrounding narrative.

Good luck, and happy building.
