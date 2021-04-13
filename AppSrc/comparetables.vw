// Use CompareTables.vw // Compare table data
Use Aps
Use CompareTables.nui // cCompareTableData class
Use ObjGroup.utl // Defining groups of objects

Use ApsWiz.pkg   // APS wizard classes
Use FdxField.nui // FDX Field things
Use MsgBox.utl   // obs procedure
Use ToolUtilities.pkg // aps.YellowBox class

object oCompareTableData_Wiz is a aps.WizardPanel label "Compare table data"
  send make_nice_size WIZSIZE_NORMAL
  property string psTable1
  property string psTable2

  Property String psPrevFolder1 ""
  Property String psPrevFolder2 ""

  object oOpenDialog is a OpenDialog
    set NoChangeDir_State to true
  end_object

  property integer phComparer

  object oPage1 is a aps.WizardPage
    object oYellow is a aps.YellowBox
      set size to 55 100
      set value item 0 to "Use this wizard to setup table data comparison."
      set value item 1 to ""
      set value item 2 to "Select two identically defined tables on disk and create a list of differences in their data content."
    end_object
    send aps_goto_max_row
    send aps_make_row_space 20
    object oTable1 is a aps.Form label "   Table 1:" abstract AFT_ASCII100
      set enabled_state to false
      set p_extra_internal_width to -300
    end_object
    object oBtn1 is a aps.Button snap SL_RIGHT
      set size to 13 40
      on_item "Select" send select_table1
    end_object
    send aps_goto_max_row
    send aps_make_row_space 5
    object oTable2 is a aps.Form label "   Table 2:" abstract AFT_ASCII100
      set enabled_state to false
      set p_extra_internal_width to -300
    end_object
    object oBtn2 is a aps.Button snap SL_RIGHT
      set size to 13 40
      on_item "Select" send select_table2
    end_object

    procedure update_display
      set value of oTable1 to (psTable1(self))
      set value of oTable2 to (psTable2(self))
    end_procedure

    function select_table string lsFolder string lsLookForTable returns string
      string lsTable lsFilter
      set Dialog_Caption of oOpenDialog to "Find a table"
      move "DAT files|*.dat|All files|*.*" to lsFilter
      if (lsLookForTable<>"") move (lsLookForTable+"|"+lsLookForTable+"|"+lsFilter) to lsFilter
      set Filter_String  of oOpenDialog to lsFilter
      if (lsFolder<>"") set Initial_Folder of oOpenDialog to lsFolder
      if (Show_Dialog(oOpenDialog)) get File_Name of oOpenDialog to lsTable
      else move "" to lsTable
      function_return lsTable
    end_function

    procedure select_table1
      string lsTable lsFolder lsLookForTable
      get psPrevFolder1 to lsFolder

      get psTable2 to lsLookForTable
      get SEQ_RemovePathFromFileName lsLookForTable to lsLookForTable

      get select_table lsFolder lsLookForTable to lsTable
      if (lsTable<>"") begin
        get SEQ_ExtractPathFromFileName lsTable to lsFolder
        set psPrevFolder1 to lsFolder
        set psTable1 to lsTable
        send update_display
      end
    end_procedure

    procedure select_table2
      string lsTable lsFolder lsLookForTable
      get psPrevFolder2 to lsFolder

      get psTable1 to lsLookForTable
      get SEQ_RemovePathFromFileName lsLookForTable to lsLookForTable

      get select_table lsFolder lsLookForTable to lsTable
      if (lsTable<>"") begin
        get SEQ_ExtractPathFromFileName lsTable to lsFolder
        set psPrevFolder2 to lsFolder
        set psTable2 to lsTable
        send update_display
      end
    end_procedure

    function iPageValidate returns boolean
      integer liError
      string lsTable1 lsTable2
      send CloseTables of (phComparer(self))
      get bOpenTables of (phComparer(self)) (psTable1(self)) (psTable2(self)) to liError
      if liError begin
        if (liError=1) send obs "Tables couldn't be opened"
        if (liError=2) send obs "Table definitions are not identical"
        send obs "Select valid tables"
      end
      function_return (liError=0)
    end_function

    procedure aps_beautify
      send aps_align_inside_container_by_sizing (oYellow(self)) SL_ALIGN_RIGHT
    end_procedure
  end_object // oPage1

  object oPage2 is a aps.WizardPage
    object oYellow is a aps.YellowBox
      set size to 55 100
      set value item 0 to "Select the (unique) index to use when identifying records in the tables."
      set value item 1 to ""
      set value item 2 to ""
    end_object

    send aps_goto_max_row
    send aps_make_row_space 10

    object oIndex is a aps.ComboFormAux abstract AFT_ASCII50 label "Select index:"
      set allow_blank_state to FALSE
      set entry_state item to FALSE
      set label_justification_mode to JMODE_TOP

      procedure fill_list.i integer liTable
        integer liMax liIndex liItm liAux
        string lsIndices lsIndex
        send Combo_Delete_Data
        get FDX_SetOfIndices 0 liTable DF_INDEX_TYPE_ONLINE to lsIndices

        send combo_add_item "Recnum" 0
        move -1 to liAux

        get HowManyIntegers lsIndices to liMax
        for liItm from 1 to liMax
          get ExtractInteger lsIndices liItm to liIndex
          if (FDX_IndexUnique(0,liTable,liIndex)) begin
            get FDX_IndexAsFieldNames 0 liTable liIndex 0 to lsIndex
            send combo_add_item (string(liIndex)+": "+lowercase(lsIndex)) liIndex
            if (liAux=-1) move liIndex to liAux
          end
        loop
        if (liAux<>-1) set Combo_Current_Aux_Value to liAux
      end_procedure
    end_object

    function iPageValidate returns boolean
      integer liTable liIndex
      get Combo_Current_Aux_Value of oIndex to liIndex
      set piIndex of (phComparer(self)) to liIndex
      function_return TRUE
    end_function

    procedure aps_beautify
      send aps_align_inside_container_by_sizing (oYellow(self)) SL_ALIGN_RIGHT
      send aps_align_inside_container_by_moving (oINdex(self)) SL_ALIGN_CENTER
    end_procedure

    procedure DoInitialize
      integer liTable
      get piTable1 of (phComparer(self)) to liTable
      send fill_list.i of oIndex liTable
    end_procedure
  end_object // oPage2

  object oPage3 is a aps.WizardPage
    object oYellow is a aps.YellowBox
      set size to 30 100
      set value item 0 to "When index-identical records are compared the default is to consider all columns in the tables."
      set value item 1 to ""
      set value item 2 to "If you want to ignore specific column indicate so in the list below."
    end_object

    send aps_goto_max_row
    send aps_make_row_space 10

    object oGrid is a aps.Grid
      send GridPrepare_AddCheckBoxColumn ""
      send GridPrepare_AddColumn "" AFT_ASCII15
      send GridPrepare_AddColumn "" AFT_ASCII15
      send GridPrepare_Apply self
      set select_mode to MULTI_SELECT
      on_key KNEXT_ITEM send switch
      on_key KPREVIOUS_ITEM send switch_back
      set Header_Visible_State to FALSE
      set gridline_mode to GRID_VISIBLE_NONE
      set size to 85 0
      on_key KEY_CTRL+KEY_A send select_all
      on_key KEY_CTRL+KEY_I send deselect_all

      procedure select_all
        send Grid_RowSelectAll self
      end_procedure
      procedure deselect_all
        send Grid_RowDeselectAll self
      end_procedure

      procedure select_toggling integer liItem integer lbState
        integer liCurrentItem liColumns
        get Grid_Columns self to liColumns
        get current_item to liCurrentItem
        move ((liCurrentItem/liColumns)*liColumns) to liCurrentItem // Redirect to first column
        forward send select_toggling liCurrentItem lbState
      end_procedure

      procedure HandleField integer liFile integer liField string lsName integer liType integer liLen integer liPrec integer liRelFile integer liRelField integer liIndex integer liOffSet
        integer liBase
        if (liType<>DF_OVERLAP) begin
          get item_count to liBase
          send Grid_AddCheckBoxItem self FALSE
          send add_item MSG_NONE lsName
          send add_item MSG_NONE (FDX_FieldTypeAndLengthName(0,liFile,liField))
          set aux_value liBase to liField
        end
      end_procedure

      procedure fill_list.i integer liTable
        send delete_data
        send FDX_FieldCallBack 0 liTable MSG_HandleField self
        send Grid_SetEntryState self FALSE
      end_procedure

      procedure HandleRow integer liRow integer liBase
        integer liField
        get aux_value liBase to liField
        set IgnoreFieldState of (phComparer(self)) liField to TRUE
      end_procedure
    end_object

    procedure aps_beautify
      send aps_align_inside_container_by_sizing (oYellow(self)) SL_ALIGN_RIGHT
      send aps_align_inside_container_by_moving (oGrid(self)) SL_ALIGN_CENTER
    end_procedure

    procedure DoInitialize
      integer liTable
      get piTable1 of (phComparer(self)) to liTable
      send fill_list.i of oGrid liTable
    end_procedure

    function iPageValidate returns boolean
      // Here we need to transfer the fields we want to ignore <--- OBS OBS OBS
      send IgnoreFieldsClearAll of (phComparer(self))
      send Grid_RowCallBackSelected (oGrid(self)) MSG_HandleRow (oGrid(self))
      function_return TRUE
    end_function

  end_object // oPage3

  object oPage4 is a aps.WizardPage

    object oTable1 is a aps.Form label "   Table 1:" abstract AFT_ASCII100
      set enabled_state to false
      set p_extra_internal_width to -255
    end_object
    send aps_goto_max_row
    object oTable2 is a aps.Form label "   Table 2:" abstract AFT_ASCII100
      set enabled_state to false
      set p_extra_internal_width to -255
    end_object
    send aps_goto_max_row
    send aps_make_row_space 5
    object oRad is a aps.RadioGroup label "Only find..."
      object oRad1 is a aps.Radio label "All differences"
      end_object
      object oRad2 is a aps.Radio label "Records missing in table 1"
      end_object
      object oRad3 is a aps.Radio label "Records missing in table 2"
      end_object
      object oRad4 is a aps.Radio label "Records present in both tables"
      end_object
      object oRad5 is a aps.Radio label "Records missing in one of the tables"
      end_object
    end_object

    procedure aps_beautify
      send aps_align_inside_container_by_moving (oRad(self)) SL_ALIGN_CENTER
    end_procedure

    procedure DoInitialize
      set value of oTable1 to (value(oTable1(oPage1)))
      set value of oTable2 to (value(oTable2(oPage1)))
    end_procedure

    function iPageValidate returns boolean
      // Here we need to transfer the fields we want to ignore <--- OBS OBS OBS
      set piCompMode of (phComparer(self)) to (current_radio(oRad))
      function_return TRUE
    end_function

  end_object // oPage4

  procedure DisplayPage integer liPage
    integer liCurrentPage
    get piCurrentPage to liCurrentPage
    if (liPage=1 and liCurrentPage<1) send DoInitialize of oPage2
    if (liPage=2 and liCurrentPage<2) send DoInitialize of oPage3
    if (liPage=3 and liCurrentPage<3) send DoInitialize of oPage4
    forward send DisplayPage liPage
  end_procedure

  property boolean pbCancel

  procedure DoFinish
    set pbCancel to FALSE
  end_procedure

  procedure aps_beautify
    forward send aps_beautify
    send aps_beautify of oPage1
    send aps_beautify of oPage2
    send aps_beautify of oPage3
    send aps_beautify of oPage4
  end_procedure

  function bPopup.i integer lhComparer returns boolean
    set pbCancel to TRUE
    set phComparer to lhComparer
    set psTable1 to "" //"C:\Apps\Admin\Data\workhour.dat"
    set psTable2 to "" //"\\Sture-6fzexs4wu\webapps\Backup\Admin\Data\workhour.dat"
    send update_display of oPage1
    send popup
    function_return (not(pbCancel(self)))
  end_function

