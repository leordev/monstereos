echo "Flushing all blockchain and databases data"
docker-compose down && rm -rf ./.dbdata; docker volume prune 
