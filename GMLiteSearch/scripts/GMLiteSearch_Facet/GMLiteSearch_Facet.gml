

//  FACETED SEARCH WITH AGGREGATIONS
function gmls_init_facets() {
    var _ls = global.gmls;
    
    if (!variable_struct_exists(_ls, "facet_index")) {
        _ls.facet_index = ds_map_create();
    }
    if (!variable_struct_exists(_ls, "facet_cache")) {
        _ls.facet_cache = ds_map_create();
    }
    if (!variable_struct_exists(_ls, "active_filters")) {
        _ls.active_filters = ds_map_create();
    }
    if (!variable_struct_exists(_ls, "filter_operator")) {
        _ls.filter_operator = "AND";
    }
	if (!variable_struct_exists(_ls, "date_facets")) {
	    _ls.date_facets = ds_map_create();
	}
}

function gmls_add_document_faceted(_id, _text, _facets, _metadata = undefined) {
    var _ls = global.gmls;
    
    if (is_undefined(_ls.facet_index)) gmls_init_facets();
    
    var _result = gmls_add_document_weighted(_id, _text, _metadata);
    if (!_result) return false;
    
    var _doc = ds_map_find_value(_ls.documents, _id);
    _doc.facets = _facets;
    
    var _facet_names = variable_struct_get_names(_facets);
    
    for (var i = 0; i < array_length(_facet_names); i++) {
        var _facet_name = _facet_names[i];
        var _facet_value = variable_struct_get(_facets, _facet_name);
        
        if (!ds_map_exists(_ls.facet_index, _facet_name)) {
            ds_map_add(_ls.facet_index, _facet_name, ds_map_create());
        }
        
        var _facet_map = ds_map_find_value(_ls.facet_index, _facet_name);
        
        if (is_array(_facet_value)) {
            for (var j = 0; j < array_length(_facet_value); j++) {
                _gmls_add_to_facet_map(_facet_map, _facet_value[j], _id);
            }
        } else {
            _gmls_add_to_facet_map(_facet_map, _facet_value, _id);
        }
    }
    
    return true;
}

function _gmls_add_to_facet_map(_facet_map, _value, _doc_id) {
    var _value_str = string(_value);
    
    if (!ds_map_exists(_facet_map, _value_str)) {
        ds_map_add(_facet_map, _value_str, ds_list_create());
    }
    
    var _doc_list = ds_map_find_value(_facet_map, _value_str);
    ds_list_add(_doc_list, _doc_id);
}

function gmls_add_facet_filter(_facet_name, _value) {
    var _ls = global.gmls;
    if (is_undefined(_ls.active_filters)) gmls_init_facets();
    
    _facet_name = string(_facet_name);
    var _value_str = string(_value);
    
    if (!ds_map_exists(_ls.active_filters, _facet_name)) {
        ds_map_add(_ls.active_filters, _facet_name, ds_list_create());
    }
    
    var _filter_list = ds_map_find_value(_ls.active_filters, _facet_name);
    
    for (var i = 0; i < ds_list_size(_filter_list); i++) {
        if (ds_list_find_value(_filter_list, i) == _value_str) {
            return false;
        }
    }
    
    ds_list_add(_filter_list, _value_str);
    _gmls_invalidate_facet_cache();
    return true;
}

function gmls_remove_facet_filter(_facet_name, _value) {
    var _ls = global.gmls;
    if (is_undefined(_ls.active_filters)) return false;
    
    _facet_name = string(_facet_name);
    var _value_str = string(_value);
    
    if (!ds_map_exists(_ls.active_filters, _facet_name)) return false;
    
    var _filter_list = ds_map_find_value(_ls.active_filters, _facet_name);
    
    for (var i = 0; i < ds_list_size(_filter_list); i++) {
        if (ds_list_find_value(_filter_list, i) == _value_str) {
            ds_list_delete(_filter_list, i);
            break;
        }
    }
    
    if (ds_list_size(_filter_list) == 0) {
        ds_list_destroy(_filter_list);
        ds_map_delete(_ls.active_filters, _facet_name);
    }
    
    _gmls_invalidate_facet_cache();
    return true;
}

