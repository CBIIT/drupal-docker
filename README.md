# Docker documentation for drupal builds

There are two options to build and run docker from the command line

 1. Using docker-compose
 2. Using docker run

# Using docker-compose

 The following environment variables need to be set in the docker-compose file or in your profile. They can also be passed in when executing docker-compose up. They are all using default values via the .env file. 
 1. repository
 2. hash_salt
 3. database
 4. username
 5. password
 6. host
 7. port
 8. namespace
 9. driver

##  To pass these values in during docker-compose up
*Not all environment variables have to be set but pass in as many as possible
1. Run **repository=githublink hash_salt=value database=value username=value password=value host=value port=value namespace=value driver=value docker-compose up**
##  To let docker-compose up read preset values

 1. Set above environment variables in your profile or set them in the docker-compose.yml file
 2. Run **docker-compose up**

 ## To shut down server
 1. Run **docker-compose down**

# Using docker run

 ## If image does not exist on machine
 

 1. Run docker build -t cbiit/drupal .
 ## To build using .env file
 1.  Change .env file to reflect real values
 2. Run **docker run --env-file=.env -p 8080:80 --name drupal-server cbiit/drupal**
  ## To build by passing in environment variables
  1. Run **docker run -e repository=githublink hash_salt=value -e database=value -e username=value -e password=value -e host=value -e port=value -e namespace=value -e driver=value -p 8080:80 --name drupal-server cbiit/drupal**
 ## To stop the server
 1. Run **docker stop drupal-server**
 ## To remove the server
 1. Run **docker rm drupal-server**

# To remove image
1. Make sure all containers are stopped and removed referencing image
2. Run **docker rmi cbiit/drupal**

