import * as React from "react"
import { Switch } from "react-router-dom"

import TopBar from "./ViewComponents/TopBar"

class MonsterEOS extends React.Component<{}, {}> {
    public render() {
        return (
            <React.Fragment>
                <Switch>
                    <React.Fragment>
                        <TopBar />
                        {/* <Toaster />
                        <Route path="/" exact component={HomeScreen} />
                        <Route path="/arenas" exact component={ArenasScreen} />
                        <Route
                            path="/arenas/:host"
                            exact
                            component={BattleScreen}
                        />
                        <Route
                            path="/my-monsters"
                            exact
                            component={MyMonstersScreen}
                        />
                        <Route
                            path="/monster/:id"
                            component={MonsterDetailsScreen}
                        />
                        <Route path="/market" component={MarketScreen} />
                        <Route path="/rank" exact component={RankScreen} />
                        <Route path="/about" exact component={AboutScreen} />
                        <Route path="/faq" exact component={FaqScreen} />
                        <Footer /> */}
                    </React.Fragment>
                </Switch>
            </React.Fragment>
        )
    }
}

export default MonsterEOS
