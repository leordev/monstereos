import * as React from "react"
import { Switch, Route } from "react-router-dom"

import TopBar from "./ViewComponents/TopBar"
import Home from "./ViewComponents/Home"
import Arena from "./ViewComponents/Arena"
import About from "./ViewComponents/About"
import TopRank from "./ViewComponents/TopRank"
class MonsterEOS extends React.Component<{}, {}> {
    public render() {
        return (
            <React.Fragment>
                <Switch>
                    <div id="iPhoneFrame" style={{height:"812px",width:"375px", backgroundColor:"#000"}}>

                        <TopBar />
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
                        {/* <Route path="/faq" exact component={FaqScreen} />
                        <Footer />  */}
                    </div>
                </Switch>
            </React.Fragment>
        )
    }
}

export default MonsterEOS
