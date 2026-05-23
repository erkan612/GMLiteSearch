gmui_init();
gmls_init();

// STEP 1: ADD DOCUMENTS WITH FACETS, GEOLOCATION, AND GAME COORDINATES

var _games = [
    { id: "game1", name: "Dragon Fantasy", 
      text: "Epic fantasy RPG with dragons, magic spells, and huge open world.",
      category: "rpg", tags: ["fantasy", "dragons", "magic"], platform: "pc", price: 59.99, year: 2024,
      lat: 40.7128, lng: -74.0060, game_x: 150, game_y: 200, game_z: 0, popularity: 95 },
      
    { id: "game2", name: "Cyber Shooter", 
      text: "Fast-paced multiplayer FPS with futuristic weapons and cyberpunk aesthetic.",
      category: "action", tags: ["shooter", "multiplayer", "cyberpunk"], platform: "pc", price: 49.99, year: 2023,
      lat: 40.7135, lng: -74.0070, game_x: 500, game_y: 300, game_z: 5, popularity: 88 },
      
    { id: "game3", name: "Mystery Mansion", 
      text: "Adventure puzzle game set in haunted mansion. Solve mysteries.",
      category: "adventure", tags: ["puzzle", "mystery", "horror"], platform: "console", price: 39.99, year: 2024,
      lat: 40.7140, lng: -74.0080, game_x: 300, game_y: 400, game_z: 2, popularity: 72 },
      
    { id: "game4", name: "Strategy Legends", 
      text: "Deep turn-based strategy game with resource management.",
      category: "strategy", tags: ["turn-based", "management"], platform: "pc", price: 44.99, year: 2022,
      lat: 40.7150, lng: -74.0090, game_x: 700, game_y: 500, game_z: 10, popularity: 68 },
      
    { id: "game5", name: "Magic Cards", 
      text: "Fantasy card game with magic spells and mythical creatures.",
      category: "card", tags: ["fantasy", "cards", "multiplayer"], platform: "mobile", price: 9.99, year: 2024,
      lat: 40.7160, lng: -74.0100, game_x: 250, game_y: 180, game_z: 0, popularity: 91 },
      
    { id: "game6", name: "Space Explorer", 
      text: "Open world space exploration game. Discover planets.",
      category: "adventure", tags: ["space", "exploration"], platform: "pc", price: 59.99, year: 2024,
      lat: 40.7110, lng: -74.0040, game_x: 600, game_y: 350, game_z: 8, popularity: 85 },
      
    { id: "game7", name: "Physics Platformer", 
      text: "Challenging platformer with realistic physics puzzles.",
      category: "action", tags: ["platformer", "physics"], platform: "switch", price: 29.99, year: 2023,
      lat: 40.7120, lng: -74.0050, game_x: 400, game_y: 250, game_z: 3, popularity: 79 },
      
    { id: "game8", name: "RPG Dungeons", 
      text: "Classic dungeon crawler RPG with character customization.",
      category: "rpg", tags: ["dungeon", "loot", "fantasy"], platform: "pc", price: 34.99, year: 2023,
      lat: 40.7130, lng: -74.0065, game_x: 200, game_y: 220, game_z: 1, popularity: 82 }
];

for (var i = 0; i < array_length(_games); i++) {
    var _g = _games[i];
    var _facets = {
        category: _g.category,
        tags: _g.tags,
        platform: _g.platform,
        price: _g.price,
        year: _g.year
    };
    
    gmls_add_document_faceted(_g.id, _g.text, _facets, { title: _g.name, timestamp: current_time - (_g.year - 2020) * 86400000 });
    gmls_add_geolocation(_g.id, _g.lat, _g.lng, 6);
    gmls_add_range_facet(_g.id, "price", _g.price);
    gmls_add_location_2d(_g.id, _g.game_x, _g.game_y);
    gmls_add_location_3d(_g.id, _g.game_x, _g.game_y, _g.game_z);
    gmls_add_location_grid(_g.id, _g.game_x, _g.game_y, 200);
    
    for (var c = 0; c < _g.popularity / 10; c++) {
        gmls_add_training_example(_g.name, _g.id, _g.popularity / 100);
        gmls_add_training_example(_g.category, _g.id, _g.popularity / 100);
        for (var t = 0; t < array_length(_g.tags); t++) {
            gmls_add_training_example(_g.tags[t], _g.id, _g.popularity / 100);
        }
    }
}

