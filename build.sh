#!/bin/bash
TAG=`git log -1 --pretty=%at`-`git log -1 --pretty=%h`
docker build ./ -t temp_drupal
docker tag temp_drupal:latest ncidockerhub.nci.nih.gov/webteam/drupal:$TAG
docker push ncidockerhub.nci.nih.gov/webteam/drupal:$TAG
docker tag ncidockerhub.nci.nih.gov/webteam/drupal:$TAG ncidockerhub.nci.nih.gov/webteam/drupal:latest
docker push ncidockerhub.nci.nih.gov/webteam/drupal:latest 

docker rmi temp_drupal:latest
docker rmi ncidockerhub.nci.nih.gov/webteam/drupal:$TAG

