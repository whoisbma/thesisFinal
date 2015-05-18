
#include <LiquidCrystal.h>

#define CHARACTERSPERLINE 16
#define LCDLINES 2
#define MAXLINES 10

String heldText = "";//String(CHARACTERSPERLINE*MAXLINES);

int received = 0;

LiquidCrystal lcd(12, 22, 8, 9, 10, 11);
LiquidCrystal lcd1(12, 26, 8, 9, 10, 11);
LiquidCrystal lcd2(12, 30, 8, 9, 10, 11);
LiquidCrystal lcd3(12, 34, 8, 9, 10, 11);
LiquidCrystal lcd4(12, 38, 8, 9, 10, 11);
LiquidCrystal lcd5(12, 42, 8, 9, 10, 11);
LiquidCrystal lcd6(12, 46, 8, 9, 10, 11);
LiquidCrystal lcd7(12, 50, 8, 9, 10, 11);
LiquidCrystal lcd8(12, 25, 8, 9, 10, 11);
LiquidCrystal lcd9(12, 29, 8, 9, 10, 11);
LiquidCrystal lcd10(12, 33, 8, 9, 10, 11);
LiquidCrystal lcd11(12, 37, 8, 9, 10, 11);
LiquidCrystal lcd12(12, 41, 8, 9, 10, 11);
LiquidCrystal lcd13(12, 45, 8, 9, 10, 11);
LiquidCrystal lcd14(12, 49, 8, 9, 10, 11);


int numLCDs = 15;

LiquidCrystal lcds[15] = {lcd, lcd1, lcd2, lcd3, lcd4, lcd5, lcd6, lcd7, lcd8, lcd9, lcd10, lcd11, lcd12, lcd13, lcd14};

//int buzzerPin = 3;
int stepper = 0;

void setup() {
  // start serial port at 9600 bps:
  Serial.begin(9600);
  //pinMode(2, INPUT);   // digital sensor is on digital pin 2
  lcds[0].begin(16, 2);
  lcds[0].print("1");
  lcds[1].begin(16, 2);
  lcds[1].print("2");
  lcds[2].begin(16, 2);
  lcds[2].print("3");
  lcds[3].begin(16, 2);
  lcds[3].print("4");
  lcds[4].begin(16, 2);
  lcds[4].print("5");
  lcds[5].begin(16, 2);
  lcds[5].print("6");
  lcds[6].begin(16, 2);
  lcds[6].print("7");
  lcds[7].begin(16, 2);
  lcds[7].print("8");
  lcds[8].begin(16, 2);
  lcds[8].print("9");
  lcds[9].begin(16, 2);
  lcds[9].print("10");
  lcds[10].begin(16, 2);
  lcds[10].print("11");
  lcds[11].begin(16, 2);
  lcds[11].print("12");
  lcds[12].begin(16, 2);
  lcds[12].print("13");
  lcds[13].begin(16, 2);
  lcds[13].print("14");
  lcds[14].begin(16, 2);
  lcds[14].print("15");
  
  //lcd.autoscroll();
  establishContact();  // send a byte to establish contact until receiver responds
  delay(1000);
  //heldText = "returns a new string that is a part of the original string. When using the endIndex parameter, the string between beginIndex and endIndex -1 is returned.";
  //heldTextToLCD();
}

void loop()
{
  // if we get a valid byte, read analog ins:
  if (Serial.available() > 0)
  {
    // get incoming byte:
    handleIncomingChars(stepper);

    // delay 10ms to let the ADC recover:
    delay(10);
  }
}

void establishContact() {
  while (Serial.available() <= 0) {
    Serial.println("test");   // send an initial string
    stepper = 0;
    delay(300);
  }
}

void handleIncomingChars(int whichLCD) {
  // read the incoming data as a char:
  char inChar = Serial.read();

  if (inChar == '\n' || inChar == '\r') {
    lcds[whichLCD].clear();
    lcds[whichLCD].home();
    heldTextToLCD(whichLCD);
    heldText = "";//String(CHARACTERSPERLINE * MAXLINES);
    if (stepper < numLCDs-1) {
      stepper++;
    } else {
      stepper = 0;
    }
  } else if (inChar == '>') {
    int maxLCD = numLCDs-1;
    stepper = maxLCD;
    while (stepper > 0) {
      lcds[stepper].clear();
      lcds[stepper].home();
      stepper--;
      delay(50);
    }
    lcds[0].clear();
    lcds[0].home();
  } else {
    // if you're not at the end of the string, append
    // the incoming character:
    if (heldText.length() < (CHARACTERSPERLINE * MAXLINES)) {
      heldText.concat(inChar);
      //heldText.append(inChar);
    } else {
      // empty the string by setting it equal to the inoming char:
      heldText = String(inChar);
    }
  }
}

void heldTextToLCD(int whichLCD)
{
  Serial.println(heldText);
//  lcd.begin(16, 2);
//  lcd.print(heldText);
  
  int numLines = heldText.length() / CHARACTERSPERLINE;
  //String lastFragment = "";
  int remainingLength = heldText.length();
  lcds[whichLCD].clear();
  int currentIndex = 0;
  int i = 0;
  while (remainingLength > 0 || i > MAXLINES) {
    if (i % LCDLINES == 0) {
      lcds[whichLCD].clear();
    } else {
      lcds[whichLCD].setCursor(0, i % LCDLINES);
    }

    String line = "";//String(32);//lastFragment;
    int lengthToTake = CHARACTERSPERLINE;

    if (remainingLength < CHARACTERSPERLINE) {
      lengthToTake = remainingLength;
    }
    line.concat(heldText.substring(currentIndex, currentIndex + lengthToTake));
    delay(10);
    currentIndex += lengthToTake;
    delay(100);
    lcds[whichLCD].print(line);
    delay(200);
    i++;


    remainingLength = heldText.length() - currentIndex;
  }
  Serial.println("done");
}
