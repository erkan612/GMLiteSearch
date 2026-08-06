

// LAMBDAMART

// REGRESSION TREE TRAINER
//	leaf: { is_leaf: true, value: real }
//	split: { is_leaf: false, feature: string, threshold: real, left: node, right: node }
function _gmls_tree_mean_target(_samples, _indices) {
    var _n = array_length(_indices);
    if (_n == 0) return 0;
    var _sum = 0;
    for (var i = 0; i < _n; i++) {
        _sum += _samples[_indices[i]].target;
    }
    return _sum / _n;
}

function _gmls_tree_sse(_samples, _indices, _mean) {
    var _sse = 0;
    for (var i = 0; i < array_length(_indices); i++) {
        var _diff = _samples[_indices[i]].target - _mean;
        _sse += _diff * _diff;
    }
    return _sse;
}

function _gmls_tree_find_best_split(_samples, _indices, _feature_names, _min_samples_leaf) {
    var _n = array_length(_indices);
    if (_n < _min_samples_leaf * 2) {
        return { found: false };
    }
    
    var _parent_mean = _gmls_tree_mean_target(_samples, _indices);
    var _parent_sse = _gmls_tree_sse(_samples, _indices, _parent_mean);
    
    var _best_gain = 0;
    var _best_feature = "";
    var _best_threshold = 0;
    var _best_left = [];
    var _best_right = [];
    var _found = false;
    
    for (var f = 0; f < array_length(_feature_names); f++) {
        var _fname = _feature_names[f];
        
        var _values = [];
        for (var i = 0; i < _n; i++) {
            var _feat = _samples[_indices[i]].features;
            var _v = variable_struct_exists(_feat, _fname) ? _feat[$ _fname] : 0;
            array_push(_values, _v);
        }
        array_sort(_values, true);
        
        for (var t = 0; t < array_length(_values) - 1; t++) {
            if (_values[t] == _values[t + 1]) continue; // skip non-distinct boundry
            var _threshold = (_values[t] + _values[t + 1]) / 2;
            
            var _left_idx = [];
            var _right_idx = [];
            for (var i = 0; i < _n; i++) {
                var _feat = _samples[_indices[i]].features;
                var _v = variable_struct_exists(_feat, _fname) ? _feat[$ _fname] : 0;
                if (_v <= _threshold) {
                    array_push(_left_idx, _indices[i]);
                } else {
                    array_push(_right_idx, _indices[i]);
                }
            }
            
            if (array_length(_left_idx) < _min_samples_leaf || array_length(_right_idx) < _min_samples_leaf) {
                continue;
            }
            
            var _left_mean = _gmls_tree_mean_target(_samples, _left_idx);
            var _right_mean = _gmls_tree_mean_target(_samples, _right_idx);
            var _left_sse = _gmls_tree_sse(_samples, _left_idx, _left_mean);
            var _right_sse = _gmls_tree_sse(_samples, _right_idx, _right_mean);
            
            var _gain = _parent_sse - (_left_sse + _right_sse);
            
            if (_gain > _best_gain) {
                _best_gain = _gain;
                _best_feature = _fname;
                _best_threshold = _threshold;
                _best_left = _left_idx;
                _best_right = _right_idx;
                _found = true;
            }
        }
    }
    
    if (!_found) return { found: false };
    
    return {
        found: true,
        feature: _best_feature,
        threshold: _best_threshold,
        left_indices: _best_left,
        right_indices: _best_right,
        gain: _best_gain
    };
}

function _gmls_tree_build(_samples, _indices, _feature_names, _max_depth, _min_samples_leaf, _depth) {
    var _mean = _gmls_tree_mean_target(_samples, _indices);
    
    if (_depth >= _max_depth || array_length(_indices) < _min_samples_leaf * 2) {
        return { is_leaf: true, value: _mean };
    }
    
    var _split = _gmls_tree_find_best_split(_samples, _indices, _feature_names, _min_samples_leaf);
    
    if (!_split.found) {
        return { is_leaf: true, value: _mean };
    }
    
    var _left_node = _gmls_tree_build(_samples, _split.left_indices, _feature_names, _max_depth, _min_samples_leaf, _depth + 1);
    var _right_node = _gmls_tree_build(_samples, _split.right_indices, _feature_names, _max_depth, _min_samples_leaf, _depth + 1);
    
    return {
        is_leaf: false,
        feature: _split.feature,
        threshold: _split.threshold,
        left: _left_node,
        right: _right_node
    };
}

