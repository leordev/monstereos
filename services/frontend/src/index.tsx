import * as React from "react"
import * as ReactDOM from "react-dom"
import { Provider } from "react-redux"
import { BrowserRouter } from "react-router-dom"
import { ApolloClient } from "apollo-client"
import { HttpLink } from "apollo-link-http"
import { InMemoryCache } from "apollo-cache-inmemory"
import { ApolloProvider } from "react-apollo"
import "bootstrap/dist/css/bootstrap.min.css"
import store from "./store"
import loadScatter from "./utils/scatter"
// import App from "./App"
import MonsterEOS from "./Game"
import registerServiceWorker from "./registerServiceWorker"
import { loadGlobalConfig } from "./utils/eos"
import LogOut from "./ViewComponents/LogOut"
const httpLink = new HttpLink({
    uri:
        process.env.REACT_APP_GRAPHQL_ENDPOINT ||
        "http://localhost:3030/graphql"
})

const client = new ApolloClient({
    link: httpLink,
    cache: new InMemoryCache()
})

ReactDOM.render(
    <ApolloProvider client={client}>
        <Provider store={store}>
            <React.Fragment>
                <LogOut />
                <BrowserRouter>
                    <MonsterEOS />
                </BrowserRouter>
            </React.Fragment>
        </Provider>
    </ApolloProvider>,
    document.getElementById("root") as HTMLElement
)

// some global inits
loadScatter(store)
loadGlobalConfig(store)

// service worker
registerServiceWorker()
