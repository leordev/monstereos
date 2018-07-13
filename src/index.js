import './main.css';
import { Main } from './Main.elm';
import registerServiceWorker from './registerServiceWorker';
import Eos from 'eosjs'
import ecc from 'eosjs-ecc'

const STORAGE_KEY = 'MONSTEREOS'
const CHAIN_PROTOCOL = 'https'
const CHAIN_HOST = 'eu.eosdac.io' //'mainnet.eoscalgary.io' //'nodes.get-scatter.com' //'br.eosrio.io'
const CHAIN_PORT = '443' //8080' //80
const CHAIN_ADDRESS = CHAIN_PROTOCOL + '://' + CHAIN_HOST + ':' + CHAIN_PORT
const CHAIN_ID = 'aca376f206b8fc25a6ed44dbdc66547c36c6c33e3a119ffbeaef943642f0e906'
const MONSTERS_ACCOUNT = 'monstereosio'
const MONSTERS_TABLE = 'pets'
const BATTLES_TABLE = 'battles'
const ELEMENTS_TABLE = 'elements'
const PET_TYPES_TABLE = 'pettypes'
const CONFIG_TABLE = 'petconfig2'
const BALANCES_TABLE = 'accounts'
const MARKET_ACCOUNT = 'monstereosmk'
const MARKET_TABLE = 'offers'
const TOKEN_SYMBOL = 'EOS'
const MEMO = 'MonsterEOS Wallet Deposit'
// const ACTIONS_API = 'https://api.eostracker.io/accounts/monstereosio/actions/to?page=1&size=300'
const ACTIONS_API = 'https://api.eosrio.io/v1/history/get_actions'

// resources
const BATTLE_REQ_CPU = 30 * 1000
const BATTLE_REQ_NET = 2 * 1000

const initialHashInfo = { mouseMove: [], lastPair: null }
const initialUser = { eosAccount: "", publicKey: "" }
const initialStorageBody = { user: initialUser, hashInfo: null }

const storageBody = localStorage.getItem(STORAGE_KEY)
const flags = !storageBody ? initialStorageBody : JSON.parse(storageBody)

console.log(flags)

const app = Main.embed(document.getElementById('root'), flags)

/* Eos and Scatter Setup */
const network = {
  protocol: CHAIN_PROTOCOL,
  blockchain: 'eos',
  host: CHAIN_HOST,
  port: CHAIN_PORT,
  chainId: CHAIN_ID
}
const localNet = Eos({httpEndpoint: CHAIN_ADDRESS, chainId: CHAIN_ID})

let scatter = null
let globalConfigs = null
let hashInfo = initialHashInfo

const scatterDetection = setTimeout(() => {
  if (scatter == null) {
    app.ports.setScatterInstalled.send(false)
  }
}, 5000)

// timeout helper
const timeout = ms => {
  return new Promise(resolve => setTimeout(resolve, ms));
}

const handleErrorMessages = (e, genericMessage, cb) => {
  console.error(genericMessage, e)

  let errorMsg = genericMessage
  if (e && e.message) {
    errorMsg = e.message
  } else {
    const errorObj = JSON.parse(e)
    if (errorObj && errorObj.error && errorObj.error.details &&
      errorObj.error.details.length) {
      errorMsg = errorObj.error.details[0].message
    }
  }

  cb(errorMsg)
}

const getAuthorization = () => {
  if (!scatter || !scatter.identity || !scatter.identity.accounts)
    return null;

  const account = scatter.identity.accounts.find(account => account.blockchain === 'eos')

  return {
    permission: {
      authorization: [ `${account.name}@${account.authority}` ]
    },
    account
  }
}

const getEos = () => {
  return scatter.eos(network, Eos, { chainId: CHAIN_ID })
}

const getContract = async () => {
  return getEos().contract(MONSTERS_ACCOUNT);
}

const getMarketContract = async () => {
  return getEos().contract(MARKET_ACCOUNT);
}

