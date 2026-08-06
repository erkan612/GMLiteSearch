

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
    var _detail_level = variable_struct_get(_options, "detail_level");
    
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
    
    if (_detail_level != "minimal") {
        var _term_list = [];
        var _term = ds_map_find_first(_ls.word_stats);
        while (!is_undefined(_term)) {
            var _stats = ds_map_find_value(_ls.word_stats, _term);
            var _term_entry = {
                term: _term,
                doc_freq: _stats.document_frequency,
                total_freq: _stats.total_frequency
            };
            if (_detail_level == "verbose") {
                _term_entry.avg_freq_per_doc = _stats.document_frequency > 0 ? 
                    (_stats.total_frequency / _stats.document_frequency) : 0;
            }
            array_push(_term_list, _term_entry);
            _term = ds_map_find_next(_ls.word_stats, _term);
        }
        
        array_sort(_term_list, function(a, b) { return sign(b.doc_freq - a.doc_freq); });
        
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
            var _preview_length = (_detail_level == "verbose") ? string_length(_doc.text) : 50;
            array_push(_inspection.sample_documents, {
                id: _doc_id,
                word_count: _doc.word_count,
                text_preview: string_copy(_doc.text, 1, _preview_length) + ((_preview_length < string_length(_doc.text)) ? "..." : ""),
                has_metadata: !is_undefined(_doc.metadata)
            });
            _doc_id = ds_map_find_next(_ls.documents, _doc_id);
            _sampled++;
        }
    }
    
    _inspection.health_checks = _gmls_run_health_checks();
    
    var _output = "";
    _output += "\n";
    _output += "┌─────────────────────────────────────────┐\n";
    _output += "│         INDEX INSPECTION REPORT         │\n";
    _output += "└─────────────────────────────────────────┘\n\n";
    _output += "Detail level: " + _detail_level + "\n\n";
    
    _output += "STATISTICS:\n";
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
    var _test_queries = [];
    var _query_source = "";
    
    if (variable_struct_exists(_ls, "query_log") && ds_list_size(_ls.query_log) > 0) {
        var _seen = ds_map_create();
        var _count = 0;
        var _log_size = ds_list_size(_ls.query_log);
        for (var i = _log_size - 1; i >= 0 && _count < 10; i--) {
            var _entry = ds_list_find_value(_ls.query_log, i);
            var _q = _entry.query;
            if (!ds_map_exists(_seen, _q)) {
                ds_map_add(_seen, _q, true);
                array_push(_test_queries, _q);
                _count++;
            }
        }
        ds_map_destroy(_seen);
        _query_source = "logged queries (" + string(_log_size) + " total logged, " + string(array_length(_test_queries)) + " unique used)";
    }
    
    if (array_length(_test_queries) == 0 && ds_map_size(_ls.inverted_index) > 0) {
        var _term = ds_map_find_first(_ls.inverted_index);
        var _count = 0;
        while (!is_undefined(_term) && _count < 10) {
            array_push(_test_queries, _term);
            _term = ds_map_find_next(_ls.inverted_index, _term);
            _count++;
        }
        _query_source = "indexed terms (no logged queries available)";
    }
    
    if (array_length(_test_queries) == 0) {
        _test_queries = ["game", "search", "test", "engine", "performance"];
        _query_source = "generic placeholder queries (no logged queries or index terms available)";
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
    show_debug_message("Query source: " + _query_source);
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
        var _norm_word = _gmls_normalize_word(_raw_words[i]);
        if (_gmls_is_stop_word(_norm_word)) {
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
    var _ls = global.gmls;
    
    if (!_ls.debug.enabled) {
        return gmls_search(_query, _max_results);
    }
    
    var _start = current_time;
    var _results = gmls_search(_query, _max_results);
    var _duration = current_time - _start;
    
    var _log_level = _ls.debug.log_level;
    var _should_warn = (_log_level == "warn" || _log_level == "info" || _log_level == "debug");
    
    if (_should_warn && _duration > _ls.debug.slow_query_threshold) {
        show_debug_message("  Slow query (" + string(_duration) + "ms): \"" + _query + "\"");
    }
    
    if (_log_level == "debug") {
        show_debug_message("  Query logged: \"" + _query + "\" (" + string(_duration) + "ms, " + string(array_length(_results)) + " results)");
    }
    
    gmls_log_query(_query, array_length(_results), -1, _duration);
    
    return _results;
}

function gmls_get_query_history() {
    var _ls = global.gmls;
    var _history = [];
    var _size = ds_list_size(_ls.query_log);
    for (var i = 0; i < _size; i++) {
        array_push(_history, ds_list_find_value(_ls.query_log, i));
    }
    return _history;
}

function gmls_clear_query_history() {
    var _ls = global.gmls;
    ds_list_clear(_ls.query_log);
    ds_map_clear(_ls.popular_queries);
}

function gmls_explain_fuzzy_score(_query, _doc_id, _threshold = 0.6, _verbose = true) {
    var _ls = global.gmls;
    
    var _explanation = {
        query: _query,
        document_id: _doc_id,
        threshold: _threshold,
        total_score: 0,
        term_contributions: []
    };
    
    if (!ds_map_exists(_ls.documents, _doc_id)) {
        return "Document " + string(_doc_id) + " not found";
    }
    
    var _terms = _gmls_process_text(_query);
    var _total_score = 0;
    
    var _doc_words = ds_map_create();
    var _word = ds_map_find_first(_ls.inverted_index);
    while (!is_undefined(_word)) {
        var _docs = ds_map_find_value(_ls.inverted_index, _word);
        if (ds_map_exists(_docs, _doc_id)) {
            ds_map_add(_doc_words, _word, ds_map_find_value(_docs, _doc_id));
        }
        _word = ds_map_find_next(_ls.inverted_index, _word);
    }
    
    for (var i = 0; i < array_length(_terms); i++) {
        var _term = _terms[i];
        var _term_detail = {
            term: _term,
            matched_words: [],
            near_misses: [],
            contribution: 0
        };
        
        var _dword = ds_map_find_first(_doc_words);
        while (!is_undefined(_dword)) {
            var _sim = _gmls_similarity(_dword, _term);
            var _tf = ds_map_find_value(_doc_words, _dword);
            
            if (_sim >= _threshold) {
                var _contrib = _tf * _sim;
                array_push(_term_detail.matched_words, {
                    word: _dword,
                    similarity: _sim,
                    term_frequency: _tf,
                    contribution: _contrib
                });
                _term_detail.contribution += _contrib;
                _total_score += _contrib;
            } else if (_sim >= _threshold / 2) {
                array_push(_term_detail.near_misses, { word: _dword, similarity: _sim });
            }
            _dword = ds_map_find_next(_doc_words, _dword);
        }
        
        array_push(_explanation.term_contributions, _term_detail);
    }
    
    ds_map_destroy(_doc_words);
    _explanation.total_score = _total_score;
    
    if (_verbose) {
        var _output = "\n========================================\n";
        _output += "FUZZY SEARCH EXPLANATION: " + _query + "\n";
        _output += "========================================\n";
        _output += "Document: " + string(_doc_id) + "\n";
        _output += "Threshold: " + string(_threshold) + "\n";
        _output += "Total Score: " + _gmls_format_decimal(_total_score, 4) + "\n";
        _output += "----------------------------------------\n";
        
        for (var i = 0; i < array_length(_explanation.term_contributions); i++) {
            var _t = _explanation.term_contributions[i];
            _output += "'" + _t.term + "':\n";
            
            if (array_length(_t.matched_words) == 0) {
                _output += "  no matches above threshold\n";
            }
            for (var j = 0; j < array_length(_t.matched_words); j++) {
                var _m = _t.matched_words[j];
                _output += "  MATCHED '" + _m.word + "' (similarity: " + _gmls_format_decimal(_m.similarity, 3) + 
                            ", tf: " + string(_m.term_frequency) + ") -> +" + _gmls_format_decimal(_m.contribution, 4) + "\n";
            }
            for (var j = 0; j < array_length(_t.near_misses); j++) {
                var _n = _t.near_misses[j];
                _output += "  near miss '" + _n.word + "' (similarity: " + _gmls_format_decimal(_n.similarity, 3) + 
                            ", below threshold of " + string(_threshold) + ")\n";
            }
        }
        
        _output += "========================================\n";
        show_debug_message(_output);
    }
    
    return _explanation;
}

function gmls_explain_facet_match(_doc_id, _verbose = true) {
    var _ls = global.gmls;
    
    if (!ds_map_exists(_ls.documents, _doc_id)) {
        return "Document " + string(_doc_id) + " not found";
    }
    
    var _explanation = {
        document_id: _doc_id,
        operator: _ls.filter_operator,
        overall_match: true,
        facet_results: [],
        date_results: [],
        notes: []
    };
    
    if (is_undefined(_ls.active_filters) || ds_map_size(_ls.active_filters) == 0) {
        _explanation.notes = ["No active filters - every document passes by default"];
        if (_verbose) show_debug_message("Document " + string(_doc_id) + ": no active filters, passes by default");
        return _explanation;
    }
    
    var _regular_pass_count = 0;
    var _regular_total_count = 0;
    var _facet = ds_map_find_first(_ls.active_filters);
    while (!is_undefined(_facet)) {
        if (string_pos("date|", _facet) != 1) {
            _regular_total_count++;
            var _filter_values = ds_map_find_value(_ls.active_filters, _facet);
            var _matched_values = [];
            
            for (var i = 0; i < ds_list_size(_filter_values); i++) {
                var _value = ds_list_find_value(_filter_values, i);
                var _docs_for_value = _gmls_get_documents_by_facet(_facet, _value);
                for (var j = 0; j < array_length(_docs_for_value); j++) {
                    if (_docs_for_value[j] == _doc_id) {
                        array_push(_matched_values, _value);
                    }
                }
            }
            
            show_debug_message("DEBUG: facet=" + _facet + " matched_values array_length=" + string(array_length(_matched_values)) + " contents=" + string(_matched_values));
            
            var _facet_passed = array_length(_matched_values) > 0;
            if (_facet_passed) _regular_pass_count++;
            
            array_push(_explanation.facet_results, {
                facet_name: _facet,
                requested_values: _filter_values,
                matched_values: _matched_values,
                passed: _facet_passed
            });
        }
        _facet = ds_map_find_next(_ls.active_filters, _facet);
    }
    
    var _facet2 = ds_map_find_first(_ls.active_filters);
    while (!is_undefined(_facet2)) {
        if (string_pos("date|", _facet2) == 1) {
            var _facet_name = string_copy(_facet2, 6, string_length(_facet2) - 5);
            var _passed = false;
            var _doc_date = undefined;
            
            if (variable_struct_exists(_ls, "date_facets") && ds_map_exists(_ls.date_facets, _facet_name)) {
                var _date_map = ds_map_find_value(_ls.date_facets, _facet_name);
                if (ds_map_exists(_date_map, _doc_id)) {
                    _doc_date = ds_map_find_value(_date_map, _doc_id);
                    var _filter_values = ds_map_find_value(_ls.active_filters, _facet2);
                    for (var i = 0; i < ds_list_size(_filter_values) && !_passed; i++) {
                        var _range_str = ds_list_find_value(_filter_values, i);
                        var _parts = string_split(_range_str, "|");
                        if (array_length(_parts) == 2) {
                            var _start_date = real(_parts[0]);
                            var _end_date = real(_parts[1]);
                            if (_doc_date >= _start_date && _doc_date < _end_date) _passed = true;
                        }
                    }
                }
            }
            
            array_push(_explanation.date_results, {
                facet_name: _facet_name,
                document_date: _doc_date,
                passed: _passed
            });
        }
        _facet2 = ds_map_find_next(_ls.active_filters, _facet2);
    }
    
    var _regular_match;
    if (_explanation.operator == "AND") {
        _regular_match = (_regular_total_count == 0) || (_regular_pass_count == _regular_total_count);
    } else {
        _regular_match = (_regular_total_count == 0) || (_regular_pass_count > 0);
    }
    
    var _date_match = true;
    for (var i = 0; i < array_length(_explanation.date_results); i++) {
        if (!_explanation.date_results[i].passed) _date_match = false;
    }
    
    _explanation.overall_match = _regular_match && _date_match;
    
    if (array_length(_explanation.date_results) > 0 && _explanation.operator == "OR") {
        array_push(_explanation.notes, "Note: date filters always require AND, even though filter_operator is set to OR. This is an intentional asymmetry in how facet filtering works, not a bug in this explanation.");
    }
    
    if (_verbose) {
        var _output = "\n========================================\n";
        _output += "FACET MATCH EXPLANATION: " + string(_doc_id) + "\n";
        _output += "========================================\n";
        _output += "Operator: " + _explanation.operator + "\n";
        _output += "Overall match: " + (_explanation.overall_match ? "PASS" : "FAIL") + "\n";
        _output += "----------------------------------------\n";
        
        for (var i = 0; i < array_length(_explanation.facet_results); i++) {
            var _f = _explanation.facet_results[i];
            _output += "'" + _f.facet_name + "': " + (_f.passed ? "PASS" : "FAIL");
            if (_f.passed) {
                _output += " (matched: " + string_join_ext(", ", _f.matched_values) + ")";
            }
            _output += "\n";
        }
        
        for (var i = 0; i < array_length(_explanation.date_results); i++) {
            var _d = _explanation.date_results[i];
            _output += "date '" + _d.facet_name + "': " + (_d.passed ? "PASS" : "FAIL");
            if (!is_undefined(_d.document_date)) {
                _output += " (document date: " + string(_d.document_date) + ")";
            } else {
                _output += " (no date indexed for this document/facet)";
            }
            _output += "\n";
        }
        
        for (var i = 0; i < array_length(_explanation.notes); i++) {
            _output += "\n" + _explanation.notes[i] + "\n";
        }
        
        _output += "========================================\n";
        show_debug_message(_output);
    }
    
    return _explanation;
}

function gmls_explain_ltr_score(_query, _doc_id, _verbose = true) {
    var _ls = global.gmls;
    
    if (!ds_map_exists(_ls.documents, _doc_id)) {
        return "Document " + string(_doc_id) + " not found";
    }
    
    var _explanation = {
        query: _query,
        document_id: _doc_id,
        model: _ls.ltr_model,
        feature_values: {},
        feature_contributions: [],
        total_score: 0,
        notes: []
    };
    
    var _base_results = gmls_search(_query, -1);
    var _search_result = undefined;
    for (var i = 0; i < array_length(_base_results); i++) {
        if (_base_results[i].id == _doc_id) {
            _search_result = _base_results[i];
            break;
        }
    }
    
    if (is_undefined(_search_result)) {
        _explanation.notes = ["This document did not match the query in plain BM25 search, so it has no bm25_score to build LTR features from. LTR scoring in GMLiteSearch always starts from a real BM25 match, a document invisible to gmls_search is invisible to gmls_search_ltr too."];
        if (_verbose) show_debug_message("Document " + string(_doc_id) + " has no BM25 match for '" + _query + "' - cannot compute LTR features.");
        return _explanation;
    }
    
    var _features = _gmls_extract_features(_doc_id, _query, _search_result);
    _explanation.feature_values = _features;
    
    if (_ls.ltr_model == "lambdamart") {
        var _ensemble = variable_struct_exists(_ls, "ltr_lambdamart_ensemble") ? _ls.ltr_lambdamart_ensemble : undefined;
        if (is_undefined(_ensemble)) {
            _explanation.notes = ["ltr_model is 'lambdamart' but no ensemble has been trained/loaded yet, falling back to linear scoring, same as the live search dispatcher does in this situation."];
            _explanation.model = "linear (lambdamart fallback)";
            
            var _total_fb = 0;
            var _feature_name_fb = ds_map_find_first(_ls.ltr_features);
            while (!is_undefined(_feature_name_fb)) {
                var _weight_fb = ds_map_find_value(_ls.ltr_features, _feature_name_fb);
                var _value_fb = variable_struct_exists(_features, _feature_name_fb) ? _features[$ _feature_name_fb] : 0;
                var _contribution_fb = _weight_fb * _value_fb;
                _total_fb += _contribution_fb;
                array_push(_explanation.feature_contributions, {
                    feature: _feature_name_fb,
                    weight: _weight_fb,
                    value: _value_fb,
                    contribution: _contribution_fb
                });
                _feature_name_fb = ds_map_find_next(_ls.ltr_features, _feature_name_fb);
            }
            _explanation.total_score = _total_fb;
        } else {
            _explanation.total_score = _gmls_ensemble_predict_raw(_ensemble, _features);
            _explanation.notes = ["LambdaMART scores come from summing predictions across " + string(array_length(_ensemble.trees)) + " trees, individual feature contributions (as shown for linear/ranknet below) don't apply the same way, since trees can combine features nonlinearly. The feature_values above are what fed into the ensemble, but there's no single per-feature 'contribution' number to report."];
        }
    } else {
        var _total = 0;
        var _feature_name = ds_map_find_first(_ls.ltr_features);
        while (!is_undefined(_feature_name)) {
            var _weight = ds_map_find_value(_ls.ltr_features, _feature_name);
            var _value = variable_struct_exists(_features, _feature_name) ? _features[$ _feature_name] : 0;
            var _contribution = _weight * _value;
            _total += _contribution;
            array_push(_explanation.feature_contributions, {
                feature: _feature_name,
                weight: _weight,
                value: _value,
                contribution: _contribution
            });
            _feature_name = ds_map_find_next(_ls.ltr_features, _feature_name);
        }
        _explanation.total_score = _total;
    }
    
    if (_verbose) {
        var _output = "\n========================================\n";
        _output += "LTR SCORE EXPLANATION: " + _query + "\n";
        _output += "========================================\n";
        _output += "Document: " + string(_doc_id) + "\n";
        _output += "Active model: " + _explanation.model + "\n";
        _output += "BM25 base score: " + _gmls_format_decimal(_search_result.score, 4) + "\n";
        _output += "----------------------------------------\n";
        
        if (array_length(_explanation.feature_contributions) > 0) {
            for (var i = 0; i < array_length(_explanation.feature_contributions); i++) {
                var _c = _explanation.feature_contributions[i];
                _output += _c.feature + ": weight(" + _gmls_format_decimal(_c.weight, 3) + ") x value(" + 
                            _gmls_format_decimal(_c.value, 3) + ") = " + _gmls_format_decimal(_c.contribution, 4) + "\n";
            }
        } else {
            var _fname = ds_map_find_first(_ls.ltr_features);
            while (!is_undefined(_fname)) {
                var _fval = variable_struct_exists(_features, _fname) ? _features[$ _fname] : 0;
                _output += _fname + ": " + _gmls_format_decimal(_fval, 3) + " (raw feature value, no single-weight contribution under this model)\n";
                _fname = ds_map_find_next(_ls.ltr_features, _fname);
            }
        }
        
        _output += "----------------------------------------\n";
        _output += "Total LTR score: " + _gmls_format_decimal(_explanation.total_score, 4) + "\n";
        
        for (var i = 0; i < array_length(_explanation.notes); i++) {
            _output += "\n" + _explanation.notes[i] + "\n";
        }
        
        _output += "========================================\n";
        show_debug_message(_output);
    }
    
    return _explanation;
}