function gmls_clear_facet_filters() {
    var _ls = global.gmls;
    if (is_undefined(_ls.active_filters)) return;
    
    var _facet = ds_map_find_first(_ls.active_filters);
    while (!is_undefined(_facet)) {
        var _list = ds_map_find_value(_ls.active_filters, _facet);
        if (ds_exists(_list, ds_type_list)) ds_list_destroy(_list);
        _facet = ds_map_find_next(_ls.active_filters, _facet);
    }
    ds_map_clear(_ls.active_filters);
    
    _gmls_invalidate_facet_cache();
}

function gmls_get_active_filters() {
    var _ls = global.gmls;
    var _result = {};
    
    if (is_undefined(_ls.active_filters)) return _result;
    
    var _facet = ds_map_find_first(_ls.active_filters);
    while (!is_undefined(_facet)) {
        var _list = ds_map_find_value(_ls.active_filters, _facet);
        var _values = [];
        for (var i = 0; i < ds_list_size(_list); i++) {
            array_push(_values, ds_list_find_value(_list, i));
        }
        _result[$ _facet] = _values;
        _facet = ds_map_find_next(_ls.active_filters, _facet);
    }
    
    return _result;
}

function gmls_add_date_facet(_doc_id, _facet_name, _datetime) {
    var _ls = global.gmls;
    if (!ds_map_exists(_ls.documents, _doc_id)) return false;
    
    if (!variable_struct_exists(_ls, "date_facets")) {
        _ls.date_facets = ds_map_create();
    }
    
    if (!ds_map_exists(_ls.date_facets, _facet_name)) {
        ds_map_add(_ls.date_facets, _facet_name, ds_map_create());
    }
    
    var _facet_map = ds_map_find_value(_ls.date_facets, _facet_name);
    ds_map_add(_facet_map, _doc_id, _datetime);
    
    gmls_add_range_facet(_doc_id, _facet_name, _datetime);
    
    return true;
}

function gmls_add_date_filter(_facet_name, _start, _end = undefined) {
    var _ls = global.gmls;
    if (is_undefined(_ls.active_filters)) gmls_init_facets();
    
    _facet_name = string(_facet_name);
    var _start_dt = _start;
    var _end_dt = _end;
    
    if (is_string(_start)) {
        var _range = _gmls_resolve_date_preset(_start);
        if (is_undefined(_range)) return false;
        _start_dt = _range.start_date;
        _end_dt = _range.end_date;
    }
    
    if (is_undefined(_end_dt)) {
        _end_dt = date_inc_day(_start_dt, 1);
    }
    
    var _filter_key = "date|" + _facet_name;
    if (!ds_map_exists(_ls.active_filters, _filter_key)) {
        ds_map_add(_ls.active_filters, _filter_key, ds_list_create());
    }
    
    var _filter_list = ds_map_find_value(_ls.active_filters, _filter_key);
    var _filter_value = string(_start_dt) + "|" + string(_end_dt);
    
    for (var i = 0; i < ds_list_size(_filter_list); i++) {
        if (ds_list_find_value(_filter_list, i) == _filter_value) return false;
    }
    
    ds_list_add(_filter_list, _filter_value);
    _gmls_invalidate_facet_cache();
    return true;
}