show_debug_message("============================================================");
show_debug_message("GMLITESEARCH - COMPLETE DEMONSTRATION");
show_debug_message("============================================================");
show_debug_message("");
show_debug_message("[SETUP] Added " + string(array_length(_games)) + " documents with facets, geolocation, and game coordinates");
show_debug_message("[SETUP] Added " + string(ds_list_size(global.gmls.ltr_training_data)) + " LTR training examples");
show_debug_message("");

// STEP 2: CORE SEARCH (BM25)

show_debug_message("------------------------------------------------------------");
show_debug_message("1. CORE SEARCH (BM25)");
show_debug_message("------------------------------------------------------------");

var _results = gmls_search("fantasy rpg", -1);
show_debug_message("Query: 'fantasy rpg' -> " + string(array_length(_results)) + " results");
for (var i = 0; i < min(3, array_length(_results)); i++) {
    show_debug_message("  " + string(i+1) + ". " + _results[i].document.metadata.title + " (score: " + string(_results[i].score) + ")");
}
show_debug_message("");

// STEP 3: FACETED SEARCH

show_debug_message("------------------------------------------------------------");
show_debug_message("2. FACETED SEARCH");
show_debug_message("------------------------------------------------------------");

var _facet_counts = gmls_get_facet_counts("", undefined, ["category"]);
show_debug_message("All documents - Category counts:");
var _cats = _facet_counts[$ "category"];
var _cat_names = variable_struct_get_names(_cats);
for (var i = 0; i < array_length(_cat_names); i++) {
    show_debug_message("  " + _cat_names[i] + ": " + string(_cats[$ _cat_names[i]]));
}

gmls_add_facet_filter("category", "rpg");
show_debug_message("");
show_debug_message("Filtered: category='rpg'");
var _faceted_results = gmls_search_faceted("", -1, ["category"]);
show_debug_message("  Results: " + string(_faceted_results.total) + " games");
for (var i = 0; i < array_length(_faceted_results.results); i++) {
    show_debug_message("  - " + _faceted_results.results[i].document.metadata.title);
}

gmls_clear_facet_filters();
show_debug_message("");

// STEP 4: GEOSPATIAL SEARCH (Real World Coordinates)

show_debug_message("------------------------------------------------------------");
show_debug_message("3. GEOSPATIAL SEARCH (Real World - Lat/Lng)");
show_debug_message("------------------------------------------------------------");

var _user_location = { lat: 40.7130, lng: -74.0065 };
show_debug_message("User location: " + string(_user_location.lat) + ", " + string(_user_location.lng));

var _nearby = gmls_get_nearest(_user_location.lat, _user_location.lng, 3);
show_debug_message("Nearest 3 games:");
for (var i = 0; i < array_length(_nearby); i++) {
    show_debug_message("  " + string(i+1) + ". " + _nearby[i].document.metadata.title + " (" + string(_nearby[i].distance) + " km)");
}
show_debug_message("");

// STEP 5: GAME COORDINATES SEARCH (2D)

show_debug_message("------------------------------------------------------------");
show_debug_message("4. GAME COORDINATES SEARCH (2D)");
show_debug_message("------------------------------------------------------------");

var _player_2d = { x: 200, y: 210 };
show_debug_message("Player position: (" + string(_player_2d.x) + ", " + string(_player_2d.y) + ")");

var _nearby_2d = gmls_search_nearby_2d(_player_2d.x, _player_2d.y, 100, "", 5);
show_debug_message("Objects within 100 units:");
for (var i = 0; i < array_length(_nearby_2d); i++) {
    show_debug_message("  " + string(i+1) + ". " + _nearby_2d[i].document.metadata.title + " (distance: " + string(_nearby_2d[i].distance) + " units)");
}

var _nearby_2d_filtered = gmls_search_nearby_2d(_player_2d.x, _player_2d.y, 150, "fantasy", 5);
show_debug_message("");
show_debug_message("Objects within 150 units matching 'fantasy':");
for (var i = 0; i < array_length(_nearby_2d_filtered); i++) {
    show_debug_message("  " + string(i+1) + ". " + _nearby_2d_filtered[i].document.metadata.title + " (distance: " + string(_nearby_2d_filtered[i].distance) + ")");
}
show_debug_message("");

// STEP 6: GAME COORDINATES SEARCH (3D)

show_debug_message("------------------------------------------------------------");
show_debug_message("5. GAME COORDINATES SEARCH (3D)");
show_debug_message("------------------------------------------------------------");

var _player_3d = { x: 300, y: 400, z: 2 };
show_debug_message("Player position: (" + string(_player_3d.x) + ", " + string(_player_3d.y) + ", " + string(_player_3d.z) + ")");

