import * as React from "react"
import * as moment from "moment"
import { MonsterProps, monsterImageSrc } from "../monsters/monsters"
import { Query } from "react-apollo"
import gql from "graphql-tag"

export interface Message {
    monster:MonsterProps,
    message:string
}


const MessageCard = (props:any) => {      
    const sinceText = moment.parseZone(props.message.createdAt).fromNow()
    const url = "https://2d.monstereos.io" + monsterImageSrc(props.message.petByPetId.typeId)
    const trxLink = "https://bloks.io/transaction/" + props.message.createdTrx
    return(
    <div key={props.message.id}>
       <img src={url} width="48px" height="48px"/><br/>
       <em>{props.message.message}</em><br/>              
       {props.message.petByPetId.petName} owned by {props.message.petByPetId.owner}<br/>       
       sent by {props.message.createdEosacc} <a href={trxLink}>{sinceText}</a>
    </div>
    )
}


export const QUERY_MESSAGES = gql`
query LatestMessages($limit: Int!, $offset: Int!) {
  allMessages(
    first: $limit,
    offset: $offset,
    orderBy: ID_DESC,
  ) {
    edges {
      node { 
        id       
        message 
        createdAt
        createdTrx
        createdEosacc
        petByPetId {
            petName
            typeId
            owner
        }
      }
    }
  }
}
`

interface Props {
    requiresMsgUpdate:boolean
}

class MessageBoard extends React.Component<Props, {}> {

    public render() {
        const {requiresMsgUpdate} = this.props
        const variables = {
            limit: 3,
            offset: 0
          }

        return <div className="container">
            <Query query={QUERY_MESSAGES} variables={variables}>
                {({error, data, loading, refetch}) => {
                    if (requiresMsgUpdate) {
                        // tslint:disable-next-line:no-console
                        console.log("refetching")
                        setTimeout(()=>refetch(variables), 500)
                    }
                    if (error) {
                        return (<span>{error.toString()} {JSON.stringify(error)}</span>)
                    }    
                    if (loading || !data || !data.allMessages) {
                        return <span>
                        <i className="fa fa-spin fa-spinner" /> Loading... Our servers are Syncing with the Chain
                        </span>
                    }
                    const messages = data.allMessages.edges                
                    
                    return <div>
                        {messages.map(({node}:any, index:number) => {                        
                            return(
                        <MessageCard 
                            key = {node.id}                    
                            message = {node}                        
                            />
                        )})}
                        </div>
                }
            }
            </Query>
        </div>
    }
}  

export default MessageBoard