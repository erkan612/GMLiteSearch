

// LEARNING TO RANK
function gmls_init_ltr() {
    var _ls = global.gmls;
    
    if (!variable_struct_exists(_ls, "ltr_features")) {
        _ls.ltr_features = ds_map_create();
        // Default features with weights
        ds_map_add(_ls.ltr_features, "bm25_score", 1.0);
        ds_map_add(_ls.ltr_features, "term_frequency", 0.8);
        ds_map_add(_ls.ltr_features, "doc_length_norm", 0.3);
        ds_map_add(_ls.ltr_features, "title_match", 1.2);
        ds_map_add(_ls.ltr_features, "term_coverage", 0.7);
        ds_map_add(_ls.ltr_features, "freshness", 0.4);
        ds_map_add(_ls.ltr_features, "popularity", 0.6);
        //show_debug_message("LTR initialized with " + string(ds_map_size(_ls.ltr_features)) + " features");
    }
    
    if (!variable_struct_exists(_ls, "ltr_training_data")) {
        _ls.ltr_training_data = ds_list_create();
    }
    
    if (!variable_struct_exists(_ls, "ltr_model")) {
        _ls.ltr_model = "linear";
    }
    
    if (!variable_struct_exists(_ls, "ltr_enabled")) {
        _ls.ltr_enabled = false;
    }
    
    if (!variable_struct_exists(_ls, "ltr_clicks")) {
        _ls.ltr_clicks = ds_map_create();
    }
    
    if (!variable_struct_exists(_ls, "ltr_impressions")) {
        _ls.ltr_impressions = ds_map_create();
    }
    
    if (!variable_struct_exists(_ls, "ltr_feature_extractors")) {
        _ls.ltr_feature_extractors = ds_map_create();
    }
}

function gmls_enable_ltr(_enabled) {
    global.gmls.ltr_enabled = _enabled;
}

function gmls_set_ltr_model(_model) {
    if (_model == "linear" || _model == "ranknet" || _model == "lambdamart") {
        global.gmls.ltr_model = _model;
        return true;
    }
    show_debug_message("GMLiteSearch: unknown LTR model '" + string(_model) + "' — model unchanged.");
    return false;
}

function gmls_set_feature_weight(_feature_name, _weight) {
    var _ls = global.gmls;
    if (variable_struct_exists(_ls, "ltr_features")) {
        if (ds_map_exists(_ls.ltr_features, _feature_name)) {
            ds_map_set(_ls.ltr_features, _feature_name, _weight);
        } else {
            ds_map_add(_ls.ltr_features, _feature_name, _weight);
        }
    }
}

function gmls_register_feature_extractor(_feature_name, _script) {
    var _ls = global.gmls;
    if (variable_struct_exists(_ls, "ltr_feature_extractors")) {
        ds_map_add(_ls.ltr_feature_extractors, _feature_name, _script);
    }
    if (variable_struct_exists(_ls, "ltr_features") && !ds_map_exists(_ls.ltr_features, _feature_name)) {
        ds_map_add(_ls.ltr_features, _feature_name, 0.5);
    }
}

