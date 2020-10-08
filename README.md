# Docker-Compose for Pimcore 6
Simple and easy Docker-Compose configuration for Pimcore 6.

## Getting Started
### Requirements
* git
* docker
* docker-compose
### Checkout Repo
```bash
git clone https://github.com/putzflorian/pimcore-docker-compose.git
cd pimcore-docker-compose/
 ```
### Run Containers
```bash
# initialize and startup containers
docker-compose up -d
```
### Install Pimcore 
```bash
# get shell in running container
docker exec -it php-fpm bash

COMPOSER_MEMORY_LIMIT=-1 composer create-project pimcore/skeleton tmp
mv tmp/.[!.]* .
mv tmp/* .
rmdir tmp

#run installer
./vendor/bin/pimcore-install --mysql-host-socket=db --mysql-username=pimcore --mysql-password=pimcore --mysql-database=pimcore 
 ```
