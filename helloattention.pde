// helloattention.pde - Show attention level (EEG) with LED color. 
// (c) Kimmo Karvinen & Tero Karvinen http://MindControl.BotBook.com
/* Disconnect TX and RX jump wires from Arduino when uploading
 from IDE. Turn robot on, then in a couple of seconds turn headband on. */

const int redPin = 9; 
const int greenPin = 10; 
const int bluePin = 11;
const int tinyLedPin = 13; 
const int speakerPin = 12; 
int tinyLedState = HIGH;

void setup() {

pinMode(redPin, OUTPUT); 
pinMode(greenPin, OUTPUT); 
pinMode(bluePin, OUTPUT); 
pinMode(tinyLedPin, OUTPUT); 
pinMode(speakerPin, OUTPUT);
Serial.begin(115200); // bits 
connectHeadset();
}


void loop() {
  float att = getAttention();
;  
  if (att > 0) {
    setBlueToRed(att);
  }
 toggleTinyLed();
}

/*** Headset ***/
void connectHeadset() {
  setGreen(); 
  delay(3000); 
  Serial.write(0xc2); 
  setWhite();
}

byte readOneByte() {
  
while (!Serial.available()) { 
  delay(5); 
}
return Serial.read();
}

float getAttention() { 
  // return attention percent (0.0 to 1.0)
  // negative (-1, -2...) for error 
  byte generatedChecksum = 0; 
  byte checksum = 0;
  int payloadLength = 0;
  byte payloadData[64] = {0};
  int poorQuality = 0; 
  float attention = 0;
  Serial.flush(); // prevent serial buffer from filling up //
  
  /* Sync */
  if (170 != readOneByte()) return -1; 
  if (170 != readOneByte()) return -1;
  
  /* Length */
  payloadLength = readOneByte();
  if (payloadLength > 169) return -2;
  
  /* Checksum */
  generatedChecksum = 0;
  for (int i = 0; i < payloadLength; i++) {
    // Read payload into array: 
    payloadData[i] = readOneByte(); 
    generatedChecksum += payloadData[i];
  }
  
  generatedChecksum = 255 - generatedChecksum; 
  checksum = readOneByte();
  if (checksum != generatedChecksum) return -3;
  
  /* Payload */
  for (int i = 0; i < payloadLength; i++) {
    switch (payloadData[i]) { 
    case 0xD0:
      sayHeadsetConnected();
      break; 
    case 4: 
      i++;
      attention = payloadData[i]; 
       break;
    case 2:
      i++;
      poorQuality = payloadData[i]; 
      if (200 == poorQuality) {
        setYellow(); 
        return -4; 
      }
      break;
    case 0xD1: // Headset Not Found
    case 0xD2: // Headset Disconnected case 0xD3: // Request Denied
    case 0xd3:
      wave(speakerPin, 900, 1500); 
      setWhite();
      return -5;
      break;
  case 0x80: // skip RAW 
  i = i + 3;
      break;
    case 0x83: // skip ASIC_EEG_POWER
      i = i + 25;
      break; 
    } // switch
  } // for
  return (float)attention / 100; 
}

/*** Outputs ***/
void setBlueToRed(float redPercent) {
  int red = redPercent * 255;
  int blue = (1 - redPercent) * 255; 
  setColor(red, 0, blue);
}
void setGreen() {
  setColor(0, 255, 0);
}
void setYellow() {
  setColor(255, 255, 0);
}
void setWhite() {
  setColor(100, 100, 100);
}
void sayHeadsetConnected() {
  wave(speakerPin, 440, 40); 
  delay(25); 
  wave(speakerPin, 300, 20); 
  wave(speakerPin, 540, 40); 
  delay(25); 
  wave(speakerPin, 440, 20); 
  wave(speakerPin, 640, 40); 
  delay(25); 
  wave(speakerPin, 540, 40); 
  delay(25);
}

void setColor(int red, int green, int blue) {
analogWrite(redPin, 255 - red); 
analogWrite(greenPin, 255 - green); 
analogWrite(bluePin, 255 - blue);
}

void toggleTinyLed() {
  tinyLedState = !tinyLedState; 
  digitalWrite(tinyLedPin, tinyLedState);
}


void wave(int pin, float frequency, int duration) {
  float period = 1 / frequency * 1000 * 1000; // microseconds 
  long int startTime = millis();
  while (millis() - startTime < duration) {
    digitalWrite(pin, HIGH); 
    delayMicroseconds(period / 2); 
    digitalWrite(pin, LOW); 
    delayMicroseconds(period / 2);
  } 
}
