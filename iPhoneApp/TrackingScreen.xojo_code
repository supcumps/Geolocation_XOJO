#tag MobileScreen
Begin MobileScreen TrackingScreen
   BackButtonCaption=   ""
   Compatibility   =   ""
   ControlCount    =   0
   Device = 7
   HasNavigationBar=   True
   LargeTitleDisplayMode=   2
   Left            =   0
   Orientation = 0
   ScaleFactor     =   0.0
   TabBarVisible   =   False
   TabIcon         =   0
   TintColor       =   
   Title           =   "Location Tracker"
   Top             =   0
   Begin MobileLocation LocationSource
      Accuracy        =   0
      AllowBackgroundUpdates=   True
      AuthorizationState=   0
      Left            =   0
      LockedInPosition=   False
      PanelIndex      =   -1
      Parent          =   ""
      Scope           =   2
      Top             =   0
      VisitAwareness  =   False
   End
   Begin MobileLabel StatusLabel
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Alignment       =   1
      AutoLayout      =   StatusLabel, 8, , 0, False, +1.00, 4, 1, 30, , True
      AutoLayout      =   StatusLabel, 1, <Parent>, 1, False, +1.00, 4, 1, 20, , True
      AutoLayout      =   StatusLabel, 2, <Parent>, 2, False, +1.00, 4, 1, -20, , True
      AutoLayout      =   StatusLabel, 3, TopLayoutGuide, 3, False, +1.00, 4, 1, 100, , True
      ControlCount    =   0
      Enabled         =   True
      Height          =   30
      Left            =   20
      LineBreakMode   =   0
      LockedInPosition=   False
      MaximumCharactersAllowed=   0
      Scope           =   0
      SelectedText    =   ""
      SelectionLength =   0
      SelectionStart  =   0
      Text            =   "Ready to track"
      TextColor       =   &c000000
      TextFont        =   ""
      TextSize        =   0
      TintColor       =   
      Top             =   165
      Visible         =   True
      Width           =   335
      _ClosingFired   =   False
   End
   Begin MobileButton StartButton
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      AutoLayout      =   StartButton, 9, <Parent>, 9, False, +1.00, 4, 1, 0, , True
      AutoLayout      =   StartButton, 8, , 0, False, +1.00, 4, 1, 44, , True
      AutoLayout      =   StartButton, 3, StatusLabel, 4, False, +1.00, 4, 1, 20, , True
      AutoLayout      =   StartButton, 7, , 0, False, +1.00, 4, 1, 140, , True
      Caption         =   "Start Tracking"
      CaptionColor    =   &c000000
      ControlCount    =   0
      Enabled         =   True
      Height          =   44
      Left            =   117
      LockedInPosition=   False
      Scope           =   0
      TextFont        =   ""
      TextSize        =   0
      TintColor       =   
      Top             =   215
      Visible         =   True
      Width           =   140
      _ClosingFired   =   False
   End
   Begin MobileButton SyncButton
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      AutoLayout      =   SyncButton, 9, <Parent>, 9, False, +1.00, 4, 1, 0, , True
      AutoLayout      =   SyncButton, 8, , 0, False, +1.00, 4, 1, 44, , True
      AutoLayout      =   SyncButton, 3, StopButton, 4, False, +1.00, 4, 1, 20, , True
      AutoLayout      =   SyncButton, 7, , 0, False, +1.00, 4, 1, 140, , True
      Caption         =   "Sync Now"
      CaptionColor    =   &c000000
      ControlCount    =   0
      Enabled         =   True
      Height          =   44
      Left            =   117
      LockedInPosition=   False
      Scope           =   0
      TextFont        =   ""
      TextSize        =   0
      TintColor       =   
      Top             =   319
      Visible         =   True
      Width           =   140
      _ClosingFired   =   False
   End
   Begin MobileTextArea LocationLogArea
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Alignment       =   0
      AllowAutoCorrection=   False
      AllowSpellChecking=   False
      AutoCapitalizationType=   0
      AutoLayout      =   LocationLogArea, 4, <Parent>, 4, False, +1.00, 4, 1, -20, , True
      AutoLayout      =   LocationLogArea, 1, <Parent>, 1, False, +1.00, 4, 1, 20, , True
      AutoLayout      =   LocationLogArea, 2, <Parent>, 2, False, +1.00, 4, 1, -20, , True
      AutoLayout      =   LocationLogArea, 3, SyncButton, 4, False, +1.00, 4, 1, 20, , True
      BorderStyle     =   1
      ControlCount    =   0
      Enabled         =   True
      Height          =   409
      Left            =   20
      LockedInPosition=   False
      maximumCharactersAllowed=   0
      ReadOnly        =   True
      Scope           =   0
      SelectedText    =   ""
      SelectionLength =   0
      SelectionStart  =   0
      Text            =   ""
      TextColor       =   &c000000
      TextFont        =   ""
      TextSize        =   12
      TintColor       =   
      Top             =   383
      Visible         =   True
      Width           =   335
      _ClosingFired   =   False
   End
   Begin MobileButton StopButton
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      AutoLayout      =   StopButton, 9, <Parent>, 9, False, +1.00, 4, 1, 0, , True
      AutoLayout      =   StopButton, 8, , 0, False, +1.00, 4, 1, 20, , True
      AutoLayout      =   StopButton, 3, StartButton, 4, False, +1.00, 4, 1, 20, , True
      AutoLayout      =   StopButton, 7, , 0, False, +1.00, 4, 1, 140, , True
      Caption         =   "Stop Tracking"
      CaptionColor    =   &c000000
      ControlCount    =   0
      Enabled         =   True
      Height          =   20
      Left            =   117
      LockedInPosition=   False
      Scope           =   2
      TextFont        =   ""
      TextSize        =   0
      TintColor       =   
      Top             =   279
      Visible         =   True
      Width           =   140
      _ClosingFired   =   False
   End
