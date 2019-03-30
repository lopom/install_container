#!/bin/bash
# Installation de sonarr/radarr/jackett/rutorrent/plex
# Paramettre 1 = Préfix que vous voulez donner aux containers
# Paramettre 2 = Chemin ou vous voulez que soit votre docker-compose.yml
# Paramettre 3 = Chemin des fichiers de conf des containers
# Paramettre 4 = Nom de domaine (Si vous en avez un)

nom=$1
chemin_2=$2
chemin_3=$3
ndd=$4

install_docker-ce() {
sudo apt-get update
sudo apt install apt-transport-https ca-certificates curl gnupg2 software-properties-common
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
sudo apt update
sudo apt install docker-ce
}

install_docker-compose(){
sudo apt-get install docker-compose
}

install_nginx_letsencrypt() {
cat >> docker-compose.yml <<EOF
  nginx:
    image: jwilder/nginx-proxy:alpine
    restart: always
    container_name: nginx
    ports:
      - 80:80
      - 443:443
    environment:
      - DHPARAM_BITS=4096
    volumes:
      - $1/nginx/proxy/conf.d:/etc/nginx/conf.d
      - $1/nginx/proxy/vhost.d:/etc/nginx/vhost.d
      - $1/nginx/proxy/html:/usr/share/nginx/html
      - $1/nginx/proxy/certs:/etc/nginx/certs:ro
      - $1/nginx/proxy/htpasswd:/etc/nginx/htpasswd:ro
      - $1/nginx/docker.sock:/tmp/docker.sock:ro

  letsencrypt-companion:
    image: jrcs/letsencrypt-nginx-proxy-companion
    container_name: letsencrypt-companion
    restart: always
    volumes_from:
      - nginx
    volumes:
      - $1/ssl/docker.sock:/var/run/docker.sock:ro
      - $1/nginx/proxy/certs:/etc/nginx/certs:rw
  depends_on:
      - nginx

EOF
}

install_sonarr_radarr(){
cat >> docker-compose.yml <<EOF
  $1_radarr:
    restart: always
    image: linuxserver/radarr
    container_name: $1_radarr
    volumes:
      - $3/radarr/config:/config
      - $2/incoming/torrents:/downloads
      - $2/incoming/Media/Movies:/movies environment:
      - VIRTUAL_PORT=7878
      - VIRTUAL_HOST=radarr.srvmx.eu
      - LETSENCRYPT_HOST=radarr.srvmx.eu
      - LETSENCRYPT_EMAIL=contact@srvmx.eu
      - PGID=1000 - PUID=1000
    depends_on:
      - $1_rutorrent

  $1_sonarr:
    restart: always
    image: linuxserver/sonarr
    container_name: $1_sonarr
    volumes:
      - $3/sonarr/config:/config
      - $3/sonarr/tv:/tv
      - $2/incoming/torrents:/downloads
    environment:
      - VIRTUAL_PORT=8989
      - VIRTUAL_HOST=sonarr.srvmx.eu
      - LETSENCRYPT_HOST=sonarr.srvmx.eu
      - LETSENCRYPT_EMAIL=contact@srvmx.eu
      - PUID=1000
      - PGID=1000
    depends_on:
      - $1_rutorrent

EOF
}

install_plex_serveur() {
cat >> docker-compose.yml <<EOF
EOF
}

install_jackett() {
cat >> docker-compose.yml <<EOF
  $1_jackett:
    restart: always
    image: linuxserver/jackett
    container_name: $1_jackett
    volumes:
      - $2/jackett:/home/jackett/.config/Jackett
      - $2/jackett:/home/jackett/.downloads/Jackett
    environment:
      - UID=1001
      - GID=1001
      - VIRTUAL_PORT=9117
      - VIRTUAL_HOST=jackett.srvmx.eu
      - LETSENCRYPT_HOST=jackett.srvmx.eu
      - LETSENCRYPT_EMAIL=contact@srvmx.eu

EOF
}

install_rutorrent(){
cat >> docker-compose.yml <<EOF
  $1_rutorrent:
    restart: always
    image: xataz/rtorrent-rutorrent:latest-filebot
    container_name: $1_rutorrent
    volumes:
      - $2/incoming:/data:rw
      - $3/rtorrent/conf:/config:rw
    ports:
      - "45000:45000"
      - "45000:45000/udp"
    environment:
      - UID=1000
      - GID=1000
      - PORT_RTORRENT=45000
      - WEBROOT=/
      - VIRTUAL_PORT=8080
      - VIRTUAL_HOST=rutorrent.srvmx.eu
      - LETSENCRYPT_HOST=rutorrent.srvmx.eu
      - LETSENCRYPT_EMAIL=admin@srvmx.eu
      - DISABLE_PERM_DATA=true
    tty: true
	
EOF
}

install_watchtower(){
cat >> docker-compose.yml <<EOF
  watchtower:
    image: v2tec/watchtower
    container_name: watchtower
    hostname: watchtower
    volumes:
      - $1/watchtower/conf/docker.sock:/var/run/docker.sock
      - $1/watchtower/conf/localtime:/etc/localtime:ro
    restart: always
    command: --cleanup
    environment:
      - TZ=Europe/Paris
	  
EOF
}

