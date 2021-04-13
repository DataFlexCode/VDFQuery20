//Use SetDir.vw    // Find file view

Use API_Attr.nui // Functions for querying API attributes (No User Interface)
Use Spec0011.utl // Floating menues on the fly
Use Buttons.utl  // Button texts
Use GridUtil.utl // Grid and List utilities
Use Files.utl    // Utilities for handling file related stuff
Use SetDir.pkg   // cSetOfDirectories class
Use Masks_DF.nui // DataFlex related file masks
Use Strings.nui


// ******************************************************************
//  Text search functions


object oSetOfDirectories is a cSetOfDirectories 
    object oWait is a cProcessStatusPanel
      set allow_cancel_state to DFFALSE
    end_object
    procedure OnWait_On string lsCaption
      set caption_text of (oWait(self)) to lsCaption
      set title_text   of (oWait(self)) to ""
      set message_text of (oWait(self)) to ""
      set action_text  of (oWait(self)) to ""
      send Start_StatusPanel to (oWait(self))
    end_procedure
    procedure OnWait_SetText1 string lsValue
      set Message_Text of (oWait(self)) to lsValue
    end_procedure
    procedure OnWait_SetText2 string lsValue
      set Action_Text of (oWait(self)) to lsValue
    end_procedure
    procedure OnWait_Off
      send Stop_StatusPanel to (oWait(self))
    end_procedure
end_object

object oSetOfFilesNew is a cSetOfFilesNew
  set piSOD_Object to (oSetOfDirectories(self))
end_object

Use Buttons.utl  // Button texts
Use APS.pkg      // Auto Positioning and Sizing classes for VDF

activate_view Activate_FindFileResultVw for oNewFindFileResultVw
object oNewFindFileResultVw is a aps.View label "Find file, result"
  on_key kuser send Activate_SetDirTestVw
  on_key kcancel send close_panel
  object oLst is a cSetOfFilesListNew
    set size to 200 0
    set piSOF_Object to (oSetOfFilesNew(self))
    procedure OnListFilled integer liFileCount number lnBytes
      send total_display (SEQ_FileSizeToString(lnBytes)+" in "+string(liFileCount)+" files")
    end_procedure
    procedure DoReset
      forward send DoReset
      send Activate_SetDirTestVw
    end_procedure
  end_object
  send aps_goto_max_row

  object oSelectTxt is a aps.TextBox
  end_object
  set auto_size_state of (oSelectTxt(self)) to DFTRUE
  procedure total_display string lsValue
    set value of (oSelectTxt(self)) to lsValue
  end_procedure
  object oBtn1 is a aps.Multi_Button
    on_item "Reset list" send DoReset to (oLst(self))
  end_object
  object oBtn2 is a aps.Multi_Button
    on_item "Copy files" send DoCopyFilesToDirectory to (oLst(self))
  end_object
  object oBtn3 is a aps.Multi_Button
    on_item t.btn.close send close_panel
  end_object
  send aps_locate_multi_buttons
  set Border_Style to BORDER_THICK   // Make panel resizeable
  procedure aps_onResize integer delta_rw# integer delta_cl#
    send aps_resize (oLst(self)) delta_rw# 0 // delta_cl#
    send aps_auto_locate_control (oSelectTxt(self)) SL_DOWN (oLst(self))
    send aps_register_multi_button (oBtn1(self))
    send aps_register_multi_button (oBtn2(self))
    send aps_register_multi_button (oBtn3(self))
    send aps_locate_multi_buttons
    send aps_auto_size_container
  end_procedure
  procedure fill_list
    send fill_list to (oLst(self))
  end_procedure
end_object // oNewFindFileResultVw
procedure Activate_FindFileResultVwReFill
  send fill_list to (oNewFindFileResultVw(self))
  send Activate_FindFileResultVw
end_procedure

