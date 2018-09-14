import * as React from "react"

import { Monster3DProfile, ActionType } from "react-monstereos-profile"
import monster3D from "../../assets/models/Devil.gltf"

class Body extends React.Component<any, any> {
 

  public render() {
    return (
      <div className="monsters" style={{width:"100%"}}>
        {/* <img src="/images/icon/BackMonster.png" /> */}
        <div className="monster3DProfile">
          <Monster3DProfile
            typeId={554845454654474}
            action={ActionType.IDLE}
            path={monster3D}
            size={{ width: "250px", height: "250px" }}
            background={{ alpha: 0 }}
          />
        </div>
        <div className="stats">
          <div className="monsterName">
            <div>
              <p>Name </p>
              <p>Alive for 3 day</p>
            </div>
            <img src="/images/icon/N1.png" />
          </div>
          <div>
            <img src="/images/icon/HP.png" />
          </div>
          <div className="monsterName">
            <div>
              <img src="/images/icon/Food.png" />
              <img src="/images/icon/Energy.png" />
            </div>
            <div>
              <img src="/images/icon/Happiness.png" />
              <img src="/images/icon/Clean.png" />
            </div>
          </div>
        </div>
      </div>
    )
  }
}

export default Body
