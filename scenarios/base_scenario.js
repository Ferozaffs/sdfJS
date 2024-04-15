import * as THREE from 'https://cdn.skypack.dev/three@0.136';

export class BaseScenario {
    constructor() {
    }

    async create(app) {
        app.camera.position.set(0, 1, -10);

        app.backgroundColor = new THREE.Vector3(1.0,1.0,1.0);

        const box = {
          Position: new THREE.Vector3( 0,0,0 ),
          Rotation: new THREE.Vector3( 0.0, 0.0, 0.0),
          Scale: new THREE.Vector3( 10000.0, 0.1, 10000.0 ),
          Color: new THREE.Vector3( 0.0, 0.1, 0.8 ),
        }
    
        const sphere = {
          Position: new THREE.Vector3( 2,0,0 ),
          Color: new THREE.Vector3( 0.8, 0.1, 0.1 ),
          Radius: 1.0
        };

        const torus = {
          Position: new THREE.Vector3( -2,0,0 ),
          Rotation: new THREE.Vector3( 90, 0, 0),
          Color: new THREE.Vector3( 0.1, 0.8, 0.1 ),
          InnerRadius: 0.5,
          OuterRadius: 1.0
        };

        app.boxes = this.boxes = [box]; 
        app.spheres = this.spheres = [sphere]; 
        app.toruses = this.toruses = [torus]
      }

    async update(app, time, deltaTime) {
        this.spheres[0].Position.y = Math.sin(time) + 1.0;

        this.toruses[0].Position.y = Math.cos(time) + 1.0;
        this.toruses[0].Rotation.x = time * 50.0;
        this.toruses[0].Rotation.z = time * 30.0;
      } 
}