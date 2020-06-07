//  XY-Plotter Server for Arduino Uno R3 board

//  Author:   Melchiorre Caruso
//  Date:     20 November 2019
//  Modified: 06 June     2020

// Specifica protocollo seriale:

// bit0 -> x-stepper tick
// bit1 -> x-stepper CCW dir (-1)
// bit2 -> y-stepper tick
// bit3 -> y-stepper CCW dir (-1)
// bit4 -> z-stepper tick
// bit5 -> z-stepper CCW dir (-1)
// bit6 -> decrease internal main-loop time**
// bit7 -> increase internal main-loop time**
// **if both bit6 and bit7 are set, the ExecInternal 
//   routine is called instead of others Exe routines.

//  Librerie utilizzate nel codice sorgente

#include <math.h>
#include <Servo.h>

// definizione PIN shield CNC V3

#define MOTOR_ONOFF_PIN   8

#define MOTOR_X_STEP_PIN  2
#define MOTOR_X_DIR_PIN   5
#define MOTOR_Y_STEP_PIN  3
#define MOTOR_Y_DIR_PIN   6
#define MOTOR_Z_PIN       11

// definizione costanti protocollo seriale 

#define NOP               255
#define RST               254

#define GETXCOUNT         240
#define GETYCOUNT         241
#define GETZCOUNT         242
#define GETKB             243
#define GETKI             244

#define SETXCOUNT         230
#define SETYCOUNT         231
#define SETZCOUNT         232
#define SETKB             233
#define SETKI             234

#define MOVX              220
#define MOVY              221
#define MOVZ              222

// definizione variabili principali

static byte Buffer[128];
static long BufferIndex;
static long BufferSize;
static unsigned long LoopStart;
static unsigned long LoopDelay;
static long RampKB;
static long RampKI;
static long RampIndex;
static long xCount;
static long yCount;
static long zCount;
static long zDelay;

Servo motorZ;

union {
  byte asbytes[4];
  long aslong;
} data;

// Motor xy & z routines

void ExecRamp(byte bt) {  
  if (bitRead(bt, 6) == 1) { RampIndex++; }
  if (bitRead(bt, 7) == 1) { RampIndex--; }
  RampIndex = max(RampKI, RampIndex);
}

void ExecServo(byte bt) {
  long dz = bitRead(bt, 4);
  if (bitRead(bt, 5) == 1) { dz *= -1; }
 
  zCount += dz;
  if (dz != 0) {
    motorZ.write(zCount);
    delay(zDelay);
  }
}

void ExecStepper(byte bt) {
  long dx = bitRead(bt, 0);
  long dy = bitRead(bt, 2);
  if (bitRead(bt, 1) == 1) { dx *= -1; }
  if (bitRead(bt, 3) == 1) { dy *= -1; }

  xCount += dx;
  if (dx < 0) {
    digitalWrite(MOTOR_X_DIR_PIN, HIGH);
  } else {
    digitalWrite(MOTOR_X_DIR_PIN, LOW );
  }

  yCount += dy;
  if (dy < 0) {
    digitalWrite(MOTOR_Y_DIR_PIN, LOW );
  } else {
    digitalWrite(MOTOR_Y_DIR_PIN, HIGH);
  }

  if ((dx != 0) || (dy != 0)) {
    if (dx != 0) { digitalWrite(MOTOR_X_STEP_PIN, HIGH); }
    if (dy != 0) { digitalWrite(MOTOR_Y_STEP_PIN, HIGH); }
    delayMicroseconds(20);

    if (dx != 0) { digitalWrite(MOTOR_X_STEP_PIN, LOW ); }
    if (dy != 0) { digitalWrite(MOTOR_Y_STEP_PIN, LOW ); }
  }
}

