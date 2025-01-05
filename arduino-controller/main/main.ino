/*********************************************************************
 This is an example for our nRF52 based Bluefruit LE modules

 Pick one up today in the adafruit shop!

 Adafruit invests time and resources providing this open source code,
 please support Adafruit and open-source hardware by purchasing
 products from Adafruit!

 MIT license, check LICENSE for more information
 All text above, and the splash screen below must be included in
 any redistribution
*********************************************************************/
#include <bluefruit.h>
#include <Adafruit_NeoPixel.h>    //  Library that provides NeoPixel functions


BLEDis bledis;
BLEHidAdafruit blehid;
Adafruit_NeoPixel boardPixel = Adafruit_NeoPixel(1, 8, NEO_GRB + NEO_KHZ800);


void startAdv(void)
{  
  // Advertising packet
  Bluefruit.Advertising.addFlags(BLE_GAP_ADV_FLAGS_LE_ONLY_GENERAL_DISC_MODE);
  Bluefruit.Advertising.addTxPower();
  Bluefruit.Advertising.addAppearance(BLE_APPEARANCE_HID_KEYBOARD);
  
  // Include BLE HID service
  Bluefruit.Advertising.addService(blehid);

  // There is enough room for the dev name in the advertising packet
  Bluefruit.Advertising.addName();
  
  /* Start Advertising
   * - Enable auto advertising if disconnected
   * - Interval:  fast mode = 20 ms, slow mode = 152.5 ms
   * - Timeout for fast mode is 30 seconds
   * - Start(timeout) with timeout = 0 will advertise forever (until connected)
   * 
   * For recommended advertising interval
   * https://developer.apple.com/library/content/qa/qa1931/_index.html   
   */
  Bluefruit.Advertising.restartOnDisconnect(true);
  Bluefruit.Advertising.setInterval(32, 244);    // in unit of 0.625 ms
  Bluefruit.Advertising.setFastTimeout(30);      // number of seconds in fast mode
  Bluefruit.Advertising.start(0);                // 0 = Don't stop advertising after n seconds
}


int inputPin = 13;
bool hasKeyPressed = false;
bool serialOutput = true;
bool showPulses = true;

unsigned long lastLoop = 0;
unsigned long lastSignal = 0;
int pulses = 0;
int ledTimeRemaining = -1;

void setup() 
{
  if (serialOutput) {
    Serial.begin(115200);
    while ( !Serial ) delay(10);   // for nrf52840 with native usb
    Serial.println("Rotary keyboard is running...");
  }
  Bluefruit.begin();
  Bluefruit.setTxPower(4);    // Check bluefruit.h for supported values

  boardPixel.begin();
  boardPixel.setBrightness(20);
  boardPixel.clear();
  boardPixel.show();

  // Configure and Start Device Information Service
  bledis.setManufacturer("Submarines LLC");
  bledis.setModel("Rotary Phone");
  bledis.begin();

  /* Start BLE HID
   * Note: Apple requires BLE device must have min connection interval >= 20m
   * ( The smaller the connection interval the faster we could send data).
   * However for HID and MIDI device, Apple could accept min connection interval 
   * up to 11.25 ms. Therefore BLEHidAdafruit::begin() will try to set the min and max
   * connection interval to 11.25  ms and 15 ms respectively for best performance.
   */
  blehid.begin();

  /* Set connection interval (min, max) to your perferred value.
   * Note: It is already set by BLEHidAdafruit::begin() to 11.25ms - 15ms
   * min = 9*1.25=11.25 ms, max = 12*1.25= 15 ms 
   */
  /* Bluefruit.Periph.setConnInterval(9, 12); */

  // Set up and start advertising
  startAdv();
  pinMode(inputPin, INPUT);

  boardPixel.setPixelColor(0, 0, 32, 32);
  boardPixel.show(); 
  ledTimeRemaining = 5000;
  lastLoop = millis();
}



void loop() 
{
  bool delayLoop = true;
  unsigned long now = millis();
  unsigned long sinceSignal = now - lastSignal;
  unsigned long sinceLoop = now - lastLoop;
  lastLoop = now;

  if ( hasKeyPressed )
  {
    hasKeyPressed = false;
    blehid.keyRelease();
  }

  // 820 = high
  // 930 = off
  int sensorValue = analogRead(A0);

  if (ledTimeRemaining > 0) {
    ledTimeRemaining -= sinceLoop;
    if (ledTimeRemaining < 0) {
      boardPixel.clear();
      boardPixel.show();
    }
  }
  if (sensorValue < 875) {
    // Blue when a pulse comes in
    if (showPulses) {
      boardPixel.setPixelColor(0, 0, 0, 32);
      boardPixel.show(); 
    }

    ledTimeRemaining = -1;

    if (sinceSignal < 22) {
      // debounce
      lastSignal = now;
    } else {
      if (serialOutput) {
        Serial.print("Since last input: ");
        Serial.print(sinceSignal);
        Serial.println("ms");
      }
      pulses += 1;
      lastSignal = now;


      // Send every third pulse as a keyboard press, reduces buffer usage
      // on the bluetooth side but lets receiver know something is coming
      if ((pulses % 3) == 1) {
        // Send key press, but on these no need to send a key release
        blehid.keyPress('.');
        if (serialOutput) {
          Serial.println("Sending '.'");
        }
        if (serialOutput && now - millis() > 5) {
          Serial.print("Slow bluetooth keypress: ");
          Serial.print(now - millis());
          Serial.println("ms");
        }
      }
      
      // Don't delay the next loop, since bluetooth can suck some time
      delayLoop = false;
    }
  } else if (pulses > 0) {
    if (sinceSignal > 250) {
      if (serialOutput) {
        Serial.print("Sending ");
        Serial.println('0' + (pulses % 10));
      }
      blehid.keyPress('0' + (pulses % 10));
      hasKeyPressed = true;

      // Green when sending dialed message
      boardPixel.setPixelColor(0, 0, 32, 0);
      boardPixel.show(); 
      ledTimeRemaining = 500;

      pulses = 0;
    } else {
      if (showPulses) {
        // Red while waiting for the next pulse
        boardPixel.setPixelColor(0, 32, 0, 0);
        boardPixel.show(); 
      }
      ledTimeRemaining = -1;
    }
  }

  if (delayLoop) {
     delay(5);
  }
}