install_plex(){
cat >> docker-compose.yml <<EOF
  $1_plex:
    container_name: $1_plex
    image: plexinc/pms-docker
    restart: always
    environment:
      - TZ=Europe/Paris
      - PLEX_CLAIM=$claim
      - PLEX_UID=1000
      - PLEX_GID=1000
    hostname: $1_plex
    volumes:
      - $3/plex/config:/config
      - $3/plex/transcode:/transcode
      - $2/plex/data:/data
EOF
}
if [ "$1" = "" ]
then
        echo "Le script s'execute de la facon suivante : ./test <prefixe_container*> <chemin_dockercompose+films_séries*> <chemin_dossier_conf*> <nom_de_domaine>"
        echo "l'étoile (*) signifie que le paramettre est obligatoire"
        exit
fi

if [ "$2" = "" ]
then
        echo "Le script s'execute de la facon suivante : ./test <prefixe_container*> <chemin_dockercompose.yml+films_series*> <chemin_dossier_conf*> <nom_de_domaine>"
        echo "l'étoile (*) signifie que le paramettre est obligatoire"
        exit
fi

if [ "$3" = "" ]
then
        echo "Le script s'execute de la facon suivante : ./test <prefixe_container*> <chemin_dockercompose.yml+films_séries*> <chemin_dossier_conf*> <nom_de_domaine>"
        echo "l'étoile (*) signifie que le paramettre est obligatoire"
        exit
fi

if [ ! -d "$2" ]
        then
                mkdir $2
fi

cd $2
put_header(){
cd $1
cat >> docker-compose.yml <<EOF
version: '2'

services:

EOF
}

check_header_exist(){
if [ -f $1/docker-compose.yml ]
then
        check_compose=$(cat "$1"/docker-compose.yml | grep service | wc -l)
        if [ "$check_compose" = "0" ]
        then
                put_header $chemin_2
        fi
fi
}
while [ 1 ]
do
        clear
        echo "
---- MENU PRINCIPAL ----

