# MonsterEOS

![MonsterEOS Icon](https://github.com/MonsterEOS/monstereos/raw/master/logo-monster.png)

Setup instructions and technical content in the bottom of the page! :)

## About
MonsterEOS was born as an experimental decentralized application in the EOS Blockchain. It is a Tamagotchi style game where you keep your pets alive and happy by feeding them, providing a pleasant environment, and letting them rest. By popular demand and adoption from the EOS community, we have added requested features such as battles and a monster market.

The project will ALWAYS be open source because we believe it’s a must for a decentralized world, and also, because we want the project to be building block and code reference for other great games and dapps on the EOS blockchain. In fact, we encourage everyone to browse our code repository, and extend/modify the game and re-publish as you wish - the more dapps built for our wonderful EOS community the better.

The game is currently in **BETA**, and under constant development and improvement. This does not restrict us from implementing profit channels to fund the required resources and team. For now, the project receives 1% of all the market transfers and we are studying ways of implementing in-app purchases avoiding PAY-TO-WIN schemes.

Many crypto-world games are based on a gambling scheme. These have a place in the market, but our goal for MonsterEOS is for folks to just have FUN, period. It's okay to create monsters, raise them, love them and then exchange them. That's why we have a market, but we aren't intending MonsterEOS to be second source of income for people, besides... You will probably love your monsters too much to part with them.

We love the EOS Community and we know that we can build a better world together!

## Connect with us!

Discord: https://discord.gg/gmrDtHF

Twitter: https://twitter.com/MonsterEos

Medium: https://medium.com/monstereos

GitHub: https://github.com/MonsterEOS

Telegram: https://t.me/joinchat/Hel9rgyuHrEwzsjG2SlUNQ


## Official Collaborators & Shareholders

Access our DAO here: https://github.com/MonsterEOS/dao

