//    * Show only commented fields
//    * Field_Not_Found are now colored red
//    * Ctrl+N Now creates a new view.
//
//    To do:
//
//      VPE interface til rapport
//      Impl. af ubenyttede felter (i DB*.DAT)
//      Hj‘lpeklasse med benyttelse af IE
//      Mulighed for at fjerne entries fra filelist.cfg
//

Use APS.pkg      // Auto Positioning and Sizing classes for VDF
Use ObjGroup.utl // Defining groups of objects
Use DBD.pkg      // cDBD_System, cDBD_TableAccess and cDBD_Updater classes
Use Files.utl    // Utilities for handling file related stuff
Use Spec0005.utl // Datadictionary object procedures ("DDUTIL_" prefix)
Use Wait.utl     // Something to put on screen while batching.
Use TrckBr.pkg   // TrackBar class

Use DeoCnfrm.pkg // DEO confirm save/delete functions
Use dbd.rv // DBD - Report object

Use Language     // Set default languange if not set by compiler command line

Use FdxSet.nui   // cFdxSetOfTables, cFdxSetOfFields, cFdxSetOfIndices
Use FdxSet.pkg   // cFdxSetOfFieldsList class
Use API_Attr.pkg // UI objects for use with API_Attr.utl
Use GridUtil.utl // Grid and List utilities (not for dbGrid's or Table's)
Use RGB.utl      // Some color functions

object oDbdFilelistReassigner is a cArray
  item_property_list
    item_property integer piCurrentEntry.i // (In dbd tables)
    item_property string  psLogicName.i
    item_property integer piNewEntry.i     // in global FDX
    item_property integer piEntryAlreadyExists.i
  end_item_property_list
  procedure ReadAllFileNumbers integer lhTableAccess
    integer lbFound liTableFile liFile liRow liNewFile liMax
    string lsLogicName
    send delete_data
    get piFile.i of lhTableAccess DBDTABLE_TABLE to liTableFile
    clear liTableFile
    repeat
      vfind liTableFile 0 GT
      move (found) to lbFound
      if lbFound begin
        get_field_value liTableFile 1 to liFile
        get_field_value liTableFile 3 to lsLogicName

        get iFindLogicalName.si of ghFDX lsLogicName 0 to liNewFile
        if (liNewFile<>0 and liNewFile<>liFile) begin
          get row_count to liRow
          set piCurrentEntry.i liRow to liFile
          set psLogicName.i    liRow to lsLogicName
          set piNewEntry.i     liRow to liNewFile
        end
      end
    until (not(lbFound))
    send sort_rows 0
    get row_count to liMax
    decrement liMax
    for liRow from 0 to liMax
      get piNewEntry.i liRow to liNewFile
      clear liTableFile
      set_field_value liTableFile 1 to liNewFile
      vfind liTableFile 1 EQ
      set piEntryAlreadyExists.i liRow to (found)
    loop
  end_procedure
  object oTmpArray is a cArray
    procedure add_recnum integer liRecnum
      integer liItem
      get item_count to liItem
      set value liItem to liRecnum
    end_procedure
    procedure update_field_table integer liFile integer liNewEntry
      integer liItem liMax
      get item_count to liMax
      decrement liMax
      for liItem from 0 to liMax
        clear liFile
        set_field_value liFile 0 to (value(self,liItem))
        vfind liFile 0 EQ
        set_field_value liFile 1 to liNewEntry
        saverecord liFile
      loop
    end_procedure
    procedure update_index_table integer liFile integer liNewEntry
      // Ir really is code identical to the procedure just above us
      // So why not:
      send update_field_table liFile liNewEntry
    end_procedure
  end_object
  procedure Run.i integer lhTableAccess
    integer liRow liMax liCurrentEntry liNewEntry lbContinue lhTmpArray
    integer liTableFile liFieldFile liIndexFile lbFound liTestValue liRecnum
    send ReadAllFileNumbers lhTableAccess
    if (row_count(self)) begin
      get DBD_ReassignConfirm to lbContinue
      if lbContinue begin
        move oTmpArray to lhTmpArray
        get piFile.i of lhTableAccess DBDTABLE_TABLE to liTableFile
        get piFile.i of lhTableAccess DBDTABLE_FIELD to liFieldFile
        get piFile.i of lhTableAccess DBDTABLE_INDEX to liIndexFile
        get row_count to liMax
        decrement liMax

        send cursor_wait to (cursor_control(self))
        lock // -----------------------------------------------------
        for liRow from 0 to liMax
          get piCurrentEntry.i liRow to liCurrentEntry
          get piNewEntry.i     liRow to liNewEntry
          ifnot (piEntryAlreadyExists.i(self,liRow)) begin

            clear liTableFile
            set_field_value liTableFile 1 to liCurrentEntry
            vfind liTableFile 1 EQ
            set_field_value liTableFile 1 to liNewEntry
            saverecord liTableFile

            send delete_data of lhTmpArray // Find all fields
            clear liFieldFile
            set_field_value liFieldFile 1 to liCurrentEntry
            repeat
              vfind liFieldFile 1 GT
              move (found) to lbFound
              if lbFound begin
                get_field_value liFieldFile 1 to liTestValue
                move (liTestValue=liCurrentEntry) to lbFound
                if lbFound begin
                  get_field_value liFieldFile 0 to liRecnum
                  send add_recnum of lhTmpArray liRecnum
                end
              end
            until (not(lbFound))
            send update_field_table of lhTmpArray liFieldFile liNewEntry

            send delete_data of lhTmpArray // Find all indices
            clear liIndexFile
            set_field_value liIndexFile 1 to liCurrentEntry
            repeat
              vfind liIndexFile 1 GT
              move (found) to lbFound
              if lbFound begin
                get_field_value liIndexFile 1 to liTestValue
                move (liTestValue=liCurrentEntry) to lbFound
                if lbFound begin
                  get_field_value liIndexFile 0 to liRecnum
                  send add_recnum of lhTmpArray liRecnum
                end
              end
            until (not(lbFound))
            send update_index_table of lhTmpArray liIndexFile liNewEntry
          end
        loop
        unlock // ---------------------------------------------------
        send cursor_ready to (cursor_control(self))
        send obs "Done"
      end
    end
    else send obs "Table numbers are already in accordance with filelist.cfg" "(If you have fastload enabled you may have to 'refresh')"
  end_procedure
end_object // oDbdFilelistReassigner