function _gmls_extract_features(_doc_id, _query, _search_result) {
    var _ls = global.gmls;
    var _features = {};
    var _doc = ds_map_find_value(_ls.documents, _doc_id);
    
    if (is_undefined(_doc)) {
        return _features;
    }
    
    _features[$ "bm25_score"] = _search_result.score;
    
    // term frequency in document
    var _terms = _gmls_process_text(_query);
    var _doc_words = _gmls_process_text(_doc.text);
    var _term_freq = 0;
    for (var i = 0; i < array_length(_terms); i++) {
        for (var j = 0; j < array_length(_doc_words); j++) {
            if (_terms[i] == _doc_words[j]) _term_freq++;
        }
    }
    _features[$ "term_frequency"] = _term_freq / max(1, array_length(_doc_words));
    
    // document length normalization
    _features[$ "doc_length_norm"] = min(1.0, array_length(_doc_words) / 500);
    
    // title match
    var _title_match = 0;
    if (!is_undefined(_doc.metadata) && variable_struct_exists(_doc.metadata, "title")) {
        var _title = string_lower(_doc.metadata.title);
        for (var i = 0; i < array_length(_terms); i++) {
            if (string_pos(_terms[i], _title) > 0) _title_match++;
        }
    }
    _features[$ "title_match"] = _title_match / max(1, array_length(_terms));
    
    // term coverage
    var _unique_terms = ds_map_create();
    for (var i = 0; i < array_length(_doc_words); i++) {
        ds_map_add(_unique_terms, _doc_words[i], true);
    }
    var _covered = 0;
    for (var i = 0; i < array_length(_terms); i++) {
        if (ds_map_exists(_unique_terms, _terms[i])) _covered++;
    }
    ds_map_destroy(_unique_terms);
    _features[$ "term_coverage"] = _covered / max(1, array_length(_terms));
    
    // freshness
    var _freshness = 0.5;
    if (!is_undefined(_doc.metadata) && variable_struct_exists(_doc.metadata, "timestamp")) {
        var _age_days = (current_time - _doc.metadata.timestamp) / (1000 * 86400);
        _freshness = 1.0 / (1.0 + _age_days / 30);
    }
    _features[$ "freshness"] = _freshness;
    
    // popularity
    var _clicks = ds_map_exists(_ls.ltr_clicks, _doc_id) ? ds_map_find_value(_ls.ltr_clicks, _doc_id) : 0;
    var _impressions = ds_map_exists(_ls.ltr_impressions, _doc_id) ? ds_map_find_value(_ls.ltr_impressions, _doc_id) : 1;
    _features[$ "popularity"] = min(1.0, _clicks / max(1, _impressions) * 5);
    
    // custom feature extractors
    if (variable_struct_exists(_ls, "ltr_feature_extractors")) {
        var _extractor_name = ds_map_find_first(_ls.ltr_feature_extractors);
        while (!is_undefined(_extractor_name)) {
            var _extractor_fn = ds_map_find_value(_ls.ltr_feature_extractors, _extractor_name);
            
            try {
                var _custom_value = _extractor_fn(_doc_id, _query, _search_result);
                if (is_real(_custom_value)) {
                    _features[$ _extractor_name] = _custom_value;
                } else {
                    show_debug_message("GMLiteSearch: feature extractor '" + _extractor_name + "' returned non-numeric value, skipped.");
                }
            } catch (_err) {
                show_debug_message("GMLiteSearch: feature extractor '" + _extractor_name + "' threw an error, skipped.");
            }
            
            _extractor_name = ds_map_find_next(_ls.ltr_feature_extractors, _extractor_name);
        }
    }
    
    return _features;
}

function _gmls_linear_rank_score(_features) {
    var _ls = global.gmls;
    var _score = 0;
    var _has_weight = false;
    
    var _feature = ds_map_find_first(_ls.ltr_features);
    while (!is_undefined(_feature)) {
        var _weight = ds_map_find_value(_ls.ltr_features, _feature);
        var _value = variable_struct_exists(_features, _feature) ? _features[$ _feature] : 0;
        _score += _weight * _value;
        _has_weight = true;
        _feature = ds_map_find_next(_ls.ltr_features, _feature);
    }
    
    return _has_weight ? _score : 0.5;
}

function gmls_record_click(_doc_id) {
    var _ls = global.gmls;
    var _clicks = ds_map_exists(_ls.ltr_clicks, _doc_id) ? ds_map_find_value(_ls.ltr_clicks, _doc_id) : 0;
    ds_map_add(_ls.ltr_clicks, _doc_id, _clicks + 1);
}

function gmls_record_click_from_result(_result_index) {
    var _ls = global.gmls;
    if (_result_index >= 0 && _result_index < array_length(_ls.last_results)) {
        var _doc_id = _ls.last_results[_result_index].id;
        gmls_record_click(_doc_id);
    }
}

function gmls_add_training_example(_query, _doc_id, _relevance_score) {
    var _ls = global.gmls;
    var _features = {};
    
    var _search_result = { id: _doc_id, score: 0 };
    _features = _gmls_extract_features(_doc_id, _query, _search_result);
    
    var _example = {
        query: _query,
        doc_id: _doc_id,
        relevance: _relevance_score,
        features: _features,
        timestamp: current_time
    };
    
    ds_list_add(_ls.ltr_training_data, _example);
    
    // keep last 10000 examples
    while (ds_list_size(_ls.ltr_training_data) > 10000) {
        ds_list_delete(_ls.ltr_training_data, 0);
    }
    
    return true;
}

