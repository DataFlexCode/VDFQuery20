// Use StrucPgm.vw  // View for creating and executing RS programs
Use StrucPgm.utl // Class for storing a sequence of restructure instructions
Use FdxCompa.nui // Class for comparing table definitions
Use StrucPgm.pkg // Display restructure program (procedure StructPgm_Display)
Use StrucTrc.utl // Object for tracing a restructure operation
Use LogFile.pkg  // Object for specifying log file properties
Use Spec0007.utl // Display modal text (DoDisplayText)
Use WildCard.nui // vdfq_WildCardMatch function
Use Files.utl    // Utilities for handling file related stuff
Use api_attr.pkg // UI objects for use with API_Attr.utl R

desktop_section
  object oFdxRestructureProgramArray_StrucPgm is a cFdxRestructureProgramArray
    procedure save_browse
      integer liChannel row# max# obj#
      string fn#
      get row_count to max#
      if max# begin
        move (SEQ_SelectOutFile("Restructure Program File destination (*.rpf)","Restructure program file|*.rpf")) to fn#
        if fn# ne "" begin
          move (SEQ_DirectOutput(fn#)) to liChannel
          if liChannel ge 0 begin
            for row# from 0 to (max#-1)
              writeln channel liChannel (piFile.i(self,row#))
              writeln (psRootName.i(self,row#))
              get piObject.i row# to obj#
              send Seq_Write to obj# liChannel
            loop
            send SEQ_CloseOutput liChannel
          end
        end
      end
    end_procedure
    procedure open_browse
      integer fin# obj# file# row# liChannel
      string fn#
      move (SEQ_SelectFile("Select Restructure Program File (*.rpf)","Restructure program file|*.rpf")) to fn#
      if fn# ne "" begin
        move (SEQ_DirectInput(fn#)) to liChannel
        if liChannel ge 0 begin
          send reset
          repeat
            move (SEQ_ReadLn(liChannel)) to file#
            move (seqeof) to fin#
            ifnot fin# begin
              get row_count to row#
              set piFile.i row# to file#
              set psRootName.i row# to (SEQ_ReadLn(liChannel))
              get iCreateFdxRestructureProgram to obj#
              set piObject.i row# to obj#
              send Seq_Read to obj# liChannel
            end
          until fin#
          send SEQ_CloseInput liChannel
        end
      end
    end_procedure
  end_object // oFdxRestructureProgramArray_StrucPgm
end_desktop_section

// NEWTHING
class cNewMaxRecordsList is a aps.Grid
  procedure construct_object integer liImage
    forward send construct_object liImage
    send GridPrepare_AddColumn ""             AFT_ASCII3
    send GridPrepare_AddColumn "#"            AFT_ASCII4
    send GridPrepare_AddColumn "Root name"    AFT_ASCII15
    send GridPrepare_AddColumn "Display name" AFT_ASCII25
    send GridPrepare_AddColumn "Max recs"     AFT_NUMERIC8.0
    send GridPrepare_AddColumn "Cur recs"     AFT_NUMERIC8.0
    send GridPrepare_AddColumn "Pct full"     AFT_NUMERIC4.0
    send GridPrepare_AddColumn "New max"      AFT_NUMERIC8.0
    send GridPrepare_Apply self
    set select_mode to MULTI_SELECT
    on_key kenter send next
    on_key key_ctrl+key_r send sort_data
    on_key knext_item send increment_item
    on_key kprevious_item send decrement_item
    on_key kswitch send switch
    on_key kswitch_back send switch_back
  end_procedure
  procedure decrement_item
    integer liCurrentItem
    get current_item to liCurrentItem
    decrement liCurrentItem
    if liCurrentItem ge 0 set current_item to liCurrentItem
    else send switch_back
  end_procedure
  procedure increment_item
    integer liCurrentItem
    get current_item to liCurrentItem
    increment liCurrentItem
    if liCurrentItem le (item_count(self)-1) set current_item to liCurrentItem
    else send switch
  end_procedure
  function iSpecialSortValueOnColumn.i integer liColumn returns integer
    if liColumn eq 2 function_return 0
    if liColumn eq 3 function_return 0
    function_return 1
  end_function
  function sSortValue.ii integer liColumn integer liItm returns string
    if liColumn eq 0 function_return (not(select_state(self,liItm)))
    if liColumn eq 6 function_return (IntToStrR(1000-integer(value(self,liItm)),10))
    function_return (IntToStrR(value(self,liItm),10))
  end_function
  procedure sort_data.i integer liColumn
    send Grid_SortByColumn self liColumn
  end_procedure
  procedure sort_data
    integer liCurrentColumn
    get Grid_CurrentColumn self to liCurrentColumn
    send sort_data.i liCurrentColumn
  end_procedure
  procedure header_mouse_click integer liItm
    send sort_data.i liItm
    forward send header_mouse_click liItm
  end_procedure
  procedure select_toggling integer liItm integer liValue
    integer liBase lbState liNewMaxRec NewMaxliItm
    move (Grid_BaseItem(self)) to liBase
    move (liBase+7) to NewMaxliItm
    forward send select_toggling liBase liValue // Redirect to first column
    get select_state item liBase to lbState
    set entry_state item NewMaxliItm to lbState
    if lbState begin
      set current_item to NewMaxliItm
      get aux_value item NewMaxliItm to liNewMaxRec
      ifnot liNewMaxRec begin
        get value item (liBase+5) to liNewMaxRec
        move (integer(value(self,liBase+4)) max liNewMaxRec) to liNewMaxRec
      end
      set value item NewMaxliItm to liNewMaxRec
    end
    else begin
      set aux_value item NewMaxliItm to (value(self,NewMaxliItm))
      set value item NewMaxliItm to ""
    end
  end_procedure
  procedure fill_list.i integer lhFdx
    integer liRow liFile liBase liMaxRecs liUsedRecs liPct
    send delete_data
    move 0 to liFile
    repeat
      move (FDX_AttrValue_FLSTNAV(lhFdx,DF_FILE_NEXT_USED,liFile)) to liFile
      if liFile begin
        // Only if DataFlex file and only if it has indices defined:
        if (FDX_AttrValue_FILE(lhFdx,DF_FILE_DRIVER,liFile)="DATAFLEX" and integer(FDX_AttrValue_FILE(lhFdx,DF_FILE_LAST_INDEX_NUMBER,liFile))<>0 and not(integer(FDX_AttrValue_FILE(lhFdx,DF_FILE_IS_SYSTEM_FILE,liFile)))) begin
          get item_count to liBase
          send add_item msg_none ""
          set checkbox_item_state item liBase to DFTRUE
          send add_item msg_none liFile
          send add_item msg_none (FDX_AttrValue_FILELIST(lhFdx,DF_FILE_ROOT_NAME,liFile))
          send add_item msg_none (FDX_AttrValue_FILELIST(lhFdx,DF_FILE_DISPLAY_NAME,liFile))
          move (FDX_AttrValue_FILE(lhFdx,DF_FILE_MAX_RECORDS,liFile))  to liMaxRecs
          move (FDX_AttrValue_FILE(lhFdx,DF_FILE_RECORDS_USED,liFile)) to liUsedRecs
          send add_item msg_none liMaxRecs
          send add_item msg_none liUsedRecs
          move (liUsedRecs*100.0/liMaxRecs) to liPct
          if liPct gt 999 move 999 to liPct
          send add_item msg_none liPct
          send add_item msg_none ""
        end
      end
    until liFile eq 0
    send Grid_SetEntryState self DFFALSE
    send sort_data.i 6
    set current_item to 0
    set dynamic_update_state to DFTRUE
  end_procedure
  procedure Callback_ModifiedEntries integer msg# integer obj#
    integer liRow liMax liNewMax liBase liFile
    string root#
    get Grid_RowCount self to liMax
    for liRow from 0 to (liMax-1)
      get Grid_RowBaseItem self liRow to liBase
      if (select_state(self,liBase)) begin
        get value item (liBase+1) to liFile
        get value item (liBase+2) to root#
        get value item (liBase+7) to liNewMax
        send msg# to obj# liFile root# liNewMax
      end
    loop
  end_procedure
  procedure AutoSetParameters integer liMinPctFree integer liNewPctFree
    integer liRow liMax liNewMax liBase liPctFull liCurRecs
    if (liNewPctFree>liMinPctFree and liNewPctFree<=90) begin // Only if there's a point
      get Grid_RowCount self to liMax
      for liRow from 0 to (liMax-1)
        get Grid_RowBaseItem self liRow to liBase
        ifnot (select_state(self,liBase)) begin // Only the ones that are not already modified
          get value item (liBase+6) to liPctFull
          if ((100-liPctFull)<liMinPctFree) begin
            set select_state item liBase to true
            get value item (liBase+5) to liCurRecs
            move (liCurRecs*100.0/(100-liNewPctFree)) to liNewMax
            if (liNewMax>16711679) move 16711679 to liNewMax // dffile of 3.2 says this is maximum
            set value item (liBase+7) to liNewMax
          end
        end
      loop
    end
  end_procedure
end_class // cNewMaxRecordsList

Use APS.pkg      // Auto Positioning and Sizing classes for VDF
Use Buttons.utl  // Button texts
object oNewMaxRecords is a aps.ModalPanel label "Set new maximum number of records (indexed DataFlex tables only)"
  set locate_mode to CENTER_ON_SCREEN
  on_key ksave_record send close_panel_ok
  on_key kcancel send close_panel
  set pMinimumSize to 200 0
  property integer piResult 0
  object oLst is a cNewMaxRecordsList
    set size to 200 0
  end_object
  object oBtn1 is a aps.Multi_Button
    on_item t.btn.ok send close_panel_ok
  end_object
  object oBtn2 is a aps.Multi_Button
    on_item t.btn.cancel send close_panel
  end_object
  send aps_locate_multi_buttons
  procedure close_panel_ok
    set piResult to 1
    send close_panel
  end_procedure
  set Border_Style to BORDER_THICK   // Make panel resizeable
  procedure aps_onResize integer delta_rw# integer delta_cl#
    send aps_resize (oLst(self)) delta_rw# 0 // delta_cl#
    send aps_register_multi_button (oBtn1(self))
    send aps_register_multi_button (oBtn2(self))
    send aps_locate_multi_buttons
    send aps_auto_size_container
  end_procedure
  function iPopup returns integer
    set piResult to 0
    send fill_list.i to (oLst(self)) (fdx.object_id(0))
    send popup
    function_return (piResult(self))
  end_procedure
  procedure AutoSetParameters integer liMinPct integer liNewPct
    send AutoSetParameters to (oLst(self)) liMinPct liNewPct
  end_procedure
  procedure precond_setup
    send fill_list.i to (oLst(self)) (fdx.object_id(0))
  end_procedure
end_object // oNewMaxRecords

Use APS.pkg      // Auto Positioning and Sizing classes for VDF
Use Buttons.utl  // Button texts
object oRestructFilterPn is a aps.ModalPanel label "Filter parameters"
  set locate_mode to CENTER_ON_SCREEN
  on_key ksave_record send close_panel_ok
  on_key kcancel send close_panel
  send tab_column_define 1 30 25 jmode_left
  set p_auto_column to 1
  on_key key_ctrl+key_a send select_all
  property integer piResult 0
  object oCb1 is a aps.CheckBox label "Ignore Display Name"
  end_object
  object oCb2 is a aps.CheckBox label "Ignore Max Records"
  end_object
  object oCb3 is a aps.CheckBox label "Ignore Compression"
  end_object
  object oCb4 is a aps.CheckBox label "Ignore Integrity Check"
  end_object
  object oCb5 is a aps.CheckBox label "Ignore Lock Type"
  end_object
  object oCb6 is a aps.CheckBox label "Ignore Multi User"
  end_object
  object oCb7 is a aps.CheckBox label "Ignore Reuse Deleted"
  end_object
  object oCb8 is a aps.CheckBox label "Ignore Transaction setting"
  end_object
  object oCb9 is a aps.CheckBox label "Ignore Root name"
  end_object
  object oCb10 is a aps.CheckBox label "Ignore Record Length"
  end_object
  object oCb11 is a aps.CheckBox label "Ignore Record Identity"
  end_object
  procedure select_all
    integer lbState
    get checked_state of (oCb1(self)) to lbState
    move (not(lbState)) to lbState
    set checked_state of (oCb1(self)) to lbState
    set checked_state of (oCb2(self)) to lbState
    set checked_state of (oCb3(self)) to lbState
    set checked_state of (oCb4(self)) to lbState
    set checked_state of (oCb5(self)) to lbState
    set checked_state of (oCb6(self)) to lbState
    set checked_state of (oCb7(self)) to lbState
    set checked_state of (oCb8(self)) to lbState
    set checked_state of (oCb9(self)) to lbState
    set checked_state of (oCb10(self)) to lbState
    set checked_state of (oCb11(self)) to lbState
  end_procedure
  object oBtn1 is a aps.Multi_Button
    on_item t.btn.ok send close_panel_ok
  end_object
  object oBtn2 is a aps.Multi_Button
    on_item t.btn.cancel send close_panel
  end_object
  send aps_locate_multi_buttons
  procedure close_panel_ok
    set piResult to 1
    send close_panel
  end_procedure
  procedure popup
    integer lhObj
    move (oFdxTableCompare(self)) to lhObj
    set piResult to 0
    set checked_state of (oCb1(self)) to (piIgnore_DisplayName(lhObj))
    set checked_state of (oCb2(self)) to (piIgnore_MaxRecords(lhObj))
    set checked_state of (oCb3(self)) to (piIgnore_Compression(lhObj))
    set checked_state of (oCb4(self)) to (piIgnore_IntegrityCheck(lhObj))
    set checked_state of (oCb5(self)) to (piIgnore_LockType(lhObj))
    set checked_state of (oCb6(self)) to (piIgnore_MultiUser(lhObj))
    set checked_state of (oCb7(self)) to (piIgnore_ReuseDeleted(lhObj))
    set checked_state of (oCb8(self)) to (piIgnore_TransactionSetting(lhObj))
    set checked_state of (oCb9(self)) to (piIgnore_RootName(lhObj))
    set checked_state of (oCb10(self)) to (piIgnore_RecordLength(lhObj))
    set checked_state of (oCb11(self)) to (piIgnore_RecordIdentity(lhObj))
    forward send popup
    if (piResult(self)) begin
      set piIgnore_DisplayName        of lhObj to (checked_state(oCb1(self)))
      set piIgnore_MaxRecords         of lhObj to (checked_state(oCb2(self)))
      set piIgnore_Compression        of lhObj to (checked_state(oCb3(self)))
      set piIgnore_IntegrityCheck     of lhObj to (checked_state(oCb4(self)))
      set piIgnore_LockType           of lhObj to (checked_state(oCb5(self)))
      set piIgnore_MultiUser          of lhObj to (checked_state(oCb6(self)))
      set piIgnore_ReuseDeleted       of lhObj to (checked_state(oCb7(self)))
      set piIgnore_TransactionSetting of lhObj to (checked_state(oCb8(self)))
      set piIgnore_Rootname           of lhObj to (checked_state(oCb9(self)))
      set piIgnore_RecordLength       of lhObj to (checked_state(oCb10(self)))
      set piIgnore_RecordIdentity     of lhObj to (checked_state(oCb11(self)))
    end
  end_procedure
end_object // oRestructFilterPn

class StrucPgmFdxList is a aps.Grid
  procedure construct_object integer liImage
    forward send construct_object liImage
    property integer piFDX_Server 0
    property integer prv.GenerateChangeEvent 1
    set highlight_row_state to DFTRUE
    on_key key_ctrl+key_d send display_file_things
    set line_width to 2 0
    set header_visible_state to false
    set gridline_mode to GRID_VISIBLE_NONE
    set form_margin item 0 to  4   //
    set form_margin item 1 to  40  //
    set highlight_row_state to true
    set highlight_row_color to (rgb(0,255,255))
    set current_item_color to (rgb(0,255,255))
    set select_mode to no_select
    on_key knext_item send switch
    on_key kprevious_item send switch_back
  end_procedure
  function iCurrentFile returns integer
    integer liBase
    move ((current_item(self)/2)*2) to liBase
    if (item_count(self)) function_return (value(self,liBase))
    function_return 0
  end_function
  procedure display_file_things
    send FDX_ModalDisplayFileAttributes (piFDX_Server(self)) (iCurrentFile(self))
  end_procedure
  procedure fill_list.i integer lhFdx
    integer liFile liMax liItm
    set piFDX_Server to lhFdx
    send delete_data
    move 0 to liFile
    repeat
      move (FDX_AttrValue_FLSTNAV(lhFdx,DF_FILE_NEXT_USED,liFile)) to liFile
      if liFile begin
        send add_item msg_none liFile
        send add_item msg_none (FDX_AttrValue_FILELIST(lhFdx,DF_FILE_DISPLAY_NAME,liFile))
      end
    until liFile eq 0
    set dynamic_update_state to true
    get item_count to liMax
    for liItm from 0 to (liMax-1)
      set entry_state item liItm to false
    loop
  end_procedure
  procedure DoGotoFile integer liFile
    integer liItm liMax
    get item_count to liMax
    move 0 to liItm
    while (liItm<liMax)
      if liFile eq (integer(value(self,liItm))) set current_item to liItm
      move (liItm+2) to liItm
    end
  end_procedure
  procedure DoGotoFilelistEntry string lsRootName string lsLogicalName
    integer liFile lhFdx
    get piFDX_Server to lhFdx
    if lhFdx begin
      get iFindLogicalName.si of lhFdx lsLogicalName 0 to liFile
      ifnot liFile get iFindRootName.sii of lhFdx lsRootName 0 0 to liFile
      ifnot liFile get iFindRootName.sii of lhFdx lsRootName 0 1 to liFile
      if liFile send DoGotoFile liFile
    end
  end_procedure
  procedure OnFilelistEntry string lsRootName string lsLogicalName
  end_procedure
  procedure item_change integer liFrom integer liTo returns integer
    integer liRval liFile
    forward get msg_item_change liFrom liTo to liRval
    if (item_count(self) and prv.GenerateChangeEvent(self)) begin
      set prv.GenerateChangeEvent to 0
      move (value(self,(liRval/2)*2)) to liFile
      send OnFilelistEntry (AttrValue_FILELIST(piFDX_Server(self),DF_FILE_ROOT_NAME,liFile)) (AttrValue_FILELIST(piFDX_Server(self),DF_FILE_LOGICAL_NAME,liFile))
      set prv.GenerateChangeEvent to 1
    end
    procedure_return liRval
  end_procedure
end_class // StrucPgmFdxList

register_object oLst1
register_object oLst2
class cFdxCompareDefinitions_Pn is a aps.ModalPanel
  procedure construct_object integer liImage
    forward send construct_object liImage
    object oArray is a cArray
    end_object
  end_procedure
  procedure DoLoadCurrent
    send DFMatrix_SecondaryOpenCurrentFilelist
    send DisplayHeaders
    send fill_list.i to (oLst2(self)) (fdx.object_id(1))
    send activate to (oLst2(self))
  end_procedure
  procedure DoLoadFile
    if (DFMatrix_SecondaryOpenFdxFile()) begin
      send DisplayHeaders
      send fill_list.i to (oLst2(self)) (fdx.object_id(1))
      send activate to (oLst2(self))
    end
  end_procedure
  procedure compare_definitions integer liFile1 integer liFile2 integer liCompareMode
    integer lhFDX1 lhFDX2 lhProgArray liPgmRow lhPgm lbCreate
    string lsRoot

    move (oFDXRestructureProgramArray_StrucPgm(self)) to lhProgArray

    move (fdx.object_id(0)) to lhFDX1
    move (fdx.object_id(1)) to lhFDX2

    move (not(iCanOpen.i(lhFDX1,liFile1))) to lbCreate

    if lbCreate move (AttrValue_FILELIST(lhFDX2,DF_FILE_ROOT_NAME,liFile2)) to lsRoot
    else        move (AttrValue_FILELIST(lhFDX1,DF_FILE_ROOT_NAME,liFile1)) to lsRoot

    // Do the comparison (thereby creating a pgm object):
    move (iFdxCompareTables.iiiiii(0,lhFDX1,liFile1,lhFDX2,liFile2,liCompareMode)) to lhPgm

    if (piProgramType(lhPgm)<>PGM_TYPE_EMPTY) begin

      // Is there such a program already?
      uppercase lsRoot
      move (iFindPgmRow.is(lhProgArray,liFile1,lsRoot)) to liPgmRow
      if liPgmRow ne -1 send reset.i to lhProgArray liPgmRow // If so, reset it
      else get iAddPgmRow.is of lhProgArray liFile1 lsRoot to liPgmRow // If not, create it

      set piObject.i of lhProgArray liPgmRow to lhPgm
    end
    else send request_destroy_object to lhPgm
  end_procedure
  procedure DoFilter
    send popup to (oRestructFilterPn(self))
  end_procedure
  procedure DoOne
    integer file1# file2# oFDX1# oFDX2#
    move (fdx.object_id(0)) to oFDX1#
    move (fdx.object_id(1)) to oFDX2#
    if (piDataOrigin(oFDX1#)<>FDX_EMPTY and piDataOrigin(oFDX2#)<>FDX_EMPTY) begin
      get iCurrentFile of (oLst1(self)) to file1#
      get iCurrentFile of (oLst2(self)) to file2#
      if (file1# or file2#) begin
        if file1# eq 0 move file2# to file1# // Create!
        send compare_definitions file1# file2# FDXCOMP_MODE_ALL
        send obs "Comparison done"
      end
    end
    else send obs "Can not compare with empty source or destination!"
  end_procedure
  procedure CheckFdnFile string lsFile string lsPath
    integer lhArray
    if (vdfq_WildCardMatch(lsFile)) begin
      move (oArray(self)) to lhArray
      set value of lhArray item (item_count(self)) to lsFile
    end
  end_procedure
  procedure DeleteFdnFile string lsFile string lsPath
    integer liGrb
    if (vdfq_WildCardMatch(lsFile)) begin
      get SEQ_ComposeAbsoluteFileName lsPath lsFile to lsFile
      get SEQ_EraseFile lsFile to liGrb
    end
  end_procedure
  procedure DoAll_CompareFieldNames
    integer max# liRow olst1# olst2# file1# file2# oFDX1# oFDX2# synch_state# liRval
    integer lbContinue
    string rn1# ln1# lsDir
    get synch_state to synch_state#
    set synch_state to 1
    move (oLst1(self)) to olst1#
    move (oLst2(self)) to olst2#
    move (fdx.object_id(0)) to oFDX1#
    move (fdx.object_id(1)) to oFDX2#
    if (piDataOrigin(oFDX1#)<>FDX_EMPTY and piDataOrigin(oFDX2#)<>FDX_EMPTY) begin
      // Do changes and drops:
      get SEQ_SelectDirectory "Directory in which to place the fdn files" to lsDir
      if (lsDir<>"") begin

        send SEQ_Load_ItemsInDir lsDir
        send delete_data to (oArray(self))
        send WildCardMatchPrepare "*.FDN"
        send SEQ_CallBack_ItemsInDir SEQCB_FILES_ONLY MSG_CheckFdnFile self
        if (item_count(oArray(self))) get MB_Verify4 "FDN files are already present in that directory." "" "Should we delete them before we continue?" "" DFFALSE to lbContinue
        else move DFTRUE to lbContinue

        if lbContinue begin
          move (item_count(oLst1#)/2) to max#
          for liRow from 0 to (max#-1)
            set current_item of olst1# to (liRow*2)
            get iCurrentFile of oLst1# to file1#
            if file1# ne 50 begin
              if (iCanOpen.i(oFDX1#,file1#) or file1#=0) begin
                move (AttrValue_FILELIST(oFDX1#,DF_FILE_ROOT_NAME,file1#)) to rn1#
                move (AttrValue_FILELIST(oFDX1#,DF_FILE_LOGICAL_NAME,file1#)) to ln1#
                get iFindLogicalName.si of oFDX2# ln1# 0 to file2#
                ifnot file2# get iFindRootName.sii of oFDX2# rn1# 0 0 to file2#
                ifnot file2# get iFindRootName.sii of oFDX2# rn1# 0 1 to file2#
                if (file2#<>0 and iCanOpen.i(oFDX2#,file2#)) begin
                  get Fdx_GenerateFieldNameChanges oFDX1# File1# oFDX2# File2# lsDir to liRval

                end
              end
            end
          loop
          procedure_return msg_ok
        end
      end
    end
    else send obs "Can not compare with empty source or destination!"
  end_procedure
  procedure DoAll
    integer liMax liRow lhLst1 lhLst2 liFile1 liFile2 lhFDX1 lhFDX2 lbSynch
    integer lbOldStrategy liTestFile lbFirstTime lbDrop lbCanOpen2
    string lsRoot1 lsLogic1 lsRoot2
    get synch_state to lbSynch
    set synch_state to 1
    move (oLst1(self)) to lhLst1
    move (oLst2(self)) to lhLst2
    move (fdx.object_id(0)) to lhFDX1
    move (fdx.object_id(1)) to lhFDX2
    if (piDataOrigin(lhFDX1)<>FDX_EMPTY and piDataOrigin(lhFDX2)<>FDX_EMPTY) begin // Neither list can be empty!
      // Do changes and drops:
      move (item_count(lhLst1)/2) to liMax
      for liRow from 0 to (liMax-1) // Go through all the files in the <- list
        set current_item of lhLst1 to (liRow*2)
        get iCurrentFile of lhLst1 to liFile1
        if liFile1 ne 50 begin
          if (iCanOpen.i(lhFDX1,liFile1) or liFile1=0) begin
            move (AttrValue_FILELIST(lhFDX1,DF_FILE_ROOT_NAME,liFile1)) to lsRoot1
            move (AttrValue_FILELIST(lhFDX1,DF_FILE_LOGICAL_NAME,liFile1)) to lsLogic1

            // At this point we have the table number, root name and logical name of the table
            // we want to update.

            if 0 begin // Old strategy
              get iFindLogicalName.si of lhFDX2 lsLogic1 0 to liFile2
              ifnot liFile2 get iFindRootName.sii of lhFDX2 lsRoot1 0 0 to liFile2 // Start at entry 0, consider path and driver
              ifnot liFile2 get iFindRootName.sii of lhFDX2 lsRoot1 0 1 to liFile2 // Start at entry 0, do not consider path and driver
              if (iCanOpen.i(lhFDX2,liFile2) or liFile2=0) send compare_definitions liFile1 liFile2 FDXCOMP_MODE_ALL
            end
            else begin // New Strategy
              // First we figure out if we have already dealt with this table (as it could be an alias file)
              get iFindRootName.sii of lhFDX1 lsRoot1 0 1 to liTestFile // Start at entry 0, do not consider path and driver
              get iFindRootName.sii of lhFDX2 lsRoot1 0 1 to liFile2    // Start at entry 0, do not consider path and driver

              move (liTestFile=liFile1) to lbFirstTime
              move (not(liFile2))       to lbDrop

              if lbDrop begin
                send compare_definitions liFile1 0 FDXCOMP_MODE_ALL
              end
              else begin
                // Edited 19/10-2004 by Sture
                if lbFirstTime begin
                  get iCanOpen.i of lhFDX2 liFile2 to lbCanOpen2
                  if lbCanOpen2 send compare_definitions liFile1 liFile2 FDXCOMP_MODE_FILE // Compare table attributes only
                  send compare_definitions liFile1 liFile1 FDXCOMP_MODE_FILELIST // Compare filelist values only
                  //                            ������Compare the same entry at both sides
                end
                else begin
                  send compare_definitions liFile1 liFile1 FDXCOMP_MODE_FILELIST
                end
              end


            //if lbFirstTime begin
            //
            //end
            //else move 0 to lbDrop
            //
            //if (liTestFile<liFile1) begin // Physical definition has already been dealt with
            //  send compare_definitions liFile1 liFile1 FDXCOMP_MODE_FILELIST
            //end
            //else begin // Physical definition must be dealt with
            //  get iFindRootName.sii of lhFDX2 lsRoot1 0 1 to liFile2 // Start at entry 0, do not consider path and driver
            //  if (iCanOpen.i(lhFDX2,liFile2) or liFile2=0) send compare_definitions liFile1 liFile2 FDXCOMP_MODE_ALL
            //
            //end

            end
          end
        end
      loop

      // Do creates:
      set synch_state to 0
      move (item_count(lhLst2)/2) to liMax
      for liRow from 0 to (liMax-1)
        set current_item of lhLst2 to (liRow*2)
        get iCurrentFile of lhLst2 to liFile2

        if (iCanOpen.i(lhFDX2,liFile2) or liFile2=0) begin
          ifnot (iCanOpen.i(lhFDX1,liFile2)) begin
            if liFile2 ne 50 begin
              // Here we need to see if a table with that root name is already present
              // in the <- database. If this is the case we do not need to create the
              // table, only set the values in filelist.cfg
              move (AttrValue_FILELIST(lhFDX2,DF_FILE_ROOT_NAME,liFile2)) to lsRoot2 // Get the root name from reference
              get iFindRootName.sii of lhFDX1 lsRoot2 0 1 to liTestFile // See if you can find it in current database. (Start at entry 0, do not consider path and driver)
              if liTestFile begin // We alreeady have that file
                send compare_definitions liFile2 liFile2 FDXCOMP_MODE_FILELIST
              end
              else begin // Create it
                send compare_definitions liFile2 liFile2 FDXCOMP_MODE_ALL
              end
            end
          end
        end

      loop
      set synch_state to lbSynch
      procedure_return msg_ok
    end
    else send obs "Can not compare with empty source or destination!"
    set synch_state to lbSynch
  end_procedure
end_class // cFdxCompareDefinitions_Pn

object oFdxCompareDefinitions_Pn is a cFdxCompareDefinitions_Pn label "Compare data definitions"
  set locate_mode to CENTER_ON_SCREEN
  on_key key_alt+key_1 send activate_list1
  on_key key_alt+key_2 send activate_list2
  on_key key_alt+key_3 send activate_buttons
  on_key kcancel send close_panel
  object oHdr1 is a aps.TextBox
    set value item 0 to "Table definitions"
  end_object
  object oHdr2 is a aps.TextBox
    set value item 0 to "Reference definitions"
  end_object
  send aps_goto_max_row
  object oContents1 is a aps.TextBox
    set border_style to BORDER_STATICEDGE
    set justification_mode to (JMODE_CENTER+JMODE_VCENTER)
  end_object
  object oContents2 is a aps.TextBox
    set border_style to BORDER_STATICEDGE
    set justification_mode to (JMODE_CENTER+JMODE_VCENTER)
  end_object
  send aps_goto_max_row
  send aps_make_row_space 5

  procedure DisplayHeaders
    set value of (oContents1(self)) item 0 to (sFdxTitle.i(fdx.object_id(0)))
    set value of (oContents2(self)) item 0 to (sFdxTitle.i(fdx.object_id(1)))
  end_procedure

  register_object oLst2
  register_object oBtn2
  object oLst1 is a StrucPgmFdxList
    set location to 3 0 relative
    procedure OnFilelistEntry string rn# string ln#
      if (select_state(oBtn2(self),0)) send DoGotoFilelistEntry to (oLst2(self)) rn# ln#
    end_procedure
  end_object
  object oLst2 is a StrucPgmFdxList
    set location to 3 39 relative
    procedure OnFilelistEntry string rn# string ln#
      if (select_state(oBtn2(self),0)) send DoGotoFilelistEntry to (oLst1(self)) rn# ln#
    end_procedure
  end_object

  send aps_align_by_moving (oHdr1(self)) (oLst1(self)) SL_ALIGN_LEFT
  send aps_align_by_sizing (oHdr1(self)) (oLst1(self)) SL_ALIGN_RIGHT
  send aps_align_by_moving (oHdr2(self)) (oLst2(self)) SL_ALIGN_LEFT
  send aps_align_by_sizing (oHdr2(self)) (oLst2(self)) SL_ALIGN_RIGHT
  send aps_align_by_moving (oContents1(self)) (oLst1(self)) SL_ALIGN_LEFT
  send aps_align_by_sizing (oContents1(self)) (oLst1(self)) SL_ALIGN_RIGHT
  send aps_align_by_moving (oContents2(self)) (oLst2(self)) SL_ALIGN_LEFT
  send aps_align_by_sizing (oContents2(self)) (oLst2(self)) SL_ALIGN_RIGHT
  send aps_goto_max_row

  object oBtn1_1 is a aps.Multi_Button
    on_item "Open current" send DoLoadCurrent
  end_object
  object oBtn1_2 is a aps.Multi_Button
    on_item "Open FDX file" send DoLoadFile
  end_object
  send aps_locate_multi_buttons
  send aps_goto_max_row
  object oBtn2 is a aps.CheckBox label "Synchronized lists"
    set checked_state to true
  end_object
  function synch_state returns integer
    function_return (checked_state(oBtn2(self)))
  end_function
  procedure set synch_state integer value#
    set checked_state of (oBtn2(self)) to value#
  end_procedure
  object oBtn3_1 is a aps.Multi_Button
    on_item "Filter" send DoFilter
  end_object
  object oBtn3_2 is a aps.Multi_Button
    on_item "Compare" send DoOne
  end_object
  object oBtn3_3 is a aps.Multi_Button
    on_item "Compare all" send DoAll
  end_object
  object oBtn3_4 is a aps.Multi_Button
    on_item "Close"        send close_panel
  end_object
  on_key key_ctrl+key_f send DoFilter
  on_key key_ctrl+key_c send DoOne
  on_key key_ctrl+key_a send DoAll
  on_key key_ctrl+key_t send DoAll_CompareFieldNames
  send aps_locate_multi_buttons
  procedure activate_list1
    send activate to (oLst1(self))
  end_procedure
  procedure activate_list2
    send activate to (oLst2(self))
  end_procedure
  procedure activate_buttons
    send activate to (oBtn3(self))
  end_procedure
  procedure popup
    integer grb#
    send DisplayHeaders
    send fill_list.i to (oLst1(self)) (fdx.object_id(0))
    send fill_list.i to (oLst2(self)) (fdx.object_id(1))
    ui_accept self to grb#
  End_Procedure
  
  Procedure DoAllAndExit
    Send doall
    Send Close_Panel
  End_Procedure
  
  //JK BEGIN
  Procedure popup_doall
    Integer grb#
    Send DisplayHeaders
    Send fill_list.i to (oLst1(Self)) (fdx.object_id(0))
    Send fill_list.i to (oLst2(Self)) (fdx.object_id(1))
    Send Deferred_Message of (Client_Area(Main)) MSG_DoAllAndExit Self
    ui_accept Self to grb#
  End_Procedure
  //JK END
  Procedure aps_beautify
    send aps_align_inside_container_by_moving (oBtn2(self)) SL_ALIGN_CENTER
  end_procedure
end_object // oFdxCompareDefinitions_Pn

register_object oFrm1
register_object oFrm2
register_object oFrm3
register_object oFrm4
register_object oFrm5
register_object oFrm6
object oStrucPgmOther_Pn is a aps.ModalPanel label "Change parameters for selected tables"
  set locate_mode to CENTER_ON_SCREEN
  on_key ksave_record send close_panel_ok
  on_key kcancel send close_panel
  property integer piResult 0
  set p_auto_column to 1
  send tab_column_define 1  20 15 JMODE_LEFT // Default column setting
  send tab_column_define 2 100 15 JMODE_LEFT // Default column setting
  object oCb1 is a aps.CheckBox label "Compression"
    procedure OnChange
      set object_shadow_state of (oFrm1(self)) to (not(checked_state(self)))
    end_procedure
  end_object
  object oFrm1 is a Api_Attr.ComboFormAux abstract AFT_ASCII20 snap 2
    send prepare_attr_values DF_FILE_COMPRESSION
    set object_shadow_state to true
  end_object
  object oCb2 is a aps.CheckBox label "Integrity check"
    procedure OnChange
      set object_shadow_state of (oFrm2(self)) to (not(checked_state(self)))
    end_procedure
  end_object
  object oFrm2 is a Api_Attr.ComboFormAux abstract AFT_ASCII20 snap 2
    send prepare_attr_values DF_FILE_INTEGRITY_CHECK
    set object_shadow_state to true
  end_object
  object oCb3 is a aps.CheckBox label "Multiuser"
    procedure OnChange
      set object_shadow_state of (oFrm3(self)) to (not(checked_state(self)))
    end_procedure
  end_object
  object oFrm3 is a Api_Attr.ComboFormAux abstract AFT_ASCII20 snap 2
    send prepare_attr_values DF_FILE_MULTIUSER
    set object_shadow_state to true
  end_object
  object oCb4 is a aps.CheckBox label "Reuse deleted"
    procedure OnChange
      set object_shadow_state of (oFrm4(self)) to (not(checked_state(self)))
    end_procedure
  end_object
  object oFrm4 is a Api_Attr.ComboFormAux abstract AFT_ASCII20 snap 2
    send prepare_attr_values DF_FILE_REUSE_DELETED
    set object_shadow_state to true
  end_object

  object oCb5 is a aps.CheckBox label "Transaction type"
    procedure OnChange
      set object_shadow_state of (oFrm5(self)) to (not(checked_state(self)))
    end_procedure
  end_object
  object oFrm5 is a Api_Attr.ComboFormAux abstract AFT_ASCII20 snap 2
    send prepare_attr_values DF_FILE_TRANSACTION
    set object_shadow_state to true
  end_object
  object oCb6 is a aps.CheckBox label "Lock type"
    procedure OnChange
      set object_shadow_state of (oFrm6(self)) to (not(checked_state(self)))
    end_procedure
  end_object
  object oFrm6 is a Api_Attr.ComboFormAux abstract AFT_ASCII20 snap 2
    send prepare_attr_values DF_FILE_LOCK_TYPE
    set object_shadow_state to true
  end_object

  object oCb9 is a aps.CheckBox label "Trim record length"
  end_object
  object oBtn1 is a aps.Multi_Button
    on_item t.btn.ok send close_panel_ok
  end_object
  object oBtn2 is a aps.Multi_Button
    on_item t.btn.cancel send close_panel
  end_object
  send aps_locate_multi_buttons
  procedure close_panel_ok
    set piResult to 1
    send close_panel
  end_procedure
  procedure popup
    set piResult to 0
    forward send popup
    if (piResult(self)) begin
    end
  end_procedure
  function iPopup returns integer
    send popup
    function_return (piResult(self))
  end_function
  function iSetAttribute.i integer attr# returns integer
    if attr# eq DF_FILE_COMPRESSION     function_return (checked_state(oCb1(self)))
    if attr# eq DF_FILE_INTEGRITY_CHECK function_return (checked_state(oCb2(self)))
    if attr# eq DF_FILE_MULTIUSER       function_return (checked_state(oCb3(self)))
    if attr# eq DF_FILE_REUSE_DELETED   function_return (checked_state(oCb4(self)))
    if attr# eq DF_FILE_TRANSACTION     function_return (checked_state(oCb5(self)))
    if attr# eq DF_FILE_LOCK_TYPE       function_return (checked_state(oCb6(self)))
    if attr# eq DF_FILE_RECORD_LENGTH   function_return (checked_state(oCb9(self)))
    //function_return 0
  end_function
  function sAttributeValue.i integer attr# returns string
    if attr# eq DF_FILE_COMPRESSION     function_return (Combo_Current_Aux_Value(oFrm1(self)))
    if attr# eq DF_FILE_INTEGRITY_CHECK function_return (Combo_Current_Aux_Value(oFrm2(self)))
    if attr# eq DF_FILE_MULTIUSER       function_return (Combo_Current_Aux_Value(oFrm3(self)))
    if attr# eq DF_FILE_REUSE_DELETED   function_return (Combo_Current_Aux_Value(oFrm4(self)))
    if attr# eq DF_FILE_TRANSACTION     function_return (Combo_Current_Aux_Value(oFrm5(self)))
    if attr# eq DF_FILE_LOCK_TYPE       function_return (Combo_Current_Aux_Value(oFrm6(self)))
    function_return ""
  end_function
end_object // oStrucPgmOther_Pn


object oListOfTablesAndFieldsThatItIsOkToDropAndDelete is a cArray

            function iFindItem.s string lsItem returns integer
              integer liMax liItm
              move (lowercase(lsItem)) to lsItem
              get item_count to liMax
              decrement liMax
              for liItm from 0 to liMax
                if (lsItem=value(self,liItm)) function_return liItm
              loop
              function_return -1
            end_function

                                  procedure add_thing string lsValue
                                    integer liItm
                                    get item_count to liItm
                                    set value item liItm to (lowercase(lsValue))
                                  end_procedure
            procedure DeleteFieldBuildList integer liFile integer liField string lsName string lsRoot
              send add_thing (lsRoot+"."+lsName)
            end_procedure
            procedure DeleteTableBuildList integer liFile string lsName
              send add_thing lsName
            end_procedure

  define DFM_DROP_FILE_ID for "File ID: DFMatrix allowed drops"
  //> Write contents to file
  procedure SEQ_Write integer liChannel
    integer liMax liItm
    writeln channel liChannel DFM_DROP_FILE_ID
    get item_count to liMax
    decrement liMax
    for liItm from 0 to liMax
      writeln channel liChannel (value(self,liItm))
    loop
  end_procedure

  //> Read contents from file
  procedure SEQ_Read integer liChannel
    integer lbSeqEof
    string lsLine
    send delete_data
    readln channel liChannel lsLine
    if (lsLine=DFM_DROP_FILE_ID) begin
      repeat
        readln channel liChannel lsLine
        move (seqeof) to lbSeqEof
        ifnot lbSeqEof begin
          send add_thing lsLine
        end
      until lbSeqEof
    end
    else error 751 "Incompatible drop file"
  end_procedure

            property integer pbOkToRestructure 0
            procedure DeleteFieldCheck integer liFile integer liField string lsName string lsRoot
              integer liItem
              move (lsRoot+"."+lsName) to lsName
              get iFindItem.s lsName to liItem
              if (liItem=-1) begin // If not found, then we can't proceed
                set pbOkToRestructure to false
                send DoWriteTimeEntry to (oStructure_LogFile(self)) ("Error: Not OK to delete field "+lsName)
              end
            end_procedure
            procedure DeleteTableCheck integer liFile string lsName
              integer liItem
              get iFindItem.s lsName to liItem
              if (liItem=-1) begin // If not found, then we can't proceed
                set pbOkToRestructure to false
                send DoWriteTimeEntry to (oStructure_LogFile(self)) ("Error: Not OK to drop table "+lsName)
              end
            end_procedure

  //> Can we approve of the array of programs
  function bOkToRestructure integer lhPgmArr returns integer
    set pbOkToRestructure to true
    send AppendOutput to (oStructure_LogFile(self))
    send callback_deleted_fields to lhPgmArr MSG_DeleteFieldCheck self
    send callback_deleted_tables to lhPgmArr MSG_DeleteTableCheck self
    ifnot (pbOkToRestructure(self)) send DoWriteTimeEntry to (oStructure_LogFile(self)) "(Restructure will be cancelled)"
    send CloseOutput to (oStructure_LogFile(self))
    function_return (pbOkToRestructure(self))
  end_function

  //
  procedure ConfirmAndWriteFile
  end_procedure

  //> Write contents to log file
  procedure SEQ_WriteReportToLog integer liChannel
  end_procedure
end_object // oListOfTablesAndFieldsThatItIsOkToDropAndDelete

class cStrucPgmList is a aps.Grid
  procedure construct_object integer img#
    forward send construct_object img#
    set highlight_row_state to dfTrue
    on_key kenter send display_program
    on_key key_ctrl+key_e send execute_one
    on_key kdelete_record send request_delete
    set line_width to 1 0
    set header_visible_state to false
    set gridline_mode to GRID_VISIBLE_NONE
    set form_margin item 0 to 70  //
    set highlight_row_state to true
    set highlight_row_color to (rgb(0,255,255))
    set current_item_color to (rgb(0,255,255))
    set select_mode to no_select
    on_key knext_item send switch
    on_key kprevious_item send switch_back
    property integer priv.pbDeletesOrDrops DFFALSE
  end_procedure
  procedure request_delete
    integer liRow lhServer lhPgm itm#
    if (item_count(self)) begin
      get piStructPgm_Server to lhServer // Gets from encapsulating object
      get current_item to itm#
      get aux_value item itm# to lhPgm
      get iFindRowFromPgm.i of lhServer lhPgm to liRow
      if liRow ne -1 begin
        send Reset.i to lhServer liRow
        get current_item to liRow
        send fill_list
        if liRow gt (item_count(self)-1) decrement liRow
        set current_item to liRow
      end
    end
  end_procedure
  procedure display_program
    if (item_count(self)) send StructPgm_Display (aux_value(self,current_item(self)))
  end_procedure
  procedure mouse_click integer liItem integer liGrb
    if ((liItem-1)<item_count(self)) send display_program
  end_procedure
  procedure fill_list
    integer max# liRow lhServer lhPgm itm# type#
    send delete_data
    get piStructPgm_Server to lhServer
    get row_count of lhServer to max#
    for liRow from 0 to (max#-1)
      get piObject.i of lhServer liRow to lhPgm
      get piProgramType of lhPgm to type#
      send add_item msg_none (sTitle(lhPgm))
      set aux_value item (item_count(self)-1) to lhPgm
    loop
    set dynamic_update_state to DFTRUE
    get item_count to max#
    for itm# from 0 to (max#-1)
      set entry_state item itm# to DFFALSE
    loop
  end_procedure

  procedure DeleteFieldWarning integer liFile integer liField string lsName string lsRoot
    string lsValue
    set priv.pbDeletesOrDrops to DFTRUE
    move "Field [ will be deleted (in table [)." to lsValue
    move (replace("[",lsValue,lsName)) to lsValue
    move (replace("[",lsValue,lsRoot)) to lsValue
    send DoDisplayTextConfirm_AddLine lsValue
  end_procedure

  procedure DeleteTableWarning integer liFile string lsName
    string lsValue
    set priv.pbDeletesOrDrops to DFTRUE
    move "Table # will be dropped." to lsValue
    move (replace("#",lsValue,lsName)) to lsValue
    send DoDisplayTextConfirm_AddLine lsValue
  end_procedure

  procedure generate_list_of_tables_and_fields_that_it_is_ok_to_drop_and_delete
    integer oPgmArr# lbForceReindex lbContinue lhListOfTablesAndFieldsThatItIsOkToDropAndDelete
    if (DFMatrix_RealDataPrimary()) begin
      move (oListOfTablesAndFieldsThatItIsOkToDropAndDelete(Self)) to lhListOfTablesAndFieldsThatItIsOkToDropAndDelete

      get piStructPgm_Server to oPgmArr#  // Gets from encapsulating object

      set priv.pbDeletesOrDrops to DFFALSE
      send delete_data to lhListOfTablesAndFieldsThatItIsOkToDropAndDelete
      send callback_deleted_fields to oPgmArr# MSG_DeleteFieldBuildList lhListOfTablesAndFieldsThatItIsOkToDropAndDelete
      send callback_deleted_tables to oPgmArr# MSG_DeleteTableBuildList lhListOfTablesAndFieldsThatItIsOkToDropAndDelete

      move DFTRUE to lbContinue
//      if (priv.pbDeletesOrDrops(self)) get DoDisplayTextConfirm "Restructure warning!" "" to lbContinue
    end
  end_procedure

  procedure execute_one
    integer lhPgm file# ci# lbForceReindex lbContinue lbDeleteDroppedTables
    if (item_count(self)) begin
      if (DFMatrix_RealDataPrimary()) begin
        move (aux_value(self,current_item(self))) to lhPgm

        set priv.pbDeletesOrDrops to DFFALSE // NEWTHING
        send DoDisplayTextConfirm_Reset // NEWTHING
        send callback_deleted_fields to lhPgm MSG_DeleteFieldWarning self // NEWTHING

        move DFTRUE to lbContinue // NEWTHING
        if (priv.pbDeletesOrDrops(self)) get DoDisplayTextConfirm "Restructure warning!" "" to lbContinue // NEWTHING

        if lbContinue begin // NEWTHING
          get piFile of lhPgm to file#
          get bForceReindex to lbForceReindex
          set piSortOnEndStructure of lhPgm to lbForceReindex

          get bDeleteDroppedTables to lbDeleteDroppedTables
          set pbDeleteDroppedTables of lhPgm to lbDeleteDroppedTables

          send Execute to lhPgm
          get current_item to ci#
          send fill_list
          set current_item to ci#
          // Now reread the definition(s) that was just restructured:
          send Read_File_RootName_Again to (fdx.object_id(0)) (API_AttrValue_FILELIST(DF_FILE_ROOT_NAME,file#))
        end
      end
      else send obs "To execute a program, real data must be loaded (Read current)"
    end
  end_procedure
  procedure execute_all
    integer oPgmArr# lbForceReindex lbContinue lbBatchMode lbReindexAll lbDeleteDroppedTables
    integer liGrb
    if (DFMatrix_RealDataPrimary()) begin
      //move (oFdxRestructureProgramArray_StrucPgm(self)) to oPgmArr#
      get piStructPgm_Server to oPgmArr#

      get DfmBatchMode to lbBatchMode

      if lbBatchMode begin
        get bOkToRestructure of (oListOfTablesAndFieldsThatItIsOkToDropAndDelete(self)) oPgmArr# to lbContinue
      end
      else begin
        set priv.pbDeletesOrDrops to DFFALSE // NEWTHING
        send DoDisplayTextConfirm_Reset // NEWTHING
        send callback_deleted_fields to oPgmArr# MSG_DeleteFieldWarning self // NEWTHING
        send callback_deleted_tables to oPgmArr# MSG_DeleteTableWarning self // NEWTHING
        move DFTRUE to lbContinue // NEWTHING
        if (priv.pbDeletesOrDrops(self)) get DoDisplayTextConfirm "Restructure warning!" "" to lbContinue // NEWTHING
      end

      if lbContinue begin // NEWTHING
        get bForceReindex to lbForceReindex
        set piSortOnEndStructure of oPgmArr# to lbForceReindex
        get bDeleteDroppedTables to lbDeleteDroppedTables
        set pbDeleteDroppedTables of oPgmArr# to lbDeleteDroppedTables
        send Execute to oPgmArr#

        if lbBatchMode begin // If we're in batch mode we will check if we should reindex all on completion:
          get bReindexAll to lbReindexAll
          if lbReindexAll begin
            runprogram wait "cls"
            runprogram wait "dfsort -a"
            send refresh_screen
            get SEQ_AppendFiles (DfmBatchMode_LogfileName()) "dfsort.log" to liGrb
          end
        end

        send fill_list
        send DFMatrix_PrimaryReread
        if (piErrorDuringStructure(oPgmArr#)) begin
          if lbBatchMode begin
            error 750 "Errors occurred during restructure"
          end
          else send obs "Errors occurred during restructure" "Check 'dfmatrix.log' for details"
        end
      end
    end
    else send obs "To execute a program, real data must be loaded (Read current)"
  end_procedure
  procedure request_open
    integer lhServer
    get piStructPgm_Server to lhServer
    send open_browse to lhServer
    send fill_list
  end_procedure
  procedure request_save
    integer lhServer
    get piStructPgm_Server to lhServer
    send save_browse to lhServer
  end_procedure

  function iProgramObject.is integer file# string rn# returns integer
    integer oOther# pgm_obj# oPgmArr# pgm_liRow
    move (oFdxRestructureProgramArray_StrucPgm(self)) to oPgmArr#
    // Is there such a program already?
    move (iFindPgmRow.is(oPgmArr#,file#,rn#)) to pgm_liRow
    if pgm_liRow ne -1 begin
      //send reset.i to oPgmArr# pgm_liRow // If so, reset it
      get piObject.i of oPgmArr# pgm_liRow to pgm_obj#
    end
    else begin
      get iAddPgmRow.is of oPgmArr# file# rn# to pgm_liRow // If not, create it
      get iCreateFdxRestructureProgram to pgm_obj#
      send reset to pgm_obj#
      set piFile     of pgm_obj# to file#
      set psRootName of pgm_obj# to rn#
      set piProgramType of pgm_obj# to PGM_TYPE_EDIT
      set piObject.i of oPgmArr# pgm_liRow to pgm_obj#
    end
    function_return pgm_obj#
  end_function

  procedure DoOthers_Help integer file# string dn# string ln# string rn#
    integer oOther# pgm_obj# oFDX# reclength#
    integer DoCompression# DoIntegrity_check# DoMultiuser# DoReuse_deleted# DoRecord_length#
    integer DoTransaction# DoLocktype#
    move (oStrucPgmOther_Pn(self)) to oOther#
    get iSetAttribute.i of oOther# DF_FILE_COMPRESSION     to DoCompression#
    get iSetAttribute.i of oOther# DF_FILE_INTEGRITY_CHECK to DoIntegrity_check#
    get iSetAttribute.i of oOther# DF_FILE_MULTIUSER       to DoMultiuser#
    get iSetAttribute.i of oOther# DF_FILE_REUSE_DELETED   to DoReuse_deleted#
    get iSetAttribute.i of oOther# DF_FILE_RECORD_LENGTH   to DoRecord_length#
    get iSetAttribute.i of oOther# DF_FILE_TRANSACTION     to DoTransaction#
    get iSetAttribute.i of oOther# DF_FILE_LOCK_TYPE       to DoLocktype#
    if (DoCompression#+DoIntegrity_check#+DoMultiuser#+DoReuse_deleted#+DoRecord_length#+DoTransaction#+DoLocktype#) begin
      get iProgramObject.is file# rn# to pgm_obj#
      if DoCompression#     send add_file_instruction to pgm_obj# DF_FILE_COMPRESSION     (sAttributeValue.i(oOther#,DF_FILE_COMPRESSION))
      if DoIntegrity_check# send add_file_instruction to pgm_obj# DF_FILE_INTEGRITY_CHECK (sAttributeValue.i(oOther#,DF_FILE_INTEGRITY_CHECK))
      if DoMultiuser#       send add_file_instruction to pgm_obj# DF_FILE_MULTIUSER       (sAttributeValue.i(oOther#,DF_FILE_MULTIUSER))
      if DoReuse_deleted#   send add_file_instruction to pgm_obj# DF_FILE_REUSE_DELETED   (sAttributeValue.i(oOther#,DF_FILE_REUSE_DELETED))
      if DoTransaction#     send add_file_instruction to pgm_obj# DF_FILE_TRANSACTION     (sAttributeValue.i(oOther#,DF_FILE_TRANSACTION))
      if DoLocktype#        send add_file_instruction to pgm_obj# DF_FILE_LOCK_TYPE       (sAttributeValue.i(oOther#,DF_FILE_LOCK_TYPE))
      if DoRecord_length#   begin
        move (fdx.object_id(0)) to oFDX#
        get AttrValue_FILE of oFDX# DF_FILE_RECORD_LENGTH_USED file# to reclength#
        send add_file_instruction to pgm_obj# DF_FILE_RECORD_LENGTH reclength#
      end
    end
  end_procedure

  procedure DoOthers
    integer oOther# pgm_obj# oPgmArr# select_count#
    move (oStrucPgmOther_Pn(self)) to oOther#
    if (iPopup(oOther#)) begin
      get File_Select_Count of (DFMatrix_SelectorObject()) to select_count#
      ifnot select_count# send obs "No files selected!"
      else begin
        send Callback_Selected_Files to (DFMatrix_SelectorObject()) msg_DoOthers_Help self
        send fill_list
      end
    end
  end_procedure

  procedure DoMaxRecs_Help integer file# string root# integer new_max#
    integer pgm_obj#
    get iProgramObject.is file# root# to pgm_obj#
    send add_file_instruction to pgm_obj# DF_FILE_MAX_RECORDS new_max#
    set piProgramType of pgm_obj# to PGM_TYPE_EDIT
  end_procedure

  procedure DoMaxRecs
    integer oNewMaxRecords#
    move (oNewMaxRecords(self)) to oNewMaxRecords#
    if (iPopup(oNewMaxRecords#)) send post_maxrecords
  end_procedure

  procedure post_maxrecords
    integer oNewMaxRecords# lhSelf
    move self to lhSelf
    move (oNewMaxRecords(self)) to oNewMaxRecords#
    send Callback_ModifiedEntries to (oLst(oNewMaxRecords#)) msg_DoMaxRecs_Help lhSelf
    send fill_list
  end_procedure
end_class // cStrucPgmList

activate_view Activate_RestructPrograms for oStructPgmArray_Vw
object oStructPgmArray_Vw is a aps.View label "Restructure programs"
  set Border_Style to BORDER_THICK   // Make panel resizeable
  set pMinimumSize to 200 0
  property integer piStructPgm_Server (oFdxRestructureProgramArray_StrucPgm(self))
  on_key kcancel send close_panel
  object oCont is a aps.Container3d
    set p_auto_column to 0
    register_object oBtn1
    register_object oBtn11
    object oLst is a cStrucPgmList
      set size to 200 0
      on_key kswitch send activate to (oBtn1(self))
    end_object
    object oBtn1 is a aps.Multi_Button
      on_key kswitch send activate to (oBtn11(self))
      on_item "List program" send display_program to (oLst(self))
    end_object
    object oBtn2 is a aps.Multi_Button
      on_key kswitch send activate to (oBtn11(self))
      on_item "Execute"  send request_execute_one
    end_object
    object oBtn3 is a aps.Multi_Button
      on_key kswitch send activate to (oBtn11(self))
      on_item "Execute all"  send request_execute_all
    end_object
    object oBtn4 is a aps.Multi_Button
      on_key kswitch send activate to (oBtn11(self))
      on_item "Remove"       send Request_delete to (oLst(self))
    end_object
    object oBtn5 is a aps.Multi_Button
      on_key kswitch send activate to (oBtn11(self))
      on_item "Remove all"   send reset_list
    end_object
    send aps_locate_multi_buttons sl_vertical
    object oCb1 is a aps.CheckBox label "Trace on" snap SL_DOWN
      on_key kswitch send activate to (oBtn11(self))
    end_object
    object oCb2 is a aps.CheckBox label "Delete dropped" snap SL_DOWN
      on_key kswitch send activate to (oBtn11(self))
    end_object
    object oCb3 is a aps.CheckBox label "Force reindex" snap SL_DOWN
      on_key kswitch send activate to (oBtn11(self))
    end_object
    object oBtn6 is a aps.Button snap SL_DOWN
      on_key kswitch send activate to (oBtn11(self))
      on_item "Trace view" send Activate_RestructureTracer
    end_object
    procedure DoLogFileProperties
      send Popup_LogFileProperties (oStructure_LogFile(self))
    end_procedure
    object oBtn7 is a aps.Button snap SL_DOWN
      on_key kswitch send activate to (oBtn11(self))
      on_item "Log file" send DoLogFileProperties
    end_object
    function bDeleteDroppedTables returns integer
      integer rval#
      get checked_state of (oCB2(self)) to rval#
      function_return rval#
    end_function
    procedure request_execute_one
      integer trace# lhPgm lhLst
      string fn#
      move (oLst(self)) to lhLst
      if (item_count(lhLst)) begin
        // At this point we need to check that then program has not already been
        // executed.
        move (aux_value(lhLst,current_item(lhLst))) to lhPgm
        if (piExecuted(lhPgm)) send obs "This program has already been executed"
        else begin
          get checked_state of (oCB1(self)) to trace#
          if trace# send RS_TraceOn
          send execute_one to lhLst
          if trace# begin
            send RS_TraceOff
            get sRootInclPath of oRestructurer# to fn#
            move (fn#+".rst") to fn#
            send obs "The restructure trace was saved in file" fn# "" "Press OK to view the file..."
            send Activate_RestructureTracer_With_File fn#
          end
        end
      end
    end_procedure
    procedure request_execute_all
      integer trace#
      get checked_state of (oCB1(self)) to trace#
      if trace# send obs "Tracing a restructure can only be done" "when executing one program a time." "" "Trace setting will be ignored."
      //if trace# send RS_TraceOn
      send execute_all to (oLst(self))
      //if trace# send RS_TraceOff
    end_procedure
  end_object // oCont

  function bForceReindex returns integer
    integer lbRval
    get checked_state of (oCB3(oCont(self))) to lbRval
    function_return lbRval
  end_function

  property integer pbReindexAll 0 // Secret, for use with batch mode only (and only in character mode)
  function bReindexAll returns integer
    function_return (pbReindexAll(self))
  end_function

  procedure compare_tables
    send popup to (oFdxCompareDefinitions_Pn(self))
    send fill_list to (oLst(oCont(self)))
    send activate to (oLst(oCont(self)))
  End_Procedure
  Procedure Compare_Tables_DoAll
    Send Popup_doall to (oFdxCompareDefinitions_Pn(Self))
    Send fill_list to (oLst(oCont(Self)))
    Send activate to (oLst(oCont(Self)))
    Send Next of (oLst(oCont(self)))
    Send activate to (oLst(oCont(Self)))
  End_Procedure
  procedure reset_list
    send Reset to (piStructPgm_Server(self))
    send fill_list to (oLst(oCont(self)))
  end_procedure
  object oBtn11 is a aps.Multi_Button
    on_key kswitch send activate to (oLst(oCont(self)))
    on_item "Compare" send compare_tables
  end_object
  object oBtn12 is a aps.Multi_Button
    on_key kswitch send activate to (oLst(oCont(self)))
    on_item "Max records" send DoMaxRecs to (oLst(oCont(self)))
  end_object
  object oBtn13 is a aps.Multi_Button
    on_key kswitch send activate to (oLst(oCont(self)))
    on_item "Other"   send DoOthers to (oLst(oCont(self)))
  end_object
  send aps_register_multi_button (oBtn13(self))
//object oBtn14 is a aps.Multi_Button
//  on_key kswitch send activate to (oLst(oCont(self)))
//  on_item "Open"    send request_open to (oLst(oCont(self)))
//end_object
//object oBtn15 is a aps.Multi_Button
//  on_key kswitch send activate to (oLst(oCont(self)))
//  on_item "Save"    send request_save to (oLst(oCont(self)))
//end_object
  object oBtn16 is a aps.Multi_Button
    on_key kswitch send activate to (oLst(oCont(self)))
    on_item "Close"   send close_panel
  end_object
  send aps_locate_multi_buttons

  procedure aps_onResize integer delta_rw# integer delta_cl#
    send aps_resize (oCont(self)) delta_rw# 0
    send aps_resize (oLst(oCont(self))) delta_rw# 0
    send aps_register_multi_button (oBtn11(self))
    send aps_register_multi_button (oBtn12(self))
    send aps_register_multi_button (oBtn13(self))
    send aps_register_multi_button (oBtn13(self)) // Twice is alright
//  send aps_register_multi_button (oBtn14(self))
//  send aps_register_multi_button (oBtn15(self))
    send aps_register_multi_button (oBtn16(self))
    send aps_locate_multi_buttons
    send aps_auto_size_container
  end_procedure
end_object // oStructPgmArray_Vw
