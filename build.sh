#!/bin/bash
TAG="alpine-1.1"
echo $TAG
echo "building drupal image"
docker build --no-cache -t temp_drupal .

echo "tagging drupal image"
docker tag temp_drupal:latest ncidockerhub.nci.nih.gov/webteam/drupal:$TAG
docker tag temp_drupal:latest ncidockerhub.nci.nih.gov/webteam/drupal:latest

echo "pushing images to repository"
docker push ncidockerhub.nci.nih.gov/webteam/drupal:$TAG
docker push ncidockerhub.nci.nih.gov/webteam/drupal:latest

echo "removing images from system"
docker rmi ncidockerhub.nci.nih.gov/webteam/drupal:$TAG
docker rmi temp_drupal:latest


docker image prune -f
