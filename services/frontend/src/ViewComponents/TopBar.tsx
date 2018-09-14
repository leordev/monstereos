import * as React from "react"
import { connect } from "react-redux"
import { State, doLogout } from "../store"
import { Button, Navbar,NavbarBrand} from "reactstrap"
import Nav_User_Icon from "../assets/UI_Elements/General/Nav_User_Icon.png"
import Hello_User from "../assets/UI_Elements/General/Hello_User.png"
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
            <Navbar color="primary" expand="md" style={{height:"60px", color:"blue"}}>
            <NavbarBrand style={{display:"flex",flexDirection:"column"}}>
                <img src={Nav_User_Icon} style={{width:"58px"}}/> 
            </NavbarBrand>
            <Button>{eos_ammount}{identity}</Button>
            <img src={Hello_User} style={{width:"25px"}}/> Player 750{identity}
            </Navbar>
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
