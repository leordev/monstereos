import * as React from "react"
import { MonsterType, Arena, MonsterArenaStats, Element, isWatcher, BATTLE_PHASE_GOING } from "./battles"
import { State, pushNotification } from "../../store"
import { getEosAccount } from "../../utils/scatter"
import { connect } from "react-redux"
import {
  monsterImageSrc,
  monsterModelSrc,
  validateTypeId
} from "../monsters/monsters"
import getConfig from "../monsters/monsterTypeConfiguration"
import { Monster3DProfile, ActionType } from "react-monstereos-profile"

const AVAILABLE_ARENA_ARTS = 18

const getArenaBackground = (startedAt: number) => {
  return `arena-${startedAt % AVAILABLE_ARENA_ARTS}`
}

const elementButton = (
  elementId: number,
  onClick: any,
  showLabelAndCancel: boolean
) => {

  let elementDisplay = []

  switch (elementId) {
    case 1:
      elementDisplay = ["is-brown", "tree", "Wood"]
      break
    case 2:
      elementDisplay = ["is-success", "leaf", "Earth"]
      break
    case 3:
      elementDisplay = ["is-info", "tint", "Water"]
      break
    case 4:
      elementDisplay = ["is-danger", "fire", "Fire"]
      break
    case 5:
      elementDisplay = ["is-dark", "wrench", "Metal"]
      break
    case 6:
      elementDisplay = ["is-primary", "paw", "Animal"]
      break
    case 7:
      elementDisplay = ["is-purple", "bug", "Poison"]
      break
    case 8:
      elementDisplay = ["is-black", "adjust", "Undead"]
      break
    case 9:
      elementDisplay = ["is-warning", "bolt", "Lightning"]
      break
    default:
      elementDisplay = ["", "asterisk", "Neutral"]
  }

  const elementClass = `button is-small ${elementDisplay[0]}`

  return !showLabelAndCancel ? <a key={elementId}
    className={elementClass}
    onClick={onClick}>
    <i className={`fa fa-${elementDisplay[1]}`} />
  </a> : <React.Fragment>
      <a className={elementClass} onClick={() => onClick(0, -1)}>{elementDisplay[2]} Attack <i className="fa fa-ban" style={{ marginLeft: 5 }} /></a>
    </React.Fragment>
}

const hpBar = (hpValue: number, monsterName: string) => {
  const hpClass = hpValue > 65 ? "is-success" :
    hpValue > 30 ? "is-warning" : "is-danger"

  return <div>
    <progress
      className={`progress ${hpClass}`}
      value={hpValue}
      data-label={monsterName}
      max={100}>
      {hpValue}%
    </progress>
  </div>
}

const winnerBanner = (winner: string, isWinner?: boolean) => {
  const status = isWinner === undefined ?
    ["has-text-info", `${winner} WON!`] :
    isWinner ? ["has-text-success", "You WON!"] :
      ["has-text-danger", "You LOST!"]

  return <div className={`battle-winner-banner ${status[0]}`}>
    {status[1]}
  </div>
}

interface Props {
  arena: Arena,
  scatter: any,
  identity: string,
  elements: Element[],
  monsterTypes: MonsterType[],
  attackSelection: any,
  enemySelection: any,
  selectedEnemyId?: number,
  selectedElementId?: number,
  selectedPetId?: number,
  submitAttack: any,
  winner?: string
}

interface HpLog {
  petId: number,
  hpDiff: number,
  time: number
}

interface ReactState {
  hpLog: HpLog[]
}

class BattleArena extends React.Component<Props, ReactState> {

  public state = { hpLog: [] as HpLog[] }

  public render() {

    const { arena, winner, identity } = this.props

    const isWinner = isWatcher(arena, identity) ? undefined : winner === identity

    const isBattleGoing = arena.phase === BATTLE_PHASE_GOING

    return <div className={`battle-arena ${getArenaBackground(arena.startedAt)}`}>
      {arena.petsStats.map((monster) => this.renderArenaMonster(monster, isBattleGoing))}
      {winner && winnerBanner(winner, isWinner)}
    </div>
  }

