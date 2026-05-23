

//  DEVELOPER EXPERIENCE
function _gmls_format_decimal(_value, _decimals) {
    var _str = string(_value);
    var _dot_pos = string_pos(".", _str);
    
    if (_dot_pos == 0) {
        return _str + "." + string_repeat("0", _decimals);
    }
    
    var _integer_part = string_copy(_str, 1, _dot_pos - 1);
    var _decimal_part = string_copy(_str, _dot_pos + 1, string_length(_str) - _dot_pos);
    
    if (string_length(_decimal_part) > _decimals) {
        _decimal_part = string_copy(_decimal_part, 1, _decimals);
    } else {
        _decimal_part = _decimal_part + string_repeat("0", _decimals - string_length(_decimal_part));
    }
    
    return _integer_part + "." + _decimal_part;
}

function _gmls_merge_options(_options, _defaults) {
    if (is_undefined(_options)) _options = {};
    
    var _keys = variable_struct_get_names(_defaults);
    for (var i = 0; i < array_length(_keys); i++) {
        var _key = _keys[i];
        if (!variable_struct_exists(_options, _key)) {
            variable_struct_set(_options, _key, variable_struct_get(_defaults, _key));
        }
    }
    
    return _options;
}

function gmls_explain_score(_query, _doc_id, _verbose = true) {
    var _ls = global.gmls;
    
    var _explanation = {
        query: _query,
        document_id: _doc_id,
        total_score: 0,
        scoring_method: _ls.scoring,
        term_contributions: [],
        document_info: {},
        parameters: {}
    };
    
    if (!ds_map_exists(_ls.documents, _doc_id)) {
        return "Document " + string(_doc_id) + " not found";
    }
    
    var _doc = ds_map_find_value(_ls.documents, _doc_id);
    _explanation.document_info = {
        word_count: _doc.word_count,
        text_preview: string_copy(_doc.text, 1, 100) + "...",
        has_metadata: !is_undefined(_doc.metadata)
    };
    
    var _terms = _gmls_process_text(_query);
    var _total_score = 0;
    var _avg_len = _gmls_total_word_freq() / max(1, _ls.doc_count);
    
    for (var i = 0; i < array_length(_terms); i++) {
        var _term = _terms[i];
        var _term_detail = {
            term: _term,
            found_in_doc: false,
            term_frequency: 0,
            document_frequency: 0,
            idf: 0,
            contribution: 0,
            formula: ""
        };
        
        if (ds_map_exists(_ls.word_stats, _term)) {
            var _stats = ds_map_find_value(_ls.word_stats, _term);
            _term_detail.document_frequency = _stats.document_frequency;
            _term_detail.idf = log10((_ls.doc_count + 1) / _stats.document_frequency);
        }
        
        if (ds_map_exists(_ls.inverted_index, _term)) {
            var _docs = ds_map_find_value(_ls.inverted_index, _term);
            if (ds_map_exists(_docs, _doc_id)) {
                _term_detail.found_in_doc = true;
                _term_detail.term_frequency = ds_map_find_value(_docs, _doc_id);
                
                var _term_score = 0;
                
                if (_ls.scoring == "tfidf") { // TF-IDF
                    _term_score = _term_detail.term_frequency * _term_detail.idf;
                    _term_detail.formula = "TF(" + string(_term_detail.term_frequency) + ") x IDF(" + _gmls_format_decimal(_term_detail.idf, 3) + ") = " + _gmls_format_decimal(_term_score, 3);
                    
                } else { // BM25
                    var _k1 = _ls.bm25_k1;
                    var _b = _ls.bm25_b;
                    var _doc_len_norm = _doc.word_count / _avg_len;
                    var _tf_component = (_term_detail.term_frequency * (_k1 + 1)) / 
                                        (_term_detail.term_frequency + _k1 * (1 - _b + _b * _doc_len_norm));
                    _term_score = _term_detail.idf * _tf_component;
                    _term_detail.formula = "IDF(" + _gmls_format_decimal(_term_detail.idf, 3) + ") x TF_component(" + _gmls_format_decimal(_tf_component, 3) + ") = " + _gmls_format_decimal(_term_score, 3);
                }
                
                _term_detail.contribution = _term_score;
                _total_score += _term_score;
            }
        }
        
        array_push(_explanation.term_contributions, _term_detail);
    }
    
    _explanation.total_score = _total_score;
    _explanation.parameters = {
        avg_doc_length: _avg_len,
        total_docs: _ls.doc_count,
        unique_terms: ds_map_size(_ls.inverted_index),
        stemming_enabled: _ls.enable_stemming,
        case_sensitive: _ls.case_sensitive
    };
    
    if (_ls.scoring == "bm25") {
        _explanation.parameters.bm25_k1 = _ls.bm25_k1;
        _explanation.parameters.bm25_b = _ls.bm25_b;
    }
    
    if (_verbose) {
        var _output = "";
        _output += "\n========================================\n";
        _output += "SEARCH EXPLANATION: " + _query + "\n";
        _output += "========================================\n";
        _output += "Document: " + string(_doc_id) + "\n";
        _output += "Total Score: " + _gmls_format_decimal(_total_score, 4) + "\n";
        _output += "Scoring Method: " + string_upper(_ls.scoring) + "\n";
        _output += "----------------------------------------\n";
        _output += "TERM BREAKDOWN:\n";
        
        for (var i = 0; i < array_length(_explanation.term_contributions); i++) {
            var _t = _explanation.term_contributions[i];
            if (_t.found_in_doc) {
                _output += _t.term + "': +" + _gmls_format_decimal(_t.contribution, 4) + "\n";
                if (_verbose) {
                    _output += "      " + _t.formula + "\n";
                }
            } else {
                _output += _t.term + "': not found in document\n";
            }
        }
        
        _output += "----------------------------------------\n";
        _output += "Document word count: " + string(_explanation.document_info.word_count) + "\n";
        _output += "Average document length: " + _gmls_format_decimal(_explanation.parameters.avg_doc_length, 1) + "\n";
        _output += "========================================\n";
        
        show_debug_message(_output);
    }
    
    return _explanation;
}

