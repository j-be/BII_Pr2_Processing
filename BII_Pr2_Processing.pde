import processing.serial.*;
import java.util.Hashtable;

int serialBaudrate = 115200;
Serial serialPort;

// Constants
// Atmospheric pressure at 0m in hPa
float PRESSURE_0 = 1013.25f;
// Minimum atmospheric pressure (Grossglockner = 3798m) in hPa
float PRESSURE_MIN = 622.8f;

// Calculated constants
// Pressure range (derived from above)
float PRESSURE_RANGE = PRESSURE_0 - PRESSURE_MIN;

// Serial data
boolean buttonPressed = false;
int light = 0;
float humidity = 0f;
float pressure = 0f;
float temperature = 0f;
boolean motionDetected = false;
String lastReadTag = "";
Hashtable rfidTags = new Hashtable();

void setup() {
  size(650, 450); frameRate(24);
  //println(Serial.list());
 serialPort = new Serial(this, Serial.list()[0], 112500);
 serialPort.bufferUntil('\n');
 serialPort.clear();

 // RFID IDs
 rfidTags.put("24849484853684869665769663", "Blue Tag");
 rfidTags.put("24849484848535251535649703", "Red Tag");
 rfidTags.put("25270484854536768656552683", "Card 52650");
 rfidTags.put("25270484854495654575251673", "Card 34452");
}

void initCanvas() {
  clear();
  background(128);
}

void drawCaption(int x, int y, String caption) {
  textSize(24);
  text(caption, x + 5, y + 25); 
}

void drawButton() {
  fill(255);
  if (buttonPressed)
    rect(25, 115, 100, 10);
  else
    rect(25, 75, 100, 50);
  drawCaption(25, 125, "Button");
}

void drawBar(int x, int y, int barHeight, int r, int g, int b, String caption) {
  fill(r, g, b);
  rect(x, y - barHeight, 100, barHeight);
  drawCaption(x, y, caption);
}

void drawLight() {
  int barHeight = int(light / 10f);
  drawBar(150, 125, barHeight, 0, 255, 0, "Light");
  drawCaption(150, 150, "" + light);
}

void drawHumPresTemp() {
  int humBarHeight = int(humidity);
  int tempBarHeight = int(temperature * 2);
  int pressBarHeight = int((pressure - PRESSURE_MIN) / PRESSURE_RANGE * 100);
  drawBar(275, 125, humBarHeight, 0, 0, 255, "Hum.");
  drawCaption(275, 150, "" + humidity + "%");
  drawBar(375, 125, tempBarHeight, 255, 0, 0, "Temp.");
  drawCaption(375, 150, "" + temperature + "°C");
  drawBar(475, 125, pressBarHeight, 255, 255, 0, "Press.");
  drawCaption(475, 150, "" + pressure + "hPa");
}

void drawMotionSensor() {
  if (motionDetected)
    fill(255, 0, 0);
  else
    fill(192);

  ellipse(75, 275, 100, 100);
  fill(32);
  drawCaption(25, 325, "Motion");

  // Send command for LED to Arduino
  serialPort.write("l\t");
  if (motionDetected)
    serialPort.write("1");
  else
    serialPort.write("0");
  serialPort.write("\n");
}

void drawLastRfidTagId() {
  drawCaption(20, 400, "Last tag: " + lastReadTag);
}

void draw() {
  initCanvas();

  drawButton();
  drawLight();
  drawHumPresTemp();
  drawMotionSensor();
  drawLastRfidTagId();
}

void serialEvent (Serial serialPort) {
  String[] messageParts = null;
  String dataType = null;
  String value = null;
  String message = serialPort.readStringUntil('\n');

  if (message != null) {
    messageParts = message.split("\t");

    if (messageParts.length == 2) {
      // Remove the \n
      dataType = messageParts[0].trim();
      value = messageParts[1].trim();
    } else
      return;
   
   if (dataType == null || dataType.isEmpty())
     return;
 
    switch (dataType.charAt(0)) {
      case 'b':
        if ("0".equals(value)) {
          buttonPressed = true;
          lastReadTag = "";
        } else
          buttonPressed = false;
        break;
      case 'l':
        try {
          light = Integer.parseInt(value);
        } catch (NumberFormatException nfe) {}
        break;
      case 'h':
        try {
          humidity = Float.parseFloat(value);
        } catch (NumberFormatException nfe) {}
        break;
      case 'p':
        try {
          pressure = Float.parseFloat(value);
        } catch (NumberFormatException nfe) {}
        break;
      case 't':
        try {
          temperature = Float.parseFloat(value);
        } catch (NumberFormatException nfe) {}
        break;
      case 'm':
        motionDetected = "1".equals(value);
        break;
      case 'r':
        if (!"no".equals(value))
          lastReadTag = rfidTags.get(value).toString();
        break;
      default:
        break;
    }
  }
}