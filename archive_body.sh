#!/bin/bash

scan_dossier(){

for file in "$1"/*
do
	if [ -f "$file" ]
	then
		cat $file
		printf "\n"

	elif [ -d "$file" ]
	then
		scan_dossier "$file"
	fi

done
}

scan_dossier $1