function gmls_profile_search(_query, _iterations = 10) {
    var _profile = {
        query: _query,
        iterations: _iterations,
        timings: [],
        average_ms: 0,
        min_ms: 0,
        max_ms: 0,
        std_dev: 0,
        result_count: 0,
        terms_processed: 0,
        memory_estimate_mb: 0
    };
    
    var _terms = _gmls_process_text(_query);
    _profile.terms_processed = array_length(_terms);
    
    for (var i = 0; i < _iterations; i++) {
        var _start = current_time;
        var _results = gmls_search(_query, -1);
        var _duration = current_time - _start;
        
        array_push(_profile.timings, _duration);
        if (i == 0) _profile.result_count = array_length(_results);
    }
    
    var _sum = 0;
    _profile.min_ms = _profile.timings[0];
    _profile.max_ms = _profile.timings[0];
    
    for (var i = 0; i < array_length(_profile.timings); i++) {
        _sum += _profile.timings[i];
        if (_profile.timings[i] < _profile.min_ms) _profile.min_ms = _profile.timings[i];
        if (_profile.timings[i] > _profile.max_ms) _profile.max_ms = _profile.timings[i];
    }
    
    _profile.average_ms = _sum / array_length(_profile.timings);
    
    var _variance = 0;
    for (var i = 0; i < array_length(_profile.timings); i++) {
        _variance += power(_profile.timings[i] - _profile.average_ms, 2);
    }
    _profile.std_dev = sqrt(_variance / array_length(_profile.timings));
    
    var _ls = global.gmls;
    _profile.memory_estimate_mb = (
        ds_map_size(_ls.inverted_index) * 0.1 +
        ds_map_size(_ls.documents) * 0.05 +
        ds_map_size(_ls.word_stats) * 0.02
    ) / 1024;
    
    var _output = "";
    _output += "╔══════════════════════════════════════════╗\n";
    _output += "║         SEARCH PERFORMANCE PROFILE       ║\n";
    _output += "╚══════════════════════════════════════════╝\n";
    _output += "Query: \"" + _query + "\"\n";
    _output += "Iterations: " + string(_iterations) + "\n";
    _output += "Results found: " + string(_profile.result_count) + "\n";
    _output += "Terms processed: " + string(_profile.terms_processed) + "\n";
    _output += "\nTIMING STATISTICS:\n";
    _output += "  Average: " + _gmls_format_decimal(_profile.average_ms, 2) + "ms\n";
    _output += "  Minimum: " + string(_profile.min_ms) + "ms\n";
    _output += "  Maximum: " + string(_profile.max_ms) + "ms\n";
    _output += "  Std Dev: ±" + _gmls_format_decimal(_profile.std_dev, 2) + "ms\n";
    _output += "  QPS: " + _gmls_format_decimal(1000 / _profile.average_ms, 1) + " queries/sec\n";
    _output += "\nMEMORY ESTIMATE:\n";
    _output += "  ~" + _gmls_format_decimal(_profile.memory_estimate_mb, 2) + " MB\n";
    _output += "════════════════════════════════════════════\n";
    
    show_debug_message(_output);
    
    return _profile;
}

