use odbc.utl
//use VdfQuery.utl

activate_view Activate_ODBCViewer for oODBCTableViewerView
object oODBCTableViewerView is a aps.View label "ODBC table viewer"
  on_key kcancel send close_panel

  object oDataSourceSelector is a aps.ComboFormAux label "Select ODBC data source"
    set label_justification_mode to JMODE_TOP
    set form_margin item 0 to 40
    set entry_state item 0 to DFFALSE
    procedure fill_list
      integer lhObj liMax liItem
      move (oODBC_DataSources(self)) to lhObj
      send Combo_Delete_Data
      get item_count of lhObj to liMax
      decrement liMax
      for liItem from 1 to liMax
        send combo_add_item (value(lhObj,liItem)) liItem
      loop
    end_procedure
    procedure OnChange
      send DoUpdateTables
    end_procedure
  end_object // oDataSourceSelector
  send aps_goto_max_row

  object oTables is a aps.Grid
    set size to 200 0
    send GridPrepare_AddColumn "Table name" AFT_ASCII40
//    send GridPrepare_AddColumn "Schema name" AFT_ASCII40
    send GridPrepare_Apply self
    procedure fill_list
      integer lhObj liMax liItem
      set dynamic_update_state to DFFALSE
      move (oODBC_Tables(self)) to lhObj
      send Delete_Data
      get row_count of lhObj to liMax
      decrement liMax
      for liItem from 1 to liMax
        send add_item MSG_NONE (psTableName.i(lhObj,liItem))
//        send add_item MSG_NONE (psSchemaName.i(lhObj,liItem))
      loop
      set dynamic_update_state to DFTRUE
      send Grid_SetEntryState self DFFALSE
    end_procedure
  end_object

  procedure DoUpdateTables
    string lsDSNName
    get value of (oDataSourceSelector(self)) item 0 to lsDSNName
    if (lsDSNName<>"") begin
      send FillArray to (oODBC_Tables(self)) lsDSNName
      send fill_list to (oTables(self))
    end
    else send delete_data to (oTables(self))
  end_procedure

  procedure DoOpen
    integer liRval
    string lsDataSource lsTableName
    get value of (oDataSourceSelector(self)) item 0 to lsDataSource
    get value of (oTables(self)) item CURRENT to lsTableName
    get ODBC_OpenAs 37 DF_SHARE lsDataSource lsTableName to liRval
    send FDX_ModalDisplayFileAttributes 0 37
    close 37
  end_procedure
  procedure DoQuery
//  integer liRval
//  string lsDataSource lsTableName
//  get value of (oDataSourceSelector(self)) item 0 to lsDataSource
//  get value of (oTables(self)) item CURRENT to lsTableName
//  get ODBC_OpenAs 37 DF_SHARE lsDataSource lsTableName to liRval
//  send CreateNewQuery 37
  end_procedure
  on_key KEY_CTRL+KEY_O send DoOpen
  on_key KEY_CTRL+KEY_Q send DoQuery

  object oBtn1 is a aps.Multi_Button
    on_item "Login" send ODBC_Login
  end_object
  object oBtn2 is a aps.Multi_Button
    on_item "Read sources" send DoReadODBCSources
  end_object
  object oBtn3 is a aps.Multi_Button
    on_item "Display def" send DoOpen
  end_object
//object oBtn4 is a aps.Multi_Button
//  on_item "Query" send DoQuery
//end_object
  object oBtn5 is a aps.Multi_Button
    on_item "Create DF table" send DoOpen
  end_object
  object oBtn6 is a aps.Multi_Button
    on_item t.btn.close send close_panel
  end_object
  send aps_locate_multi_buttons SL_VERTICAL

  set Border_Style to BORDER_THICK   // Make panel resizeable
  procedure aps_onResize integer delta_rw# integer delta_cl#
    send aps_resize (oTables(self)) delta_rw# 0 // delta_cl#
    send aps_register_multi_button (oBtn1(self))
    send aps_register_multi_button (oBtn2(self))
    send aps_register_multi_button (oBtn3(self))
//    send aps_register_multi_button (oBtn4(self))
    send aps_register_multi_button (oBtn5(self))
    send aps_register_multi_button (oBtn6(self))
    send aps_locate_multi_buttons SL_VERTICAL
    send aps_auto_size_container
  end_procedure
  procedure DoReadODBCSources
    integer liGarbage
//    get ODBC_StartAdministrator to liGarbage
    send FillArray to (oODBC_DataSources(self))
    send fill_list to (oDataSourceSelector(self))
  end_procedure
  procedure popup
    forward send popup
    send DoReadODBCSources
  end_procedure
end_object // oODBCTableSelector
