extends Node2D

##############################################################################
############################### VARIABLES ####################################
##############################################################################

var Players = []
var Nb_Players
var Current_Player = 0
var case = 100
var color = Colors.Red
var X_Comp = 10
var Y_Comp = 5
var Grid
onready var J_R = preload("res://Jeton_Rouge.tscn")
onready var J_B = preload("res://Jeton_Bleu.tscn")
var Nb_Choix = 4

###############################################################################
############################ ENUMERATIONS #####################################
###############################################################################

enum Gains{
	PTS_PLUS, PTS_MINUS, HP_PLUS, HP_MINUS, SPECIAL_1, SPECIAL_2, SPECIAL_3, NB_GAINS
}

enum Units{
	NOP, R_1 , R_2, R_3, R_4, B_1, B_2, B_3, B_4, NB_UNITES
}

enum Colors{
	Red, Blue, NB_COLORS
}

############################################################################
######################## CODE GENERAL ######################################
############################################################################

func _ready():
	$Red.move_local_x(case/2)
	$Red.move_local_y(case/2)
	create_grid()
	init_nb_player()

func create_grid():
	Grid = []
	for i in range(X_Comp):
		Grid.append([])
		for j in range(Y_Comp):
			Grid[i].append([0,""])


func switch_color():
	if color == Colors.Red:
		$Red/Sprite.set_texture($Red.Blue_Sprite)
		color = Colors.Blue
	else:
		$Red/Sprite.set_texture($Red.Red_Sprite)
		color = Colors.Red
	Current_Player = (Current_Player + 1) % Nb_Players
		
func position_in_grid(nodePath):
	var vect = to_global(get_node(nodePath).position)
	#print("GLOBAL:" , vect)
	return Vector2(int(vect.x)/case,int(vect.y)/case)

func in_the_grid(vect,nodePath): #take the local futur deplacement of Red, and says 
								#if it's ok
	vect += position_in_grid(nodePath)
	#print("MODIFIED:" , vect)
	if 0 <= vect.x && vect.x <= (X_Comp - 1) && 0 <= vect.y && vect.y <= (Y_Comp - 1):
		return true
	return false

func movement_question(vect,nodePath):
	if in_the_grid(vect,nodePath):
		get_node(nodePath).position += vect*case

func new_unit(number,nodePath):
	place_unit(number,nodePath)

func place_unit(number, nodePath):
	var vect = position_in_grid(nodePath)
	number += Nb_Choix * int(color == Colors.Blue)
	print(Current_Player,vect)
	var cost = cout_placement(vect,number%Nb_Choix)
	if Grid[vect.x][vect.y][0] == 0:
		if Players[Current_Player].Nb_Unites[number%Nb_Choix-1] >= cost:
			var son
			Players[Current_Player].Nb_Unites[number%Nb_Choix-1] -= cost
			print(Current_Player," A ENCORE ",Players[Current_Player].Nb_Unites[number%Nb_Choix-1])
			match number:
				1:
					son = J_R.instance()
				5:
					son = J_B.instance()
			Grid[vect.x][vect.y] = [number,son]
			son.set_global_position(Vector2(case/2 + case*vect.x,case/2 + case*vect.y))
			get_node("Stockage").add_child(son)
			var result_array = check_pattern_position(vect)
			if result_array != []:
				Payoff(result_array[-1][0],result_array[-1][1])
				check_victory()
				var tempo_vect
				for j in range(result_array.size()-1):
					tempo_vect = Vector2(vect.x + result_array[j][0],vect.y + result_array[j][1])
					delete_piece(tempo_vect,result_array,j)
			switch_color() # !!! ON A DONC CHANGE LE Current_Player !!!
	else:
		pass
		#print(Grid[vect.x][vect.y])
		#son.queue_free()

func delete_piece(tempo_vect,result_array,j):
	var num_color =  Grid[tempo_vect.x][tempo_vect.y][0]
	var concerned_player = floor((num_color-1/2)/Nb_Choix)
	#print("INDEX:",num_color - concerned_player*Nb_Choix,"// CONCERNED PLAYER:",concerned_player,"// COUT:",cout_placement(tempo_vect))
	Grid[tempo_vect.x][tempo_vect.y][0] = 0
	print(Players[concerned_player].Nb_Unites)
	Players[concerned_player].Nb_Unites[num_color - concerned_player*Nb_Choix - 1] += cout_placement(tempo_vect,num_color%Nb_Choix)
	print(Players[concerned_player].Nb_Unites)
	Grid[tempo_vect.x][tempo_vect.y][0] = 0
	Grid[tempo_vect.x][tempo_vect.y][1].queue_free()

