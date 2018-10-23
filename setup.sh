echo "Building images"
docker-compose build

echo "Initializing docker containers"
docker-compose up -d mongo postgres
sleep 5s
docker-compose up -d eosiodev
sleep 3s
docker-compose up -d fullnode

read -p "Creating Postgres schema (y/n)?" -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
  echo "Please use the password: pass (or any other one you setup in docker-compose)"
  docker-compose run demux yarn _migrate
fi

read -p "Initializing Chain data (y/n)? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
  docker-compose run eosiodev /opt/application/scripts/0000_init-chain.sh
fi

read -p "Load Elements (y/n)? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
  docker-compose run eosiodev /opt/application/scripts/0010_load-elements.sh
fi

read -p "Load pet types (y/n)? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
  docker-compose run eosiodev /opt/application/scripts/0020_load-pet-types.sh
fi

read -p "Load some monsters (y/n)? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
  docker-compose run eosiodev /opt/application/scripts/0030_load-data.sh
fi

echo "Initializing demux!"
docker-compose up -d demux

echo "Installing frontend packages"
cd services/frontend
yarn install