function gmls_train_linear_model(_iterations = 200, _learning_rate = 0.001) {
    var _ls = global.gmls;
    var _training_size = ds_list_size(_ls.ltr_training_data);
	
	var _log = [];
    array_push(_log, "Training linear model on " + string(_training_size) + " examples");
    
    if (_training_size < 10) {
        //show_debug_message("LTR: Need at least 10 training examples. Current: " + string(_training_size));
        return false;
    }
    
    //show_debug_message("LTR: Training linear model on " + string(_training_size) + " examples...");
    
    var _feature = ds_map_find_first(_ls.ltr_features);
    while (!is_undefined(_feature)) {
        if (ds_map_find_value(_ls.ltr_features, _feature) == 0) {
            ds_map_set(_ls.ltr_features, _feature, 0.5);
        }
        _feature = ds_map_find_next(_ls.ltr_features, _feature);
    }
    
    var _prev_loss = -1;
    
    for (var iter = 0; iter < _iterations; iter++) {
        var _total_loss = 0;
        
        for (var i = 0; i < _training_size; i++) {
            var _example = ds_list_find_value(_ls.ltr_training_data, i);
            var _predicted = _gmls_linear_rank_score(_example.features);
            var _error = _example.relevance - _predicted;
            _total_loss += _error * _error;
            
            var _feature_name = ds_map_find_first(_ls.ltr_features);
            while (!is_undefined(_feature_name)) {
                var _feature_value = variable_struct_exists(_example.features, _feature_name) ? 
                                     _example.features[$ _feature_name] : 0;
                var _current_weight = ds_map_find_value(_ls.ltr_features, _feature_name);
                var _gradient = -2 * _error * _feature_value;
                var _new_weight = _current_weight - _learning_rate * _gradient;
                ds_map_set(_ls.ltr_features, _feature_name, _new_weight);
                _feature_name = ds_map_find_next(_ls.ltr_features, _feature_name);
            }
        }
        
        var _avg_loss = _total_loss / _training_size;
        
        if (iter % 20 == 0 || iter == _iterations - 1) { // _verbose && (iter % 20 == 0 || iter == _iterations - 1) ? ?
            //show_debug_message("  Iteration " + string(iter) + " - Loss: " + string(_avg_loss));
			array_push(_log, "Iteration " + string(iter) + " - Loss: " + string(_avg_loss));
        }
        
        if (_prev_loss > 0 && abs(_prev_loss - _avg_loss) < 0.0001) {
            if (iter > 50) {
                //show_debug_message("  Converged at iteration " + string(iter));
				array_push(_log, "  Converged at iteration " + string(iter));
                break;
            }
        }
        _prev_loss = _avg_loss;
    }
    
    array_push(_log, "Training complete");
    return _log;
}

function gmls_evaluate_model(_test_ratio = 0.2) {
    var _ls = global.gmls;
    var _training_size = ds_list_size(_ls.ltr_training_data);
    
    if (_training_size < 10) {
        //show_debug_message("LTR: Not enough training data for evaluation. Need at least 10 examples.");
        return { error: true, message: "Not enough training data", test_samples: 0, mse: 0, mae: 0, rmse: 0 };
    }
    
    var _test_size = floor(_training_size * _test_ratio);
    if (_test_size < 1) _test_size = 1;
    
    var _train_size = _training_size - _test_size;
    
    var _mse = 0;
    var _mae = 0;
    
    for (var i = _train_size; i < _training_size; i++) {
        var _example = ds_list_find_value(_ls.ltr_training_data, i);
        var _predicted = _gmls_linear_rank_score(_example.features);
        var _error = _example.relevance - _predicted;
        _mse += _error * _error;
        _mae += abs(_error);
    }
    
    _mse /= _test_size;
    _mae /= _test_size;
    
    return {
        error: false,
        test_samples: _test_size,
        mse: _mse,
        mae: _mae,
        rmse: sqrt(_mse)
    };
}

