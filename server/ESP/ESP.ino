// XY-Plotter Server for ESP32/ESP8266 board

// Author: Melchiorre Caruso
// Date:   03 Apr 2021

// Serial data format:
//
// bit0 -> increase internal main-loop time
// bit1 -> decrease internal main-loop time
// bit2 -> x-motor stp ()
// bit3 -> y-motor stp ()
// bit4 -> z-motor stp ()
// bit5 -> x-motor dir ()
// bit6 -> y-motor dir ()
// bit7 -> z-motor dir ()

#include <math.h>
#if defined(ESP32) 
  #include "ESP32Module.h" 
#endif
#if defined(ESP8266)
  #include "ESP8266Module.h"  
#endif
#include "TimerInterrupt_Generic.h"

volatile uint8_t Bits = 0; 
uint8_t Buffer[256];
uint8_t BufferIndex = 0;
uint8_t BufferSize  = 0; 

#define  RampLen 250 
uint16_t Ramps[RampLen];
uint16_t RampKB = 44000;
volatile uint16_t RampIndex = 0;

char ssid[] = "";
char pass[] = "";

WiFiClient client1;
WiFiServer server1(8888);

#if defined(ESP32) 
  ESP32Timer timer1(1);
#endif  
#if defined(ESP8266)
  ESP8266Timer timer1;
#endif

void ICACHE_RAM_ATTR onTime1() {

  if (Bits != 0) {  
    timer1.setInterval(Ramps[RampIndex], onTime1);       

    digitalWrite(MOTOR_X_DIR, bitRead(Bits, 5));
    digitalWrite(MOTOR_Y_DIR, bitRead(Bits, 6));
    digitalWrite(MOTOR_Z_DIR, bitRead(Bits, 7));        
    digitalWrite(MOTOR_X_STP, bitRead(Bits, 2));
    digitalWrite(MOTOR_Y_STP, bitRead(Bits, 3));   
    digitalWrite(MOTOR_Z_STP, bitRead(Bits, 4));  
    digitalWrite(MOTOR_X_STP, LOW);        
    digitalWrite(MOTOR_Y_STP, LOW);   
    digitalWrite(MOTOR_Z_STP, LOW);  
    if (bitRead(Bits, 0)) { 
      if (RampIndex < RampLen-1) { RampIndex++; } 
    }        
    if (bitRead(Bits, 1)) { 
      if (RampIndex > 0) { RampIndex--; } 
    }                   
    Bits = 0;      
  }      
}
 
void setup() {
  // init wifi
  WiFi.begin(ssid, pass);
  // disable stepper motors
  pinMode(MOTOR_OFF, OUTPUT);
  digitalWrite(MOTOR_OFF, HIGH);
  // init stepper X/Y/Z
  pinMode(MOTOR_X_STP, OUTPUT);
  pinMode(MOTOR_Y_STP, OUTPUT);
  pinMode(MOTOR_Z_STP, OUTPUT);
  pinMode(MOTOR_X_DIR, OUTPUT);
  pinMode(MOTOR_Y_DIR, OUTPUT);
  pinMode(MOTOR_Z_DIR, OUTPUT);   
  // init server
  server1.begin();     
  // enable stepper motors
  digitalWrite(MOTOR_OFF, LOW);    
  // init ramp table
  for (uint16_t i = 0; i < RampLen; i++) { 
    Ramps[i] = round(RampKB*(sqrt(i+2)-sqrt(i+1)));  
  }   
  // init interrupt
  timer1.attachInterruptInterval(Ramps[RampIndex], onTime1);
  // connect to WiFi
  while (WiFi.status() != WL_CONNECTED) { delay(50); }
}

void loop() { 
  
  if (Bits == 0) {      
    if (BufferIndex < BufferSize) {        
      Bits = Buffer[BufferIndex];
      BufferIndex++;      
    }
    if (BufferIndex == BufferSize) {
      if (client1) {
        if (client1.connected()) {            
          BufferIndex = 0;  
          BufferSize  = min(128, client1.available());         
          if (BufferSize > 0)  {                                 
            client1.read(Buffer, BufferSize);
            client1.write(BufferSize);               
          }          
        } else { client1.stop(); } 
      } else { 
        client1 = server1.available();
        client1.setNoDelay(true); 
      } 
    }
  }  

}