func association_color(color):
	match color:
		Colors.Red:
			return "ROUGE"
		Colors.Blue:
			return "BLEU"
		_:
			return "INDEFINI"

func init_nb_player():
	Nb_Players = global.Class_Players.size()
	for i in range(Nb_Players):
		match global.Class_Players[i]:
			global.Factions.WARRIOR:
				Players.append(Warrior.new())

func cout_placement(vect,nb_unit):
	#print("PLUS:",float(Current_Player)/(Nb_Players)*X_Comp,"// MOINS:",float((Current_Player+1))/(Nb_Players)*X_Comp,"// NB:",Nb_Players,"// X_COMP:",X_Comp)
	if (vect.x >= float(Current_Player)/(Nb_Players)*X_Comp) && (vect.x < float((Current_Player+1))/(Nb_Players)*X_Comp):
		return Players[Current_Player].owner_cost(vect,nb_unit)
	#return (1+vect.x-(Current_Player+1)/(Nb_Players-1)*X_Comp)
	# Plus c'est loin chez l'adversaire, plus ça coûte cher (mauvaise idée)
	return Players[Current_Player].stranger_cost(vect,nb_unit)


func belong_to(vect):
	print(vect.x," APPARTIENT A ",floor(vect.x/(X_Comp*(1-1/Nb_Players))*Nb_Players))
	return floor(vect.x/(X_Comp*(1-1/Nb_Players))*Nb_Players)
	

##########################################################################
############################ Partie Pattern ##############################
##########################################################################


func check_pattern_position(vect,espion=false):
	var colors = []
	var already_exists
	for i in range(Nb_Choix):
		colors.append(0)
	colors[0] = Grid[vect.x][vect.y][0]
	var size_serie
	var count
	for i in range(Players[Current_Player].TMG.size()):
		for k in range(0,Nb_Choix):
			colors[k] = 0
		size_serie = Players[Current_Player].TMG[i].size() - 1
		count = 0
		for j in range(size_serie):
			if (vect.x + Players[Current_Player].TMG[i][j][0] < X_Comp) && (vect.y + Players[Current_Player].TMG[i][j][1] < Y_Comp) && (vect.x + Players[Current_Player].TMG[i][j][0] >= 0) && (vect.y + Players[Current_Player].TMG[i][j][1] >= 0):
				if colors[Players[Current_Player].TMG[i][j][2] - 1] == 0:
					var num_color =  Grid[vect.x + Players[Current_Player].TMG[i][j][0]][vect.y + Players[Current_Player].TMG[i][j][1]][0]
					if num_color != 0 && (floor((num_color-1/2)/Nb_Choix) == Current_Player || espion ):
						already_exists = 0
						for k in range(Nb_Choix):
							if colors[k] != 0:
								if colors[k] == num_color:
									already_exists += 1
						colors[Players[Current_Player].TMG[i][j][2] - 1] = Grid[vect.x + Players[Current_Player].TMG[i][j][0]][vect.y + Players[Current_Player].TMG[i][j][1]][0]
						if !already_exists :
							count += 1
				elif (colors[Players[Current_Player].TMG[i][j][2] - 1] == Grid[vect.x + Players[Current_Player].TMG[i][j][0]][vect.y + Players[Current_Player].TMG[i][j][1]][0]) :
					count += 1
		if count == size_serie:
			return Players[Current_Player].TMG[i]
	return []

func Payoff(nature, level): # nature: pts_plus, ... // level: puissance de la combi
	match nature:
		Gains.PTS_PLUS:
			Players[Current_Player].Pts += Players[Current_Player].pts_levels(level)
			print("COULEUR:",color," //POINTS:",Players[Current_Player].Pts)
		Gains.PTS_MINUS:
			for i in range(Nb_Players):
				if i  != Current_Player:
					Players[i].Pts += Players[Current_Player].pts_level(level)
		Gains.HP_PLUS:
			Players[Current_Player].HP += Players[Current_Player].HP_levels(level)
		Gains.HP_MINUS:
			for i in range(Nb_Players):
				if i  != Current_Player:
					Players[i].HP += Players[Current_Player].HP_levels(level)
		Gains.SPECIAL_1:
			Players[Current_Player].special_1(level)
		Gains.SPECIAL_2:
			Players[Current_Player].special_2(level)
		Gains.SPECIAL_3:
			Players[Current_Player].special_3(level)

func check_victory():
	for i in range(Nb_Players):
		if i  != Current_Player:
			if  Players[i].HP <= 0: # !!! NE VERIFIE
		# QUE LA VICTOIRE DU JOUEUR ACTUEL (normalement pas possible de se faire 
		#perdre, mais on sait jamais (classe piège ? Bofbof)
				win()
				return
	if Players[Current_Player].Pts >= Players[Current_Player].Pts_Objective:
		win()
		return
	Players[Current_Player].special_victory()

