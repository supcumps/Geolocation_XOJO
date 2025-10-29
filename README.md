# 📍 GPS Location Tracker System

A complete real-time GPS tracking solution consisting of an iOS mobile app and a macOS web server. Track your location continuously, sync data over WiFi, and visualize your GPS tracks on an interactive web map.

![System Status](https://img.shields.io/badge/Status-Operational-brightgreen)
![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20macOS-blue)
![Language](https://img.shields.io/badge/Language-Xojo-orange)

---

## 🎯 System Overview

The system consists of two main components:

1. **iOS Mobile App** - Captures GPS location data and syncs to server
2. **macOS Server** - Receives, stores, and visualizes location data via web interface

### Architecture Flow

```
┌─────────────────┐
│   iPhone App    │
│                 │
│  GPS Tracking   │ ──┐
│  Data Storage   │   │
│  Auto-Sync      │   │
└─────────────────┘   │
                      │ HTTP POST
                      │ (JSON over WiFi)
                      ▼
              ┌───────────────┐
              │  macOS Server │
              │               │
              │  HTTP Server  │
              │  SQLite DB    │
              │  Map Viewer   │
              └───────────────┘
                      │
                      │ HTTP GET
                      ▼
              ┌───────────────┐
              │  Web Browser  │
              │               │
              │ Interactive   │
              │   Map View    │
              └───────────────┘
```

---

## 📱 iOS Mobile App

### Purpose
Continuously captures GPS location data, stores it locally, and automatically syncs to the server every 10 seconds.

### Key Features
- ✅ Continuous background GPS tracking
- ✅ Automatic sync every 10 seconds (configurable)
- ✅ Manual "Sync Now" button
- ✅ Queue management (stores data when offline)
- ✅ Start/Stop tracking controls
- ✅ Real-time status updates

### Classes & Components

#### **1. LocationTracker**
*Main tracking and sync coordinator*

**Purpose:** Manages GPS data collection, queuing, and server synchronization.

**Properties:**
- `mSessionID` - Unique session identifier (e.g., "session_1761694500")
- `mLastSyncTime` - Timestamp of last successful sync
- `mPendingLocations()` - Array of Dictionary objects holding unsent GPS data
- `mAutoSyncTimer` - Timer that triggers automatic sync every 10 seconds
- `mIsSyncing` - Boolean flag to prevent concurrent syncs

**Methods:**

##### `Constructor()`
Initializes the tracker with a new session ID and starts the auto-sync timer.
```xojo
Sub Constructor()
  mLastSyncTime = DateTime.Now.SecondsFrom1970
  mSessionID = "session_" + mLastSyncTime.ToString
  mAutoSyncTimer = New AutoSyncTimer
  mAutoSyncTimer.Period = 10000 ' 10 seconds
  mAutoSyncTimer.RunMode = Timer.RunModes.Multiple
  AddHandler mAutoSyncTimer.Tick, WeakAddressOf HandleAutoSync
End Sub
```

##### `AddLocationData(timestamp, lat, lon, alt, spd)`
Stores a new GPS reading in the pending queue.
```xojo
Sub AddLocationData(timestamp As DateTime, lat As Double, lon As Double, 
                     alt As Double, spd As Double)
  Var locationData As New Dictionary
  locationData.Value("timestamp") = timestamp.SecondsFrom1970
  locationData.Value("latitude") = lat
  locationData.Value("longitude") = lon
  locationData.Value("altitude") = alt
  locationData.Value("speed") = spd
  locationData.Value("session_id") = mSessionID
  mPendingLocations.Add(locationData)
End Sub
```

##### `StartTracking()`
Starts the auto-sync timer and notifies the UI.
```xojo
Sub StartTracking()
  If mAutoSyncTimer <> Nil Then
    mAutoSyncTimer.RunMode = Timer.RunModes.Multiple
  End If
  RaiseEvent StatusChanged(Self, 1)
End Sub
```

##### `StopTracking()`
Stops auto-sync, performs final sync, and notifies the UI.
```xojo
Sub StopTracking()
  If mAutoSyncTimer <> Nil Then
    mAutoSyncTimer.RunMode = Timer.RunModes.Off
  End If
  If mPendingLocations.Count > 0 Then
    SyncToServer
  End If
  RaiseEvent StatusChanged(Self, 0)
End Sub
```

##### `SyncToServer()`
Sends all pending locations to the server via HTTP POST.
```xojo
Sub SyncToServer()
  If mIsSyncing Then Return
  mIsSyncing = True
  
  ' Convert pending locations to JSON
  Var payload As New Dictionary
  payload.Value("session_id") = mSessionID
  payload.Value("locations") = mPendingLocations
  Var payloadJSON As New JSONItem(payload)
  
  ' Send HTTP POST request
  Var socket As New URLConnection
  socket.RequestHeader("Content-Type") = "application/json"
  socket.SetRequestContent(payloadJSON.ToString, "application/json")
  Var response As String = socket.SendSync("POST", kServerURL, 30)
  
  If socket.HTTPStatusCode = 200 Then
    mPendingLocations.RemoveAll  ' Clear sent data
    RaiseEvent StatusChanged(Self, 2)
  End If
  
  mIsSyncing = False
End Sub
```

##### `SetAutoSyncInterval(seconds)`
Changes the auto-sync frequency (5-300 seconds).
```xojo
Sub SetAutoSyncInterval(seconds As Integer)
  If seconds < 5 Then seconds = 5
  If seconds > 300 Then seconds = 300
  mAutoSyncTimer.Period = seconds * 1000
End Sub
```

**Events:**
- `LocationUpdated(sender, timestamp, lat, lon, alt, spd)` - Fired when new GPS data is added
- `StatusChanged(sender, status)` - Fired when tracking state changes (0=stopped, 1=started, 2=synced)
- `SyncFailed(errorMessage)` - Fired when sync encounters an error

**Constants:**
- `kServerURL = "http://[Your IP address for the server]:8080/location"` - Server endpoint

---

#### **2. AutoSyncTimer**
*Custom Timer subclass for iOS compatibility*

**Purpose:** Wraps the iOS Timer to provide a custom event handler that works with AddHandler.

**Inherits From:** Timer

**Events:**
- `Run()` - Built-in Timer event (fires based on Period)
- `Tick()` - Custom event that can be used with AddHandler

**Implementation:**
```xojo
Class AutoSyncTimer
Inherits Timer

  Event Run()
    RaiseEvent Tick
  End Event
  
  Event Tick()
  ' Custom event hook
  
End Class
```

**Why This Exists:** iOS Timer doesn't support AddHandler with its built-in Run event, so this custom class creates a Tick event that can be used with AddHandler.

---

#### **3. TrackingScreen (Main View)**
*User interface for tracking control*

**Purpose:** Provides UI for starting/stopping tracking and displaying status.

**UI Controls:**
- `StartButton` - Begins GPS tracking
- `StopButton` - Ends GPS tracking
- `SyncButton` - Manual sync trigger
- `StatusLabel` - Shows current status (Active/Stopped/Syncing)
- `PendingLabel` - Shows number of locations waiting to sync

**Properties:**
- `mTracker` - Instance of LocationTracker
- `mLocationManager` - iOS MobileLocationManager for GPS access

**Key Methods:**

##### `Opening()`
Initialize tracker and location manager when screen opens.
```xojo
Sub Opening()
  ' Create tracker once
  mTracker = New LocationTracker
  AddHandler mTracker.LocationUpdated, AddressOf HandleLocationUpdated
  AddHandler mTracker.StatusChanged, AddressOf HandleStatusChanged
  
  ' Setup location manager
  mLocationManager = New MobileLocationManager
  mLocationManager.DesiredAccuracy = MobileLocationManager.Accuracies.Best
  mLocationManager.DistanceFilter = 5  ' Meters
  AddHandler mLocationManager.LocationChanged, AddressOf HandleLocationChanged
End Sub
```

##### `StartButton_Pressed()`
Starts GPS tracking and auto-sync.
```xojo
Sub StartButton_Pressed()
  If mTracker <> Nil Then
    mLocationManager.RequestLocation()
    mTracker.StartTracking()
    StartButton.Enabled = False
    StopButton.Enabled = True
    StatusLabel.Text = "Active"
  End If
End Sub
```

##### `StopButton_Pressed()`
Stops GPS tracking (performs final sync).
```xojo
Sub StopButton_Pressed()
  If mTracker <> Nil Then
    mTracker.StopTracking()
    StopButton.Enabled = False
    StartButton.Enabled = True
    StatusLabel.Text = "Stopped"
  End If
End Sub
```

##### `SyncButton_Pressed()`
Manually triggers sync immediately.
```xojo
Sub SyncButton_Pressed()
  If mTracker <> Nil Then
    mTracker.SyncToServer()
  End If
End Sub
```

##### `HandleLocationChanged(newLocation)`
Receives GPS updates from iOS and adds them to tracker.
```xojo
Sub HandleLocationChanged(newLocation As MobileLocation)
  If mTracker <> Nil Then
    mTracker.AddLocationData(
      DateTime.Now,
      newLocation.Latitude,
      newLocation.Longitude,
      newLocation.Altitude,
      newLocation.Speed
    )
  End If
End Sub
```

##### `HandleStatusChanged(sender, status)`
Updates UI based on tracker status.
```xojo
Sub HandleStatusChanged(sender As LocationTracker, status As Integer)
  Select Case status
  Case 0  ' Stopped
    StatusLabel.Text = "Stopped"
    StatusLabel.TextColor = Color.Red
  Case 1  ' Started
    StatusLabel.Text = "Active"
    StatusLabel.TextColor = Color.Green
  Case 2  ' Synced
    StatusLabel.Text = "Synced ✓"
  End Select
End Sub
```

---

### Data Format

**JSON Payload Sent to Server:**
```json
{
  "session_id": "session_1761694500",
  "locations": [
    {
      "timestamp": 1761694500.123,
      "latitude": -26.450012,
      "longitude": 152.875500,
      "altitude": 165.8983,
      "speed": 0.7180318,
      "session_id": "session_1761694500"
    },
    {
      "timestamp": 1761694501.456,
      "latitude": -26.450020,
      "longitude": 152.875510,
      "altitude": 166.1234,
      "speed": 0.8234567,
      "session_id": "session_1761694500"
    }
  ]
}
```

---

## 🖥️ macOS Server

### Purpose
Receives GPS data from mobile clients, stores it in a SQLite database, and serves an interactive web-based map viewer.

### Key Features
- ✅ HTTP server on port 8080
- ✅ RESTful API endpoints
- ✅ SQLite database storage
- ✅ Real-time web map visualization
- ✅ GeoJSON API for location data
- ✅ Session-based data organization

### Classes & Components

#### **1. App**
*Main application and HTTP server*

**Purpose:** Handles HTTP requests and routes them to appropriate handlers.

**Properties:**
- `mDBManager` - Instance of ServerDatabaseManager
- `mHTTPServer` - Built-in Xojo HTTP server

**Key Methods:**

##### `Opening()`
Initialize database and start HTTP server.
```xojo
Sub Opening()
  mDBManager = New ServerDatabaseManager
  mDBManager.InitializeDatabase()
  
  ' Server automatically starts listening on port 8080
  System.DebugLog("Server started on port 8080")
End Sub
```

##### `HandleURL(request, response) As Boolean`
Main request router - handles all incoming HTTP requests.

**Routes:**

**POST /location** - Receive GPS data from mobile app
```xojo
If method = "POST" Then
  ' Parse JSON body
  Var json As New JSONItem(request.Body)
  Var sessionID As String = json.Value("session_id")
  Var locations As JSONItem = json.Value("locations")
  
  ' Save each location to database
  For i = 0 To locations.Count - 1
    Var loc As JSONItem = locations.ValueAt(i)
    Var timestampDouble As Double = loc.Value("timestamp")
    Var dt As New DateTime(timestampDouble)
    Var timestamp As String = dt.SQLDateTime
    
    mDBManager.AddLocation(
      sessionID,
      timestamp,
      loc.Value("latitude"),
      loc.Value("longitude"),
      loc.Value("altitude"),
      loc.Value("speed")
    )
  Next
  
  response.Status = 200
  response.Write("{""status"":""success"",""count"":" + count.ToString + "}")
  Return True
End If
```

**GET /?page=map** - Serve interactive map viewer
```xojo
If query.IndexOf("page=map") >= 0 Then
  response.Status = 200
  response.MIMEType = "text/html"
  response.Write(GetMapViewerHTML())
  Return True
End If
```

**GET /?api=locations&limit=100** - Return location data as GeoJSON
```xojo
If query.IndexOf("api=locations") >= 0 Then
  ' Parse limit parameter (default 100)
  Var limit As Integer = 100
  ' ... parse limit from query string ...
  
  Var locations As JSONItem = mDBManager.GetRecentLocations(limit)
  response.Status = 200
  response.MIMEType = "application/json"
  response.Write(locations.ToString)
  Return True
End If
```

**GET /** - API info (default route)
```xojo
' Default route - return API info
Var info As New JSONItem
info.Value("status") = "online"
info.Value("service") = "Location Tracking Server"
info.Value("version") = "1.0.0"
info.Value("endpoints") = ["POST /location", "GET /?api=locations", "GET /?page=map"]

response.Status = 200
response.MIMEType = "application/json"
response.Write(info.ToString)
Return True
```

##### `GetMapViewerHTML() As String`
Generates complete HTML page for interactive map viewer.
```xojo
Function GetMapViewerHTML() As String
  ' Returns complete HTML with:
  ' - Leaflet.js for mapping
  ' - JavaScript for fetching and displaying GPS data
  ' - Auto-refresh every 10 seconds
  ' - Session filtering
  ' - Interactive markers and paths
  Return "<html>...</html>"
End Function
```

---

#### **2. ServerDatabaseManager**
*SQLite database management*

**Purpose:** Handles all database operations for storing and retrieving location data.

**Properties:**
- `mDatabase` - SQLiteDatabase instance
- `mDatabaseFile` - FolderItem pointing to database file

**Database Location:**
```
/Users/[username]/Library/Application Support/LocationTracker/locations.sqlite
```

**Schema:**

**Table: Locations**
```sql
CREATE TABLE Locations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL,
    timestamp TEXT NOT NULL,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    altitude REAL,
    speed REAL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
)
```

**Methods:**

##### `InitializeDatabase()`
Creates database file and tables if they don't exist.
```xojo
Sub InitializeDatabase()
  ' Get or create database folder
  Var appSupportFolder As FolderItem = SpecialFolder.ApplicationSupport
  Var dbFolder As FolderItem = appSupportFolder.Child("LocationTracker")
  If Not dbFolder.Exists Then
    dbFolder.CreateFolder()
  End If
  
  ' Connect to database
  mDatabaseFile = dbFolder.Child("locations.sqlite")
  mDatabase = New SQLiteDatabase
  mDatabase.DatabaseFile = mDatabaseFile
  mDatabase.Connect()
  
  ' Create tables
  Var sql As String = "CREATE TABLE IF NOT EXISTS Locations (...)"
  mDatabase.ExecuteSQL(sql)
End Sub
```

##### `AddLocation(sessionID, timestamp, lat, lon, alt, spd)`
Inserts a new location record into the database.
```xojo
Sub AddLocation(sessionID As String, timestamp As String, lat As Double, 
                 lon As Double, alt As Double, spd As Double)
  Try
    Var sql As String = "INSERT INTO Locations " + _
      "(session_id, timestamp, latitude, longitude, altitude, speed) " + _
      "VALUES ('" + sessionID + "', '" + timestamp + "', " + _
      lat.ToString + ", " + lon.ToString + ", " + _
      alt.ToString + ", " + spd.ToString + ")"
    
    mDatabase.ExecuteSQL(sql)
    
    ' Verify insertion
    Var rs As RowSet = mDatabase.SelectSQL("SELECT COUNT(*) FROM Locations")
    System.DebugLog("Total records: " + rs.Column("count").StringValue)
    
  Catch e As DatabaseException
    System.DebugLog("Database error: " + e.Message)
  End Try
End Sub
```

##### `GetRecentLocations(limit As Integer) As JSONItem`
Retrieves location data formatted as GeoJSON for mapping.
```xojo
Function GetRecentLocations(limit As Integer) As JSONItem
  Var geojson As New JSONItem
  geojson.Value("type") = "FeatureCollection"
  Var features() As Variant
  
  Try
    Var sql As String = "SELECT * FROM Locations " + _
                        "ORDER BY id DESC LIMIT " + limit.ToString
    Var rs As RowSet = mDatabase.SelectSQL(sql)
    
    While Not rs.AfterLastRow
      ' Create GeoJSON feature for each location
      Var feature As New Dictionary
      feature.Value("type") = "Feature"
      
      ' Geometry (Point with [longitude, latitude])
      Var geometry As New Dictionary
      geometry.Value("type") = "Point"
      Var coordinates() As Variant
      coordinates.Add(rs.Column("longitude").DoubleValue)  ' Lon first!
      coordinates.Add(rs.Column("latitude").DoubleValue)   ' Lat second!
      geometry.Value("coordinates") = coordinates
      feature.Value("geometry") = geometry
      
      ' Properties
      Var properties As New Dictionary
      properties.Value("id") = rs.Column("id").IntegerValue
      properties.Value("session_id") = rs.Column("session_id").StringValue
      properties.Value("timestamp") = rs.Column("timestamp").StringValue
      properties.Value("latitude") = rs.Column("latitude").DoubleValue
      properties.Value("longitude") = rs.Column("longitude").DoubleValue
      properties.Value("altitude") = rs.Column("altitude").DoubleValue
      properties.Value("speed") = rs.Column("speed").DoubleValue
      feature.Value("properties") = properties
      
      features.Add(feature)
      rs.MoveToNextRow
    Wend
    
    geojson.Value("features") = features
    
  Catch e As DatabaseException
    System.DebugLog("Error: " + e.Message)
  End Try
  
  Return geojson
End Function
```

**GeoJSON Output Format:**
```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [152.875500, -26.450012]
      },
      "properties": {
        "id": 5,
        "session_id": "session_1761694500",
        "timestamp": "2025-10-29 09:34:57",
        "latitude": -26.450012,
        "longitude": 152.875500,
        "altitude": 165.8983,
        "speed": 0.7180318
      }
    }
  ]
}
```

---

### Web Map Viewer

**Technology Stack:**
- **Leaflet.js** - Interactive mapping library
- **OpenStreetMap** - Map tile provider
- **Vanilla JavaScript** - Client-side logic

**Features:**
- 🗺️ Interactive pan and zoom
- 📍 GPS point markers (green=start, red=latest)
- 〰️ Colored path lines connecting points
- 🔄 Auto-refresh every 10 seconds
- 🎯 "Fit All" button to zoom to all points
- 📊 Statistics (total points, sessions, last update)
- 🔍 Session filtering dropdown
- 🔢 Point limit selector (100/500/1000)
- 💬 Click markers for details popup

**JavaScript Functions:**

##### `initMap()`
Initialize Leaflet map with OpenStreetMap tiles.
```javascript
function initMap() {
  map = L.map('map').setView([-26.45, 152.875], 15);
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '© OpenStreetMap',
    maxZoom: 19
  }).addTo(map);
  
  markersLayer = L.layerGroup().addTo(map);
  pathLayer = L.layerGroup().addTo(map);
  
  refreshData();
  setInterval(refreshData, 10000);  // Auto-refresh
}
```

##### `refreshData()`
Fetch location data from server API.
```javascript
async function refreshData() {
  const limit = document.getElementById('limit-select').value;
  const response = await fetch(`/?api=locations&limit=${limit}`);
  const geojson = await response.json();
  allLocations = geojson.features || [];
  updateMap();
  updateStats();
  updateSessionFilter();
}
```

##### `updateMap()`
Render GPS points and paths on the map.
```javascript
function updateMap() {
  markersLayer.clearLayers();
  pathLayer.clearLayers();
  
  // Group locations by session
  const sessionGroups = {};
  filteredLocations.forEach(f => {
    const sid = f.properties.session_id;
    if (!sessionGroups[sid]) sessionGroups[sid] = [];
    sessionGroups[sid].push(f);
  });
  
  // Draw colored paths for each session
  Object.keys(sessionGroups).forEach(sid => {
    const features = sessionGroups[sid];
    const coords = features.map(f => 
      [f.geometry.coordinates[1], f.geometry.coordinates[0]]
    );
    
    // Draw polyline path
    L.polyline(coords, {
      color: color,
      weight: 3,
      opacity: 0.7
    }).addTo(pathLayer);
    
    // Add markers
    features.forEach((f, i) => {
      const isFirst = i === 0;
      const isLast = i === features.length - 1;
      
      const marker = L.circleMarker([coords[1], coords[0]], {
        radius: isFirst || isLast ? 8 : 5,
        fillColor: isFirst ? '#48bb78' : (isLast ? '#f56565' : color),
        color: 'white',
        weight: 2,
        fillOpacity: 0.8
      });
      
      marker.bindPopup(`Details: ${f.properties.timestamp}...`);
      marker.addTo(markersLayer);
    });
  });
}
```

---

## 🔄 Data Flow

### 1. Location Capture (iPhone)
```
GPS Hardware
    ↓
MobileLocationManager
    ↓
TrackingScreen.HandleLocationChanged()
    ↓
LocationTracker.AddLocationData()
    ↓
Stored in mPendingLocations array
```

### 2. Auto-Sync Process (iPhone → Server)
```
AutoSyncTimer fires every 10 seconds
    ↓
LocationTracker.HandleAutoSync()
    ↓
LocationTracker.SyncToServer()
    ↓
Create JSON payload with all pending locations
    ↓
HTTP POST to http://[Your IP address for the server]:8080/location
    ↓
Clear mPendingLocations if successful
```

### 3. Server Processing (Server)
```
HTTP POST received
    ↓
App.HandleURL()
    ↓
Parse JSON body
    ↓
Extract session_id and locations array
    ↓
For each location:
    Convert timestamp (Double → DateTime → SQLDateTime)
    ↓
    ServerDatabaseManager.AddLocation()
    ↓
    INSERT INTO Locations table
    ↓
Return success response
```

### 4. Map Visualization (Browser)
```
Browser opens http://[Your IP address for the server]:8080/?page=map
    ↓
App.HandleURL() serves GetMapViewerHTML()
    ↓
JavaScript initMap() runs
    ↓
refreshData() fetches /?api=locations&limit=100
    ↓
App.HandleURL() returns GeoJSON
    ↓
ServerDatabaseManager.GetRecentLocations(100)
    ↓
SELECT * FROM Locations ORDER BY id DESC LIMIT 100
    ↓
Convert to GeoJSON format
    ↓
JavaScript updateMap() renders markers and paths
    ↓
Auto-refresh every 10 seconds
```

---

## 📊 API Reference

### POST /location

**Purpose:** Receive GPS location data from mobile clients

**Request:**
```http
POST /location HTTP/1.1
Content-Type: application/json

{
  "session_id": "session_1761694500",
  "locations": [
    {
      "timestamp": 1761694500.123,
      "latitude": -26.450012,
      "longitude": 152.875500,
      "altitude": 165.8983,
      "speed": 0.7180318,
      "session_id": "session_1761694500"
    }
  ]
}
```

**Response:**
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "status": "success",
  "count": 1
}
```

**Error Responses:**
- `400 Bad Request` - Invalid JSON or missing data
- `500 Internal Server Error` - Database error

---

### GET /?api=locations&limit=100

**Purpose:** Retrieve location data in GeoJSON format

**Request:**
```http
GET /?api=locations&limit=100 HTTP/1.1
```

**Query Parameters:**
- `limit` (optional) - Number of locations to return (default: 100, max: 10000)

**Response:**
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [152.875500, -26.450012]
      },
      "properties": {
        "id": 5,
        "session_id": "session_1761694500",
        "timestamp": "2025-10-29 09:34:57",
        "latitude": -26.450012,
        "longitude": 152.875500,
        "altitude": 165.8983,
        "speed": 0.7180318
      }
    }
  ]
}
```

---

### GET /?page=map

**Purpose:** Serve interactive web-based map viewer

**Request:**
```http
GET /?page=map HTTP/1.1
```

**Response:**
```http
HTTP/1.1 200 OK
Content-Type: text/html

<!DOCTYPE html>
<html>
  <!-- Complete HTML page with Leaflet.js map -->
</html>
```

---

### GET /

**Purpose:** Return API information (default route)

**Request:**
```http
GET / HTTP/1.1
```

**Response:**
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "status": "online",
  "service": "Location Tracking Server",
  "version": "1.0.0",
  "timestamp": "2025-10-29 10:50:17",
  "endpoints": [
    "POST /location",
    "GET /?api=locations&limit=100",
    "GET /?page=map"
  ]
}
```

---

## 🗄️ Database Schema

### Table: Locations

```sql
CREATE TABLE Locations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL,
    timestamp TEXT NOT NULL,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    altitude REAL,
    speed REAL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
)
```

**Columns:**
- `id` - Auto-incrementing primary key
- `session_id` - Tracking session identifier (e.g., "session_1761694500")
- `timestamp` - GPS reading time in SQL DateTime format (e.g., "2025-10-29 09:34:57")
- `latitude` - Decimal degrees (-90 to 90)
- `longitude` - Decimal degrees (-180 to 180)
- `altitude` - Meters above sea level
- `speed` - Meters per second
- `created_at` - Record insertion timestamp

**Indexes:**
```sql
CREATE INDEX idx_session_id ON Locations(session_id);
CREATE INDEX idx_timestamp ON Locations(timestamp);
```

**Example Query:**
```sql
-- Get all locations for a specific session
SELECT * FROM Locations 
WHERE session_id = 'session_1761694500' 
ORDER BY timestamp ASC;

-- Get the last 100 locations across all sessions
SELECT * FROM Locations 
ORDER BY id DESC 
LIMIT 100;

-- Count locations per session
SELECT session_id, COUNT(*) as count, 
       MIN(timestamp) as start_time, 
       MAX(timestamp) as end_time
FROM Locations 
GROUP BY session_id;
```

---

## 🚀 Setup Instructions

### iPhone App Setup

1. **Create Xojo iOS Project**
   - New Project → iOS App
   - Add `LocationTracker` class
   - Add `AutoSyncTimer` class
   - Add `TrackingScreen` view with UI controls

2. **Configure Location Permissions**
   - Add to Info.plist:
     ```xml
     <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
     <string>This app needs your location to track your GPS path</string>
     <key>NSLocationWhenInUseUsageDescription</key>
     <string>This app needs your location to track your GPS path</string>
     ```

3. **Update Server URL**
   - In `LocationTracker` class, set `kServerURL` to your Mac's IP:
     ```xojo
     Const kServerURL = "http://[Your IP address for the server]:8080/location"
     ```

4. **Build & Deploy**
   - Connect iPhone to Mac
   - Build → iOS Device
   - Install and run

### macOS Server Setup

1. **Create Xojo Console Project**
   - New Project → Console App
   - Change to Web App in build settings
   - Add `App` class
   - Add `ServerDatabaseManager` class

2. **Configure Port**
   - Server listens on port 8080 by default
   - Ensure firewall allows incoming connections

3. **Database Location**
   - Auto-creates at:
     ```
     ~/Library/Application Support/LocationTracker/locations.sqlite
     ```

4. **Build & Run**
   - Build → macOS
   - Run the executable
   - Server starts on port 8080

5. **Access Map Viewer**
   - Open browser: `http://localhost:8080/?page=map`
   - Or from other device: `http://[YOUR_MAC_IP]:8080/?page=map`

---

## 🔧 Configuration

### iPhone App Settings

**Auto-Sync Interval:**
```xojo
' Default: 10 seconds
' Change in LocationTracker.Constructor or call:
tracker.SetAutoSyncInterval(30)  ' Change to 30 seconds
```

**GPS Accuracy:**
```xojo
' In TrackingScreen.Opening():
mLocationManager.DesiredAccuracy = MobileLocationManager.Accuracies.Best
' Options: Best, NearestTenMeters, HundredMeters, Kilometer, ThreeKilometers
```

**Distance Filter:**
```xojo
' Minimum distance (meters) between location updates
mLocationManager.DistanceFilter = 5  ' Update every 5 meters
```

### Server Settings

**Port Number:**
```xojo
' In App.Opening():
' Port 8080 is default for Xojo Web apps
' Change in project settings if needed
```

**Database Location:**
```xojo
' In ServerDatabaseManager.InitializeDatabase():
Var dbFolder As FolderItem = SpecialFolder.ApplicationSupport.Child("LocationTracker")
' Change "LocationTracker" to your preferred folder name
```

**Map Refresh Rate:**
```javascript
// In GetMapViewerHTML():
setInterval(refreshData, 10000);  // 10 seconds
// Change 10000 to desired milliseconds
```

---

## 🐛 Troubleshooting

### iPhone App Issues

**"No data being synced"**
- ✅ Check WiFi connection
- ✅ Verify server IP address in `kServerURL`
- ✅ Ensure server is running
- ✅ Check iPhone console logs for errors

**"GPS not updating"**
- ✅ Enable Location Services in iPhone Settings
- ✅ Grant location permission to app
- ✅ Check `mLocationManager.DesiredAccuracy` setting
- ✅ Test outdoors for better GPS signal

**"App crashes on start/stop"**
- ✅ Ensure tracker is created in `Opening()` event
- ✅ Don't create multiple trackers
- ✅ Use `AddHandler` only once per event

### Server Issues

**"Database not saving records"**
- ✅ Check database file permissions
- ✅ Verify timestamp format conversion
- ✅ Check server logs for SQL errors
- ✅ Test with manual INSERT query

**"Map not loading"**
- ✅ Verify server is running on port 8080
- ✅ Check browser console for JavaScript errors
- ✅ Ensure database has location records
- ✅ Test API endpoint: `http://localhost:8080/?api=locations`

**"GeoJSON format errors"**
- ✅ Verify coordinates are [longitude, latitude] (lon first!)
- ✅ Check that all features have required properties
- ✅ Validate JSON structure

---

## 📈 Performance Considerations

### iPhone App
- **Battery Impact:** Continuous GPS tracking drains battery. Consider:
  - Reduce accuracy for less critical use cases
  - Increase distance filter to reduce updates
  - Stop tracking when stationary

- **Network Usage:** Minimal (10-20 KB per sync with ~50 points)

- **Storage:** Negligible (locations stored in memory until synced)

### Server
- **Database Growth:** ~100 bytes per location record
  - 1000 points/day = ~100 KB/day
  - 365,000 points/year = ~35 MB/year

- **Memory Usage:** Minimal (< 50 MB typical)

- **CPU Usage:** Negligible (< 1% when idle, < 5% during sync)

---

## 🎯 Future Enhancements

### Potential Features

**iOS App:**
- [ ] Background location tracking
- [ ] Low battery mode (reduced accuracy)
- [ ] Offline queue persistence (save to disk)
- [ ] Multiple server profiles
- [ ] Export data to GPX/KML
- [ ] Trip statistics (distance, duration, speed)

**Server:**
- [ ] User authentication
- [ ] Multiple user support
- [ ] Data export (CSV, GPX, KML)
- [ ] Distance calculation
- [ ] Speed graphs and charts
- [ ] Elevation profiles
- [ ] Heat maps
- [ ] Geofencing and alerts
- [ ] Historical playback
- [ ] Data cleanup/archival tools

**Map Viewer:**
- [ ] Dark mode
- [ ] Different map styles (satellite, terrain)
- [ ] Draw tools (measure distance, create areas)
- [ ] Print/export map images
- [ ] Share tracking links
- [ ] Live tracking mode
- [ ] Route optimization

---

## 📝 License

This project is provided as-is for educational and personal use.

---

## 🙋 Support

For questions or issues:
1. Check the troubleshooting section above
2. Review the code comments in each class
3. Test individual components (tracker, server, map) separately

---

## 📚 Technologies Used

- **Xojo** - Cross-platform development framework
- **iOS SDK** - CoreLocation framework (via Xojo)
- **SQLite** - Embedded database
- **HTTP/REST** - Client-server communication
- **JSON** - Data serialization format
- **GeoJSON** - Geographic data format
- **Leaflet.js** - Interactive mapping library
- **OpenStreetMap** - Map tile provider

---

## ✅ System Requirements

**iPhone App:**
- iOS 14.0 or later
- iPhone with GPS capability
- WiFi connection to reach server

**macOS Server:**
- macOS 11.0 (Big Sur) or later
- Xojo 2024 or later
- Port 8080 available

**Web Browser (Map Viewer):**
- Modern browser with JavaScript enabled
- Chrome, Safari, Firefox, or Edge
- No special plugins required

---

## 🎉 Success Metrics

Your system is working correctly when:
- ✅ iPhone shows "Active" status when tracking
- ✅ Pending count increases as GPS points are captured
- ✅ Auto-sync occurs every 10 seconds (count resets to 0)
- ✅ Server logs show "✅ SAVED X LOCATIONS!"
- ✅ Database contains records (verify with DB Browser)
- ✅ Map displays GPS track with colored markers
- ✅ Map auto-refreshes with new data

---

**Built with ❤️ using Xojo**

*Last Updated: October 29, 2025*