function gmls_get_date_histogram(_facet_name, _interval, _count, _query = "", _filters = undefined) {
    var _ls = global.gmls;
    if (!variable_struct_exists(_ls, "date_facets")) return {};
    if (!ds_map_exists(_ls.date_facets, _facet_name)) return {};
    
    var _date_map = ds_map_find_value(_ls.date_facets, _facet_name);
    
    var _base_ids = [];
    if (string_length(_query) > 0) {
        var _search_results = gmls_search(_query, -1);
        for (var i = 0; i < array_length(_search_results); i++) {
            array_push(_base_ids, _search_results[i].id);
        }
    } else {
        var _doc = ds_map_find_first(_ls.documents);
        while (!is_undefined(_doc)) {
            array_push(_base_ids, _doc);
            _doc = ds_map_find_next(_ls.documents, _doc);
        }
    }
    
    var _saved_filters = undefined;
    if (!is_undefined(_filters)) {
        _saved_filters = _gmls_save_filter_state();
        for (var i = 0; i < array_length(_filters); i++) {
            var _filter = _filters[i];
            gmls_add_facet_filter(_filter.facet, _filter.value);
        }
    }
    
    var _filtered_ids = _gmls_apply_facet_filters(_base_ids);
    
    if (!is_undefined(_saved_filters)) {
        _gmls_restore_filter_state(_saved_filters);
    }
    
    var _min_date = 9223372036854775807;
    var _max_date = -9223372036854775807;
    
    for (var i = 0; i < array_length(_filtered_ids); i++) {
        var _id = _filtered_ids[i];
        if (ds_map_exists(_date_map, _id)) {
            var _d = ds_map_find_value(_date_map, _id);
            if (_d < _min_date) _min_date = _d;
            if (_d > _max_date) _max_date = _d;
        }
    }
    
    if (_min_date == 9223372036854775807) return {};
    
    var _histogram = {};
    var _current = _min_date;
    
    for (var i = 0; i < _count; i++) {
        var _label = "";
        var _year = date_get_year(_current);
        var _month = date_get_month(_current);
        var _day = date_get_day(_current);
        
        var _month_str = string(_month);
        if (string_length(_month_str) == 1) _month_str = "0" + _month_str;
        
        var _day_str = string(_day);
        if (string_length(_day_str) == 1) _day_str = "0" + _day_str;
        
        switch (_interval) {
            case "day":
                _label = string(_year) + "-" + _month_str + "-" + _day_str;
                _current = date_inc_day(_current, 1);
                break;
            case "week":
                _label = string(_year) + "-" + _month_str + "-" + _day_str;
                _current = date_inc_week(_current, 1);
                break;
            case "month":
                _label = string(_year) + "-" + _month_str;
                _current = date_inc_month(_current, 1);
                break;
            case "year":
                _label = string(_year);
                _current = date_inc_year(_current, 1);
                break;
            default:
                return {};
        }
        
        _histogram[$ _label] = 0;
    }
    
    for (var i = 0; i < array_length(_filtered_ids); i++) {
        var _id = _filtered_ids[i];
        if (ds_map_exists(_date_map, _id)) {
            var _doc_date = ds_map_find_value(_date_map, _id);
            
            var _bucket_label = "";
            var _year = date_get_year(_doc_date);
            var _month = date_get_month(_doc_date);
            var _day = date_get_day(_doc_date);
            
            var _month_str = string(_month);
            if (string_length(_month_str) == 1) _month_str = "0" + _month_str;
            
            var _day_str = string(_day);
            if (string_length(_day_str) == 1) _day_str = "0" + _day_str;
            
            switch (_interval) {
                case "day":
                    _bucket_label = string(_year) + "-" + _month_str + "-" + _day_str;
                    break;
                case "week":
                    // monday = 1, sunday = 7
                    var _weekday = date_get_weekday(_doc_date);
                    var _days_to_subtract = _weekday - 1;
                    var _week_start = date_inc_day(_doc_date, -_days_to_subtract);
                    var _ws_year = date_get_year(_week_start);
                    var _ws_month = date_get_month(_week_start);
                    var _ws_day = date_get_day(_week_start);
                    var _ws_month_str = string(_ws_month);
                    var _ws_day_str = string(_ws_day);
                    if (string_length(_ws_month_str) == 1) _ws_month_str = "0" + _ws_month_str;
                    if (string_length(_ws_day_str) == 1) _ws_day_str = "0" + _ws_day_str;
                    _bucket_label = string(_ws_year) + "-" + _ws_month_str + "-" + _ws_day_str;
                    break;
                case "month":
                    _bucket_label = string(_year) + "-" + _month_str;
                    break;
                case "year":
                    _bucket_label = string(_year);
                    break;
            }
            
            if (variable_struct_exists(_histogram, _bucket_label)) {
                _histogram[$ _bucket_label] = _histogram[$ _bucket_label] + 1;
            }
        }
    }
    
    return _histogram;
}

