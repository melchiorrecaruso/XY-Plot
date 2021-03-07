// XY-Plotter Server for ESP32/ESP8266 boards

// Author: Melchiorre Caruso
// Date:   06 Mar 2021

// Server protocol

// bit0 -> x-stepper tick
// bit1 -> x-stepper CCW dir (-1)
// bit2 -> y-stepper tick
// bit3 -> y-stepper CCW dir (-1)
// bit4 -> z-stepper tick
// bit5 -> z-stepper CCW dir (-1)
// bit6 -> increase internal main-loop time
// bit7 -> decrease internal main-loop time

#include <math.h>
#if defined(ESP32)
  #include <WiFi.h>
#elif defined(ESP8266)
  #include <ESP8266WiFi.h>
#endif

char ssid[] = "QUACK-NET";
char pass[] = "0SVDTPGPQVGOVO7HN";
uint16_t port1 = 8888;

uint8_t Bits = 0; 
uint8_t Buffer[255];
uint8_t BufferIndex = 0;
uint8_t BufferSize = 0;

uint32_t Num = 24; 
uint32_t Freq = 20000;
uint32_t Acceleration = 1024+512;
volatile uint8_t Flag = 0;
volatile uint32_t Accumulator = 0;
volatile uint32_t SpeedNow = 1 << (Num - 7);
uint32_t SpeedMin = 1 << (Num -  7);
uint32_t SpeedMax = 1 << (Num -  3);
uint8_t Shift1 = 0;
uint8_t Shift2 = 0;

WiFiClient client1;
WiFiServer server1(port1);

#if defined(ESP32) 
  #include "ESP32Module.h"
#elif defined(ESP8266)
  #include "ESP8266Module.h"
#endif

void setup() {
  // init serial
  // Serial.begin(115200);  
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
  // init wifi
  WiFi.begin(ssid, pass);
  while (WiFi.status() != WL_CONNECTED) { delay(50); }
  // init server
  server1.begin();  
  server1.setNoDelay(true);    
  // init interrupt
  #if defined(ESP32) 
    initESP32Interrupt();
  #elif defined(ESP8266)
    initESP8266Interrupt();
  #endif     
   // enable stepper motors
  digitalWrite(MOTOR_OFF, LOW);
}

void loop() {
  
  if (Flag > 0) {
    #if defined(ESP32) 
      portENTER_CRITICAL(&timerMux); 
    #endif
    Shift1 = bitRead(Accumulator, Num -1);
    #if defined(ESP32) 
      portEXIT_CRITICAL(&timerMux);
    #endif  
    
    if (Shift2 != Shift1) {  
      Shift2 = Shift1;      
      if (Shift2 != 0) {                
        digitalWrite(MOTOR_X_DIR, bitRead(Bits, 1));
        digitalWrite(MOTOR_Y_DIR, bitRead(Bits, 3));
        digitalWrite(MOTOR_Z_DIR, bitRead(Bits, 5));  
        digitalWrite(MOTOR_X_STP, bitRead(Bits, 0));
        digitalWrite(MOTOR_Y_STP, bitRead(Bits, 2));   
        digitalWrite(MOTOR_Z_STP, bitRead(Bits, 4));              
        if (bitRead(Bits, 6)) {
          SpeedNow += Acceleration;
          if(SpeedNow > SpeedMax) { SpeedNow = SpeedMax; }
        }        
        if (bitRead(Bits, 7)) {
          SpeedNow -= Acceleration;
          if(SpeedNow < SpeedMin) { SpeedNow = SpeedMin; }
        }                      
        Bits = 0;

       } else {
        digitalWrite(MOTOR_X_STP, LOW);
        digitalWrite(MOTOR_Y_STP, LOW);   
        digitalWrite(MOTOR_Z_STP, LOW);  
        if (BufferIndex < BufferSize) {
          Bits = Buffer[BufferIndex];
          BufferIndex++;        
        } 
      }     
    }    
    Flag--;  
  }
  
  /*
  if (BufferIndex == BufferSize) {         
    BufferIndex = 0;  
    BufferSize  = min(Serial.available(), 255);          
    if (BufferSize > 0) {                                 
      Serial.readBytes(Buffer, BufferSize);
      Serial.write(BufferSize);
    }            
  }
  */
  if (BufferIndex == BufferSize) {  
    if (client1) {
      if (client1.connected()) {                    
        BufferIndex = 0;  
        BufferSize  = min(client1.available(), 255);          
        if (BufferSize > 0) {                                 
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