document.addEventListener('scatterLoaded', scatterExtension => {
  clearTimeout(scatterDetection)
  scatter = window.scatter
  window.scatter = null

  scatter.suggestNetwork(network)

  app.ports.setScatterInstalled.send(true)

  if (scatter.identity) {

    const user = {
        eosAccount: scatter.identity.accounts[0].name,
        publicKey: scatter.identity.publicKey
    }

    app.ports.setScatterIdentity.send(user)
  }
})

app.ports.refreshPage.subscribe(() => {
  location.reload()
})

app.ports.signOut.subscribe(() => {
  scatter.forgetIdentity()
  app.ports.setScatterInstalled.send(true)
})

app.ports.scatterRequestIdentity.subscribe(async () => {

    await scatter.suggestNetwork(network)

    let requiredFields = {
        accounts: [network]
    }
    scatter.getIdentity(requiredFields).then((identity) => {

      const user = {
          eosAccount: identity.accounts[0].name,
          publicKey: identity.publicKey
      }

      app.ports.setScatterIdentity.send(user)
    }).catch(error => {
      app.ports.scatterRejected.send("Identity or Network was rejected")
      console.error(error)
    })
})

app.ports.listMonsters.subscribe(async () => {

    const monsters = await localNet.getTableRows({
                "json": true,
                "scope": MONSTERS_ACCOUNT,
                "code": MONSTERS_ACCOUNT,
                "table": MONSTERS_TABLE,
                "limit": 5000
            }).then(res => res.rows.map(parseMonster)).catch(e => {
              app.ports.setMonstersFailed.send('Error while listing Monsters')
            })

    if(monsters) app.ports.setMonsters.send(monsters)
})

app.ports.getGlobalConfig.subscribe(async () => {

    const config = await localNet.getTableRows({
      "json": true,
      "scope": MONSTERS_ACCOUNT,
      "code": MONSTERS_ACCOUNT,
      "table": CONFIG_TABLE,
      "limit": 1
    }).then(res => {
      if (res && res.rows && res.rows.length) {
        return res.rows[0];
      } else {
        return null;
      }
    }).catch(e => {
      app.ports.setGlobalConfigFailed.send('Error while getting MonsterEOS Global Settings')
    })

    if (config) {
      globalConfigs = config
      app.ports.setGlobalConfig.send(config)
    }
})

app.ports.getWallet.subscribe(async () => {

    const { account } = getAuthorization()

    if (!account) {
      return app.ports.setWalletFailed.send('You are not authenticated with Scatter');
    }

    const funds = await localNet.getTableRows({
          "json": true,
          "scope": account.name,
          "code": MONSTERS_ACCOUNT,
          "table": BALANCES_TABLE,
          "limit": 100000 // TODO: improve read
      }).then(res => {
        if (res && res.rows && res.rows.length) {
          return { funds: Number(res.rows[0].balance.split(" ")[0]) }
        } else {
          return { funds: 0 }
        }
      }).catch(e => {
        app.ports.setWalletFailed.send('Error while getting current Wallet')
      })

    if(funds) app.ports.setWallet.send(funds)
})

app.ports.requestDeposit.subscribe(async (depositAmount) => {

  const auth = getAuthorization()

  console.log("depositing " + depositAmount)

  const data = {
    from: auth.account.name,
    to: MONSTERS_ACCOUNT,
    quantity: depositAmount.toFixed(4) + ' ' + TOKEN_SYMBOL,
    memo: MEMO
  }

  const options = {
    broadcast: true,
    authorization: auth.permission.authorization
  }

  const contract = await getEos().contract('eosio.token')
    .catch(e => {
      console.error('fail to initialize eosio.token ', e)
      app.ports.depositFailed.send('Fail to Initialize eosio.token')
    })

  if (!contract) return

  const transfer = await contract.transfer(data, auth.permission)
    .catch(e => {
        console.error('error on deposit transfer ', e)
        const errorMsg = (e && e.message) ||
        'An error happened while making the deposit, please try again'
        app.ports.depositFailed.send(errorMsg)
      })

  if (transfer) app.ports.depositSucceed.send(transfer.transaction_id)
})