activate_view Activate_SetDirTestVw for oNewFindFileVw
object oNewFindFileVw is a aps.View label "Find file"
  on_key kuser send Activate_FindFileResultVw
  set pMinimumSize to 220 0
  on_key kcancel send close_panel
  object oLstHeader is a aps.Textbox label "Folders in search path"
  end_object
  object oLst is a cSetOfDirectoriesList snap SL_DOWN
    set size to 170 0
    set piSetOfDirectoriesObject to (oSetOfDirectories(self))
    register_object oLstTotal
    set Horz_Scroll_Bar_Visible_State to false

    procedure OnListChanged integer liItems
      set value of (oLstTotal(self)) to ("  "+string(liItems)+" folders")
    end_procedure
  end_object
  object oLstTotal is a aps.Textbox label "  0 folders         "
  end_object
  send aps_goto_max_row
  object oFrm is a aps.Form abstract AFT_ASCII80 label "Find this file (wildcards allowed):"
    set p_extra_internal_width to -240
    register_object oBtn4
    on_key kenter send goto_search_button
  end_object
  procedure DoAddOne
    send DoAddDirectory to (oLst(self))
  end_procedure
  procedure DoAddSub
    send DoAddSubDirectories to (oLst(self))
  end_procedure
  procedure DoMakePath
    integer lhoWorkSpace
    string lsPath
    get_profile_string "DfComp" "MakePath" to lsPath
#IFDEF get_DFMatrix_WorkSpaceLoaded
    if (DFMatrix_WorkSpaceLoaded()) begin
      get phoWorkspace of ghoApplication To lhoWorkSpace
      move (psAppSrcPath(lhoWorkSpace)+";"+psProgramPath(lhoWorkSpace)+";"+psDataPath(lhoWorkSpace)+";"+psDdSrcPath(lhoWorkSpace)+";"+psHelpPath(lhoWorkSpace)+";"+psSystemMakePath(lhoWorkSpace)) to lsPath
    end
#ENDIF
    send DoAddSearchPath to (oLst(self)) lsPath
  end_procedure
  procedure DoDFPath
    integer lhoWorkSpace
    string lsPath
#IFDEF get_DFMatrix_WorkSpaceLoaded
    get phoWorkspace of ghoApplication To lhoWorkSpace
    if (DFMatrix_WorkSpaceLoaded()) move (psDfPath(lhoWorkSpace)) to lsPath
    else move (API_AttrValue_GLOBAL(DF_OPEN_PATH)) to lsPath // Oem fixed!
    move (ToOem(lsPath)) to lsPath
#ELSE
    move (API_AttrValue_GLOBAL(DF_OPEN_PATH)) to lsPath