function gmls_inspect_index(_options = {}) {
    var _ls = global.gmls;
    var _defaults = {
        show_top_terms: 20,
        show_sample_docs: 5,
        show_ngrams: false,
        detail_level: "normal"
    };
    
    _options = _gmls_merge_options(_options, _defaults);
    
    var _inspection = {
        timestamp: current_time,
        stats: gmls_get_stats(),
        config: {
            case_sensitive: _ls.case_sensitive,
            stemming: _ls.enable_stemming,
            min_word_length: _ls.min_word_length,
            scoring: _ls.scoring,
            ngrams_enabled: _ls.enable_ngrams
        },
        top_terms: [],
        sample_documents: [],
        term_distribution: {
            total_terms: ds_map_size(_ls.inverted_index),
            total_postings: 0
        },
        health_checks: []
    };
    
    var _term_list = [];
    var _term = ds_map_find_first(_ls.word_stats);
    while (!is_undefined(_term)) {
        var _stats = ds_map_find_value(_ls.word_stats, _term);
        array_push(_term_list, {
            term: _term,
            doc_freq: _stats.document_frequency,
            total_freq: _stats.total_frequency
        });
        _term = ds_map_find_next(_ls.word_stats, _term);
    }
    
    array_sort(_term_list, function(a, b) { return b.doc_freq - a.doc_freq; });
    
    var _show_top = variable_struct_get(_options, "show_top_terms");
    for (var i = 0; i < min(_show_top, array_length(_term_list)); i++) {
        array_push(_inspection.top_terms, _term_list[i]);
        _inspection.term_distribution.total_postings += _term_list[i].doc_freq;
    }
    
    var _doc_id = ds_map_find_first(_ls.documents);
    var _sampled = 0;
    var _show_docs = variable_struct_get(_options, "show_sample_docs");
    while (!is_undefined(_doc_id) && _sampled < _show_docs) {
        var _doc = ds_map_find_value(_ls.documents, _doc_id);
        array_push(_inspection.sample_documents, {
            id: _doc_id,
            word_count: _doc.word_count,
            text_preview: string_copy(_doc.text, 1, 50) + "...",
            has_metadata: !is_undefined(_doc.metadata)
        });
        _doc_id = ds_map_find_next(_ls.documents, _doc_id);
        _sampled++;
    }
    
    _inspection.health_checks = _gmls_run_health_checks();
    
    var _output = "";
    _output += "\n";
    _output += "┌─────────────────────────────────────────┐\n";
    _output += "│         INDEX INSPECTION REPORT         │\n";
    _output += "└─────────────────────────────────────────┘\n\n";
    
    _output += "SATISTICS:\n";
    _output += "  Documents: " + string(_inspection.stats.document_count) + "\n";
    _output += "  Unique Terms: " + string(_inspection.stats.unique_words) + "\n";
    _output += "  Total Postings: " + string(_inspection.term_distribution.total_postings) + "\n";
    _output += "  Total Occurrences: " + string(_inspection.stats.total_word_occurrences) + "\n";
    
    var _show_ngrams = variable_struct_get(_options, "show_ngrams");
    if (_show_ngrams) {
        _output += "  N-grams: " + string(_inspection.stats.ngram_count) + "\n";
    }
    
    _output += "\nTOP TERMS (by document frequency):\n";
    for (var i = 0; i < array_length(_inspection.top_terms); i++) {
        var _t = _inspection.top_terms[i];
        _output += "  " + string(i+1) + ". '" + _t.term + "' -> " + string(_t.doc_freq) + " docs (" + string(_t.total_freq) + " occurrences)\n";
    }
    
    _output += "\nSAMPLE DOCUMENTS:\n";
    for (var i = 0; i < array_length(_inspection.sample_documents); i++) {
        var _d = _inspection.sample_documents[i];
        _output += "  [" + string(_d.id) + "] " + string(_d.word_count) + " words: " + _d.text_preview + "\n";
    }
    
    if (array_length(_inspection.health_checks) > 0) {
        _output += "\nHEALTH CHECKS:\n";
        for (var i = 0; i < array_length(_inspection.health_checks); i++) {
            var _h = _inspection.health_checks[i];
            var _icon = "+";
            if (!_h.passed) _icon = "!";
            _output += "  " + _icon + " " + _h.message + "\n";
        }
    }
    
    show_debug_message(_output);
    
    return _inspection;
}