End
#tag EndMobileScreen

#tag WindowCode
	#tag Event
		Sub Opening()
		  LogMessage("=== App Started ===")
		  
		  ' Initialize database manager
		  mDBManager = New DatabaseManager
		  LogMessage("✅ Database ready")
		  
		  ' Configure LocationSource
		  LocationSource.Accuracy = MobileLocation.Accuracies.Best
		  LocationSource.AllowBackgroundUpdates = True
		  LogMessage("✅ GPS configured")
		  
		  ' Check authorization state
		  Select Case LocationSource.AuthorizationState
		  Case MobileLocation.AuthorizationStates.NotDetermined
		    LogMessage("⏳ Requesting permission...")
		    StatusLabel.Text = "Requesting permission..."
		    LocationSource.RequestUsageAuthorization(MobileLocation.UsageTypes.Always)
		    
		  Case MobileLocation.AuthorizationStates.AuthorizedAlways
		    LogMessage("✅ Permission: Always")
		    StatusLabel.Text = "Ready to track"
		    
		  Case MobileLocation.AuthorizationStates.AuthorizedAppInUse
		    LogMessage("✅ Permission: When In Use")
		    StatusLabel.Text = "Ready to track"
		    
		  Case MobileLocation.AuthorizationStates.Denied
		    LogMessage("❌ Permission DENIED")
		    StatusLabel.Text = "❌ Location Denied"
		    LogMessage("Go to Settings > Privacy")
		    LogMessage("Enable location for this app")
		    
		  Case MobileLocation.AuthorizationStates.Restricted
		    LogMessage("⚠️ Permission restricted")
		    StatusLabel.Text = "❌ Restricted"
		  End Select
		  
		  ' Create tracker once when screen opens
		  LogMessage("Creating tracker...")
		  mTracker = New LocationTracker
		  LogMessage("✅ Tracker created")
		  
		  ' Add event handlers
		  LogMessage("Adding handlers...")
		  AddHandler mTracker.LocationUpdated, AddressOf HandleLocationUpdated
		  AddHandler mTracker.StatusChanged, AddressOf HandleStatusChanged
		  AddHandler mTracker.SyncFailed, AddressOf HandleSyncFailed
		  LogMessage("✅ Handlers added")
		  
		  
		  LogMessage("=== Ready ===")
		  
		End Sub
	#tag EndEvent


	#tag Method, Flags = &h21
		Private Sub HandleLocationUpdated(sender As LocationTracker, timestamp As DateTime, lat As Double, lon As Double, alt As Double, spd As Double)
		  LogMessage("📦 LocationTracker stored data")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub HandleStatusChanged(sender As LocationTracker, status As Integer)
		  Select Case status
		  Case 0
		    LogMessage("⏸️ Tracker: Stopped")
		    StatusLabel.Text = "⏸️ Stopped"
		    StatusLabel.TextColor = Color.Red
		    StopButton.Enabled = False
		    StartButton.Enabled = True
		    
		  Case 1
		    LogMessage("✅ Tracker: Active")
		    StatusLabel.Text = "✅ Tracking Active"
		    StatusLabel.TextColor = Color.Green
		    StartButton.Enabled = False
		    StopButton.Enabled = True
		    
		    
		  Case 2
		    LogMessage("✅ SYNC SUCCESS!")
		    StatusLabel.Text = "✅ Synced"
		    
		  Case -2
		    LogMessage("ℹ️ No data to sync yet")
		    StatusLabel.Text = "ℹ️ No data"
		    
		  Else
		    LogMessage("Status: " + status.ToString)
		  End Select
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub HandleSyncFailed(sender As LocationTracker, errorMessage As String)
		  LogMessage("❌ Sync FAILED")
		  LogMessage("Error: " + errorMessage)
		  StatusLabel.Text = "❌ Sync Failed"
		  MessageBox("Sync failed: " + errorMessage)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub LogMessage(msg As String)
		  ' Add message to log area with timestamp
		  Var timestamp As String = DateTime.Now.ToString("HH:mm:ss")
		  Var line As String = timestamp + " | " + msg
		  
		  If LocationLogArea <> Nil Then
		    LocationLogArea.Text = line + EndOfLine + LocationLogArea.Text
		    
		    ' Keep only last 100 lines
		    Var lines() As String = LocationLogArea.Text.Split(EndOfLine)
		    If lines.Count > 100 Then
		      ReDim lines(99)
		      LocationLogArea.Text = String.FromArray(lines, EndOfLine)
		    End If
		  End If
		  
		  ' Also send to system debug log
		  System.DebugLog(msg)
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h21
		Private mDBManager As DatabaseManager
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mIsTracking As Boolean = False
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLocationCount As Integer = 0
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mTracker As LocationTracker
	#tag EndProperty


