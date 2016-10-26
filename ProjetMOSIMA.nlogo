breed[agents agent]

globals [
  x-domain ;
  precision-Domain
  effort-min  ; = 0.00010  ; effort minimum fournir par un agent
  effort-max  ; = 2.001  ; effort maximum fournir par un agent
]

agents-own [
  typeAgent
  couleur_effort
  couleur_type
  evolution
  nbInteractions
  effort
  last_effort
  profit
  profit_cumule
  last_profit
  binome_last_effort
  binome_last_profit
  all_average_effort
  all_average_profit
  have_Played? ; true si l'agent a participé à un binômage durant le tick courant
  ;( utilisée pour la fonction "logs" et "adaptation" )
]

; Initialisation de tous les agents
; Leur couleur initiale représente le type de comportement qu'ils ont
to setup
  clear-all

  set effort-min 0.00010
  set effort-max 2.001

  ; On crée une liste contenant tous les chiffres de 0.00010 à 2.001 , avec un pas de  (1 / precision-Domain )
  ; Ce domaine sera utilisé pour les comportement de type "rational" et  "average rational"
  set precision-Domain 1000

  let dom1 n-values precision-Domain [? / precision-Domain] ; [0.00010 à  1[  ( 1 exlu )
  set dom1 replace-item 0 dom1 effort-min  ; ; on sremplace l'effort "0" par 0.00010

  let  dom2 n-values (precision-Domain + 1) [(? / precision-Domain) + 1 ] ; [1 à  2] ( 2 inclu )
  set dom2 lput 2.001 dom2  ; ajout de l'effort 2.001
  set x-domain sentence dom1 dom2
  print x-domain

  create-agents nbAgents_null [
    set typeAgent 0
    set couleur_type red
  ]

  create-agents nbAgents_shrinking [
    set typeAgent 1
    set couleur_type orange
  ]

  create-agents nbAgents_replicator [
    set typeAgent 2
    set couleur_type brown
  ]

  create-agents nbAgents_rational [
    set typeAgent 3
    set couleur_type yellow
  ]

  create-agents nbAgents_profit [
    set typeAgent 4
    set couleur_type green
  ]

  create-agents nbAgents_high [
    set typeAgent 5
    set couleur_type cyan
  ]

  create-agents nbAgents_average_Rational [
    set typeAgent 6
    set couleur_type blue
  ]

  create-agents nbAgents_winner [
    set typeAgent 7
    set couleur_type violet
  ]

  create-agents nbAgents_effort [
    set typeAgent 8
    set couleur_type magenta
  ]

  create-agents nbAgents_averager [
    set typeAgent 9
    set couleur_type pink
  ]

  ask agents [
    move-to one-of patches with [not any? turtles-here]
    set color couleur_type
    ;set shape "square"
    set heading one-of [0 90 180 270]

    set effort ( random-float ( 2 + effort-min )) + effort-min  ; random d'un flottant  allant de 0.00010 à 2.001
    set label who
    logs
  ]

  reset-ticks
end

; Suite d'actions des agents à chaque pas de temps :
; Mouvement, Jeu, Adaptation
to go
  tick
  ask agents [
    move
  ]
  if verbose? [print "-- Start Game phase --"]
  ask agents [
    set have_Played? false
    game
  ]
  if verbose? [print "-- End Game phase --"]
  ask agents with [have_Played? ] [
    adaptation
  ]
  if verbose? [
    ask agents with [have_Played? ][ logs ]
  ]
end

; Methode de mouvements :
; L'agent se tourne vers un des quatres points cardinaux
; Puis il se déplace sur la case qui est devant lui s'il n'y a personne
to move
  set heading one-of [0 90 180 270]
  if patch-ahead 1 != nobody
  [
    if ( [ not any? turtles-here ] of patch-ahead 1 )
    [
      fd 1
    ]
  ]
end

; Methode de jeu
to game
  let antagonist nobody
  if patch-ahead 1 != nobody
  [
    set antagonist one-of turtles-on patch-ahead 1
  ]
  if antagonist = nobody [stop]
  let face_a_face False
  let heading_i heading

  ask antagonist [
    set face_a_face ( abs ( heading - heading_i ) = 180 )
  ]
  if not face_a_face[ stop]

  ;-----------------------GAME -----------------------------------------

  if verbose? [print (word who " game with " ([who] of antagonist))]
  set have_Played? true

  set nbInteractions ( nbInteractions + 1 )
  set last_effort effort
  set last_profit profit


  let effort_j 0
  ask antagonist [ set effort_j effort ]
  set profit ( ( 5 * ( sqrt ( effort + effort_j ) ) ) - ( effort ^ 2) )
  set profit_cumule ( profit_cumule + profit )

  set binome_last_effort effort_j


  let profit_i profit
  ask antagonist [ set binome_last_profit profit_i ]

end

; Methode permettant de logger toutes les valeurs de chaque agent
to logs
  print "---------------------"
  print word "Type: " typeAgent
  print word "Effort: " effort
  print word "Last Effort: " last_effort
  print word "Profit: " profit
  print word "Profit Cumulé: " profit_cumule
  print word "Last Profit: " last_profit
  print word "Effort du dernier partenaire: " binome_last_effort
  print word "Profit du dernier partenaire: " binome_last_profit
  print word "nbInteractions: " nbInteractions

end

; TODO : Integrer la notion de bruit (Note 5.10 du sujet en anglais)
; Le slider varie de 1 à 50, 1 correspond à un bruit entre 0.99 et 1.01
; 50 correspond à un bruit entre 0.50 et 1.50

; En gros, on n'utilise plus binome_last_effort mais binome_last_effort * un random entre les deux bornes

; Je ne sais pas si on doit prendre en compte le bruit seulement dans l'adaptation mais aussi à chaque jeu pour le calcul du profit

; Il y aura juste un probleme, vite réglé : On ne peut pas faire la ( moyenne de toutes les valeurs de profit ) * bruit par exemple
; Le bruit ne se fait pas sur la moyenne en général, mais sur les valeurs percues déja bruitées, c'est à dire
; moyenne ( valeurs percues * bruit ) plutôt. A changer dans la fonction game si necessaire.

to adaptation
  let resultat 0

  if nbInteractions > 0 [
    ; Nouvel effort presque nul. Varie entre 0 et 0.0001
    if typeAgent = 0
    [
      ;set effort random-float 0.00010
      set effort effort-min
    ]
    ; Nouvel effort valant la moitié de l'effort du partenaire précédent
    if typeAgent = 1
    [
      set effort ( binome_last_effort / 2 )
    ]
    ; Nouvel effort valant exactement l'effort du partenaire précédent
    if typeAgent = 2
    [
      set effort binome_last_effort
    ]
    ; Nouvel effort donnant le meilleur profit en fonction de l'effort du partenaire précédent
    ; Pour obtenir la valeur d'effort donnant le profit maximum, il faut donc calculer
    ; newEffort = argmax ( ( 5 / ( 2*sqrt(x+binome_last_effort) ) - 2x )
    if typeAgent = 3
    [
      let profitTmp 0   ; profit
      let profit-values []  ; liste de tous les profits calculés
      foreach x-domain
      [
        set profitTmp fct ? binome_last_effort
        set profit-values lput profitTmp profit-values   ; on remplie la liste des profits
      ]
      ;print profit-values
      let positionOfProfitMax position (max profit-values) profit-values  ; on récupére l'indice du profit max
      set effort item positionOfProfitMax x-domain  ; on récupère l'effort qui a donné le profit max

      ;print word "profit max : " (max profit-values)
      ;print word "res : " effort
    ]
    ; On compare son profit avec celui du dernier partenaire.
    ; Si le profit de l'agent même est supérieur, il augmente de 10%, sinon il baisse de 10%
    if typeAgent = 4
    [
      ifelse ( last_profit >= binome_last_profit )
      [
        set effort ( effort * 1.1 )
      ]
      [
        set effort ( effort * 0.9 )
      ]
    ]
    ; Nouvel effort plus ou moins autour de 2. Varie entre 1.999 et 2.001
    if typeAgent = 5
    [
      ;set effort ( 1.999 + random-float 0.002 )
      set effort effort-max
    ]
    ; Idem que le rationel, remplacer binome_last_effort par all_average_effort
    if typeAgent = 6
    [

      let profitTmp 0   ; profit
      let profit-values []  ; liste de tous les profits calculés
      foreach x-domain
      [
        set profitTmp fct ? all_average_effort
        set profit-values lput profitTmp profit-values   ; on remplie la liste des profits
      ]
      ;print profit-values
      let positionOfProfitMax position (max profit-values) profit-values  ; on récupére l'indice du profit max
      set effort item positionOfProfitMax x-domain  ; on récupère l'effort qui a donné le profit max

      ;print word "profit max : " (max profit-values)
      ;print word "res : " effort


    ]
    ; Nouvel effort devient celui de l'ancien partenaire si celui-ci a eu un meilleur profit
    if typeAgent = 7
    [
      if ( last_profit < binome_last_profit )
      [
        set effort binome_last_effort
      ]
    ]
    ; On compare son effort avec celui du dernier partenaire.
    ; Si l'effort de l'agent même est supérieur, il baisse de 10%, sinon il augmente de 10%
    if typeAgent = 8
    [
      ifelse ( last_effort <= binome_last_effort )
      [
        set effort ( effort * 1.1 )
      ]
      [
        set effort ( effort * 0.9 )
      ]
    ]
    if typeAgent = 9
    [
      set effort ( ( effort + binome_last_effort ) / 2 )
    ]
  ]
end


to-report fct [_x binLastEff ]
  ; f(x) = ( ( 5 * ( sqrt ( effort + effort_j ) ) ) - ( effort ^ 2) )
  report ( ( 5 * ( sqrt ( _x + binLastEff ) ) ) - ( _x ^ 2) )
end


@#$#@#$#@
GRAPHICS-WINDOW
518
10
763
221
-1
-1
90.0
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
1
0
1
1
1
1
ticks
30.0

INPUTBOX
5
10
117
70
nbAgents_null
1
1
0
Number

INPUTBOX
5
73
166
133
nbAgents_shrinking
0
1
0
Number

INPUTBOX
5
136
166
196
nbAgents_replicator
0
1
0
Number

INPUTBOX
5
199
166
259
nbAgents_rational
1
1
0
Number

INPUTBOX
5
262
166
322
nbAgents_profit
0
1
0
Number

INPUTBOX
5
325
166
385
nbAgents_high
0
1
0
Number

INPUTBOX
5
388
166
448
nbAgents_average_Rational
0
1
0
Number

INPUTBOX
5
451
166
511
nbAgents_winner
0
1
0
Number

INPUTBOX
5
514
166
574
nbAgents_effort
0
1
0
Number

INPUTBOX
5
577
166
637
nbAgents_averager
0
1
0
Number

BUTTON
546
339
619
372
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

BUTTON
694
338
757
371
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
0

SLIDER
216
177
388
210
bruit
bruit
1
50
1
1
1
NIL
HORIZONTAL

SWITCH
245
126
366
159
verbose?
verbose?
0
1
-1000

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