[OK] (I) Installer docker + docker compose (Linux uniquement)
[OK] (1) Tout configurer (Nginx/Let's Encrypt/Sonarr/Radarr/Plex Serveur/Jackett/watchtower)
[OK] (2) Configurer Nginx/Let's Encrypt
[OK] (3) Configurer Sonarr/Radarr
[OK] (4) Configurer Plex Serveur
[OK] (5) Configurer jackett
[OK] (6) Configurer rutorrent
[OK] (7) Configurer watchtower
[A FAIRE] (8) Configurer une autre image docker
[OK] (9) Finaliser l'installation (A faire lorsque vous avez configuré toutes les images souhaitées)

(Q) Quitter
        "
        echo "Choisissez une option :"
        read opt
        case $opt in
                
				I|i)	check_docker_ce=$(apt list --installed 2>/dev/null | grep docker-ce | wc -l)
						check_docker_compose=$(apt list --installed 2>/dev/null | grep docker-compose | wc -l)
						if [ "$check_docker-ce" = "0" ]
						then
							install_docker-ce
						else
							echo "Docker-ce déjà installé"
						fi
						if [ "$check_docker-compose" = "0" ]
						then
							install_docker-compose
						else
							echo "Docker-compose déjà installé"
						fi
						exit 0
						;;
						
				1)		check_header_exist $chemin_2
						if [ -f "$2/docker-compose.yml" ]
                        then
                                echo "Un fichier docker-compose.yml existe déjà"
                                echo "Est-ce un [a]jout au docker-compose.yml existant ou un [n]ouveau docker-compose.yml ([n] supprimera l'ancien) ? [a/n]"
                                read add_or_new
                                if [ "$add_or_new" = "a" ]
                                then
                                        install_nginx_letsencrypt $chemin_3
										install_sonarr_radarr $nom $chemin_2 $chemin_3
										install_jackett $nom $chemin_3
										install_rutorrent $nom $chemin_2 $chemin_3
										install_watchtower $chemin_3
                                else
                                        put_header $chemin_2
                                        rm -rf $2/docker-compose.yml
                                        install_nginx_letsencrypt $chemin_3
										install_sonarr_radarr $nom $chemin_2 $chemin_3
										install_jackett $nom $chemin_3
										install_rutorrent $nom $chemin_2 $chemin_3
										install_watchtower $chemin_3
                                fi
                        else
                                put_header $chemin_2
                                install_nginx_letsencrypt $chemin_3
								install_sonarr_radarr $nom $chemin_2 $chemin_3
								install_jackett $nom $chemin_3
								install_rutorrent $nom $chemin_2 $chemin_3
								install_watchtower $chemin_3
                        fi
                        clear
                        exit 0
                        ;;
                2)
                        check_header_exist $chemin_2
                        if [ -f "$2/docker-compose.yml" ]
                        then
                                echo "Un fichier docker-compose.yml existe déjà"
                                echo "Est-ce un [a]jout au docker-compose.yml existant ou un [n]ouveau docker-compose.yml ([n] supprimera l'ancien) ? [a/n]"
                                read add_or_new
                                if [ "$add_or_new" = "a" ]
                                then
                                        install_nginx_letsencrypt $chemin_3
                                else
                                        put_header $chemin_2
                                        rm -rf $2/docker-compose.yml
                                        install_nginx_letsencrypt $chemin_3
                                fi
                        else
                                put_header $chemin_2
                                install_nginx_letsencrypt $chemin_3
                        fi
                        exit 0
                        ;;

                3)      check_header_exist $chemin_2
                        if [ -f "$2/docker-compose.yml" ]
                        then
                                echo "Un fichier docker-compose.yml existe déjà"                                                                                                                                                             
                                echo "Est-ce un [a]jout au docker-compose.yml existant ou un [n]ouveau docker-compose.yml ([n] supprimera l'ancien) ? [a/n]"
                                read add_or_new
                                if [ "$add_or_new" = "a" ]
                                then
                                        install_sonarr_radarr $nom $chemin_2 $chemin_3                                                                                                                                                         
                                else
                                        rm -rf $2/docker-compose.yml
                                        put_header $chemin_2
                                        install_sonarr_radarr $nom $chemin_2 $chemin_3                                                                                                                                                             
                                fi
                        else
                                put_header $chemin_2
                                install_sonarr_radarr $nom $chemin_2 $chemin_3
                        fi
                        exit 0
                        ;;
                4)		check_header_exist $chemin_2
				        echo "Pour configurer plex j'ai besoin de votre clé 'claim' trouvable ici https://www.plex.tv/claim/"
						echo "Saisissez votre clé :"
						read claim
						if [ -f "$2/docker-compose.yml" ]
                        then
                                echo "Un fichier docker-compose.yml existe déjà"
                                echo "Est-ce un [a]jout au docker-compose.yml existant ou un [n]ouveau docker-compose.yml ([n] supprimera l'ancien) ? [a/n]"
                                read add_or_new
                                if [ "$add_or_new" = "a" ]
                                then
                                        install_plex $nom $chemin_2 $chemin_3
                                else
                                        rm -rf $2/docker-compose.yml
                                        put_header $chemin_2
                                        install_plex $nom $chemin_2 $chemin_3
                                fi
                        else
                                put_header $chemin_2
                                install_plex $nom $chemin_2 $chemin_3
                        fi
                        exit 0
						exit 0
						;;
				5)      check_header_exist $chemin_2
                        if [ -f "$2/docker-compose.yml" ]
                        then
                                echo "Un fichier docker-compose.yml existe déjà"
                                echo "Est-ce un [a]jout au docker-compose.yml existant ou un [n]ouveau docker-compose.yml ([n] supprimera l'ancien) ? [a/n]"
                                read add_or_new
                                if [ "$add_or_new" = "a" ]
                                then
                                        install_jackett $nom $chemin_3
                                else
                                        rm -rf $2/docker-compose.yml
                                        put_header $chemin_2
                                        install_jackett $nom $chemin_3
                                fi
                        else
                                put_header $chemin_2
                                install_jackett $nom $chemin_3
                        fi
                        exit 0
                        ;;
                6)		check_header_exist $chemin_2
						if [ -f "$2/docker-compose.yml" ]
                        then
                                echo "Un fichier docker-compose.yml existe déjà"
                                echo "Est-ce un [a]jout au docker-compose.yml existant ou un [n]ouveau docker-compose.yml ([n] supprimera l'ancien) ? [a/n]"
                                read add_or_new
                                if [ "$add_or_new" = "a" ]
                                then
                                        install_rutorrent $nom $chemin_2 $chemin_3
                                else
                                        rm -rf $2/docker-compose.yml
                                        put_header $chemin_2
                                        install_rutorrent $nom $chemin_2 $chemin_3
                                fi
                        else
                                put_header $chemin_2
                                install_rutorrent $nom $chemin_2 $chemin_3
                        fi
						exit 0
						;;
				7)		check_header_exist $chemin_2
						if [ -f "$2/docker-compose.yml" ]
                        then
                                echo "Un fichier docker-compose.yml existe déjà"
                                echo "Est-ce un [a]jout au docker-compose.yml existant ou un [n]ouveau docker-compose.yml ([n] supprimera l'ancien) ? [a/n]"
                                read add_or_new
                                if [ "$add_or_new" = "a" ]
                                then
                                        install_watchtower $chemin_3
                                else
                                        rm -rf $2/docker-compose.yml
                                        put_header $chemin_2
                                        install_watchtower $chemin_3
                                fi
                        else
                                put_header $chemin_2
                                install_watchtower $chemin_3
                        fi
						exit 0
						;;
				9)		cd $2
						docker-compose up -d
						exit 0
						;;
				Q|q)
                        clear
                        exit 0
                        ;;
                *)
                        echo "[ERREUR] Veuillez suivre les numéros du menu"
                        echo "Appuyez sur entrée pour revenir au menu principal"
                        read
                        ;;
        esac
done
