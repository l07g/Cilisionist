#!/bin/bash

scan_dossier(){

for file in "$1"/*
do
	if [ -f "$file" ]
	then
		cat $file >> archive.txt
		printf "\n" >> archive.txt

	elif [ -d "$file" ]
	then
		scan_dossier "$file"
	fi

done
}

scan_dossier $1