function _gmls_resolve_date_preset(_preset) {
    var _now = date_current_datetime();
    var _result = { start_date: 0, end_date: 0 };
    switch (string_lower(_preset)) {
        case "today":
            _result.start_date = date_create_date(date_get_year(_now), date_get_month(_now), date_get_day(_now));
            _result.end_date = date_inc_day(_result.start_date, 1);
            break;
        case "yesterday":
            var _yesterday = date_inc_day(_now, -1);
            _result.start_date = date_create_date(date_get_year(_yesterday), date_get_month(_yesterday), date_get_day(_yesterday));
            _result.end_date = date_inc_day(_result.start_date, 1);
            break;
        case "last_7_days":
            _result.end_date = _now;
            _result.start_date = date_inc_day(_now, -7);
            break;
        case "last_30_days":
            _result.end_date = _now;
            _result.start_date = date_inc_day(_now, -30);
            break;
        case "this_month":
            _result.start_date = date_create_date(date_get_year(_now), date_get_month(_now), 1);
            _result.end_date = date_inc_month(_result.start_date, 1);
            break;
        case "last_month":
            var _first_this_month = date_create_date(date_get_year(_now), date_get_month(_now), 1);
            _result.start_date = date_inc_month(_first_this_month, -1);
            _result.end_date = _first_this_month;
            break;
        case "this_year":
            _result.start_date = date_create_date(date_get_year(_now), 1, 1);
            _result.end_date = date_create_date(date_get_year(_now) + 1, 1, 1);
            break;
        case "last_year":
            var _this_year_start = date_create_date(date_get_year(_now), 1, 1);
            _result.start_date = date_create_date(date_get_year(_now) - 1, 1, 1);
            _result.end_date = _this_year_start;
            break;
        default:
            return undefined;
    }
    return _result;
}

function gmls_remove_date_filter(_facet_name) {
    var _ls = global.gmls;
    var _filter_key = "date|" + string(_facet_name);
    if (ds_map_exists(_ls.active_filters, _filter_key)) {
        var _list = ds_map_find_value(_ls.active_filters, _filter_key);
        ds_list_destroy(_list);
        ds_map_delete(_ls.active_filters, _filter_key);
        _gmls_invalidate_facet_cache();
        return true;
    }
    return false;
}

function gmls_set_filter_operator(_operator) {
    if (_operator == "AND" || _operator == "OR") {
        global.gmls.filter_operator = _operator;
        _gmls_invalidate_facet_cache();
    }
}

function _gmls_invalidate_facet_cache() {
    if (!is_undefined(global.gmls.facet_cache)) {
        ds_map_clear(global.gmls.facet_cache);
    }
}

