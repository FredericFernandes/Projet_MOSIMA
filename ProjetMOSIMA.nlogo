extensions [palette]
breed[agents agent]
breed[agentsE agentE] ; Agents utilisés pour visualiser les efforts

globals [
  x-domain ;
  precision-Domain
  effort-min  ; = 0.0001  ; effort minimum fournir par un agent
  effort-max  ; = 2.001  ; effort maximum fournir par un agent

  availableClones ; Pour la double visualisation
]

; Patchs du milieu (pour empecher que les agents se mélangent)
patches-own [
  obstacle?
]

agents-own [
  typeAgent
  couleur_type
  evolution
  nbInteractions
  effort
  effort_cumule
  ;last_effort
  profit
  profit_cumule
  ;last_profit
  binome_last_effort
  binome_last_profit
  ;all_average_effort
  all_average_profit
  binome_average_effort
  binome_all_effort
  have_Played? ; true si l'agent a participé à un binômage durant le tick courant
  ;( utilisée pour la fonction "logs" et "adaptation" )

  binome_interactions_nature
  binome_effort_nature
  binome_profit_nature
]

; Agents représentant les efforts et leurs équivalents représentant le type
agentsE-own [
  clone
]

; On déplace les agents sur les memes cases dans chaque moitié du modele
; On leur affecte une couleur suivant un gradian du bleu au rouge en passant par le vert selon leur effort
to agentsE-update
  ask agentsE [
    let xCl 0
    let yCl 0
    let effortCl 0
    ask clone [
      set xCl xcor
      set yCl ycor
      set effortCl effort
    ]
    setxy (xCl + max-pxcor / 2 + 1) yCl

    set color palette:scale-gradient [[0 0 255][0 85 255][0 170 255][0 255 255][0 255 170][0 255 85][0 255 0][85 255 0][170 255 0][255 255 0][255 170 0][255 85 0][255 0 0]] effortCl 0 2
  ]
end

to setup-agents
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

  ; On rempli la liste des agents n'ayant pas encore d'équivalent d'un point de vue effort
  set availableClones sort-by < agents

  ask agents [
    move-to one-of patches with [not any? turtles-here and pxcor < max-pxcor / 2]
    set color couleur_type
    set shape "square"
    set heading one-of [0 90 180 270]

    set binome_effort_nature [0 0 0 0 0 0 0 0 0 0]
    set binome_profit_nature [0 0 0 0 0 0 0 0 0 0]
    set binome_interactions_nature [0 0 0 0 0 0 0 0 0 0]

    ifelse (typeAgent = 0)[
      set effort effort-min
    ]
    [
      ifelse (typeAgent = 5)
      [
        set effort effort-max
      ]
      [
        ifelse (typeAgent = 7)
        [
          set effort effort-max
        ]
        [
          set effort effort-min + random-float (effort-max - effort-min) ; random d'un flottant  allant de 0.00010 à 2.001
        ]
      ]
      set label who
      ;logs
    ]
  ]
end

; On crée les agents représentant l'effort et leur affecte un équivalent qu'ils représenteront
to setup-agentsE
  ; J'aurais pu utiliser create-agentsE count agents, c'était plus rapide et moins con. Flemme de changer
  create-agentsE nbAgents_null + nbAgents_shrinking + nbAgents_replicator + nbAgents_rational + nbAgents_profit + nbAgents_high + nbAgents_average_Rational + nbAgents_winner + nbAgents_effort + nbAgents_averager[
    set clone one-of availableClones
    set availableClones remove clone availableClones
    set shape "square"
  ]
end

