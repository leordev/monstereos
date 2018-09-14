import * as React from "react"

export interface ArenaProps {
    identity:any
}

export interface ArenaState {
    users:any
}

export default class Arena extends React.Component<ArenaProps, ArenaState> {
  constructor(props: ArenaProps) {
    super(props)

    this.state = {
        users:{none:""}
    }
  }

  public render() {
    return (
      <div>
        Chuz have this
      </div>
    )
  }
}
