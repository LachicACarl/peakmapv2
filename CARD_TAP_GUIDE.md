# 🎫 RFID Card Tap Feature

## ✅ What's Working

Your system now **remembers card owners and balances** when you tap card **1603310630** (or any registered card).

## 🎯 Features

### 1. **Card Tap Endpoint**
When you tap a card, the system retrieves:
- **Card Owner Information** (name, email, user ID)
- **Current Balance** (in PHP)
- **Card Status** (active/blocked)
- **Last Tapped Time**

### 2. **API Endpoints**

#### GET Request
```bash
GET http://127.0.0.1:8000/rfid/cards/tap/1603310630
```

#### POST Request
```bash
POST http://127.0.0.1:8000/rfid/cards/tap?card_uid=1603310630
```

### 3. **Response Format**
```json
{
  "success": true,
  "message": "Card 1603310630 tapped successfully",
  "registered": true,
  "card": {
    "id": 1,
    "card_uid": "1603310630",
    "alias": "ali",
    "status": "active",
    "registered_at": "2026-03-08T14:00:00",
    "last_tapped_at": "2026-03-08T14:14:02"
  },
  "user": {
    "user_id": 5,
    "email": "lachicacarl14@gmail.com",
    "name": "carllachica"
  },
  "balance": {
    "amount": 500.0,
    "currency": "PHP",
    "formatted": "₱500.00"
  }
}
```

## 🚀 How to Use

### Method 1: PowerShell Command
```powershell
# Tap card and get info
$card = Invoke-RestMethod -Uri 'http://127.0.0.1:8000/rfid/cards/tap/1603310630' -Method Get

# Display results
Write-Host "Owner: $($card.user.name)"
Write-Host "Balance: $($card.balance.formatted)"
```

### Method 2: Web Interface
1. Open `card_tap_interface.html` in your browser
2. Enter card UID: **1603310630**
3. Click "Check Card"
4. See owner and balance information

### Method 3: ESP32 RFID Reader
Configure your ESP32 to call:
```cpp
String url = "http://192.168.5.31:8000/rfid/cards/tap/" + cardUID;
HTTPClient http;
http.begin(url);
int httpCode = http.GET();
if (httpCode == 200) {
  String response = http.getString();
  // Parse JSON response
}
```

## 💰 Balance Management

### Load Balance to Card
```powershell
$body = @{
  user_id = "5"
  amount = 500.00
  payment_method = "admin_nfc"
  card_id = "1603310630"
} | ConvertTo-Json

Invoke-RestMethod -Uri 'http://127.0.0.1:8000/payments/load-balance' `
  -Method Post -ContentType 'application/json' -Body $body
```

### Check Balance Only
```powershell
# Get balance for user
Invoke-RestMethod -Uri 'http://127.0.0.1:8000/payments/balance/5' -Method Get
```

## 📊 Current Card Status

**Card UID:** 1603310630
**Owner:** carllachica (lachicacarl14@gmail.com)
**Balance:** ₱500.00
**Status:** Active ✅

## 🔧 Testing Commands

### Test 1: Tap Card
```powershell
Invoke-RestMethod -Uri 'http://127.0.0.1:8000/rfid/cards/tap/1603310630' -Method Get | ConvertTo-Json -Depth 10
```

### Test 2: Load More Balance
```powershell
$body = @{ user_id = "5"; amount = 100.00; payment_method = "admin_nfc"; card_id = "1603310630" } | ConvertTo-Json
Invoke-RestMethod -Uri 'http://127.0.0.1:8000/payments/load-balance' -Method Post -ContentType 'application/json' -Body $body
```

### Test 3: Tap Again to See Updated Balance
```powershell
$tap = Invoke-RestMethod -Uri 'http://127.0.0.1:8000/rfid/cards/tap/1603310630' -Method Get
Write-Host "Balance: $($tap.balance.formatted)" -ForegroundColor Green
```

## 🎨 Web Interface

Open `card_tap_interface.html` for a beautiful web interface:

**Features:**
- ✨ Modern UI with gradient design
- 📡 Tap area that simulates physical card tap
- 💚 Real-time balance display
- 📧 Shows owner email and name
- 🔄 Auto-focus for quick scanning
- ⚡ Support for hardware RFID scanners

**How to Open:**
```bash
# Option 1: Double-click the file
# Option 2: Open in browser
start card_tap_interface.html

# Option 3: Use Live Server (VS Code extension)
# Right-click → Open with Live Server
```

## 🔗 Integration with ESP32

Add this to your ESP32 Arduino code:

```cpp
// After reading card UID
String cardUID = readCardUID();  // Your existing function

// Call tap endpoint
String url = "http://192.168.5.31:8000/rfid/cards/tap/" + cardUID;
HTTPClient http;
http.begin(url);
int httpCode = http.GET();

if (httpCode == 200) {
  String response = http.getString();
  
  // Parse JSON
  DynamicJsonDocument doc(2048);
  deserializeJson(doc, response);
  
  // Get data
  String ownerName = doc["user"]["name"];
  float balance = doc["balance"]["amount"];
  String status = doc["card"]["status"];
  
  // Display on LCD/OLED
  lcd.print("Owner: " + ownerName);
  lcd.setCursor(0, 1);
  lcd.print("Balance: P" + String(balance, 2));
  
  // Check if can board bus
  if (balance >= 50.00 && status == "active") {
    digitalWrite(GREEN_LED, HIGH);  // Grant access
    playSound(SUCCESS_TONE);
  } else {
    digitalWrite(RED_LED, HIGH);    // Deny access
    playSound(ERROR_TONE);
  }
}
```

## 📱 Mobile App Integration (Flutter)

```dart
Future<Map<String, dynamic>> tapCard(String cardUid) async {
  final response = await http.get(
    Uri.parse('http://192.168.5.31:8000/rfid/cards/tap/$cardUid'),
  );
  
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Card tap failed');
  }
}

// Usage
void scanCard() async {
  try {
    final data = await tapCard('1603310630');
    
    setState(() {
      ownerName = data['user']['name'];
      balance = data['balance']['amount'];
      cardStatus = data['card']['status'];
    });
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Card Tapped'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Owner: $ownerName'),
            Text('Balance: ₱${balance.toStringAsFixed(2)}'),
            Text('Status: $cardStatus'),
          ],
        ),
      ),
    );
  } catch (e) {
    print('Error: $e');
  }
}
```

## 🛠️ Backend Code Location

The card tap endpoint is implemented in:
```
peak-map-backend/app/routes/rfid.py
```

**Function:** `tap_card()` and `tap_card_get()`

## 🎯 What's Next?

1. **Add more cards** - Register additional cards for other users
2. **Integrate with ESP32** - Connect hardware RFID reader
3. **Add tap-in/tap-out** - Use this endpoint for bus boarding
4. **Real-time updates** - Add WebSocket notifications when cards are tapped

## 📞 Support

If you need to:
- Register a new card
- Load balance
- Check card status
- Block/unblock cards

Use the admin dashboard or contact system administrator.

---

**System Status:** ✅ Backend Running  
**Card Status:** ✅ 1603310630 Active  
**Balance:** ✅ ₱500.00 Loaded
