// XY-Plotter Server for Arduino Uno

// Author: Melchiorre Caruso
// Date:   27 Mar 2021

// Serial data format

// bit0 -> decrease internal main-loop time
// bit1 -> increase internal main-loop time
// bit2 -> x-motor stp (avr register PORTD2)
// bit3 -> y-motor stp (avr register PORTD3)
// bit4 -> z-motor stp (avr register PORTD4)
// bit5 -> x-motor dir (avr register PORTD5)
// bit6 -> y-motor dir (avr register PORTD6)
// bit7 -> z-motor dir (avr register PORTD7)

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
  DDRB |= B00000001; 
  PORTB |= B00000001; 
  // init stepper X/Y/Z
  DDRD |= B11111100;
  // enable stepper motors   
  PORTB &= B11111110;
}

void loop() {

  LoopNow = micros();
  if ((unsigned long)(LoopNow - LoopStart) >= LoopDelay) {
    // SET X-DIR, Y-DIR and Z-DIR PIN,   
    // SET LOW X-STEP, Y-STEP and Z-STEP PIN
    PORTD = (PORTD & B00000011) | (Bits & B11100000);             
    // SET HIGH X-STEP, Y-STEP and Z-STEP PIN
    PORTD = (PORTD & B11100011) | (Bits & B00011100);
                   
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
