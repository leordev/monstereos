/**
 * ideal configuration for every monster 3D model.
 */
export default (type: number) => {
    switch (type) {
        case 0:
            return {
                position: { y: -50 },
                rotation: { y: Math.PI },
                cameraPosition: { z: -30 }
            }
        case 1:
            return {
                position: { y: -20 },
                rotation: {},
                cameraPosition: { z: -120 }
            }
        default:
            return {}
    }
}