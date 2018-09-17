import * as React from "react"
import { Link } from "react-router-dom"
import { connect } from "react-redux"
import { State, doLogout, requestScatterIdentity } from "../../store"
import { getEosAccount, SCATTER_EXTENSION_LINK } from "../../utils/scatter"

interface Props {
  scatter: any,
  identity: any,
  dispatchDoLogout: any,
  dispatchRequestScatterIdentity: any,
  myWalletBalance: string,
}

interface ReactState {
  activeMenu: boolean
}

class TopMenu extends React.Component<Props, ReactState> {
  public state: ReactState = { activeMenu: false }

  public render() {

    const { identity } = this.props
    const { activeMenu } = this.state

    const eosAccount = getEosAccount(identity)

    return (
      <nav className="navbar">
        <div className="navbar-brand">
          <div className="logo-small-img">
            <img alt="MonsterEOS" src="/images/ui/logo-small.png" />
          </div>
          <a
            role="button"
            className="navbar-burger"
            aria-label="menu"
            aria-expanded="false"
            onClick={() => this.setState({activeMenu: !activeMenu})}>
            <span aria-hidden="true" />
            <span aria-hidden="true" />
            <span aria-hidden="true" />
          </a>
        </div>
        <div className={`navbar-menu ${activeMenu ? "is-active" : ""}`}>
          <div className="navbar-end">
            {this.greetings(eosAccount)}
            {!eosAccount && this.homeButton()}
            {!eosAccount && this.scatterButton()}
            {eosAccount && this.myWalletButton()}
            {eosAccount && this.myMonstersButton()}
            {this.marketButton()}
            {this.arenasButton()}
            {this.rankButton()}
            {this.aboutButton()}
            {eosAccount && this.logoutButton()}
            {this.helpButton(activeMenu)}
          </div>
        </div>
      </nav>
    )
  }

  private greetings(eosAccount: string) {
    return eosAccount &&
      <p className="navbar-item greetings">
        Hello <span><b>{eosAccount}</b></span>!
      </p>
  }

  private helpButton(showText: boolean) {
    return showText ?
      (<Link className="navbar-item" to="/faq">
        <i className="fa fa-question-circle has-text-info" />
        Help
      </Link>) :
      (<Link className="navbar-item help-button" to="/faq">
        <span className="navbar-item icon is-small">
          <i className="fa fa-2x fa-question-circle has-text-info" />
        </span>
      </Link>)
  }

  private homeButton() {
    return (
      <Link className="navbar-item" to="/">
        Home
      </Link>
    )
  }

  private myMonstersButton() {
    return (
      <Link className="navbar-item" to="/my-monsters">
        <i className="fa fa-paw" />
        My Monsters
      </Link>
    )
  }

  private myWalletButton() {
    const { myWalletBalance } = this.props

    return (
      <div className="navbar-item">
        <div className="field is-grouped">
          <p className="control">
            <Link className="button is-primary" to="/my-wallet">
              <span className="icon"><i className="fa fa-suitcase" /></span>
              <span>{myWalletBalance}</span>
            </Link>
          </p>
        </div>
      </div>
    )
  }

  private marketButton() {
    return (
      <Link className="navbar-item" to="/market">
        <i className="fa fa-money" />
        Market
      </Link>
    )
  }

  private rankButton() {
    return (
      <Link className="navbar-item" to="/rank">
        <i className="fa fa-trophy" />
        Rank
      </Link>
    )
  }

  private arenasButton() {
    return (
      <Link className="navbar-item" to="/arenas">
        <i className="fa fa-legal" />
        Arenas
      </Link>
    )
  }

  private logoutButton() {
    const { dispatchDoLogout } = this.props

    return (
      <a className="navbar-item" onClick={dispatchDoLogout}>
        <i className="fa fa-sign-out" />
        Logout
      </a>
    )
  }

  private aboutButton() {
    return (
      <Link className="navbar-item" to="/about">
        About
      </Link>
    )
  }

  private scatterButton() {

    const { scatter, dispatchRequestScatterIdentity } = this.props

    return (
      scatter ?
      <a className="navbar-item" onClick={dispatchRequestScatterIdentity}>
        Enter with Scatter
      </a>
      : <a className="navbar-item" href={SCATTER_EXTENSION_LINK} target="_blank">
        Install Scatter Wallet
      </a>
    )
  }
}

const mapStateToProps = (state: State) => ({
  scatter: state.scatter,
  identity: state.identity,
  myWalletBalance: state.myWalletBalance,
})

const mapDispatchToProps = {
  dispatchDoLogout: doLogout,
  dispatchRequestScatterIdentity: requestScatterIdentity
}

export default connect(mapStateToProps, mapDispatchToProps)(TopMenu)