app.ports.submitNewMonster.subscribe(async (monsterName) => {

  const auth = getAuthorization()

  const contract = await getContract()

  const createpet = await contract.createpet(auth.account.name, monsterName, auth.permission)
    .catch(e => handleErrorMessages(e, 'An error happened while creating the monster', app.ports.monsterCreationFailed.send))

  if (createpet) app.ports.monsterCreationSucceed.send(createpet.transaction_id)
})

app.ports.requestFeed.subscribe(async (petId) => {
  const auth = getAuthorization()

  const contract = await getContract()

  const feedpet = await contract.feedpet(petId, auth.permission)
    .catch(e => handleErrorMessages(e, 'An error happened while feeding the monster', app.ports.feedFailed.send))

  if(feedpet) app.ports.feedSucceed.send(feedpet.transaction_id)
})

app.ports.requestAwake.subscribe(async (petId) => {

  const auth = getAuthorization()

  const contract = await getContract()

  const awakepet = await contract.awakepet(petId, auth.permission)
    .catch(e => handleErrorMessages(e, 'An error happened while awaking the monster', app.ports.awakeFailed.send))

  if(awakepet) app.ports.awakeSucceed.send(awakepet.transaction_id)
})

app.ports.requestBed.subscribe(async (petId) => {
  const auth = getAuthorization()

  const contract = await getContract()

  const bedpet = await contract.bedpet(petId, auth.permission)
    .catch(e => handleErrorMessages(e, 'An error happened while attempting to bed the monster', app.ports.bedFailed.send))

  if(bedpet) app.ports.bedSucceed.send(bedpet.transaction_id)
})

app.ports.requestDelete.subscribe(async (petId) => {
  const auth = getAuthorization()

  const contract = await getContract()

  const destroypet = await contract.destroypet(petId, auth.permission)
    .catch(e => handleErrorMessages(e, 'An error happened while attempting to destroy the monster', app.ports.deleteFailed.send))

  console.log(destroypet)

  if(destroypet) app.ports.deleteSucceed.send(destroypet.transaction_id)
})

app.ports.requestPlay.subscribe(async (petId) => {
  app.ports.feedSucceed.send('lazy developer must build "Play" action')
})

app.ports.requestWash.subscribe(async (petId) => {
  app.ports.feedSucceed.send('lazy developer must build "Wash" action')
})

app.ports.submitNewOwner.subscribe(async (petId, newOwner) => {
  const auth = getAuthorization()

  const marketContract = await getMarketContract()

  const transferpet = await marketContract.offerpet(petId, newOwner)
    .catch(e => {
        console.error('error on transferring pet ', e)
        const errorMsg = (e && e.message) ||
        'An error happened while attempting to transferring the monster'
        app.ports.transferFailed.send(errorMsg)
      })

  console.log(transferpet)

  if(transferpet) app.ports.transferSucceed.send(transferpet.transaction_id)
})


app.ports.requestClaim.subscribe(async (oldowner, petId) => {
  const auth = getAuthorization()

  const marketContract = await getMarketContract()

  const claimpet = await marketContract.claimpet(oldowner, petId)
    .catch(e => {
        console.error('error on claiming pet ', e)
        const errorMsg = (e && e.message) ||
        'An error happened while attempting to claim the monster'
        app.ports.claimFailed.send(errorMsg)
      })

  console.log(claimpet)

  if(claimpet) app.ports.claimSucceed.send(transferpet.transaction_id)
})

/**
 * We should've probably parse the monster inside ELM, but as javascript
 * is the most widely used among the community we decided to leave this
 * monter stats calcs here
 */
