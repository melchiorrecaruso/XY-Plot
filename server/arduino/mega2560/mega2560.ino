// XY-Plotter Server for Arduino Mega 2560

// Author: Melchiorre Caruso
// Date:   21 Mar 2021

// Serial data format

// bit0 -> increase internal main-loop time
// bit1 -> decrease internal main-loop time
// bit2 -> x-motor stp (avr register PORTE4)
// bit3 -> y-motor stp (avr register PORTE5)
// bit4 -> z-motor stp (avr register PORTG5)
// bit5 -> x-motor dir (avr register PORTE3)
// bit6 -> y-motor dir (avr register PORTH3)
// bit7 -> z-motor dir (avr register PORTH4)

#include <math.h>

uint8_t Bits = 0; 
uint8_t Buffer[255];
uint8_t BufferIndex = 0;
uint8_t BufferSize = 0;

uint32_t LoopStart = micros();
uint32_t LoopNow   = 0;
uint32_t LoopDelay = 440;

#define  RampLen 250
uint16_t Ramps[RampLen];
uint32_t RampKB = 40000;
uint16_t RampIndex = 0;

void setup() {
  // init serial
  Serial.begin(115200); 
  while (Serial.available() > 0) { Serial.read(); } 
  // init ramps
  for (uint16_t i = 0; i < RampLen; i++) { 
    Ramps[i] = round(RampKB*(sqrt(i+2)-sqrt(i+1)));
  }
  // disable stepper motors
  DDRH |= B00100000;
  PORTH |= B00100000; 
  // init stepper X/Y/Z
  DDRE |= B00111000;
  DDRG |= B00100000;
  DDRH |= B00011000;
  // enable stepper motors   
  PORTH &= B11011111;
}

void loop() {

  LoopNow = micros();
  if ((unsigned long)(LoopNow - LoopStart) >= LoopDelay) {

    // SET X-DIR, Y-DIR and Z-DIR PIN,   
    PORTE = (PORTE & B11110111) | ((Bits & B00100000) >> 2); 
    PORTH = (PORTH & B11100111) | ((Bits & B11000000) >> 3);             
    // SET HIGH X-STEP, Y-STEP and Z-STEP PIN
    PORTE = (PORTE & B11001111) | ((Bits & B00000011) << 4);
    PORTG = (PORTG & B11011111) | ((Bits & B00000100) << 3);
    // SET LOW X-STEP, Y-STEP and Z-STEP PIN
    PORTE = (PORTE & B11001111);
    PORTG = (PORTG & B11011111);
                   
    if (Bits & B00000001) {        
      if (RampIndex < RampLen-1) { RampIndex++; }    
    }     
    if (Bits & B00000010) {        
      if (RampIndex > 0) { RampIndex--; } 
    }
    
    if (BufferIndex < BufferSize) {
      Bits = Buffer[BufferIndex];
      BufferIndex++;             
    } else { 
      Bits = 0; 
    }    
    LoopStart = LoopNow;
    LoopDelay = Ramps[RampIndex];   
  }  

  if (BufferIndex == BufferSize) {         
    BufferIndex = 0;  
    BufferSize  = Serial.available();   
    if (BufferSize > 0) {                                 
      Serial.readBytes(Buffer, BufferSize);
      Serial.write(BufferSize);   
    }            
  }
}
