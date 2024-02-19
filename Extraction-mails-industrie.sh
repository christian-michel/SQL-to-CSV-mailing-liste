#!/bin/bash


#
# Créé le 22 septembre 2018 par Christian-Michel CHAMPON
# Pour Bref Eco
# licence GPL
#
# 
# Extraction pour le mailing de vérification des fiches annuaires (2 envois par an)
# ATTENTION : à la fin du travail, ouvrir le fichier 03_contacts_a_verifier.csv 
# et récupérer manuellement les bons mails exclus par erreur du fichier destiné à MailJet : 02_mailing_liste_dat_heure.csv
#
#
# Pour faire fonctionner le script : 
# 	1 - ouvrir un terminal, 
# 	2 - se déplacer dans le dossier du script et taper : ./Extract-mailing-annuaire.sh
# Si le script ne se lance pas, vérifier les droits d'exécution : ls -l
# Ajouter les droits si besoin : chmod +x Extract-mailing-annuaire.sh
# 	3 - traiter les erreurs manuellement pour compléter le fichier destiné à MailJet
#
#
# Algorithmique du script : 
# PARTIE 1 : RECUPERATION DES DONNEES
# 	extraction BDD >> 01_extraction_verif_fiche_anuaire_date_heure.csv
# PARTIE 2 : TRAITEMENT DES DONNEES
# 	données destinées à MailJet >> 02_mailing_liste_dat_heure.csv
# 	récupération des erreurs à traiter manuellement (pour compléter le fichier mailjet) >> 03_contacts_a_verifier.csv
#
#
# MailJet :
# l'id sera utilisé comme variable d'une url ayant la forme brefeco.com/node/$id, 
# dans un lien hypertext dans le corps du mail dans MailJet.
# Ainsi, chaque mail pointera sur la bonne fiche d'entreprise pour chaque personne.
#




# ===================================
# PARTIE 1 : RECUPERATION DES DONNEES
# ===================================

ma_base=annuaire
ma_table=entreprises

mysql_server=ip-server
mysql_user=userSQL
mysql_pass=passwordSQL

requete_sql="SELECT id, secteur_eco, email, contact_maj_email FROM $ma_base.$ma_table WHERE (secteur_eco='Sport') OR (secteur_eco='Emballage / Papier / Carton') OR (secteur_eco='Electrique / Electronique') OR (secteur_eco='Cosmétique / Parfumerie') OR (secteur_eco='Mécanique / Métallurgie') OR (secteur_eco='Navale / Nautique') OR (secteur_eco='Santé') OR (secteur_eco='Plasturgie / Caoutchouc / Composites') OR (secteur_eco='Textile / Habillement / Cuir') OR (secteur_eco='Constructeurs automobiles / Véhicules industriels') OR (secteur_eco='Bâtiment / Construction') OR (secteur_eco='Aéronautique / Aérospatiale') OR (secteur_eco='Agroalimentaire') OR (secteur_eco='Biens d\'équipement') OR (secteur_eco='Bois / Ameublement') OR (secteur_eco='Biens de consommation') OR (secteur_eco='Chimie')"
chemin=`pwd`
ma_date=`date '+%Y-%m-%d_%Hh%Mmin%Ss'`
save_name=Extraction_bdd_guides_mails_industrie_$ma_date.csv


mysql --default-character-set=utf8 -h $mysql_server -u $mysql_user --password=$mysql_pass -e "$requete_sql" | tr '\t' ',' | sed "s/$/\,/" > $chemin/$save_name

echo "Fin de l'export."




# ===================================
# PARTIE 2 : TRAITEMENT DES DONNEES
# ===================================

echo "Début du traitement."

file_traitement=02_mailing_liste_$ma_date.csv
contact_form=03_contacts_a_verifier.csv
regex_email='^[^ ][^\:][a-z0-9]+[\.a-z0-9\-]*@[a-z0-9]+[\.a-z0-9\-]*$'


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
    l_email=`echo $enreg | awk -F"," '{ print $2 }'`
    l_email_maj=`echo $enreg | awk -F"," '{ print $3 }'`

    # traitement
    
    # On doit conserver la première ligne : id,email,contact_maj_email
    if [ "$increment" -eq 0 ]
    then
        echo "$l_id,$l_email," >> $file_traitement
        ((increment++))
    else
        # on est au-delà de la ligne 1 du fichier
        
        # on teste l'id
        if [ -n $l_id ] && [[ "${l_id}" =~ ^[^:@.\ ][0-9]+$ ]]
        then
            # si l'id est bon, on test $email et $l_email_maj.
            declare -i l_id
            echo "L'ID est bon"

            # définir si $l_email est bon (contient un @ et pas de "/") ou pas
            if [[ "$l_email" =~ $regex_email ]] 
            then
                test_email="bon"
                echo "$l_email est bon"
            else
                test_email="pas_bon"
                echo "$l_email n'est pas bon"
            fi
            # définir si $l_email_maj est bon (contient un @ et pas de "/") ou pas
            if [[ "$l_email_maj" =~ $regex_email ]] 
            then
                test_email_maj="bon"
                echo "$l_email_maj est bon"
            else
                test_email_maj="pas_bon"
                echo "$l_email_maj n'est pas bon"
            fi

            # traitement des différentes actions selon le cas
            
            # $l_email bon && $l_email_maj bon  
            if [ $test_email = "bon" ] && [ $test_email_maj = "bon" ]
            then
                l_email="$l_email_maj"
                echo "$l_id,$l_email," >> $file_traitement
            
            # $l_email bon && $l_email_maj pas_bon 
            elif [ $test_email = "bon" ] && [ $test_email_maj = "pas_bon" ]
            then
                echo "$l_id,$l_email," >> $file_traitement
            
            # $l_email pas_bon && $l_email_maj bon 
            elif [ $test_email = "pas_bon" ] && [ $test_email_maj = "bon" ]
            then
                l_email="$l_email_maj"
                echo "$l_id,$l_email," >> $file_traitement
            
            # $l_email pas_bon && $l_email_maj pas_bon
            else
                echo "$l_email pas_bon && $l_email_maj pas_bon"
                # on récupère le données non-validées dans un fichier à part pour contrôler au cas où (03_contacts_a_verifier.csv)
                # pour les emails qui se retrouvent par erreur dans ce fichier, il faut les remettre manuellement dans le fichier d'envoi destiné à MailJet : 02_mailing_liste_date_heure.csv
                if [ -n "$l_email" ] && [ "$l_email" != "NULL" ]
                then
                    if [ "$increment_k" -eq 0 ]
				    then
				        echo "id,email," >> $contact_form
				        echo "$l_id,$l_email," >> $contact_form
				        ((increment_k++))
				    else
                    	echo "$l_email est une url"
                    	echo "$l_id,$l_email," >> $contact_form
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

