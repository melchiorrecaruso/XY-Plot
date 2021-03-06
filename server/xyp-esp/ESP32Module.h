// define PIN shield CNC V3

#define MOTOR_X_STP_PIN   12
#define MOTOR_Y_STP_PIN   26
#define MOTOR_Z_STP_PIN   27
#define MOTOR_X_DIR_PIN   14 
#define MOTOR_Y_DIR_PIN   15
#define MOTOR_Z_DIR_PIN   33
#define MOTOR_OFF         13

hw_timer_t * timer    = NULL;
portMUX_TYPE timerMux = portMUX_INITIALIZER_UNLOCKED;

void IRAM_ATTR onESP32Timer() {
  portENTER_CRITICAL_ISR(&timerMux);
  Accumulator += SpeedNow; 
  Flag++; 
  portEXIT_CRITICAL_ISR(&timerMux);
}

void initESP32Interrupt() {
  timer = timerBegin(1, 80, true);                
  timerAttachInterrupt(timer, &onESP32Timer, true);    
  timerAlarmWrite(timer, (F_CPU/16)/Freq, true);      
  timerAlarmEnable(timer);
}
 