function _gmls_apply_facet_filters(_doc_ids_array) {
    var _ls = global.gmls;
    if (is_undefined(_ls.active_filters) || ds_map_size(_ls.active_filters) == 0) {
        return _doc_ids_array;
    }
    
    var _filter_groups = ds_map_create();
    var _facet = ds_map_find_first(_ls.active_filters);
    while (!is_undefined(_facet)) {
        if (string_pos("date|", _facet) != 1) {
            var _filter_values = ds_map_find_value(_ls.active_filters, _facet);
            var _doc_set = ds_map_create();
            for (var i = 0; i < ds_list_size(_filter_values); i++) {
                var _value = ds_list_find_value(_filter_values, i);
                var _docs_for_value = _gmls_get_documents_by_facet(_facet, _value);
                for (var j = 0; j < array_length(_docs_for_value); j++) {
                    var _doc_id = _docs_for_value[j];
                    ds_map_add(_doc_set, _doc_id, true);
                }
            }
            ds_map_add(_filter_groups, _facet, _doc_set);
        }
        _facet = ds_map_find_next(_ls.active_filters, _facet);
    }
    
    var _date_filter_keys = [];
    _facet = ds_map_find_first(_ls.active_filters);
    while (!is_undefined(_facet)) {
        if (string_pos("date|", _facet) == 1) {
            array_push(_date_filter_keys, _facet);
        }
        _facet = ds_map_find_next(_ls.active_filters, _facet);
    }
    
    var _date_doc_sets = [];
    for (var di = 0; di < array_length(_date_filter_keys); di++) {
        var _filter_key = _date_filter_keys[di];
        var _facet_name = string_copy(_filter_key, 6, string_length(_filter_key) - 5); // date|
        var _filter_values = ds_map_find_value(_ls.active_filters, _filter_key);
        var _pass_set = ds_map_create();
        
        if (variable_struct_exists(_ls, "date_facets") && ds_map_exists(_ls.date_facets, _facet_name)) {
            var _date_map = ds_map_find_value(_ls.date_facets, _facet_name);
            
            for (var i = 0; i < ds_list_size(_filter_values); i++) {
                var _range_str = ds_list_find_value(_filter_values, i);
                var _parts = string_split(_range_str, "|");
                if (array_length(_parts) != 2) continue;
                var _start_date = real(_parts[0]);
                var _end_date = real(_parts[1]);
                
                var _doc_id = ds_map_find_first(_date_map);
                while (!is_undefined(_doc_id)) {
                    var _doc_date = ds_map_find_value(_date_map, _doc_id);
                    if (_doc_date >= _start_date && _doc_date < _end_date) {
                        ds_map_add(_pass_set, _doc_id, true);
                    }
                    _doc_id = ds_map_find_next(_date_map, _doc_id);
                }
            }
        }
        array_push(_date_doc_sets, _pass_set);
    }
    
    var _operator = _ls.filter_operator;
    var _filtered_ids = [];
    
    for (var i = 0; i < array_length(_doc_ids_array); i++) {
        var _doc_id = _doc_ids_array[i];
        var _matches = true;
        
        if (_operator == "AND") {
            var _group = ds_map_find_first(_filter_groups);
            while (!is_undefined(_group) && _matches) {
                var _doc_set = ds_map_find_value(_filter_groups, _group);
                if (!ds_map_exists(_doc_set, _doc_id)) {
                    _matches = false;
                }
                _group = ds_map_find_next(_filter_groups, _group);
            }
        } else { // OR
            _matches = false;
            var _group = ds_map_find_first(_filter_groups);
            while (!is_undefined(_group) && !_matches) {
                var _doc_set = ds_map_find_value(_filter_groups, _group);
                if (ds_map_exists(_doc_set, _doc_id)) {
                    _matches = true;
                }
                _group = ds_map_find_next(_filter_groups, _group);
            }
        }
        
        if (_matches) {
            for (var d = 0; d < array_length(_date_doc_sets); d++) {
                var _date_set = _date_doc_sets[d];
                if (!ds_map_exists(_date_set, _doc_id)) {
                    _matches = false;
                    break;
                }
            }
        }
        
        if (_matches) {
            array_push(_filtered_ids, _doc_id);
        }
    }
    
    var _group = ds_map_find_first(_filter_groups);
    while (!is_undefined(_group)) {
        ds_map_destroy(ds_map_find_value(_filter_groups, _group));
        _group = ds_map_find_next(_filter_groups, _group);
    }
    ds_map_destroy(_filter_groups);
    
    for (var d = 0; d < array_length(_date_doc_sets); d++) {
        ds_map_destroy(_date_doc_sets[d]);
    }
    
    return _filtered_ids;
}

function _gmls_get_documents_by_facet(_facet_name, _value) {
    var _ls = global.gmls;
    var _result = [];
    
    if (!ds_map_exists(_ls.facet_index, _facet_name)) return _result;
    
    var _facet_map = ds_map_find_value(_ls.facet_index, _facet_name);
    var _value_str = string(_value);
    
    if (ds_map_exists(_facet_map, _value_str)) {
        var _doc_list = ds_map_find_value(_facet_map, _value_str);
        for (var i = 0; i < ds_list_size(_doc_list); i++) {
            array_push(_result, ds_list_find_value(_doc_list, i));
        }
    }
    
    return _result;
}

