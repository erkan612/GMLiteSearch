

//  DOCUMENT ADDITION
function gmls_add_document(_id, _text, _metadata = undefined) {
    var _ls = global.gmls;
    
    var _word_estimate = string_length(_text) / 6;
    if (_word_estimate > _ls.max_doc_size) {
        show_debug_message("GMLS warning: document " + string(_id) + " exceeds max_doc_size, truncating.");
        _text = string_copy(_text, 1, _ls.max_doc_size * 6);
    }
    
    if (is_undefined(_metadata)) {
        _metadata = { title: "", tags: [], timestamp: current_time };
    }
    
    ds_map_add(_ls.documents, _id, {
        id: _id,
        text: _text,
        metadata: _metadata,
        word_count: 0
    });
    
    var _words = _gmls_process_text(_text);
    var _doc_words = ds_map_create();
    
    for (var i = 0; i < array_length(_words); i++) {
        var _w = _words[i];
        if (!ds_map_exists(_doc_words, _w)) ds_map_add(_doc_words, _w, 0);
        ds_map_set(_doc_words, _w, ds_map_find_value(_doc_words, _w) + 1);
    }
    
    var _w = ds_map_find_first(_doc_words);
    while (!is_undefined(_w)) {
        var _freq = ds_map_find_value(_doc_words, _w);
        
        if (!ds_map_exists(_ls.inverted_index, _w))
            ds_map_add(_ls.inverted_index, _w, ds_map_create());
        var _docs_map = ds_map_find_value(_ls.inverted_index, _w);
        ds_map_add(_docs_map, _id, _freq);
        
        if (!ds_map_exists(_ls.word_stats, _w))
            ds_map_add(_ls.word_stats, _w, { total_frequency:0, document_frequency:0 });
        var _stats = ds_map_find_value(_ls.word_stats, _w);
        _stats.total_frequency += _freq;
        _stats.document_frequency++;
        
        _w = ds_map_find_next(_doc_words, _w);
    }
    
    var _doc = ds_map_find_value(_ls.documents, _id);
    _doc.word_count = ds_map_size(_doc_words);
    ds_map_destroy(_doc_words);
    _ls.doc_count++;
    
    if (_ls.enable_ngrams) _gmls_index_ngrams(_text, _id);
    
    return true;
}

function gmls_add_document_weighted(_id, _text, _metadata = undefined) {
    if (is_undefined(_metadata)) _metadata = { title: "", tags: [], timestamp: current_time };
    
    var _searchable = _text + " ";
    if (_metadata.title != "") {
        _searchable += string_repeat(_metadata.title + " ", 3);
    }
    if (variable_struct_exists(_metadata, "tags") && is_array(_metadata.tags)) {
        for (var i = 0; i < array_length(_metadata.tags); i++) {
            _searchable += string_repeat(_metadata.tags[i] + " ", 2);
        }
    }
    if (variable_struct_exists(_metadata, "author")) _searchable += _metadata.author + " ";
    if (variable_struct_exists(_metadata, "description")) _searchable += _metadata.description + " ";
    
    return gmls_add_document(_id, _searchable, _metadata);
}

function gmls_add_document_enhanced(_id, _text, _metadata = undefined) {
    return gmls_add_document_weighted(_id, _text, _metadata);
}

//  DOCUMENT MANAGEMENT
function gmls_remove_document(_id) {
    var _ls = global.gmls;
    if (!ds_map_exists(_ls.documents, _id)) return false;
    
    var _words_to_delete = [];
    var _word = ds_map_find_first(_ls.inverted_index);
    while (!is_undefined(_word)) {
        var _docs = ds_map_find_value(_ls.inverted_index, _word);
        if (ds_map_exists(_docs, _id)) {
            var _freq = ds_map_find_value(_docs, _id);
            ds_map_delete(_docs, _id);
            var _stats = ds_map_find_value(_ls.word_stats, _word);
            _stats.total_frequency -= _freq;
            _stats.document_frequency--;
            if (_stats.document_frequency <= 0) {
                array_push(_words_to_delete, _word);
            }
        }
        _word = ds_map_find_next(_ls.inverted_index, _word);
    }
    
    for (var i = 0; i < array_length(_words_to_delete); i++) {
        var _w = _words_to_delete[i];
        ds_map_delete(_ls.inverted_index, _w);
        ds_map_delete(_ls.word_stats, _w);
    }
    
    if (_ls.enable_ngrams) {
        var _ngrams_to_delete = [];
        var _ng = ds_map_find_first(_ls.ngram_index);
        while (!is_undefined(_ng)) {
            var _docs = ds_map_find_value(_ls.ngram_index, _ng);
            if (ds_map_exists(_docs, _id)) {
                ds_map_delete(_docs, _id);
                if (ds_map_size(_docs) == 0) {
                    array_push(_ngrams_to_delete, _ng);
                }
            }
            _ng = ds_map_find_next(_ls.ngram_index, _ng);
        }
        for (var i = 0; i < array_length(_ngrams_to_delete); i++) {
            ds_map_delete(_ls.ngram_index, _ngrams_to_delete[i]);
        }
    }
    
    ds_map_delete(_ls.documents, _id);
    _ls.doc_count--;
    return true;
}

function gmls_get_document(_id) {
    if (ds_map_exists(global.gmls.documents, _id))
        return ds_map_find_value(global.gmls.documents, _id);
    return undefined;
}

function gmls_get_stats() {
    var _ls = global.gmls;
    return {
        document_count: _ls.doc_count,
        unique_words: ds_map_size(_ls.inverted_index),
        total_word_occurrences: _gmls_total_word_freq(),
        ngram_count: ds_map_size(_ls.ngram_index),
        stemming_enabled: _ls.enable_stemming
    };
}