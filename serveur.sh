#! /bin/bash

# Ce script impl�mente un serveur.  
# Le script doit �tre invoqu� avec l'argument :                                                              
# PORT   le port sur lequel le serveur attend ses clients  

if [ $# -ne 1 ]; then
    echo "usage: $(basename $0) PORT"
    exit -1
fi

PORT="$1"

# D�claration du tube

FIFO="/tmp/$USER-fifo-$$"


# Il faut d�truire le tube quand le serveur termine pour �viter de
# polluer /tmp.  On utilise pour cela une instruction trap pour �tre sur de
# nettoyer m�me si le serveur est interrompu par un signal.

function nettoyage() { rm -f "$FIFO"; }
trap nettoyage EXIT

# on cr�e le tube nomm�

[ -e "$FIFO" ] || mkfifo "$FIFO"


function accept-loop() {
    while true; do
	interaction < "$FIFO" | netcat -l -p "$PORT" > "$FIFO"
    done
}

# La fonction interaction lit les commandes du client sur entr�e standard 
# et envoie les r�ponses sur sa sortie standard. 
#
# 	CMD arg1 arg2 ... argn                   
#                     
# alors elle invoque la fonction :
#                                                                            
#         commande-CMD arg1 arg2 ... argn                                      
#                                                                              
# si elle existe; sinon elle envoie une r�ponse d'erreur.                     

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

# Les fonctions impl�mentant les diff�rentes commandes du serveur


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
			debut_header="$(head -1 $2 | awk 'BEGIN {FS=":"; FNR=1} {print $1}')"
			echo "debut du header: $debut_header"
			debut_body="$(head -1 $2 | awk 'BEGIN {FS=":"; FNR=1} {print $2}')"
			echo "debut du body: $debut_body"
			
			nligne_courante="$debut_header"
			echo "ligne courante: $nligne_courante"
			ligne_courante="$(awk 'NR==$nligne_courante)"
			echo "$ligne_courante"
			

			#erreur de merde a la con qui fait chier: problème de guillements dans le while

			#while [ $ligne_courante -lt $debut_body ]
			#do
				if [ "$ligne_courante" =~ "/^directory/" ];
				then
					directory=$(echo "$ligne_courante" | awk '{print $2}')
					#mkdir -p "$directory"
				fi
			#done
		else
			"wallah, tu n'as pas entre un nom d'archive valide"
		fi
	else
		echo "mashallah, t'as entré une option invalide, essaie plutot -list, -browse ou -extract"
	fi
}




# On accepte et traite les connexions

accept-loop

