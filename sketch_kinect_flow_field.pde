import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;

import org.openkinect.freenect.*;
import org.openkinect.freenect2.*;
import org.openkinect.processing.*;
import org.openkinect.tests.*;

FlowField           flowField;
ArrayList<Particle> particles; 
float               particlesIncrement = 8;
float               particleSpacing = 2;

float zTranslate = 0;
float wPadding;

AudioPlayer song;
Minim       minim;
BeatDetect  beat;
Kinect2     kinect2;

void setup() {
  fullScreen(P3D, 2);
  background(20);
  flowField = new FlowField(15);
  particles = new ArrayList<Particle>();

  wPadding = 0;

  kinect2 = new Kinect2(this);
  kinect2.initDepth();
  kinect2.initDevice();
  
  minim = new Minim(this);
  song  = minim.loadFile("gone_too_soon.mp3", 1024);
  beat  = new BeatDetect();
  song.play();

}

void draw() {   
  fill(20, 50);
  rect(0, 0, width, height);
  translate(
    wPadding, 
    0, 
    zTranslate
  );
  
  flowField.updateField();
  
  int[] depth = kinect2.getRawDepth();
  
  for (int x = 0; x < kinect2.depthWidth; x += particlesIncrement) {
    for (int y = 0; y < kinect2.depthHeight; y += particlesIncrement) {
      int offset = x + y * kinect2.depthWidth;
      int z = depth[offset];
      //println(z);
      // number compared to z needs to get bigger if we want to capture things at a further distance
      if (z > 1800 || z == 0) {
        continue;
      }
      if ( x < 50) {
        continue;
      }
      Particle particle = new Particle(
        x * particleSpacing, 
        y * particleSpacing
      );
      particles.add(particle);
    }
  } 
  
  
  beat.detect(song.mix);
  
  for (int i = 0; i < particles.size(); i++) {
    if (beat.isOnset()) {
      //particles.get(i).changeColor();
    }
    particles.get(i).update();
    particles.get(i).render();
    if (particles.get(i).age > particles.get(i).lifeSpan) {
      particles.remove(i);
    }
  }
}


class Particle {
  PVector location;
  PVector velocity;
  
  float speed;
  float lifeSpan;
  float age;
  
  float r;
  float g;
  float b;
  
  Particle (float x, float y) {
    location = new PVector(x, y);
    velocity = new PVector(0, 0);
    r = 0;
    g = random(255);
    b = random(255);
    
    lifeSpan = random(3, 15);
    speed    = random(2, 4);
  }
  
  //void changeColor() {
  //  //r = random(0);
  //  //if (r == 0) {
  //  //  r = random(10, 255);
  //  //  g = 0;
  //  //  b = 0;
  //  //} else {
  //  //  g = random(255);
  //  //  r = 0;
  //  //  b = random(255);
  //  //}
  
  //}
  
  void update() {
    // get current velocity
    velocity = flowField.lookupVelocity(location);
    velocity.mult(speed);
    location.add(velocity);
    age++;
  }
  
  void render() {
    fill(r, g, b, 80);
    noStroke();
    ellipse(location.x, location.y, 2, 2);
  }
}

class FlowField {
   PVector[][] grid;
   int   cols, rows;
   int   resolution;
   float zNoise = 0.0;
   
   FlowField (int res) {
     resolution = res;
     rows = height/resolution;
     cols = width/ resolution;
     grid = new PVector[cols][rows];
   }
   
   void updateField() {
     float xNoise = 0;
     for (int i = 0; i < cols; i++) {
       float yNoise = 0;
       for (int j = 0; j < rows; j++) {
         // TODO: play around with angles to make it prettier?
         //float angle = radians((noise(xNoise, yNoise, zNoise)) *700) + noise(frameCount);
         //sin(noise(xNoise, yNoise, zNoise) * frameCount) * cos(noise(xOff, yOff, zOff));
         //map(noise(xNoise, yNoise, zNoise), 0, 1, 0, radians(360));
         //float angle = radians((noise(xNoise, yNoise, zNoise)) *700);
         float angle = radians(noise(xNoise, yNoise, zNoise) * 700);
         grid[i][j] = PVector.fromAngle(angle);
         yNoise += 0.1;
       }
       xNoise += 0.1;
     }
     zNoise += 0.04;
   
   }
  
  PVector lookupVelocity(PVector particleLocation) {
    int column = int(
      constrain(
        particleLocation.x / resolution, 
        0, 
        cols - 1)
      );
    int row = int(
      constrain(
        particleLocation.y / resolution, 
        0, 
        rows - 1)
       );
    return grid[column][row].copy();
  }
}