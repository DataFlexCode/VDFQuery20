// Use dfm_importexport.vw
use aps.pkg
Use Buttons.utl  // Button texts
Use ToolUtilities.pkg // aps.YellowBox class


Use strings.utl
Use Spec0012.utl // Read image to string (sTextDfFromImage function)
Use files.utl
use rgb.utl


Use strings.utl
Use files.utl
Use Spec0012.utl // Read image to string (sTextDfFromImage function)


use dfm_importexport.pkg

/DFM.ImportExportConfirmDescription
The tables in the list below will be processed. If a table displays "Map fields" in the status column it means that you are about to import data to a table that are not compatible in terms of columns sequence. You must then point to the table and click the "Map fields" button. You can not confirm the operation until all tables have a "Ready" in the status column.
/*


object oDFM_ImportExport_Confirm is a aps.ModalPanel label "Dump/LoadData - Confirm"
  set Border_Style to BORDER_THICK   // Make panel resizeable
  property integer piResult
  on_key ksave_record send close_panel_ok
  on_key kcancel send close_panel
  property integer pbNoShowStoppers
  object oEdit is a aps.YellowBox
    set peAnchors to (anTop+anLeft+anRight)
    set size to 30 415
    set piTextSourceImage to DFM.ImportExportConfirmDescription.N
  end_object
  send aps_goto_max_row
  object oGrid is a aps.Grid
    set peAnchors to (anTop+anLeft+anRight+anBottom)
    set peResizeColumn to rcAll
    set size to 100 0
    send GridPrepare_AddColumn "#"            AFT_NUMERIC4.0
    send GridPrepare_AddColumn "Table"        AFT_ASCII12
    send GridPrepare_AddColumn "Display name" AFT_ASCII32
    send GridPrepare_AddColumn "Recs table"   AFT_NUMERIC8.0
    send GridPrepare_AddColumn "Recs in file" AFT_NUMERIC8.0
    send GridPrepare_AddColumn "Status"       AFT_ASCII10
    send GridPrepare_Apply self
    set select_mode to NO_SELECT

    procedure row_change integer liRowFrom integer liRowTo
      if (item_count(self)) send NowOnRow liRowTo
    end_procedure
    procedure item_change integer liItm1 integer liItm2 returns integer
      integer liRval liColumns
      get Grid_Columns self to liColumns
      forward get msg_item_change liItm1 liItm2 to liRval
      if (liItm1/liColumns) ne (liItm2/liColumns) send row_change (liItm1/liColumns) (liItm2/liColumns)
      procedure_return liRval
    end_procedure

    function sStatusText.i integer liRow returns string
      integer lhControl lbExport lbErase lbImport lbMappingSpecified lhArr
      string lsStatus
      get object_id of DFM_IE_ControlBlock to lhControl
      get pbExport of lhControl to lbExport
      get pbErase  of lhControl to lbErase
      get pbImport of lhControl to lbImport

      get object_id of DFM_IE_WorkHorse to lhArr
      if (piCanOpen.i(lhArr,liRow)) begin
        if lbImport begin
          get bMappingSpecified.i of lhArr liRow to lbMappingSpecified
          if lbExport move "Ready" to lsStatus
          else begin
            ifnot (pbImportFileFound.i(lhArr,liRow)) move "No file" to lsStatus
            else if (pbDefinitionMatch.i(lhArr,liRow)) move "Ready" to lsStatus
            else begin
              if lbMappingSpecified move "Ready" to lsStatus
              else move "Map fields" to lsStatus
            end
          end
        end
        else move "Ready" to lsStatus
        if lbMappingSpecified move (lsStatus+" (M)") to lsStatus
      end
      else move "No table" to lsStatus
      function_return lsStatus
    end_function

    procedure fill_list
      integer lhControl lbExport lbErase lbImport
      integer lhArr liMax liRow liBase liFile lbMappingSpecified
      string lsDisplayName lsStatus

      get object_id of DFM_IE_ControlBlock to lhControl
      get pbExport of lhControl to lbExport
      get pbErase  of lhControl to lbErase
      get pbImport of lhControl to lbImport

      set dynamic_update_state to DFFALSE
      send delete_data
      get object_id of DFM_IE_WorkHorse to lhArr
      get row_count of lhArr to liMax
      decrement liMax
      for liRow from 0 to liMax
        get item_count to liBase

        get piFile.i of lhArr liRow to liFile
        get API_AttrValue_FILELIST DF_FILE_DISPLAY_NAME liFile to lsDisplayName

        send add_item MSG_NONE liFile
        set aux_value item liBase to liRow

        send add_item MSG_NONE (psRootOfRoot.i(lhArr,liRow))
        send add_item MSG_NONE lsDisplayName

        if (piCanOpen.i(lhArr,liRow)) begin

          send add_item MSG_NONE (piTableRecordCount.i(lhArr,liRow))
          if lbImport begin
            if lbExport send add_item MSG_NONE (piTableRecordCount.i(lhArr,liRow))
            else        send add_item MSG_NONE (piFileRecordCount.i(lhArr,liRow))
          end
          else send add_item MSG_NONE ""

          if lbImport begin
            if lbExport move "Ready" to lsStatus
            else begin
              ifnot (pbImportFileFound.i(lhArr,liRow)) begin
                move "No file" to lsStatus
                set pbNoShowStoppers to false
              end
              else if (pbDefinitionMatch.i(lhArr,liRow)) move "Ready" to lsStatus
              else begin
                get bMappingSpecified.i of lhArr liRow to lbMappingSpecified
                if lbMappingSpecified move "Ready" to lsStatus
                else move "Map fields" to lsStatus
              end
            end
          end
          else move "Ready" to lsStatus
          send add_item MSG_NONE (sStatusText.i(self,liRow)) //lsStatus
        end
        else begin
          send add_item MSG_NONE "" // Reccount 1
          send add_item MSG_NONE "" // Reccount 2
          send add_item MSG_NONE "No table"
          set pbNoShowStoppers to false
        end
      loop
      send Grid_SetEntryState self DFFALSE
      set dynamic_update_state to DFTRUE
    end_procedure

    procedure DoFieldMapping
      integer lhArr liRow liBase
      get Grid_BaseItem self to liBase
      get aux_value item liBase to liRow
      get object_id of DFM_IE_WorkHorse to lhArr
      send DoFieldMapperDialog of lhArr liRow
      set value item (liBase+5) to (sStatusText.i(self,liRow))
    end_procedure

  end_object
  procedure close_panel_ok
    set piResult to true
    send close_panel
  end_procedure
  object oBtn1 is a aps.Multi_Button
    on_item "OK" send close_panel_ok
    set peAnchors to (anBottom+anRight)
  end_object
  object oMapFieldsBtn is a aps.Multi_Button
    on_item "Map fields" send DoFieldMapping of oGrid
    set peAnchors to (anBottom+anRight)
  end_object
  object oBtn3 is a aps.Multi_Button
    on_item "Cancel" send close_panel
    set peAnchors to (anBottom+anRight)
  end_object

  procedure NowOnRow integer liRow
    integer lbOkToMap
    get bCanMapFields of DFM_IE_WorkHorse liRow to lbOkToMap
    set enabled_state of oMapFieldsBtn to lbOkToMap
  end_procedure

  send aps_locate_multi_buttons
  function iPopup returns integer
    integer lhControl lbExport lbErase lbImport
    string lsLabel
    get object_id of DFM_IE_ControlBlock to lhControl
    get pbExport of lhControl to lbExport
    get pbErase  of lhControl to lbErase
    get pbImport of lhControl to lbImport

    move "" to lsLabel
    if lbExport move (lsLabel+" Dump ") to lsLabel
    if lbErase  move (lsLabel+" Erase ") to lsLabel
    if lbImport move (lsLabel+" Load ") to lsLabel
    move ("Confirm "+trim(replaces("  ",lsLabel,", "))) to lsLabel
    set label to lsLabel

    set piResult to false
    set pbNoShowStoppers to true
    send fill_list of oGrid
    send NowOnRow 0
    set enabled_state of oBtn1 to (pbNoShowStoppers(self))
//    set enabled_state of oBtn2 to lbImport

    send popup
    function_return (piResult(self))
  end_procedure
end_object // oDFM_ImportExport_Confirm
send aps_SetMinimumDialogSize (oDFM_ImportExport_Confirm(self))


/DFM.ImportExportDescription
This function lets you dump, erase or load table data as selected in the table selector. You may perform more functions in one go.

When dumping data a copy of the table definition is stored as part of the header of the ascii file. This is used for reference when the file is later loaded. Tables remain locked during load.

The checkbox labelled "Maintain compatibility..." determines if ASCII fields that contains non-ASCII characters can be handelled safely by the routines. While this is an error condition it still can happen in real life.
/*

Activate_View Activate_ImportExport_View for oDFM_ImportExport_View
object oDFM_ImportExport_View is a aps.View label "Dump/Load Data"
  on_key kcancel send close_panel
  on_key ksave_record send DoRun
  property integer piResult DFFALSE
  object oEdit is a aps.YellowBox
    set peAnchors to (anTop+anLeft+anRight+anBottom)
    Set size to 80 310
    set piTextSourceImage to DFM.ImportExportDescription.N
  end_object
  send aps_goto_max_row
  send aps_make_row_space 5
  send tab_column_define 1 20 15 JMODE_LEFT // Default column setting
  set p_auto_column to 1
  object oExportCb is a aps.CheckBox label "Dump table data to files named implicitly as the tables themselves (but with ext. 'dmp')"
    procedure OnChange
      send UpdateShadowStates
    end_procedure
  end_object
  object oEraseCb is a aps.CheckBox label "Erase data from the table (requires exclusive access to the tables)"
    procedure OnChange
      send UpdateShadowStates
    end_procedure
  end_object
  object oImportCb is a aps.CheckBox label "Load table data (if formats are not compatible you will be prompted to map the fields)"
    procedure OnChange
      send UpdateShadowStates
    end_procedure
  end_object
  send aps_goto_max_row
  send aps_make_row_space 5
  object oPauseOnErrorsCb is a aps.CheckBox label "Pause on errors (when loading data)"
  end_object
  set p_auto_column to 0
  send aps_goto_max_row
  send aps_make_row_space 5
  object oDirectory is a aps.SelectDirForm label "Use this folder for dump/load files:" abstract AFT_ASCII255
    set p_extra_internal_width to -1080
  end_object
  set p_auto_column to 1
  send aps_goto_max_row
  send aps_make_row_space 5
  object oNotProtectAscFieldsCb is a aps.CheckBox label "Maintain compability with older versions of DFMatrix (before 2008)"
  end_object

  procedure DoRun
    integer lhControl lbContinue
    integer lbExport lbErase lbImport liCreate liError
    Boolean lbNotProtectAscFieldsCb
    string lsFolder
    get checked_state of oExportCb to lbExport
    get checked_state of oEraseCb  to lbErase
    get checked_state of oImportCb to lbImport
    get checked_state of oNotProtectAscFieldsCb to lbNotProtectAscFieldsCb
    get value of oDirectory to lsFolder

    if (DFM_IE_GetListOfFiles()) begin
      if (lbExport or lbErase or lbImport) begin
        if (lbImport and not(lbExport)) get SEQ_ValidateFolder lsFolder VALIDFOLDER_CREATE_FALSE 0 to liError
        if lbExport get SEQ_ValidateFolder lsFolder VALIDFOLDER_CREATE_PROMPT 0 to liError

        ifnot liError begin
          get object_id of DFM_IE_ControlBlock to lhControl
          set pbExport of lhControl to lbExport
          set pbErase  of lhControl to lbErase
          set pbImport of lhControl to lbImport
          set psFolder of lhControl to lsFolder
          Set pbProtectAsciiFields of lhControl to (not(lbNotProtectAscFieldsCb))

          send cursor_wait to (cursor_control(self))
          send DFM_IE_ValidateFunction
          send cursor_ready to (cursor_control(self))

          get iPopup of oDFM_ImportExport_Confirm to lbContinue
          if lbContinue begin
            send close_panel
            send DFM_IE_ExecuteFunctions
          end
        end
      end
      else send obs "No functions selected"
    end
    else send obs "No tables selected"
  end_procedure

  procedure UpdateShadowStates
    integer lbExport lbErase lbImport
    get checked_state of oExportCb to lbExport
    get checked_state of oEraseCb  to lbErase
    get checked_state of oImportCb to lbImport
    set enabled_state of oDirectory to (lbExport or lbImport)
    set enabled_state of oPauseOnErrorsCb to lbImport
    set enabled_state of oNotProtectAscFieldsCb to lbExport
  end_procedure

  object oBtn1 is a aps.Multi_Button
    on_item "OK" send DoRun
    set peAnchors to (anBottom+anRight)
  end_object
  object oBtn2 is a aps.Multi_Button
    on_item "Cancel" send close_panel
    set peAnchors to (anBottom+anRight)
  end_object
  send aps_locate_multi_buttons

  procedure OnChangeFDX_Broadcasted // Sent by DFM
    set delegation_mode to DELEGATE_TO_PARENT
    send close_panel
  end_procedure
  procedure Close_Query_View // Sent by FastView
    set delegation_mode to DELEGATE_TO_PARENT
    send close_panel
  end_procedure

  procedure popup
    integer lhControl
    if (DFMatrix_RealData_Check()) begin
      get object_id of DFM_IE_ControlBlock to lhControl
      ifnot (active_state(self)) begin
        set checked_state of oExportCb to (pbExport(lhControl))
        set checked_state of oEraseCb  to (pbErase(lhControl))
        set checked_state of oImportCb to (pbImport(lhControl))
        set value of oDirectory        to (psFolder(lhControl))
        set checked_state of oNotProtectAscFieldsCb to (not(pbProtectAsciiFields(lhControl)))
      end
      send UpdateShadowStates
      forward send popup
    end
  end_procedure
end_object // oDFM_ImportExport_View
//send popup of oDFM_ImportExport_View

