import { BlockInfo } from "demux"
import moment from "moment"

const createPet = async (db: any, payload: any, blockInfo: BlockInfo) => {

  console.info("\n\n==== Create Pet Updater ====")
  console.info("\n\nUpdater Payload >>> \n", payload)
  console.info("\n\nUpdater Block Info >>> \n", blockInfo)

  const data = {
    owner: payload.data.owner,
    pet_name: payload.data.pet_name,
    created_block: blockInfo.blockNumber,
    created_trx: payload.transactionId,
    created_at: blockInfo.timestamp,
    created_eosacc: payload.authorization[0].actor,
  }

  console.info("DB Data to Insert >>> ", data)

  const res = await db.pets.insert(data)

  console.info("DB State Result >>> ", res)

  const actionData = {
    pet_id: res.id,
    action: "createpet",
    is_invalid: false,
    created_block: blockInfo.blockNumber,
    created_trx: payload.transactionId,
    created_at: blockInfo.timestamp,
    created_eosacc: payload.authorization[0].actor,
  }

  console.info("DB Action Data to Insert >>> ", actionData)

  const actionRes = await db.pet_actions.insert(actionData)

  console.info("DB State Action Result >>> ", actionRes)
}

const addpettype = async (db: any, payload: any, blockInfo: BlockInfo) => {

  console.info("\n\n==== Create Element Updater ====")
  console.info("\n\nUpdater Payload >>> \n", payload)
  console.info("\n\nUpdater Block Info >>> \n", blockInfo)

  const data = {
    elements: payload.data.elements,
    created_block: blockInfo.blockNumber,
    created_trx: payload.transactionId,
    created_at: blockInfo.timestamp,
    created_eosacc: payload.authorization[0].actor,
  }

  console.info("DB Data to Insert >>> ", data)

  const res = await db.types.insert(data)

  console.info("DB State Result >>> ", res)
}

const addelemttype = async (db: any, payload: any, blockInfo: BlockInfo) => {

  console.info("\n\n==== Create Element Type ====")
  console.info("\n\nUpdater Payload >>> \n", payload)
  console.info("\n\nUpdater Block Info >>> \n", blockInfo)

  const data = {
    ratios: payload.data.ratios,
    created_block: blockInfo.blockNumber,
    created_trx: payload.transactionId,
    created_at: blockInfo.timestamp,
    created_eosacc: payload.authorization[0].actor,
  }

  console.info("DB Data to Insert >>> ", data)

  const res = await db.elements.insert(data)

  console.info("DB State Result >>> ", res)

}

const addAction = async (db: any, payload: any, blockInfo: BlockInfo) => {

  console.info("\n\n==== Add Pet Action ====")
  console.info("\n\nUpdater Payload >>> \n", payload)
  console.info("\n\nUpdater Block Info >>> \n", blockInfo)

  const data = {
    pet_id: payload.data.pet_id,
    action: payload.name,
    is_invalid: false,
    created_block: blockInfo.blockNumber,
    created_trx: payload.transactionId,
    created_at: blockInfo.timestamp,
    created_eosacc: payload.authorization[0].actor,
  }

  console.info("DB Data to Insert >>> ", data)

  const res = await db.pet_actions.insert(data)

  console.info("DB State Result >>> ", res)

}

const destroypet = async (db: any, payload: any, blockInfo: BlockInfo) => {

  console.info("\n\n==== Destroy Pet ====")
  console.info("\n\nUpdater Payload >>> \n", payload)
  console.info("\n\nUpdater Block Info >>> \n", blockInfo)

  const data = {
    criteria: { id: payload.data.pet_id },
    statement: { destroyed_at: blockInfo.timestamp },
  }

  console.info("DB Data to Insert >>> ", data)

  const res = await db.pets.update(data.criteria, data.statement)

  console.info("DB State Result >>> ", res)

}

const battlecreate = async (db: any, payload: any, blockInfo: BlockInfo) => {

  console.info("\n\n==== Battle Create ====")
  console.info("\n\nUpdater Payload >>> \n", payload)
  console.info("\n\nUpdater Block Info >>> \n", blockInfo)

  const data = {
    host: payload.data.host,
    mode: payload.data.mode,
    created_block: blockInfo.blockNumber,
    created_trx: payload.transactionId,
    created_at: blockInfo.timestamp,
    created_eosacc: payload.authorization[0].actor,
  }

  console.info("DB Data to Insert >>> ", data)

  const res = await db.battles.insert(data)

  console.info("DB State Result >>> ", res)

}

const quickbattle = async (db: any, payload: any, blockInfo: BlockInfo) => {

  console.info("\n\n==== Quick Battle ====")
  console.info("\n\nUpdater Payload >>> \n", payload)
  console.info("\n\nUpdater Block Info >>> \n", blockInfo)

  const lastBattle = await getLastBattle(db)
  const startedBattleMinTime = new Date(2018, 0, 1).getTime()

  // if last battle is already started, creates a new one
  if (moment(lastBattle.started_at).valueOf() > startedBattleMinTime) {

    const data = {
      host: payload.authorization[0].actor,
      mode: payload.data.mode,
      created_block: blockInfo.blockNumber,
      created_trx: payload.transactionId,
      created_at: blockInfo.timestamp,
      created_eosacc: payload.authorization[0].actor,
    }

    console.info("DB Data to Insert >>> ", data)

    const res = await db.battles.insert(data)

    console.info("DB State Result >>> ", res)

    await battleJoin(db, res.id, payload.data.picks.pets, payload.authorization[0].actor, blockInfo, true)

  } else { // join in the current battle
    await battleJoin(db, lastBattle.id, payload.data.picks.pets, payload.authorization[0].actor, blockInfo, false)
  }
}

