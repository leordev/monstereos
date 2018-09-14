import * as React from "react"
import { Switch, Route } from "react-router-dom"
import Head from "./modules/interface/Head"
import Home from "./ViewComponents/Home"
import Arena from "./ViewComponents/Arena"
import About from "./ViewComponents/About"
import TopRank from "./ViewComponents/TopRank"
import Footer from "./modules/interface/Footer"
import "./styles/home.css"
class MonsterEOS extends React.Component<{}, {}> {
    public render() {
        return (
            <React.Fragment>
                <Switch>
                    <div id="iPhoneFrame" style={{height:"100vh", maxHeight:"812px",width:"375px", minHeight: "100vh"}}>
                    <div style={{height: "100vh", width: "100%", paddingTop: "10px" , marginLeft: "5%"}}>
                        <Head />
                        <Route path="/" exact component={Home} />
                        <Route path="/arenas" exact component={Arena} />
                        {/* <Route
                            path="/arenas/:host"
                            exact
                            component={BattleScreen}
                        /> */}
                        {/* <Route
                            path="/my-monsters"
                            exact
                            component={MyMonsters}
                        />
                        <Route
                            path="/monster/:id"
                            component={MonsterDetailsScreen}
                        />
                        <Route path="/market" component={MarketScreen} />*/}
                        <Route path="/rank" exact component={TopRank} /> 
                        <Route path="/about" exact component={About} />
                        {/* <Route path="/faq" exact component={FaqScreen} />*/}
                        <Footer />  
                        </div>
                    </div>
                </Switch>
            </React.Fragment>
        )
    }
}

export default MonsterEOS
