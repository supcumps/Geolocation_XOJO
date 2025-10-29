#tag Class
Protected Class App
Inherits WebApplication
	#tag Event
		Function HandleURL(request As WebRequest, response As WebResponse) As Boolean
		  
		  Var path As String = request.Path
		  Var query As String = request.QueryString
		  Var method As String = request.Method
		  
		  System.DebugLog("=== REQUEST ===")
		  System.DebugLog("Method: " + method)
		  System.DebugLog("Path: " + path)
		  System.DebugLog("Query: " + query)
		  
		  ' ========================================
		  ' ACCEPT ALL POST REQUESTS
		  ' ========================================
		  If method = "POST" Then
		    System.DebugLog("→ POST DETECTED - Processing location data")
		    
		    Try
		      Var body As String = request.Body
		      
		      If body = "" Then
		        System.DebugLog("❌ Empty body")
		        response.Status = 400
		        response.Write("{""error"":""No data""}")
		        Return True
		      End If
		      
		      Var bodyLen As String = body.Length.ToString
		      System.DebugLog("Body length: " + bodyLen)
		      
		      Var json As JSONItem
		      Try
		        json = New JSONItem(body)
		      Catch jsonError As RuntimeException
		        Var errMsg As String = jsonError.Message
		        System.DebugLog("❌ JSON parse error: " + errMsg)
		        response.Status = 400
		        response.Write("{""error"":""Invalid JSON""}")
		        Return True
		      End Try
		      
		      If json.HasKey("locations") Then
		        System.DebugLog("✅ Found locations array!")
		        
		        Var sessionID As String = json.Value("session_id")
		        Var locations As JSONItem = json.Value("locations")
		        Var locCount As String = locations.Count.ToString
		        
		        System.DebugLog("Session: " + sessionID)
		        System.DebugLog("Count: " + locCount)
		        
		        Var count As Integer = 0
		        Var i As Integer
		        For i = 0 To locations.Count - 1
		          Try
		            Var loc As JSONItem = locations.ValueAt(i)
		            
		            ' Convert timestamp properly
		            Var timestampDouble As Double = loc.Value("timestamp")
		            Var dt As New DateTime(timestampDouble)
		            Var timestamp As String = dt.SQLDateTime
		            
		            Var lat As Double = loc.Value("latitude")
		            Var lon As Double = loc.Value("longitude")
		            Var alt As Double = loc.Value("altitude")
		            Var spd As Double = loc.Value("speed")
		            Var n As Integer = (i+1)
		            
		            System.DebugLog("Location " + n.ToString + ": " + timestamp + " at " + lat.ToString + ", " + lon.ToString)
		            
		            mDBManager.AddLocation(sessionID, timestamp, lat, lon, alt, spd)
		            count = count + 1
		            
		          Catch locErr As RuntimeException
		            Var iStr As String = i.ToString
		            Var errMsg As String = locErr.Message
		            System.DebugLog("❌ Error at location " + iStr + ": " + errMsg)
		          End Try
		        Next
		        
		        Var countStr As String = count.ToString
		        System.DebugLog("✅ SAVED " + countStr + " LOCATIONS!")
		        
		        response.Status = 200
		        response.Write("{""status"":""success"",""count"":" + countStr + "}")
		        Return True
		        
		      Else
		        System.DebugLog("❌ No locations array in JSON")
		        response.Status = 400
		        response.Write("{""error"":""No locations data""}")
		        Return True
		      End If
		      
		    Catch e As RuntimeException
		      Var errMsg As String = e.Message
		      System.DebugLog("❌ Error processing POST: " + errMsg)
		      response.Status = 500
		      response.Write("{""error"":""Server error""}")
		      Return True
		    End Try
		  End If
		  
		  ' ========================================
		  ' GET /?page=map - MAP VIEWER
		  ' ========================================
		  If query.IndexOf("page=map") >= 0 Then
		    System.DebugLog("→ Serving map viewer")
		    response.Status = 200
		    response.MIMEType = "text/html"
		    response.Write(GetMapViewerHTML())
		    Return True
		  End If
		  
		  ' ========================================
		  ' GET /?api=locations - GEOJSON API
		  ' ========================================
		  If query.IndexOf("api=locations") >= 0 Then
		    System.DebugLog("→ Serving locations GeoJSON")
		    
		    ' Parse limit parameter (default 100)
		    Var limit As Integer = 100
		    Var limitPos As Integer = query.IndexOf("limit=")
		    If limitPos >= 0 Then
		      Var limitStr As String = query.Middle(limitPos + 6)
		      Var ampPos As Integer = limitStr.IndexOf("&")
		      If ampPos >= 0 Then
		        limitStr = limitStr.Left(ampPos)
		      End If
		      Try
		        limit = Val(limitStr)
		        If limit < 1 Then limit = 100
		        If limit > 10000 Then limit = 10000
		      Catch
		        limit = 100
		      End Try
		    End If
		    
		    System.DebugLog("   Limit: " + limit.ToString)
		    
		    Try
		      Var locations As JSONItem = mDBManager.GetRecentLocations(limit)
		      response.Status = 200
		      response.MIMEType = "application/json"
		      response.Write(locations.ToString)
		    Catch e As RuntimeException
		      Var errMsg As String = e.Message
		      System.DebugLog("Error getting locations: " + errMsg)
		      response.Status = 500
		      response.Write("{""error"":""Server error""}")
		    End Try
		    
		    Return True
		  End If
		  
		  ' ========================================
		  ' Default: API Info
		  ' ========================================
		  System.DebugLog("→ Sending default API info")
		  
		  Var info As New JSONItem
		  info.Value("status") = "online"
		  info.Value("service") = "Location Tracking Server"
		  info.Value("version") = "1.0.0"
		  info.Value("timestamp") = DateTime.Now.SQLDateTime
		  
		  Var endpoints() As String
		  endpoints.Add("POST /location")
		  endpoints.Add("GET /?api=locations&limit=100")
		  endpoints.Add("GET /?page=map")
		  
		  info.Value("endpoints") = endpoints
		  
		  response.Status = 200
		  response.MIMEType = "application/json"
		  response.Write(info.ToString)
		  
		  Return True
		  
		End Function
	#tag EndEvent

	#tag Event
		Sub Opening(args() As String)
		  // Sub Opening(args() As String)
		  ' Initialize the server
		  
		  ' Create database manager
		  mDBManager = New ServerDatabaseManager
		  mDBManager.InitDatabase
		  Call mDBManager.VerifyDatabaseConnection
		  
		  
		  ' Log startup
		  System.DebugLog("===========================================")
		  System.DebugLog("Location Tracker Server Started")
		  System.DebugLog("Port: " + Self.Port.ToString)
		  System.DebugLog("Time: " + DateTime.Now.ToString)
		  System.DebugLog("===========================================")
		  System.DebugLog("")
		  System.DebugLog("Available endpoints:")
		  System.DebugLog("  POST /?api=location")
		  System.DebugLog("  POST /location")
		  System.DebugLog("  GET  /?api=locations")
		  System.DebugLog("  GET  /?page=map")
		  System.DebugLog("")
		  
		  ' ServerSocket - don't set NetworkInterface to listen on ALL interfaces
		  Var socket As New ServerSocket
		  socket.Port = 8080
		  socket.MaximumSocketsConnected = 25
		  socket.MinimumSocketsAvailable = 2
		  socket.Listen
		  
		  ' Log what interface we're bound to
		  If socket.IsListening Then
		    System.DebugLog("✅ Server is listening!")
		    System.DebugLog("   Port: " + socket.Port.ToString)
		    If socket.NetworkInterface <> Nil Then
		      System.DebugLog("   Interface: " + socket.NetworkInterface.IPAddress)
		    Else
		      System.DebugLog("   Interface: ALL (0.0.0.0)")
		    End If
		    System.DebugLog("")
		    System.DebugLog("Access via:")
		    System.DebugLog("   http://127.0.0.1:8080")
		    System.DebugLog("   http://" +kServerURL+":8080")
		  Else
		    System.DebugLog("❌ Server failed to start listening!")
		  End If
		  
		  
		  
		  
		  ' IMPORTANT NOTE:
		  ' ===============
		  ' By NOT setting socket.NetworkInterface, the ServerSocket
		  ' will listen on ALL available network interfaces (0.0.0.0).
		  ' This is the correct behavior for allowing network access.
		  
		End Sub
	#tag EndEvent


	#tag Method, Flags = &h0
		Function GetLaunchFolder() As FolderItem
		  //Function GetLaunchFolder() As FolderItem
		  #If DebugBuild Then
		    // App.ExecutableFile.Parent = GeolocationTrackerServer.debug
		    // Parent.Parent = WebServer ✅
		    Return App.ExecutableFile.Parent.Parent
		  #Else
		    // Built app lives directly in WebServer
		    Return App.ExecutableFile.Parent
		  #EndIf
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function GetMapViewerHTML() As String
		  ' Returns complete HTML for the map viewer
		  
		  Return "<!DOCTYPE html>" + EndOfLine + _
		  "<html lang=""en"">" + EndOfLine + _
		  "<head>" + EndOfLine + _
		  "    <meta charset=""UTF-8"">" + EndOfLine + _
		  "    <meta name=""viewport"" content=""width=device-width, initial-scale=1.0"">" + EndOfLine + _
		  "    <title>Location Tracker Map</title>" + EndOfLine + _
		  "    <link rel=""stylesheet"" href=""https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"" />" + EndOfLine + _
		  "    <style>" + EndOfLine + _
		  "        * { margin: 0; padding: 0; box-sizing: border-box; }" + EndOfLine + _
		  "        body { font-family: -apple-system, BlinkMacSystemFont, ""Segoe UI"", Roboto, sans-serif; height: 100vh; display: flex; flex-direction: column; }" + EndOfLine + _
		  "        #header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 15px 20px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }" + EndOfLine + _
		  "        #header h1 { font-size: 24px; font-weight: 600; margin-bottom: 8px; }" + EndOfLine + _
		  "        #stats { display: flex; gap: 20px; font-size: 14px; opacity: 0.95; }" + EndOfLine + _
		  "        .stat { display: flex; align-items: center; gap: 5px; }" + EndOfLine + _
		  "        #controls { background: white; padding: 15px 20px; border-bottom: 1px solid #e0e0e0; display: flex; gap: 15px; align-items: center; flex-wrap: wrap; }" + EndOfLine + _
		  "        .btn { padding: 8px 16px; border: none; border-radius: 6px; cursor: pointer; font-size: 14px; font-weight: 500; transition: all 0.2s; }" + EndOfLine + _
		  "        .btn-primary { background: #667eea; color: white; }" + EndOfLine + _
		  "        .btn-primary:hover { background: #5568d3; }" + EndOfLine + _
		  "        .btn-secondary { background: #f3f4f6; color: #374151; }" + EndOfLine + _
		  "        .btn-secondary:hover { background: #e5e7eb; }" + EndOfLine + _
		  "        select { padding: 8px 12px; border: 1px solid #d1d5db; border-radius: 6px; font-size: 14px; cursor: pointer; background: white; }" + EndOfLine + _
		  "        #map { flex: 1; position: relative; }" + EndOfLine + _
		  "        .loading { position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.2); z-index: 2000; }" + EndOfLine + _
		  "        .spinner { border: 3px solid #f3f4f6; border-top: 3px solid #667eea; border-radius: 50%; width: 40px; height: 40px; animation: spin 1s linear infinite; margin: 0 auto 10px; }" + EndOfLine + _
		  "        @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }" + EndOfLine + _
		  "    </style>" + EndOfLine + _
		  "</head>" + EndOfLine + _
		  "<body>" + EndOfLine + _
		  "    <div id=""header"">" + EndOfLine + _
		  "        <h1>📍 Location Tracker</h1>" + EndOfLine + _
		  "        <div id=""stats"">" + EndOfLine + _
		  "            <div class=""stat""><span>🗺️</span><span id=""total-points"">0 points</span></div>" + EndOfLine + _
		  "            <div class=""stat""><span>📊</span><span id=""total-sessions"">0 sessions</span></div>" + EndOfLine + _
		  "            <div class=""stat""><span>🕒</span><span id=""last-update"">Never</span></div>" + EndOfLine + _
		  "        </div>" + EndOfLine + _
		  "    </div>" + EndOfLine + _
		  "    <div id=""controls"">" + EndOfLine + _
		  "        <button class=""btn btn-primary"" onclick=""refreshData()"">🔄 Refresh</button>" + EndOfLine + _
		  "        <button class=""btn btn-secondary"" onclick=""fitBounds()"">🎯 Fit All</button>" + EndOfLine + _
		  "        <select id=""session-filter"" onchange=""filterBySession()"">" + EndOfLine + _
		  "            <option value=""all"">All Sessions</option>" + EndOfLine + _
		  "        </select>" + EndOfLine + _
		  "        <select id=""limit-select"" onchange=""refreshData()"">" + EndOfLine + _
		  "            <option value=""100"" selected>Last 100 points</option>" + EndOfLine + _
		  "            <option value=""500"">Last 500 points</option>" + EndOfLine + _
		  "            <option value=""1000"">Last 1000 points</option>" + EndOfLine + _
		  "        </select>" + EndOfLine + _
		  "    </div>" + EndOfLine + _
		  "    <div id=""map"">" + EndOfLine + _
		  "        <div class=""loading"" id=""loading"">" + EndOfLine + _
		  "            <div class=""spinner""></div>" + EndOfLine + _
		  "            <div>Loading locations...</div>" + EndOfLine + _
		  "        </div>" + EndOfLine + _
		  "    </div>" + EndOfLine + _
		  "    <script src=""https://unpkg.com/leaflet@1.9.4/dist/leaflet.js""></script>" + EndOfLine + _
		  "    <script>" + EndOfLine + _
		  "        let map, markersLayer, pathLayer, allLocations = [];" + EndOfLine + _
		  "        function initMap() {" + EndOfLine + _
		  "            map = L.map('map').setView([-26.45, 152.875], 15);" + EndOfLine + _
		  "            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {" + EndOfLine + _
		  "                attribution: '© OpenStreetMap', maxZoom: 19" + EndOfLine + _
		  "            }).addTo(map);" + EndOfLine + _
		  "            markersLayer = L.layerGroup().addTo(map);" + EndOfLine + _
		  "            pathLayer = L.layerGroup().addTo(map);" + EndOfLine + _
		  "            refreshData();" + EndOfLine + _
		  "            setInterval(refreshData, 10000);" + EndOfLine + _
		  "        }" + EndOfLine + _
		  "        async function refreshData() {" + EndOfLine + _
		  "            const limit = document.getElementById('limit-select').value;" + EndOfLine + _
		  "            try {" + EndOfLine + _
		  "                const response = await fetch(`/?api=locations&limit=${limit}`);" + EndOfLine + _
		  "                const geojson = await response.json();" + EndOfLine + _
		  "                allLocations = geojson.features || [];" + EndOfLine + _
		  "                updateMap();" + EndOfLine + _
		  "                updateStats();" + EndOfLine + _
		  "                updateSessionFilter();" + EndOfLine + _
		  "                document.getElementById('loading').style.display = 'none';" + EndOfLine + _
		  "            } catch (error) {" + EndOfLine + _
		  "                console.error('Error:', error);" + EndOfLine + _
		  "                document.getElementById('loading').innerHTML = '<div>Error loading data</div>';" + EndOfLine + _
		  "            }" + EndOfLine + _
		  "        }" + EndOfLine + _
		  "        function updateMap() {" + EndOfLine + _
		  "            markersLayer.clearLayers();" + EndOfLine + _
		  "            pathLayer.clearLayers();" + EndOfLine + _
		  "            if (allLocations.length === 0) return;" + EndOfLine + _
		  "            const sessionFilter = document.getElementById('session-filter').value;" + EndOfLine + _
		  "            let filteredLocations = sessionFilter === 'all' ? allLocations : allLocations.filter(f => f.properties.session_id === sessionFilter);" + EndOfLine + _
		  "            const sessionGroups = {};" + EndOfLine + _
		  "            filteredLocations.forEach(f => {" + EndOfLine + _
		  "                const sid = f.properties.session_id || 'unknown';" + EndOfLine + _
		  "                if (!sessionGroups[sid]) sessionGroups[sid] = [];" + EndOfLine + _
		  "                sessionGroups[sid].push(f);" + EndOfLine + _
		  "            });" + EndOfLine + _
		  "            const colors = ['#667eea', '#f56565', '#48bb78', '#ed8936', '#9f7aea'];" + EndOfLine + _
		  "            let colorIndex = 0;" + EndOfLine + _
		  "            Object.keys(sessionGroups).forEach(sid => {" + EndOfLine + _
		  "                const features = sessionGroups[sid];" + EndOfLine + _
		  "                const color = colors[colorIndex % colors.length];" + EndOfLine + _
		  "                colorIndex++;" + EndOfLine + _
		  "                features.sort((a, b) => new Date(a.properties.timestamp) - new Date(b.properties.timestamp));" + EndOfLine + _
		  "                const coords = features.map(f => [f.geometry.coordinates[1], f.geometry.coordinates[0]]);" + EndOfLine + _
		  "                if (coords.length > 1) {" + EndOfLine + _
		  "                    L.polyline(coords, { color: color, weight: 3, opacity: 0.7 }).addTo(pathLayer);" + EndOfLine + _
		  "                }" + EndOfLine + _
		  "                features.forEach((f, i) => {" + EndOfLine + _
		  "                    const isFirst = i === 0, isLast = i === features.length - 1;" + EndOfLine + _
		  "                    const marker = L.circleMarker([f.geometry.coordinates[1], f.geometry.coordinates[0]], {" + EndOfLine + _
		  "                        radius: isFirst || isLast ? 8 : 5," + EndOfLine + _
		  "                        fillColor: isFirst ? '#48bb78' : (isLast ? '#f56565' : color)," + EndOfLine + _
		  "                        color: 'white', weight: 2, fillOpacity: 0.8" + EndOfLine + _
		  "                    });" + EndOfLine + _
		  "                    marker.bindPopup(`<strong>${isFirst ? '🟢 Start' : (isLast ? '🔴 Latest' : '📍 Point')}</strong><br><strong>Time:</strong> ${new Date(f.properties.timestamp).toLocaleString()}<br><strong>Lat:</strong> ${f.geometry.coordinates[1].toFixed(6)}<br><strong>Lon:</strong> ${f.geometry.coordinates[0].toFixed(6)}<br><strong>Alt:</strong> ${f.properties.altitude.toFixed(1)}m<br><strong>Speed:</strong> ${f.properties.speed.toFixed(1)}m/s`);" + EndOfLine + _
		  "                    marker.addTo(markersLayer);" + EndOfLine + _
		  "                });" + EndOfLine + _
		  "            });" + EndOfLine + _
		  "            if (filteredLocations.length > 0) {" + EndOfLine + _
		  "                const bounds = L.latLngBounds(filteredLocations.map(f => [f.geometry.coordinates[1], f.geometry.coordinates[0]]));" + EndOfLine + _
		  "                map.fitBounds(bounds, { padding: [50, 50] });" + EndOfLine + _
		  "            }" + EndOfLine + _
		  "        }" + EndOfLine + _
		  "        function updateStats() {" + EndOfLine + _
		  "            document.getElementById('total-points').textContent = `${allLocations.length} points`;" + EndOfLine + _
		  "            const uniqueSessions = new Set(allLocations.map(f => f.properties.session_id));" + EndOfLine + _
		  "            document.getElementById('total-sessions').textContent = `${uniqueSessions.size} sessions`;" + EndOfLine + _
		  "            if (allLocations.length > 0) {" + EndOfLine + _
		  "                const times = allLocations.map(f => new Date(f.properties.timestamp));" + EndOfLine + _
		  "                const latest = new Date(Math.max(...times));" + EndOfLine + _
		  "                document.getElementById('last-update').textContent = latest.toLocaleString();" + EndOfLine + _
		  "            }" + EndOfLine + _
		  "        }" + EndOfLine + _
		  "        function updateSessionFilter() {" + EndOfLine + _
		  "            const select = document.getElementById('session-filter');" + EndOfLine + _
		  "            const currentValue = select.value;" + EndOfLine + _
		  "            const uniqueSessions = new Set(allLocations.map(f => f.properties.session_id));" + EndOfLine + _
		  "            select.innerHTML = '<option value=""all"">All Sessions</option>';" + EndOfLine + _
		  "            Array.from(uniqueSessions).sort().forEach(sid => {" + EndOfLine + _
		  "                const option = document.createElement('option');" + EndOfLine + _
		  "                option.value = sid;" + EndOfLine + _
		  "                option.textContent = sid;" + EndOfLine + _
		  "                select.appendChild(option);" + EndOfLine + _
		  "            });" + EndOfLine + _
		  "            if (currentValue !== 'all' && uniqueSessions.has(currentValue)) select.value = currentValue;" + EndOfLine + _
		  "        }" + EndOfLine + _
		  "        function filterBySession() { updateMap(); }" + EndOfLine + _
		  "        function fitBounds() {" + EndOfLine + _
		  "            if (allLocations.length > 0) {" + EndOfLine + _
		  "                const bounds = L.latLngBounds(allLocations.map(f => [f.geometry.coordinates[1], f.geometry.coordinates[0]]));" + EndOfLine + _
		  "                map.fitBounds(bounds, { padding: [50, 50] });" + EndOfLine + _
		  "            }" + EndOfLine + _
		  "        }" + EndOfLine + _
		  "        window.onload = initMap;" + EndOfLine + _
		  "    </script>" + EndOfLine + _
		  "</body>" + EndOfLine + _
		  "</html>"
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function HandleLocationGet(request As WebRequest, response As WebResponse) As Boolean
		  // Private Function HandleLocationGet(request As WebRequest, response As WebResponse) As Boolean
		  // Get the latest location
		  
		  Try
		    Var latest As Dictionary = mDBManager.GetLatestLocation
		    
		    If latest <> Nil Then
		      response.Status = 200
		      
		      Var json As New JSONItem
		      json.Value("timestamp") = latest.Value("timestamp")
		      json.Value("latitude") = latest.Value("latitude")
		      json.Value("longitude") = latest.Value("longitude")
		      json.Value("altitude") = latest.Value("altitude")
		      json.Value("speed") = latest.Value("speed")
		      
		      response.Write(json.ToString)
		    Else
		      response.Status = 404
		      response.Write("{""error"": ""No location data available""}")
		    End If
		    
		  Catch e As RuntimeException
		    System.Log(System.LogLevelError, "HandleLocationGet error: " + e.Message)
		    response.Status = 500
		    response.Write("{""error"": ""Internal server error""}")
		  End Try
		  
		  Return True
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function HandleLocationPost(request As WebRequest, response As WebResponse) As Boolean
		  // Private Function HandleLocationPost(request As WebRequest, response As WebResponse) As Boolean
		  Try
		    System.DebugLog("📍 POST /api=location received")
		    
		    ' Read POST body
		    Var body As String = request.Body
		    
		    If body = "" Then
		      System.DebugLog("❌ Empty POST body")
		      response.Status = 400
		      response.Write("{""error"": ""No data received""}")
		      Return True
		    End If
		    
		    System.DebugLog("Body length: " + Str(body.Length))
		    
		    ' Parse JSON
		    Var json As JSONItem
		    Try
		      json = New JSONItem(body)
		    Catch e As RuntimeException
		      System.DebugLog("❌ JSON parse error: " + e.Message)
		      response.Status = 400
		      response.Write("{""error"": ""Invalid JSON""}")
		      Return True
		    End Try
		    
		    ' Check for batch mode
		    If json.HasKey("locations") Then
		      System.DebugLog("📦 Batch mode detected")
		      
		      Var sessionID As String = json.Value("session_id")
		      Var locations As JSONItem = json.Value("locations")
		      
		      System.DebugLog("Session: " + sessionID)
		      System.DebugLog("Count: " + Str(locations.Count))
		      
		      If sessionID = "" Then
		        sessionID = "session_" + DateTime.Now.SecondsFrom1970.ToString
		      End If
		      
		      Var count As Integer = 0
		      For i As Integer = 0 To locations.Count - 1
		        Try
		          Var loc As JSONItem = locations.ValueAt(i)
		          Var timestamp As String = loc.Value("timestamp")
		          Var lat As Double = loc.Value("latitude")
		          Var lon As Double = loc.Value("longitude")
		          Var alt As Double = loc.Value("altitude")
		          Var spd As Double = loc.Value("speed")
		          
		          ' Add to database
		          mDBManager.AddLocation(sessionID, timestamp, lat, lon, alt, spd)
		          count = count + 1
		          
		        Catch e As RuntimeException
		          System.DebugLog("❌ Error processing location: " + e.Message)
		        End Try
		      Next
		      
		      System.DebugLog("✅ Processed " + Str(count) + " locations")
		      
		      response.Status = 200
		      response.Write("{""status"":""success"",""count"":" + Str(count) + "}")
		      
		    Else
		      ' Single location mode
		      System.DebugLog("📍 Single location mode")
		      
		      Var sessionID As String = json.Value("session_id")
		      Var timestamp As String = json.Value("timestamp")
		      Var lat As Double = json.Value("latitude")
		      Var lon As Double = json.Value("longitude")
		      Var alt As Double = json.Value("altitude")
		      Var spd As Double = json.Value("speed")
		      
		      If sessionID = "" Then
		        sessionID = "session_" + DateTime.Now.SecondsFrom1970.ToString
		      End If
		      
		      If timestamp = "" Then
		        timestamp = DateTime.Now.SQLDateTime
		      End If
		      
		      mDBManager.AddLocation(sessionID, timestamp, lat, lon, alt, spd)
		      
		      System.DebugLog("✅ Added single location")
		      
		      response.Status = 200
		      response.Write("{""status"":""success""}")
		    End If
		    
		  Catch e As RuntimeException
		    System.DebugLog("❌ HandleLocationPost ERROR: " + e.Message)
		    response.Status = 500
		    response.Write("{""error"":""Server error""}")
		  End Try
		  
		  Return True
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function HandleLocationsGet(request As WebRequest, response As WebResponse) As Boolean
		  // Private Function HandleLocationsGet(request As WebRequest, response As WebResponse) As Boolean
		  // Get recent locations in GeoJSON format
		  
		  Try
		    // Parse limit parameter
		    Var limit As Integer = 100
		    Var queryString As String = request.QueryString
		    
		    If queryString.IndexOf("limit=") > -1 Then
		      Var parts() As String = queryString.Split("&")
		      For Each part As String In parts
		        If part.BeginsWith("limit=") Then
		          Var limitStr As String = part.Replace("limit=", "")
		          limit = Val(limitStr)
		          If limit < 1 Then limit = 100
		          If limit > 1000 Then limit = 1000
		          Exit For
		        End If
		      Next
		    End If
		    
		    Var locations As JSONItem = mDBManager.GetRecentLocations(limit)
		    
		    response.Status = 200
		    response.Write(locations.ToString)
		    
		  Catch e As RuntimeException
		    System.DebugLog("HandleLocationsGet error: " + e.Message)
		    response.Status = 500
		    
		    response.Write("{""error"": ""Internal server error""}")
		  End Try
		  
		  Return True
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function HandleSessionLocationsGet(request As WebRequest, response As WebResponse) As Boolean
		  // Private Function HandleSessionLocationsGet(request As WebRequest, response As WebResponse) As Boolean
		  // Get locations for a specific session
		  
		  Try
		    Var sessionID As String = ""
		    Var queryString As String = request.QueryString
		    
		    // Extract session_id parameter
		    If queryString.IndexOf("session_id=") > -1 Then
		      Var parts() As String = queryString.Split("&")
		      For Each part As String In parts
		        If part.BeginsWith("session_id=") Then
		          sessionID = part.Replace("session_id=", "")
		          Exit For
		        End If
		      Next
		    End If
		    
		    If sessionID = "" Then
		      response.Status = 400
		      
		      response.Write("{""error"": ""Missing session_id parameter""}")
		      Return True
		    End If
		    
		    Var locations As JSONItem = mDBManager.GetSessionLocations(sessionID)
		    
		    
		    response.Status = 200
		    response.Write(locations.ToString)
		    
		  Catch e As RuntimeException
		    System.DebugLog("HandleSessionLocationsGet error: " + e.Message)
		    response.Status = 500
		    
		    response.Write("{""error"": ""Internal server error""}")
		  End Try
		  
		  Return True
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function HandleSessionsGet(request As WebRequest, response As WebResponse) As Boolean
		  // Private Function HandleSessionsGet(request As WebRequest, response As WebResponse) As Boolean
		  // Get all tracking sessions
		  
		  Try
		    Var sessions As JSONItem = mDBManager.GetSessions
		    
		    
		    response.Status = 200
		    response.Write(sessions.ToString)
		    
		  Catch e As RuntimeException
		    System.DebugLog("HandleSessionsGet error: " + e.Message)
		    response.Status = 500
		    
		    response.Write("{""error"": ""Internal server error""}")
		  End Try
		  
		  Return True
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function HandleStatsGet(request As WebRequest, response As WebResponse) As Boolean
		  // Private Function HandleStatsGet(request As WebRequest, response As WebResponse) As Boolean
		  // Get statistics
		  
		  Try
		    Var stats As Dictionary = mDBManager.GetStatistics
		    
		    
		    response.Status = 200
		    
		    Var json As New JSONItem
		    json.Value("total_locations") = stats.Value("total_locations")
		    json.Value("total_sessions") = stats.Value("total_sessions")
		    json.Value("oldest_location") = stats.Value("oldest_location")
		    json.Value("newest_location") = stats.Value("newest_location")
		    
		    response.Write(json.ToString)
		    
		  Catch e As RuntimeException
		    System.DebugLog("HandleStatsGet error: " + e.Message)
		    response.Status = 500
		    
		    response.Write("{""error"": ""Internal server error""}")
		  End Try
		  
		  Return True
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function PercentDecode(encoded As String) As String
		  // Helper: simple percent-decode for query values (put this in App as well)
		  // Public Function PercentDecode(encoded As String) As String
		  If encoded.Trim = "" Then Return ""
		  Var s As String = encoded
		  Var out As String = ""
		  Var i As Integer = 0
		  
		  While i < s.Length
		    Var ch As String = s.Middle(i, 1)
		    If ch = "%" And i + 2 < s.Length Then
		      Var Hex As String = s.Middle(i + 1, 2)
		      Try
		        Var Val As Integer = Val("&h" + Hex) // convert hex to Int
		        out = out + Chr(Val)
		        i = i + 3
		      Catch
		        // if malformed, just append raw and advance one
		        out = out + ch
		        i = i + 1
		      End Try
		    ElseIf ch = "+" Then
		      out = out + " "
		      i = i + 1
		    Else
		      out = out + ch
		      i = i + 1
		    End If
		  Wend
		  
		  Return out
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ServeMapViewer(request As WebRequest, response As WebResponse) As Boolean
		  '// Private Function ServeMapViewer(request As WebRequest, response As WebResponse) As Boolean
		  '// TEST VERSION - Simple HTML to verify this function is being called
		  '
		  '
		  'System.debugLog("🗺️ ServeMapViewer was called!")
		  '
		  'response.Status = 200
		  '
		  'Var testHTML As String = "<!DOCTYPE html><html><head><title>TEST</title></head>"
		  'testHTML = testHTML + "<body style='background:green;color:white;padding:50px;font-size:30px;'>"
		  'testHTML = testHTML + "<h1>SUCCESS! ServeMapViewer is working!</h1>"
		  'testHTML = testHTML + "<p>The routing is correct. Now we need to add the real map code.</p>"
		  'testHTML = testHTML + "</body></html>"
		  '
		  '
		  'response.Write(testHTML)
		  '
		  'Return True
		  //Function ServeMapViewer(request As WebRequest, response As WebResponse) As Boolean
		  'System.DebugLog("🗺️ ServeMapViewer was called!")
		  
		  // Function ServeMapViewer(request As WebRequest, response As WebResponse) As Boolean
		  // System.DebugLog("🗺️ ServeMapViewer was called!")
		  
		  Var html As String
		  
		  Try
		    Var htmlFile As FolderItem = GetLaunchFolder.Child("MapViewer.html")
		    If htmlFile.Exists Then
		      Var stream As TextInputStream = TextInputStream.Open(htmlFile)
		      html = stream.ReadAll
		      stream.Close
		    Else
		      html = "<html><body><h1>MapViewer.html not found</h1></body></html>"
		    End If
		  Catch e As RuntimeException
		    html = "<html><body><h1>Error reading HTML: " + e.Message + "</h1></body></html>"
		  End Try
		  
		  response.MIMEType = "text/html"
		  response.Write(html)
		  Return True
		  
		  // Try current working directory first
		  
		End Function
	#tag EndMethod


	#tag Property, Flags = &h21
		Private mDBManager As ServerDatabaseManager
	#tag EndProperty


	#tag Constant, Name = kServerURL, Type = String, Dynamic = False, Default = \"http://127.0.0.1:8080/\?page\x3Dmap", Scope = Public
	#tag EndConstant


	#tag ViewBehavior
	#tag EndViewBehavior
End Class
#tag EndClass