#tag EndWindowCode

#tag Events LocationSource
	#tag Event
		Sub LocationChanged(latitude As Double, longitude As Double, accuracy As Double, altitude As Double, altitudeAccuracy As Double, course As Double, speed As Double)
		  mLocationCount = mLocationCount + 1
		  
		  LogMessage("📍 GPS #" + mLocationCount.ToString)
		  LogMessage("   " + latitude.ToString("#.######") + ", " + longitude.ToString("#.######"))
		  LogMessage("   Accuracy: ±" + accuracy.ToString("#.0") + "m")
		  
		  ' Update status
		  StatusLabel.Text = "📍 Active (" + mLocationCount.ToString + ")"
		  
		  ' Save to database
		  If mDBManager <> Nil Then
		    mDBManager.AddLocation(DateTime.Now, latitude, longitude, altitude, speed)
		  End If
		  
		  ' Pass to tracker if tracking
		  If mTracker <> Nil And mIsTracking Then
		    mTracker.AddLocationData(DateTime.Now, latitude, longitude, altitude, speed)
		  End If
		End Sub
	#tag EndEvent
	#tag Event
		Sub AuthorizationStateChanged(state as MobileLocation.AuthorizationStates)
		  LogMessage("=== Permission Changed ===")
		  
		  Select Case state
		  Case MobileLocation.AuthorizationStates.AuthorizedAlways
		    LogMessage("✅ Granted: Always")
		    StatusLabel.Text = "✅ Authorized (Always)"
		    LogMessage("You can now start tracking")
		    
		  Case MobileLocation.AuthorizationStates.AuthorizedAppInUse
		    LogMessage("✅ Granted: When In Use")
		    StatusLabel.Text = "✅ Authorized (In Use)"
		    LogMessage("You can now start tracking")
		    
		  Case MobileLocation.AuthorizationStates.Denied
		    LogMessage("❌ DENIED by user")
		    StatusLabel.Text = "❌ Location DENIED"
		    LogMessage("Go to Settings > Privacy")
		    LogMessage("Enable location for this app")
		    
		  Case MobileLocation.AuthorizationStates.NotDetermined
		    LogMessage("⏳ User hasn't decided yet")
		    StatusLabel.Text = "⏳ Waiting for permission..."
		    
		  Case MobileLocation.AuthorizationStates.Restricted
		    LogMessage("⚠️ Restricted by system")
		    StatusLabel.Text = "❌ Restricted"
		  End Select
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events StartButton
	#tag Event
		Sub Pressed()
		  LogMessage("=== START PRESSED ===")
		  
		  ' Check authorization
		  Select Case LocationSource.AuthorizationState
		  Case MobileLocation.AuthorizationStates.Denied
		    LogMessage("❌ Can't start - denied")
		    MessageBox("Location access is denied. Enable in Settings.")
		    Return
		    
		  Case MobileLocation.AuthorizationStates.Restricted
		    LogMessage("❌ Can't start - restricted")
		    MessageBox("Location access is restricted.")
		    Return
		    
		  Case MobileLocation.AuthorizationStates.NotDetermined
		    LogMessage("⏳ Requesting permission first...")
		    LocationSource.RequestUsageAuthorization(MobileLocation.UsageTypes.Always)
		    Return
		  End Select
		  
		  
		  
		  
		  
		  ' Start tracking
		  
		  ' Just start the existing tracker
		  If mTracker <> Nil Then
		    LogMessage("Starting tracker...")
		    mTracker.StartTracking()
		    StartButton.Enabled = False
		    StopButton.Enabled = True
		    mIsTracking = True
		  End If
		  
		  
		  
		  
		  
		  
		  ' Start GPS
		  LogMessage("Starting GPS...")
		  LocationSource.Start
		  LogMessage("✅ GPS started")
		  
		  ' Reset counter
		  mLocationCount = 0
		  
		  ' Update UI
		  StartButton.Enabled = False
		  SyncButton.Enabled = True
		  StatusLabel.Text = "⏳ Waiting for GPS..."
		  
		  LogMessage("=== Listening for GPS ===")
		  LogMessage("Waiting for signal...")
		  LogMessage("(May take 30-60 seconds)")
		  LogMessage("Move around if indoors")
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events SyncButton
	#tag Event
		Sub Pressed()
		  LogMessage("=== SYNC PRESSED ===")
		  
		  If mTracker = Nil Then
		    LogMessage("❌ Tracker not initialized")
		    StatusLabel.Text = "❌ Error: Not tracking"
		    Return
		  End If
		  
		  If Not mIsTracking Then
		    LogMessage("❌ Not tracking")
		    StatusLabel.Text = "❌ Start tracking first"
		    Return
		  End If
		  
		  LogMessage("Syncing to server...")
		  LogMessage("Server: " + mTracker.kServerURL)
		  StatusLabel.Text = "⏳ Syncing..."
		  
		  mTracker.SyncToServer()
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events StopButton
	#tag Event
		Sub Pressed()
		  ' Stop location tracking
		  
		  ' Just stop the existing tracker
		  If mTracker <> Nil Then
		    mTracker.StopTracking()
		    StopButton.Enabled = False
		    StartButton.Enabled = True
		  End If
		  
		  StatusLabel.Text = "Stopped"
		  
		  
		  
		End Sub
	#tag EndEvent
