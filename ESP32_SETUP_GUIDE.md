# ESP32 NFC Reader Setup Guide

**Device:** ESP32 with RC522 RFID Module  
**Backend IP:** 192.168.5.31  
**Date:** March 1, 2026

---

## 📋 What You Need

### Hardware:
- ✅ ESP32 Development Board
- ✅ RC522 RFID Module
- ✅ Micro-USB cable (for programming ESP32)
- ✅ 7 Jumper wires (Female-to-Female or Male-to-Female)
- ✅ NFC cards/tags for testing

### Software:
- Arduino IDE (Download: https://www.arduino.cc/en/software)
- ESP32 Board Support Package
- Required Libraries: MFRC522

---

## 🔌 Step 1: Wire the RC522 to ESP32

**IMPORTANT:** Use 3.3V power, NOT 5V!

| RC522 Pin | ESP32 GPIO | Wire Color (Suggested) |
|-----------|------------|------------------------|
| SDA (SS)  | GPIO 5     | Yellow                 |
| SCK       | GPIO 18    | Green                  |
| MOSI      | GPIO 23    | Blue                   |
| MISO      | GPIO 19    | Purple                 |
| RST       | GPIO 22    | Orange                 |
| GND       | GND        | Black                  |
| 3.3V      | 3.3V       | Red                    |

**Visual Check:**
```
RC522 Module          ESP32 Board
[SDA]────────────────→ [GPIO 5]
[SCK]────────────────→ [GPIO 18]
[MOSI]───────────────→ [GPIO 23]
[MISO]───────────────→ [GPIO 19]
[RST]────────────────→ [GPIO 22]
[GND]────────────────→ [GND]
[3.3V]───────────────→ [3.3V]
```

---

## 💻 Step 2: Install Arduino IDE

1. **Download Arduino IDE**
   - Visit: https://www.arduino.cc/en/software
   - Download Windows installer (.exe)
   - Run installer and follow prompts

2. **Install ESP32 Board Support**
   - Open Arduino IDE
   - Go to `File → Preferences`
   - Find "Additional Board Manager URLs"
   - Add this URL:
     ```
     https://dl.espressif.com/dl/package_esp32_index.json
     ```
   - Click OK
   - Go to `Tools → Board → Boards Manager`
   - Search for "esp32"
   - Install "esp32 by Espressif Systems"
   - Wait for installation to complete

3. **Install MFRC522 Library**
   - Go to `Sketch → Include Library → Manage Libraries`
   - Search for "MFRC522"
   - Install "MFRC522 by GithubCommunity"

---

## 🔧 Step 3: Configure Your ESP32

### A. Connect ESP32 to Computer
1. Connect ESP32 to your Windows PC using micro-USB cable
2. Windows may install drivers automatically
3. Check Device Manager (`Win + X → Device Manager`)
4. Look under "Ports (COM & LPT)" for "Silicon Labs CP210x" or similar
5. Note the COM port number (e.g., COM3, COM4, COM5)

### B. Configure Arduino IDE
1. Go to `Tools → Board → ESP32 Arduino → ESP32 Dev Module`
2. Go to `Tools → Port → COMx` (select your COM port)
3. Set `Tools → Upload Speed → 115200`

---

## ⚙️ Step 4: Update ESP32 Sketch Configuration

Open the file: `esp32_rc522_tap/esp32_rc522_tap.ino`

**You need to update these lines:**

```cpp
// Line 8-9: Update with YOUR WiFi credentials
const char* WIFI_SSID = "YOUR_WIFI_NAME";        // ← Change this
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD"; // ← Change this

// Line 14: Already configured for your PC
String API_BASE = "http://192.168.5.31:8000";    // ✅ Already set!
```

### Example Configuration:
If your WiFi name is "HomeNetwork" and password is "MyPassword123":
```cpp
const char* WIFI_SSID = "HomeNetwork";
const char* WIFI_PASSWORD = "MyPassword123";
String API_BASE = "http://192.168.5.31:8000";  // Your backend IP
```

---

## 📤 Step 5: Upload to ESP32

1. **Open the Sketch**
   - In Arduino IDE: `File → Open`
   - Navigate to: `C:\Users\Win11\Documents\GitHub\peakmap2.0\esp32_rc522_tap\esp32_rc522_tap.ino`

2. **Verify Configuration**
   - Double-check WiFi credentials
   - Verify API_BASE is "http://192.168.5.31:8000"

3. **Compile the Sketch**
   - Click the checkmark (✓) button or press `Ctrl+R`
   - Wait for "Done compiling"
   - Fix any errors if they appear

4. **Upload to ESP32**
   - Click the right arrow (→) button or press `Ctrl+U`
   - Wait for "Connecting...." message
   - If stuck, press and hold the BOOT button on ESP32
   - Wait for "Leaving... Hard resetting via RTS pin..."
   - Success message: "Done uploading."

---

## 🔍 Step 6: Test the Connection

1. **Open Serial Monitor**
   - Go to `Tools → Serial Monitor`
   - Set baud rate to **115200** (bottom-right dropdown)

2. **Expected Output:**
   ```
   === ESP32 RC522 Tap-In/Tap-Out ===
   RC522 initialized
   Connecting to WiFi.........
   WiFi connected
   IP: 192.168.5.xxx
   
   === Current Config ===
   Mode      : TAP-IN
   Station   : 1
   Bus       : BUS-01
   Driver    : DR-01
   API Base  : http://192.168.5.31:8000
   WiFi IP   : 192.168.5.xxx
   ======================
   
   === Commands ===
   IN                 -> Set mode to Tap-In
   OUT                -> Set mode to Tap-Out
   STATION <id>       -> Set station id
   BUS <id>           -> Set bus id
   DRIVER <id>        -> Set driver id
   SERVER <url>       -> Set API base
   STATUS             -> Show current config
   HELP               -> Show commands
   
   Scan RFID card now...
   ```

3. **If WiFi Connection Fails:**
   - Check WiFi credentials (case-sensitive!)
   - Ensure WiFi is 2.4GHz (ESP32 doesn't support 5GHz)
   - Move ESP32 closer to router

---

## 🧪 Step 7: Test NFC Card Reading

1. **Make Sure Backend is Running:**
   ```powershell
   cd peak-map-backend
   python run_server.py
   ```
   Backend should show: `Uvicorn running on http://0.0.0.0:8000`

2. **Scan an NFC Card:**
   - Hold an NFC card/tag near the RC522 module
   - Watch the Serial Monitor

3. **Expected Output:**
   ```
   Card UID: A1B2C3D4
   Passenger ID: bb6e65b6-1cc5-4b63-8b99-0c80f86e0b9b
   
   Sending TAP-IN request...
   URL: http://192.168.5.31:8000/payments/tap-in
   Payload: {"user_id":"bb6e65b6-1cc5-4b63-8b99-0c80f86e0b9b","bus_id":"BUS-01","driver_id":"DR-01","station_id":1,"card_uid":"A1B2C3D4"}
   HTTP Code: 200
   Response: {"status":"success",...}
   ```

4. **If Card Not Found:**
   - Note the card UID shown (e.g., "12345678")
   - Add it to the cardMaps array in the sketch:
   ```cpp
   CardMap cardMaps[] = {
     {"A1B2C3D4", "bb6e65b6-1cc5-4b63-8b99-0c80f86e0b9b"},
     {"11223344", "PASSENGER-002"},
     {"12345678", "YOUR-NEW-PASSENGER-ID"}  // ← Add your card
   };
   ```
   - Re-upload the sketch

---

## 🎮 Serial Commands

You can configure the ESP32 in real-time via Serial Monitor:

| Command | Example | Description |
|---------|---------|-------------|
| `IN` | `IN` | Set mode to Tap-In |
| `OUT` | `OUT` | Set mode to Tap-Out |
| `STATION <id>` | `STATION 5` | Change station ID |
| `BUS <id>` | `BUS BUS-07` | Change bus ID |
| `DRIVER <id>` | `DRIVER DR-22` | Change driver ID |
| `SERVER <url>` | `SERVER http://192.168.5.31:8000` | Change API base |
| `STATUS` | `STATUS` | Show current config |
| `HELP` | `HELP` | Show commands |

---

## 🐛 Troubleshooting

### Problem: ESP32 not detected in Arduino IDE
**Solution:**
- Install CP210x USB driver: https://www.silabs.com/developers/usb-to-uart-bridge-vcp-drivers
- Try different USB cable (some are charge-only)
- Try different USB port

### Problem: "Failed to connect to ESP32"
**Solution:**
- Press and hold BOOT button during upload
- Check proper COM port selected
- Close Serial Monitor before uploading

### Problem: "RC522 initialization failed"
**Solution:**
- Double-check wiring (especially SDA → GPIO 5)
- Ensure RC522 is powered by 3.3V, NOT 5V
- Try reseating the wires

### Problem: "WiFi connection failed"
**Solution:**
- Verify WiFi credentials (case-sensitive!)
- Use 2.4GHz WiFi only (not 5GHz)
- Move closer to router
- Check router allows new devices

### Problem: "HTTP POST fails / Timeout"
**Solution:**
- Verify backend is running: `python run_server.py`
- Check API_BASE matches your IP: `http://192.168.5.31:8000`
- Ensure ESP32 and PC are on same WiFi network
- Check Windows Firewall isn't blocking port 8000

### Problem: "Card not recognized"
**Solution:**
- Check serial output for card UID
- Add UID to cardMaps array in sketch
- Make sure card is NFC/RFID compatible (13.56MHz)

---

## ✅ Verification Checklist

- [ ] Hardware wired correctly (RC522 to ESP32)
- [ ] Arduino IDE installed with ESP32 support
- [ ] MFRC522 library installed
- [ ] ESP32 connected to PC via USB
- [ ] Correct COM port selected in Arduino IDE
- [ ] WiFi credentials updated in sketch
- [ ] API_BASE set to http://192.168.5.31:8000
- [ ] Sketch compiled without errors
- [ ] Sketch uploaded successfully
- [ ] Serial Monitor shows WiFi connected
- [ ] Backend server is running
- [ ] NFC card detected and UID shown
- [ ] HTTP POST to backend successful

---

## 🎯 Quick Reference

**Your Configuration:**
```
WiFi SSID:     [Enter your WiFi name]
WiFi Password: [Enter your password]
Backend URL:   http://192.168.5.31:8000
COM Port:      COM[?] (check Device Manager)
Baud Rate:     115200
```

**Backend Commands:**
```powershell
cd peak-map-backend
python run_server.py
```

**Test the System:**
1. Start backend server
2. Power on ESP32 (via USB)
3. Open Serial Monitor (115200 baud)
4. Wait for WiFi connection
5. Scan NFC card
6. Check Serial Monitor for HTTP response
7. Check admin dashboard for real-time updates

---

## 📞 Need More Help?

- Check wiring diagram above
- Review troubleshooting section
- Ensure all software is installed
- Verify backend is running and accessible

**Common Issue:** ESP32 and PC must be on the **same WiFi network**!

---

✅ **You're all set!** Once configured, the ESP32 will automatically connect to WiFi and communicate with your backend whenever an NFC card is scanned.