const getLastBattle = async (db: any) => {
  return await db.battles.findOne({}, {
    order: [
      { field: "id", direction: "desc" },
    ],
  })
}

const getLastBattleByHost = async (db: any, host: string) => {
  return await db.battles.findOne({
    host,
  }, {
    order: [
      { field: "id", direction: "desc" },
    ],
  })
}

const battlestart = async (db: any, payload: any, blockInfo: BlockInfo) => {

  console.info("\n\n==== Battle Start/Picks ====")
  console.info("\n\nUpdater Payload >>> \n", payload)
  console.info("\n\nUpdater Block Info >>> \n", blockInfo)

  if (payload.data.picks) {
    const battle = await getLastBattleByHost(db, payload.data.host)

    // check current existent picks
    const existentPicks = await db.battle_picks.findOne({
      battle_id: battle.id,
    })

    battleJoin(db, battle.id, payload.data.picks.pets, payload.authorization[0].actor, blockInfo, !existentPicks)
  } else { // ignoring old battles
    console.info("Ignoring old battle pick")
  }

}

const battleJoin = async (
  db: any,
  battleId: any,
  pickPets: any,
  picker: any,
  blockInfo: BlockInfo,
  firstPick: boolean,
) => {

  // insert new picks
  const picks = pickPets.map((petId: number) =>
    db.battle_picks.save({
      battle_id: battleId,
      pet_id: petId,
      picker,
    }))

  await Promise.all(picks)

  // if it's second pick set the battle started time
  if (!firstPick) {
    await db.battles.update({ id: battleId }, { started_at: blockInfo.timestamp })
  }

  console.info("DB Battle Joining Processed Successfully")
}

const battleattack = async (db: any, payload: any, blockInfo: BlockInfo) => {

  console.info("\n\n==== Battle Create ====")
  console.info("\n\nUpdater Payload >>> \n", payload)
  console.info("\n\nUpdater Block Info >>> \n", blockInfo)

  const battle = await getLastBattleByHost(db, payload.data.host)

  const data = {
    battle_id: battle.id,
    pet_id: payload.data.pet_id,
    enemy_pet_id: payload.data.pet_enemy_id,
    element_id: payload.data.element,
    created_block: blockInfo.blockNumber,
    created_trx: payload.transactionId,
    created_at: blockInfo.timestamp,
    created_eosacc: payload.authorization[0].actor,
  }

  console.info("DB Data to Insert >>> ", data)

  const res = await db.battle_turns.insert(data)

  console.info("DB State Result >>> ", res)

  console.info("Checking battle winner...")
  if (payload.inlineActions && payload.inlineActions.length) {
    const { act: finishAction }: any = payload.inlineActions.find(
      ({act}: any) => act.account === "monstereosio" &&
        act.name === "battlefinish") || {}

    if (finishAction && finishAction.data && finishAction.data.winner) {
      console.info("Battle has a winner: ", finishAction.data.winner)

      await db.battles.update(
        { id: battle.id },
        { winner: finishAction.data.winner },
      )
    } else {
      console.info("battle has inline actions but no winner...")
    }
  } else {
    console.info("battle has no winner...")
  }

}

const messagefrom =  async (db: any, payload: any, blockInfo: BlockInfo) => {

  console.info("\n\n==== Message From ====")
  console.info("\n\nUpdater Payload >>> \n", payload)
  console.info("\n\nUpdater Block Info >>> \n", blockInfo)

  const data = {
    pet_id: payload.data.pet_id,
    message: payload.data.message,
    created_block: blockInfo.blockNumber,
    created_trx: payload.transactionId,
    created_at: blockInfo.timestamp,
    created_eosacc: payload.authorization[0].actor,
  }

  const res = await db.messages.insert(data)
  console.info("DB State Result >>> ", res)
}

const updaters = [
  {
    actionType: "monstereosio::createpet",
    updater: createPet,
  },
  {
    actionType: "monstereosio::addpettype",
    updater: addpettype,
  },
  {
    actionType: "monstereosio::addelemttype",
    updater: addelemttype,
  },
  {
    actionType: "monstereosio::feedpet",
    updater: addAction,
  },
  {
    actionType: "monstereosio::bedpet",
    updater: addAction,
  },
  {
    actionType: "monstereosio::awakepet",
    updater: addAction,
  },
  {
    actionType: "monstereosio::destroypet",
    updater: destroypet,
  },
  {
    actionType: "monstereosio::quickbattle",
    updater: quickbattle,
  },
  {
    actionType: "monstereosio::battlecreate",
    updater: battlecreate,
  },
  {
    actionType: "monstereosio::battlestart",
    updater: battlestart,
  },
  {
    actionType: "monstereosio::battleattack",
    updater: battleattack,
  },
  {
    actionType: "monstereosio::messagefrom",
    updater: messagefrom,
  },
]

export { updaters }