#ENDIF
    send DoAddSearchPath to (oLst(self)) lsPath
  end_procedure
  send DoDFPath // Default value
  procedure DoPath
    send DoAddSearchPath to (oLst(self)) (API_OtherAttr_Value(OA_PATH))
  end_procedure
  procedure DoReset
    send DoReset to (oLst(self))
  end_procedure
  object oBtn1 is a aps.Button snap SL_RIGHT relative_to (oLst(self))
    set size to 14 70
    procedure PopupFM
      send FLOATMENU_PrepareAddItem msg_DoAddOne   "One folder"
      send FLOATMENU_PrepareAddItem msg_DoAddSub   "Sub-folders"
      send FLOATMENU_PrepareAddItem msg_DoMakePath "MakePath"
      send FLOATMENU_PrepareAddItem msg_DoDFPath   "DFPath"
      send FLOATMENU_PrepareAddItem msg_DoPath     "EXE search path"
      send FLOATMENU_PrepareAddItem msg_none       ""
      send FLOATMENU_PrepareAddItem msg_DoReset    "Reset list"
      send popup to (FLOATMENU_Apply(self))
    end_procedure
    on_item "Add folders" send PopupFM
  end_object
  object oBtn2 is a aps.Button snap SL_DOWN
    set size to 14 70
    on_item "Remove from list" send DoRemoveDirectory to (oLst(self))
  end_object
  object oBtn3 is a aps.Button snap SL_DOWN
    set size to 14 70
    on_item "Reset list" send DoReset
  end_object
  object oSpacer1 is a aps.Textbox label " " snap SL_DOWN
  end_object
  object oBtn4 is a aps.Button snap SL_DOWN
    set size to 14 70
    on_item "Find file" send DoFindFile
  end_object
  object oBtn4 is a aps.Button snap SL_DOWN
    set size to 14 70
    register_procedure DoFindDFSource
    register_procedure DoFindDFData
    register_procedure DoFindDFRuntime
    register_procedure DoFindDFAll
    procedure PopupFM
      send FLOATMENU_PrepareAddItem msg_DoFindDFSource  "DF source code"
      send FLOATMENU_PrepareAddItem msg_DoFindDFData    "DF data files"
      send FLOATMENU_PrepareAddItem msg_DoFindDFRuntime "DF runtime files"
      send FLOATMENU_PrepareAddItem msg_DoFindDFAll     "All DF files"
      send popup to (FLOATMENU_Apply(self))
    end_procedure
    on_item "Special find (slow)" send PopupFM
  end_object
  procedure goto_search_button
    send activate to (oBtn4(self))
  end_procedure
  object oBtn5 is a aps.Button snap SL_DOWN
    set size to 14 70
    on_item "Scan PR? file" send DoFindPrnFile
  end_object
  object oFirstOccuranceOnly is a aps.CheckBox label "1st occur. only" snap SL_DOWN
  end_object
  object oSpacer2 is a aps.Textbox label " " snap SL_DOWN
  end_object
  object oBtnClose is a aps.Button snap SL_DOWN
    set size to 14 70
    on_item t.btn.close send close_panel
  end_object
  procedure DoFindFile
    integer lbFirstOnly
    string lsFileMask
    get value of (oFrm(self)) item 0 to lsFileMask
    if (lsFileMask<>"") begin
      get select_state of (oFirstOccuranceOnly(self)) to lbFirstOnly
      send DoFindFile to (oSetOfFilesNew(self)) lsFileMask lbFirstOnly
      send Activate_FindFileResultVwReFill
    end
    else begin
      send obs "You must enter a file name before finding."
      send activate to (oFrm(self))
    end
  end_procedure
  procedure DoFindDFSource
    integer lbFirstOnly
    get select_state of (oFirstOccuranceOnly(self)) to lbFirstOnly
    send DoFindFileBySetOfMasks to (oSetOfFilesNew(self)) (oSetOfMasks_DFSource(self)) lbFirstOnly
    send Activate_FindFileResultVwReFill
  end_procedure
  procedure DoFindDFData
    integer lbFirstOnly
    get select_state of (oFirstOccuranceOnly(self)) to lbFirstOnly
    send DoFindFileBySetOfMasks to (oSetOfFilesNew(self)) (oSetOfMasks_DFData(self)) lbFirstOnly
    send Activate_FindFileResultVwReFill
  end_procedure
  procedure DoFindDFRuntime
    integer lbFirstOnly
    get select_state of (oFirstOccuranceOnly(self)) to lbFirstOnly
    send DoFindFileBySetOfMasks to (oSetOfFilesNew(self)) (oSetOfMasks_DFRuntime(self)) lbFirstOnly
    send Activate_FindFileResultVwReFill
  end_procedure
  procedure DoFindDFAll
    integer lbFirstOnly
    get select_state of (oFirstOccuranceOnly(self)) to lbFirstOnly
    send DoFindFileBySetOfMasks to (oSetOfFilesNew(self)) (oSetOfMasks_DFAll(self)) lbFirstOnly
    send Activate_FindFileResultVwReFill
  end_procedure
  procedure DoFindPrnFile
    integer lbFirstOnly
    string lsPrnFile
    get SEQ_SelectFile "Select compiler listing file" "Compiler listing (*.prn)|*.PRN|Precompile listing (*.prp)|*.PRP" to lsPrnFile
    if lsPrnFile ne "" begin
      get select_state of (oFirstOccuranceOnly(self)) to lbFirstOnly
      send DoFindFilesCompilerListing to (oSetOfFilesNew(self)) lsPrnFile lbFirstOnly
      send Activate_FindFileResultVwReFill
    end
  end_procedure
  procedure aps_beautify
    send aps_align_by_moving (oFrm(self)) (oLst(self)) SL_ALIGN_RIGHT
    send aps_align_by_moving (oLstTotal(self)) (oLst(self)) SL_ALIGN_BOTTOM
  end_procedure
  set Border_Style to BORDER_THICK   // Make panel resizeable
  procedure aps_onResize integer delta_rw# integer delta_cl#
    send aps_resize (oLst(self)) delta_rw# 0 // delta_cl#
    send aps_auto_locate_control (oFrm(self)) SL_DOWN (oLst(self))
    send aps_beautify
    send aps_register_max_rc (oBtn1(self))
    send aps_auto_size_container
  end_procedure
end_object // oNewFindFileVw

