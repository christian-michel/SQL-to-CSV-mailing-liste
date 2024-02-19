#!/bin/bash


#
# Créé le 12 novembre 2018 par Christian-Michel CHAMPON
# Pour Bref Eco
# licence GPL
#
# 
# Extraction pour la mise à jur des fiches annuaire, tout au long de l'année
# ATTENTION : à la fin du travail, ouvrir le fichier 03_ca_a_verifier.csv 
#
#
# Pour faire fonctionner le script : 
# 	1 - ouvrir un terminal, 
# 	2 - se déplacer dans le dossier du script et taper : ./Extract-vieux-ca.sh
# Si le script ne se lance pas, vérifier les droits d'exécution : ls -l
# Ajouter les droits si besoin : chmod +x Extract-mailing-annuaire.sh
# 	3 - traiter les erreurs manuellement pour mettre à jour les fiches annuaire sur le site brefeco.com
#
#
# Algorithmique du script : 
# PARTIE 1 : RECUPERATION DES DONNEES
# 	extraction BDD >> 01_extraction_verif_fiche_anuaire_date_heure.csv
# PARTIE 2 : TRAITEMENT DES DONNEES
# 	données à mettre à jour >> 02_ca_a_mettre_a_jour.csv
# 	récupération des vides ou NULL >> 03_ca_a_verifier.csv
#





# ===================================
# PARTIE 1 : RECUPERATION DES DONNEES
# ===================================

ma_base=annuaire
ma_table=entreprises

mysql_server=54.36.120.164
mysql_user=annuaire
mysql_pass=Q46R0ufPFrneTUDcQHRA
read -p 'On souhaite trouver les fiches annuaires dont le CA est antérieur ou égal à : ' annee_vieux_ca

requete_sql="SELECT id, annee_ca, annee_ca_groupe, guide_eco, guide_innov FROM $ma_base.$ma_table"
chemin=`pwd`
ma_date=`date '+%Y-%m-%d_%Hh%Mmin%Ss'`
save_name=01_extraction_tous_les_ca_sur_annuaire_$ma_date.csv


mysql --default-character-set=utf8 -h $mysql_server -u $mysql_user --password=$mysql_pass -e "$requete_sql" | tr '\t' ',' | sed "s/$/\,/" > $chemin/$save_name

echo "Fin de l'export."




# ===================================
# PARTIE 2 : TRAITEMENT DES DONNEES
# ===================================

echo "Début du traitement."

file_traitement=02_ca_a_mettre_a_jour.csv
erreur=03_ca_a_verifier_ou_a_completer.csv

declare -i increment
increment=0
declare -i increment_k
increment_k=0
enreg=`cat $save_name`


# Parcourir le fichier (et retirer les espaces pour éviter les bugs vue qu'après on coupe avec awk)
for enreg in `cat $save_name | tr -d "\ "`
do
    echo $enreg
    l_id=`echo $enreg | awk -F"," '{ print $1 }'`
    l_annee_ca=`echo $enreg | awk -F"," '{ print $2 }'`
    l_annee_ca_groupe=`echo $enreg | awk -F"," '{ print $3 }'`
	guide_eco=`echo $enreg | awk -F"," '{ print $4 }'`
	guide_innov=`echo $enreg | awk -F"," '{ print $5 }'`

    # traitement
    
    # On doit conserver la première ligne : id,annee_ca,annee_ca_groupe
    if [ "$increment" -eq 0 ]
    then
        echo "$l_id,$l_annee_ca,$l_annee_ca_groupe,$guide_eco,$guide_innov" >> $file_traitement
        ((increment++))
    else
        # on est au-delà de la ligne 1 du fichier
        
        # on teste l'id
        if [ -n $l_id ] && [[ "${l_id}" =~ ^[^:@.\ ][0-9]+$ ]]
        then
            # si l'id est bon, on test $annee_ca et $annee_ce_groupe.
            declare -i l_id
            echo "L'ID est bon"

            # ne prendre que les fiches société exportées dans le guide éco ou dans le guide innov
			if [ $guide_eco = "1" ] || [ $guide_innov = "1" ]
			then
				
				echo "Cette fiche est exporté sur l'annuaire papier."
				
				# regarder si $l_annee_ca est un nombre
				# regarder si l_annee_ca_groupe est un nombre
				if [ "$(echo $l_annee_ca | grep "^[[:digit:]]*$")" ] || [ "$(echo $l_annee_ca_groupe | grep "^[[:digit:]]*$")" ]
				then
					# si l'un des deux est un nombre et que ce nombre est inférieur $annee_vieux_ca >> $file_traitement
					if [ $l_annee_ca -le $annee_vieux_ca ] || [ $l_annee_ca -le $annee_vieux_ca ]
					then
						echo "$l_id,$l_annee_ca,$l_annee_ca_groupe,$guide_eco,$guide_innov" >> $file_traitement
					fi
				else
					# si aucun des deux n'est un nombre >> $erreur
					if [ "$increment_k" -eq 0 ]
						then
							echo "id,annee_ca,annee_ca_groupe,guide_eco,guide_innov" >> $erreur
							echo "$l_id,$l_annee_ca,$l_annee_ca_groupe,$guide_eco,$guide_innov" >> $erreur
							((increment_k++))
						else
							echo "$l_id,$l_annee_ca,$l_annee_ca_groupe,$guide_eco,$guide_innov" >> $erreur
							((increment_k++))
						fi
			   
				fi
				
			fi
            ((increment++))
        else
            # si l'id n'est pas bon, on supprime la ligne du fichier et on passe au traitement de la suivante
            echo "L'ID n'est pas bon."
            ((increment++))
        fi
    fi
done

echo "Voici les fiches annuaires destinées à l'export dans les annuaires papier éco ou innov dont le CA est antérieur ou égal à : $annee_vieux_ca"