const parseMonster = row => {

  // set default monster attributes
  const monster = Object.assign({}, row, {
    created_at: row.created_at * 1000,
    death_at: row.death_at * 1000,
    last_bed_at: row.last_bed_at * 1000,
    last_fed_at: row.last_fed_at * 1000,
    last_play_at: row.last_play_at * 1000,
    last_shower_at: row.last_shower_at * 1000,
    last_awake_at: row.last_awake_at * 1000,
    is_sleeping: row.last_bed_at > row.last_awake_at,
    health: 100,
    hunger: 100,
    awake: 100,
    happiness: 100,
    clean: 100
  })

  // calcs params
  const config = globalConfigs;

  if (config) {
    const currentTime = Date.now();

    // calculates hunger bar
    monster.hunger = 100;

    const hungrySeconds = (currentTime - monster.last_fed_at) / 1000;
    const hungryPoints = hungrySeconds * config.max_hunger_points / config.hunger_to_zero;
    monster.hunger = Math.round(config.max_hunger_points - hungryPoints);
    monster.hunger = monster.hunger < 0 ? 0 : monster.hunger;

    const effectHpHunger = hungryPoints > config.max_health ?
      Math.round((hungryPoints - config.max_hunger_points) / config.hunger_hp_modifier) :
      0;

    // calculates health and death time
    monster.health = config.max_health - effectHpHunger;
    if (monster.health <= 0) {
      monster.hunger = monster.health = monster.awake = monster.happiness = monster.clean = 0;

      monster.death_at = ((monster.last_fed_at / 1000) + config.hunger_to_zero
        + (config.hunger_to_zero * config.hunger_hp_modifier)) * 1000;
    }

  }

  return monster;
}

/**
 * BATTLES INTERFACE
 */
app.ports.listBattles.subscribe(async () => {

  const data = await localNet.getTableRows({
              "json": true,
              "scope": MONSTERS_ACCOUNT,
              "code": MONSTERS_ACCOUNT,
              "table": BATTLES_TABLE,
              "limit": 5000
          }).then(res => res.rows.map(r => {
            r.startedAt = r.started_at * 1000;
            r.lastMoveAt = r.last_move_at * 1000;
            return r;
          }))
          .catch(e => handleErrorMessages(e, 'Error while listing Battles', app.ports.listBattlesFailed.send))

  if(data) app.ports.listBattlesSucceed.send(data)
})

app.ports.getBattleWinner.subscribe(async (host) => {

  const genericError = 'Battle is finished but failed to get the winner'

  const _interval = await timeout(500)

  // const data = await fetch(ACTIONS_API)
  const body = `{ "account_name": "monstereosio", "offset": -300 }`
  const data = await fetch(ACTIONS_API, {method: 'POST', body})
  .then(r => r.json())
  .catch(e => {
    console.error(e)
    app.ports.getBattleWinnerFailed.send(genericError)
  })

  // // eostracker.io api <3
  // if (data) {
  //   const actionData = data.filter(a => {
  //     return a.name == 'battlefinish' && a.data && a.data.host == host
  //   }).map(a => a.data)

  //   if(actionData.length) {
  //     return app.ports.getBattleWinnerSucceed.send(actionData[0].winner)
  //   }
  // }

  // original eosrpc api endpoint
  if (data && data.actions) {
    const actionData = data.actions
      .reverse()
      .filter(a => {
        return a.action_trace && a.action_trace.act &&
          a.action_trace.act.name == 'battlefinish' &&
          a.action_trace.act.data.host == host
      }).map(a => a.action_trace.act.data)

    if (actionData.length) {
      console.log('and the winner is >>>', actionData[0].winner)
      return app.ports.getBattleWinnerSucceed.send(actionData[0].winner)
    }
  }

  app.ports.getBattleWinnerFailed.send(genericError)
})

