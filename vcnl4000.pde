// Example sketch for talking to the VCNL4000 i2c proximity/light sensor
// Written by Adafruit! Public domain.
// To use: Connect VCC to 3.3-5V (5V is best if it is available), GND to
//         ground, SCL to i2c clock (on classic arduinos, Analog 5), SDA
//         to i2c data (on classic arduinos Analog 4). The 3.3v pin is
//         an ouptut if you need 3.3V
// This sensor is 5V compliant so you can use it with 3.3 or 5V micros

// You can pick one up at the Adafruit shop: www.adafruit.com/products/466



//#include <Wire.h>
#include <TinyWireM.h> //use Wire.h if you are using Arduino Uno and the like

// the i2c address
#define VCNL4000_ADDRESS 0x13

// commands and constants
#define VCNL4000_COMMAND 0x80
#define VCNL4000_PRODUCTID 0x81
#define VCNL4000_IRLED 0x83
#define VCNL4000_AMBIENTPARAMETER 0x84
#define VCNL4000_AMBIENTDATA 0x85
#define VCNL4000_PROXIMITYDATA 0x87
#define VCNL4000_SIGNALFREQ 0x89
#define VCNL4000_PROXINITYADJUST 0x8A

#define VCNL4000_3M125 0
#define VCNL4000_1M5625 1
#define VCNL4000_781K25 2
#define VCNL4000_390K625 3

#define VCNL4000_MEASUREAMBIENT 0x10
#define VCNL4000_MEASUREPROXIMITY 0x08
#define VCNL4000_AMBIENTREADY 0x40
#define VCNL4000_PROXIMITYREADY 0x20

// Adjust to your preferences:
int motorPin = 4;
int delayTime = 3000;
int proxMax = 1995;

void setup() {
//  Serial.begin();
//  while (!Serial);
  pinMode(motorPin, OUTPUT);
//  Serial.println("VCNL");
  TinyWireM.begin(); //replace TinyWireM with Wire on all calls if using Wire.h

  uint8_t rev = read8(VCNL4000_PRODUCTID);
  
  if ((rev & 0xF0) != 0x10) {
//    Serial.println("Sensor not found :(");
    while (1);
  }
    
  
  write8(VCNL4000_IRLED, 20);        // set to 20 * 10mA = 200mA
//  Serial.print("IR LED current = ");
//  Serial.print(read8(VCNL4000_IRLED) * 10, DEC);
//  Serial.println(" mA");
  
  //write8(VCNL4000_SIGNALFREQ, 3);
//  Serial.print("Proximity measurement frequency = ");
  uint8_t freq = read8(VCNL4000_SIGNALFREQ);
//  if (freq == VCNL4000_3M125) Serial.println("3.125 MHz");
//  if (freq == VCNL4000_1M5625) Serial.println("1.5625 MHz");
//  if (freq == VCNL4000_781K25) Serial.println("781.25 KHz");
//  if (freq == VCNL4000_390K625) Serial.println("390.625 KHz");
  
  write8(VCNL4000_PROXINITYADJUST, 0x81);
//  Serial.print("Proximity adjustment register = ");
//  Serial.println(read8(VCNL4000_PROXINITYADJUST), HEX);
  
  // arrange for continuous conversion
  //write8(VCNL4000_AMBIENTPARAMETER, 0x89);

}

uint16_t readProximity() {
  write8(VCNL4000_COMMAND, VCNL4000_MEASUREPROXIMITY);
  while (1) {
    uint8_t result = read8(VCNL4000_COMMAND);
    //Serial.print("Ready = 0x"); Serial.println(result, HEX);
    if (result & VCNL4000_PROXIMITYREADY) {
      return read16(VCNL4000_PROXIMITYDATA);
    }
    
    delay(1);
  }
}


void loop() {

  // read ambient light!
  write8(VCNL4000_COMMAND, VCNL4000_MEASUREAMBIENT | VCNL4000_MEASUREPROXIMITY);
  
  while (1) {
    uint8_t result = read8(VCNL4000_COMMAND);
    //Serial.print("Ready = 0x"); Serial.println(result, HEX);
    if ((result & VCNL4000_AMBIENTREADY)&&(result & VCNL4000_PROXIMITYREADY)) {

//      Serial.print("Ambient = ");
//      Serial.print(read16(VCNL4000_AMBIENTDATA));
//      Serial.print("\t\tProximity = ");
      int prox = read16(VCNL4000_PROXIMITYDATA);
//      Serial.println(prox);
      if(prox >= proxMax) {
        digitalWrite(motorPin, HIGH);
        delay(delayTime);
      } else {
        digitalWrite(motorPin, LOW);
      }
      break;
    }
    delay(10);
  }
   delay(100);
 }

// Read 1 byte from the VCNL4000 at 'address'
uint8_t read8(uint8_t address)
{
  uint8_t data;

  TinyWireM.beginTransmission(VCNL4000_ADDRESS);
#if ARDUINO >= 100
  TinyWireM.write(address);
#else
  TinyWireM.send(address);
#endif
  TinyWireM.endTransmission();

  delayMicroseconds(170);  // delay required

  TinyWireM.requestFrom(VCNL4000_ADDRESS, 1);
  while(!TinyWireM.available());

#if ARDUINO >= 100
  return TinyWireM.read();
#else
  return TinyWireM.receive();
#endif
}


// Read 2 byte from the VCNL4000 at 'address'
uint16_t read16(uint8_t address)
{
  uint16_t data;

  TinyWireM.beginTransmission(VCNL4000_ADDRESS);
#if ARDUINO >= 100
  TinyWireM.write(address);
#else
  TinyWireM.send(address);
#endif
  TinyWireM.endTransmission();

  TinyWireM.requestFrom(VCNL4000_ADDRESS, 2);
  while(!TinyWireM.available());
#if ARDUINO >= 100
  data = TinyWireM.read();
  data <<= 8;
  while(!TinyWireM.available());
  data |= TinyWireM.read();
#else
  data = Wire.receive();
  data <<= 8;
  while(!Wire.available());
  data |= Wire.receive();
#endif
  
  return data;
}

// write 1 byte
void write8(uint8_t address, uint8_t data)
{
  TinyWireM.beginTransmission(VCNL4000_ADDRESS);
#if ARDUINO >= 100
  TinyWireM.write(address);
  TinyWireM.write(data);  
#else
  TinyWireM.send(address);
  TinyWireM.send(data);  
#endif
  TinyWireM.endTransmission();
}