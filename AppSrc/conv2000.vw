// Use Conv2000.vw  // Activate_Conv2000_Vw (for use in the DFMatrix environment)

Use Conv2000.pkg // UI bricks for reindexing a set of tables
Use Spec0011.utl // Floating menues on the fly
Use API_Attr.utl // Functions for querying API attributes
Use Files.utl    // Utilities for handling file related stuff

/Conv2000.Vw.Intro
 $Title$ Reindexing of tables

 With this utility you may reindex tables
/*

activate_view Activate_Conv2000_Vw for oConv2000_Vw
object oConv2000_Vw is a aps.View label "Year 2000 Convertions"
  on_key KCANCEL send close_panel
  object oLst is a cConv2000List
    set size to 225 0
    register_object oTotal
    procedure update_total integer iItemsInList
      set value of (oTotal(self)) to (string(iItemsInList)+" tables")
    end_procedure
  end_object
  object oTotal is a aps.TextBox label "" snap SL_DOWN
    set fixed_size to 12 60
    set justification_mode to JMODE_LEFT
  end_object
  send update_total to (oLst(self)) 0
  procedure DoConvTables
    send DoConv to (oLst(self))
  end_procedure
  procedure DoGetTablesSelector_Help integer iFile integer iSelected integer iShaded
    string sRoot
    get API_AttrValue_FILELIST DF_FILE_ROOT_NAME iFile to sRoot
    send Y2K_Add_Rootname sRoot
  end_procedure
  procedure DoGetTablesSelector
    send cursor_wait to (cursor_control(self))
    send DFMatrix_CallBack_Selected_Files msg_DoGetTablesSelector_Help self 1 0 1
    send fill_list to (oLst(self))
    send cursor_ready to (cursor_control(self))
  end_procedure
  procedure DoGetTablesDirectories
    string sDir
    get SEQ_SelectDirectory "Select directory structure" to sDir
    if sDir ne "" begin
      send cursor_wait to (cursor_control(self))
      send Y2K_Add_RootNamesInDirectories sDir
      send fill_list to (oLst(self))
    send cursor_ready to (cursor_control(self))
    end
  end_procedure
  procedure DoGetTablesDirectory
    string sDir
    get SEQ_SelectDirectory "Select directory" to sDir
    if sDir ne "" begin
      send cursor_wait to (cursor_control(self))
      send Y2K_Add_RootNamesInDirectory sDir
      send fill_list to (oLst(self))
      send cursor_ready to (cursor_control(self))
    end
  end_procedure
  procedure DoGetTablesAllWS
    string sDir
    send cursor_wait to (cursor_control(self))
    get_profile_string "defaults" "VDFRootDir" to sDir
    send Y2K_Add_RootNamesInAllWS
    send Y2K_Add_RootNamesInDirectories sDir
    send fill_list to (oLst(self))
    send cursor_ready to (cursor_control(self))
  end_procedure
  procedure DoGetTableBrowse
    string sRoot
    get SEQ_SelectInFile "Select data file to convert" "DAT files|*.dat" to sRoot
    if sRoot ne "" begin
      send Y2K_Add_Rootname sRoot
      send fill_list to (oLst(self))
    end
  end_procedure
  procedure DoProperties
    send DoProperties to (oLst(self))
  end_procedure
  procedure DoReset
    send reset to (oLst(self))
  end_procedure
  object oBtn1 is a aps.Multi_Button
    procedure PopupFM
      send FLOATMENU_PrepareAddItem msg_DoGetTablesSelector    "Get tables from table selector"
      send FLOATMENU_PrepareAddItem msg_DoGetTableBrowse       "Browse for one table"
      send FLOATMENU_PrepareAddItem msg_DoGetTablesDirectory   "Get all tables in folder"
      send FLOATMENU_PrepareAddItem msg_DoGetTablesDirectories "Get all tables in folder and below"
      send FLOATMENU_PrepareAddItem msg_DoGetTablesAllWS       "Get tables from all Work Spaces"
      send popup to (FLOATMENU_Apply(self))
    end_procedure
    on_item "Add tables"  send PopupFM
  end_object
  object oBtn2 is a aps.Multi_Button
    on_item "Convert tables" send DoConvTables
  end_object
  object oBtn3 is a aps.Multi_Button
    on_item "Reset list"  send DoReset
  end_object
//object oBtn4 is a aps.Multi_Button
//  on_item "Properties" send DoProperties
//end_object
  object oBtn5 is a aps.Multi_Button
    on_item "Close" send close_panel
  end_object
  send aps_locate_multi_buttons
  set Border_Style to BORDER_THICK   // Make panel resizeable
  procedure aps_onResize integer delta_rw# integer delta_cl#
    send aps_resize (oLst(self)) delta_rw# 0 // delta_cl#
    send aps_auto_locate_control (oTotal(self)) SL_DOWN (oLst(self))
    send aps_register_multi_button (oBtn1(self))
    send aps_register_multi_button (oBtn2(self))
    send aps_register_multi_button (oBtn3(self))
//  send aps_register_multi_button (oBtn4(self))
    send aps_register_multi_button (oBtn5(self))
    send aps_locate_multi_buttons
    send aps_auto_size_container
  end_procedure
end_object