end_object // oCompareTableData_Wiz

DEFINE_OBJECT_GROUP OG_CompareTableDataView
  object oCompareTableData_View is a aps.View label "Compare table data"
    set Border_Style to BORDER_THICK     // Make panel resizeable

    property integer phComparer

    object oGroup is a aps.Group label "Selected tables"
      set peAnchors to (anLeft+anRight)
      send tab_column_define 1 40 35 JMODE_RIGHT

      object oTable1 is a aps.Form label "Table 1:" abstract AFT_ASCII100
        set peAnchors to (anLeft+anRight)
        set enabled_state to false
        set p_extra_internal_width to -200
      end_object
      object oRecords1 is a aps.Form abstract AFT_NUMERIC8.0 snap SL_RIGHT
        set peAnchors to (anRight)
        set enabled_state to false
      end_object

      object oTable2 is a aps.Form label "Table 2:" abstract AFT_ASCII100
        set peAnchors to (anLeft+anRight)
        set enabled_state to false
        set p_extra_internal_width to -200
      end_object
      object oRecords2 is a aps.Form abstract AFT_NUMERIC8.0 snap SL_RIGHT
        set peAnchors to (anRight)
        set enabled_state to false
      end_object

      object oIndex is a aps.Form label "Index:" abstract AFT_ASCII100
        set peAnchors to (anLeft+anRight)
        set enabled_state to false
        set p_extra_internal_width to -150
      end_object
    end_object

    send aps_goto_max_row

    object oResultGrid is a aps.Grid
      send GridPrepare_AddCheckBoxColumn ""
      send GridPrepare_AddColumn "Index value" AFT_ASCII60
      send GridPrepare_AddCheckBoxColumn "Table 1"
      send GridPrepare_AddCheckBoxColumn "Table 2"
      send GridPrepare_Apply self
      set select_mode to MULTI_SELECT
      on_key KNEXT_ITEM send switch
      on_key KPREVIOUS_ITEM send switch_back
      set gridline_mode to GRID_VISIBLE_NONE
      set size to 150 0
      set peAnchors to (anLeft+anRight)
      set peResizeColumn to rcSelectedColumn // Resize mode (rcAll or rcSelectedColumn)
      set piResizeColumn to 1                // This is the column to resize

      set form_typeface 1 to "Courier New"
      set form_fontheight 1 to 16

      on_key KEY_CTRL+KEY_A send select_all
      on_key KEY_CTRL+KEY_I send deselect_all

      procedure select_all
        send Grid_RowSelectAll self
      end_procedure
      procedure deselect_all
        send Grid_RowDeselectAll self
      end_procedure


                          procedure HandleMoveTo1 integer liTable1 integer liField string lsName integer liType integer liLen integer liPrec integer liRelFile integer liRelField integer liIndex integer liOffSet
                            integer liTable2
                            string lsValue
                            get piTable2 of (phComparer(self)) to liTable2
                            if (liType<>DF_OVERLAP) begin
                              get_field_value liTable2 liField to lsValue
                              set_field_value liTable1 liField to lsValue
                            end
                          end_procedure
                          procedure HandleMoveTo2 integer liTable2 integer liField string lsName integer liType integer liLen integer liPrec integer liRelFile integer liRelField integer liIndex integer liOffSet
                            integer liTable1
                            string lsValue
                            get piTable1 of (phComparer(self)) to liTable1
                            if (liType<>DF_OVERLAP) begin
                              get_field_value liTable1 liField to lsValue
                              set_field_value liTable2 liField to lsValue
                            end
                          end_procedure
                procedure TransferRecord integer liRow integer liBase
                  integer liCompMode liTable1 liTable2 lhComparer
                  get phComparer to lhComparer
                  get piCompMode of lhComparer to liCompMode
                  get piTable1   of lhComparer to liTable1
                  get piTable2   of lhComparer to liTable2
                  send ActivateRecordsRow liRow
                  if (liCompMode=CTP_TABLE1_MISSING) begin
                    clear liTable1
                    send FDX_FieldCallBack 0 liTable1 MSG_HandleMoveTo1 self
                    saverecord liTable1
                  end
                  if (liCompMode=CTP_TABLE2_MISSING) begin
                    send FDX_FieldCallBack 0 liTable2 MSG_HandleMoveTo2 self
                    saverecord liTable2
                  end
                end_procedure
      procedure CreateMissingRecords
        boolean lbContinue
        integer liCompMode liCount
        string lsVal1 lsVal2 lsVal3 lsVal4
        get piCompMode of (phComparer(self)) to liCompMode
        if (liCompMode=CTP_TABLE1_MISSING or liCompMode=CTP_TABLE2_MISSING) begin
          get Grid_SelectedRows self to liCount
          if liCount begin
            move ("Do you want to transfer "+string(liCount)+" records from table") to lsVal1
            move "to table" to lsVal3
            if (liCompMode=CTP_TABLE1_MISSING) begin
              get psTable1 of (phComparer(self)) to lsVal4
              get psTable2 of (phComparer(self)) to lsVal2
            end
            if (liCompMode=CTP_TABLE2_MISSING) begin
              get psTable1 of (phComparer(self)) to lsVal2
              get psTable2 of (phComparer(self)) to lsVal4
            end
            get MB_Verify4 lsVal1 lsVal2 lsVal3 (lsVal4+"?") FALSE to lbContinue
            if lbContinue begin
              begin_transaction
                send Grid_RowCallBackSelected self MSG_TransferRecord self
              end_transaction
              get MB_Verify "Records transferred. Do you want to re-run the comparison?" FALSE to lbContinue
              if lbContinue send run_compare
            end
          end
          else send obs "No rows has been selected"
        end
      end_procedure

      procedure AddResult string lsIndex integer liRec1 integer liRec2
        integer liBase liCompMode lbTransferEnabled

        get piCompMode of (phComparer(self)) to liCompMode
        move (liCompMode=CTP_TABLE1_MISSING or liCompMode=CTP_TABLE2_MISSING) to lbTransferEnabled

        get item_count to liBase
        if lbTransferEnabled send Grid_AddCheckBoxItem self FALSE
        else send add_item MSG_NONE ""
        send add_item MSG_NONE lsIndex
        send Grid_AddCheckBoxItem self (liRec1<>0)
        send Grid_AddCheckBoxItem self (liRec2<>0)
        set aux_value (liBase+1) to liRec1
        set aux_value (liBase+2) to liRec2
      end_procedure

      procedure fill_list
        set dynamic_update_state to FALSE
        send delete_data
        send call_back_results of (phComparer(self)) MSG_AddResult self
        send Grid_SetEntryState self FALSE
        set dynamic_update_state to TRUE
        send ActivateRecordsRow 0
        send UpdateValueGrid
      end_procedure

      procedure select_toggling integer liItem integer lbState
        integer liCurrentItem liColumns
        get Grid_Columns self to liColumns
        get current_item to liCurrentItem
        move ((liCurrentItem/liColumns)*liColumns) to liCurrentItem // Redirect to first column
        forward send select_toggling liCurrentItem lbState
      end_procedure

      procedure row_change integer liRowFrom integer liRowTo
        send ActivateRecordsRow liRowTo
        send UpdateValueGrid
      end_procedure

      procedure item_change integer liItm1 integer liItm2 returns integer
        integer liRval liColumns
        get Grid_Columns self to liColumns
        forward get msg_item_change liItm1 liItm2 to liRval
        if (liItm1/liColumns) ne (liItm2/liColumns) send row_change (liItm1/liColumns) (liItm2/liColumns)
        procedure_return liRval
      end_procedure

      procedure ActivateRecordsRow integer liRow
        integer liTable liBase liRecnum
        get Grid_RowBaseItem self liRow to liBase

        get piTable1 of (phComparer(self)) to liTable
        clear liTable
        if (item_count(self)) begin
          get aux_value (liBase+1) to liRecnum
          if liRecnum begin
            set_field_value liTable 0 to liRecnum
            vfind liTable 0 EQ
          end
        end

        get piTable2 of (phComparer(self)) to liTable
        clear liTable
        if (item_count(self)) begin
          get aux_value (liBase+2) to liRecnum
          if liRecnum begin
            set_field_value liTable 0 to liRecnum
            vfind liTable 0 EQ
          end
        end
      end_procedure

      procedure ActivateRecordsCurrentRow
        integer liRow
        get Grid_CurrentColumn self to liRow
        send ActivateRecordsRow liRow
      end_procedure

    end_object

    send aps_goto_max_row
    object oValueGrid is a aps.Grid
      set peAnchors to (anTop+anLeft+anRight+anBottom)
      send GridPrepare_AddColumn "Field name"    AFT_ASCII15
      send GridPrepare_AddColumn "Value Table 1" AFT_ASCII30
      send GridPrepare_AddColumn "Value Table 2" AFT_ASCII30
      send GridPrepare_Apply self FALSE
      set select_mode to NO_SELECT
      on_key KNEXT_ITEM send switch
      on_key KPREVIOUS_ITEM send switch_back
      set gridline_mode to GRID_VISIBLE_NONE
      set size to 85 0
      set peResizeColumn to rcSelectedColumn // Resize mode (rcAll or rcSelectedColumn)
      set piResizeColumn to 1                // This is the column to resize

      procedure HandleField integer liFile integer liField string lsName integer liType integer liLen integer liPrec integer liRelFile integer liRelField integer liIndex integer liOffSet
        integer liBase
        if (liType<>DF_OVERLAP) begin
          get item_count to liBase
          send add_item MSG_NONE lsName
          send add_item MSG_NONE ""
          send add_item MSG_NONE ""
          set aux_value (liBase+1) to liField
          set aux_value (liBase+2) to liField
          set ItemColor liBase to clBtnFace
        end
      end_procedure

      procedure fill_field_labels
        integer liTable
        set dynamic_update_state to FALSE
        send delete_data
        get piTable1 of (phComparer(self)) to liTable
        send FDX_FieldCallBack 0 liTable MSG_HandleField self
        send Grid_SetEntryState self FALSE
        set dynamic_update_state to TRUE
      end_procedure

      procedure DisplayRow integer liRow integer liBase
        integer liTable liField liType liColor1 liColor2
        integer liRec1 liRec2
        string lsValue1 lsValue2

        get piTable1 of (phComparer(self)) to liTable
        get aux_value (liBase+1) to liField
        get_field_value liTable 0 to liRec1
        if liRec1 get_field_value liTable liField to lsValue1
        else move "" to lsValue1
        set value (liBase+1) to lsValue1

        get piTable2 of (phComparer(self)) to liTable
        get_field_value liTable 0 to liRec2
        get aux_value (liBase+2) to liField
        if liRec2 get_field_value liTable liField to lsValue2
        else move "" to lsValue2
        set value (liBase+2) to lsValue2

        if (lsValue1<>lsValue2) move (RGB_Compose(255,192,192)) to liColor1
        else move (RGB_Compose(255,255,255)) to liColor1
        move liColor1 to liColor2

        ifnot liRec1 begin
          move clBtnFace to liColor1
          move (RGB_Compose(255,255,255)) to liColor2
        end
        ifnot liRec2 begin
          move (RGB_Compose(255,255,255)) to liColor1
          move clBtnFace to liColor2
        end

        set ItemColor (liBase+1) to liColor1
        set ItemColor (liBase+2) to liColor2
      end_procedure

      procedure display_values
        send Grid_RowCallBackAll self MSG_DisplayRow self
      end_procedure

    end_object // oValueGrid

    procedure run_compare
      integer liTable liIndex lhComp liCount
      string lsIndex
      get phComparer to lhComp
      set value of oTable1 to (psTable1(lhComp))
      set value of oTable2 to (psTable2(lhComp))

      get piTable1 of lhComp to liTable
      get piIndex of lhComp to liIndex

      set value of oIndex to (piIndex(phComparer(self)))
      get FDX_IndexAsFieldNames 0 liTable liIndex 0 to lsIndex
      set value of oIndex to lsIndex

      get_attribute DF_FILE_RECORDS_USED of liTable to liCount
      set value of oRecords1 to liCount

      get piTable2 of lhComp to liTable
      get_attribute DF_FILE_RECORDS_USED of liTable to liCount
      set value of oRecords2 to liCount

      send run_table_comparison of (phComparer(self))

      send fill_field_labels of oValueGrid
      send fill_list of oResultGrid
    end_procedure

    object oBtn1 is a aps.Multi_Button
      set size to 14 100
      on_item "Create missing records" send CreateMissingRecords of oResultGrid
      set peAnchors to (anRight+anBottom)
    end_object
    object oBtn2 is a aps.Multi_Button
      on_item "Close" send close_panel
      set peAnchors to (anRight+anBottom)
    end_object
    send aps_locate_multi_buttons

    procedure UpdateValueGrid
      integer liCompMode
      send display_values of oValueGrid
      get piCompMode of (phComparer(self)) to liCompMode
      set enabled_state of oBtn1 to (liCompMode=CTP_TABLE1_MISSING or liCompMode=CTP_TABLE2_MISSING)
    end_procedure

    procedure aps_beautify
    end_procedure

    procedure Close_Panel // Release when closed!
      Forward Send Close_Panel
      send CloseTables of (phComparer(self))
      send destroy of (phComparer(self))
      send Deferred_Request_Destroy_Object
    end_procedure

    move self to OG_Current_Object# // global integer
  end_object
  send aps_SetMinimumDialogSize OG_Current_Object# // Set minimum size
END_DEFINE_OBJECT_GROUP // OG_CompareTableDataView

procedure Activate_CompareTables
  boolean lbContinue
  integer lhComparer

  // Create a comparer object:
  object oComparer is a cCompareTableData
    move self to lhComparer
  end_object

  get bPopup.i of oCompareTableData_Wiz lhComparer to lbContinue

  if lbContinue begin
    CREATE_OBJECT_GROUP OG_CompareTableDataView
    set phComparer of OG_Current_Object# to lhComparer
    send popup to OG_Current_Object#
    send run_compare of OG_Current_Object#
  end
  else begin
    send CloseTables of lhComparer
    send destroy of lhComparer
  end
end_procedure


