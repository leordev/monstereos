import * as React from "react"

export interface TopRankProps {
    identity:any
}

export interface TopRankState {
    usersData:any
}

export default class TopRank extends React.Component<TopRankProps, TopRankState> {
  constructor(props: TopRankProps) {
    super(props)

    this.state = {
        usersData:{
            none:""
        }
    }
  }

  public render() {
    return (
      <div>
        I will do dis soon
      </div>
    )
  }
}
