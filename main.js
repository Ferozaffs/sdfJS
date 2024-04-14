import * as THREE from 'https://cdn.skypack.dev/three@0.136';
import {OrbitControls} from 'https://cdn.skypack.dev/three@0.136/examples/jsm/controls/OrbitControls.js';

import * as BS from './scenarios/base_scenario.js';

const MAX_SDF = 50;

class SDFJS {
  constructor() {
  }

  async initialize() {
    this.renderer = new THREE.WebGLRenderer();
    document.body.appendChild(this.renderer.domElement);

    window.addEventListener('resize', () => {
      this.onWindowResize();
    }, false);

    this.scene = new THREE.Scene();
    
    this.camera = new THREE.PerspectiveCamera(60, 1920.0 / 1080.0, 0.1, 2000.0);
    this.scene.add(this.camera);

    const controls = new OrbitControls(this.camera, this.renderer.domElement);
    controls.target.set(0, 1, 0);
    controls.update();

    this.scenario = new BS.BaseScenario();
    await this.scenario.create(this)

    await this.setupShader();
    this.onWindowResize();

    this.totalTime = 0.0;
    this.previousRAF = null;
    this.raf();
  }

  async setupShader() {
      const vsh = await fetch('./shaders/sdf_vs.glsl');
      const fsh = await fetch('./shaders/sdf_ps.glsl');
  
      const dummySphere = {
        Position: new THREE.Vector3( 0, 0, 0 ),
        Color: new THREE.Vector3( 0, 0, 0 ),
        Radius: 0.0
      };
      const dummyTorus = {
        Position: new THREE.Vector3( 0, 0, 0 ),
        Rotation: new THREE.Vector3( 0, 0, 0 ),
        Color: new THREE.Vector3( 0, 0, 0 ),
        InnerRadius: 0.0,
        OuterRadius: 0.0
      };
      const dummyBox = {
        Position: new THREE.Vector3( 0, 0, 0 ),
        Rotation: new THREE.Vector3( 0, 0, 0 ),
        Scale: new THREE.Vector3( 0, 0, 0 ),
        Color: new THREE.Vector3( 0, 0, 0 )
      };
      var shaderSpheres = this.fillRemainder(this.spheres, dummySphere, MAX_SDF);
      var shaderToruses = this.fillRemainder(this.toruses, dummyTorus, MAX_SDF);
      var shaderBoxes = this.fillRemainder(this.boxes, dummyBox, MAX_SDF);

      const material = new THREE.ShaderMaterial({
        vertexShader: await vsh.text(),
        fragmentShader: await fsh.text(),
        uniforms: {     
          uNumSpheres: { value: this.spheres.length },
          uSpheres: { value: shaderSpheres },
          uNumToruses: { value: this.toruses.length },
          uToruses: { value: shaderToruses},
          uNumBoxes: { value: this.boxes.length },
          uBoxes: { value: shaderBoxes},
          uBackgroundColor: { value: this.backgroundColor },
        },
      });
  
      this.sdfMaterial = material;
  
      var geometry = new THREE.PlaneGeometry(2, 2);
      this.sdfQuad = new THREE.Mesh(geometry, material);
      this.sdfQuad.position.z = -1;
  
      this.camera.add(this.sdfQuad); 
  }

  fillRemainder(array, value, length) {
    const remainder = length - array.length;
    return array.concat(new Array(remainder).fill(value));
  }

  onWindowResize() {
    this.camera.aspect = window.innerWidth / window.innerHeight;
    this.camera.updateProjectionMatrix();

    this.renderer.setSize(window.innerWidth, window.innerHeight);
  }

  raf() {
    requestAnimationFrame((t) => {
      if (this.previousRAF === null) {
        this.previousRAF = t;
      }

      this.step(t - this.previousRAF);
      this.renderer.render(this.scene, this.camera);
      this.raf();
      this.previousRAF = t;
    });
  }

  step(timeElapsed) {
    const secondsElapsed = timeElapsed * 0.001;
    this.totalTime += secondsElapsed;

    this.sdfQuad.lookAt(this.camera.position);

    this.scenario.update(this, this.totalTime);
  }
}


let APP = null;

window.addEventListener('DOMContentLoaded', async () => {
  APP = new SDFJS();
  await APP.initialize();
});
