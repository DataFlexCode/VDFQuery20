Use Fdx1.utl     // FDX aware display global attributes (FDX_DisplayGlobalAttributes procedure)
Use Fdx2.utl     // FDX aware object for displaying a table definiton
Use Fdx3.utl     // FDX aware cFileList_List selector class
Use SetFiles.pkg // Class for displaying the contents of a cSetOfFiles object
Use GridUtil.utl // Grid and List utilities
Use FDXSet.vw    // Display contents of cSetOfFiles cSetOfFieldsUse FDXSet.vw    // Display contents of cSetOfFiles cSetOfFields

object oFdxDisplayGlobalAttributes is a aps.View label "Global attributes"
  on_key kcancel send close_panel
  set Border_Style to BORDER_THICK   // Make panel resizeable
  object oLst is a cFdxGlobalAttrGrid
  set peAnchors to (anTop+anLeft+anBottom+anRight)
  set peResizeColumn to rcAll
  end_object
  object oBtn1 is a aps.Multi_Button
    on_item "Folders" send Activate_Directory_Contents
  set peAnchors to (anBottom+anRight)
  end_object
  object oBtn2 is a aps.Multi_Button
    on_item t.btn.close send close_panel
  set peAnchors to (anBottom+anRight)
  end_object
  send aps_locate_multi_buttons
  procedure OnChangeFDX
    integer oFDX#
    move (fdx.object_id(0)) to oFDX#
    send fill_list.i to (oLst(self)) oFDX#
    set dynamic_update_state of (oLst(self)) to true
  end_procedure
  send DFMatrix_Vw_Register WAY_GLOBAL_ATTRIBUTES_VW self
end_object // oFdxDisplayGlobalAttributes
 send aps_SetMinimumDialogSize (oFdxDisplayGlobalAttributes(self))
procedure Activate_Global_Attributes
  send popup to (oFdxDisplayGlobalAttributes(self))
end_procedure