; Initialisation de tous les agents
; Leur couleur initiale représente le type de comportement qu'ils ont
to setup
  clear-globals
  clear-ticks
  clear-turtles
  clear-patches
  clear-drawing
  clear-output

  set effort-min 0.0001
  set effort-max 2.001

  ; On crée une liste contenant tous les chiffres de 0.00010 à 2.001 , avec un pas de  (1 / precision-Domain )
  ; Ce domaine sera utilisé pour les comportement de type "rational" et  "average rational"
  set precision-Domain 100

  let dom1 n-values precision-Domain [? / precision-Domain] ; [0.00010 à  1[  ( 1 exlu )
  set dom1 replace-item 0 dom1 effort-min  ; ; on sremplace l'effort "0" par 0.00010

  let  dom2 n-values (precision-Domain + 1) [(? / precision-Domain) + 1 ] ; [1 à  2] ( 2 inclu )
  set dom2 lput 2.001 dom2  ; ajout de l'effort 2.001
  set x-domain sentence dom1 dom2
  ;print x-domain

  ask patches [
    set obstacle? False
  ]
  ask patches with [pxcor = max-pxcor / 2]
  [
    set pcolor white
    set obstacle? True
  ]

  setup-agents
  setup-agentsE
  agentsE-update

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

  agentsE-update

  ask agents with [have_Played? ] [
    adaptation
  ]

  if mutation?
  [
    ask agents with [have_Played?]
    [
      mutation
    ]
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
      let obs False
      ask patch-ahead 1 [
        set obs obstacle?
      ]
      if not obs [
        fd 1
      ]
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
  ;set last_effort effort
  ;set last_profit profit


  let effort_j 0
  ask antagonist [ set effort_j effort ]

  let coefNoise 1
  if useNoise? [
    set coefNoise ((1 - Noise) + random-float ((1 + Noise) - (1 - Noise))) ; random d'un flottant  allant de 1-buit à 1+buit
    ;print coefNoise
  ]
  set effort_j (effort_j * coefNoise)

  set profit ( ( 5 * ( sqrt ( effort + effort_j ) ) ) - ( effort ^ 2) )
  set profit_cumule ( profit_cumule + profit )
  set effort_cumule ( effort_cumule + effort )

  set binome_last_effort effort_j


  let profit_i (profit * coefNoise)
  ask antagonist [ set binome_last_profit profit_i ]

  set binome_all_effort binome_all_effort + effort_j
  set binome_average_effort (binome_all_effort / nbInteractions)

  let index [typeAgent] of antagonist
  set binome_interactions_nature (replace-item index binome_interactions_nature ( (item index binome_interactions_nature) + 1))
  set binome_effort_nature (replace-item index binome_effort_nature ( (item index binome_effort_nature) + binome_last_effort))

  set index typeAgent
  ask antagonist [
    set binome_profit_nature (replace-item index binome_profit_nature ( (item index binome_profit_nature) + profit_i))
  ]



end

; Methode permettant de logger toutes les valeurs de chaque agent
to logs
  print (word "----------- Agent " who " ----------")
  print word "Type: " typeAgent
  print word "Effort: " effort
 ; print word "Last Effort: " last_effort
  print word "Profit: " profit
  print word "Profit Cumulé: " profit_cumule
  ;print word "Last Profit: " last_profit
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
    ; newEffort = argmax ( 5 * sqrt(x + binome_last_effort) - x² ) , c'est à dire
    ; newEffort = x tel que ( ( 5 / ( 2*sqrt(x+binome_last_effort) ) - 2x ) = 0 ( car la dérivée seconde est < 0, donc concave )
    if typeAgent = 3
    [
      let profitTmp 0   ; profit
      let profit-values []  ; liste de tous les profits calculés
      foreach x-domain
      [
        set profitTmp fct ? binome_last_effort
        set profit-values lput profitTmp profit-values   ; on remplie la liste des profits
      ]
      let positionOfProfitMax position (max profit-values) profit-values  ; on récupére l'indice du profit max
      set effort item positionOfProfitMax x-domain  ; on récupère l'effort qui a donné le profit max
    ]
    ; On compare son profit avec celui du dernier partenaire.
    ; Si le profit de l'agent même est supérieur, il augmente de 10%, sinon il baisse de 10%
    if typeAgent = 4
    [
      ifelse ( profit > binome_last_profit )
      [
        set effort ( effort * 1.1 )
      ]
      [
        set effort ( effort * 0.9 )
      ]
    ]
    ; Nouvel effort égale à l'effort max ,  2.001
    if typeAgent = 5
    [
      set effort effort-max
    ]
    ; Idem que le rationel, remplacer binome_last_effort par binome_average_effort
    if typeAgent = 6
    [

      let profitTmp 0   ; profit
      let profit-values []  ; liste de tous les profits calculés
      foreach x-domain
      [
        set profitTmp fct ? binome_average_effort
        set profit-values lput profitTmp profit-values   ; on remplie la liste des profits
      ]
      let positionOfProfitMax position (max profit-values) profit-values  ; on récupére l'indice du profit max
      set effort item positionOfProfitMax x-domain  ; on récupère l'effort qui a donné le profit max
    ]
    ; Nouvel effort devient celui de l'ancien partenaire si celui-ci a eu un meilleur profit
    if typeAgent = 7
    [
      if ( profit < binome_last_profit )
      [
        set effort binome_last_effort
      ]
    ]
    ; On compare son effort avec celui du dernier partenaire.
    ; Si l'effort de l'agent même est supérieur, il baisse de 10%, sinon il augmente de 10%
    if typeAgent = 8
    [
      ifelse ( effort < binome_last_effort )
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


; Methode permettant de changer le nombre d'agent de chaque type directement sans le faire manuellement
to setup_values [null shrinking replicator rational prfit high avg winner effrt avgr]
  set nbAgents_null null
  set nbAgents_shrinking shrinking
  set nbAgents_replicator replicator
  set nbAgents_rational rational
  set nbAgents_profit prfit
  set nbAgents_high high
  set nbAgents_average_Rational avg
  set nbAgents_winner winner
  set nbAgents_effort effrt
  set nbAgents_averager avgr
end


; Simulation (Reproduire les courbes 6.9)

; Methode affichant l'effort moyen de chaque population d'agent en fonction du pourcentage d'agents High Efforts
to allHighEffortSims
  clear-all-plots
  simuHighEffort 0
  simuHighEffort 1
  simuHighEffort 2
  simuHighEffort 4
  simuHighEffort 7
  simuHighEffort 8
  simuHighEffort 9
end

; Simulation (Reproduire les courbes 6.10)
to SimsRational
  clear-all-plots
  simuHighEffort 3
  simuHighEffort 6
end
; Prend en parametre le type de population voulu (null, shrinking, replicator, profit, winner, effort, averager)
; Trace une courbe indiquant l'effort moyen d'une population au bout de 5000 ticks pour 0, 0.6, 5.6, 33.3, 66.7, 100% d'agents High
to simuHighEffort [otherAgent]

  set-current-plot "Average Effort - HE Sim"
  create-temporary-plot-pen "Marques"
  set-current-plot-pen "Marques"
  set-plot-pen-color grey
  plotxy 0.6 0
  plot-pen-down
  plotxy 0.6 2.5
  plot-pen-up
  plotxy 5.6 0
  plot-pen-down
  plotxy 5.6 2.5
  plot-pen-up
  plotxy 33.3 0
  plot-pen-down
  plotxy 33.3 2.5
  plot-pen-up
  plotxy 66.6 0
  plot-pen-down
  plotxy 66.6 2.5
  plot-pen-up

  let avgEffort 0

  let x_0 0
  let x_1 0
  let x_2 0
  let x_3 0
  let x_4 0
  let x_6 0
  let x_7 0
  let x_8 0
  let x_9 0

   if otherAgent = 0 [print "Null Effort" ]
   if otherAgent = 1 [print "Shrinking Effort"]
   if otherAgent = 2 [print "Replicator"]
   if otherAgent = 3 [print "Rational"]
   if otherAgent = 4 [print "Profit Comparator"]
   if otherAgent = 6 [print "Average_Rational"]
   if otherAgent = 7 [print "Winner Imitator"]
   if otherAgent = 8 [print "Effort Comparator"]
   if otherAgent = 9 [print "Averager"]

  let percentage 100

  if otherAgent = 5 [ stop ]

  while [percentage != -1]
  [
    if otherAgent = 0 [set-current-plot-pen "Null Effort" set x_0 percentage]
    if otherAgent = 1 [set-current-plot-pen "Shrinking Effort" set x_1 percentage]
    if otherAgent = 2 [set-current-plot-pen "Replicator" set x_2 percentage]
    if otherAgent = 3 [set-current-plot-pen "Rational" set x_3 percentage]
    if otherAgent = 4 [set-current-plot-pen "Profit Comparator" set x_4 percentage]
    if otherAgent = 6 [set-current-plot-pen "Average_Rational" set x_6 percentage]
    if otherAgent = 7 [set-current-plot-pen "Winner Imitator" set x_7 percentage]
    if otherAgent = 8 [set-current-plot-pen "Effort Comparator" set x_8 percentage]
    if otherAgent = 9 [set-current-plot-pen "Averager" set x_9 percentage]
    setup_values x_0 x_1 x_2 x_3 x_4 (100 - percentage) x_6 x_7 x_8 x_9
    setup
    while [ticks < 4000]
    [
      go
    ]

    ask agents [
      set avgEffort avgEffort + effort
    ]
    set avgEffort (avgEffort / count agents)
    print word (word (100 - percentage) "%, Observed Effort ") avgEffort

    plotxy (100 - percentage) avgEffort

    if (percentage = 0) [set percentage -1]
    if (percentage = 33) [set percentage 0]
    if (percentage = 67) [set percentage 33]
    if (percentage = 95) [set percentage 67]
    if (percentage = 99) [plot-pen-down set percentage 95]
    if (percentage = 100) [plot-pen-down set percentage 99]
  ]
  plot-pen-up

end

to simuNoiseAgents [namePlot]

  let nbTicks 4000
  set-current-plot "Noise Effect"
  create-temporary-plot-pen "Marques"
  set-current-plot-pen "Marques"
  set-plot-pen-color grey
  plotxy 0 2
  plot-pen-down
  plotxy nbTicks 2
  plot-pen-up
  set-current-plot-pen namePlot
  let x 0
  setup_values x x x x x x x 100 x x
  setup
  let avgEffort 0
  while [ticks < nbTicks]
  [
    go
    set avgEffort 0
    ask agents [
      set avgEffort avgEffort + effort
    ]
    set avgEffort (avgEffort / count agents)
    plotxy ticks avgEffort
    if ticks = 0 [plot-pen-down]

  ]

  plot-pen-up

end

to mutation
  if (sum binome_interactions_nature mod 500 = 0)
  [
  let moyenneProfit []
  let i 0
  while [i < 10]
    [
      ifelse ( (item i binome_interactions_nature) != 0)
      [

        if (mutation_type = "mutation_profit")
        [
          set moyenneProfit lput ( (item i binome_profit_nature) / (item i binome_interactions_nature) ) moyenneProfit
        ]

        if (mutation_type = "mutation_ratio")
        [
          set moyenneProfit lput ( (item i binome_profit_nature) / (item i binome_interactions_nature) / (item i binome_effort_nature + 0.000001) ) moyenneProfit
        ]
      ]
      [
        set moyenneProfit lput 0 moyenneProfit
      ]
      set i (i + 1)
    ]

  let newType typeAgent

  if (mutation_type = "mutation_profit")
  [
    if (max moyenneProfit >= profit_cumule / nbInteractions)
    [
      set newType position max moyenneProfit moyenneProfit
    ]
  ]
  if (mutation_type = "mutation_ratio")
  [
    if (max moyenneProfit >= profit_cumule / nbInteractions / (effort_cumule + 0.000001))
    [
      set newType position max moyenneProfit moyenneProfit
    ]
  ]

  if (newType != typeAgent)
    [
      set typeAgent newType
      if (typeAgent = 0) [
        set color red
      ]

      if (typeAgent = 1) [
        set color orange
      ]

      if (typeAgent = 2) [
        set color brown
      ]

      if (typeAgent = 3) [
        set color yellow
      ]

      if (typeAgent = 4) [
        set color green
      ]

      if (typeAgent = 5) [
        set color cyan
      ]

      if (typeAgent = 6) [
        set color blue
      ]

      if (typeAgent = 7) [
        set color violet
      ]

      if (typeAgent = 8) [
        set color magenta
      ]

      if (typeAgent = 9) [
        set color pink
      ]

    ]

  ]
end


; Simulation (Reproduire les courbes 6.15)
to simul_Noise
  clear-all-plots
  set useNoise? True
  set Noise 0.01
  simuNoiseAgents "Noise_Low_Level"
  set Noise 0.25
  simuNoiseAgents "Noise_Medium_Level"
  set Noise 0.5
  simuNoiseAgents "Noise_High_Level"
end
@#$#@#$#@
GRAPHICS-WINDOW
533
27
1032
430
-1
-1
23.3
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
20
0
15
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
10
1
0
Number

INPUTBOX
5
73
166
133
nbAgents_shrinking
10
1
0
Number

INPUTBOX
5
136
166
196
nbAgents_replicator
10
1
0
Number

INPUTBOX
5
199
166
259
nbAgents_rational
10
1
0
Number

INPUTBOX
5
262
166
322
nbAgents_profit
10
1
0
Number

INPUTBOX
5
325
166
385
nbAgents_high
10
1
0
Number

INPUTBOX
5
388
166
448
nbAgents_average_Rational
10
1
0
Number

INPUTBOX
5
451
166
511
nbAgents_winner
10
1
0
Number

INPUTBOX
5
514
166
574
nbAgents_effort
10
1
0
Number

INPUTBOX
5
577
166
637
nbAgents_averager
10
1
0
Number

BUTTON
282
306
355
339
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
386
305
449
338
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
254
235
481
268
Noise
Noise
0.01
0.5
0.26
0.01
1
NIL
HORIZONTAL

SWITCH
256
200
364
233
verbose?
verbose?
1
1
-1000

PLOT
230
488
627
688
Average Effort - HE Sim
High Effort Agents %
Effort
0.0
100.0
0.0
2.5
true
true
"" ""
PENS
"Null Effort" 1.0 0 -13345367 true "" ""
"Shrinking Effort" 1.0 0 -2064490 true "" ""
"Replicator" 1.0 0 -8630108 true "" ""
"Profit Comparator" 1.0 0 -4079321 true "" ""
"Winner Imitator" 1.0 0 -11221820 true "" ""
"Effort Comparator" 1.0 0 -6459832 true "" ""
"Averager" 1.0 0 -14835848 true "" ""
"Rational" 1.0 0 -955883 true "" ""
"Average_Rational" 1.0 0 -5825686 true "" ""

BUTTON
258
806
410
839
NIL
allHighEffortSims
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
717
563
845
596
NIL
clear-all-plots
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
131
706
226
739
Null - HE Sim
simuHighEffort 0
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
228
706
354
739
Shrinking - HE Sim
simuHighEffort 1
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
356
706
489
739
Replicator - HE Sim
simuHighEffort 2
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
490
706
601
739
Profit - HE Sim
simuHighEffort 4
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
603
706
721
739
Winner - HE Sim
simuHighEffort 7
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
122
743
235
776
Effort - HE Sim
simuHighEffort 8
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
236
743
364
776
Averager - HE Sim
simuHighEffort 9
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
365
743
519
776
Rational - HE Sim
simuHighEffort 3
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
520
743
732
776
AverageRational - HE Sim
simuHighEffort 6
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
365
200
479
233
useNoise?
useNoise?
1
1
-1000

BUTTON
1058
714
1172
747
Simul Noise
simul_Noise\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
911
488
1315
689
Noise Effect
Ticks
Effort
0.0
4000.0
0.0
2.5
true
true
"" ""
PENS
"Noise_Low_Level" 1.0 0 -5825686 true "" ""
"Noise_Medium_Level" 1.0 0 -4079321 true "" ""
"Noise_High_Level" 1.0 0 -13791810 true "" ""

BUTTON
473
809
611
842
Sims - Rational
SimsRational
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
1073
195
1212
256
Effort Moyen
(sum [effort] of agents) / count agents
5
1
15

TEXTBOX
591
438
741
456
Affichage par Nature
12
0.0
1

TEXTBOX
847
439
997
457
Affichage par Effort
12
0.0
1

SWITCH
299
368
427
401
mutation?
mutation?
0
1
-1000

CHOOSER
274
405
455
450
mutation_type
mutation_type
"mutation_profit" "mutation_ratio"
0

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
