

// GEOSPATIAL SEARCH
function gmls_init_geo() {
    var _ls = global.gmls;
    
    if (!variable_struct_exists(_ls, "geo_index")) {
        _ls.geo_index = ds_map_create();
    }
    if (!variable_struct_exists(_ls, "geo_radius_cache")) {
        _ls.geo_radius_cache = ds_map_create();
    }
    if (!variable_struct_exists(_ls, "default_geo_unit")) {
        _ls.default_geo_unit = "km";
    }
}

function gmls_add_geolocation(_doc_id, _lat, _lng, _geohash_precision = 6) {
    var _ls = global.gmls;
    
    if (!ds_map_exists(_ls.documents, _doc_id)) return false;
    if (is_undefined(_ls.geo_index)) gmls_init_geo();
    
    var _geohash = _gmls_encode_geohash(_lat, _lng, _geohash_precision);
    
    ds_map_add(_ls.geo_index, _doc_id, {
        lat: _lat,
        lng: _lng,
        geohash: _geohash
    });
    
    return true;
}

function _gmls_distance_2d(_x1, _y1, _x2, _y2) {
    return sqrt(power(_x2 - _x1, 2) + power(_y2 - _y1, 2));
}

function _gmls_distance_3d(_x1, _y1, _z1, _x2, _y2, _z2) {
    return sqrt(power(_x2 - _x1, 2) + power(_y2 - _y1, 2) + power(_z2 - _z1, 2));
}

function gmls_add_location_2d(_doc_id, _x, _y) {
    var _ls = global.gmls;
    if (!ds_map_exists(_ls.documents, _doc_id)) return false;
    if (is_undefined(_ls.geo_index)) gmls_init_geo();
    
    if (!ds_map_exists(_ls.geo_index, _doc_id)) {
        ds_map_add(_ls.geo_index, _doc_id, {});
    }
    var _loc = ds_map_find_value(_ls.geo_index, _doc_id);
    _loc.x = _x;
    _loc.y = _y;
    _loc.type = "2d";
    return true;
}

function gmls_add_location_3d(_doc_id, _x, _y, _z) {
    var _ls = global.gmls;
    if (!ds_map_exists(_ls.documents, _doc_id)) return false;
    if (is_undefined(_ls.geo_index)) gmls_init_geo();
    
    if (!ds_map_exists(_ls.geo_index, _doc_id)) {
        ds_map_add(_ls.geo_index, _doc_id, {});
    }
    var _loc = ds_map_find_value(_ls.geo_index, _doc_id);
    _loc.x = _x;
    _loc.y = _y;
    _loc.z = _z;
    _loc.type = "3d";
    return true;
}

function gmls_add_location_grid(_doc_id, _x, _y, _cell_size = 100) {
    var _ls = global.gmls;
    if (!ds_map_exists(_ls.documents, _doc_id)) return false;
    if (is_undefined(_ls.geo_index)) gmls_init_geo();
    
    var _cell_x = floor(_x / _cell_size);
    var _cell_y = floor(_y / _cell_size);
    var _cell_key = string(_cell_x) + "," + string(_cell_y);
    
    if (!ds_map_exists(_ls.geo_index, _doc_id)) {
        ds_map_add(_ls.geo_index, _doc_id, {});
    }
    var _loc = ds_map_find_value(_ls.geo_index, _doc_id);
    _loc.x = _x;
    _loc.y = _y;
    _loc.cell_x = _cell_x;
    _loc.cell_y = _cell_y;
    _loc.cell_key = _cell_key;
    _loc.type = "grid";
    
    if (!variable_struct_exists(_ls, "cell_index")) {
        _ls.cell_index = ds_map_create();
    }
    
    if (!ds_map_exists(_ls.cell_index, _cell_key)) {
        ds_map_add(_ls.cell_index, _cell_key, ds_list_create());
    }
    
    var _cell_list = ds_map_find_value(_ls.cell_index, _cell_key);
    var _already_exists = false;
    for (var i = 0; i < ds_list_size(_cell_list); i++) {
        if (ds_list_find_value(_cell_list, i) == _doc_id) {
            _already_exists = true;
            break;
        }
    }
    if (!_already_exists) ds_list_add(_cell_list, _doc_id);
    
    return true;
}

function _gmls_haversine_distance(_lat1, _lon1, _lat2, _lon2, _unit = "km") {
    var _r = (_unit == "km") ? 6371 : 3959;
    var _dLat = (_lat2 - _lat1) * pi / 180;
    var _dLon = (_lon2 - _lon1) * pi / 180;
    var _a = sin(_dLat / 2) * sin(_dLat / 2) +
             cos(_lat1 * pi / 180) * cos(_lat2 * pi / 180) *
             sin(_dLon / 2) * sin(_dLon / 2);
    var _c = 2 * arctan2(sqrt(_a), sqrt(1 - _a));
    return _r * _c;
}

function gmls_get_nearest(_lat, _lng, _limit = 5, _query = "") {
    var _results = gmls_search_nearby(_lat, _lng, 999999, "km", _query, _limit);
    return _results;
}

