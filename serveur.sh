#! /bin/bash

# Ce script implémente un serveur.  
# Le script doit être invoqué avec l'argument :                                                              
# PORT   le port sur lequel le serveur attend ses clients  

if [ $# -ne 1 ]; then
    echo "usage: $(basename $0) PORT"
    exit -1
fi

PORT="$1"

# Déclaration du tube

FIFO="/tmp/$USER-fifo-$$"


# Il faut détruire le tube quand le serveur termine pour éviter de
# polluer /tmp.  On utilise pour cela une instruction trap pour être sur de
# nettoyer même si le serveur est interrompu par un signal.

function nettoyage() { rm -f "$FIFO"; }
trap nettoyage EXIT

# on crée le tube nommé

[ -e "$FIFO" ] || mkfifo "$FIFO"


function accept-loop() {
    while true; do
	interaction < "$FIFO" | netcat -l -p "$PORT" > "$FIFO"
    done
}

# La fonction interaction lit les commandes du client sur entrée standard 
# et envoie les réponses sur sa sortie standard. 
#
# 	CMD arg1 arg2 ... argn                   
#                     
# alors elle invoque la fonction :
#                                                                            
#         commande-CMD arg1 arg2 ... argn                                      
#                                                                              
# si elle existe; sinon elle envoie une réponse d'erreur.                     

function interaction() {
    local cmd args
    while true; do
	read cmd args || exit -1
	fun="commande-$cmd"
	if [ "$(type -t $fun)" = "function" ]; then
	    $fun $args
	else
	    commande-non-comprise $fun $args
	fi
    done
}

# Les fonctions implémentant les différentes commandes du serveur


function commande-non-comprise () {
	echo "Le serveur ne peut pas interpreter cette commande"
}

function commande-exit() {
	exit 1
}

function commande-vsh() {
	if [ $1 = "-list" ];
	then
		ls -l  | grep "archive.*txt"
	elif [ $1 = "-browse" ]
	then
		if [ -f $2 ];
		then
			printf "\n"
			cat $2
		else
			echo "wallah, tu n'as pas entre un nom d'archive valide"
		fi
	elif [ $1 = "-extract" ]
	then
		echo "wesh, cette partie est encore en construction"
		if [ -f $2 ];
		then
			printf "\n Initialisation de l'extraction \n"
			debut_header="$(head -1 $2 | awk 'BEGIN {FS=":"; FNR=1} {print $1}')"
			echo "debut du header: $debut_header"
			debut_body="$(head -1 $2 | awk 'BEGIN {FS=":"; FNR=1} {print $2}')"
			debut_body="$(echo $debut_body | tr -d '\r' )"
			echo "debut du body: $debut_body"
			
			echo "ligne courante: $debut_header"

			for i in `seq $debut_header $((debut_body-1))`;
			do
				
				ligne_courante="$(cat $2 | awk -v nligne="$i" '{if(NR==nligne) {print $0}}' )"
				echo "ligne courante: $ligne_courante"

				fmm="$( echo $ligne_courante | grep -ce "^directory" )"
				if [ $fmm -eq 1 ];
				then
					directory="$(echo "$ligne_courante" | awk '{print $2}')"
					directory="$(echo $directory | tr -d '\r' )"
					mkdir -p "$directory"
					echo "création dossier: $directory"
				fi
				
				ligne_debut_fichier="$(echo $ligne_courante | awk '{if (NF==5) {print $4 } else {print '-1'}}')"
				n_ligne_fichier="$(echo $ligne_courante | awk '{if (NF==5) {print $5 } else {print '-1'}}')"
				n_ligne_fichier="$(echo $n_ligne_fichier | tr -d '\r' )"
				
				if [ $ligne_debut_fichier -gt -1 ];
				then

					nom_fichier="$(echo $ligne_courante | awk '{print $1}')"
					racine="$directory/$nom_fichier"
					echo "root= $racine"
					ligne_debut_fichier=$(($debut_body+$ligne_debut_fichier-1))
					ligne_fin_fichier=$(($ligne_debut_fichier+$n_ligne_fichier-1))
					sed "$ligne_debut_fichier,$ligne_fin_fichier!d" $2 
					sed "$ligne_debut_fichier,$ligne_fin_fichier!d" $2 >> "$racine"
				fi
				

			done
			echo "c'est fini"
		else
			"wallah, tu n'as pas entre un nom d'archive valide"
		fi
	else
		echo "mashallah, t'as entrÃ© une option invalide, essaie plutot -list, -browse ou -extract"
	fi
}




# On accepte et traite les connexions

accept-loop

