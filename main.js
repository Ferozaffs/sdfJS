import * as THREE from 'https://cdn.skypack.dev/three@0.136';

import {OrbitControls} from 'https://cdn.skypack.dev/three@0.136/examples/jsm/controls/OrbitControls.js';

class SDFJS {
  constructor() {
  }

  async initialize() {
    this.renderer_ = new THREE.WebGLRenderer({ antialias: true });
    document.body.appendChild(this.renderer_.domElement);

    window.addEventListener('resize', () => {
      this.onWindowResize_();
    }, false);

    this.scene_ = new THREE.Scene();

    this.camera_ = new THREE.PerspectiveCamera(60, 1920.0 / 1080.0, 0.1, 2000.0);
    this.camera_.position.set(0, 0, -10);

    const controls = new OrbitControls(this.camera_, this.renderer_.domElement);
    controls.target.set(0, 1, 0);
    controls.update();

    await this.createSDFQuad();

    this.onWindowResize_();

    this.totalTime_ = 0.0;
    this.previousRAF_ = null;
    this.raf_();
  }

  async createSDFQuad() {
    const vsh = await fetch('./shaders/sdf_vs.glsl');
    const fsh = await fetch('./shaders/sdf_ps.glsl');

    const sphere1 = {
      Position: new THREE.Vector3( 0,0,0 ),
      Color: new THREE.Vector3( 1, 0, 0 ),
      Radius: 1.0
    };

    const sphere2 = {
      Position: new THREE.Vector3( 2,0,0 ),
      Color: new THREE.Vector3( 0, 1, 0 ),
      Radius: 1.0
    };

    const sphere3 = {
      Position: new THREE.Vector3( 1,2,0 ),
      Color: new THREE.Vector3( 0, 0, 1 ),
      Radius: 1.0
    };

    const material = new THREE.ShaderMaterial({
      vertexShader: await vsh.text(),
      fragmentShader: await fsh.text(),
      uniforms: {
        uNumSpheres: { value: 3 },
        //uNumToruses: { value: 0 },
        uSpheres: { 
          value: [sphere1, sphere2, sphere3] 
        },
        uBackgroundColor: { value: new THREE.Vector3( 0.1, 0.1, 0.1 ) },
      },

      transparent: true
    });

    this.sdfMaterial_ = material;

    var geometry = new THREE.PlaneGeometry(2, 2);
    this.sdfQuad_ = new THREE.Mesh(geometry, material);
    this.sdfQuad_.position.z = -1;

    this.camera_.add(this.sdfQuad_); 
    this.scene_.add(this.camera_);
  }

  onWindowResize_() {
    this.camera_.aspect = window.innerWidth / window.innerHeight;
    this.camera_.updateProjectionMatrix();

    this.renderer_.setSize(window.innerWidth, window.innerHeight);
  }

  raf_() {
    requestAnimationFrame((t) => {
      if (this.previousRAF_ === null) {
        this.previousRAF_ = t;
      }

      this.step_(t - this.previousRAF_);
      this.renderer_.render(this.scene_, this.camera_);
      this.raf_();
      this.previousRAF_ = t;
    });
  }

  step_(timeElapsed) {
    const secondsElapsed = timeElapsed * 0.001;
    this.totalTime_ += secondsElapsed;

    this.sdfQuad_.lookAt(this.camera_.position);
  }
}


let APP_ = null;

window.addEventListener('DOMContentLoaded', async () => {
  APP_ = new SDFJS();
  await APP_.initialize();
});