function gmls_train_regression_tree(_samples, _feature_names, _max_depth = 3, _min_samples_leaf = 1) {
    var _n = array_length(_samples);
    if (_n == 0) return { is_leaf: true, value: 0 };
    
    var _all_indices = [];
    for (var i = 0; i < _n; i++) array_push(_all_indices, i);
    
    return _gmls_tree_build(_samples, _all_indices, _feature_names, _max_depth, _min_samples_leaf, 0);
}

function gmls_tree_predict(_tree, _features) {
    var _node = _tree;
    while (!_node.is_leaf) {
        var _v = variable_struct_exists(_features, _node.feature) ? _features[$ _node.feature] : 0;
        _node = (_v <= _node.threshold) ? _node.left : _node.right;
    }
    return _node.value;
}

// GRADIENT BOOSTING ENSEMBLE
function _gmls_ensemble_predict_raw(_ensemble, _features) {
    var _pred = _ensemble.initial_value;
    for (var i = 0; i < array_length(_ensemble.trees); i++) {
        _pred += _ensemble.learning_rate * gmls_tree_predict(_ensemble.trees[i], _features);
    }
    return _pred;
}

function gmls_train_tree_ensemble(_samples, _feature_names, _n_trees = 20, _learning_rate = 0.1, _max_depth = 3, _min_samples_leaf = 1) {
    var _n = array_length(_samples);
    var _log = [];
    
    if (_n == 0) {
        array_push(_log, "Ensemble training: no samples provided");
        return { ensemble: { initial_value: 0, trees: [], learning_rate: _learning_rate }, log: _log };
    }
    
    var _sum = 0;
    for (var i = 0; i < _n; i++) _sum += _samples[i].target;
    var _initial_value = _sum / _n;
    
    var _ensemble = { initial_value: _initial_value, trees: [], learning_rate: _learning_rate };
    
    array_push(_log, "Boosting: " + string(_n_trees) + " trees, lr=" + string(_learning_rate) + 
               ", initial_value=" + string(_initial_value));
    
    var _current_preds = array_create(_n, _initial_value);
    
    for (var _round = 0; _round < _n_trees; _round++) {
        var _residual_samples = [];
        for (var i = 0; i < _n; i++) {
            var _residual = _samples[i].target - _current_preds[i];
            array_push(_residual_samples, { features: _samples[i].features, target: _residual });
        }
        
        var _tree = gmls_train_regression_tree(_residual_samples, _feature_names, _max_depth, _min_samples_leaf);
        array_push(_ensemble.trees, _tree);
        
        var _mse = 0;
        for (var i = 0; i < _n; i++) {
            var _tree_out = gmls_tree_predict(_tree, _samples[i].features);
            _current_preds[i] += _learning_rate * _tree_out;
            var _err = _samples[i].target - _current_preds[i];
            _mse += _err * _err;
        }
        _mse /= _n;
        
        if (_round % 5 == 0 || _round == _n_trees - 1) {
            array_push(_log, "  Round " + string(_round) + " - MSE: " + string(_mse));
        }
    }
    
    array_push(_log, "Ensemble training complete: " + string(array_length(_ensemble.trees)) + " trees built");
    
    return { ensemble: _ensemble, log: _log };
}

function gmls_ensemble_predict(_ensemble, _features) {
    return _gmls_ensemble_predict_raw(_ensemble, _features);
}

// NDCG CALCULATOR
function _gmls_dcg(_relevances, _k = -1) {
    var _n = array_length(_relevances);
    var _limit = (_k < 0) ? _n : min(_k, _n);
    var _dcg = 0;
    for (var _i = 0; _i < _limit; _i++) {
        var _rel = _relevances[_i];
        var _gain = power(2, _rel) - 1;
        var _discount = log2(_i + 2); // rank is _i+1, discount = log2(rank+1) = log2(_i+2)
        _dcg += _gain / _discount;
    }
    return _dcg;
}

function _gmls_ideal_dcg(_relevances, _k = -1) {
    var _sorted = variable_clone(_relevances);
    array_sort(_sorted, false);
    return _gmls_dcg(_sorted, _k);
}

function gmls_ndcg(_relevances, _k = -1) {
    var _idcg = _gmls_ideal_dcg(_relevances, _k);
    if (_idcg == 0) return 0;
    var _dcg = _gmls_dcg(_relevances, _k);
    return _dcg / _idcg;
}

