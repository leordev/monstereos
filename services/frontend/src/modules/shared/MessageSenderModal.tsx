import * as React from "react"
import { MonsterProps } from "../monsters/monsters"
import { State, NOTIFICATION_ERROR, NOTIFICATION_SUCCESS, pushNotification } from "../../store"
import { connect } from "react-redux"
import Modal from "./Modal"
import { trxMessageFrom } from "../../utils/eos"


interface Props {
    scatter: any,
    closeModal: (msgSent:boolean) => void,
    dispatchPushNotification: any,
    myMonsters: MonsterProps[]
}


interface ReactState {
    message:string,
    monster:MonsterProps | undefined,
    validMessage: boolean
}

class MessageSenderModal extends React.Component<Props, ReactState> {

    public state: ReactState = {
      message: "",
      monster: undefined,
      validMessage: false
    }

    public render() {
        const { closeModal, myMonsters } = this.props
        const { message, monster } = this.state
        
        const footerButtons = [
            <a
              key="cancel"
              className="button is-danger"
              onClick={() => closeModal(false)}>
              Cancel
            </a>,
            <a
              key="submit"
              className="button"
              onClick={this.sendMessage}>
              Send Message
            </a>
          ]

        return (
            <Modal
                title="Send a message to the world"
                close={() => closeModal(false)}
                footerButtons={footerButtons}>
                <p className="has-text-info"><small><em>Please follow the EOS constitution when you post a message to the public. It will be there for ever!</em></small></p>
                <div className="field">
                    <label className="label">Monster</label>
                    <div className="control has-icons-left">
                    <div className="select is-fullwidth">
                        <select
                        className="is-large"
                        onChange={this.handleChangeMonster}
                        value={monster ? monster.id : ""}>
                        <option value="">Please select the Monster that has something to say</option>
                        {myMonsters.map((opt) =>
                            <option
                            key={opt.id}
                            value={opt.id}>{opt.name} (#{opt.id})</option>
                        )}
                        </select>
                    </div>
                    <span className="icon is-left"><i className="fa fa-paw" /></span>
                    </div>
                </div>
                <div className="field">
                    <div className="control">
                        <input
                        className="input is-large"
                        placeholder="I am so happy to have been fed."
                        type="textArea"
                        onChange={this.handleMessageChange}
                        value={message} />
                    </div>
                </div>
            </Modal>
        )
    }

    private handleChangeMonster = (event: any) => {
        const {myMonsters} = this.props
        const monster = myMonsters.find((m) => m.id === Number(event.target.value))
        if (monster) {
            this.setState({monster})
        }
    }

    private handleMessageChange = (event: any) => {
        const message = event.target.value
        const validMessage = message.length <= 255    
        this.setState({validMessage, message})        
    }

    private sendMessage = () => {
        const { scatter, closeModal, dispatchPushNotification } = this.props
        const { validMessage, monster, message } = this.state

        if (!monster) {
            return dispatchPushNotification(`Monster is required to send a message`, NOTIFICATION_ERROR)
        }
        
        if (monster && !validMessage) {
            return dispatchPushNotification(`Message more than 255 characters`, NOTIFICATION_ERROR)
        }
    
        trxMessageFrom(scatter, monster!!.id, message)
          .then((res: any) => {
            console.info(`Message from ${monster!!.id} was successfully sent`, res)
            dispatchPushNotification(`Message from ${monster!!.name} was successfully sent`, NOTIFICATION_SUCCESS)
            closeModal(true)
          }).catch((err: any) => {
            dispatchPushNotification(`Fail to send message from ${monster!!.name}: ${err.eosError}`, NOTIFICATION_ERROR)
          })
      }
}

const mapStateToProps = (state: State) => {
    return {
        scatter: state.scatter,
        myMonsters: state.myMonsters
    }
}
  
const mapDispatchToProps = {
    dispatchPushNotification: pushNotification
}

export default connect(mapStateToProps, mapDispatchToProps)(MessageSenderModal)