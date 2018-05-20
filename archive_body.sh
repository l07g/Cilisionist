#!/bin/bash

scan_dossier(){


#scan dossier actuel
for file in "$1"/*
do
	#Si c'est un fichier...
	if [ -f "$file" ]
	then
		#on met dans un fichier
		cat $file >> archive.txt
		printf "\n" >> archive.txt

	#Si c'est un dossier...
	elif [ -d "$file" ]
	then
		#On recommence dans le nouveau dossier
		scan_dossier "$file"
	fi

done
}

scan_dossier $1
