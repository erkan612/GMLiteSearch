

//  STEMMING ENGINE (Porter2 Snowball English)
function _gmls_is_vowel(ch) {
        return (ch == "a" || ch == "e" || ch == "i" || ch == "o" || ch == "u" || ch == "y");
}

function _gmls_get_r1(str) {
        var i, found_vowel = false;
        for (i = 1; i <= string_length(str); i++) {
            var ch = string_char_at(str, i);
            if (_gmls_is_vowel(ch)) {
                found_vowel = true;
            } else if (found_vowel && !_gmls_is_vowel(ch)) {
                return string_copy(str, i + 1, string_length(str) - i);
            }
        }
        return "";
}

function _gmls_get_r2(str) {
        var r1 = _gmls_get_r1(str);
        if (string_length(r1) <= 1) return "";
        var i, found_vowel = false;
        for (i = 1; i <= string_length(r1); i++) {
            var ch = string_char_at(r1, i);
            if (_gmls_is_vowel(ch)) {
                found_vowel = true;
            } else if (found_vowel && !_gmls_is_vowel(ch)) {
                return string_copy(r1, i + 1, string_length(r1) - i);
            }
        }
        return "";
}

function _gmls_ends_with(str, suffix) {
        return string_pos(suffix, str) == string_length(str) - string_length(suffix) + 1;
}

function _gmls_replace_suffix(str, old_suffix, new_suffix) {
        if (_gmls_ends_with(str, old_suffix)) {
            return string_copy(str, 1, string_length(str) - string_length(old_suffix)) + new_suffix;
        }
        return str;
}

function _gmls_handle_irregulars(word) {
    // irregular plural forms
    static irregulars = undefined;
    if (is_undefined(irregulars)) {
        irregulars = ds_map_create();
        ds_map_add(irregulars, "mice", "mouse");
        ds_map_add(irregulars, "lice", "louse");
        ds_map_add(irregulars, "geese", "goose");
        ds_map_add(irregulars, "teeth", "tooth");
        ds_map_add(irregulars, "feet", "foot");
        ds_map_add(irregulars, "children", "child");
        ds_map_add(irregulars, "oxen", "ox");
        ds_map_add(irregulars, "indices", "index");
        ds_map_add(irregulars, "appendices", "appendix");
        ds_map_add(irregulars, "criteria", "criterion");
        ds_map_add(irregulars, "phenomena", "phenomenon");
        ds_map_add(irregulars, "data", "datum");
        ds_map_add(irregulars, "media", "medium");
        ds_map_add(irregulars, "analyses", "analysis");
        ds_map_add(irregulars, "diagnoses", "diagnosis");
        ds_map_add(irregulars, "theses", "thesis");
        ds_map_add(irregulars, "men", "man");
        ds_map_add(irregulars, "women", "woman");
        ds_map_add(irregulars, "people", "person");

        // past tense
        ds_map_add(irregulars, "ran", "run");
        ds_map_add(irregulars, "went", "go");
        ds_map_add(irregulars, "saw", "see");
        ds_map_add(irregulars, "ate", "eat");
        ds_map_add(irregulars, "gave", "give");
        ds_map_add(irregulars, "took", "take");
        ds_map_add(irregulars, "came", "come");
        ds_map_add(irregulars, "became", "become");
        ds_map_add(irregulars, "began", "begin");
        ds_map_add(irregulars, "drank", "drink");
        ds_map_add(irregulars, "sang", "sing");
        ds_map_add(irregulars, "rang", "ring");
        ds_map_add(irregulars, "swam", "swim");
        ds_map_add(irregulars, "froze", "freeze");
        ds_map_add(irregulars, "spoke", "speak");
        ds_map_add(irregulars, "broke", "break");
        ds_map_add(irregulars, "chose", "choose");
        ds_map_add(irregulars, "drove", "drive");
        ds_map_add(irregulars, "wrote", "write");
        ds_map_add(irregulars, "rose", "rise");
        ds_map_add(irregulars, "shook", "shake");
        ds_map_add(irregulars, "tore", "tear");
        ds_map_add(irregulars, "wore", "wear");
        ds_map_add(irregulars, "bore", "bear");
        ds_map_add(irregulars, "stole", "steal");
        ds_map_add(irregulars, "got", "get");
        ds_map_add(irregulars, "forgot", "forget");
        ds_map_add(irregulars, "shot", "shoot");
        ds_map_add(irregulars, "lit", "light");
        ds_map_add(irregulars, "bled", "bleed");
        ds_map_add(irregulars, "fed", "feed");
        ds_map_add(irregulars, "met", "meet");
        ds_map_add(irregulars, "led", "lead");
        ds_map_add(irregulars, "read", "read");
        ds_map_add(irregulars, "sped", "speed");
    }

    var lower = string_lower(word);
    if (ds_map_exists(irregulars, lower)) {
        return ds_map_find_value(irregulars, lower);
    }
    return word;
}

