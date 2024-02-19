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

requete_sql="SELECT * FROM $ma_base.$ma_table"
chemin=`pwd`
ma_date=`date '+%Y-%m-%d_%Hh%Mmin%Ss'`
save_name=Extraction_bdd_guides_$ma_date.csv


mysql --default-character-set=utf8 -h $mysql_server -u $mysql_user --password=$mysql_pass -e "$requete_sql" | tr '\t' ',' | sed "s/$/\,/" > $chemin/$save_name

echo "Fin de l'export."