void ExecInternal(byte bt) {
  switch (bt) {
    case SETXCOUNT:
      Serial.readBytes(data.asbytes, 4);
      Serial.write(SETXCOUNT);
      xCount = data.aslong;
      break;
    case SETYCOUNT:
      Serial.readBytes(data.asbytes, 4);
      Serial.write(SETYCOUNT);
      yCount = data.aslong;
      break;
    case SETZCOUNT:
      Serial.readBytes(data.asbytes, 4);
      Serial.write(SETZCOUNT);
      zCount = data.aslong;
      break; 
    case SETKB:
      Serial.readBytes(data.asbytes, 4);
      Serial.write(SETKB);
      RampKB = data.aslong;
      break;  
    case SETKI:
      Serial.readBytes(data.asbytes, 4);
      Serial.write(SETKI);
      RampKI = max(1, data.aslong);
      break;    
                 
    case GETXCOUNT:
      data.aslong = xCount;
      Serial.write(GETXCOUNT);
      Serial.write(data.asbytes, 4);
      break;
    case GETYCOUNT:
      data.aslong = yCount;
      Serial.write(GETYCOUNT);
      Serial.write(data.asbytes, 4);
      break;
    case GETZCOUNT:
      data.aslong = zCount;
      Serial.write(GETZCOUNT);
      Serial.write(data.asbytes, 4);
      break;
    case GETKB:
      data.aslong = RampKB;
      Serial.write(GETKB);
      Serial.write(data.asbytes, 4);
      break;  
    case GETKI:
      data.aslong = RampKI;
      Serial.write(GETKI);
      Serial.write(data.asbytes, 4);
      break; 
      
    case MOVX:
      Serial.readBytes(data.asbytes, 4);
      Serial.write(MOVX);   
      // not implemented
      break;
    case MOVY:
      Serial.readBytes(data.asbytes, 4);
      Serial.write(MOVY);
      // not implemented
      break;      
    case MOVZ:
      Serial.readBytes(data.asbytes, 4);
      Serial.write(MOVZ);
      zCount = data.aslong;
      motorZ.write(zCount);
      break;
      
    case RST:
      Serial.write(RST);   
      RampIndex = RampKI;
      break;
    case NOP:
      Serial.write(NOP);   
      break;
    default:
      Serial.write(bt);
      break;      
  }
}

// Setup routine

void setup() {
  // init serial
  Serial.begin(115200);
  Serial.setTimeout(1000);
  // clear serial
  while (Serial.available() > 0) {
    Serial.read();
    delay(50);
  }  
  // init stepper X/Y
  pinMode(MOTOR_X_STEP_PIN, OUTPUT);
  pinMode(MOTOR_Y_STEP_PIN, OUTPUT);
  pinMode(MOTOR_X_DIR_PIN,  OUTPUT);
  pinMode(MOTOR_Y_DIR_PIN,  OUTPUT);
  pinMode(MOTOR_ONOFF_PIN,  OUTPUT);
  // enable steppers
  digitalWrite(MOTOR_ONOFF_PIN, LOW);  
  // init servo Z
  motorZ.attach(MOTOR_Z_PIN);
  // init variables
  BufferIndex = 0;
  BufferSize = 0;
  LoopStart = micros();
  LoopDelay = 400;
  RampIndex = 1;
  RampKB = 40000;
  RampKI = 1;
  xCount = 0;
  yCount = 0;
  zCount = motorZ.read();
  zDelay = 4;  
}

// Main Loop

void loop() {
  if ((unsigned long)(micros() - LoopStart) >= LoopDelay) {
    LoopStart = micros();
    if (BufferIndex == BufferSize) {
      BufferIndex = 0;
      BufferSize = Serial.available();
      if (BufferSize > 0) {
        Serial.readBytes(Buffer, BufferSize);
        Serial.write(BufferSize);
      }
    }

    if (BufferIndex < BufferSize) {
      byte bt = Buffer[BufferIndex];
      if (bt < B11000000) {
        ExecRamp(bt);
        ExecServo(bt);
        ExecStepper(bt);
      } else {
        ExecInternal(bt);
      }
      BufferIndex++;          
    }   
    LoopDelay = round(RampKB*(sqrt(RampIndex+1)-sqrt(RampIndex)));
  }
}