func win():
	var GLobal = load("res://Global.gd")
	global.Winner = association_color(color)
	print("GAGNEEEEEEE POUR LE JOUEUR ", association_color(color))
	end_screen()

func end_screen():
	get_tree().change_scene("res://Ecran_Fin.tscn")


#TODO: Afficher un HUB
#TODO: Modifier le pattern checking histoire de pouvoir avoir des combos

##############################################################################
############################## CLASSES #######################################
##############################################################################

class Faction extends Node2D:
	var TMG = [[[0,0,1],[0,1,1],[0,-1,1],[Gains.PTS_PLUS, 1]], #Pour un minus, level < 0 !!!
		[[0,0,1],[1,0,1],[-1,0,1],[Gains.PTS_PLUS, 1]], # [0,0,1] : case actuelle, couleur 1

		[[0,0,1],[0,1,1],[0,2,1],[Gains.PTS_PLUS, 1]],
		[[0,0,1],[1,0,1],[2,0,1],[Gains.PTS_PLUS, 1]],
		[[0,0,1],[0,-1,1],[0,-2,1],[Gains.PTS_PLUS, 1]],
		[[0,0,1],[-1,0,1],[-2,0,1],[Gains.PTS_PLUS, 1]],
		
		[[0,0,1],[1,0,2],[0,1,2],[1,1,1],[Gains.PTS_PLUS, 1]], # Possible opti : dire dès le debut ce qui est necessaire dans les 4 directions)
		[[0,0,1],[-1,0,2],[0,-1,2],[-1,-1,1],[Gains.PTS_PLUS, 1]],
		[[0,0,1],[-1,0,2],[0,1,2],[-1,1,1],[Gains.PTS_PLUS, 1]],
		[[0,0,1],[1,0,2],[0,-1,2],[1,-1,1],[Gains.PTS_PLUS, 1]],
		] #Tableau des masques généraux
		# !!! TRIER PAR ORDRE DE PRIORITE DECROISSANT !!! (ptet en faire plusieurs
		#séparés, chacun s'arretant au premier sélectionné, mais comme ca on peut
		#cumuler plusieurs patterns sans changer le fonctionnement)

	var Nb_Unites = [10,10,10,10]#Le tableau récapitulant le nombre max de points 
							 #d'unité de chaque type (de ton coté = moins dépensés)
	var Nb_Unites_Max = [10,10,10,10]

	var Ressource #La ressource propre à la faction
	
	var HP = 10
	var Max_HP = 10
	
	var Pts = 0
	var Pts_Objective = 10
	
	
	func pts_levels(level): #How much point gain or loss scales
		if level > 0:
			return level*2 + 1
		else:
			return level*2 - 1
		
	func HP_levels(level): #How much HP gain or loss scales
		if level > 0:
			return level*2 + 1
		else:
			return level*2 - 1
	
	func special_1(level):
		pass
	
	func special_2(level):
		pass
	
	func special_3(level):
		pass
	
	func special_victory():
		pass
	
	func owner_cost(vect,nb_unit):
		print("OWNER")
		return 1
	
	func stranger_cost(vect,nb_unit):
		print("STRANGER")
		#print(load("res://Main.gd").belong_to(vect)) #ca marche pas, casse les couilles ...
		#return 1+abs(get_node("res://Main.gd").belong_to(vect)) #Plus c'est loin, plus ca coute
		return 2

class Warrior extends Faction:
	var TMF = [[[0,0,1],[1,0,2],[0,1,2],[1,1,1],[Gains.PTS_PLUS, 1]], # Possible opti : dire dès le debut ce qui est necessaire dans les 4 directions)
	[[0,0,1],[-1,0,2],[0,-1,2],[-1,-1,2],[Gains.PTS_PLUS, 1]],
	[[0,0,1],[-1,0,2],[0,1,2],[-1,1,1],[Gains.PTS_PLUS, 1]],
	[[0,0,1],[1,0,2],[0,-1,2],[1,-1,1],[Gains.PTS_PLUS, 1]],
	[[],[],[],[Gains.PTS_PLUS, 1]]
	#[[],[],[],[Gains.PTS_PLUS, 1]]
	]#Tableau des masques de faction
	
	var agressive = false # If true, berzerker mode 
	func _init():
		Max_HP = 20
		HP = Max_HP
	
	func pts_level(level):
		if agressive:
			return level*2 - 1
		return level*2 
	
	func HP_levels(level):
		if level > 0:
			if agressive:
				return level*5	
			return level*3 + 1
		if agressive: # Theoriquement les else ne servent a rien (retours partout)
			return level
		return level*3 - 1
