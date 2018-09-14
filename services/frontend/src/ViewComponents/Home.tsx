import * as React from "react"

export interface HomeProps {
    identity: any
}

export interface HomeState {
    monsterlist:any
}

export default class Home extends React.Component<HomeProps, HomeState> {
  constructor(props: HomeProps) {
    super(props)

    this.state = {
        monsterlist:{none:""}
    }
  }

  public render() {
    return (
      <div>
        Max Have this
      </div>
    )
  }
}
