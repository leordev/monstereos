import { Rpc } from "eosjs2"
import massive from "massive"
import moment from "moment"
import nodeFetch from "node-fetch"

const BLOCK_SYNC_TOLERANCE = process.env.BLOCK_SYNC_TOLERANCE || 10

const NODEOS = process.env.CHAIN_HOST || "http://localhost:8840"
const rpc = new Rpc.JsonRpc(NODEOS, { fetch: nodeFetch })

const dbConfig = {
  user: process.env.DB_USER || "user",
  password: process.env.DB_PASSWORD || "pass",
  host: process.env.DB_HOST || "localhost",
  port: Number(process.env.DB_PORT) || 5432,
  database: process.env.DB_NAME || "monstereosio",
  schema: process.env.DB_SCHEMA || "pets",
}

const PENDING_TYPE_PET = -1
const DESTROYED_TYPE_PET = -2
const EMPTY_TIMESTAMP = "1970-01-01 00:00:00"
const MONSTERS_ACCOUNT = "monstereosio"
const IDLE_FEED_DEATH_MILLIS = 72 * 60 * 60000 // TODO: get this amount dynamically

const isChainSync = async (db: any) => {

  const chainInfo = await rpc.get_info()

  const indexState = await db._index_state.findOne({ id: 1 })

  const blocksDiff = chainInfo.head_block_num - indexState.block_number

  return blocksDiff < BLOCK_SYNC_TOLERANCE
}

const updatePetsWithoutTypes = async (db: any) => {
  try {
    const pendingPets = await db.pets.find({type_id: PENDING_TYPE_PET, destroyed_at: EMPTY_TIMESTAMP}, { limit: 100 })

    if (pendingPets.length) {
      console.info(`${pendingPets.length} Pets to Update Type`)

      const pendingPetsChain = pendingPets.map((pet: any) => {
        return rpc.get_table_rows({
          json: true,
          code: MONSTERS_ACCOUNT,
          scope: MONSTERS_ACCOUNT,
          table: "pets",
          lower_bound: pet.id,
          limit: 1,
        }).then((res: any) => res.rows[0])
      })

      const pendingPetsChainRes = await Promise.all(pendingPetsChain)

      const petsToUpdate = pendingPets.map((pet: any) => {
        const chainPet: any = pendingPetsChainRes.find((p: any) => p.id === pet.id)
        return {id: pet.id, type_id: chainPet ? chainPet.type : DESTROYED_TYPE_PET }
      })
      .filter((pet: any) => pet.type_id >= 0)

      console.info("Type Updated Pets:", petsToUpdate)

      const updatedPets = petsToUpdate.map((pet: any) => (db.pets.save(pet)))
      if (updatedPets.length) {
        await Promise.all(updatedPets)
      }
    }
  } catch (error) {
    console.error("Fail to update data", error)
  }
}

const killMonsters = async (db: any, dbFull: any) => {
  try {
    const pendingPets = await db.pets.find({death_at: EMPTY_TIMESTAMP})

    if (pendingPets.length) {
      console.info(`${pendingPets.length}  Pets to Check Death`)

      const pendingPetsIds = pendingPets.map((pet: any) => pet.id).join(",")

      const query = `
      SELECT pet_id, MAX(created_at) as last_feed_at FROM "pets"."pet_actions"
       WHERE pet_id IN (${pendingPetsIds}) AND action = 'feedpet' AND is_invalid = FALSE
       GROUP BY pet_id
      `

      const lastFeeds = await dbFull.query(query)

      const deadPets = pendingPets.map((pet: any) => {
        const lastFeedAction = lastFeeds.find((action: any) => action.pet_id === pet.id)

        const lastFeed = lastFeedAction ? lastFeedAction.last_feed_at : pet.created_at

        const lastFeedTime = moment(lastFeed).valueOf()

        const deathTime = lastFeedTime + IDLE_FEED_DEATH_MILLIS + (moment().utcOffset() * 60000)

        const isDead = Date.now() - deathTime > 0

        const deathAt = isDead ? moment(deathTime).toISOString() : pet.death_at

        return { isDead, deathAt, id: pet.id }
      }).filter((pet: any) => pet.isDead)

      const updatedDeadPets = deadPets.map((pet: any) => (db.pets.save({id: pet.id, death_at: pet.deathAt})))
      if (updatedDeadPets.length) {
        console.info("Dead pets: ", deadPets)
        await Promise.all(updatedDeadPets)
      }
    }
  } catch (error) {
    console.error("Fail to update dead pets", error)
  }
}

// clean old arenas
const cleanOldArenas = async (_: any) => {
  // TODO: implement
}

// main loop that read and updates data
const loop = async (db: any, dbFull: any) => {

  console.info("Data Cleaner Loop")

  const isSync = await isChainSync(db)

  if (isSync) {
    console.info("Chain is synched, starting cleaning tasks")

    await updatePetsWithoutTypes(db)

    await cleanOldArenas(db)

    await killMonsters(db, dbFull)
  } else {
    console.info("Chain is out of sync, skipping cleaning")
  }

  setTimeout(() => loop(db, dbFull), 500)

}

const init = async () => {
  const db = await massive(dbConfig)
  loop(db[dbConfig.schema], db)
}

init()
