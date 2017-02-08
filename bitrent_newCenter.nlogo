extensions [gis]

globals[
 rings-data  ;;accessibility data for the 8 rings
 sorted-assec-list
 move-out ;;total number of people moved out
 areas-changed
 centers
 g1
 g2
 g3
 g4
 g5
 g6
 g7
 g8
 g9
 g10
 g11
 g12
 g13
]

patches-own[
acces
center ;;1 if it's a center of buffer
neighborhood ;;patches in this neighborhood, for centers only
cost ;;the cost to live here
accessibility  ;;accessibility of the area,for centers only
local-cost ;;cost in a local space
ring  ;;in which ring
]

breed [ residents resident]
breed [employers employer]

residents-own[
  income ;;1 high 2 middle, 3 low
  age
  age-group;;1 young 2 middle 3 old
  moved ;; times that he/she has moved
  will-move ;; 1 if it will tyr to move
  space ;;sapce needed
  ]

employers-own[
 income ;;1 high 2 middle, 3 low
 incomeg;;1=commerce 2=service 3=industry
 tenure ;;0-6, can move when = 0
 moved ;; times that he/she has moved
 will-move
 space ;;sapce needed
]

to setup
ca
reset-ticks

set rings-data gis:load-dataset "data/rings_newCenter.shp"

gis:set-world-envelope gis:envelope-of rings-data

gis:set-drawing-color 5  gis:draw rings-data 1.0


gis:apply-coverage rings-data "ACCES01" acces
gis:apply-coverage rings-data "OBJECTID" ring
ask patches [ifelse acces > 0[][set acces 0] ]

crt population-residents [set breed residents set color yellow set income random 2 + 1 set age 18 + random 50 move-to one-of patches with [acces > 0] ]

crt population-employers [set breed employers set color blue set incomeg random 2 + 1  set tenure random 7 move-to one-of patches with [acces > 0]]

ask turtles [set size 5]


reset-age-groups
set-income
set-space

;;create 9 X 9 center points for buffers
let x 0
let y 0
repeat 9 [
set x x + (world-height / 10)
set y 0
  repeat 9 [
    set y y +  (world-width / 10)
    ask patch x y [set center 1]
  ]
]

set centers patches with [center = 1]
ask centers [set neighborhood patches in-radius (world-height / 10) set neighborhood neighborhood with [acces > 0]]
ask centers [set accessibility ((sum [acces] of neighborhood) / (count neighborhood)) ]


set sorted-assec-list reverse sort-on [accessibility] patches with [center = 1]

set areas-changed nobody

set g1 patches with [ring = 1]
set g2 patches with [ring = 2]
set g3 patches with [ring = 3]
set g4 patches with [ring = 4]
set g5 patches with [ring = 5]
set g6 patches with [ring = 6]
set g7 patches with [ring = 7]
set g8 patches with [ring = 8]
set g9 patches with [ring = 9]
set g10 patches with [ring = 10]
set g11 patches with [ring = 11]
set g12 patches with [ring = 12]
set g13 patches with [ring = 13]

end

to go
  tick
  reset-age-groups

  ask patches with [center = 1][recalculate-cost]

  ask turtles [set will-move 0]
  ;;decide who can move
  ask residents with [age-group = 1][if random-float 1 < 0.5 [set will-move 1]]
  ask residents with [age-group = 2][if random-float 1 < 0.2 [set will-move 1]]
  ask residents with [age-group = 3][if random-float 1 < 0.1 [set will-move 1]]

  ask employers with [tenure = 0][set will-move 1]

  ask turtles with [will-move = 1][search-new-area]
  ask residents [set age age + 1]
  ask employers [if tenure > 0 [set tenure tenure - 1]]
end


to set-income

ask residents with [income = 1][set income 279 + (628 - 279) * random-float 1 ]
ask residents with [income = 2][set income 375 + (649 - 375) * random-float 1 ]
ask residents with [income = 3][set income 602 + (965 - 602) * random-float 1 ]

ask employers with [incomeg = 1][set income 4 * (279 + (628 - 279) * random-float 1) ]
ask employers with [incomeg = 2][set income 4 * (375 + (649 - 375) * random-float 1) ]
ask employers with [incomeg = 3][set income 4 * (602 + (965 - 602) * random-float 1) ]
end

to set-space

  ask residents with [age-group = 1][set space space-for-young]
  ask residents with [age-group = 2][set space space-for-middle]
  ask residents with [age-group = 3][set space space-for-old]


  ask employers with [incomeg = 1][set space space-for-industry]
  ask employers with [incomeg = 2][set space space-for-service]
  ask employers with [incomeg = 3][set space space-for-commerce]
end


to reset-age-groups
ask residents [
   ifelse age <= 34 [set age-group 1]
  [ifelse age <= 65 [set age-group 2]
                    [set age-group 3]]
]

end


