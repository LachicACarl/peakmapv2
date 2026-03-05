#include <WiFi.h>
#include <HTTPClient.h>
#include <SPI.h>
#include <MFRC522.h>

// =========================
// WiFi + Backend Settings
// =========================
const char* WIFI_SSID = "Goblok Anjing";
const char* WIFI_PASSWORD = "192.168.0.254";

// IMPORTANT:
// Use your PC LAN IP, not 127.0.0.1 (example: http://192.168.1.10:8000)
String API_BASE = "http://192.168.5.31:8000";

String BUS_ID = "BUS-01";
String DRIVER_ID = "DR-01";
int STATION_ID = 1;

// true = tap-in mode, false = tap-out mode
bool tapInMode = true;

// =========================
// RC522 Pins (ESP32)
// =========================
// Default wiring:
// SDA(SS) -> GPIO5
// SCK     -> GPIO18
// MOSI    -> GPIO23
// MISO    -> GPIO19
// RST     -> GPIO22
#define SS_PIN 5
#define RST_PIN 22
MFRC522 mfrc522(SS_PIN, RST_PIN);

// =========================
// UID -> Passenger Mapping
// =========================
struct CardMap {
  const char* uid;
  const char* passengerId;
};

CardMap cardMaps[] = {
  {"A1B2C3D4", "bb6e65b6-1cc5-4b63-8b99-0c80f86e0b9b"},
  {"11223344", "PASSENGER-002"},
  {"DEADBEEF", "PASSENGER-003"}
};

const int CARD_MAP_COUNT = sizeof(cardMaps) / sizeof(cardMaps[0]);

String lastUid = "";
unsigned long lastScanMillis = 0;

String bytesToHexString(byte* buffer, byte bufferSize) {
  String uid = "";
  for (byte i = 0; i < bufferSize; i++) {
    if (buffer[i] < 0x10) uid += "0";
    uid += String(buffer[i], HEX);
  }
  uid.toUpperCase();
  return uid;
}

String lookupPassengerId(const String& uid) {
  for (int i = 0; i < CARD_MAP_COUNT; i++) {
    if (uid.equalsIgnoreCase(cardMaps[i].uid)) {
      return String(cardMaps[i].passengerId);
    }
  }
  return "";
}

void printHelp() {
  Serial.println("\n=== Commands ===");
  Serial.println("IN                 -> Set mode to Tap-In");
  Serial.println("OUT                -> Set mode to Tap-Out");
  Serial.println("STATION <id>       -> Set station id (e.g. STATION 5)");
  Serial.println("BUS <id>           -> Set bus id (e.g. BUS BUS-07)");
  Serial.println("DRIVER <id>        -> Set driver id (e.g. DRIVER DR-22)");
  Serial.println("SERVER <url>       -> Set API base (e.g. SERVER http://192.168.1.10:8000)");
  Serial.println("STATUS             -> Show current config");
  Serial.println("HELP               -> Show commands\n");
}

void printStatus() {
  Serial.println("\n=== Current Config ===");
  Serial.println("Mode      : " + String(tapInMode ? "TAP-IN" : "TAP-OUT"));
  Serial.println("Station   : " + String(STATION_ID));
  Serial.println("Bus       : " + BUS_ID);
  Serial.println("Driver    : " + DRIVER_ID);
  Serial.println("API Base  : " + API_BASE);
  Serial.println("WiFi IP   : " + WiFi.localIP().toString());
  Serial.println("======================\n");
}