Name | Title | Social Info
---|---|---
Leo Ribeiro | Founder and Head of Development | [GitHub](http://github.com/leordev) / [Twitter](https://twitter.com/leordev) / [Steemit](https://steemit.com/@leordev)
Alex Rozgo | Head of Gaming Engineering | [GitHub](http://github.com/rozgo) / [Twitter](https://twitter.com/rozgo) / [Steemit](https://steemit.com/@rozgo)
Vertex Studio | Arts & Gaming Studio | [Official Website](https://vertexstudio.github.io)
Cypherglass | Sponsor of Infrastructure and EOS Resources | [Official Website](https://cypherglass.com) / [Twitter](https://twitter.com/cypherglassbp) / [Youtube](https://www.youtube.com/channel/UCnXofUeO5w1dO9JGWWDdqPQ) / [Steemit](https://steemit.com/@cypherglass)
Friedger Muffke | Developer | [GitHub](http://github.com/friedger) / [Twitter](https://twitter.com/fmdroid) / [Steemit](https://steemit.com/@friedger)
Marcelo Mendes | Developer | [GitHub](http://github.com/marcelormendes) / [Twitter](https://twitter.com/itsmemarcelorm)
Julien Lucca | Developer | [GitHub](http://github.com/lucca65) / [Twitter](https://twitter.com/JulienLucca)
John Williamson | Developer | [GitHub](http://github.com/velua) / [Twitter](https://twitter.com/velua) / [Steemit](https://steemit.com/@johnwilliamson)
Jenny Calpu | PR & Marketing | [Twitter](https://twitter.com/topkpop) / [Steemit](https://steemit.com/@topkpop)
Daniel Wagner | Gaming Curator | [Medium](https://medium.com/@tikuzero)

The project is open to the public and we welcome anyone who would like to collaborate. Our Github repository is there for the community, but in order to receive shares of the project and participate in our distribution, you must be approved by board members.

Our Decentralized Autonomous Organization is still being defined but [you can check out our current proposal here](https://github.com/MonsterEOS/dao/blob/master/README.md). This model is inspired by Slicing Pie for startup companies, and we believe that it’s the fairest way to reward collaborators of an open source project. We intend to translate our agreement into an EOS Smart Contract and automate the distribution process in the future.


##  Partnerships

Large Seafaring Mammal T-Shirts: [Buy your shirt here!](https://largeseafaringmammal.com/products/monstereos-x-lsm)

MyEOSKit - EOS Blockchain Explorer: https://www.myeoskit.com/#/tx/monstereosio - This is where we link our transactions and explore them.

MonsterEOS Animal Jungle Version - JungleNet is the TestNet that we consider as our staging environment, and guess what?! They just prepared an Animal Version of Monsters! Coming out Soon...

If you have any partnership ideas, feel free to contact us in our Telegram, GitHub or Email.


## Disclaimer

This project remains purely experimental software and is not to be considered in any way production ready, and has no guarantee of any kind. Use at your own risk.

Any transferred tokens sent to account name 'monstereosio' will not return any entitlement of any asset, investment digital or physical including the sent asset itself. Any proceeds received from any user transfers are used at the sole control and discretion of the receiver.


## Big Thanks & Credits

Open source is all :heart:

Monsters Pictures Package: [Itch.io @Pipoya - Free RPG Monster Pack](https://pipoya.itch.io/free-rpg-monster-pack)

Sleeping GIF Credits: [Giphy @AlabasterPizzo](https://giphy.com/stickers/zzz-snore-51WvIEoUKKHlGwgmgy)

Arena Background Credits: Freebies from craftpix.net - license here: [Craftpix](https://craftpix.net/file-licenses/)

## Setup

First of all, clone the repo and enter in the root folder of the project:

```
git clone https://github.com/MonsterEOS/monstereos
cd monstereos
```

You will need to install node (version 8+), yarn and docker.

### Chain and Backend

We structured everything in microservices and it can be automagically initialized by docker! Don't be afraid of docker, a lot of people hear docker and run away but we already did the hard part (configuration) for you. You will just need to install docker in your computer (a simple installer that you will press next next next finish lol).

After you installed docker just run the following commands:

**Start docker containers and Create postgres database and init chain and monster data**
```
./setup.sh
```

Now that you have installed everything you can always start the app with the following command:

```
./start.sh
```

Note: the postgres password is `pass`, you can change it in `docker-compose.yml`

Open [Kitematic](https://docs.docker.com/kitematic/userguide/) (a nice UI for docker containers management that comes by default on docker installation) and you will see all the containers running (or run the command `docker-compose logs -f`):

- eosdev: this is the local single-producer blockchain with basic data (ready for development) and development of the contracts
- fullnode: this is a node that will simulate your mainnet fullnode that will listen for the blockchain and persist data in mongo with mongodb_plugin
- mongo: this is our chain database, fed by fullnode
- postgres: this is our database, the chain is the source of truth, and this is just a cache layer to help our application to query nice and fast reports
- demux: The backend for monstereosio, it consists of the following node services (using pm2):
  - demux: this is the blockchain watcher, demux is a tool from Block.one that allows us to watch the blockchain data through MongoDB, manage state saving records to database and also any side effects as submit emails, notifications, external apis etc <3
  - postgraphile: we serve data with GraphQL out-of-the-box through postgraphile under port 3030
  - data-cleaner: updates data about monsters and battle arenas according to our business rules

### Frontend App: UI

With all these nodes running you can just access it with our frontend app:

```
cd services/frontend
yarn
yarn start
```

Feel free to build any other apps and/or dockerize it. We didn't create a docker container for it because we usually build the static files (`yarn build`) and serve it on `gh-pages` branch.

### Troubleshooting

- https://developers.eos.io/eosio-nodeos/docs/troubleshooting
- https://github.com/enaqx/awesome-react#debugging-react 
- https://docs.docker.com/compose/reference/logs/
- https://medium.com/@betz.mark/ten-tips-for-debugging-docker-containers-cde4da841a1d

### EOS Dream Stack

You can build any Dapp using the above structure. Tweak the structure a little bit to satisfy all your needs, i.e.: you can change the postgres for other database as mongo or mysql; you might not need demux and the backend if your app is very basic, allowing the frontend to read directly from the chain; change the frontend to whatever framework you want to use as Vue or Angular, not only this but your frontend can be a mobile native app, why not?

### Notes
* mongo and postgres data is stored in parent folder of this git repo under `.monstereos`
* eos data is stored in the docker volume `monstereos_eosiodevapp`
* to compile the contract you need to use `eosio.cdt` and build it using `make`
* to change postgres schema run `yarn migrate` from console (outside docker) in folder `services/demux`.

