#tag Class
Protected Class DatabaseManager
	#tag Method, Flags = &h0
		Sub AddLocation(ts As DateTime, lat As Double, lon As Double, alt As Double, spd As Double)
		  Try
		    If mDatabase = Nil Then InitDatabase
		    
		    Var sql As String = "INSERT INTO Locations (timestamp, latitude, longitude, altitude, speed, synced) VALUES (?, ?, ?, ?, ?, 0)"
		    mDatabase.ExecuteSQL(sql, ts.SQLDateTime, lat, lon, alt, spd)
		  Catch e As DatabaseException
		    System.DebugLog("Insert failed: " + e.Message)
		  End Try
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor()
		  InitDatabase
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetUnsyncedLocations() As RowSet
		  If mDatabase = Nil Then Return Nil
		  
		  Try
		    Return mDatabase.SelectSQL("SELECT * FROM Locations WHERE synced = 0 ORDER BY id LIMIT 100")
		  Catch e As DatabaseException
		    System.DebugLog("Select failed: " + e.Message)
		    Return Nil
		  End Try
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub InitDatabase()
		  Try
		    mDatabase = New SQLiteDatabase
		    mDatabase.DatabaseFile = SpecialFolder.Documents.Child("TrackerData.sqlite")
		    
		    If Not mDatabase.DatabaseFile.Exists Then
		      mDatabase.CreateDatabase
		      If mDatabase.IsConnected Then
		        Var sql As String = _
		        "CREATE TABLE IF NOT EXISTS Locations (" + _
		        "id INTEGER PRIMARY KEY AUTOINCREMENT, " + _
		        "timestamp TEXT NOT NULL, " + _
		        "latitude REAL NOT NULL, " + _
		        "longitude REAL NOT NULL, " + _
		        "altitude REAL, " + _
		        "speed REAL, " + _
		        "synced INTEGER DEFAULT 0)"
		        mDatabase.ExecuteSQL(sql)
		      End If
		    Else
		      mDatabase.Connect
		    End If
		  Catch e As DatabaseException
		    System.DebugLog("DB init failed: " + e.Message)
		  End Try
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub MarkAsSynced(ids() As Integer)
		  If mDatabase = Nil Or ids.Count = 0 Then Return
		  
		  Try
		    Var placeholders As String
		    For i As Integer = 0 To ids.LastIndex
		      If i > 0 Then placeholders = placeholders + ","
		      placeholders = placeholders + "?"
		    Next
		    
		    Var sql As String = "UPDATE Locations SET synced = 1 WHERE id IN (" + placeholders + ")"
		    Var params() As Variant
		    For Each id As Integer In ids
		      params.Add(id)
		    Next
		    
		    mDatabase.ExecuteSQL(sql, params)
		  Catch e As DatabaseException
		    System.DebugLog("Mark synced failed: " + e.Message)
		  End Try
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
