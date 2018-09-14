import * as React from "react"

import { Monster3DProfile, ActionType } from "react-monstereos-profile"
import monster3D from "../../../assets/models/Devil.gltf"

const Battle = (props: any) => (
    <div>
        <img className="battleTemplate" src="/images/Battle/BattleTemplate.png" />
        <div className="battleCanvas">
            <Monster3DProfile
                typeId={554845454654474}
                action={ActionType.IDLE}
                path={monster3D}
                size={{ width: "auto", height: "250px" }}
                background={{ alpha: 0 }}
            />

            <Monster3DProfile
                typeId={554845454654475}
                action={ActionType.IDLE}
                path={monster3D}
                size={{ width: "200px", height: "200px" }}
                background={{ alpha: 0 }}
            />
        </div>
    </div>
    
  )

  export default Battle