function _gmls_stemmer(word) {
    if (string_length(word) <= 2) return word;
    
    var irregular_check = _gmls_handle_irregulars(word);
    if (irregular_check != word) return irregular_check;
    
    var original = word;
    var lower = string_lower(word);
    var len = string_length(lower);
    
    if (string_pos("'s'", lower) > 0 || string_pos("'s", lower) > 0) {
        lower = string_replace_all(lower, "'s'", "");
        lower = string_replace_all(lower, "'s", "");
        len = string_length(lower);
    }
    if (string_pos("'", lower) > 0) {
        lower = string_replace_all(lower, "'", "");
        len = string_length(lower);
    }
    
    if (_gmls_ends_with(lower, "sses")) {
        lower = _gmls_replace_suffix(lower, "sses", "ss");
    } else if (_gmls_ends_with(lower, "ies")) {
        lower = _gmls_replace_suffix(lower, "ies", "i");
    } else if (_gmls_ends_with(lower, "ss")) {
        // keep
    } else if (_gmls_ends_with(lower, "s")) {
        lower = _gmls_replace_suffix(lower, "s", "");
    }
    
    var prev_lower = lower;
    if (_gmls_ends_with(lower, "eed")) {
        if (string_length(_gmls_get_r1(lower)) >= 1) {
            lower = _gmls_replace_suffix(lower, "eed", "ee");
        }
    } else if (_gmls_ends_with(lower, "ed")) {
        lower = _gmls_replace_suffix(lower, "ed", "");
        var stem = lower;
        var has_vowel = false;
        for (var i = 1; i <= string_length(stem); i++) {
            if (_gmls_is_vowel(string_char_at(stem, i))) {
                has_vowel = true;
                break;
            }
        }
        if (!has_vowel) lower = prev_lower;
        else {
            if (_gmls_ends_with(lower, "at") || _gmls_ends_with(lower, "bl") || _gmls_ends_with(lower, "iz")) { // double consts
                lower += "e";
            } else {
                var last_char = string_char_at(lower, string_length(lower));
                var prev_char = string_char_at(lower, string_length(lower) - 1);
                if (last_char == prev_char && last_char != "l" && last_char != "s" && last_char != "z") {
                    lower = string_copy(lower, 1, string_length(lower) - 1);
                } else {
                    var r1 = _gmls_get_r1(lower);
                    if (string_length(r1) >= 1 && (_gmls_ends_with(lower, "y") || 
                        (!_gmls_is_vowel(string_char_at(lower, string_length(lower))) && 
                         string_length(lower) >= 3 && 
                         !_gmls_is_vowel(string_char_at(lower, string_length(lower)-1)) && 
                         string_char_at(lower, string_length(lower)-2) != string_char_at(lower, string_length(lower)-1)))) {
                        // correct
                    }
                }
            }
        }
    } else if (_gmls_ends_with(lower, "ing")) {
        lower = _gmls_replace_suffix(lower, "ing", "");
        var stem = lower;
        var has_vowel = false;
        for (var i = 1; i <= string_length(stem); i++) {
            if (_gmls_is_vowel(string_char_at(stem, i))) {
                has_vowel = true;
                break;
            }
        }
        if (!has_vowel) lower = prev_lower;
        else {
            if (_gmls_ends_with(lower, "at") || _gmls_ends_with(lower, "bl") || _gmls_ends_with(lower, "iz")) { // for -ing
                lower += "e";
            } else {
                var last_char = string_char_at(lower, string_length(lower));
                var prev_char = string_char_at(lower, string_length(lower) - 1);
                if (last_char == prev_char && last_char != "l" && last_char != "s" && last_char != "z") {
                    lower = string_copy(lower, 1, string_length(lower) - 1);
                }
            }
        }
    }
    
    if (_gmls_ends_with(lower, "y") && string_length(lower) > 1) {
        var before_y = string_char_at(lower, string_length(lower) - 1);
        if (!_gmls_is_vowel(before_y)) {
            lower = _gmls_replace_suffix(lower, "y", "i");
        }
    }
    
    var suffixes2 = [ // complete list?
        "ational", "tional", "enci", "anci", "izer", "abli", "alli", 
        "entli", "eli", "ousli", "ization", "isation", "ation", "ator", 
        "alism", "iveness", "fulness", "ousness", "aliti", "iviti", 
        "biliti", "logi", "ance", "ence", "able", "ible", "ment"
    ];
    var replacements2 = [ // complete list?
        "ate", "tion", "ence", "ance", "ize", "able", "al", 
        "ent", "e", "ous", "ize", "ize", "ate", "ate", 
        "al", "ive", "ful", "ous", "al", "ive", 
        "ble", "log", "ance", "ence", "able", "ible", "ment"
    ];
    
    for (var i = 0; i < array_length(suffixes2); i++) {
        if (_gmls_ends_with(lower, suffixes2[i])) {
            var r1 = _gmls_get_r1(lower);
            if (string_length(r1) >= string_length(suffixes2[i])) {
                lower = _gmls_replace_suffix(lower, suffixes2[i], replacements2[i]);
                break;
            }
        }
    }
    
    var suffixes3 = [ // complete list?
        "icate", "ative", "alize", "alise", "iciti", "ical", 
        "ful", "ness", "ional", "tion", "ence", "ance", "ment"
    ];
    var replacements3 = [ // complete list?
        "ic", "", "al", "al", "ic", "ic", 
        "", "", "ion", "tion", "ence", "ance", "ment"
    ];
    
    for (var i = 0; i < array_length(suffixes3); i++) {
        if (_gmls_ends_with(lower, suffixes3[i])) {
            var r1 = _gmls_get_r1(lower);
            if (string_length(r1) >= string_length(suffixes3[i])) {
                lower = _gmls_replace_suffix(lower, suffixes3[i], replacements3[i]);
                break;
            }
        }
    }
    
    var endings4 = [ // complete list?
        "al", "ance", "ence", "er", "ic", "able", "ible", 
        "ant", "ement", "ment", "ent", "ion", "ou", "ism", 
        "ate", "iti", "ous", "ive", "ize", "ise", "tion", 
        "ance", "ence", "ment", "ness", "ful", "ive", "ous"
    ];
    
    for (var i = 0; i < array_length(endings4); i++) {
        if (_gmls_ends_with(lower, endings4[i])) {
            var r2 = _gmls_get_r2(lower);
            if (string_length(r2) >= string_length(endings4[i])) {
                lower = _gmls_replace_suffix(lower, endings4[i], "");
                break;
            }
        }
    }
    
    if (_gmls_ends_with(lower, "ion")) {
        var r2 = _gmls_get_r2(lower);
        if (string_length(r2) >= 3) {
            var stem = string_copy(lower, 1, string_length(lower) - 3);
            var last = string_char_at(stem, string_length(stem));
            if (last == "s" || last == "t") {
                lower = stem;
            }
        }
    }
    
    if (_gmls_ends_with(lower, "e")) {
        var r2 = _gmls_get_r2(lower);
        var r1 = _gmls_get_r1(lower);
        if (string_length(r2) >= 1) {
            lower = _gmls_replace_suffix(lower, "e", "");
        } else if (string_length(r1) >= 1) {
            var stem = _gmls_replace_suffix(lower, "e", "");
            var last_consonant = false;
            var last_char = string_char_at(stem, string_length(stem));
            if (!_gmls_is_vowel(last_char)) {
                var prev_char = string_char_at(stem, string_length(stem) - 1);
                if (!_gmls_is_vowel(prev_char)) {
                    last_consonant = true;
                }
            }
            if (!last_consonant) {
                lower = stem;
            }
        }
    }
    
    if (_gmls_ends_with(lower, "l") && _gmls_get_r2(lower) != "") {
        var prev_char = string_char_at(lower, string_length(lower) - 1);
        if (prev_char == "l") {
            lower = _gmls_replace_suffix(lower, "l", "");
        }
    }
    
    var final_suffixes = ["ization", "ification", "ation", "ment", "ness", "ful", "ive", "ous"];
    for (var i = 0; i < array_length(final_suffixes); i++) {
        if (_gmls_ends_with(lower, final_suffixes[i])) {
            lower = _gmls_replace_suffix(lower, final_suffixes[i], "");
            break;
        }
    }
    
    if (string_length(lower) == 0) lower = original;
    
    return lower;
}