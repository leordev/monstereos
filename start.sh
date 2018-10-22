echo "Starting docker containers"
docker-compose up -d --build

cd services/frontend
yarn start

cd ../..