function _gmls_ndcg_swap_delta(_relevances, _pos_i, _pos_j, _k = -1) {
    var _idcg = _gmls_ideal_dcg(_relevances, _k);
    if (_idcg == 0) return 0;
    
    var _n = array_length(_relevances);
    var _limit = (_k < 0) ? _n : min(_k, _n);
    
    var _rel_i = _relevances[_pos_i];
    var _rel_j = _relevances[_pos_j];
    
    var _gain_i = power(2, _rel_i) - 1;
    var _gain_j = power(2, _rel_j) - 1;
    
    var _discount_i = log2(_pos_i + 2);
    var _discount_j = log2(_pos_j + 2);
    
    var _contrib_before = 0;
    var _contrib_after = 0;
    
    if (_pos_i < _limit) _contrib_before += _gain_i / _discount_i;
    if (_pos_j < _limit) _contrib_before += _gain_j / _discount_j;
    
    if (_pos_i < _limit) _contrib_after += _gain_j / _discount_i;
    if (_pos_j < _limit) _contrib_after += _gain_i / _discount_j;
    
    var _dcg_delta = _contrib_after - _contrib_before;
    return abs(_dcg_delta / _idcg);
}

// LAMBDA GRADIENT COMPUTATION
function _gmls_group_indices_by_query(_samples) {
    var _by_query = ds_map_create();
    for (var _i = 0; _i < array_length(_samples); _i++) {
        var _q = _samples[_i].query;
        if (!ds_map_exists(_by_query, _q)) {
            ds_map_add(_by_query, _q, []);
        }
        var _indices = ds_map_find_value(_by_query, _q);
        array_push(_indices, _i);
        ds_map_set(_by_query, _q, _indices);
    }
    return _by_query;
}

function gmls_compute_lambda_gradients(_samples, _current_scores) {
    var _n = array_length(_samples);
    var _lambdas = array_create(_n, 0);
    
    var _by_query = _gmls_group_indices_by_query(_samples);
    
    var _query_key = ds_map_find_first(_by_query);
    while (!is_undefined(_query_key)) {
        var _group_indices = ds_map_find_value(_by_query, _query_key);
        var _group_size = array_length(_group_indices);
        
        if (_group_size < 2) {
            _query_key = ds_map_find_next(_by_query, _query_key);
            continue;
        }
        
        var _group_with_scores = [];
        for (var _gi = 0; _gi < _group_size; _gi++) {
            var _sample_idx = _group_indices[_gi];
            array_push(_group_with_scores, {
                sample_index: _sample_idx,
                relevance: _samples[_sample_idx].target,
                score: _current_scores[_sample_idx]
            });
        }
        array_sort(_group_with_scores, function(_a, _b) {
            if (_a.score != _b.score) return _b.score - _a.score;
            return sign(_a.sample_index - _b.sample_index);
        });
        
        var _ranked_relevances = [];
        for (var _gi = 0; _gi < _group_size; _gi++) {
            array_push(_ranked_relevances, _group_with_scores[_gi].relevance);
        }
        
        for (var _pos_a = 0; _pos_a < _group_size; _pos_a++) {
            for (var _pos_b = _pos_a + 1; _pos_b < _group_size; _pos_b++) {
                var _rel_a = _ranked_relevances[_pos_a];
                var _rel_b = _ranked_relevances[_pos_b];
                
                if (_rel_a == _rel_b) continue; // no signal
                
                var _higher_pos = (_rel_a > _rel_b) ? _pos_a : _pos_b;
                var _lower_pos  = (_rel_a > _rel_b) ? _pos_b : _pos_a;
                
                var _higher_sample_idx = _group_with_scores[_higher_pos].sample_index;
                var _lower_sample_idx  = _group_with_scores[_lower_pos].sample_index;
                
                var _score_higher = _current_scores[_higher_sample_idx];
                var _score_lower  = _current_scores[_lower_sample_idx];
                
                var _score_diff = _score_higher - _score_lower;
                var _sigmoid_prob = 1 / (1 + exp(-_score_diff));
                
                var _ndcg_delta = _gmls_ndcg_swap_delta(_ranked_relevances, _higher_pos, _lower_pos);
                
                var _lambda_pair = _ndcg_delta * (1 - _sigmoid_prob);
                
                _lambdas[_higher_sample_idx] += _lambda_pair;
                _lambdas[_lower_sample_idx]  -= _lambda_pair;
            }
        }
        
        _query_key = ds_map_find_next(_by_query, _query_key);
    }
    
    ds_map_destroy(_by_query);
    return _lambdas;
}