function gmls_get_facet_counts(_query, _filters = undefined, _facets_to_aggregate = undefined) {
    var _ls = global.gmls;
    
    if (is_undefined(_facets_to_aggregate)) {
        _facets_to_aggregate = [];
        var _facet = ds_map_find_first(_ls.facet_index);
        while (!is_undefined(_facet)) {
            array_push(_facets_to_aggregate, _facet);
            _facet = ds_map_find_next(_ls.facet_index, _facet);
        }
    }
    
    var _cache_key = _gmls_facet_cache_key(_query, _filters, _facets_to_aggregate);
    if (ds_map_exists(_ls.facet_cache, _cache_key)) {
        return ds_map_find_value(_ls.facet_cache, _cache_key);
    }
    
    var _base_doc_ids = [];
    
    if (string_length(_query) > 0) {
        var _search_results = gmls_search(_query, -1);
        for (var i = 0; i < array_length(_search_results); i++) {
            array_push(_base_doc_ids, _search_results[i].id);
        }
    } else {
        var _doc = ds_map_find_first(_ls.documents);
        while (!is_undefined(_doc)) {
            array_push(_base_doc_ids, _doc);
            _doc = ds_map_find_next(_ls.documents, _doc);
        }
    }
    
    var _saved_filters = undefined;
    if (!is_undefined(_filters)) {
        _saved_filters = _gmls_save_filter_state();
        for (var i = 0; i < array_length(_filters); i++) {
            var _filter = _filters[i];
            gmls_add_facet_filter(_filter.facet, _filter.value);
        }
    }
    
    var _filtered_ids = _gmls_apply_facet_filters(_base_doc_ids);
    
    var _counts = {};
    
    for (var i = 0; i < array_length(_facets_to_aggregate); i++) {
        var _facet_name = _facets_to_aggregate[i];
        _counts[$ _facet_name] = {};
        
        if (ds_map_exists(_ls.facet_index, _facet_name)) {
            var _facet_map = ds_map_find_value(_ls.facet_index, _facet_name);
            var _value = ds_map_find_first(_facet_map);
            
            while (!is_undefined(_value)) {
                var _doc_list = ds_map_find_value(_facet_map, _value);
                var _count = 0;
                
                for (var j = 0; j < ds_list_size(_doc_list); j++) {
                    var _doc_id = ds_list_find_value(_doc_list, j);
                    if (_gmls_array_contains(_filtered_ids, _doc_id)) {
                        _count++;
                    }
                }
                
                if (_count > 0) {
                    _counts[$ _facet_name][$ _value] = _count;
                }
                
                _value = ds_map_find_next(_facet_map, _value);
            }
        }
    }
    
    if (!is_undefined(_saved_filters)) {
        _gmls_restore_filter_state(_saved_filters);
    }
    
    ds_map_add(_ls.facet_cache, _cache_key, _counts);
    
    return _counts;
}

function _gmls_facet_cache_key(_query, _filters, _facets) {
    var _ls = global.gmls;
    
    var _key = _query + "|";
    
    if (!is_undefined(_filters)) {
        for (var i = 0; i < array_length(_filters); i++) {
            _key += _filters[i].facet + ":" + _filters[i].value + ",";
        }
    }
    _key += "|";
    
    var _active = gmls_get_active_filters();
    var _names = variable_struct_get_names(_active);
    for (var i = 0; i < array_length(_names); i++) {
        var _values = _active[$ _names[i]];
        for (var j = 0; j < array_length(_values); j++) {
            _key += _names[i] + ":" + _values[j] + ",";
        }
    }
    _key += "|" + string(_ls.filter_operator);
    
    return md5_string_unicode(_key);
}

function _gmls_save_filter_state() {
    var _ls = global.gmls;
    var _state = ds_map_create();
    
    var _facet = ds_map_find_first(_ls.active_filters);
    while (!is_undefined(_facet)) {
        var _list = ds_map_find_value(_ls.active_filters, _facet);
        var _saved_list = ds_list_create();
        for (var i = 0; i < ds_list_size(_list); i++) {
            ds_list_add(_saved_list, ds_list_find_value(_list, i));
        }
        ds_map_add(_state, _facet, _saved_list);
        _facet = ds_map_find_next(_ls.active_filters, _facet);
    }
    
    return _state;
}

function _gmls_restore_filter_state(_state) {
    gmls_clear_facet_filters();
    
    var _facet = ds_map_find_first(_state);
    while (!is_undefined(_facet)) {
        var _saved_list = ds_map_find_value(_state, _facet);
        for (var i = 0; i < ds_list_size(_saved_list); i++) {
            gmls_add_facet_filter(_facet, ds_list_find_value(_saved_list, i));
        }
        ds_list_destroy(_saved_list);
        _facet = ds_map_find_next(_state, _facet);
    }
    
    ds_map_destroy(_state);
}

function _gmls_array_contains(_arr, _value) {
    for (var i = 0; i < array_length(_arr); i++) {
        if (_arr[i] == _value) return true;
    }
    return false;
}

