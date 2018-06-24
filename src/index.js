import './main.css';
import { Main } from './Main.elm';
import registerServiceWorker from './registerServiceWorker';
import Eos from 'eosjs'

const STORAGE_KEY = 'MONSTEREOS'
const CHAIN_PROTOCOL = 'http'
const CHAIN_HOST = 'mainnet.eoscalgary.io'
const CHAIN_PORT = 80
const CHAIN_ADDRESS = CHAIN_PROTOCOL + '://' + CHAIN_HOST + ':' + CHAIN_PORT
const CHAIN_ID = 'aca376f206b8fc25a6ed44dbdc66547c36c6c33e3a119ffbeaef943642f0e906'
const MONSTERS_ACCOUNT = 'monstereosio'
const MONSTERS_TABLE = 'pets'
const CONFIG_TABLE = 'petconfig'
const BALANCES_TABLE = 'accounts'
const TOKEN_SYMBOL = 'EOS'
const MEMO = 'MonsterEOS Wallet Deposit'

const storageBody = localStorage.getItem(STORAGE_KEY)
const flags = !storageBody ?
  { user: { eosAccount: "", publicKey: "" } } : JSON.parse(storageBody)

const app = Main.embed(document.getElementById('root'), flags)

/* Eos and Scatter Setup */
const network = {
  blockchain: 'eos',
  host: CHAIN_HOST,
  port: CHAIN_PORT,
  chainId: CHAIN_ID
}
const localNet = Eos({httpEndpoint: CHAIN_ADDRESS, chainId: CHAIN_ID})

let scatter = null
let globalConfigs = null

const scatterDetection = setTimeout(() => {
  if (scatter == null) {
    app.ports.setScatterInstalled.send(false)
  }
}, 5000)

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

    app.ports.setMonsters.send(monsters)
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

    app.ports.setWallet.send(funds)
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
    .catch(e => {
        console.error('error on pet creation ', e)
        const errorObj = JSON.parse(e)
        const errorMsg = (e && e.message) ||
        (errorObj && errorObj.error && errorObj.error.details && errorObj.error.details.length && errorObj.error.details[0].message) ||
        'An error happened while creating the monster'
        app.ports.monsterCreationFailed.send(errorMsg)
      })

  if (createpet) app.ports.monsterCreationSucceed.send(createpet.transaction_id)
})

app.ports.requestFeed.subscribe(async (petId) => {
  const auth = getAuthorization()

  const contract = await getContract()

  const feedpet = await contract.feedpet(petId, auth.permission)
    .catch(e => {
        console.error('error on feedpet ', e)
        const errorMsg = (e && e.message) ||
        'An error happened while feeding the monster'
        app.ports.feedFailed.send(errorMsg)
      })

  console.log(feedpet)

  if(feedpet) app.ports.feedSucceed.send(feedpet.transaction_id)
})

app.ports.requestAwake.subscribe(async (petId) => {

  const auth = getAuthorization()

  const contract = await getContract()

  const awakepet = await contract.awakepet(petId, auth.permission)
    .catch(e => {
        console.error('error on waking pet ', e)
        const errorMsg = (e && e.message) ||
        'An error happened while awaking the monster'
        app.ports.awakeFailed.send(errorMsg)
      })

  console.log(awakepet)

  if(awakepet) app.ports.awakeSucceed.send(awakepet.transaction_id)
})

app.ports.requestBed.subscribe(async (petId) => {
  const auth = getAuthorization()

  const contract = await getContract()

  const bedpet = await contract.bedpet(petId, auth.permission)
    .catch(e => {
        console.error('error on bed pet ', e)
        const errorMsg = (e && e.message) ||
        'An error happened while attempting to bed the monster'
        app.ports.bedFailed.send(errorMsg)
      })

  console.log(bedpet)

  if(bedpet) app.ports.bedSucceed.send(bedpet.transaction_id)
})

app.ports.requestDelete.subscribe(async (petId) => {
  const auth = getAuthorization()

  const contract = await getContract()

  const destroypet = await contract.destroypet(petId, auth.permission)
    .catch(e => {
        console.error('error on destroy pet ', e)
        const errorMsg = (e && e.message) ||
        'An error happened while attempting to destroy the monster'
        app.ports.deleteFailed.send(errorMsg)
      })

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

  const contract = await getContract()

  const transferpet = await contract.transferpet(petId, newOwner)
    .catch(e => {
        console.error('error on transferring pet ', e)
        const errorMsg = (e && e.message) ||
        'An error happened while attempting to transferring the monster'
        app.ports.transferFailed.send(errorMsg)
      })

  console.log(transferpet)

  if(transferpet) app.ports.transferSucceed.send(transferpet.transaction_id)
})


app.ports.requestClaim.subscribe(async (petId) => {
  const auth = getAuthorization()

  const contract = await getContract()

  const claimpet = await contract.claimpet(petId)
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

registerServiceWorker();
