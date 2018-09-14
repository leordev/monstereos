import * as React from "react"

const Head = (props: any) => (
    <div className="head">
        <div className="head-player">
            <div className="info-player">
                <img className="menu-home" src="/images/icon/User_Icon.png" />
                <div className="info">
                    <p className="head-text">Hello</p>
                    <p className="head-text" style={{color:"#00ffea"}}>Player 750</p>
                </div>
            </div>
            <div className="eos-player" >
                <img className = "coin-eos" src="/images/icon/Coin_Icon.png"/>
                <div className="info-coin">
                    <p className="head-text-coin" style={{fontSize: "16px"}}>10,000</p>
                    <p className="head-text-eos" style={{color:"#00ffea"}}>EOS</p>
                </div>
            </div>
        </div>
    </div>
  )

  export default Head