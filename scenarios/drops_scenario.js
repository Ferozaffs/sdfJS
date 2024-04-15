import * as THREE from 'https://cdn.skypack.dev/three@0.136';

export class DropsScenario {
    constructor() {
    }

    async create(app) {
        app.camera.position.set(0, 1, -40);

        app.backgroundColor = new THREE.Vector3(1.0,1.0,1.0);

        const boxTop = {
          Position: new THREE.Vector3( 0,20,0 ),
          Rotation: new THREE.Vector3( 0.0, 0.0, 0.0),
          Scale: new THREE.Vector3( 1000.0, 2.0, 1000.0 ),
          Color: new THREE.Vector3( 1.0,1.0,1.0 ),
        }
    
        const boxBottom = {
          Position: new THREE.Vector3( 0,-20,0 ),
          Rotation: new THREE.Vector3( 0.0, 0.0, 0.0),
          Scale: new THREE.Vector3( 1000.0, 2.0, 1000.0 ),
          Color: new THREE.Vector3( 1.0,1.0,1.0 ),
        }

        const sphere = {
          Position: new THREE.Vector3( 0,0,0 ),
          Color: new THREE.Vector3( 0.0, 0.0, 0.0 ),
          Radius: 1.0
        };

        this.spheres = [];
        for (let index = 0; index < 10; index++) {
            this.spheres[index] = structuredClone(sphere);
            this.spheres[index].Position.y = 20.0 - Math.random() * 40.0;
            this.spheres[index].Position.x = 15.0 - Math.random() * 30.0;
            this.spheres[index].Position.z = 15.0 - Math.random() * 30.0;
            this.spheres[index].Radius = 1.0 + Math.random() * 2.0;
          }

        console.log(this.spheres);

        app.spheres = this.spheres;
        app.boxes = this.boxes = [boxTop, boxBottom]; 
        app.toruses = []; 
      }

    async update(app, time, deltaTime) {
        this.spheres.forEach(element => {
          if (element.Position.y < -20.0)
          {
            element.Position.y = 20.0
            element.Position.x = 10.0 - Math.random() * 20.0;
            element.Position.z = 10.0 - Math.random() * 20.0;
          }
          else
          {
            element.Position.y -= (5.0 - element.Radius) * deltaTime;
          }
        });
      } 
}