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

#define _TIMERINTERRUPT_LOGLEVEL_  0

#include <math.h>
#if defined(ESP32) 
  #include "ESP32Module.h" 
  #include "ESP32TimerInterrupt.h"
#endif
#if defined(ESP8266)
  #include "ESP8266Module.h"  
  #include "ESP8266TimerInterrupt.h"
#endif

uint8_t Buffer[256];
uint8_t BufferIndex   = 0;
uint8_t BufferSize    = 0; 
volatile uint8_t Bits = 0; 

#define NumOfPoints     0x80000000 
#define SpeedTableSize  201
volatile bool     Flag  = false;   
volatile uint32_t Accum = 0;
volatile uint32_t SpeedIndex = 0;
         uint32_t SpeedTable[SpeedTableSize];

char ssid[] = "QUACK-NET";
char pass[] = "0SVDTPGPQVGOVO7HN";

WiFiClient client1;
WiFiServer server1(8888);

#if defined(ESP32) 
  ESP32Timer timer1(1);
#endif  
#if defined(ESP8266)
  ESP8266Timer timer1;
#endif

#if defined(ESP32)  
  bool IRAM_ATTR onTime1(void * TimerNo) {
#endif 
#if defined(ESP8266) 
  void IRAM_ATTR onTime1() { 
#endif
  Accum += SpeedTable[SpeedIndex];
  if (Accum > NumOfPoints) { 
    if (Flag == true) {  
      digitalWrite(MOTOR_X_DIR, bitRead(Bits, 5));
      digitalWrite(MOTOR_Y_DIR, bitRead(Bits, 6));
      digitalWrite(MOTOR_Z_DIR, bitRead(Bits, 7));        
      digitalWrite(MOTOR_X_STP, bitRead(Bits, 2));
      digitalWrite(MOTOR_Y_STP, bitRead(Bits, 3));   
      digitalWrite(MOTOR_Z_STP, bitRead(Bits, 4)); 
      if (bitRead(Bits, 0)) { SpeedIndex++; }        
      if (bitRead(Bits, 1)) { SpeedIndex--; }  

        if (SpeedIndex > 200)  { Serial.println(SpeedIndex); }     
        if (SpeedIndex <   0)  { Serial.println(SpeedIndex); }     
      
      Bits = 0;   
      Flag = false;     
    } else {
      digitalWrite(MOTOR_X_STP, LOW);        
      digitalWrite(MOTOR_Y_STP, LOW);   
      digitalWrite(MOTOR_Z_STP, LOW);
      Flag = true;
    }      
    Accum -= NumOfPoints;                          
  }
  
  #if defined(ESP32)  
    return true;  
  #endif  
}
 
void setup() {
  Serial.begin(115200);
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
  // init speed table
  double Freq     = 1000.00;  // Hz
  double CoreFreq = 16000.00; // Hz
  double KC       = 2*(Freq/CoreFreq*(double)NumOfPoints)/(sqrt(2)-sqrt(1));  
  for (uint16_t i = 1; i <= SpeedTableSize; i++) { 
    SpeedTable[SpeedTableSize - i] = trunc(KC*(sqrt(i + 1)-sqrt(i)));     
  }     
  // connect to WiFi
  while (WiFi.status() != WL_CONNECTED) { delay(50); }
  // init interrupt
  timer1.attachInterrupt(CoreFreq, onTime1);    
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
      } 
    }
  }  

}