void handleSerialCommands() {
  if (!Serial.available()) return;

  String cmd = Serial.readStringUntil('\n');
  cmd.trim();

  if (cmd.equalsIgnoreCase("IN")) {
    tapInMode = true;
    Serial.println("Mode set to TAP-IN");
    return;
  }

  if (cmd.equalsIgnoreCase("OUT")) {
    tapInMode = false;
    Serial.println("Mode set to TAP-OUT");
    return;
  }

  if (cmd.equalsIgnoreCase("STATUS")) {
    printStatus();
    return;
  }

  if (cmd.equalsIgnoreCase("HELP")) {
    printHelp();
    return;
  }

  if (cmd.startsWith("STATION ")) {
    String value = cmd.substring(8);
    value.trim();
    STATION_ID = value.toInt();
    Serial.println("Station set to " + String(STATION_ID));
    return;
  }

  if (cmd.startsWith("BUS ")) {
    BUS_ID = cmd.substring(4);
    BUS_ID.trim();
    Serial.println("Bus set to " + BUS_ID);
    return;
  }

  if (cmd.startsWith("DRIVER ")) {
    DRIVER_ID = cmd.substring(7);
    DRIVER_ID.trim();
    Serial.println("Driver set to " + DRIVER_ID);
    return;
  }

  if (cmd.startsWith("SERVER ")) {
    API_BASE = cmd.substring(7);
    API_BASE.trim();
    Serial.println("API Base set to " + API_BASE);
    return;
  }

  Serial.println("Unknown command. Type HELP.");
}

void connectWiFi() {
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  Serial.print("Connecting to WiFi");
  int retries = 0;
  while (WiFi.status() != WL_CONNECTED && retries < 40) {
    delay(500);
    Serial.print(".");
    retries++;
  }
  Serial.println();

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("WiFi connected");
    Serial.println("IP: " + WiFi.localIP().toString());
  } else {
    Serial.println("WiFi connection failed");
  }
}

void postTapEvent(const String& passengerId, const String& uid) {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi not connected. Reconnecting...");
    connectWiFi();
    if (WiFi.status() != WL_CONNECTED) {
      Serial.println("Still offline. Tap not sent.");
      return;
    }
  }

  HTTPClient http;

  String endpoint = tapInMode ? "/payments/tap-in" : "/payments/tap-out";
  String url = API_BASE + endpoint;

  String payload = "{";
  payload += "\"user_id\":\"" + passengerId + "\",";
  payload += "\"bus_id\":\"" + BUS_ID + "\",";
  payload += "\"driver_id\":\"" + DRIVER_ID + "\",";
  payload += "\"station_id\":" + String(STATION_ID) + ",";
  payload += "\"card_uid\":\"" + uid + "\"";
  payload += "}";

  http.begin(url);
  http.addHeader("Content-Type", "application/json");

  Serial.println("\nSending " + String(tapInMode ? "TAP-IN" : "TAP-OUT") + " request...");
  Serial.println("URL: " + url);
  Serial.println("Payload: " + payload);

  int httpCode = http.POST(payload);
  String response = http.getString();

  Serial.println("HTTP Code: " + String(httpCode));
  Serial.println("Response: " + response);

  http.end();
}

void setup() {
  Serial.begin(115200);
  delay(500);

  Serial.println("\n=== ESP32 RC522 Tap-In/Tap-Out ===");

  SPI.begin();
  mfrc522.PCD_Init();
  Serial.println("RC522 initialized");

  connectWiFi();
  printStatus();
  printHelp();

  Serial.println("Scan RFID card now...");
}

void loop() {
  handleSerialCommands();

  if (!mfrc522.PICC_IsNewCardPresent()) return;
  if (!mfrc522.PICC_ReadCardSerial()) return;

  String uid = bytesToHexString(mfrc522.uid.uidByte, mfrc522.uid.size);
  unsigned long now = millis();

  // local anti-bounce (2 sec)
  if (uid == lastUid && (now - lastScanMillis) < 2000) {
    mfrc522.PICC_HaltA();
    mfrc522.PCD_StopCrypto1();
    return;
  }

  lastUid = uid;
  lastScanMillis = now;

  Serial.println("\nCard UID: " + uid);

  String passengerId = lookupPassengerId(uid);
  if (passengerId.length() == 0) {
    Serial.println("Card not mapped to passenger. Add UID in cardMaps[]");
  } else {
    Serial.println("Passenger ID: " + passengerId);
    postTapEvent(passengerId, uid);
  }

  mfrc522.PICC_HaltA();
  mfrc522.PCD_StopCrypto1();
  delay(300);
}
