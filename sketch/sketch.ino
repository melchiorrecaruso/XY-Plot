// XY-Plotter Server for ESP32/ESP8266 boards

// Author: Melchiorre Caruso
// Date:   28 Feb 2021

// Specifica protocollo:

// bit0 -> x-stepper tick
// bit1 -> x-stepper CCW dir (-1)
// bit2 -> y-stepper tick
// bit3 -> y-stepper CCW dir (-1)
// bit4 -> z-stepper tick
// bit5 -> z-stepper CCW dir (-1)
// bit6 -> increase internal main-loop time
// bit7 -> decrease internal main-loop time

// LIBRARY
 
#if defined(ESP32)
  #include <WiFi.h>
#elif defined(ESP8266)
  #include <ESP8266WiFi.h>
#endif

// CONST

char ssid[] = "QUACK-NET";
char pass[] = "0SVDTPGPQVGOVO7HN";
uint16_t port1 = 8888;

WiFiClient client1;
WiFiServer server1(port1);

// VAR

#define  BUFFER_LEN 512
uint8_t  Bits = 0; 
uint8_t  Buffer[BUFFER_LEN];
uint8_t  BufferCrc   = 0;
uint16_t BufferIndex = 0;
uint16_t BufferSize  = 0;

uint32_t LoopStart = micros();
uint32_t LoopNow   = 0;
uint32_t LoopDelay = 440;

uint32_t Freq = 50000;
uint32_t Num = 24; 
uint32_t Acceleration = 64;
volatile uint32_t Accumulator = 0;
volatile uint32_t SpeedNow = 2 << (Num - 10);
uint32_t SpeedMin = 2 << (Num - 10);
uint32_t SpeedMax = 2 << (Num -  2);
 uint8_t Shift1 = 0;
 uint8_t Shift2 = 0;

#if defined(ESP32) 
  #include "ESP32Module.h"
#elif defined(ESP8266)
  #include "ESP8266Module.h"
#endif
#include "CRC8.h"
          
void setup() {
  // disable stepper motors
  pinMode(MOTOR_OFF, OUTPUT);
  digitalWrite(MOTOR_OFF, HIGH);
  // init stepper X/Y/Z
  pinMode(MOTOR_X_STP_PIN, OUTPUT);
  pinMode(MOTOR_Y_STP_PIN, OUTPUT);
  pinMode(MOTOR_Z_STP_PIN, OUTPUT);
  pinMode(MOTOR_X_DIR_PIN, OUTPUT);
  pinMode(MOTOR_Y_DIR_PIN, OUTPUT);
  pinMode(MOTOR_Z_DIR_PIN, OUTPUT); 
  // init wifi
  WiFi.begin(ssid, pass);
  while (WiFi.status() != WL_CONNECTED) { 
    delay(50);
  }   
  // init server
  server1.begin();       
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
  
  LoopNow = micros();
  if ((int32_t)(LoopNow - LoopStart) >= LoopDelay) { 
          
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
        if (Bits != 0) {
          digitalWrite(MOTOR_X_DIR_PIN, bitRead(Bits, 1));
          digitalWrite(MOTOR_Y_DIR_PIN, bitRead(Bits, 3));
          digitalWrite(MOTOR_Z_DIR_PIN, bitRead(Bits, 5));  
          digitalWrite(MOTOR_X_STP_PIN, bitRead(Bits, 0));
          digitalWrite(MOTOR_Y_STP_PIN, bitRead(Bits, 2));   
          digitalWrite(MOTOR_Z_STP_PIN, bitRead(Bits, 4));   
          Bits = 0;                                                         
        }         
      } else {
        digitalWrite(MOTOR_X_STP_PIN, LOW);
        digitalWrite(MOTOR_Y_STP_PIN, LOW);   
        digitalWrite(MOTOR_Z_STP_PIN, LOW);  
      }
    } 

    if (Bits == 0) { 
      if (BufferIndex < BufferSize) {
        Bits = Buffer[BufferIndex];
        BufferIndex++;
      }    
    } else {  
      if (bitRead(Bits, 6)) {
        SpeedNow += Acceleration;
        if(SpeedNow > SpeedMax) { SpeedNow = SpeedMax; }
      }        
      if (bitRead(Bits, 7)) {
        SpeedNow -= Acceleration;
        if(SpeedNow < SpeedMin) { SpeedNow = SpeedMin; }
      }
    }
    LoopStart = LoopNow;
  }

  if (BufferIndex == BufferSize) {         
    if (client1) {
      if (client1.connected()) {     
        BufferIndex = 0;  
        BufferSize  = 0;          
        if (client1.available() >= BUFFER_LEN) {                                 
          client1.read(Buffer, BUFFER_LEN);
          BufferCrc = CRC8();
          if (BufferCrc == Buffer[BUFFER_LEN -1]) {
            BufferSize = BUFFER_LEN -1;              
          }
          client1.write(BufferCrc);            
        }
      } else { client1.stop(); } 
    } else { client1 = server1.available(); }             
  }  
}  
