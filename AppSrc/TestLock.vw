// Skriv lock count efter hver lock/unlock
// Make panel resizable
// Skriv DF-fejlmeddelser ind i listen
// Giv mulighed for at logge sekvensen til fil (f‘lles med en anden maskine). N†r denne funktion v‘lges
// promptes brugeren for det navn som processen skal identificere sig med i loggen.
// Hvis "Open (share)" og "Open (Excl)" lukker filerne f›r de †bner dem, s† skriv det (i listen).
// Skriv hvilken DB-driver hvergang en tabel †bnes.
// Indf›r "Reset list" knap
// Marker grafisk hvilke knapper, der er "Table operation" buttons.
//
// Reset list, Log to file,
//
//   TestLock is a utility that allows you to test the table locking function in DataFlex.
//
//   Select a table to test. Start another DFMatrix and select the same table. Then Perform
//   the operations you desire by clicking the "table operation" buttons.
//
//   If any DF-errors occurs during operation, they will appear in the log-listing.
//
//   Finally, you may have more instances of TestLock (DFMatrix) writing to the same disk-file log at
//   the same time. This may be used to help document a special sequence of events, that
//   leads to an error situation.

Use aps.pkg      // Auto Positioning and Sizing classes for VDF
Use Buttons.utl  // Button texts
Use Files.utl    // Utilities for handling file related stuff
Use OpenStat.nui // cTablesOpenStatus class (formely cFileAllFiles) (No User Interface)
Use DBMS.nui     // Basic DBMS functions (No User Interface)
Use Version.nui

enumeration_list
  define TLOP_DoOpenShare
  define TLOP_DoOpenExclusive
  define TLOP_DoCloseTable
  define TLOP_DoLock
  define TLOP_DoUnlock
end_enumeration_list

object oTestLockVw is a aps.ModalPanel label "Test file locking"
  set locate_mode to CENTER_ON_SCREEN
  on_key kcancel send close_panel

  object oRootName is a aps.Form abstract AFT_ASCII80 label "Table name"
    set p_extra_internal_width to -150
    procedure prompt
      string lsFileName
      get SEQ_SelectInFile "Select data file" "DataFlex data files|*.dat|Intermediate files|*.int" to lsFileName
      if lsFileName ne "" set value item 0 to lsFileName
    end_procedure
    on_key kprompt send Prompt
    set peAnchors to (anRight+anLeft+anTop)
  end_object
  object oPrompt is a aps.Button
    on_item "Browse" send prompt to (oRootName(self))
    set peAnchors to (anRight+anTop)
  end_object
  send aps_goto_max_row
  object oLst is a aps.List
    set size to 100 360
    procedure Add_Line string lsValue
      integer liItem
      get item_count to liItem
      send add_item MSG_NONE lsValue
      set current_item to liItem
    end_procedure
    set peAnchors to (anRight+anLeft+anTop+anBottom)
  end_object

  send aps_goto_max_row

  procedure TakeAction integer liOpCodesend
    integer liResult
    string lsFileName

    if (liOpCodesend=TLOP_DoOpenShare) begin
      get value of oRootName to lsFileName
      get DBMS_OpenFileAs lsFileName 10 DF_SHARE 0 to liResult
      send add_line to oLst (if(liResult,"Ok","Failure"))
    end
    if (liOpCodesend=TLOP_DoOpenExclusive) begin
      get value of oRootName to lsFileName
      get DBMS_OpenFileAs lsFileName 10 DF_EXCLUSIVE 0 to liResult
      send add_line to oLst (if(liResult,"Ok","Failure"))
    end
    if (liOpCodesend=TLOP_DoCloseTable) begin
      close 10
    end
    if (liOpCodesend=TLOP_DoLock) begin
      lock
    end
    if (liOpCodesend=TLOP_DoUnlock) begin
      unlock
    end
    send add_line to oLst "Ready!"
  end_procedure

  procedure DoOpenShare
    integer liResult
    send add_line to (oLst(self)) "Open (shared)..."
    send TakeAction TLOP_DoOpenShare

  end_procedure
  procedure DoOpenExclusive
    send add_line to (oLst(self)) "Open (exclusive)..."
    send TakeAction TLOP_DoOpenExclusive
  end_procedure
  procedure DoCloseTable
    send add_line to (oLst(self)) "Close table..."
    send TakeAction TLOP_DoCloseTable
  end_procedure
  procedure DoLock
    send add_line to (oLst(self)) "Lock..."
    send TakeAction TLOP_DoLock
  end_procedure
  procedure DoUnlock
    send add_line to (oLst(self)) "Unlock..."
    send TakeAction TLOP_DoUnlock
  end_procedure

  object oBtn1 is a aps.Multi_Button
    on_item "Open (share)" send DoOpenShare
    set peAnchors to (anRight+anBottom)
  end_object
  object oBtn2 is a aps.Multi_Button
    on_item "Open (excl.)" send DoOpenExclusive
    set peAnchors to (anRight+anBottom)
  end_object
  object oBtn3 is a aps.Multi_Button
    on_item "Close table"  send DoCloseTable
    set peAnchors to (anRight+anBottom)
  end_object
  send aps_locate_multi_buttons
  object oBtn4 is a aps.Multi_Button
    on_item "Lock"         send DoLock
    set peAnchors to (anRight+anBottom)
  end_object
  object oBtn5 is a aps.Multi_Button
    on_item "Unlock"       send DoUnlock
    set peAnchors to (anRight+anBottom)
  end_object
  object oBtn6 is a aps.Multi_Button
    on_item "Close panel"  send close_panel
    set peAnchors to (anRight+anBottom)
  end_object
  send aps_locate_multi_buttons
  set Border_Style to BORDER_THICK   // Make panel resizeable
  procedure popup
    send OpenStat_RegisterFiles
    send OpenStat_CloseAllFiles
    forward send popup
    send OpenStat_RestoreFiles
  end_procedure
end_object // oTestLockVw

procedure Popup_TestLockPanel
  send popup to (oTestLockVw(self))
end_procedure