app.ports.listElements.subscribe(async () => {

  const data = await localNet.getTableRows({
              "json": true,
              "scope": MONSTERS_ACCOUNT,
              "code": MONSTERS_ACCOUNT,
              "table": ELEMENTS_TABLE,
              "limit": 5000
          }).then(res => res.rows.map(r => {

            switch(r.id) {
              case 0:
                r.name = "Neutral";
                break;
              case 1:
                r.name = "Wood";
                break;
              case 2:
                r.name = "Earth";
                break;
              case 3:
                r.name = "Water";
                break;
              case 4:
                r.name = "Fire";
                break;
              case 5:
                r.name = "Metal";
                break;
              case 6:
                r.name = "Animal";
                break;
              case 7:
                r.name = "Poison";
                break;
              case 8:
                r.name = "Undead";
                break;
              case 9:
                r.name = "Light";
                break;
            }

            return r;
          }))
          .catch(e => handleErrorMessages(e, 'Error while listing Elements', app.ports.listElementsFailed.send))

  if(data) app.ports.listElementsSucceed.send(data)
})

app.ports.listPetTypes.subscribe(async () => {

  const data = await localNet.getTableRows({
              "json": true,
              "scope": MONSTERS_ACCOUNT,
              "code": MONSTERS_ACCOUNT,
              "table": PET_TYPES_TABLE,
              "limit": 5000
          }).then(res => res.rows)
          .catch(e => handleErrorMessages(e, 'Error while listing Monster Types', app.ports.listPetTypesFailed.send))

  if(data) app.ports.listPetTypesSucceed.send(data)
})

app.ports.battleCreate.subscribe(async (mode) => {
  const auth = getAuthorization()

  const accResources = await getEos().getAccount(auth.account.name)
  console.log('acc resources', accResources)

  const availableCpu = accResources.cpu_limit.available
  const availableNet = accResources.net_limit.available

  if (availableCpu < BATTLE_REQ_CPU) {
    return app.ports.battleJoinFailed.send(`You don\'t have enough CPU to join in a Battle. You have ${availableCpu/1000}ms and a battle requires at least ${BATTLE_REQ_CPU}.`)
  } else if (availableNet < BATTLE_REQ_NET) {
    return app.ports.battleJoinFailed.send(`You don\'t have enough Net to join in a Battle. You have ${availableNet/1000}kb and a battle requires at least ${BATTLE_REQ_NET}.`)
  }

  const contract = await getContract()

  const hashInfo = generateHashInfo()

  const action = await contract.battlecreate(auth.account.name, mode, hashInfo.secret, auth.permission)
  .catch(e => handleErrorMessages(e, 'An error happened while attempting to Create a Battle', app.ports.battleCreateFailed.send))

  if(action) {
    app.ports.battleCreateSucceed.send(action.transaction_id)
  } else {
    destroyHashInfo()
  }
})

app.ports.battleJoin.subscribe(async (host) => {
  const auth = getAuthorization()

  const accResources = await getEos().getAccount(auth.account.name)
  console.log('acc resources', accResources)

  const availableCpu = accResources.cpu_limit.available
  const availableNet = accResources.net_limit.available

  if (availableCpu < BATTLE_REQ_CPU) {
    return app.ports.battleJoinFailed.send(`You don\'t have enough CPU to join in a Battle. You have ${availableCpu/1000}ms and a battle requires at least ${BATTLE_REQ_CPU}.`)
  } else if (availableNet < BATTLE_REQ_NET) {
    return app.ports.battleJoinFailed.send(`You don\'t have enough Net to join in a Battle. You have ${availableNet/1000}kb and a battle requires at least ${BATTLE_REQ_NET}.`)
  }

  const contract = await getContract()

  const hashInfo = generateHashInfo()

  const action = await contract.battlejoin(host, auth.account.name, hashInfo.secret, auth.permission)
  .catch(e => handleErrorMessages(e, 'An error happened while attempting to Join a Battle', app.ports.battleJoinFailed.send))

  if(action) {
    app.ports.battleJoinSucceed.send(action.transaction_id)
  } else {
    destroyHashInfo()
  }
})

app.ports.battleLeave.subscribe(async (host) => {
  const auth = getAuthorization()

  const contract = await getContract()

  const action = await contract.battleleave(host, auth.account.name, auth.permission)
  .catch(e => handleErrorMessages(e, 'An error happened while attempting to Leave a Battle', app.ports.battleLeaveFailed.send))

  if(action) {
    destroyHashInfo()
    app.ports.battleLeaveSucceed.send(action.transaction_id)
  }
})