var _nearby_3d = gmls_search_nearby_3d(_player_3d.x, _player_3d.y, _player_3d.z, 150, "", 5);
show_debug_message("Objects within 150 units (3D):");
for (var i = 0; i < array_length(_nearby_3d); i++) {
    show_debug_message("  " + string(i+1) + ". " + _nearby_3d[i].document.metadata.title + " (distance: " + string(_nearby_3d[i].distance) + ")");
}
show_debug_message("");

// STEP 7: GAME COORDINATES SEARCH (Grid Optimized)

show_debug_message("------------------------------------------------------------");
show_debug_message("6. GAME COORDINATES SEARCH (Grid Optimized)");
show_debug_message("------------------------------------------------------------");

var _player_grid = { x: 200, y: 210 };
show_debug_message("Player position: (" + string(_player_grid.x) + ", " + string(_player_grid.y) + ")");
show_debug_message("Cell size: 200 units");

var _nearby_grid = gmls_search_nearby_grid(_player_grid.x, _player_grid.y, 250, 200, "", 5);
show_debug_message("Objects within 250 units (using grid index):");
for (var i = 0; i < array_length(_nearby_grid); i++) {
    show_debug_message("  " + string(i+1) + ". " + _nearby_grid[i].document.metadata.title + " (distance: " + string(_nearby_grid[i].distance) + ", cell: " + _nearby_grid[i].cell + ")");
}
show_debug_message("");

// STEP 8: LEARNING-TO-RANK

show_debug_message("------------------------------------------------------------");
show_debug_message("7. LEARNING-TO-RANK");
show_debug_message("------------------------------------------------------------");

show_debug_message("Training LTR model on " + string(ds_list_size(global.gmls.ltr_training_data)) + " examples...");
gmls_enable_ltr(true);
gmls_train_linear_model(30, 0.005);

var _stats = gmls_get_ltr_stats();
show_debug_message("");
show_debug_message("Trained feature weights:");
var _weights = _stats.feature_weights;
var _weight_names = variable_struct_get_names(_weights);
for (var i = 0; i < array_length(_weight_names); i++) {
    show_debug_message("  " + _weight_names[i] + ": " + string(_weights[$ _weight_names[i]]));
}
show_debug_message("");

// STEP 9: ADVANCED SNIPPETS

show_debug_message("------------------------------------------------------------");
show_debug_message("8. ADVANCED SNIPPETS");
show_debug_message("------------------------------------------------------------");

gmls_configure_snippets({
    highlight_start: "[",
    highlight_end: "]",
    strategy: "best_fragment",
    default_length: 150
});

var _snippet_results = gmls_search_with_snippets("magic dragons", 3);
for (var i = 0; i < array_length(_snippet_results); i++) {
    show_debug_message("");
    show_debug_message("  " + string(i+1) + ". " + _snippet_results[i].highlighted_title);
    show_debug_message("     " + _snippet_results[i].snippet);
}
show_debug_message("");

// STEP 10: FINAL STATISTICS

show_debug_message("------------------------------------------------------------");
show_debug_message("9. FINAL STATISTICS");
show_debug_message("------------------------------------------------------------");

var _main_stats = gmls_get_stats();
var _geo_stats = gmls_get_geo_stats();
var _ltr_stats = gmls_get_ltr_stats();

show_debug_message("[DOCUMENTS] " + string(_main_stats.document_count));
show_debug_message("[UNIQUE WORDS] " + string(_main_stats.unique_words));
show_debug_message("[FACETS INDEXED] " + string(ds_map_size(global.gmls.facet_index)));
show_debug_message("[GEOTAGGED LOCATIONS] " + string(_geo_stats.total_locations));
show_debug_message("[LTR EXAMPLES] " + string(_ltr_stats.training_examples));
show_debug_message("[SNIPPET STRATEGY] " + global.gmls.snippet_config.strategy);

show_debug_message("");
show_debug_message("============================================================");
show_debug_message("GMLITESEARCH DEMO COMPLETED SUCCESSFULLY");
show_debug_message("============================================================");