function _gmls_run_health_checks() {
    var _checks = [];
    var _ls = global.gmls;
    
    var _inverted_size = ds_map_size(_ls.inverted_index);
    var _stats_size = ds_map_size(_ls.word_stats);
    if (_inverted_size == _stats_size) {
        array_push(_checks, { passed: true, message: "Index consistent (" + string(_inverted_size) + " terms)" });
    } else {
        array_push(_checks, { passed: false, message: "Index mismatch: inverted=" + string(_inverted_size) + ", stats=" + string(_stats_size) });
    }
    
    var _orphaned = 0;
    var _word = ds_map_find_first(_ls.inverted_index);
    while (!is_undefined(_word)) {
        var _docs = ds_map_find_value(_ls.inverted_index, _word);
        var _did = ds_map_find_first(_docs);
        while (!is_undefined(_did)) {
            if (!ds_map_exists(_ls.documents, _did)) _orphaned++;
            _did = ds_map_find_next(_docs, _did);
        }
        _word = ds_map_find_next(_ls.inverted_index, _word);
    }
    
    if (_orphaned == 0) {
        array_push(_checks, { passed: true, message: "No orphaned document references" });
    } else {
        array_push(_checks, { passed: false, message: "Found " + string(_orphaned) + " orphaned references" });
    }
    
    var _cache_size = ds_map_size(_ls.cache_idf);
    if (_cache_size < 1000) {
        array_push(_checks, { passed: true, message: "IDF cache healthy (" + string(_cache_size) + " entries)" });
    } else {
        array_push(_checks, { passed: false, message: "Large IDF cache (" + string(_cache_size) + "), consider clearing" });
    }
    
    var _stop_size = ds_list_size(_ls.stop_words);
    array_push(_checks, { passed: true, message: "Stop words loaded: " + string(_stop_size) });
    
    if (_ls.doc_count == 0) {
        array_push(_checks, { passed: false, message: "Index is empty - add documents first" });
    }
    
    return _checks;
}