app.ports.battleStart.subscribe(async (host) => {
  const auth = getAuthorization()

  const contract = await getContract()

  const hashInfo = flags.hashInfo

  const action = await contract.battlestart(host, auth.account.name, hashInfo.hash, auth.permission)
  .catch(e => handleErrorMessages(e, 'An error happened while attempting to Start a Battle', app.ports.battleStartFailed.send))

  if(action) {
    destroyHashInfo()
    app.ports.battleStartSucceed.send(action.transaction_id)
  }
})

app.ports.battleSelPet.subscribe(async params => {
  const auth = getAuthorization()

  const contract = await getContract()

  const action = await contract.battleselpet(params.host, auth.account.name, params.petId, auth.permission)
  .catch(e => handleErrorMessages(e, 'An error happened while attempting to Select a Monster for a Battle', app.ports.battleSelPetFailed.send))

  if(action) app.ports.battleSelPetSucceed.send(action.transaction_id)
})

app.ports.battleAttack.subscribe(async params => {
  const auth = getAuthorization()

  const contract = await getContract()

  const action = await contract.battleattack(params.host, auth.account.name, params.petId, params.petEnemyId, params.element, auth.permission)
  .catch(e => handleErrorMessages(e, 'An error happened while attempting to Attack', app.ports.battleAttackFailed.send))

  if(action) app.ports.battleAttackSucceed.send(action.transaction_id)
})

app.ports.showChat.subscribe(chatId => {
  setTimeout(() => {
    // console.log('opening battle chat: ' + chatId)

    // does not work :P
    // let embedId = document.getElementsByClassName("tlk-webchat");
    // if (embedId && embedId[0]) {
    //   embedId[0].innerHTML = `<div id="tlkio" data-channel="monstereos-${chatId}" style="width:100%;height:400px;"></div><script async src="http://tlk.io/embed.js" type="text/javascript"></script>`;
    // }
  }, 900)

});

// generate secret and hash random pair
const generateHashInfo = () => {
  if (!flags.hashInfo) {
    // generate secret
    const hash = ecc.sha256("meos" + Date.now() + hashInfo.mouseMove.join())
    const hashBinary = Buffer.from(hash, 'hex');
    const secret = ecc.sha256(hashBinary)

    hashInfo.lastPair = { hash, secret }

    flags.hashInfo = hashInfo.lastPair

    localStorage.setItem(STORAGE_KEY, JSON.stringify(flags))
  }

  return flags.hashInfo
}

// destroy last battle commitment random pair
const destroyHashInfo = () => {
  flags.hashInfo = null
  localStorage.setItem(STORAGE_KEY, JSON.stringify(flags))
}

// keep track of mouse to help hash generation
const handleMouseMove = event => {
  let dot, eventDoc, doc, body, pageX, pageY;

  event = event || window.event; // IE-ism

  // If pageX/Y aren't available and clientX/Y are,
  // calculate pageX/Y - logic taken from jQuery.
  // (This is to support old IE)
  if (event.pageX == null && event.clientX != null) {
      eventDoc = (event.target && event.target.ownerDocument) || document;
      doc = eventDoc.documentElement;
      body = eventDoc.body;

      event.pageX = event.clientX +
        (doc && doc.scrollLeft || body && body.scrollLeft || 0) -
        (doc && doc.clientLeft || body && body.clientLeft || 0);
      event.pageY = event.clientY +
        (doc && doc.scrollTop  || body && body.scrollTop  || 0) -
        (doc && doc.clientTop  || body && body.clientTop  || 0 );
  }

  // Use event.pageX / event.pageY here
  hashInfo.mouseMove.unshift("x" + event.pageX + "y" + event.pageY)
  hashInfo.mouseMove = hashInfo.mouseMove.slice(0,10);
}
document.onmousemove = handleMouseMove;

registerServiceWorker();