object oFdxDisplayFileAttributes is a aps.View label "Table definition"
  property integer piFDX_Server 0
  property integer piMain_File  0
  property integer piIndex      1
  on_key kcancel send close_panel
  on_key key_ctrl+key_d send DoDisplaySelector
  set Border_Style to BORDER_THICK   // Make panel resizeable
  procedure DoDisplaySelector
    send Activate_Table_Selector
  end_procedure
  object oTabs is a aps.TabDialog
    set peAnchors to (anTop+anLeft+anBottom+anRight)
    object oTab1 is a aps.TabPage label "Fields"
      set p_Auto_Column to false
      object oFields is a cFDX.Display.FieldList
        set size to 160 0
        set peAnchors to (anTop+anLeft+anBottom+anRight)
        set peResizeColumn to rcAll
      end_object
    end_object
    register_object oIndexFields
    object oTab2 is a aps.TabPage label "Indices"
      object oIndexNo is a cFDX.Display.IndexList
        set size to 160 0
        set peAnchors to (anTop+anBottom)
        set peResizeColumn to rcAll
        procedure item_change integer from# integer to# returns integer
          integer rval#
          forward get msg_item_change from# to# to rval#
          set piIndex to (rval#+1)
          send fill_list to (oIndexFields(self))
          send display_info
          procedure_return rval#
        end_procedure
      end_object
      set p_auto_column to false
      object oIndexFields is a cFDX.Display.IndexSegmentList
        set peAnchors to (anTop+anLeft+anBottom+anRight)
        set peResizeColumn to rcAll
        set size to 160 0
      end_object
      object oFrm1 is a aps.Form label "Key length:" abstract aft_numeric4.0 snap sl_right_space
        set peAnchors to (anTop+anRight)
        set object_shadow_state to true
      end_object
      object oFrm2 is a aps.Form label "Levels:" abstract aft_numeric4.0 snap sl_down
        set peAnchors to (anTop+anRight)
        set object_shadow_state to true
        set label_offset to 0 0
        set label_justification_mode to jmode_right
      end_object
      object oFrm3 is a aps.Form label "Batch:" abstract aft_ascii4 snap sl_down
        set peAnchors to (anTop+anRight)
        set object_shadow_state to true
        set label_offset to 0 0
        set label_justification_mode to jmode_right
      end_object
      procedure display_info
        integer idx# attr#
        integer file# fdx#
        get piMain_File to file#
        get piFDX_Server to fdx#
        get piIndex to idx#
        move (FDX_AttrValue_INDEX(fdx#,DF_INDEX_KEY_LENGTH,file#,idx#)) to attr#
        set value of (oFrm1(self)) item 0 to attr#
        move (FDX_AttrValue_INDEX(fdx#,DF_INDEX_LEVELS,file#,idx#)) to attr#
        set value of (oFrm2(self)) item 0 to attr#
        move (FDX_AttrValue_INDEX(fdx#,DF_INDEX_TYPE,file#,idx#)) to attr#
        if attr# eq DF_INDEX_TYPE_ONLINE set value of (oFrm3(self)) item 0 to "No"
        else                             set value of (oFrm3(self)) item 0 to "Yes"
      end_procedure
    end_object
    object oTab3 is a aps.TabPage label "Attributes"
      object oOther is a cFDX.Display.FileOtherList
        set size to 160 0
        set peAnchors to (anTop+anLeft+anBottom+anRight)
        set peResizeColumn to rcAll
      end_object
    end_object
  end_object
  object oBtn is a aps.Multi_Button
    on_item t.btn.close send close_panel
    set peAnchors to (anBottom+anRight)
  end_object
  send aps_locate_multi_buttons
  procedure OnChangeFdxFile
    integer oFDX# file#
    move (fdx.object_id(0)) to oFDX#
    get DFMatrix_Current_File to file#
    set piFDX_Server to oFDX#
    set piMain_File  to file#
    if (active_state(self)) begin // Only if on screen
      if (file# and piDataOrigin(oFDX#)<>FDX_EMPTY) begin
        send fill_list to (oFields(oTab1(oTabs(self))))
        set piIndex to 1
        send fill_list to (oIndexNo(oTab2(oTabs(self))))
        send fill_list to (oIndexFields(oTab2(oTabs(self))))
        send display_info to (oTab2(oTabs(self)))
        send fill_list to (oOther(oTab3(oTabs(self)))) oFDX#
      end
      else begin
        send delete_data to (oFields(oTab1(oTabs(self))))
        send delete_data to (oOther(oTab3(oTabs(self))))
        send delete_data to (oIndexNo(oTab2(oTabs(self))))
        send delete_data to (oIndexFields(oTab2(oTabs(self))))
      end
    end
  end_procedure
  procedure popup
    forward send popup
    send OnChangeFdxFile
  end_procedure
  procedure OnChangeFDX
    send OnChangeFdxFile
  end_procedure
  send DFMatrix_Vw_Register WAY_TABLE_DEFINITION_VW self
end_object // oFdxDisplayFileAttributes
send aps_SetMinimumDialogSize (oFdxDisplayFileAttributes(self))

procedure Activate_Table_Definition
  send popup to (oFdxDisplayFileAttributes(self))
end_procedure

object oDFMatrix_AdvancedSelect_FM is a FloatingPopupMenu
  send add_item msg_Activate_SetOfTables "Build set of &tables"
  send add_item msg_Activate_SetOfFields "Build set of &fields"
  send add_item msg_Activate_SetOfIndices "Build set of &indices"
end_object

object oUserSelectTables is a aps.View label "Table selector"
  set Border_Style to BORDER_THICK   // Make panel resizeable
  set pMinimumSize to 225 0 // Size no less than this
  on_key kCancel send close_panel
  procedure DoDisplayDefinition
    integer vw# sz#
    move (oFdxDisplayFileAttributes(self)) to vw#
    ifnot (active_state(vw#)) begin
      send Activate_Table_Definition
      set location to 5 5
      get size to sz#
      move (hi(sz#)) to sz#
      send aps_onResize (230-sz#) 0
      set location of vw# to 235 5
    end
    else send Activate_Table_Definition
  end_procedure
  register_object oLst
  on_key key_ctrl+key_a send select_all_not_bad to (oLst(self))
  on_key key_ctrl+key_c send select_none        to (oLst(self))
  on_key key_ctrl+key_d send DoDisplayDefinition
  on_key key_ctrl+key_h send select_children    to (oLst(self))
  on_key key_ctrl+key_i send select_invert      to (oLst(self))
  on_key key_ctrl+key_l send load_current_selection.browse to (oLst(self))
  on_key key_ctrl+key_m send select_master      to (oLst(self))
  on_key key_ctrl+key_p send select_parents     to (oLst(self))
  on_key key_ctrl+key_s send save_current_selection.browse to (oLst(self))
  on_key key_ctrl+key_g send Activate_Global_Attributes
  object oLst is a cFdxFileMultiSelector
    set size to 180 0
    set piNo_Alias_State to false
    set piBad_Entries_State to BAD_ENTRIES_SHADOW
    set piGeneric_Display_Name_State to true
    on_key key_ctrl+key_d send DoDisplayDefinition
    set peAnchors to (anTop+anLeft+anBottom+anRight)
    set peResizeColumn to rcAll
    procedure sort.i integer by#
      forward send sort.i by#
      send OnChangeFile 0
    end_procedure
    procedure OnChangeFile integer row#
      if (item_count(self)) begin
        if (Row_Shadow_State(self,row#)) send DFMatrix_NewFileInSelector 0
        else send DFMatrix_NewFileInSelector (Row_File(self,row#))
      end
    end_procedure
    procedure row_change integer row_from# integer row_to#
      send OnChangeFile row_to#
    end_procedure
    procedure re_order
    end_procedure
    procedure update_select_display // This is called automatically by the class
      integer selected# total#
      get File_Select_Count to selected#
      get Row_Count to total#
      send select_display selected# total#
    end_procedure
  end_object // oLst

  object oSelectTxt is a aps.TextBox snap sl_right
    set peAnchors to (anBottom+anRight)
  end_object
  set auto_size_state of (oSelectTxt(self)) to true
  send aps_align_by_moving (oSelectTxt(self)) (oLst(self)) SL_ALIGN_BOTTOM
  procedure select_display integer selected# integer total#
    set value of (oSelectTxt(self)) to ("Selected: "+string(selected#)+"/"+string(total#))
  end_procedure

  object oBtn11 is a aps.multi_button
    on_item "&All"      send select_all_not_bad to (oLst(self))
    set peAnchors to (anTop+anRight)
  end_object
  object oBtn12 is a aps.multi_button
    on_item "&Clear"    send select_none        to (oLst(self))
    set peAnchors to (anTop+anRight)
  end_object
  object oBtn13 is a aps.multi_button
    on_item "&Invert"   send select_invert      to (oLst(self))
    set peAnchors to (anTop+anRight)
  end_object
  object oBtn14 is a aps.multi_button
    on_item "&Master"   send select_master      to (oLst(self))
    set peAnchors to (anTop+anRight)
  end_object
  object oBtn15 is a aps.multi_button
    on_item "&Parents"  send select_parents     to (oLst(self))
    set peAnchors to (anTop+anRight)
  end_object
  object oBtn16 is a aps.multi_button
    on_item "C&hildren" send select_children    to (oLst(self))
    set peAnchors to (anTop+anRight)
  end_object
  object oBtn17 is a aps.multi_button
    procedure DoAction
      send popup to (oDFMatrix_AdvancedSelect_FM(self))
    end_procedure
    on_item "Advanced" send DoAction
    set peAnchors to (anTop+anRight)
  end_object
  object oBtn18 is a aps.multi_button
    on_item "Show &definition" send DoDisplayDefinition
    set peAnchors to (anTop+anRight)
  end_object
  send aps_register_multi_button (oBtn18(self))

  object oBtn19 is a aps.multi_button
    on_item "&Global attr." send Activate_Global_Attributes
    set peAnchors to (anTop+anRight)
  end_object
  send aps_locate_multi_buttons sl_vertical
  send aps_goto_max_row
  send aps_make_row_space 3
  object oLine is a aps.LineControl
    set peAnchors to (anBottom+anRight+anLeft)
  end_object
  object oBtn1 is a aps.multi_button
    on_item "&Load selection" send load_current_selection.browse to (oLst(self))
    set peAnchors to (anBottom+anRight)
  end_object
  object oBtn2 is a aps.multi_button
    on_item "&Save selection" send save_current_selection.browse to (oLst(self))
    set peAnchors to (anBottom+anRight)
  end_object
  object oBtn3 is a aps.multi_button
    on_item "Close"          send close_panel
    set peAnchors to (anBottom+anRight)
  end_object
  send aps_locate_multi_buttons
  function iCallback_Selected_Files integer get# integer obj# returns integer
    integer rval#
    get iCallback_Selected_Files_Server of (oLst(self)) get# obj# to rval#
    function_return rval#
  end_function
  procedure OnChangeFdx
    integer oFDX# lst#
    move (oLst(self)) to lst#
    move (fdx.object_id(0)) to oFDX#
    set piFDX_Server of lst# to oFDX#
    send fill_list_all_files to lst#
    set dynamic_update_state of lst# to true
    send OnChangeFile to lst# 0
  end_procedure
  procedure aps_beautify
    send APS_ALIGN_INSIDE_CONTAINER_BY_SIZING (oLine(self)) SL_ALIGN_RIGHT
  end_procedure
  send DFMatrix_Vw_Register WAY_TABLE_SELECTOR_VW self
end_object // oUserSelectTables
send aps_SetMinimumDialogSize (oUserSelectTables(self))

procedure Activate_Table_Selector
  send popup to (oUserSelectTables(self))
end_procedure
register_object oList
object oListDirectoryContents is a aps.View label "Directory contents"
  on_key kcancel send close_panel
  property integer piFDX_Server 0
  set Border_Style to BORDER_THICK   // Make panel resizeable
  object oPaths is a aps.ComboFormAux label "Constrain directory:"
    set combo_sort_state to false
    set form_margin item 0 to 60
    set entry_state item 0 to false
    procedure fill
      integer obj# itm# max#
      send Combo_Delete_Data
      send combo_add_item "All" 0
      move (oListDir_SnapShot(piFDX_Server(self))) to obj#
      get iPath_Count of obj# to max#
      for itm# from 0 to (max#-1)
        send combo_add_item (sPath.i(obj#,itm#)) (itm#+1)
      loop
    end_procedure
    procedure OnChange
      string path#
      get value item 0 to path#
      if path# eq "All" move "" to path#
      set psConstrainPath of (oList(self)) to path#
      send fill_list to (oList(self))
    end_procedure
  end_object
  send aps_goto_max_row
  object oList is a cSetOfFilesList
    set size to 196 0
    procedure fill_list_start
      set piSetOfFilesObject to (oListDir_SnapShot(piFDX_Server(self)))
      send fill_list
      send fill_other
    end_procedure
    procedure display_totals number file_count# number total_bytes#
      send total_display (SEQ_FileSizeToString(total_bytes#)+" in "+string(file_count#)+" files")
    end_procedure
  end_object
  send aps_goto_max_row

  object oSelectTxt is a aps.TextBox
  end_object
  set auto_size_state of (oSelectTxt(self)) to true
  procedure total_display string str#
    set value of (oSelectTxt(self)) to str#
  end_procedure
  procedure fill_other // is called from oList object
    send fill to (oPaths(self))
  end_procedure
  set multi_button_size to 14 80
  object oBtn1 is a aps.Multi_Button
    on_item "Read folders" send DFMatrix_OpenDirectoryContents
  end_object
  object oBtn2 is a aps.Multi_Button
    on_item t.btn.close send close_panel
  end_object
  send aps_locate_multi_buttons
  procedure OnChangeFdx
    integer oFDX#
    move (fdx.object_id(0)) to oFDX#
    set piFDX_Server to oFDX#
    send fill_list_start to (oList(self))
  end_procedure
  send DFMatrix_Vw_Register WAY_DIRECTORY_CONTENTS_VW self
end_object // oListDirectoryContents
procedure Activate_Directory_Contents
  send popup to (oListDirectoryContents(self))
end_procedure
