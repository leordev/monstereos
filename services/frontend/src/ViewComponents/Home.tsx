import * as React from "react"
import Body from "../modules/interface/body"

export interface HomeProps {
    identity: any
}

export interface HomeState {
    monsterlist: any
}

export default class Home extends React.Component<HomeProps, HomeState> {
    constructor(props: HomeProps) {
        super(props)

        this.state = {
            monsterlist: { none: "" }
        }
    }

    public render() {
        return (
            <React.Fragment>
                <div className="title-monsters" style={{width:"100%"}}>
                    <div className="sub-head">
                        <img
                            className="icon-monsters"
                            src="/images/icon/MMONSTERS.png"
                            style={{width:"100%"}}
                        />
                    </div>
                    <img
                        className="Separation"
                        src="images/icon/Separation.png"
                    />
                </div>
                <div className="statistics" style={{width:"100%"}}>
                    <Body />
                    <Body />
                    <Body />
                </div>
            </React.Fragment>
        )
    }
}