to recalculate-cost
    ;;recalculate cost of each area
    ifelse count turtles-on neighborhood > 0 [
    let allincome (sum [income] of residents-on neighborhood) + (sum [income] of employers-on neighborhood)
    ;;set cost allincome / (count turtles-on neighborhood)]
    set cost allincome / (count neighborhood) ]
    [set cost 0]
end


to search-new-area
 set areas-changed nobody
 let moved-in-this-round false
 foreach sorted-assec-list [
   if moved-in-this-round = false [
     if ([cost] of ? * space) <= income [
       let target nobody
       repeat 50 [
         let try-target one-of [neighborhood] of ?
         ask try-target [
           ifelse count turtles-on neighbors > 0[set local-cost sum ([income] of turtles in-radius local-search-radius) / count patches in-radius local-search-radius][set local-cost 0]]
         if ([local-cost] of try-target * space) <= income [
           let areas-changed1 centers in-radius (world-height / 10)
           move-to try-target
           let areas-changed2 centers in-radius (world-height / 10)
           set areas-changed (patch-set areas-changed1 areas-changed2)
           set moved-in-this-round true set moved moved + 1
           ask areas-changed [recalculate-cost]
           stop]]
]]]

 if moved-in-this-round = false [set move-out move-out + 1 die]
end

to add-100-residents
  crt population-residents [set breed residents set color yellow set income random 2 + 1 set age 18 + random 50 move-to one-of patches with [acces > 0] set size 5]
  reset-age-groups
  set-income
  set-space
end

to add-100-employers
  crt population-employers [set breed employers set color blue set incomeg random 2 + 1  set tenure random 7 move-to one-of patches with [acces > 0] set size 5]
  set-income
  set-space
end
@#$#@#$#@
GRAPHICS-WINDOW
273
10
773
531
-1
-1
2.45
1
10
1
1
1
0
0
0
1
0
199
0
199
0
0
1
ticks
30.0

BUTTON
11
19
74
52
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
7
65
124
125
population-residents
1000
1
0
Number

INPUTBOX
131
65
255
125
population-employers
1000
1
0
Number

BUTTON
80
19
143
52
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
7
129
127
189
space-for-young
6
1
0
Number

INPUTBOX
7
196
128
256
space-for-middle
20
1
0
Number

INPUTBOX
6
259
128
319
space-for-old
20
1
0
Number

BUTTON
791
17
910
50
colorful-accessibility
ask patches with [center = 1][ask neighborhood [set pcolor (([accessibility] of myself / 66.11905672402804 ) * 9 + 10)]]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
792
57
912
90
black-patches
ask patches [set pcolor black]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
794
97
868
142
NIL
move-out
17
1
11

MONITOR
794
149
869
194
avg income
mean [income] of turtles
2
1
11

MONITOR
794
199
870
244
avg cost
mean [cost] of patches with [center = 1]
2
1
11

PLOT
921
15
1161
165
income
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "clear-plot\nif ticks > 0[foreach sort [income] of turtles [plot ?]]"

INPUTBOX
5
326
130
386
local-search-radius
5
1
0
Number

INPUTBOX
134
129
255
189
space-for-commerce
20
1
0
Number

INPUTBOX
135
195
255
255
space-for-service
40
1
0
Number

INPUTBOX
135
260
255
320
space-for-industry
60
1
0
Number

PLOT
922
173
1162
323
population density over rings
NIL
NIL
0.0
10.0
0.0
0.1
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "if ticks > 0 [\nclear-plot\nplot count turtles-on g1 / count g1\nplot count turtles-on g2 / count g2\nplot count turtles-on g3 / count g3\nplot count turtles-on g4 / count g4\nplot count turtles-on g5 / count g5\nplot count turtles-on g6 / count g6\nplot count turtles-on g7 / count g7\nplot count turtles-on g8 / count g8\nplot count turtles-on g9 / count g9\nplot count turtles-on g10 / count g10\nplot count turtles-on g11 / count g11\nplot count turtles-on g12 / count g12\nplot count turtles-on g13 / count g13\n]"

BUTTON
147
20
210
53
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
924
333
1162
483
cost per m2 over rings
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "if ticks > 0 [\nclear-plot\nplot (sum ([income] of turtles-on g1) / count g1)\nplot (sum ([income] of turtles-on g2) / count g2)\nplot (sum ([income] of turtles-on g3) / count g3)\nplot (sum ([income] of turtles-on g4) / count g4)\nplot (sum ([income] of turtles-on g5) / count g5)\nplot (sum ([income] of turtles-on g6) / count g6)\nplot (sum ([income] of turtles-on g7) / count g7)\nplot (sum ([income] of turtles-on g8) / count g8)\nplot (sum ([income] of turtles-on g9) / count g9)\nplot (sum ([income] of turtles-on g10) / count g10)\nplot (sum ([income] of turtles-on g11) / count g11)\nplot (sum ([income] of turtles-on g10) / count g12)\nplot (sum ([income] of turtles-on g11) / count g13)\n]"

BUTTON
7
393
131
426
NIL
add-100-residents
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
6
431
132
464
NIL
add-100-employers
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.3.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