function gmls_assert_search(_query, _expected_min_results, _test_name = "Untitled Test") {
    var _results = gmls_search(_query);
    var _actual = array_length(_results);
    var _passed = _actual >= _expected_min_results;
    
    var _output = "";
    if (_passed) {
        _output += "+";
    } else {
        _output += "x";
    }
    _output += " TEST: " + _test_name + "\n";
    _output += "  Query: \"" + _query + "\"\n";
    _output += "  Expected >= " + string(_expected_min_results) + " results, got " + string(_actual) + "\n";
    
    if (!_passed && _actual > 0) {
        _output += "  Top result: " + string(_results[0].id) + " (score: " + _gmls_format_decimal(_results[0].score, 3) + ")\n";
    }
    
    show_debug_message(_output);
    
    return { passed: _passed, expected: _expected_min_results, actual: _actual, results: _results };
}

function gmls_benchmark(_iterations = 100) {
    if (global.gmls.doc_count == 0) {
        show_debug_message("Cannot benchmark: No documents indexed");
        return undefined;
    }
    
    var _ls = global.gmls;
    var _test_queries = ["game", "search", "test", "engine", "performance"];
    
    if (ds_map_size(_ls.inverted_index) > 0) {
        _test_queries = [];
        var _term = ds_map_find_first(_ls.inverted_index);
        var _count = 0;
        while (!is_undefined(_term) && _count < 10) {
            array_push(_test_queries, _term);
            _term = ds_map_find_next(_ls.inverted_index, _term);
            _count++;
        }
    }
    
    var _benchmark = {
        timestamp: current_time,
        iterations: _iterations,
        queries_tested: [],
        overall_average_ms: 0,
        recommendations: []
    };
    
    show_debug_message("╔══════════════════════════════════════════╗");
    show_debug_message("║         BENCHMARK SUITE v1.0             ║");
    show_debug_message("╚══════════════════════════════════════════╝");
    show_debug_message("Running " + string(_iterations) + " iterations on " + string(array_length(_test_queries)) + " queries...\n");
    
    var _total_time = 0;
    
    for (var i = 0; i < array_length(_test_queries); i++) {
        var _query = _test_queries[i];
        var _profile = gmls_profile_search(_query, min(_iterations, 20));
        
        array_push(_benchmark.queries_tested, {
            query: _query,
            avg_ms: _profile.average_ms,
            result_count: _profile.result_count
        });
        
        _total_time += _profile.average_ms;
        show_debug_message("  '" + _query + "': " + _gmls_format_decimal(_profile.average_ms, 2) + "ms (" + string(_profile.result_count) + " results)");
    }
    
    _benchmark.overall_average_ms = _total_time / array_length(_benchmark.queries_tested);
    
    if (_benchmark.overall_average_ms > 100) {
        array_push(_benchmark.recommendations, "  Search is slow (>100ms). Consider enabling stemming or reducing index size.");
    }
    if (_ls.enable_ngrams && _benchmark.overall_average_ms > 50) {
        array_push(_benchmark.recommendations, "  N-gram search is enabled and may slow down queries. Disable if not needed.");
    }
    if (_ls.doc_count > 10000 && !_ls.enable_stemming) {
        array_push(_benchmark.recommendations, "  Enable stemming to reduce index size and improve speed.");
    }
    
    show_debug_message("\nBENCHMARK SUMMARY:");
    show_debug_message("  Overall Average: " + _gmls_format_decimal(_benchmark.overall_average_ms, 2) + "ms");
    show_debug_message("  Fastest Query: " + _gmls_format_decimal(_benchmark.queries_tested[0].avg_ms, 2) + "ms");
    
    if (array_length(_benchmark.recommendations) > 0) {
        show_debug_message("\nRECOMMENDATIONS:");
        for (var i = 0; i < array_length(_benchmark.recommendations); i++) {
            show_debug_message("  " + _benchmark.recommendations[i]);
        }
    }
    
    return _benchmark;
}