#tag EndEvents
#tag ViewBehavior
	#tag ViewProperty
		Name="ControlCount"
		Visible=false
		Group="Behavior"
		InitialValue=""
		Type="Integer"
		EditorType=""
	#tag EndViewProperty
	#tag ViewProperty
		Name="ScaleFactor"
		Visible=false
		Group="Behavior"
		InitialValue=""
		Type="Double"
		EditorType=""
	#tag EndViewProperty
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
	#tag ViewProperty
		Name="BackButtonCaption"
		Visible=true
		Group="Behavior"
		InitialValue=""
		Type="String"
		EditorType="MultiLineEditor"
	#tag EndViewProperty
	#tag ViewProperty
		Name="HasNavigationBar"
		Visible=true
		Group="Behavior"
		InitialValue="True"
		Type="Boolean"
		EditorType=""
	#tag EndViewProperty
	#tag ViewProperty
		Name="TabIcon"
		Visible=true
		Group="Behavior"
		InitialValue=""
		Type="Picture"
		EditorType=""
	#tag EndViewProperty
	#tag ViewProperty
		Name="Title"
		Visible=true
		Group="Behavior"
		InitialValue="Untitled"
		Type="String"
		EditorType="MultiLineEditor"
	#tag EndViewProperty
	#tag ViewProperty
		Name="LargeTitleDisplayMode"
		Visible=true
		Group="Behavior"
		InitialValue="2"
		Type="MobileScreen.LargeTitleDisplayModes"
		EditorType="Enum"
		#tag EnumValues
			"0 - Automatic"
			"1 - Always"
			"2 - Never"
		#tag EndEnumValues
	#tag EndViewProperty
	#tag ViewProperty
		Name="TabBarVisible"
		Visible=true
		Group="Behavior"
		InitialValue="True"
		Type="Boolean"
		EditorType=""
	#tag EndViewProperty
	#tag ViewProperty
		Name="TintColor"
		Visible=false
		Group="Behavior"
		InitialValue=""
		Type="ColorGroup"
		EditorType=""
	#tag EndViewProperty
#tag EndViewBehavior
