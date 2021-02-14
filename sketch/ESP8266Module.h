// define PIN shield CNC V3

#define MOTOR_X_STP_PIN    4
#define MOTOR_Y_STP_PIN    0
#define MOTOR_Z_STP_PIN    2
#define MOTOR_X_DIR_PIN   14
#define MOTOR_Y_DIR_PIN   12
#define MOTOR_Z_DIR_PIN   13
#define MOTOR_OFF          5 

void ICACHE_RAM_ATTR onESP8266Timer() {
  Accumulator += SpeedNow;    
}

void initESP8266Interrupt() {
  timer1_attachInterrupt(onESP8266Timer);
  timer1_enable(TIM_DIV16, TIM_EDGE, TIM_LOOP);
  timer1_write((F_CPU/16)/Freq); 
}