function gmls_debug_term(_term) {
    var _ls = global.gmls;
    var _normalized = _gmls_normalize_word(_term);
    
    show_debug_message("-------------------------------------------");
    show_debug_message("  TERM DEBUG: '" + _term + "'");
    show_debug_message("  Normalized: '" + _normalized + "'");
    show_debug_message("-------------------------------------------");
    
    if (!ds_map_exists(_ls.inverted_index, _normalized)) {
        show_debug_message("Term not found in index");
        
        show_debug_message("\nSimilar terms in index:");
        var _found = 0;
        var _word = ds_map_find_first(_ls.inverted_index);
        while (!is_undefined(_word) && _found < 5) {
            if (string_pos(_normalized, _word) > 0 || string_pos(_word, _normalized) > 0) {
                show_debug_message("  → '" + _word + "'");
                _found++;
            }
            _word = ds_map_find_next(_ls.inverted_index, _word);
        }
        if (_found == 0) show_debug_message("  (none found)");
        return;
    }
    
    var _docs = ds_map_find_value(_ls.inverted_index, _normalized);
    var _stats = ds_map_find_value(_ls.word_stats, _normalized);
    
    show_debug_message("\nSTATISTICS:");
    show_debug_message("  Document Frequency: " + string(_stats.document_frequency));
    show_debug_message("  Total Frequency: " + string(_stats.total_frequency));
    var _idf = log10((_ls.doc_count + 1) / _stats.document_frequency);
    show_debug_message("  IDF Score: " + _gmls_format_decimal(_idf, 4));
    
    show_debug_message("\nDOCUMENTS CONTAINING '" + _term + "':");
    var _did = ds_map_find_first(_docs);
    var _count = 0;
    while (!is_undefined(_did) && _count < 10) {
        var _tf = ds_map_find_value(_docs, _did);
        var _doc = ds_map_find_value(_ls.documents, _did);
        show_debug_message("  [" + string(_did) + "] TF: " + string(_tf) + ", Word Count: " + string(_doc.word_count));
        _did = ds_map_find_next(_docs, _did);
        _count++;
    }
    
    if (ds_map_size(_docs) > 10) {
        show_debug_message("  ... and " + string(ds_map_size(_docs) - 10) + " more documents");
    }
}

function gmls_analyze_query(_query) {
    var _processed = _gmls_process_text(_query);
    var _stop_words_removed = [];
    var _raw_words = string_split(_query, " ");
    for (var i = 0; i < array_length(_raw_words); i++) {
        if (_gmls_is_stop_word(_raw_words[i])) {
            array_push(_stop_words_removed, _raw_words[i]);
        }
    }
    
    var _output = "\nQUERY ANALYSIS\n";
    _output += "=========================================\n";
    _output += "Original: \"" + _query + "\"\n";
    _output += "Normalized Terms: [" + string_join(_processed, ", ") + "]\n";
    if (array_length(_stop_words_removed) > 0) {
        _output += "Stop Words Removed: " + string_join(_stop_words_removed, ", ") + "\n";
    }
    if (array_length(_processed) == 0) {
        _output += "WARNING: Query has no searchable terms!\n";
    }
    show_debug_message(_output);
    
    return {
        original: _query,
        terms: _processed,
        stop_words_removed: _stop_words_removed
    };
}

function gmls_search_with_logging(_query, _max_results = -1) {
    var _start = current_time;
    var _results = gmls_search(_query, _max_results);
    var _duration = current_time - _start;
    
    if (_duration > global.gmls.debug.slow_query_threshold) {
        show_debug_message("  Slow query (" + string(_duration) + "ms): \"" + _query + "\"");
    }
    
    array_push(global.gmls.debug.query_history, {
        query: _query,
        duration: _duration,
        timestamp: current_time,
        results: array_length(_results)
    });
    
    if (array_length(global.gmls.debug.query_history) > 100) {
        array_delete(global.gmls.debug.query_history, 0, 1);
    }
    
    return _results;
}

function gmls_get_query_history() {
    return global.gmls.debug.query_history;
}

function gmls_clear_query_history() {
    if (global.gmls != undefined && global.gmls.debug != undefined) {
        global.gmls.debug.query_history = [];
        show_debug_message("Query history cleared");
    }
}