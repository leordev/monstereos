import { GlobalConfig } from "../../store"

export interface MonsterAction {
  action: string,
  createdAt: number,
  author: string,
  block: number,
  transaction: string,
}

export interface MonsterProps {
  id: number,
  name: string,
  owner: string,
  type: number,
  createdAt: number,
  deathAt: number,
  hunger: number,
  health: number,
  energy: number,
  lastFeedAt: number,
  lastAwakeAt: number,
  lastBedAt: number,
  isSleeping: boolean,
  actions: MonsterAction[]
}

export const parseMonstersFromChain = (pet: any, config: GlobalConfig): MonsterProps => {
  const monster = {
    id: pet.id,
    name: pet.name,
    owner: pet.owner,
    type: pet.type,
    deathAt: 0,
    createdAt: pet.created_at * 1000,
    lastFeedAt: pet.last_fed_at * 1000,
    lastAwakeAt: pet.last_awake_at * 1000,
    lastBedAt: pet.last_bed_at * 1000,
    isSleeping: pet.last_bed_at > pet.last_awake_at,
    hunger: 100,
    health: 100,
    energy: 100,
    actions: []
  }

  return calcMonsterStats(monster, config)
}

export const calcMonsterStats = (
  monster: MonsterProps,
  config: GlobalConfig,
): MonsterProps => {

  if (config) {
    const currentTime = Date.now()

    // calculates hunger bar
    monster.hunger = 100
    monster.deathAt = 0

    const hungrySeconds = (currentTime - monster.lastFeedAt) / 1000
    const hungryPoints = hungrySeconds * config.max_hunger_points / config.hunger_to_zero
    monster.hunger = Math.round(config.max_hunger_points - hungryPoints)
    monster.hunger = monster.hunger < 0 ? 0 : monster.hunger

    const effectHpHunger = hungryPoints > config.max_health ?
      Math.round((hungryPoints - config.max_hunger_points) / config.hunger_hp_modifier) :
      0

    // calculates energy
    const awakeSeconds = (currentTime - monster.lastAwakeAt) / 1000
    const awakePoints = 100 * awakeSeconds / (24 * 3600)
    monster.energy = 100 - awakePoints

    // calculates health and death time
    monster.health = config.max_health - effectHpHunger
    if (monster.health <= 0) {
      monster.hunger = monster.health = monster.energy = 0

      monster.deathAt = ((monster.lastFeedAt / 1000) + config.hunger_to_zero
        + (config.hunger_to_zero * config.hunger_hp_modifier)) * 1000
    }

  }

  return monster
}

export const getCurrentAction = (monster: MonsterProps, ActionType: any) => {
  if (monster.isSleeping) {
    return ActionType.SLEEPING
  } else if (monster.deathAt) {
    return ActionType.DEAD
  }
  return ActionType.IDLE
}

export const monsterImageSrc = (typeId: number) =>
  (`/images/monsters/monster-${typeId}.png`)

export const monsterModelSrc = (typeId: number) =>
  (`/models/monsters/monster-${typeId}.gltf`)