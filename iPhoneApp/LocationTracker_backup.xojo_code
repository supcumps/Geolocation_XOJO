#tag Class
Protected Class LocationTracker
	#tag Method, Flags = &h0
		Sub AddLocationData(timestamp As DateTime, lat As Double, lon As Double, alt As Double, spd As Double)
		  ' Create location data dictionary
		  Var locationData As New Dictionary
		  locationData.Value("timestamp") = timestamp.SecondsFrom1970
		  locationData.Value("latitude") = lat
		  locationData.Value("longitude") = lon
		  locationData.Value("altitude") = alt
		  locationData.Value("speed") = spd
		  locationData.Value("session_id") = mSessionID
		  
		  ' Add to pending locations array
		  mPendingLocations.Add(locationData)
		  
		  System.DebugLog("📦 Location stored (pending: " + mPendingLocations.Count.ToString + ")")
		  
		  ' Raise event to notify UI
		  RaiseEvent LocationUpdated(timestamp, lat, lon, alt, spd)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor()
		  ' Initialize session tracking
		  mLastSyncTime = DateTime.Now.SecondsFrom1970
		  mSessionID = "session_" + mLastSyncTime.ToString
		  
		  System.DebugLog("✅ LocationTracker initialized")
		  System.DebugLog("   Session: " + mSessionID)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub StartTracking()
		  System.DebugLog("📍 LocationTracker ready for data")
		  RaiseEvent StatusChanged(1)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub StopTracking()
		  System.DebugLog("⏸️ Location tracking stopped")
		  RaiseEvent StatusChanged(0)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SyncToServer()
		  If mPendingLocations.Count = 0 Then
		    System.DebugLog("ℹ️ No pending locations to sync")
		    RaiseEvent StatusChanged(-2)
		    Return
		  End If
		  
		  System.DebugLog("📤 Syncing " + mPendingLocations.Count.ToString + " locations...")
		  
		  ' Convert Dictionary array to Variant array for JSONItem
		  Var locationsArray() As Variant
		  For Each loc As Dictionary In mPendingLocations
		    locationsArray.Add(loc)
		  Next
		  
		  ' Prepare payload
		  Var payload As New Dictionary
		  payload.Value("session_id") = mSessionID
		  payload.Value("locations") = locationsArray
		  
		  Var payloadJSON As New JSONItem(payload)
		  
		  Try
		    ' Create HTTP request
		    Var socket As New URLConnection
		    socket.RequestHeader("Content-Type") = "application/json"
		    socket.SetRequestContent(payloadJSON.ToString, "application/json")
		    
		    System.DebugLog("📤 Sending to: " + kServerURL)
		    
		    ' Send to server
		    Var response As String = socket.SendSync("POST", kServerURL, 30)
		    
		    System.DebugLog("📥 HTTP Status: " + socket.HTTPStatusCode.ToString)
		    
		    ' Check response
		    If socket.HTTPStatusCode = 200 Then
		      System.DebugLog("✅ Sync successful")
		      
		      ' Clear pending locations
		      mPendingLocations.RemoveAll
		      mLastSyncTime = DateTime.Now.SecondsFrom1970
		      
		      RaiseEvent StatusChanged(2)
		    Else
		      System.DebugLog("❌ Sync failed: HTTP " + socket.HTTPStatusCode.ToString)
		      RaiseEvent SyncFailed("HTTP error: " + socket.HTTPStatusCode.ToString)
		    End If
		    
		  Catch e As RuntimeException
		    System.DebugLog("❌ Sync error: " + e.Message)
		    RaiseEvent SyncFailed(e.Message)
		  End Try
		End Sub
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event LocationUpdated(timestamp As DateTime, lat As Double, lon As Double, alt As Double, spd As Double)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event StatusChanged(status As Integer)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event SyncFailed(errorMessage As String)
	#tag EndHook


	#tag Property, Flags = &h21
		Private mLastSyncTime As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mPendingLocations() As Dictionary
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mSessionID As String
	#tag EndProperty


	#tag Constant, Name = kServerURL, Type = String, Dynamic = False, Default = \"http://192.168.0.108:8080/location", Scope = Private
	#tag EndConstant


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