function gmls_get_geo_stats() {
    var _ls = global.gmls;
    if (is_undefined(_ls.geo_index)) return { total_locations: 0 };
    
    var _center = { lat: 0, lng: 0, count: 0 };
    var _bounds = { min_lat: 90, max_lat: -90, min_lng: 180, max_lng: -180 };
    
    var _doc_id = ds_map_find_first(_ls.geo_index);
    while (!is_undefined(_doc_id)) {
        var _geo = ds_map_find_value(_ls.geo_index, _doc_id);
        _center.lat += _geo.lat;
        _center.lng += _geo.lng;
        _center.count++;
        
        _bounds.min_lat = min(_bounds.min_lat, _geo.lat);
        _bounds.max_lat = max(_bounds.max_lat, _geo.lat);
        _bounds.min_lng = min(_bounds.min_lng, _geo.lng);
        _bounds.max_lng = max(_bounds.max_lng, _geo.lng);
        
        _doc_id = ds_map_find_next(_ls.geo_index, _doc_id);
    }
    
    if (_center.count > 0) {
        _center.lat /= _center.count;
        _center.lng /= _center.count;
    }
    
    return {
        total_locations: _center.count,
        center: { lat: _center.lat, lng: _center.lng },
        bounds: _bounds,
        has_data: _center.count > 0
    };
}

function gmls_clear_geo_cache() {
    if (!is_undefined(global.gmls.geo_radius_cache)) {
        ds_map_clear(global.gmls.geo_radius_cache);
    }
}

function _gmls_geo_cache_key(_lat, _lng, _radius, _unit, _query) {
    return string(_lat) + "|" + string(_lng) + "|" + string(_radius) + "|" + _unit + "|" + _query;
}

function _gmls_encode_geohash(_lat, _lng, _precision) {
    var _lat_range = [-90, 90];
    var _lng_range = [-180, 180];
    var _geohash = "";
    var _is_even = true;
    var _bits = 0;
    var _ch = 0;
    
    var _base32 = "0123456789bcdefghjkmnpqrstuvwxyz";
    
    while (string_length(_geohash) < _precision) {
        if (_is_even) {
            var _mid = (_lng_range[0] + _lng_range[1]) / 2;
            if (_lng > _mid) {
                _ch = (_ch << 1) | 1;
                _lng_range[0] = _mid;
            } else {
                _ch = _ch << 1;
                _lng_range[1] = _mid;
            }
        } else {
            var _mid = (_lat_range[0] + _lat_range[1]) / 2;
            if (_lat > _mid) {
                _ch = (_ch << 1) | 1;
                _lat_range[0] = _mid;
            } else {
                _ch = _ch << 1;
                _lat_range[1] = _mid;
            }
        }
        
        _is_even = !_is_even;
        _bits++;
        
        if (_bits == 5) {
            _geohash += string_char_at(_base32, _ch + 1);
            _bits = 0;
            _ch = 0;
        }
    }
    
    return _geohash;
}

function _gmls_decode_geohash(_geohash) {
    var _base32 = "0123456789bcdefghjkmnpqrstuvwxyz";
    var _lat_range = [-90, 90];
    var _lng_range = [-180, 180];
    var _is_even = true;
    
    for (var i = 1; i <= string_length(_geohash); i++) {
        var _char = string_char_at(_geohash, i);
        var _idx = string_pos(_char, _base32) - 1;
        
        for (var b = 4; b >= 0; b--) {
            var _bit = (_idx >> b) & 1;
            if (_is_even) {
                var _mid = (_lng_range[0] + _lng_range[1]) / 2;
                if (_bit == 1) {
                    _lng_range[0] = _mid;
                } else {
                    _lng_range[1] = _mid;
                }
            } else {
                var _mid = (_lat_range[0] + _lat_range[1]) / 2;
                if (_bit == 1) {
                    _lat_range[0] = _mid;
                } else {
                    _lat_range[1] = _mid;
                }
            }
            _is_even = !_is_even;
        }
    }
    
    return {
        lat: (_lat_range[0] + _lat_range[1]) / 2,
        lng: (_lng_range[0] + _lng_range[1]) / 2,
        error_lat: (_lat_range[1] - _lat_range[0]) / 2,
        error_lng: (_lng_range[1] - _lng_range[0]) / 2
    };
}

function gmls_geohash_neighbors(_geohash) {
    var _neighbors = [];
    var _decoded = _gmls_decode_geohash(_geohash);
    var _lat = _decoded.lat;
    var _lng = _decoded.lng;
    var _error_lat = _decoded.error_lat * 2;
    var _error_lng = _decoded.error_lng * 2;
    
    var _dirs = [
        { dlng: -_error_lng, dlat: -_error_lat },
        { dlng: 0, dlat: -_error_lat },
        { dlng: _error_lng, dlat: -_error_lat },
        { dlng: -_error_lng, dlat: 0 },
        { dlng: _error_lng, dlat: 0 },
        { dlng: -_error_lng, dlat: _error_lat },
        { dlng: 0, dlat: _error_lat },
        { dlng: _error_lng, dlat: _error_lat }
    ];
    
    for (var i = 0; i < array_length(_dirs); i++) {
        var _neighbor_hash = _gmls_encode_geohash(
            _lat + _dirs[i].dlat,
            _lng + _dirs[i].dlng,
            string_length(_geohash)
        );
        array_push(_neighbors, _neighbor_hash);
    }
    
    return _neighbors;
}