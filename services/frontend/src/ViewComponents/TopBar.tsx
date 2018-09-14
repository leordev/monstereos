import * as React from "react"
import { Button } from "reactstrap"
import { connect } from "react-redux"
import { State, doLogout } from "../store"

export interface TopBarProps {
    identity: any
}

export interface TopBarState {
    eos_ammount: number
}

class TopBar extends React.Component<TopBarProps, TopBarState> {
    constructor(props: TopBarProps) {
        super(props)

        this.state = {
            eos_ammount: 0
        }
    }

    public render() {
        const { identity } = this.props
        const { eos_ammount } = this.state
        return (
            <React.Fragment>
                <Button>{eos_ammount}{identity}</Button>
            </React.Fragment>
        )
    }
}

const mapStateToProps = (state: State) => ({
    identity: state.identity
})

const mapDispatchToProps = {
    dispatchDoLogout: doLogout
}

export default connect(
    mapStateToProps,
    mapDispatchToProps
)(TopBar)
