// GMLiteSearch Tutorial - Chapter 6 Dataset
// Two datasets for two coordinate systems:
//   1. 40 real-world points of interest with genuine NYC-area lat/lng
//   2. 51 game-world objects placed at arbitrary x/y/z coordinates
// Used throughout Chapter 6 to demonstrate real-world (Haversine-based)
// and game-world (Euclidean-based) geospatial search, plus geohashing.
//
// Usage (real-world):
//   var pois = chapter6_get_pois();
//   for (var i = 0; i < array_length(pois); i++) {
//       var p = pois[i];
//       gmls_add_document_weighted(p.id, p.desc, { title: p.name, tags: [], timestamp: current_time });
//       gmls_add_geolocation(p.id, p.lat, p.lng, 6);
//   }
//
// Usage (game-world):
//   var objects = chapter6_get_gameworld_objects();
//   for (var i = 0; i < array_length(objects); i++) {
//       var o = objects[i];
//       gmls_add_document_weighted(o.id, o.desc, { title: o.name, tags: [], timestamp: current_time });
//       gmls_add_location_2d(o.id, o.x, o.y);
//   }

function chapter6_get_pois() {
    return [
        { id: "poi_001", name: "Ironhold Trading Post", desc: "A busy general store selling adventuring supplies near the old clock tower.", lat: 40.7128, lng: -74.006 },
        { id: "poi_002", name: "The Rusty Anchor Tavern", desc: "A dockside tavern popular with sailors and traveling merchants.", lat: 40.7061, lng: -74.0087 },
        { id: "poi_003", name: "Millhaven Apothecary", desc: "A small shop stocked with herbs, tonics, and remedies.", lat: 40.718, lng: -74.002 },
        { id: "poi_004", name: "Grand Central Armory", desc: "A well-stocked weapons and armor shop near the transit hub.", lat: 40.7527, lng: -73.9772 },
        { id: "poi_005", name: "Riverside Fishmonger", desc: "Fresh catch sold daily along the eastern riverbank.", lat: 40.7069, lng: -73.995 },
        { id: "poi_006", name: "Stonebridge Smithy", desc: "A blacksmith's forge known for quality tools and horseshoes.", lat: 40.7295, lng: -73.9965 },
        { id: "poi_007", name: "The Gilded Quill Bookshop", desc: "A cozy bookshop specializing in maps and old manuscripts.", lat: 40.7359, lng: -73.9911 },
        { id: "poi_008", name: "Harbor View Inn", desc: "A comfortable inn with a view of the harbor, popular with travelers.", lat: 40.7009, lng: -74.0154 },
        { id: "poi_009", name: "Copperfield Jewelers", desc: "Fine jewelry crafted from gems sourced across the region.", lat: 40.7484, lng: -73.9857 },
        { id: "poi_010", name: "Old Mill Bakery", desc: "A family-run bakery famous for its sourdough and pastries.", lat: 40.7411, lng: -74.0018 },
        { id: "poi_011", name: "Thistledown Herbalist", desc: "A quiet shop selling rare plants and homemade tinctures.", lat: 40.7196, lng: -73.9873 },
        { id: "poi_012", name: "The Wandering Cartographer", desc: "A map shop known for detailed surveys of the surrounding region.", lat: 40.7306, lng: -73.9866 },
        { id: "poi_013", name: "Brightwater Fountain Square", desc: "A public square with a large fountain, popular meeting spot.", lat: 40.7143, lng: -74.0089 },
        { id: "poi_014", name: "Ferrous Row Foundry", desc: "An industrial foundry producing metal goods for the whole district.", lat: 40.7075, lng: -74.0113 },
        { id: "poi_015", name: "Willowbrook Tea House", desc: "A peaceful tea house tucked away near the botanical gardens.", lat: 40.7218, lng: -73.9973 },
        { id: "poi_016", name: "The Salted Rope Chandlery", desc: "A shop selling rope, sailcloth, and other ship supplies.", lat: 40.7038, lng: -74.0176 },
        { id: "poi_017", name: "Emberlight Candle Works", desc: "Handmade candles crafted from local beeswax.", lat: 40.7267, lng: -74.0058 },
        { id: "poi_018", name: "Duskwood Tannery", desc: "A leather tannery producing goods for saddlers and cobblers.", lat: 40.7328, lng: -74.0043 },
        { id: "poi_019", name: "Greywater Locksmith", desc: "A locksmith and metalworker specializing in secure vaults.", lat: 40.7452, lng: -73.9908 },
        { id: "poi_020", name: "The Silver Compass Outfitters", desc: "An outfitter equipping travelers for long journeys.", lat: 40.7166, lng: -73.9928 },
        { id: "poi_021", name: "Hollowreed Basket Weavers", desc: "A workshop weaving baskets and crates from river reeds.", lat: 40.7099, lng: -73.9899 },
        { id: "poi_022", name: "Northgate Stables", desc: "Stables offering horse boarding and riding lessons.", lat: 40.7502, lng: -73.9934 },
        { id: "poi_023", name: "The Amber Hearth Inn", desc: "A warm, welcoming inn known for its hearty stew.", lat: 40.7241, lng: -74.0104 },
        { id: "poi_024", name: "Cinderpath Forge", desc: "A second smithy specializing in ornamental ironwork.", lat: 40.7383, lng: -73.9954 },
        { id: "poi_025", name: "Marrowbone Butcher Shop", desc: "A butcher shop supplying meat to taverns across the district.", lat: 40.7052, lng: -73.9994 },
        { id: "poi_026", name: "The Cartwright Wheelwright", desc: "A wheelwright repairing carts and wagon wheels.", lat: 40.7189, lng: -74.0141 },
        { id: "poi_027", name: "Silverleaf Perfumery", desc: "A perfumery crafting scents from imported and local ingredients.", lat: 40.7314, lng: -73.9887 },
        { id: "poi_028", name: "The Weathered Sail Shipwright", desc: "A shipwright building and repairing small river vessels.", lat: 40.6998, lng: -74.0129 },
        { id: "poi_029", name: "Goldenrod Apiary", desc: "A beekeeping operation supplying honey to shops across town.", lat: 40.7473, lng: -73.9986 },
        { id: "poi_030", name: "The Quiet Scribe Stationers", desc: "A stationer's shop selling ink, parchment, and sealing wax.", lat: 40.7256, lng: -73.9942 },
        { id: "poi_031", name: "Ashford Millinery", desc: "A hat shop known for both practical and ceremonial headwear.", lat: 40.7112, lng: -74.0031 },
        { id: "poi_032", name: "The Coppersmith's Corner", desc: "A shop specializing in copper cookware and fittings.", lat: 40.7347, lng: -74.0089 },
        { id: "poi_033", name: "Blackthorn Curiosities", desc: "An eccentric shop selling oddities and imported trinkets.", lat: 40.7086, lng: -73.9878 },
        { id: "poi_034", name: "The Millrace Grain Exchange", desc: "A grain market where farmers sell their harvest.", lat: 40.7429, lng: -74.0072 },
        { id: "poi_035", name: "Foxglove Florist", desc: "A flower shop supplying blooms for every occasion.", lat: 40.7203, lng: -74.0007 },
        { id: "poi_036", name: "The Driftwood Carpenter", desc: "A carpenter's workshop building furniture from reclaimed wood.", lat: 40.7157, lng: -73.9962 },
        { id: "poi_037", name: "Ravensworth Gunsmith", desc: "A gunsmith crafting and repairing hunting rifles.", lat: 40.7398, lng: -73.9899 },
        { id: "poi_038", name: "The Hollow Bell Chapel Shop", desc: "A small shop near the chapel selling candles and charms.", lat: 40.7024, lng: -74.0048 },
        { id: "poi_039", name: "Winterset Furrier", desc: "A furrier selling warm clothing for the colder seasons.", lat: 40.7461, lng: -74.0011 },
        { id: "poi_040", name: "The Copper Kettle Brewhouse", desc: "A brewhouse producing ales sold throughout the district.", lat: 40.7178, lng: -74.0134 }
    ];
}

