# Larchrow Village & Cave tiles (MapView atlas 5)

B25R1-Q8. Larchrow's *Pixel Tileset: Village & Cave Expansion* (private package `private-assets/larchrow-village-cave-tileset.zip`,
registry entry `larchrow_village_cave`) is imported unchanged by `tools/village_tile_sheets.py` as
`game/assets/tiles/larchrow_village_cave.png`, MapView atlas 5. A tile's value in village.json-style layers and stamps
(`atlas * 100000 + tile`) is **500000 + Larchrow's `tile_id`** (row * 16 + column of the 16-column sheet); the names are the
pack's own `tile_index.csv`. Autotile names end in a corner code 00-15: top-left 1 + top-right 2 + bottom-left 4 +
bottom-right 8, a set bit meaning that corner is the named terrain (roof 00 is an empty cell). Lava frames 1-3 are the
rows below frame 0 (tile + 16, + 32, + 48); the crystal's frames are side by side.

| Value | Name | Value | Name | Value | Name | Value | Name |
|---|---|---|---|---|---|---|---|
| 500000 | `grass_0` | 500001 | `dirt_0` | 500002 | `plank_floor_0` | 500003 | `plank_floor_1` |
| 500004 | `plank_floor_2` | 500005 | `plank_floor_3` | 500006 | `tilled_soil_0` | 500007 | `tilled_soil_1` |
| 500008 | `cave_floor_0` | 500009 | `cave_floor_1` | 500010 | `cave_floor_2` | 500011 | `cave_floor_3` |
| 500012 | `crop_0` | 500013 | `crop_1` | 500014 | `crop_2` | 500015 | `well` |
| 500016 | `haystack` | 500017 | `roof_red_01` | 500018 | `roof_red_02` | 500019 | `roof_red_03` |
| 500020 | `roof_red_04` | 500021 | `roof_red_05` | 500022 | `roof_red_06` | 500023 | `roof_red_07` |
| 500024 | `roof_red_08` | 500025 | `roof_red_09` | 500026 | `roof_red_10` | 500027 | `roof_red_11` |
| 500028 | `roof_red_12` | 500029 | `roof_red_13` | 500030 | `roof_red_14` | 500031 | `roof_red_15` |
| 500032 | `stepping_stones` | 500033 | `roof_blue_01` | 500034 | `roof_blue_02` | 500035 | `roof_blue_03` |
| 500036 | `roof_blue_04` | 500037 | `roof_blue_05` | 500038 | `roof_blue_06` | 500039 | `roof_blue_07` |
| 500040 | `roof_blue_08` | 500041 | `roof_blue_09` | 500042 | `roof_blue_10` | 500043 | `roof_blue_11` |
| 500044 | `roof_blue_12` | 500045 | `roof_blue_13` | 500046 | `roof_blue_14` | 500047 | `roof_blue_15` |
| 500048 | `cave_wall_00` | 500049 | `cave_wall_01` | 500050 | `cave_wall_02` | 500051 | `cave_wall_03` |
| 500052 | `cave_wall_04` | 500053 | `cave_wall_05` | 500054 | `cave_wall_06` | 500055 | `cave_wall_07` |
| 500056 | `cave_wall_08` | 500057 | `cave_wall_09` | 500058 | `cave_wall_10` | 500059 | `cave_wall_11` |
| 500060 | `cave_wall_12` | 500061 | `cave_wall_13` | 500062 | `cave_wall_14` | 500063 | `cave_wall_15` |
| 500065 | `lava_01` | 500066 | `lava_02` | 500067 | `lava_03` | 500068 | `lava_04` |
| 500069 | `lava_05` | 500070 | `lava_06` | 500071 | `lava_07` | 500072 | `lava_08` |
| 500073 | `lava_09` | 500074 | `lava_10` | 500075 | `lava_11` | 500076 | `lava_12` |
| 500077 | `lava_13` | 500078 | `lava_14` | 500079 | `lava_15` | 500081 | `lava_01_f1` |
| 500082 | `lava_02_f1` | 500083 | `lava_03_f1` | 500084 | `lava_04_f1` | 500085 | `lava_05_f1` |
| 500086 | `lava_06_f1` | 500087 | `lava_07_f1` | 500088 | `lava_08_f1` | 500089 | `lava_09_f1` |
| 500090 | `lava_10_f1` | 500091 | `lava_11_f1` | 500092 | `lava_12_f1` | 500093 | `lava_13_f1` |
| 500094 | `lava_14_f1` | 500095 | `lava_15_f1` | 500097 | `lava_01_f2` | 500098 | `lava_02_f2` |
| 500099 | `lava_03_f2` | 500100 | `lava_04_f2` | 500101 | `lava_05_f2` | 500102 | `lava_06_f2` |
| 500103 | `lava_07_f2` | 500104 | `lava_08_f2` | 500105 | `lava_09_f2` | 500106 | `lava_10_f2` |
| 500107 | `lava_11_f2` | 500108 | `lava_12_f2` | 500109 | `lava_13_f2` | 500110 | `lava_14_f2` |
| 500111 | `lava_15_f2` | 500113 | `lava_01_f3` | 500114 | `lava_02_f3` | 500115 | `lava_03_f3` |
| 500116 | `lava_04_f3` | 500117 | `lava_05_f3` | 500118 | `lava_06_f3` | 500119 | `lava_07_f3` |
| 500120 | `lava_08_f3` | 500121 | `lava_09_f3` | 500122 | `lava_10_f3` | 500123 | `lava_11_f3` |
| 500124 | `lava_12_f3` | 500125 | `lava_13_f3` | 500126 | `lava_14_f3` | 500127 | `lava_15_f3` |
| 500128 | `timber_wall` | 500129 | `timber_window` | 500130 | `timber_door` | 500131 | `stone_wall` |
| 500132 | `stone_window` | 500133 | `stone_door` | 500134 | `fence_h` | 500135 | `fence_v` |
| 500136 | `fence_gate` | 500137 | `market_stall_00` | 500138 | `market_stall_01` | 500139 | `market_stall_10` |
| 500140 | `market_stall_11` | 500141 | `signpost` | 500142 | `village_flowers_0` | 500143 | `village_flowers_1` |
| 500144 | `lamp_post_0` | 500145 | `lamp_post_1` | 500146 | `barrel_lidded` | 500147 | `barrel_water` |
| 500148 | `crate_apples` | 500149 | `crystal_glow_0` | 500150 | `crystal_glow_1` | 500151 | `crystal_glow_2` |
| 500152 | `crystal_glow_3` | 500153 | `stalagmite_0` | 500154 | `stalagmite_1` | 500155 | `cave_mushrooms_0` |
| 500156 | `cave_mushrooms_1` | 500157 | `ore_iron` | 500158 | `ore_gold` | 500159 | `bones_pile` |
| 500160 | `rail_v` | 500161 | `rail_h` | 500162 | `rail_curve_ne` | 500163 | `rail_curve_nw` |
| 500164 | `rail_curve_se` | 500165 | `rail_curve_sw` | 500166 | `rail_cross` | 500167 | `minecart` |
| 500168 | `rope` | 500169 | `ladder` |  |  | |  |  | |