function gmls_get_ltr_stats() {
    var _ls = global.gmls;
    var _weights = {};
    
    if (variable_struct_exists(_ls, "ltr_features")) {
        var _feature = ds_map_find_first(_ls.ltr_features);
        while (!is_undefined(_feature)) {
            _weights[$ _feature] = ds_map_find_value(_ls.ltr_features, _feature);
            _feature = ds_map_find_next(_ls.ltr_features, _feature);
        }
    }
    
    var _training_size = 0;
    if (variable_struct_exists(_ls, "ltr_training_data")) {
        _training_size = ds_list_size(_ls.ltr_training_data);
    }
    
    var _result = {
        enabled: _ls.ltr_enabled,
        model: _ls.ltr_model,
        training_examples: _training_size,
        feature_weights: _weights,
        total_clicks: ds_map_size(_ls.ltr_clicks),
        total_impressions: ds_map_size(_ls.ltr_impressions)
    };
    
    return _result;
}

function gmls_save_ltr_model() {
    var _ls = global.gmls;
    var _model = {
        features: {},
        model_type: _ls.ltr_model,
        version: 1,
        timestamp: current_time
    };
    
    var _feature = ds_map_find_first(_ls.ltr_features);
    while (!is_undefined(_feature)) {
        _model.features[$ _feature] = ds_map_find_value(_ls.ltr_features, _feature);
        _feature = ds_map_find_next(_ls.ltr_features, _feature);
    }
    
    return json_stringify(_model);
}

function gmls_load_ltr_model(_json) {
    var _ls = global.gmls;
    var _model = json_parse(_json);
    
    if (!is_struct(_model) || !variable_struct_exists(_model, "features")) {
        return false;
    }
    
    var _feature_names = variable_struct_get_names(_model.features);
    for (var i = 0; i < array_length(_feature_names); i++) {
        var _name = _feature_names[i];
        var _weight = _model.features[$ _name];
        if (ds_map_exists(_ls.ltr_features, _name)) {
            ds_map_set(_ls.ltr_features, _name, _weight);
        } else {
            ds_map_add(_ls.ltr_features, _name, _weight);
        }
    }
    
    if (variable_struct_exists(_model, "model_type")) {
        _ls.ltr_model = _model.model_type;
    }
    
    return true;
}

function _gmls_rank_score(_features) {
    var _ls = global.gmls;
    
    if (_ls.ltr_model == "lambdamart") {
        var _ensemble = gmls_get_ltr_ensemble();
        if (is_undefined(_ensemble)) {
            return _gmls_linear_rank_score(_features);
        }
        return _gmls_ensemble_predict_raw(_ensemble, _features);
    }
    
    return _gmls_linear_rank_score(_features);
}

function _gmls_build_training_pairs() {
    var _ls = global.gmls;
    var _training_size = ds_list_size(_ls.ltr_training_data);
    var _by_query = ds_map_create();
    
    for (var i = 0; i < _training_size; i++) {
        var _example = ds_list_find_value(_ls.ltr_training_data, i);
        var _q = _example.query;
        if (!ds_map_exists(_by_query, _q)) {
            ds_map_add(_by_query, _q, ds_list_create());
        }
        var _indices = ds_map_find_value(_by_query, _q);
        ds_list_add(_indices, i);
    }
    
    var _pairs = [];
    var _q = ds_map_find_first(_by_query);
    while (!is_undefined(_q)) {
        var _indices = ds_map_find_value(_by_query, _q);
        var _n = ds_list_size(_indices);
        for (var a = 0; a < _n; a++) {
            for (var b = a + 1; b < _n; b++) {
                var _idx_a = ds_list_find_value(_indices, a);
                var _idx_b = ds_list_find_value(_indices, b);
                var _ex_a = ds_list_find_value(_ls.ltr_training_data, _idx_a);
                var _ex_b = ds_list_find_value(_ls.ltr_training_data, _idx_b);
                
                if (_ex_a.relevance == _ex_b.relevance) continue; // no signal
                
                var _higher = (_ex_a.relevance > _ex_b.relevance) ? _ex_a : _ex_b;
                var _lower  = (_ex_a.relevance > _ex_b.relevance) ? _ex_b : _ex_a;
                array_push(_pairs, { higher: _higher, lower: _lower });
            }
        }
        ds_list_destroy(_indices);
        _q = ds_map_find_next(_by_query, _q);
    }
    ds_map_destroy(_by_query);
    return _pairs;
}

