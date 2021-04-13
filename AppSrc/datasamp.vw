Use DataSamp.utl // Class for sampling data file values (Field statistics)
Use FdxSelct.utl // Functions iFdxSelectOneFile and iFdxSelectOneField
Use SetOfFld.utl // cSetOfFields class
Use OpenStat.nui // cTablesOpenStatus class (formely cFileAllFiles)
Use DBMS.utl     // Basic DBMS functions
Use Strings.utl  // String manipulation for VDF and 3.1
Use Files.utl    // Utilities for handling file related stuff

class cDisplayDataSamplerSet is a aps.Grid
  procedure construct_object integer img#
    forward send construct_object img#
    property integer piDataType 0
    property integer piSet      0
    send GridPrepare_AddColumn "Value"     AFT_ASCII40
    send GridPrepare_AddColumn "Frequency" AFT_ASCII7
    send GridPrepare_Apply self
    set select_mode to no_select
    on_key kenter send next
    on_key kenter send next
    on_key key_ctrl+key_r send sort_data
  end_procedure
  function iSpecialSortValueOnColumn.i integer itm# returns integer
    function_return 1
  end_function
  function sSortValue.ii integer column# integer itm# returns string
    integer type# int#
    string rval#
//    showln "sSortValue.ii " (string(column#)) " " (string(itm#))
    get value item itm# to rval#
    if column# eq 0 begin
      get piDataType to type#
      if type# eq DF_BCD move (NumToStrR(rval#,8,23)) to rval#
      if type# eq DF_DATE begin
        move (date(rval#)) to int#
        move (IntToStrR(int#,10)) to rval#
      end
      function_return rval#
    end
    if column# eq 1 function_return (IntToStrR(rval#,10))
  end_function
  procedure sort_data.i integer column#
    send Grid_SortByColumn self column#
  end_procedure
  procedure sort_data
    integer cc#
    get Grid_CurrentColumn self to cc#
    send sort_data.i cc#
  end_procedure
  procedure header_mouse_click integer itm#
    send sort_data.i itm#
    forward send header_mouse_click itm#
  end_procedure
  procedure fill_list.i integer set#
    integer row# max#
    send delete_data
    set piSet to set#
    set piDataType to (piDataType(set#))
    get row_count of set# to max#
    for row# from 0 to (max#-1)
      send add_item msg_none (psValue.i(set#,row#))
      send add_item msg_none (piCount.i(set#,row#))
    loop
    send Grid_SetEntryState self dfFalse
    send sort_data.i 0 // Sort by value
    send beginning_of_data
  end_procedure
  procedure save_file
    integer ch#
    string fn#
    move (SEQ_SelectOutFile("Save to text file","All (*.*)|*.*")) to fn#
    if fn# ne "" begin
      move (SEQ_DirectOutput(fn#)) to ch#
      if ch# begin
        send seq_write to (piSet(self)) ch#
        send SEQ_CloseOutput ch#
      end
    end
  end_procedure
end_class // cDisplayDataSamplerSet

Use APS.pkg      // Auto Positioning and Sizing classes for VDF
Use Buttons.utl  // Button texts
object oDisplayDataSamplerSet is a aps.ModalPanel
  set locate_mode to CENTER_ON_SCREEN
  on_key kcancel send close_panel
  object oLst is a cDisplayDataSamplerSet
    set size to 200 0
  end_object
  object oBtn1 is a aps.Multi_Button
    on_item t.btn.save  send save_file to (oLst(self))
  end_object
  object oBtn2 is a aps.Multi_Button
    on_item t.btn.close send close_panel
  end_object
  send aps_locate_multi_buttons
  set Border_Style to BORDER_THICK   // Make panel resizeable
  procedure aps_onResize integer delta_rw# integer delta_cl#
    send aps_resize (oLst(self)) delta_rw# 0
    send aps_register_multi_button (oBtn1(self))
    send aps_register_multi_button (oBtn2(self))
    send aps_locate_multi_buttons
    send aps_auto_size_container
  end_procedure
  procedure popup.is integer set# string name#
    set label to ("Discrete values for field: "+name#)
    send fill_list.i to (oLst(self)) set#
    send popup
  end_procedure
end_object // oDisplayDataSamplerSet


class cDataSamplerResultList is a aps.Grid
  procedure construct_object integer img#
    forward send construct_object img#
    property integer piDataSampler 0
    send GridPrepare_AddColumn "Name"     AFT_ASCII20
    send GridPrepare_AddColumn "Type"     AFT_ASCII6
    send GridPrepare_AddColumn "Count"    AFT_ASCII10
    send GridPrepare_AddColumn "0 count"  AFT_ASCII10
    send GridPrepare_AddColumn "Minimum"  AFT_ASCII14
    send GridPrepare_AddColumn "Maximum"  AFT_ASCII14
    send GridPrepare_AddColumn "Discrete" AFT_ASCII3
    send GridPrepare_Apply self
    on_key kEnter send display_discrete_values
    set select_mode to MULTI_SELECT
    on_key kenter send next
  end_procedure
  procedure select_toggling integer itm# integer i#
    integer ci# hasrun#
    get piHasRun to hasrun#
    if hasrun# send display_discrete_values
    else begin
      get current_item to ci#
      move ((ci#/7)*7+6) to ci# // Redirect to last column
      forward send select_toggling ci# i#
    end
  end_procedure
  procedure display_discrete_values
    integer base#
    if (item_count(self)) begin
      get Grid_BaseItem self to base#
      if (select_state(self,base#+6)) begin
        send popup.is to (oDisplayDataSamplerSet(self)) (piSet.i(piDataSampler(self),aux_value(self,base#))) (value(self,base#))
      end
    end
  end_procedure
  procedure Update_DataSampler
    integer DataSampler# max# row# itm# st# columns# sampler_row# base#
    get piDataSampler to DataSampler#
    get Grid_RowCount self to max#
    get Grid_Columns self to columns#
    for row# from 0 to (max#-1)
      move (row#*columns#) to base#
      get aux_value base# to sampler_row#
      move (base#+columns#-1) to itm#
      get select_state item itm# to st#
      set piDiscrete.i of DataSampler# sampler_row# to st#
    loop
  end_procedure
  procedure fill_list
    integer DataSampler# max# row# itm#
    get piDataSampler to DataSampler#
    send delete_data
    set dynamic_update_state to false
    if DataSampler# begin
      get row_count of DataSampler# to max#
      for row# from 0 to (max#-1)
        get item_count to itm#
        send add_item msg_none (psName.i(DataSampler#,row#))
        set aux_value item itm# to row#
        send add_item msg_none (StringFieldType(piType.i(DataSampler#,row#)))
        send add_item msg_none (piCount.i(DataSampler#,row#))
        send add_item msg_none (piNullCount.i(DataSampler#,row#))
        send add_item msg_none (sMin.i(DataSampler#,row#))
        send add_item msg_none (sMax.i(DataSampler#,row#))
        get item_count to itm#
        send add_item msg_none ""
        set checkbox_item_state item itm# to true
        set select_state item itm# to (piDiscrete.i(DataSampler#,row#))
      loop
    end
    send Grid_SetEntryState self dfFalse
    set dynamic_update_state to true
  end_procedure
end_class // cDataSamplerResultList

object oDataSampler_Vw is a aps.View label "Field statistics"
  property integer piCurrentTable 0
  property integer piHasRun       0
  on_key KCANCEL send close_panel

  object oSetOfFields is a cSetOfFields
  end_object
  object oDataSampler is a cdbDataSampler
    procedure rebuild_from_set
      integer set# max# row#
      move (oSetOfFields(self)) to set#
      send reset
      get row_count of set# to max#
      for row# from 0 to (max#-1)
        send add_field.ii (piFile.i(set#,row#)) (piField.i(set#,row#))
      loop
    end_procedure
  end_object
  object oLst is a cDataSamplerResultList
    set piDataSampler to (oDataSampler(self))
    set size to 200 0
    procedure display_discrete_values
      if (piHasRun(self)) forward send display_discrete_values
    end_procedure
  end_object
  procedure select_table
    integer file#
    get piCurrentTable to file#
    get iFdxSelectOneFile 0 file# to file#
    if file# begin
      set piCurrentTable to file#
      send delete_data to (oSetOfFields(self))
      send rebuild_from_set to (oDataSampler(self))
      send fill_list to (oLst(self))
      set piHasRun to false
      send select_fields
    end
  end_procedure
  procedure select_related_fields
  end_procedure
  procedure select_fields
    integer set#
    if (piCurrentTable(self)) begin
      move (oSetOfFields(self)) to set#
      if (iFdxSelectFields(0,piCurrentTable(self),set#)) begin
        send OpenStat_RegisterFiles
        if (DBMS_OpenFile(piCurrentTable(self),DF_SHARE,0)) begin
          send rebuild_from_set to (oDataSampler(self))
          send fill_list to (oLst(self))
        end
        set piHasRun to false
        send OpenStat_RestoreFiles
      end
    end
    else send obs "Before you can select which fields to sample" "you have to select a table!"
  end_procedure
  procedure DoRun
    send OpenStat_RegisterFiles
    if (piCurrentTable(self)) begin
      if (DBMS_OpenFile(piCurrentTable(self),DF_SHARE,0)) begin // recnumÄÄÄÄÄ ÄDo display wait'er
        send Update_DataSampler to (oLst(self))
        send run.iii to (oDataSampler(self)) (piCurrentTable(self)) 0 1
        send fill_list to (oLst(self))
        send OpenStat_RestoreFiles
        set piHasRun to true
      end
    end
  end_procedure
  object oBtn1 is a aps.Multi_Button
    on_item "Select table" send select_table
  end_object
  object oBtn2 is a aps.Multi_Button
    on_item "Select fields" send select_fields
  end_object
//object oBtn3 is a aps.Multi_Button
//  on_item "Related fields" send select_related_fields
//end_object
  object oBtn4 is a aps.Multi_Button
    on_item "Run" send DoRun
  end_object
  object oBtn5 is a aps.Multi_Button
    on_item "Display discrete" send display_discrete_values to (oLst(self))
  end_object
  object oBtn6 is a aps.Multi_Button
    on_item t.btn.close send close_panel
  end_object
  send aps_locate_multi_buttons
  set Border_Style to BORDER_THICK   // Make panel resizeable
  procedure aps_onResize integer delta_rw# integer delta_cl#
    send aps_resize (oLst(self)) delta_rw# 0 // delta_cl#
    send aps_register_multi_button (oBtn1(self))
    send aps_register_multi_button (oBtn2(self))
  //send aps_register_multi_button (oBtn3(self))
    send aps_register_multi_button (oBtn4(self))
    send aps_register_multi_button (oBtn5(self))
    send aps_register_multi_button (oBtn6(self))
    send aps_locate_multi_buttons
    send aps_auto_size_container
  end_procedure
end_object
procedure Activate_DataSampler_Vw
  if (DFMatrix_RealData_Check()) send popup to (oDataSampler_Vw(self))
end_procedure