object oDbdFilelistReassignerConfirm is a aps.ModalPanel label "Reassign table numbers according to filelist.cfg"
  set locate_mode to CENTER_ON_SCREEN
  set Border_Style to BORDER_THICK   // Make panel resizeable
  on_key ksave_record send close_panel_ok
  on_key kcancel send close_panel
  property integer pbResult

  object oGrid is a aps.Grid
    set peAnchors to (anTop+anLeft+anRight+anBottom)
    send GridPrepare_AddColumn "Logical name"                   AFT_ASCII12
    send GridPrepare_AddColumn "Current entry"                  AFT_NUMERIC4.0
    send GridPrepare_AddColumn "New entry"                      AFT_NUMERIC4.0
    send GridPrepare_AddCheckBoxColumn "New entry already occupied"
    send GridPrepare_Apply self
    set select_mode to NO_SELECT
    on_key KNEXT_ITEM send switch
    on_key KPREVIOUS_ITEM send switch_back
    set size to 200 0
    procedure fill_list
      integer lhArr liRow liMax
      send delete_data
      move oDbdFilelistReassigner to lhArr
      set dynamic_update_state to FALSE
      get row_count of lhArr to liMax
      decrement liMax
      for liRow from 0 to liMax
        send add_item MSG_NONE (psLogicName.i(lhArr,liRow))
        send add_item MSG_NONE (piCurrentEntry.i(lhArr,liRow))
        send add_item MSG_NONE (piNewEntry.i(lhArr,liRow))
        send Grid_AddCheckBoxItem self (piEntryAlreadyExists.i(lhArr,liRow))
      loop
      set dynamic_update_state to TRUE
      send Grid_SetEntryState self FALSE
    end_procedure
  end_object

  object oBtn1 is a aps.Multi_Button
    on_item "OK" send close_panel_ok
    set peAnchors to (anBottom+anRight)
  end_object
  object oBtn2 is a aps.Multi_Button
    on_item "Close" send close_panel
    set peAnchors to (anBottom+anRight)
  end_object
  send aps_locate_multi_buttons

  procedure close_panel_ok
    set pbResult to DFTRUE
    send close_panel
  end_procedure
  function iPopup returns integer
    set pbResult to DFFALSE
    send fill_list of oGrid
    send popup
    function_return (pbResult(self))
  end_procedure
end_object // oDbdFilelistReassignerConfirm
send aps_SetMinimumDialogSize (oDbdFilelistReassignerConfirm(self)) // Set minimum size

function DBD_ReassignConfirm global returns integer
  integer lbRval
  get iPopup of oDbdFilelistReassignerConfirm to lbRval
  function_return lbRval
end_function


/Dbd.Help.Main
<h1>Document your database</h1>
<p>You may document your database table by table and field by field using this
function. The text you enter, may be used to describe your database to other
developers or the contents may be published for use with VDFQuery (later).</p>

<p>The data you enter is stored in a set of tables that may be queried using the
built in report (the Report button) or whatever reporting tool you have handy.</p>
/Dbd.Help.CreateTables
<h1>Document your database</h1>
<h2>Description tables not found</h2>
<p>In order for this function to work a set of tables must be created to store
the table and field descriptions.</p>

<p>This is a automated process that will look for 4 available entries in your
<i>filelist.cfg</i> (above entry 600) and fill them in with a set of empty
tables automatically created for this purpose.</p>