function chapter6_get_gameworld_objects() {
    return [
        { id: "obj_001", name: "Riverside Watchpost", desc: "A wooden watchtower overlooking the river crossing.", x: 1357.1, y: 1679.3, z: 46.2 },
        { id: "obj_002", name: "Old Miner's Camp", desc: "An abandoned mining camp with scattered tools and crates.", x: 1397.0, y: 1523.5, z: 29.4 },
        { id: "obj_003", name: "Cinder Wolf Den", desc: "A cave entrance marked with claw scratches and bones.", x: 554.0, y: 1535.7, z: 31.5 },
        { id: "obj_004", name: "Traveling Merchant Wagon", desc: "A merchant's wagon parked along the trade road.", x: 2378.9, y: 282.4, z: 15.2 },
        { id: "obj_005", name: "Fallen Watchtower", desc: "A collapsed guard tower, now overgrown with vines.", x: 272.0, y: 2428.9, z: 34.7 },
        { id: "obj_006", name: "Hunter's Blind", desc: "A concealed platform used for tracking game.", x: 125.6, y: 2946.6, z: 48.2 },
        { id: "obj_007", name: "Sunken Shrine", desc: "A partially submerged shrine dedicated to a forgotten god.", x: 1961.8, y: 1846.7, z: 7.9 },
        { id: "obj_008", name: "Bandit Lookout", desc: "A rocky outcrop used by bandits to spot travelers.", x: 45.0, y: 1585.1, z: 3.0 },
        { id: "obj_009", name: "Farmstead Ruins", desc: "The remains of a farmhouse destroyed by fire long ago.", x: 570.6, y: 725.8, z: 1.5 },
        { id: "obj_010", name: "Crystal Cave Entrance", desc: "A glowing cave mouth rumored to hold rare crystals.", x: 1391.8, y: 1321.6, z: 42.1 },
        { id: "obj_011", name: "Old Toll Bridge", desc: "A stone bridge where travelers once paid a crossing fee.", x: 1557.4, y: 1920.9, z: 25.0 },
        { id: "obj_012", name: "Ranger Outpost", desc: "A small wooden outpost used by forest rangers.", x: 1987.3, y: 1372.0, z: 13.9 },
        { id: "obj_013", name: "Withered Orchard", desc: "Rows of dead apple trees from a long-forgotten farm.", x: 2993.0, y: 2987.1, z: 42.0 },
        { id: "obj_014", name: "Smuggler's Cove", desc: "A hidden cove used for illicit trade.", x: 2123.4, y: 945.8, z: 11.5 },
        { id: "obj_015", name: "Ancient Standing Stones", desc: "A circle of weathered stones with faded carvings.", x: 867.1, y: 210.7, z: 38.3 },
        { id: "obj_016", name: "Abandoned Windmill", desc: "A windmill with broken blades, creaking in the wind.", x: 1201.2, y: 2539.8, z: 19.3 },
        { id: "obj_017", name: "Wolf Pack Territory", desc: "An area marked by frequent wolf howls at night.", x: 2874.1, y: 2541.9, z: 0.0 },
        { id: "obj_018", name: "Collapsed Mine Shaft", desc: "A dangerous shaft that caved in years ago.", x: 629.2, y: 2730.8, z: 23.5 },
        { id: "obj_019", name: "Fisherman's Dock", desc: "A small dock used by local fishermen.", x: 2941.1, y: 1192.3, z: 3.7 },
        { id: "obj_020", name: "Overgrown Cemetery", desc: "A cemetery reclaimed by moss and wild roots.", x: 1888.4, y: 2335.5, z: 13.5 },
        { id: "obj_021", name: "Trader's Rest Camp", desc: "A common resting spot for traders on the road.", x: 261.4, y: 997.8, z: 48.2 },
        { id: "obj_022", name: "Goblin Warren Entrance", desc: "A crude tunnel entrance marked with goblin totems.", x: 2274.1, y: 354.0, z: 12.3 },
        { id: "obj_023", name: "Ruined Watchfire", desc: "The remains of a signal fire pit atop a hill.", x: 303.1, y: 179.7, z: 39.9 },
        { id: "obj_024", name: "Old Quarry", desc: "An abandoned stone quarry with deep excavation pits.", x: 533.0, y: 1677.9, z: 22.4 },
        { id: "obj_025", name: "Sacred Grove", desc: "A grove of ancient trees said to be protected by spirits.", x: 572.1, y: 2195.7, z: 6.5 },
        { id: "obj_026", name: "Highland Sheep Pasture", desc: "Open pastureland dotted with grazing sheep.", x: 1931.1, y: 349.5, z: 21.0 },
        { id: "obj_027", name: "Sunken Shipwreck", desc: "The wreckage of an old ship, half-buried in sand.", x: 638.6, y: 809.4, z: 48.5 },
        { id: "obj_028", name: "Bear Cave", desc: "A large cave entrance with fresh bear tracks nearby.", x: 2410.2, y: 912.4, z: 44.2 },
        { id: "obj_029", name: "Broken Aqueduct", desc: "The remains of an ancient stone aqueduct.", x: 632.1, y: 1182.8, z: 42.7 },
        { id: "obj_030", name: "Foggy Marshland", desc: "A misty marsh known for disorienting travelers.", x: 1925.5, y: 301.0, z: 49.5 },
        { id: "obj_031", name: "Old Battlefield", desc: "A field still scattered with rusted weapons and bones.", x: 639.7, y: 774.8, z: 38.6 },
        { id: "obj_032", name: "Whispering Falls", desc: "A waterfall said to whisper secrets to those who listen.", x: 986.9, y: 889.0, z: 3.7 },
        { id: "obj_033", name: "Nomad Camp", desc: "A temporary camp used by traveling nomads.", x: 270.4, y: 1748.2, z: 12.2 },
        { id: "obj_034", name: "Rockslide Pass", desc: "A narrow mountain pass prone to rockslides.", x: 1803.9, y: 1115.1, z: 22.7 },
        { id: "obj_035", name: "Twin Peaks Overlook", desc: "A high vantage point offering a view of the valley.", x: 2877.4, y: 1451.2, z: 28.7 },
        { id: "obj_036", name: "Sunken Garden Ruins", desc: "The remains of an ornate garden, now overgrown.", x: 2599.6, y: 548.5, z: 7.7 },
        { id: "obj_037", name: "Old Signal Tower", desc: "A stone tower once used to relay messages between camps.", x: 2725.3, y: 2453.4, z: 12.5 },
        { id: "obj_038", name: "Frostbite Ridge", desc: "A cold, windswept ridge near the mountain's peak.", x: 569.4, y: 2218.3, z: 47.0 },
        { id: "obj_039", name: "Abandoned Lighthouse", desc: "A lighthouse no longer in use, its lamp long dark.", x: 589.8, y: 2850.4, z: 44.1 },
        { id: "obj_040", name: "Thornwood Thicket", desc: "A dense thicket of thorned bushes blocking the path.", x: 1810.6, y: 1264.4, z: 5.2 },
        { id: "obj_041", name: "River Delta Camp", desc: "A camp set up where the river splits into the delta.", x: 116.1, y: 2888.0, z: 11.9 },
        { id: "obj_042", name: "Old Prospector's Claim", desc: "A staked claim from a prospector who never returned.", x: 2113.7, y: 770.9, z: 41.2 },
        { id: "obj_043", name: "Elven Waystone", desc: "An ancient waystone marking a forgotten elven trail.", x: 1789.4, y: 880.3, z: 8.8 },
        { id: "obj_044", name: "Windswept Dunes", desc: "Rolling sand dunes shaped by constant wind.", x: 2161.1, y: 206.3, z: 11.4 },
        { id: "obj_045", name: "Hidden Waterfall Grotto", desc: "A grotto behind a waterfall, rarely discovered.", x: 1678.1, y: 2557.2, z: 30.7 },
        { id: "obj_046", name: "Trapper's Cabin", desc: "A small cabin used by a local fur trapper.", x: 840.7, y: 2752.1, z: 10.2 },
        { id: "obj_047", name: "Old Stone Well", desc: "A deep well of unknown age near the crossroads.", x: 49.7, y: 807.6, z: 22.3 },
        { id: "obj_048", name: "Charred Forest Clearing", desc: "A clearing left by an old forest fire.", x: 181.4, y: 528.8, z: 18.4 },
        { id: "obj_049", name: "Sunlit Meadow", desc: "An open meadow filled with wildflowers.", x: 1716.5, y: 394.7, z: 18.1 },
        { id: "obj_050", name: "Cliffside Eagle Nest", desc: "A large nest visible on a nearby cliff face.", x: 2672.8, y: 2941.5, z: 32.8 },
        { id: "obj_051", name: "Old Border Marker", desc: "A weathered stone marking an old territorial border.", x: 2073.7, y: 1753.3, z: 7.0 }
    ];
}