function gmls_add_range_facet(_id, _facet_name, _numeric_value) {
    var _ls = global.gmls;
    
    if (!ds_map_exists(_ls.facet_index, _facet_name)) {
        ds_map_add(_ls.facet_index, _facet_name, ds_map_create());
    }
    
    if (!variable_struct_exists(_ls, "range_facets")) {
        _ls.range_facets = ds_map_create();
    }
    
    if (!ds_map_exists(_ls.range_facets, _facet_name)) {
        ds_map_add(_ls.range_facets, _facet_name, ds_map_create());
    }
    
    var _range_map = ds_map_find_value(_ls.range_facets, _facet_name);
    ds_map_add(_range_map, _id, _numeric_value);
    
    var _bucket = _gmls_get_numeric_bucket(_numeric_value);
    var _facet_map = ds_map_find_value(_ls.facet_index, _facet_name);
    _gmls_add_to_facet_map(_facet_map, _bucket, _id);
}

function gmls_get_range_facet_counts(_facet_name, _min, _max, _bucket_size) {
    var _ls = global.gmls;
    var _counts = {};
    
    if (!variable_struct_exists(_ls, "range_facets")) return _counts;
    if (!ds_map_exists(_ls.range_facets, _facet_name)) return _counts;
    
    var _range_map = ds_map_find_value(_ls.range_facets, _facet_name);
    var _active_ids = _gmls_get_current_filtered_doc_ids();
    
    for (var _bucket_start = _min; _bucket_start <= _max; _bucket_start += _bucket_size) {
        var _bucket_end = _bucket_start + _bucket_size;
        var _bucket_label = string(_bucket_start) + "-" + string(_bucket_end);
        var _count = 0;
        
        var _doc_id = ds_map_find_first(_range_map);
        while (!is_undefined(_doc_id)) {
            var _value = ds_map_find_value(_range_map, _doc_id);
            if (_value >= _bucket_start && _value < _bucket_end) {
                if (_gmls_array_contains(_active_ids, _doc_id)) {
                    _count++;
                }
            }
            _doc_id = ds_map_find_next(_range_map, _doc_id);
        }
        
        if (_count > 0) {
            _counts[$ _bucket_label] = _count;
        }
    }
    
    return _counts;
}

function _gmls_get_numeric_bucket(_value) {
    if (_value < 10) return "0-9";
    if (_value < 20) return "10-19";
    if (_value < 50) return "20-49";
    if (_value < 100) return "50-99";
    return "100+";
}

function _gmls_get_current_filtered_doc_ids() {
    var _ls = global.gmls;
    var _all_ids = [];
    
    var _doc = ds_map_find_first(_ls.documents);
    while (!is_undefined(_doc)) {
        array_push(_all_ids, _doc);
        _doc = ds_map_find_next(_ls.documents, _doc);
    }
    
    return _gmls_apply_facet_filters(_all_ids);
}


function gmls_update_document_facets(_id, _new_facets) {
    var _ls = global.gmls;
    
    if (!ds_map_exists(_ls.documents, _id)) return false;
    
    var _doc = ds_map_find_value(_ls.documents, _id);
    if (variable_struct_exists(_doc, "facets")) {
        var _old_facets = _doc.facets;
        var _old_names = variable_struct_get_names(_old_facets);
        
        for (var i = 0; i < array_length(_old_names); i++) {
            _gmls_remove_document_from_facet(_old_names[i], _id);
        }
    }
    
    return gmls_add_document_faceted(_id, _doc.text, _new_facets, _doc.metadata);
}

function _gmls_remove_document_from_facet(_facet_name, _doc_id) {
    var _ls = global.gmls;
    
    if (!ds_map_exists(_ls.facet_index, _facet_name)) return;
    
    var _facet_map = ds_map_find_value(_ls.facet_index, _facet_name);
    var _value = ds_map_find_first(_facet_map);
    
    while (!is_undefined(_value)) {
        var _doc_list = ds_map_find_value(_facet_map, _value);
        for (var i = 0; i < ds_list_size(_doc_list); i++) {
            if (ds_list_find_value(_doc_list, i) == _doc_id) {
                ds_list_delete(_doc_list, i);
                break;
            }
        }
        
        if (ds_list_size(_doc_list) == 0) {
            ds_list_destroy(_doc_list);
            ds_map_delete(_facet_map, _value);
        }
        
        _value = ds_map_find_next(_facet_map, _value);
    }
    
    if (ds_map_size(_facet_map) == 0) {
        ds_map_destroy(_facet_map);
        ds_map_delete(_ls.facet_index, _facet_name);
    }
}