<p><b>NOTE</b> that the first thing you want to do after having created the
tables is to click the "Read DB definitions" button in the main view</p>
/*


object oDbdSetOfFieldsResultModal is a aps.ModalPanel
  set locate_mode to CENTER_ON_SCREEN
  set Border_Style to BORDER_THICK   // Make panel resizeable
  on_key kcancel send close_panel
  on_key ksave_record send none
  on_key KEY_ALT+KEY_U send DoUnion
  on_key KEY_ALT+KEY_I send DoIntersection
  on_key KEY_ALT+KEY_C send DoComplement
  property integer phResultSet 0
  property integer phTargetSet 0
  register_object oTxt
  object oLst is a cFdxSetOfFieldsList
    set size to 100 0
    set peResizeColumn to rcAll
    set peAnchors to (anTop+anLeft+anRight+anBottom)
    procedure update_display_counter integer liFiles integer liFields
      string lsValue
      if liFields move (string(liFields)+" fields from "+string(liFiles)+" tables") to lsValue
      else move "" to lsValue
      set value of (oTxt(self)) item 0 to lsValue
    end_procedure
  end_object
  object oTxt is a aps.TextBox snap SL_DOWN
    set peAnchors to (anRight+anBottom+anLeft)
    set auto_size_state to false
    set size to 10 300
    set value to "(empty)"
  end_object
  set auto_size_state of (oTxt(self)) to true
  object oBtn1 is a aps.Multi_Button
    set peAnchors to (anRight+anBottom)
    on_item "&Union"        send DoUnion
  end_object
  object oBtn2 is a aps.Multi_Button
    set peAnchors to (anRight+anBottom)
    on_item "&Intersection" send DoIntersection
  end_object
  object oBtn3 is a aps.Multi_Button
    set peAnchors to (anRight+anBottom)
    on_item "&Complement"   send DoComplement
  end_object
  object oBtn4 is a aps.Multi_Button
    set peAnchors to (anRight+anBottom)
    on_item t.btn.cancel send close_panel
  end_object
  send aps_locate_multi_buttons
  procedure DoIntersection
    send DoIntersection.i to (phTargetSet(self)) (phResultSet(self))
    send close_panel
  end_procedure
  procedure DoUnion
    send DoUnion.i to (phTargetSet(self)) (phResultSet(self))
    send close_panel
  end_procedure
  procedure DoComplement
    send DoComplement.i to (phTargetSet(self)) (phResultSet(self))
    send close_panel
  end_procedure
  procedure update_display integer lhResultSet
    set label to (psTitle(lhResultSet))
    set phResultSet to lhResultSet
    send fill_list.i to (oLst(self)) lhResultSet
  end_procedure
  procedure popup.ii integer lhResultSet integer lhTargetset
    set phTargetSet to lhTargetset
    send update_display lhResultSet
    send popup
  end_procedure
end_object // oDbdSetOfFieldsResultModal
send aps_SetMinimumDialogSize (oDbdSetOfFieldsResultModal(self))

object oDbdFieldSearcher is a aps.View label "Field search"
  set Border_Style to BORDER_THICK   // Make panel resizeable
  set Window_Style to WS_MAXIMIZEBOX 1
  on_key kcancel send close_panel
  property integer phDbdView

  procedure GoBackToDbd
    send GotoEditObject to (phDbdView(self))
  end_procedure
  on_key KEY_ALT+KEY_S send GoBackToDbd

  // If the DBD view that started this view is closed we should close this view as well
  procedure DestroyingDbdView integer lhView
    if (lhView=phDbdView(self)) send close_panel
  end_procedure
  object oSetOfFields is a cFdxSetOfFields
    set piFDX_Server to ghFDX
  end_object
  object oSetOfFieldsResult is a cFdxSetOfFields
    set piFDX_Server to ghFDX
    set psTitle to "Field search result"
  end_object
  object oLst is a cFdxSetOfFieldsList
    set piAllowDelete to dfTrue
    set size to 100 0
    set piFDX_Server to ghFDX
    set piSOF_Server to (oSetOfFields(self))
    set peResizeColumn to rcAll
    set peAnchors to (anTop+anLeft+anRight+anBottom)
    procedure update_display_counter integer liFiles integer liFields
      string lsValue
      if liFields move (string(liFields)+" fields from "+string(liFiles)+" tables") to lsValue
      else move "(empty)" to lsValue
      set value of (oTxt(self)) item 0 to lsValue
    end_procedure

    procedure row_change integer liRowFrom integer liRowTo
      send DisplayDbd liRowTo
    end_procedure
    procedure item_change integer liItm1 integer liItm2 returns integer
      integer liRval liColumns
      get Grid_Columns self to liColumns
      forward get msg_item_change liItm1 liItm2 to liRval
      if (liItm1/liColumns) ne (liItm2/liColumns) send row_change (liItm1/liColumns) (liItm2/liColumns)
      procedure_return liRval
    end_procedure

  end_object
  procedure DoWriteToFile
    send DoWriteToFile of oLst
  end_procedure
  on_key KEY_CTRL+KEY_W send DoWriteToFile
  object oTxt is a aps.TextBox snap SL_DOWN
    set peAnchors to (anRight+anBottom+anLeft)
    set auto_size_state to false
    set size to 10 300
    set value to "(empty)"
  end_object
  object oTrackMainView is a aps.CheckBox label "Track fields in main panel" snap SL_RIGHT_SPACE
    set peAnchors to (anRight+anBottom)
    set checked_state to true
  end_object
  procedure DisplayDbd integer liRow
    integer liFile lbSelect
    string lsFieldName
    get checked_state of oTrackMainView to lbSelect
    if lbSelect begin
      get row_file.i of oLst liRow to liFile
      get row_field_name.i of oLst liRow to lsFieldName
      send GotoField of (phDbdView(self)) liFile lsFieldName
    end
  end_procedure

  send aps_goto_max_row

  object oHint1 is a aps.TextBox label " Click column headers to sort the grid. "
    set color to (RGB_Brighten(clYellow,75))
    set peAnchors to (anBottom+anLeft)
    set justification_mode to (JMODE_CENTER+JMODE_VCENTER)
  end_object
  object oHint2 is a aps.TextBox label " Press Ctrl+W to write grid contents to ASCII file " snap SL_RIGHT
    set color to (RGB_Brighten(clYellow,75))
    set peAnchors to (anRight+anBottom+anLeft)
    set justification_mode to (JMODE_CENTER+JMODE_VCENTER)
  end_object
  object oHint3 is a aps.TextBox label " When selecting by name, wildcards are allowed " snap SL_RIGHT
    set color to (RGB_Brighten(clYellow,75))
    set peAnchors to (anRight+anBottom)
    set justification_mode to (JMODE_CENTER+JMODE_VCENTER)
  end_object
  send aps_goto_max_row
  object oAddFieldsGroup is a aps.Group label "Add fields (selected by attribute value):"
    set peAnchors to (anRight+anBottom+anLeft)
    set p_auto_column to 0
    object oAttribute is a Api_Attr.ComboFormAux label "Attribute:"
      set form_margin item 0 to 20
      set p_extra_internal_width to -50
      procedure OnChange
        send DoUpdate (Combo_Current_Aux_Value(self))
      end_procedure
      procedure fill_list_attrtype integer liAttrTyoe
        forward send fill_list_attrtype liAttrTyoe // which is ATTRTYPE_FIELD
        set value item 0 to "Name"
      end_procedure
    end_object
    object oComperator is a Api_Attr.ComboFormAux label "Comp:" snap SL_RIGHT_SPACE
      set form_margin item 0 to 2
    end_object
    object oDiscreteValue is a Api_Attr.ComboFormAux label "Discrete value:" snap SL_RIGHT_SPACE
      set p_extra_internal_width to -23
      set form_margin item 0 to 10
    end_object
    object oUserValue is a aps.Form label "User value:" snap SL_RIGHT_SPACE
      set form_margin item 0 to 20
      set p_extra_internal_width to -40
      set peAnchors to (anRight+anLeft)
      on_key kenter send DoAddFields
    end_object
    procedure DoUpdate integer liAttr
      send prepare_comparison_modes to (oComperator(self)) liAttr
      send prepare_attr_values to (oDiscreteValue(self)) liAttr
      if (API_AttrDiscreteValues(liAttr)) begin
        set enabled_state of (oDiscreteValue(self)) to true
        set enabled_state of (oUserValue(self)) to false
        set value of (oUserValue(self)) item 0 to ""
      end
      else begin
        set enabled_state of (oDiscreteValue(self)) to false
        set enabled_state of (oUserValue(self)) to true
      end
    end_procedure
    function iAttribute returns integer
      function_return (Combo_Current_Aux_Value(oAttribute(self)))
    end_function
    function iComperator returns integer
      function_return (Combo_Current_Aux_Value(oComperator(self)))
    end_function
    function sValue returns string
      if (API_AttrDiscreteValues(iAttribute(self))) function_return (Combo_Current_Aux_Value(oDiscreteValue(self)))
      function_return (value(oUserValue(self),0))
    end_function
    procedure DoAddFields
      integer lhSet lbNotEmpty
      get row_count of oSetOfFields to lbNotEmpty
      if lbNotEmpty move (oSetOfFieldsResult(self)) to lhSet
      else move (oSetOfFields(self)) to lhSet

      set piTestAttribute of lhSet to (iAttribute(self))
      set piTestCompMode  of lhSet to (iComperator(self))
      set psTestValue     of lhSet to (sValue(self))

      // This line saves us for a lot of errors if an alphanumeric value is entered into an integer comparation:
      if (piTestAttribute(lhSet)<>DF_FIELD_NAME) set psTestValue of lhSet to (ExtractInteger(psTestValue(lhSet),1))

      send Traverse_All of lhSet
      send DoRemoveFile.i of lhSet 49 // Remove MENU
      send DoRemoveFile.i of lhSet 50 // Remove FLEXERRS

      if lbNotEmpty begin // The set was empty so we just dump it right away
        send popup.ii of oDbdSetOfFieldsResultModal lhSet (oSetOfFields(self))
        send fill_list.i of oLst (oSetOfFields(self))
      end
      else begin
        send fill_list.i of oLst lhSet
      end
    end_procedure
    object oAddBtn is a aps.Button snap SL_RIGHT_SPACE
      set size to 14 30
      set peAnchors to (anRight)
      on_item "Add" send DoAddFields
    end_object
    send Combo_Delete_Data to (oAttribute(self))
    send Combo_Delete_Data to (oComperator(self))
    send Combo_Delete_Data to (oDiscreteValue(self))
    send fill_list_attrtype to (oAttribute(self)) ATTRTYPE_FIELD
    send DoUpdate (Combo_Current_Aux_Value(oAttribute(self)))
  end_object // oAddFieldsGroup
  procedure DoSelectByRelation
    integer liFile liField liRow lhLst lhSet
    move (oLst(self)) to lhSet
    if (item_count(lhSet)) begin
      get Grid_CurrentRow lhSet to liRow
      get row_file.i of lhSet liRow to liFile
      get row_field.i of lhSet liRow to liField
      move (oSetOfFieldsResult(self)) to lhSet

      send Traverse_ConnectedFields of lhSet liFile liField

      send DoRemoveFile.i of lhSet 49 // Remove MENU
      send DoRemoveFile.i of lhSet 50 // Remove FLEXERRS
      send popup.ii of oDbdSetOfFieldsResultModal lhSet (oSetOfFields(self))
      send fill_list.i of oLst (oSetOfFields(self))
    end
    else send obs "You must point to a field" "before executing this function"
  end_procedure
  object oBtn1 is a aps.Multi_Button
    set size to 14 50
    set peAnchors to (anRight+anBottom)
    on_item t.btn.reset  send DoReset
  end_object
  object oBtn2 is a aps.Multi_Button
    set size to 14 83
    set peAnchors to (anRight+anBottom)
    on_item "Select by relations"  send DoSelectByRelation
  end_object
  object oBtn3 is a aps.Multi_Button
    set size to 14 50
    set peAnchors to (anRight+anBottom)
    on_item t.btn.close  send close_panel
  end_object
  send aps_locate_multi_buttons
  procedure DoReset
    send reset to (oSetOfFields(self))
    send update_display
  end_procedure
  procedure DoPrint
  end_procedure
  procedure update_display
    send fill_list.i to (oLst(self)) (oSetOfFields(self))
  end_procedure
  procedure OnChangeFdx
    send reset to (oSetOfFields(self))
    send update_display
  end_procedure
end_object // oDbdFieldSearcher
send aps_SetMinimumDialogSize (oDbdFieldSearcher(self))

procedure Activate_DbdFieldSearcher integer lhDbdView
  set phDbdView of oDbdFieldSearcher to lhDbdView
  send popup of oDbdFieldSearcher
end_procedure



DEFINE_OBJECT_GROUP OG_Dbd_View
  object oDBD_System is a cDBD_System
    object oDBD_TableAccess is a cDBD_TableAccess
      set pbOpenTablesOnDefine to false
      set psRootNamePrefix to (og_param(0))
      function bConvertFilelistTo4095 returns integer
        function_return (MB_Verify4("Your filelist.cfg is an old one","with less than 256 entries.","","Should it be converted to a 4095 entry filelist?",1))
      end_function
    end_object
    object oDBD_Updater is a cDBD_Updater
      object oUpdateSentinel is a cBatchCompanion
      end_object
      procedure OnUpdateBegin
        send batch_on of oUpdateSentinel "Reading (new) tables and fields"
      end_procedure
      procedure OnHandleTable string lsMsg
        send batch_update of oUpdateSentinel lsMsg
      end_procedure
      procedure OnHandleField string lsMsg
        send batch_update2 of oUpdateSentinel lsMsg
      end_procedure
      procedure OnHandleIndex string lsMsg
        send batch_update2 of oUpdateSentinel lsMsg
      end_procedure
      procedure OnUpdateEnd
        send batch_off of oUpdateSentinel
      end_procedure
    end_object
    move self to OG_Current_Object# // global integer
  end_object // oDBD_System

  // WindowIndex is a globally defined integer that I use

  get DoOpenTables of (oDBD_TableAccess(OG_Current_Object#)) to WindowIndex
  ifnot WindowIndex begin
    //send Popup_DbdControlPanel OG_Current_Object#
    send Popup_DbdCreateTablesPanel OG_Current_Object#
    get DoOpenTables of (oDBD_TableAccess(OG_Current_Object#)) to WindowIndex
  end

  ifnot WindowIndex begin // Tables were not opened: therefore we abort the whole thing
    send Request_Destroy_Object of OG_Current_Object#
    move 0 to OG_Current_Object#
  end
  else begin
    object oDBD_View is a aps.dbView
      set Border_Style to BORDER_THICK   // Make panel resizeable
      set Window_Style to WS_MAXIMIZEBOX 1
      on_key kcancel send close_panel
      on_key key_ctrl+key_n send Request_CloneView

      procedure Request_CloneView
        integer liLocation lhVw lhParent
        get location to liLocation

        get parent of self to lhParent

        CREATE_OBJECT_GROUP OG_Dbd_View PARENT lhParent "db"
        if (OG_Current_Object#<>0) begin
          move OG_Current_Object# to lhVw
          set location of lhVw to (hi(liLocation)+13) (low(liLocation)+13)
          send popup to lhVw
        end
        else send obs "Tables could not be opened"
      end_procedure

      function ViewPanelObjectId returns integer
        function_return self
      end_function

      property integer phDbdSystem OG_Current_Object#
      property integer piTable_FileNumber 0
      property integer piField_FileNumber 0
      property integer piIndex_FileNumber 0

      function iTable_FileNumber returns integer
        integer lhTableAccess liTableFile
        move (phTableAccessObject(integer(phDbdSystem(self)))) to lhTableAccess
        get piFile.i of lhTableAccess DBDTABLE_TABLE to liTableFile
        function_return liTableFile
      end_function
      function iField_FileNumber returns integer
        integer lhTableAccess liFieldFile
        move (phTableAccessObject(integer(phDbdSystem(self)))) to lhTableAccess
        get piFile.i of lhTableAccess DBDTABLE_FIELD to liFieldFile
        function_return liFieldFile
      end_function

      object oTable_DD is a DataDictionary
        //set main_file to dbTable.file_number
        procedure OnCreate
          integer lhTableAccess
          move (phTableAccessObject(integer(phDbdSystem(self)))) to lhTableAccess
          set main_file to (piFile.i(lhTableAccess,DBDTABLE_TABLE))
          set piTable_FileNumber to (main_file(self))
          send DDUTIL_DoQuickSetup self
         set cascade_delete_state to false // Don't delete tables if fields exists
        end_procedure
        send OnCreate
        procedure new_current_record integer liOldRec integer liNewRec
          forward send new_current_record liOldRec liNewRec
          send update_ui_properties
        end_procedure
      end_object

                  // The bConstrainHelp function is placed here (instead of inside the
                  // oField_DD object, where it belongs) because of an error in the
                  // constrain mechanism (that is not able to interprete the "self"
                  // symbol correctly)
                  property integer pbCommentedOnly false
                  function bConstrainHelp returns integer
                    integer liFile
                    string lsValue
                    if (pbCommentedOnly(self)) begin
                      get piFile.i of (phTableAccessObject(integer(phDbdSystem(self)))) DBDTABLE_FIELD to liFile
                      get_field_value liFile 5 to lsValue
                      function_return (lsValue<>"")
                    end
                    else function_return 1
                  end_function
      object oField_DD is a DataDictionary
        procedure OnCreate
          integer lhTableAccess
          move (phTableAccessObject(integer(phDbdSystem(self)))) to lhTableAccess
          set main_file      to (piFile.i(lhTableAccess,DBDTABLE_FIELD))
          set constrain_file to (piFile.i(lhTableAccess,DBDTABLE_TABLE))
          set piField_FileNumber to (main_file(self))
          set key_field_state 2 to true
          send DDUTIL_DoQuickSetup self
        end_procedure
        send OnCreate
        set DDO_Server to oTable_DD
        set ordering to 2

        procedure OnConstrain
          integer liFile
          get piFile.i of (phTableAccessObject(integer(phDbdSystem(self)))) DBDTABLE_TABLE to liFile
          set constrain_file to liFile
          get piFile.i of (phTableAccessObject(integer(phDbdSystem(self)))) DBDTABLE_FIELD to liFile
          vconstrain liFile as (bConstrainHelp(self))
        end_procedure

        Procedure Field_Defaults
          integer liPos
          //integer lhTableAccess
          //move (phTableAccessObject(integer(phDbdSystem(self)))) to lhTableAccess
          get iNextAvailableFieldPosCurrentTable of (phTableAccessObject(integer(phDbdSystem(self)))) to liPos
          set field_changed_value 2 to liPos
        End_Procedure

        procedure save_main_file
          integer liTableFile liFieldFile liTableId
          date ldDate
          string lsName lsBetterName
          get iTable_FileNumber to liTableFile
          get iField_FileNumber to liFieldFile

          get_field_value liTableFile 1 to liTableId
          get_field_value liFieldFile 3 to lsName
          get_field_value liFieldFile 6 to lsBetterName

          if (liTableId=DBDLIB_DICTIONARY or liTableId=DBDLIB_ARTICLES) begin
            set_field_value liFieldFile 3 to lsBetterName
          end
          if (liTableId=DBDLIB_CALENDAR  ) begin
            if (DateIsValid(lsBetterName)) begin
              move (date(lsBetterName)) to ldDate
              move (DateToStr(ldDate,DF_DATE_MILITARY,1,"")) to lsName
              set_field_value liFieldFile 3 to lsName
            end
            else error 205 "Enter a valid date"
          end

          forward send save_main_file
        end_procedure
      end_object
      object oIndex_DD is a DataDictionary
        procedure OnCreate
          integer lhTableAccess
          move (phTableAccessObject(integer(phDbdSystem(self)))) to lhTableAccess
          set main_file      to (piFile.i(lhTableAccess,DBDTABLE_INDEX))
          set constrain_file to (piFile.i(lhTableAccess,DBDTABLE_TABLE))
          set piIndex_FileNumber to (main_file(self))
          send DDUTIL_DoQuickSetup self
        end_procedure
        send OnCreate
        set DDO_Server to oTable_DD
        set ordering to 1
      end_object

      set server to oTable_DD
      set main_dd to oTable_DD

      set auto_clear_deo_state to false

      set Verify_Save_Msg to GET_Verify_Save_AutoName
      set Verify_Delete_Msg to GET_Verify_Delete_AutoName

      procedure DoSetPanelLabel
        string lsValue lsTableFn
        move "Document your database (#, #)" to lsValue
        move (replace("#",lsValue,psRootNamePrefix(phTableAccessObject(phDbdSystem(self))))) to lsValue
        get DBMS_TablePath (piTable_FileNumber(self)) to lsTableFn
        move (replace("#",lsValue,lsTableFn)) to lsValue
        set label to lsValue
      end_procedure
      send DoSetPanelLabel

      set p_auto_column to 1
      object dbTable_Tbl_Id is a aps.dbForm label "Table no:"
        send bind_data (piTable_FileNumber(self)) 1 // entry_item dbTable.Tbl_Id
        set prompt_object 0 to (DefaultPromptList(self))
      end_object
      object dbTable_Tbl_Name is a aps.dbForm label NONE snap SL_RIGHT_SPACE
        send bind_data (piTable_FileNumber(self)) 2 // entry_item dbTable.Tbl_Name
        set p_extra_internal_width to -26
        set entry_state item 0 to FALSE
        set enabled_state to FALSE
      end_object
      object dbTable_Tbl_Logic_Name is a aps.dbForm label "Logical name:"
        send bind_data (piTable_FileNumber(self)) 3 // entry_item dbTable.Tbl_Logic_Name
        set entry_state item 0 to FALSE
        set enabled_state to FALSE
      end_object
      object dbTable_Tbl_Physic_Name is a aps.dbForm snap SL_RIGHT_SPACE label "Physical name:"
        set p_extra_internal_width to -300
        send bind_data (piTable_FileNumber(self)) 4 // entry_item dbTable.Tbl_Physic_Name
        set entry_state item 0 to FALSE
        set enabled_state to FALSE
      end_object
      object dbTable_Tbl_Not_Found is a aps.dbCheckBox label "Table definition not found"
        send bind_data (piTable_FileNumber(self)) 5 // entry_item dbTable.Tbl_Not_Found
        set enabled_state to FALSE
      end_object
      object dbTable_Tbl_Not_Found is a aps.dbCheckBox label "Table obsolete" snap SL_RIGHT_SPACE
        send bind_data (piTable_FileNumber(self)) 8 // entry_item dbTable.Tbl_Obsolete
      end_object
      object dbTable_Tbl_OpenAs_Path is a aps.dbForm label "Data path:"
        set p_extra_internal_width to -1050
        send bind_data (piTable_FileNumber(self)) 6 // entry_item dbTable.Tbl_OpenAs_Path
        set enabled_state to FALSE
      end_object
      set p_auto_column to 0
      send aps_goto_max_row
      send aps_make_row_space 2
      object oSliderLabel is a aps.TextBox label "Font size:"
      end_object

      object oSlider is a TrackBar
        set Size             To 13 100
        set Location         To 50 10
        set Minimum_Position To 12
        set Maximum_Position To 36
        set Skip_State to true

        procedure OnSliding
          integer liFontSize
          get Current_Position to liFontSize
          send DoAllFontSize liFontSize
        end_procedure

        procedure OnFinishedSliding
          integer liFontSize
          get Current_Position to liFontSize
          send DoAllFontSize liFontSize
        end_procedure
        property integer p_extra_external_width 30
      end_object
      send aps_auto_locate_control (oSlider(self)) SL_RIGHT
      send aps_align_by_moving (oSlider(self)) (dbTable_Tbl_OpenAs_Path(self)) SL_ALIGN_LEFT
      object oDisplayDefBtn is a aps.Button snap SL_RIGHT
        procedure DisplayDef
          integer liTableID liTableFile
          get iTable_FileNumber to liTableFile
          get_field_value liTableFile 1 to liTableId
          send FDX_ModalDisplayFileAttributes 0 liTableId
        end_procedure
        on_item "Show definition" send DisplayDef
        set size to 14 60
        set skip_state to TRUE
      end_object
      object oReadBtn is a aps.Button snap SL_RIGHT
        procedure ReadDB
          integer lhDbdSystem
          if (MB_Verify4("Read (new) table- and field definitions into the description tables?","","","",0)) begin
            // This one needs to refresh fastload.fdx (if enabled) before
            // proceeding.
            send FV_FastLoadRefresh // Refresh FastLoad file if active
            get phDbdSystem to lhDbdSystem
            send DbdControl_ReadDatabaseDefinitions lhDbdSystem
            send update_fields_list
            send obs "Done"
          end
        end_procedure
        on_item "Read definitions" send ReadDB
        set size to 14 60
        set skip_state to TRUE
      end_object

      object dbTable_Tbl_Description is a aps.dbEdit label "Table description:     (Use Alt+Up/Dn to move to previous/next table)" snap SL_RIGHT_SPACE relative_to (dbTable_Tbl_Name(self)) NEW_COLUMN
        set label_justification_mode to JMODE_TOP
        set size to 65 253
        send bind_data (piTable_FileNumber(self)) 7 // entry_item dbTable.Tbl_Description
        set peAnchors to (anTop+anLeft+anRight)
        on_key KEY_ALT+KEY_UP_ARROW   send MoveTableUp
        on_key KEY_ALT+KEY_DOWN_ARROW send MoveTableDown
        procedure MoveTableUp
          send request_save
          send find of oTable_DD LT 1
        end_procedure
        procedure MoveTableDown
          send request_save
          send find of oTable_DD GT 1
        end_procedure
      end_object
      send aps_goto_max_row
      send aps_make_row_space 5
      set p_auto_column to 0

      object oTabs is a aps.dbTabDialog
        set peAnchors to (anTop+anLeft+anRight+anBottom)
        object oTab1 is a aps.dbTabpage label "Fields"
          set p_auto_column to 0
          object oLst is a aps.dbGrid // Fields
            set server to oField_DD
            set ordering to 2
//          set highlight_row_state to DFTRUE
//          set highlight_row_color to (rgb(0,255,255))
//          set current_item_color to (rgb(0,255,255))

            set highlight_row_state to DFTRUE
            set CurrentCellColor     to clHighlight
            set CurrentCellTextColor to clHighlightText
            set CurrentRowColor      to clHighlight
            set CurrentRowTextColor  to clHighlightText

            set peAnchors to (anTop+anLeft+anBottom)
            get piField_FileNumber to filenumber
            set size to 83 0
            begin_row
              move 2 to fieldindex
              entry_item indirect_file.recnum {noput}      // dbField.Fld_Pos          {noput}
              move 3 to fieldindex
              entry_item indirect_file.recnum {noenter}    // dbField.Fld_Name         {noenter}
              entry_item ""                                // ""
//            move 4 to fieldindex
//            entry_item indirect_file.recnum {noenter}    // dbField.Fld_Not_Found    {noenter}
              move 8 to fieldindex
              entry_item indirect_file.recnum              // dbField.Obsolete         {noenter}
              move 6 to fieldindex
              entry_item indirect_file.recnum              // dbField.Suggested_Label  {noenter}
            end_row
            set header_label 0 to "Pos"
            set header_label 1 to "Name"
//          set column_checkbox_state 3 to true
//          set header_label 3 to "Err"
            set column_checkbox_state 3 to true
            set header_label 3 to "Obsolete"
            set header_label 4 to "Better name"
            set aps_fixed_column_width 2 to 16
            procedure color_the_row
              integer liBase liMax liItem
              get base_item to liBase
              get Grid_Columns self to liMax
              decrement liMax
              for liItem from liBase to (liBase+liMax)
                set item_color item liItem  to (RGB_Brighten(clRed,75))
              loop
            end_procedure
            procedure entry_display integer liInt1 integer liInt2
              integer liBase liFile lbFieldNotFound
              string lsBmp lsValue
              get piField_FileNumber to liFile
              get base_item to liBase
              forward send entry_display liInt1 liInt2
              get_field_value liFile 5 to lsValue
              if (lsValue<>"") move "openbook.bmp" to lsBmp // dbField.Fld_Description
              else move "" to lsBmp
              set form_bitmap (liBase+2) to lsBmp
              get_field_value liFile 4 to lbFieldNotFound
              if lbFieldNotFound send color_the_row
            end_procedure
          end_object
          send aps_goto_max_row
          object oOrdering is a aps.ComboForm label "&Order fields by:" abstract AFT_ASCII8
            set peAnchors to (anLeft+anBottom)
            set p_extra_internal_width to -8
            set skip_state to true
            set combo_sort_state to false
            set entry_state item 0 to false
            send Combo_Add_Item "Position"
            send Combo_Add_Item "Name"
            set value item 0 to "Position"
            procedure OnChange
              integer liOrder
              string lsValue
              get value item 0 to lsValue
              if (lsValue="Position") move 2 to liOrder
              else move 1 to liOrder
              send FieldListOrdering liOrder
            end_procedure
          end_object

          procedure ToggleFieldOrder
            integer liOrdering
            get ordering of oLst to liOrdering
            if (liOrdering=2) set value of oOrdering item 0 to "Name"
            else set value of oOrdering item 0 to "Position"
          end_procedure
          on_key KEY_ALT+KEY_O send ToggleFieldOrder

          procedure DoFieldSearch
            integer lhView
            get ViewPanelObjectId to lhView
            send Activate_DbdFieldSearcher lhView
          end_procedure

          object oFieldSearchBtn is a aps.Button snap SL_RIGHT_SPACE
            set peAnchors to (anLeft+anBottom)
            set size to 14 55
            set skip_state to TRUE
            on_item "Field &search" send DoFieldSearch
          end_object
          on_key KEY_ALT+KEY_S send DoFieldSearch

          object oConstrainCB is a aps.CheckBox label "Show only &commented fields" snap SL_RIGHT_SPACE
            set peAnchors to (anLeft+anBottom)
            set skip_state to true
            procedure OnChange
              integer liOrder
              string lsValue
              get value of oOrdering item 0 to lsValue
              if (lsValue="Position") move 2 to liOrder
              else move 1 to liOrder
              set pbCommentedOnly to (checked_state(self))
              send FieldListOrdering liOrder
            end_procedure
          end_object
          procedure DoConstrainRem
            integer lhConstrainCB
            move oConstrainCB to lhConstrainCB
            set select_state of lhConstrainCB to (not(select_state(lhConstrainCB)))
          end_procedure
          on_key KEY_ALT+KEY_C send DoConstrainRem

          object dbField_Fld_Description is a aps.dbEdit label "Description of field:     (Use Ctrl+Up/Dn to move to previous/next field)" snap SL_RIGHT relative_to (oLst(self))
            set label_justification_mode to JMODE_TOP
            set server to oField_DD
            set peAnchors to (anTop+anLeft+anRight+anBottom)
            set size to 72 250
            send bind_data (piField_FileNumber(self)) 5 // entry_item dbField.Fld_Description

            property integer piFontSize 12

            procedure upfont
              integer liFontSize
              get piFontSize to liFontSize
              increment liFontSize
              set Fontsize To liFontSize 0
              set piFontSize to liFontSize
            end_procedure
            procedure downfont
              integer liFontSize
              get piFontSize to liFontSize
              decrement liFontSize
              set Fontsize To liFontSize 0
              set piFontSize to liFontSize
            end_procedure
            on_key KEY_ALT+KEY_UP_ARROW   send upfont
            on_key KEY_ALT+KEY_DOWN_ARROW send downfont

            procedure MoveFieldUp
              send process_key of oLst KUPARROW
            end_procedure
            procedure MoveFieldDown
              send process_key of oLst KDOWNARROW
            end_procedure
            procedure MoveTableUp
              send request_save
              send find of oTable_DD LT 1
            end_procedure
            procedure MoveTableDown
              send request_save
              send find of oTable_DD GT 1
            end_procedure

            on_key KEY_CTRL+KEY_UP_ARROW   send MoveFieldUp
            on_key KEY_CTRL+KEY_DOWN_ARROW send MoveFieldDown
            on_key KEY_ALT+KEY_UP_ARROW   send MoveTableUp
            on_key KEY_ALT+KEY_DOWN_ARROW send MoveTableDown
            procedure request_clear
              send request_clear of oLst
            end_procedure
            procedure request_save
              send request_save of oLst
            end_procedure
            procedure request_delete
              send request_delete of oLst
            end_procedure
          end_object
          send aps_relocate (dbField_Fld_Description(self)) 0 7 DFTRUE
          object dbField_Fld_Definition is a aps.dbForm label NONE snap SL_DOWN
            send bind_data (piField_FileNumber(self)) 7 // entry_item dbField.Fld_Definition
            set server to oField_DD
            set enabled_state to FALSE
            set peAnchors to (anLeft+anRight+anBottom)
          end_object
          procedure aps_beautify
            send APS_ALIGN_INSIDE_CONTAINER_BY_SIZING (dbField_Fld_Description(self)) SL_ALIGN_RIGHT
            send APS_ALIGN_INSIDE_CONTAINER_BY_SIZING (dbField_Fld_Definition(self)) SL_ALIGN_RIGHT
          end_procedure
          procedure FieldListOrdering integer liOrder
            integer liRec
            get current_record of oField_DD to liRec
            set ordering of oLst to liOrder
            set ordering of oField_DD to liOrder
            send rebuild_constraints of oField_DD
            send beginning_of_data to oLst
            //send find_by_recnum of oField_DD (main_file(oField_DD(self))) liRec
          end_procedure
        end_object // oTab1
        object oTab2 is a aps.dbTabpage label "Indices"
          set p_auto_column to 0
          object oLst is a aps.dbGrid // Indices
            set server to oIndex_DD
            set ordering to 1
          //set highlight_row_state to DFTRUE
          //set highlight_row_color to (rgb(0,255,255))
          //set current_item_color to (rgb(0,255,255))

            set highlight_row_state to DFTRUE
            set CurrentCellColor     to clHighlight
            set CurrentCellTextColor to clHighlightText
            set CurrentRowColor      to clHighlight
            set CurrentRowTextColor  to clHighlightText

            set peAnchors to (anTop+anLeft+anBottom)
          //  set Verify_Save_Msg to GET_Verify_Save_AutoName
          //  set Verify_Delete_Msg to GET_Verify_Delete_AutoName
            get piIndex_FileNumber to filenumber
            begin_row
              move 2 to fieldindex
              entry_item indirect_file.recnum {noput}   //entry_item dbIndex.Idx_Pos          {noput}
              move 3 to fieldindex
              entry_item indirect_file.recnum {noenter} //entry_item dbIndex.Idx_Name         {noenter}
              entry_item ""                             //entry_item ""
              move 5 to fieldindex
              entry_item indirect_file.recnum {noenter} //entry_item dbIndex.Idx_Not_Found    {noenter}
            end_row
            set header_label 0 to "Pos"
            set header_label 1 to "Ordering fields"
            set aps_fixed_column_width 2 to 16
            set column_checkbox_state 3 to true
            set header_label 3 to "Not found"
            procedure entry_display integer liInt1 integer liInt2
              integer liBase liFile
              string lsBmp lsValue
              get piIndex_FileNumber to liFile
              get base_item to liBase
              forward send entry_display liInt1 liInt2
              get_field_value liFile 4 to lsValue
              if (lsValue<>"") move "openbook.bmp" to lsBmp // dbIndex.Idx_Description
              else move "" to lsBmp
              set form_bitmap (liBase+2) to lsBmp
            end_procedure
          end_object
          object dbIndex_Idx_Description is a aps.dbEdit label "Description of index:" snap SL_RIGHT_SPACE
            set label_justification_mode to JMODE_TOP
            set server to oIndex_DD
            set peAnchors to (anTop+anLeft+anRight+anBottom)
            set size to 89 250
            send bind_data (piIndex_FileNumber(self)) 4 // entry_item dbIndex.Idx_Description
            procedure MoveIndexUp
              send process_key of oLst KUPARROW
            end_procedure
            procedure MoveIndexDown
              send process_key of oLst KDOWNARROW
            end_procedure
            procedure MoveTableUp
              send request_save
              send find of oTable_DD LT 1
            end_procedure
            procedure MoveTableDown
              send request_save
              send find of oTable_DD GT 1
            end_procedure

            on_key KEY_CTRL+KEY_UP_ARROW   send MoveIndexUp
            on_key KEY_CTRL+KEY_DOWN_ARROW send MoveIndexDown
            on_key KEY_ALT+KEY_UP_ARROW   send MoveTableUp
            on_key KEY_ALT+KEY_DOWN_ARROW send MoveTableDown
            procedure request_clear
              send request_clear of oLst
            end_procedure
            procedure request_save
              send request_save of oLst
            end_procedure
            procedure request_delete
              send request_delete of oLst
            end_procedure
          end_object
          procedure aps_beautify
            send APS_ALIGN_INSIDE_CONTAINER_BY_SIZING (dbIndex_Idx_Description(self)) SL_ALIGN_RIGHT
          end_procedure
        end_object // oTab2
        procedure ToggleFieldOrder
          if (current_tab(self)=0) send ToggleFieldOrder of oTab1
        end_procedure
        procedure DoFieldSearch
          if (current_tab(self)=0) send DoFieldSearch of oTab1
        end_procedure
        procedure DoConstrainRem
          if (current_tab(self)=0) send DoConstrainRem of oTab1
        end_procedure
      end_object // oTabs

      on_key KEY_ALT+KEY_O send ToggleFieldOrder of oTabs
      on_key KEY_ALT+KEY_S send DoFieldSearch of oTabs
      on_key KEY_ALT+KEY_C send DoConstrainRem of oTabs

      procedure update_fields_list
        integer liRecnum lhTableAccess liTableFile
        move (phTableAccessObject(integer(phDbdSystem(self)))) to lhTableAccess
        get piFile.i of lhTableAccess DBDTABLE_TABLE to liTableFile
        get current_record of oTable_DD to liRecnum
        send find_by_recnum of oTable_DD liTableFile liRecnum
      end_procedure

      procedure DoAllFontSize integer liFontSize
        set Fontsize of (dbTable_Tbl_Description(self)) to liFontSize 0
        set Fontsize of (dbField_Fld_Description(oTab1(oTabs(self)))) to liFontSize 0
        set Fontsize of (dbIndex_Idx_Description(oTab2(oTabs(self)))) to liFontSize 0
      end_procedure

      procedure PopupControl
        integer lhDbdSystem
        get phDbdSystem to lhDbdSystem
        send Popup_DbdControlPanel lhDbdSystem
        if (DbdControl_NewTablesSelected()) begin

          CREATE_OBJECT_GROUP OG_Dbd_View PARENT ghClientArea_FastView (psRootNamePrefix(phTableAccessObject(lhDbdSystem)))
          if (OG_Current_Object#<>0) send popup to OG_Current_Object#
          else send obs "Tables could not be opened"
          send close_panel
        end
        else begin
          send request_clear_all
          send DoSetPanelLabel
        end
      end_procedure

      procedure PrintReport
        integer lhView
        get ViewPanelObjectId to lhView
        send popup_dbdreport (phDbdSystem(self)) lhView
      end_procedure

      procedure DoRelocateFilelistEntries
        integer lhTableAccess liTableFile liFieldFile liIndexFile
        string lsValue

        // Just save all changes so we don't have to worry about that
        send request_save of oTable_DD
        send request_save of oField_DD
        send request_save of oIndex_DD

        get piFile.i of lhTableAccess DBDTABLE_TABLE to liTableFile
        get piFile.i of lhTableAccess DBDTABLE_FIELD to liFieldFile
        get piFile.i of lhTableAccess DBDTABLE_INDEX to liIndexFile

        move (phTableAccessObject(integer(phDbdSystem(self)))) to lhTableAccess





      end_procedure
      procedure GotoField integer liFile string lsFieldName
        integer lhTableAccess liTableFile liFieldFile liRecnum lbCommentedFieldsOnly
        string lsValue

        // Just save all changes so we don't have to worry about that
        send request_save of oTable_DD
        send request_save of oField_DD
        send request_save of oIndex_DD

        move (phTableAccessObject(integer(phDbdSystem(self)))) to lhTableAccess

        if (pbCommentedOnly(self)) begin
          // At this point we have to make sure that the list of fields
          // isn't constrained to only commented fields if the field
          // we are about to display doesn't have any comments
          get piFile.i of lhTableAccess DBDTABLE_FIELD to liFieldFile
          clear liFieldFile
          set_field_value liFieldFile 1 to liFile
          set_field_value liFieldFile 3 to lsFieldName
          vfind liFieldFile 1 EQ
          if (found) begin
            get_field_value liFieldFile 5 to lsValue
            if (lsValue="") set checked_state of (oConstrainCB(oTab1(oTabs(self)))) to false
          end
        end

        get piFile.i of lhTableAccess DBDTABLE_TABLE to liTableFile
        clear liTableFile
        set_field_value liTableFile 1 to liFile
        vfind liTableFile 1 EQ
        if (found) begin
          get_field_value liTableFile 0 to liRecnum
          send find_by_recnum of oTable_DD liTableFile liRecnum

          get piFile.i of lhTableAccess DBDTABLE_FIELD to liFieldFile
          clear liFieldFile
          set_field_value liFieldFile 1 to liFile
          set_field_value liFieldFile 3 to lsFieldName
          vfind liFieldFile 1 EQ
          if (found) begin
            get_field_value liFieldFile 0 to liRecnum
            send find_by_recnum of oField_DD liFieldFile liRecnum
          end
          else if (liFile<>50) send obs "Field could not found." "You should click the 'Read DB definitions' button" "to create the missing files and fields"

        end
        else if (liFile<>50) send obs "Table could not found." "You should click the 'Read DB definitions' button" "to create the missing files and fields"
      end_procedure

      procedure GotoEditObject
        send activate of dbField_Fld_Description
      end_procedure

      procedure update_ui_properties
        integer liTableFile liTableId liRow lhLst
        string lsColumnHeader

        get iTable_FileNumber to liTableFile
        move (oLst(oTab1(oTabs(self)))) to lhLst

        get_field_value liTableFile 1 to liTableId
        get iFindPredefinedTableRow of oDBD_PredefinedLibraries liTableId to liRow
        if (liRow=-1) begin // Normal table
          move "Better name" to lsColumnHeader
          set no_create_state of lhLst to true
        end
        else begin
          get psColumnHeader.i of oDBD_PredefinedLibraries liRow to lsColumnHeader
          set no_create_state of lhLst to false
        end
        set header_label of lhLst 4 to lsColumnHeader
      end_procedure

      object oPrintBtn is a aps.Multi_Button
        set peAnchors to (anRight+anBottom)
        on_item "Report" send PrintReport
      end_object

      object oReassignBtn is a aps.Multi_Button
        set peAnchors to (anRight+anBottom)
        procedure ReassignFilelist
          integer lhTableAccess
          move (phTableAccessObject(integer(phDbdSystem(self)))) to lhTableAccess
          send Run.i of oDbdFilelistReassigner lhTableAccess
        end_procedure
        on_item "Reassign" send ReassignFilelist
      end_object
      object oControlBtn is a aps.Multi_Button
        set peAnchors to (anRight+anBottom)
        on_item "Advanced" send PopupControl
      end_object
      object oCloseBtn is a aps.Multi_Button
        set peAnchors to (anRight+anBottom)
        on_item t.btn.close send close_panel
      end_object
      send aps_locate_multi_buttons

      procedure aps_beautify
        send aps_align_inside_container_by_moving (dbTable_Tbl_Description(self)) SL_ALIGN_RIGHT
        send aps_align_inside_container_by_sizing (oTabs(self)) SL_ALIGN_RIGHT
        send aps_beautify to (oTab1(oTabs(self)))
        send aps_beautify to (oTab2(oTabs(self)))
      end_procedure

      procedure Close_Panel // Release when closed!
        integer lhView
        get ViewPanelObjectId to lhView
        send DestroyingDbdView of oDbdFieldSearcher lhView
        send DestroyingDbdView of oDbdReport lhView
        Forward Send Close_Panel
        send Request_Destroy_Object of (phDbdSystem(self))
        send Request_Destroy_Object
      end_procedure

      procedure Close_Query_View // Meant to be broadcasted by somebody that needs to close all queries
        set delegation_mode to DELEGATE_TO_PARENT
        send deferred_message MSG_close_panel
      end_procedure

      move self to OG_Current_Object# // global integer
    end_object
    send aps_SetMinimumDialogSize OG_Current_Object#
  end
END_DEFINE_OBJECT_GROUP

procedure Popup_DBD_View
  CREATE_OBJECT_GROUP OG_Dbd_View "db"
  if (OG_Current_Object#<>0) send popup to OG_Current_Object#
  else send obs "Tables could not be opened"
end_procedure