// FULL TRAINING LOOP
function _gmls_lambdamart_avg_ndcg(_samples, _current_scores) {
    var _by_query = _gmls_group_indices_by_query(_samples);
    var _total_ndcg = 0;
    var _query_count = 0;
    
    var _query_key = ds_map_find_first(_by_query);
    while (!is_undefined(_query_key)) {
        var _group_indices = ds_map_find_value(_by_query, _query_key);
        var _group_size = array_length(_group_indices);
        
        if (_group_size >= 2) {
            var _group_with_scores = [];
            for (var _gi = 0; _gi < _group_size; _gi++) {
                var _sample_idx = _group_indices[_gi];
                array_push(_group_with_scores, {
                    relevance: _samples[_sample_idx].target,
                    score: _current_scores[_sample_idx]
                });
            }
            array_sort(_group_with_scores, function(_a, _b) {
                if (_a.score != _b.score) return sign(_b.score - _a.score);
                return 0;
            });
            
            var _ranked_relevances = [];
            for (var _gi = 0; _gi < _group_size; _gi++) {
                array_push(_ranked_relevances, _group_with_scores[_gi].relevance);
            }
            
            _total_ndcg += gmls_ndcg(_ranked_relevances);
            _query_count++;
        }
        
        _query_key = ds_map_find_next(_by_query, _query_key);
    }
    ds_map_destroy(_by_query);
    
    return (_query_count > 0) ? (_total_ndcg / _query_count) : 0;
}

function gmls_train_lambdamart_model(_samples, _feature_names, _n_trees = 20, _learning_rate = 0.1, _max_depth = 3, _min_samples_leaf = 1) {
    var _n = array_length(_samples);
    var _log = [];
    
    if (_n == 0) {
        array_push(_log, "LambdaMART training: no samples provided");
        return { ensemble: { initial_value: 0, trees: [], learning_rate: _learning_rate }, log: _log };
    }
    
    var _sum = 0;
    for (var _i = 0; _i < _n; _i++) _sum += _samples[_i].target;
    var _initial_value = _sum / _n;
    
    var _ensemble = { initial_value: _initial_value, trees: [], learning_rate: _learning_rate };
    
    array_push(_log, "LambdaMART: " + string(_n_trees) + " trees, lr=" + string(_learning_rate) + 
               ", initial_value=" + string(_initial_value));
    
    var _current_preds = array_create(_n, _initial_value);
    
    var _initial_ndcg = _gmls_lambdamart_avg_ndcg(_samples, _current_preds);
    array_push(_log, "  Initial avg NDCG: " + string(_initial_ndcg));
    
    for (var _round = 0; _round < _n_trees; _round++) {
        var _lambdas = gmls_compute_lambda_gradients(_samples, _current_preds);
        
        var _lambda_samples = [];
        for (var _i = 0; _i < _n; _i++) {
            array_push(_lambda_samples, { features: _samples[_i].features, target: _lambdas[_i] });
        }
        
        var _tree = gmls_train_regression_tree(_lambda_samples, _feature_names, _max_depth, _min_samples_leaf);
        array_push(_ensemble.trees, _tree);
        
        for (var _i = 0; _i < _n; _i++) {
            var _tree_out = gmls_tree_predict(_tree, _samples[_i].features);
            _current_preds[_i] += _learning_rate * _tree_out;
        }
        
        if (_round % 5 == 0 || _round == _n_trees - 1) {
            var _avg_ndcg = _gmls_lambdamart_avg_ndcg(_samples, _current_preds);
            array_push(_log, "  Round " + string(_round) + " - Avg NDCG: " + string(_avg_ndcg));
        }
    }
    
    array_push(_log, "LambdaMART training complete: " + string(array_length(_ensemble.trees)) + " trees built");
    
    return { ensemble: _ensemble, log: _log };
}

// DISPATCHER INTEGRATION + SAVE/LOAD

function gmls_set_ltr_ensemble(_ensemble) {
    global.gmls.ltr_lambdamart_ensemble = _ensemble;
}

function gmls_get_ltr_ensemble() {
    var _ls = global.gmls;
    if (!variable_struct_exists(_ls, "ltr_lambdamart_ensemble")) return undefined;
    return _ls.ltr_lambdamart_ensemble;
}

function gmls_save_lambdamart_model() {
    var _ls = global.gmls;
    if (!variable_struct_exists(_ls, "ltr_lambdamart_ensemble") || is_undefined(_ls.ltr_lambdamart_ensemble)) {
        return json_stringify({ error: "no ensemble trained yet" });
    }
    var _model = {
        model_type: "lambdamart",
        version: 1,
        timestamp: current_time,
        ensemble: _ls.ltr_lambdamart_ensemble
    };
    return json_stringify(_model);
}

function gmls_load_lambdamart_model(_json) {
    var _ls = global.gmls;
    var _model = json_parse(_json);
    
    if (!is_struct(_model) || !variable_struct_exists(_model, "ensemble")) {
        return false;
    }
    
    _ls.ltr_lambdamart_ensemble = _model.ensemble;
    return true;
}