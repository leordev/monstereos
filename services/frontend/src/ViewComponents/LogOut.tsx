import * as React from "react"
import { Button, Modal, ModalHeader, ModalBody, ModalFooter } from "reactstrap"

export default class LogOut extends React.Component<any, any> {
  constructor(props:any){
    super(props)
    this.state={
      modal: false
    }
  }

  public toggle = () => {
    this.setState({
      modal: !this.state.modal
    })
  }

  public render() {
    return (
      <React.Fragment>
        {/* <Button color="danger" onClick={this.toggle}>LogOut</Button> */}
        <Modal isOpen={this.state.modal} toggle={this.toggle} >
          <ModalHeader toggle={this.toggle}>Log Out</ModalHeader>
          <ModalBody>
            ARE YOU SURE YOU WANT YO LOG OUT?
            </ModalBody>
          <ModalFooter>
            <Button color="primary" onClick={this.toggle}>ACCEPT</Button>
            <Button color="secondary" onClick={this.toggle}>DECLINE</Button>
          </ModalFooter>
        </Modal>
      </React.Fragment>
    )
  }
}
