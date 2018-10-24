import { Block, BlockInfo } from "demux"
import { EosAction } from "demux-eos"

export class MongoBlock implements Block {
  public actions: EosAction[]
  public blockInfo: BlockInfo

  constructor(rawBlock: any) {
    this.actions = this.collectActionsFromBlock(rawBlock)
    this.blockInfo = {
      blockNumber: rawBlock.block_num,
      blockHash: rawBlock.block_id,
      previousBlockHash: rawBlock.block.previous,
      timestamp: new Date(rawBlock.block.timestamp),
    }
  }

  public addInlineActions(transactionTraces: any): void {

    const newActions = this.actions.map((action) => {

      console.info(transactionTraces)

      const transaction = transactionTraces.find((trx: any) =>
        trx.id === action.payload.transactionId)

      if (transaction) {
        const actionTrace = transaction.action_traces.find(
          ({act}: any) =>
            action.type === `${act.account}::${act.name}`,
        )

        if (actionTrace) {
          return {
            ...action,
            payload: {
              ...action.payload,
              inlineActions: actionTrace.inline_traces,
            },
          }
        }
      }

      return action

    })

    this.actions = newActions
  }

  protected collectActionsFromBlock(rawBlock: any = { actions: [] }): EosAction[] {
    return this.flattenArray(rawBlock.block.transactions.map(({ trx }: any) => {

      // Deferred transactions
      if (!trx.transaction) {
        return [{
          type: `deferred::emptytrx`,
          payload: {
            transactionId: trx.id,
            actionIndex: 0,
          }
        }]
      }

      return trx.transaction.actions.map((action: any, actionIndex: number) => {

        // Delete unneeded hex data if we have deserialized data
        if (action.payload) {
          delete action.hex_data // eslint-disable-line
        }

        return {
          type: `${action.account}::${action.name}`,
          payload: {
            actionIndex,
            transactionId: trx.id,
            ...action,
          },
        }
      })
    }))
  }

  private flattenArray(arr: any[]): any[] {
    return arr.reduce((flat, toFlatten) =>
      flat.concat(Array.isArray(toFlatten) ? this.flattenArray(toFlatten) : toFlatten), [])
  }
}