function gmls_train_ranknet_model(_iterations = 200, _learning_rate = 0.001) {
    var _ls = global.gmls;
    var _log = [];
    
    var _pairs = _gmls_build_training_pairs();
    array_push(_log, "RankNet: built " + string(array_length(_pairs)) + " training pairs");
    
    if (array_length(_pairs) < 1) {
        array_push(_log, "RankNet: need at least 1 valid pair (same query, differing relevance). Found 0.");
        return _log;
    }
    
    var _feature = ds_map_find_first(_ls.ltr_features);
    while (!is_undefined(_feature)) {
        if (ds_map_find_value(_ls.ltr_features, _feature) == 0) {
            ds_map_set(_ls.ltr_features, _feature, 0.5);
        }
        _feature = ds_map_find_next(_ls.ltr_features, _feature);
    }
    
    var _prev_loss = -1;
    
    for (var iter = 0; iter < _iterations; iter++) {
        var _total_loss = 0;
        
        for (var p = 0; p < array_length(_pairs); p++) {
            var _pair = _pairs[p];
            var _score_higher = _gmls_linear_rank_score(_pair.higher.features);
            var _score_lower  = _gmls_linear_rank_score(_pair.lower.features);
            
            var _diff = _score_higher - _score_lower;
            var _prob = 1 / (1 + exp(-_diff));
            var _target = 1;
            
            // cross-entropy loss
            var _p_clamped = clamp(_prob, 0.0001, 0.9999);
            _total_loss += -( _target * ln(_p_clamped) + (1 - _target) * ln(1 - _p_clamped) );
            
            var _grad_shared = (_prob - _target); // dLoss/dDiff
            
            var _feature_name = ds_map_find_first(_ls.ltr_features);
            while (!is_undefined(_feature_name)) {
                var _fv_higher = variable_struct_exists(_pair.higher.features, _feature_name) ? 
                                 _pair.higher.features[$ _feature_name] : 0;
                var _fv_lower = variable_struct_exists(_pair.lower.features, _feature_name) ? 
                                _pair.lower.features[$ _feature_name] : 0;
                
                // d(diff)/d(weight) = fv_higher - fv_lower
                var _gradient = _grad_shared * (_fv_higher - _fv_lower);
                var _current_weight = ds_map_find_value(_ls.ltr_features, _feature_name);
                var _new_weight = _current_weight - _learning_rate * _gradient;
                ds_map_set(_ls.ltr_features, _feature_name, _new_weight);
                
                _feature_name = ds_map_find_next(_ls.ltr_features, _feature_name);
            }
        }
        
        var _avg_loss = _total_loss / array_length(_pairs);
        
        if (iter % 20 == 0 || iter == _iterations - 1) {
            array_push(_log, "Iteration " + string(iter) + " - Pairwise loss: " + string(_avg_loss));
        }
        
        if (_prev_loss > 0 && abs(_prev_loss - _avg_loss) < 0.0001) {
            if (iter > 50) {
                array_push(_log, "Converged at iteration " + string(iter));
                break;
            }
        }
        _prev_loss = _avg_loss;
    }
    
    array_push(_log, "RankNet training complete");
    return _log;
}

function gmls_evaluate_ranknet_model() {
    var _ls = global.gmls;
    var _pairs = _gmls_build_training_pairs();
    
    if (array_length(_pairs) < 1) {
        return { error: true, message: "No valid pairs to evaluate", pairs_tested: 0, accuracy: 0 };
    }
    
    var _correct = 0;
    for (var p = 0; p < array_length(_pairs); p++) {
        var _pair = _pairs[p];
        var _score_higher = _gmls_linear_rank_score(_pair.higher.features);
        var _score_lower  = _gmls_linear_rank_score(_pair.lower.features);
        if (_score_higher > _score_lower) _correct++;
    }
    
    return {
        error: false,
        pairs_tested: array_length(_pairs),
        correct: _correct,
        accuracy: _correct / array_length(_pairs)
    };
}