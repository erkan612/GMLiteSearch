

//  N‑GRAM INDEXING
function _gmls_index_ngrams(_text, _doc_id) {
    var _ls = global.gmls;
    if (!_ls.enable_ngrams) return;
    
    var _clean = "";
    var _len = string_length(_text);
    for (var i = 1; i <= _len; i++) {
        var _ch = string_char_at(_text, i);
        var _code = ord(_ch);
        if ((_code >= 48 && _code <= 57) ||
            (_code >= 65 && _code <= 90) ||
            (_code >= 97 && _code <= 122) ||
            _ch == " ") {
            _clean += _ch;
        } else {
            _clean += " ";
        }
    }
    if (!_ls.case_sensitive) _clean = string_lower(_clean);
    
    var _ngram_len = _ls.ngram_size;
    var _text_len = string_length(_clean);
    var _ngram_counts = ds_map_create();
    
    for (var i = 1; i <= _text_len - _ngram_len + 1; i++) {
        var _ngram = string_copy(_clean, i, _ngram_len);
        if (string_pos(" ", _ngram) == 0) {
            if (!ds_map_exists(_ngram_counts, _ngram))
                ds_map_add(_ngram_counts, _ngram, 0);
            ds_map_set(_ngram_counts, _ngram, ds_map_find_value(_ngram_counts, _ngram) + 1);
        }
    }
    
    var _ngram = ds_map_find_first(_ngram_counts);
    while (!is_undefined(_ngram)) {
        var _freq = ds_map_find_value(_ngram_counts, _ngram);
        if (!ds_map_exists(_ls.ngram_index, _ngram))
            ds_map_add(_ls.ngram_index, _ngram, ds_map_create());
        var _doc_map = ds_map_find_value(_ls.ngram_index, _ngram);
        ds_map_add(_doc_map, _doc_id, _freq);
        _ngram = ds_map_find_next(_ngram_counts, _ngram);
    }
    ds_map_destroy(_ngram_counts);
}