#!/bin/bash
TAG=`git log -1 --pretty=%ad --date=short`-`git log -1 --pretty=%h`

echo "building drupal image"
docker build ./ -t temp_drupal

echo "tagging drupal image"
docker tag temp_drupal:latest ncidockerhub.nci.nih.gov/webteam/drupal:$TAG
docker tag temp_drupal:latest ncidockerhub.nci.nih.gov/webteam/drupal:latest

echo "pushing images to repository"
docker push ncidockerhub.nci.nih.gov/webteam/drupal:$TAG
docker push ncidockerhub.nci.nih.gov/webteam/drupal:latest 

echo "removing images from system"
docker rmi temp_drupal:latest
docker rmi ncidockerhub.nci.nih.gov/webteam/drupal:$TAG

