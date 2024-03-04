// serialPortProject
// Nathan Lord
// Last modified 12/6/23
// Function: Loop through A-Z and give ASCII values corresponding
//  Receive valid data in hex for values and loop will continue from there


extern "C" {
  //function prototypes 
  void start();
  void SerialLoop();
}

void setup() {
  void ClearScreen(); // clears screen
  start(); // calls to initalize ports
}

void loop() {
  SerialLoop(); // Runs the main loop for A-Z and handling transmissions
}





// Clears the LCD display and returns to position (1,1)
void ClearScreen(){
  Serial.write(0xFE);
  Serial.write(0x58);
  delay(10);
}
