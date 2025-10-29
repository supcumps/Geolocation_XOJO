#tag Class
Protected Class ServerDatabaseManager
	#tag Method, Flags = &h0
		Sub AddLocation(sessionID As String, timestamp As String, lat As Double, lon As Double, alt As Double, spd As Double)
		  ' ServerDatabaseManager.AddLocation - FIXED TIMESTAMP HANDLING
		  ' ==============================================================
		  
		  // Sub AddLocation(sessionID As String, timestamp As String, lat As Double, lon As Double, alt As Double, spd As Double)
		  
		  System.DebugLog("🔵 AddLocation called")
		  System.DebugLog("   Session: " + sessionID)
		  System.DebugLog("   Timestamp: " + timestamp)
		  System.DebugLog("   Lat/Lon: " + Str(lat) + ", " + Str(lon))
		  
		  If mDatabase = Nil Then
		    System.DebugLog("❌ ERROR: Database is NIL!")
		    Return
		  End If
		  
		  Try
		    ' IMPORTANT: Use simple INSERT without prepared statement first to debug
		    ' Build SQL directly to see exactly what's being inserted
		    
		    Var sql As String = "INSERT INTO Locations (session_id, timestamp, latitude, longitude, altitude, speed) VALUES ('" + _
		    sessionID + "', '" + _
		    timestamp + "', " + _
		    lat.ToString + ", " + _
		    lon.ToString + ", " + _
		    alt.ToString + ", " + _
		    spd.ToString + ")"
		    
		    System.DebugLog("   SQL: " + sql)
		    
		    ' Execute the INSERT
		    mDatabase.ExecuteSQL(sql)
		    
		    System.DebugLog("✅ SQL executed - location saved")
		    
		    ' IMMEDIATELY VERIFY IT WAS WRITTEN
		    Var checkSQL As String = "SELECT COUNT(*) as count FROM Locations"
		    Var rs As RowSet = mDatabase.SelectSQL(checkSQL)
		    
		    If rs <> Nil And Not rs.AfterLastRow Then
		      Var count As Integer = rs.Column("count").IntegerValue
		      System.DebugLog("   ✓ VERIFICATION: Database now has " + count.ToString + " total records")
		    Else
		      System.DebugLog("   ❌ VERIFICATION FAILED: Could not read back count!")
		    End If
		    
		    ' Also check if this specific record exists
		    Var checkSQL2 As String = "SELECT * FROM Locations WHERE session_id = '" + sessionID + "' ORDER BY id DESC LIMIT 1"
		    Var rs2 As RowSet = mDatabase.SelectSQL(checkSQL2)
		    
		    If rs2 <> Nil And Not rs2.AfterLastRow Then
		      System.DebugLog("   ✓ Last record confirmed: ID=" + rs2.Column("id").StringValue + ", Lat=" + rs2.Column("latitude").StringValue)
		    Else
		      System.DebugLog("   ❌ WARNING: Could not find the record we just inserted!")
		    End If
		    
		  Catch e As DatabaseException
		    System.DebugLog("❌ DATABASE EXCEPTION: " + e.Message)
		    System.DebugLog("   Error Number: " + e.ErrorNumber.ToString)
		    
		  Catch e As RuntimeException
		    System.DebugLog("❌ RUNTIME EXCEPTION: " + e.Message)
		  End Try
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor()
		  InitDatabase
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetLatestLocation() As Dictionary
		  // Get the most recent location
		  
		  If mDatabase = Nil Then Return Nil
		  
		  Try
		    Var rs As RowSet = mDatabase.SelectSQL("SELECT * FROM Locations ORDER BY id DESC LIMIT 1")
		    
		    If rs <> Nil And Not rs.AfterLastRow Then
		      Var result As New Dictionary
		      result.Value("id") = rs.Column("id").IntegerValue
		      result.Value("session_id") = rs.Column("session_id").StringValue
		      result.Value("timestamp") = rs.Column("timestamp").StringValue
		      result.Value("latitude") = rs.Column("latitude").DoubleValue
		      result.Value("longitude") = rs.Column("longitude").DoubleValue
		      result.Value("altitude") = rs.Column("altitude").DoubleValue
		      result.Value("speed") = rs.Column("speed").DoubleValue
		      Return result
		    End If
		  Catch e As DatabaseException
		    System.DebugLog("GetLatestLocation failed: " + e.Message)
		  End Try
		  
		  Return Nil
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetRecentLocations(limit As Integer) As JSONItem
		  //Function GetRecentLocations(limit As Integer) As JSONItem
		  ' Returns locations in GeoJSON format for mapping
		  
		  Var geojson As New JSONItem
		  geojson.Value("type") = "FeatureCollection"
		  
		  Var features() As Variant
		  
		  Try
		    Var sql As String = "SELECT * FROM Locations ORDER BY id DESC LIMIT " + limit.ToString
		    Var rs As RowSet = mDatabase.SelectSQL(sql)
		    
		    While Not rs.AfterLastRow
		      ' Create GeoJSON feature
		      Var feature As New Dictionary
		      feature.Value("type") = "Feature"
		      
		      ' Geometry (Point with [longitude, latitude])
		      Var geometry As New Dictionary
		      geometry.Value("type") = "Point"
		      
		      Var coordinates() As Variant
		      coordinates.Add(rs.Column("longitude").DoubleValue) ' Lon first!
		      coordinates.Add(rs.Column("latitude").DoubleValue)  ' Lat second!
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
		    
		    System.DebugLog("📊 Generated GeoJSON with " + features.Count.ToString + " features")
		    
		  Catch e As DatabaseException
		    System.DebugLog("❌ Error generating GeoJSON: " + e.Message)
		  End Try
		  
		  Return geojson
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetSessionLocations(sessionID As String) As JSONItem
		  // Get all locations for a specific session in GeoJSON format
		  
		  If mDatabase = Nil Then Return Nil
		  
		  Try
		    Var rs As RowSet = mDatabase.SelectSQL("SELECT * FROM Locations WHERE session_id = ? ORDER BY id ASC", sessionID)
		    
		    Var json As New JSONItem
		    json.Value("type") = "FeatureCollection"
		    json.Value("session_id") = sessionID
		    
		    Var features() As Variant
		    
		    While Not rs.AfterLastRow
		      Var feature As New Dictionary
		      feature.Value("type") = "Feature"
		      
		      // Geometry (Point)
		      Var geometry As New Dictionary
		      geometry.Value("type") = "Point"
		      Var coordinates() As Variant
		      coordinates.Add(rs.Column("longitude").DoubleValue)
		      coordinates.Add(rs.Column("latitude").DoubleValue)
		      geometry.Value("coordinates") = coordinates
		      feature.Value("geometry") = geometry
		      
		      // Properties
		      Var properties As New Dictionary
		      properties.Value("id") = rs.Column("id").IntegerValue
		      properties.Value("timestamp") = rs.Column("timestamp").StringValue
		      properties.Value("altitude") = rs.Column("altitude").DoubleValue
		      properties.Value("speed") = rs.Column("speed").DoubleValue
		      feature.Value("properties") = properties
		      
		      features.Add(feature)
		      rs.MoveToNextRow
		    Wend
		    
		    json.Value("features") = features
		    Return json
		    
		  Catch e As DatabaseException
		    System.DebugLog("GetSessionLocations failed: " + e.Message)
		    Return Nil
		  End Try
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetSessions() As JSONItem
		  // Get all tracking sessions with metadata
		  
		  If mDatabase = Nil Then Return Nil
		  
		  Try
		    Var sql As String = _
		    "SELECT session_id, " + _
		    "COUNT(*) as point_count, " + _
		    "MIN(timestamp) as start_time, " + _
		    "MAX(timestamp) as end_time, " + _
		    "MIN(latitude) as min_lat, MAX(latitude) as max_lat, " + _
		    "MIN(longitude) as min_lon, MAX(longitude) as max_lon " + _
		    "FROM Locations " + _
		    "GROUP BY session_id " + _
		    "ORDER BY MAX(id) DESC"
		    
		    Var rs As RowSet = mDatabase.SelectSQL(sql)
		    
		    Var json As New JSONItem
		    Var sessions() As Variant
		    
		    While Not rs.AfterLastRow
		      Var session As New Dictionary
		      session.Value("session_id") = rs.Column("session_id").StringValue
		      session.Value("point_count") = rs.Column("point_count").IntegerValue
		      session.Value("start_time") = rs.Column("start_time").StringValue
		      session.Value("end_time") = rs.Column("end_time").StringValue
		      
		      // Bounding box
		      Var bbox As New Dictionary
		      bbox.Value("min_lat") = rs.Column("min_lat").DoubleValue
		      bbox.Value("max_lat") = rs.Column("max_lat").DoubleValue
		      bbox.Value("min_lon") = rs.Column("min_lon").DoubleValue
		      bbox.Value("max_lon") = rs.Column("max_lon").DoubleValue
		      session.Value("bbox") = bbox
		      
		      sessions.Add(session)
		      rs.MoveToNextRow
		    Wend
		    
		    json.Value("sessions") = sessions
		    json.Value("count") = sessions.Count
		    Return json
		    
		  Catch e As DatabaseException
		    System.DebugLog("GetSessions failed: " + e.Message)
		    Return Nil
		  End Try
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetStatistics() As Dictionary
		  // Get overall statistics
		  
		  If mDatabase = Nil Then Return Nil
		  
		  Try
		    Var stats As New Dictionary
		    
		    // Total locations
		    Var rs As RowSet = mDatabase.SelectSQL("SELECT COUNT(*) as total FROM Locations")
		    If Not rs.AfterLastRow Then
		      stats.Value("total_locations") = rs.Column("total").IntegerValue
		    End If
		    
		    // Total sessions
		    rs = mDatabase.SelectSQL("SELECT COUNT(DISTINCT session_id) as total FROM Locations")
		    If Not rs.AfterLastRow Then
		      stats.Value("total_sessions") = rs.Column("total").IntegerValue
		    End If
		    
		    // Oldest and newest
		    rs = mDatabase.SelectSQL("SELECT MIN(timestamp) as oldest, MAX(timestamp) as newest FROM Locations")
		    If Not rs.AfterLastRow Then
		      stats.Value("oldest_location") = rs.Column("oldest").StringValue
		      stats.Value("newest_location") = rs.Column("newest").StringValue
		    End If
		    
		    Return stats
		    
		  Catch e As DatabaseException
		    System.DebugLog("GetStatistics failed: " + e.Message)
		    Return Nil
		  End Try
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub InitDatabase()
		  // Initialize the SQLite database
		  
		  Try
		    mDatabase = New SQLiteDatabase
		    
		    // Use a db folder in the app data folder
		    Var dbFolder As FolderItem = SpecialFolder.ApplicationData.Child("LocationTracker")
		    If Not dbFolder.Exists Then
		      dbFolder.CreateFolder
		    End If
		    
		    mDatabase.DatabaseFile = dbFolder.Child("locations.sqlite")
		    
		    system.DebugLog("Database location:  "  + mDatabase.DatabaseFile.NativePath)
		    
		    If Not mDatabase.DatabaseFile.Exists Then
		      // Create new database
		      mDatabase.CreateDatabase
		      
		      If mDatabase.IsConnected Then
		        // Create Locations table
		        Var sql As String = _
		        "CREATE TABLE IF NOT EXISTS Locations (" + _
		        "id INTEGER PRIMARY KEY AUTOINCREMENT, " + _
		        "session_id TEXT NOT NULL, " + _
		        "timestamp TEXT NOT NULL, " + _
		        "latitude REAL NOT NULL, " + _
		        "longitude REAL NOT NULL, " + _
		        "altitude REAL, " + _
		        "speed REAL, " + _
		        "created_at DATETIME DEFAULT CURRENT_TIMESTAMP)"
		        
		        mDatabase.ExecuteSQL(sql)
		        
		        // Create indexes for better performance
		        mDatabase.ExecuteSQL("CREATE INDEX IF NOT EXISTS idx_session ON Locations(session_id)")
		        mDatabase.ExecuteSQL("CREATE INDEX IF NOT EXISTS idx_timestamp ON Locations(timestamp)")
		        
		        System.DebugLog("✅ Database created: " + mDatabase.DatabaseFile.NativePath)
		      End If
		    Else
		      // Connect to existing database
		      mDatabase.Connect
		      System.DebugLog("✅ Database connected: " + mDatabase.DatabaseFile.NativePath)
		    End If
		    
		  Catch e As DatabaseException
		    System.DebugLog("❌ DB init failed: " + e.Message)
		  End Try
		  
		  
		  ' ADD THIS DIAGNOSTIC CODE:
		  System.DebugLog("===========================================")
		  System.DebugLog("DATABASE FILE LOCATION:")
		  
		  If mDatabase <> Nil And mDatabase.DatabaseFile <> Nil Then
		    Var dbFile As FolderItem = mDatabase.DatabaseFile
		    System.DebugLog("   Path: " + dbFile.NativePath)
		    System.DebugLog("   Exists: " + dbFile.Exists.ToString)
		    
		    If dbFile.Exists Then
		      System.DebugLog("   Size: " + dbFile.Length.ToString + " bytes")
		    End If
		  Else
		    System.DebugLog("   ERROR: Cannot determine database location!")
		  End If
		  
		  System.DebugLog("===========================================")
		  
		  ' Also check how many records are in the database
		  Try
		    Var rs As RowSet = mDatabase.SelectSQL("SELECT COUNT(*) as count FROM Locations")
		    If rs <> Nil And Not rs.AfterLastRow Then
		      Var recordCount As Integer = rs.Column("count").IntegerValue
		      System.DebugLog("📊 Database currently has " + recordCount.ToString + " location records")
		    End If
		  Catch e As DatabaseException
		    System.DebugLog("Error counting records: " + e.Message)
		  End Try
		  
		  
		  
		  
		  ' WHAT THIS WILL SHOW:
		  ' ====================
		  ' When you restart the server, you'll see:
		  '
		  ' DATABASE FILE LOCATION:
		  '    Path: /actual/path/to/database.sqlite
		  '    Exists: True
		  '    Size: 123456 bytes
		  ' 📊 Database currently has 3772 location records
		  '
		  ' Copy that path and open THAT file in DB Browser!
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub VerifyDatabaseConnection()
		  System.DebugLog("=== DATABASE CONNECTION VERIFICATION ===")
		  
		  If mDatabase = Nil Then
		    System.DebugLog("❌ mDatabase is NIL!")
		    Return
		  End If
		  
		  System.DebugLog("✓ mDatabase exists")
		  
		  If mDatabase.DatabaseFile = Nil Then
		    System.DebugLog("❌ DatabaseFile is NIL!")
		    Return
		  End If
		  
		  Var dbFile As FolderItem = mDatabase.DatabaseFile
		  System.DebugLog("✓ Database file: " + dbFile.NativePath)
		  System.DebugLog("  Exists: " + dbFile.Exists.ToString)
		  System.DebugLog("  Writable: " + dbFile.IsWriteable.ToString)
		  System.DebugLog("  Size: " + dbFile.Length.ToString + " bytes")
		  
		  Try
		    ' Try to read table structure
		    Var rs As RowSet = mDatabase.SelectSQL("SELECT * FROM Locations LIMIT 1")
		    System.DebugLog("✓ Can query Locations table")
		    
		    ' Try to insert a test record
		    mDatabase.ExecuteSQL("INSERT INTO Locations (session_id, timestamp, latitude, longitude, altitude, speed) VALUES ('test', '2025-10-29 07:00:00', -26.45, 152.87, 100, 0)")
		    System.DebugLog("✓ Test insert succeeded")
		    
		    ' Check if it's there
		    Var checkRS As RowSet = mDatabase.SelectSQL("SELECT COUNT(*) as count FROM Locations WHERE session_id = 'test'")
		    If checkRS <> Nil Then
		      System.DebugLog("✓ Test record count: " + checkRS.Column("count").StringValue)
		    End If
		    
		    ' Clean up test record
		    mDatabase.ExecuteSQL("DELETE FROM Locations WHERE session_id = 'test'")
		    System.DebugLog("✓ Test record deleted")
		    
		  Catch e As DatabaseException
		    System.DebugLog("❌ Database test failed: " + e.Message)
		  End Try
		  
		  System.DebugLog("========================================")
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h21
		Private mDatabase As SQLiteDatabase
	#tag EndProperty


	#tag ViewBehavior
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			InitialValue=""
			Type="String"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue="-2147483648"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Super"
			Visible=true
			Group="ID"
			InitialValue=""
			Type="String"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Left"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Top"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