  public componentDidUpdate(prevProps: Props) {
    // Typical usage (don't forget to compare props):
    if (this.props.arena.petsStats !== prevProps.arena.petsStats) {
      this.updateHpLog(this.props.arena.petsStats, prevProps.arena.petsStats)
    }
  }

  private updateHpLog = (
    newStats: MonsterArenaStats[],
    oldStats: MonsterArenaStats[],
  ) => {
    const newLogs = newStats.map((newStat) => {
      const oldStat = oldStats.find((item) => item.pet_id === newStat.pet_id)
      const hpDiff = oldStat ? newStat.hp - oldStat.hp : 0
      return { petId: newStat.pet_id, hpDiff, time: Date.now() }
    }).filter((item) => item.hpDiff !== 0)

    if (newLogs.length) {
      this.setState({ hpLog: this.state.hpLog.concat(newLogs) })
    }
  }

  private renderArenaMonster = (monster: MonsterArenaStats, isBattleGoing: boolean) => {
    const {
      arena,
      identity,
      selectedEnemyId,
      enemySelection,
      selectedElementId
    } = this.props

    const myMonster = monster.player === identity

    const myTurn = isBattleGoing &&
      (arena.commits[0].player === identity ||
        Date.now() - arena.lastMoveAt > 60000)

    const monsterClass =
      (myMonster ? "my-monster" : "enemy-monster") +
      (monster.pet_id === selectedEnemyId && isBattleGoing ? " active" : "")

    const enemyClick = !myMonster ?
      () => enemySelection(monster.pet_id) :
      undefined

    const { position, rotation, cameraPosition } = getConfig(monster.pet_type)

    return <div className="arena-monster"
      key={monster.pet_id}>
      {
        validateTypeId(monster.pet_type)
          ? (
            <div
              className={`image ${monsterClass}`}
              onClick={enemyClick}
            >
              <Monster3DProfile
                typeId={monster.pet_type}
                path={monsterModelSrc(monster.pet_type)}
                action={ActionType.IDLE}
                position={position}
                rotation={rotation}
                cameraPosition={cameraPosition}
                size={{ width: "200px", height: "228px" }}
                background={{ alpha: 0 }}
                zoom={false}
              />
            </div>
          )
          : (
            <figure
              className="image">
              <img
                src={monsterImageSrc(monster.pet_type)}
                className={monsterClass}
                onClick={enemyClick} />
            </figure>
          )
      }
      {this.hpNotification(monster.pet_id)}
      {hpBar(monster.hp, monster.player)}
      {myMonster && myTurn && this.attackButtons(monster)}
      {myTurn && selectedEnemyId === monster.pet_id &&
        (selectedElementId !== undefined && selectedElementId >= 0) &&
        this.confirmAttackButton()}
    </div>
  }


  private hpNotification = (petId: number) => {
    const { hpLog } = this.state

    const notifications = hpLog
      .filter((item) => item.petId === petId && (Date.now() - item.time) < 5000).map((item, index) => (
        <span
          key={index}
          className="monster-hp-notification">
          {item.hpDiff}
        </span>
      ))

    return notifications.length ? notifications : null
  }

  private confirmAttackButton = () => {
    return <a
      className="button is-small is-danger"
      onClick={this.props.submitAttack}>
      Submit Attack
    </a>
  }

  private attackButtons = (pet: MonsterArenaStats) => {

    const { monsterTypes, attackSelection, selectedElementId, selectedPetId } = this.props

    const monsterType = monsterTypes.find((type) => type.id === pet.pet_type)

    const elements = monsterType ? monsterType.elements : [0] // neutral

    return <div className="buttons elements">
      {pet.pet_id === selectedPetId ?
        elementButton(selectedElementId!, attackSelection, true) :
        elements.map((element) => {
          const doAttack = () => attackSelection(pet.pet_id, element)
          return elementButton(element, doAttack, false)
        })}
    </div>
  }
}

const mapStateToProps = (state: State) => {
  return {
    scatter: state.scatter,
    identity: getEosAccount(state.identity)
  }
}

const mapDispatchToProps = {
  dispatchPushNotification: pushNotification
}

export default connect(mapStateToProps, mapDispatchToProps)(BattleArena)