/*
gmls_set_config(false, false, 4);

// Document 1-10: Health & Wellness
gmls_add_document("doc_001", "Drinking enough water is essential for maintaining good health and energy levels", {
    title: "Hydration Importance",
    tags: ["health", "water", "hydration", "wellness"],
});

gmls_add_document("doc_002", "Regular exercise improves cardiovascular health and mental wellbeing", {
    title: "Exercise Benefits",
    tags: ["fitness", "exercise", "health", "cardio"],
});

gmls_add_document("doc_003", "Getting 7-9 hours of sleep each night is crucial for brain function", {
    title: "Sleep Guidelines",
    tags: ["sleep", "rest", "recovery", "brain"],
});

gmls_add_document("doc_004", "Meditation reduces stress and increases mindfulness in daily life", {
    title: "Meditation Practice",
    tags: ["meditation", "mindfulness", "stress", "calm"],
});

gmls_add_document("doc_005", "Eating a balanced diet with fruits and vegetables provides essential nutrients", {
    title: "Nutrition Basics",
    tags: ["diet", "nutrition", "food", "health"],
});

gmls_add_document("doc_006", "Walking 10,000 steps daily improves circulation and overall fitness", {
    title: "Daily Walking Goal",
    tags: ["walking", "steps", "activity", "fitness"],
});

gmls_add_document("doc_007", "Stretching regularly prevents muscle stiffness and improves flexibility", {
    title: "Stretching Routine",
    tags: ["stretching", "flexibility", "muscle", "warmup"],
});

gmls_add_document("doc_008", "Annual checkups help detect health issues before they become serious", {
    title: "Health Checkups",
    tags: ["doctor", "checkup", "prevention", "health"],
});

gmls_add_document("doc_009", "Limiting screen time before bed improves sleep quality", {
    title: "Screen Time Management",
    tags: ["screen", "sleep", "digital", "rest"],
});

gmls_add_document("doc_010", "Vitamin D from sunlight is important for bone health and mood", {
    title: "Sunlight Benefits",
    tags: ["sunlight", "vitamin D", "mood", "health"],
});

// Document 11-20: Personal Finance
gmls_add_document("doc_011", "Creating a monthly budget helps track income and expenses effectively", {
    title: "Budget Planning",
    tags: ["budget", "finance", "money", "planning"],
});

gmls_add_document("doc_012", "Emergency funds should cover 3-6 months of living expenses", {
    title: "Emergency Savings",
    tags: ["savings", "emergency", "security", "money"],
});

gmls_add_document("doc_013", "Investing early takes advantage of compound interest over time", {
    title: "Early Investing",
    tags: ["investing", "compound", "interest", "growth"],
});

gmls_add_document("doc_014", "Paying off high-interest debt quickly saves money in the long run", {
    title: "Debt Management",
    tags: ["debt", "payment", "interest", "finance"],
});

gmls_add_document("doc_015", "Retirement planning should start as early as possible", {
    title: "Retirement Planning",
    tags: ["retirement", "planning", "future", "savings"],
});

gmls_add_document("doc_016", "Credit scores affect loan approvals and interest rates", {
    title: "Credit Score Importance",
    tags: ["credit", "score", "loan", "finance"],
});

gmls_add_document("doc_017", "Insurance protects against unexpected financial losses", {
    title: "Insurance Basics",
    tags: ["insurance", "protection", "risk", "finance"],
});

gmls_add_document("doc_018", "Tax planning can help maximize deductions and refunds", {
    title: "Tax Strategies",
    tags: ["tax", "planning", "deduction", "finance"],
});

gmls_add_document("doc_019", "Avoiding impulse purchases helps maintain financial discipline", {
    title: "Spending Control",
    tags: ["spending", "impulse", "discipline", "money"],
});

gmls_add_document("doc_020", "Diversifying investments reduces risk in financial portfolios", {
    title: "Investment Diversification",
    tags: ["investment", "diversify", "risk", "portfolio"],
});

// Document 21-30: Relationships & Social
gmls_add_document("doc_021", "Active listening improves communication in all relationships", {
    title: "Communication Skills",
    tags: ["listening", "communication", "relationship", "social"],
});

gmls_add_document("doc_022", "Setting boundaries is important for healthy personal relationships", {
    title: "Personal Boundaries",
    tags: ["boundaries", "relationship", "health", "personal"],
});

gmls_add_document("doc_023", "Expressing gratitude regularly strengthens connections with others", {
    title: "Gratitude Practice",
    tags: ["gratitude", "thankful", "relationship", "positive"],
});

gmls_add_document("doc_024", "Conflict resolution skills help maintain harmony in relationships", {
    title: "Conflict Resolution",
    tags: ["conflict", "resolution", "relationship", "problem"],
});

gmls_add_document("doc_025", "Making time for friends and family improves social wellbeing", {
    title: "Social Connections",
    tags: ["friends", "family", "social", "connection"],
});

gmls_add_document("doc_026", "Learning to say no protects personal time and energy", {
    title: "Saying No Politely",
    tags: ["boundaries", "time", "energy", "personal"],
});

gmls_add_document("doc_027", "Apologizing sincerely repairs trust after misunderstandings", {
    title: "Sincere Apologies",
    tags: ["apology", "trust", "relationship", "repair"],
});

gmls_add_document("doc_028", "Supporting others during difficult times builds strong bonds", {
    title: "Supporting Others",
    tags: ["support", "help", "friendship", "care"],
});

gmls_add_document("doc_029", "Meeting new people expands social circles and perspectives", {
    title: "Meeting New People",
    tags: ["social", "new", "people", "network"],
});

gmls_add_document("doc_030", "Quality time is more important than quantity in relationships", {
    title: "Quality Time",
    tags: ["time", "quality", "relationship", "attention"],
});

// Document 31-40: Learning & Productivity
gmls_add_document("doc_031", "The Pomodoro technique improves focus by working in timed intervals", {
    title: "Pomodoro Technique",
    tags: ["productivity", "focus", "time", "work"],
});

gmls_add_document("doc_032", "Taking regular breaks prevents burnout and maintains productivity", {
    title: "Break Importance",
    tags: ["break", "rest", "productivity", "work"],
});

gmls_add_document("doc_033", "Goal setting provides direction and motivation for achievement", {
    title: "Goal Setting",
    tags: ["goal", "planning", "achievement", "motivation"],
});

gmls_add_document("doc_034", "Reading daily expands knowledge and improves vocabulary", {
    title: "Daily Reading Habit",
    tags: ["reading", "learning", "knowledge", "habit"],
});

gmls_add_document("doc_035", "Journaling helps organize thoughts and track personal growth", {
    title: "Journaling Benefits",
    tags: ["journal", "writing", "reflection", "growth"],
});

gmls_add_document("doc_036", "Learning a new language improves cognitive abilities and cultural understanding", {
    title: "Language Learning",
    tags: ["language", "learning", "cognitive", "culture"],
});

gmls_add_document("doc_037", "Time blocking schedules specific tasks for specific times", {
    title: "Time Blocking Method",
    tags: ["time", "schedule", "planning", "productivity"],
});

gmls_add_document("doc_038", "Digital detox periods improve focus and reduce anxiety", {
    title: "Digital Detox",
    tags: ["digital", "detox", "focus", "anxiety"],
});

gmls_add_document("doc_039", "Mind mapping organizes ideas visually for better understanding", {
    title: "Mind Mapping",
    tags: ["ideas", "visual", "organization", "planning"],
});

gmls_add_document("doc_040", "Continuous learning keeps skills relevant in changing job markets", {
    title: "Lifelong Learning",
    tags: ["learning", "skills", "career", "growth"],
});

// Document 41-50: Lifestyle & Hobbies
gmls_add_document("doc_041", "Gardening reduces stress and provides fresh produce", {
    title: "Gardening Benefits",
    tags: ["gardening", "plants", "stress", "hobby"],
});

gmls_add_document("doc_042", "Cooking at home saves money and improves nutrition", {
    title: "Home Cooking",
    tags: ["cooking", "food", "home", "savings"],
});

gmls_add_document("doc_043", "Traveling broadens perspectives and creates lasting memories", {
    title: "Travel Experiences",
    tags: ["travel", "experience", "culture", "memory"],
});

gmls_add_document("doc_044", "Photography captures moments and develops artistic skills", {
    title: "Photography Hobby",
    tags: ["photography", "art", "memory", "creative"],
});

gmls_add_document("doc_045", "Music listening reduces stress and improves mood", {
    title: "Music Therapy",
    tags: ["music", "therapy", "mood", "stress"],
});

gmls_add_document("doc_046", "Volunteering provides purpose and helps communities", {
    title: "Volunteer Work",
    tags: ["volunteer", "community", "purpose", "help"],
});

gmls_add_document("doc_047", "Decluttering living spaces reduces stress and improves focus", {
    title: "Decluttering Home",
    tags: ["declutter", "organization", "space", "stress"],
});

gmls_add_document("doc_048", "Nature walks improve mental health and physical fitness", {
    title: "Nature Walks",
    tags: ["nature", "walk", "mental", "fitness"],
});

gmls_add_document("doc_049", "Art creation expresses emotions and develops creativity", {
    title: "Art Expression",
    tags: ["art", "creative", "expression", "emotion"],
});

gmls_add_document("doc_050", "Morning routines set positive tone for the entire day", {
    title: "Morning Routine",
    tags: ["morning", "routine", "productivity", "day"],
});