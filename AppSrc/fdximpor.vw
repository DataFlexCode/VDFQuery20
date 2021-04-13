Use aps.pkg      // Auto Positioning and Sizing classes for VDF
Use FDXData.nui  // Class for reading and writing table data to files incl. definition
Use TextData.pkg // Properties for text data file (Popup_TextDataProperties)
Use FdxSelct.utl // Functions iFdxSelectOneFile and iFdxSelectOneField
Use Fdx2.utl     // FDX aware object for displaying a table definition
Use Mapper.pkg   // Dialog for mapping (fields)
Use Files.nui    // Utilities for handling file related stuff (No User Interface)
Use TableUpd.nui // Class for updating table data
Use AppDB.utl    // Create data tables

Use ImportDataDefaultValuesPanel.pkg

object oFdxImport_RootName is a aps.ModalPanel label "Specify file root name for new table"
  set locate_mode to CENTER_ON_SCREEN
  on_key ksave_record send close_panel_ok
  on_key kcancel send close_panel
  Property Integer piResult DFFALSE

  object oFrm is a aps.Form abstract AFT_ASCII80
    set p_extra_internal_width to -200
  end_object
  object oBtn1 is a aps.Multi_Button
    on_item t.btn.ok send close_panel_ok
  end_object
  object oBtn2 is a aps.Multi_Button
    on_item t.btn.cancel send close_panel
  end_object
  send aps_locate_multi_buttons
  procedure close_panel_ok
    set piResult to DFTRUE
    send close_panel
  end_procedure
  function sPopup returns string
    string lsRval
    set piResult to DFFALSE
    move "" to lsRval
    send popup
    if (piResult(self)) get value of oFrm item 0 to lsRval
    function_return (trim(lsRval))
  end_function
end_object

activate_view Activate_FdxImport_Vw for oFdxImport_Vw
object oFdxImport_Vw is a aps.View label "Import data from text file"

  object oTextDataParameters is a cTextDataParameters
  end_object
  object oTextDataReader is a cTextDataReader
    set phTextDataParameters to (oTextDataParameters(self))
    procedure DoSetup string lsFileName
      integer liResult
      get iFileOpen.s lsFileName to liResult
      if (liResult=TDATFO_OK) send FileClose
      else send obs "Not OK"
    end_procedure
  end_object

  object oFDXDataFileImport is a cFDXDataFile
  end_object

  object oFileMapObject is a cMapObject
  end_object
  object oTableMapObject is a cMapObject
  end_object
  object oMapper is a cMapper
    set phObject1 to (oFileMapObject(self))
    set phObject2 to (oTableMapObject(self))
  end_object

  object oTableFDX is a cFdxFileDef
  end_object

  object oTableUpdateParameters is a cTableUpdateParameters
  end_object

  object oTableDefaultValues is a cArray
    item_property_list
      item_property integer piField.i
      item_property integer pbEvenIfNotEmpty.i
      item_property string  psValue.i
    end_item_property_list
    Procedure AddRow Integer iField Integer iEvenIfNotEmpty String sValue
        Integer iRow
        Get Row_Count to iRow
        Set piField.i          iRow to iField         
        Set pbEvenIfNotEmpty.i iRow to iEvenIfNotEmpty
        Set psValue.i          iRow to sValue
    End_Procedure
    function FindRow integer iField returns integer
      Integer iRow iMax
      Get Row_Count to iMax
      decrement imax
      for iRow from 0 to iMax
        if (iField=piField.i(self,iRow)) begin
          function_return iRow
        end
      loop
      function_return -1
    End_Function
    
        Function _FieldIsEmpty Integer iTable Integer iField Returns Boolean
            Integer iType
            String sFieldValue
            Get_Attribute DF_FIELD_TYPE of iTable iField to iType
            Get_Field_Value iTable iField to sFieldValue
            If (iType=DF_DATE) Begin
                Function_Return (Integer(Date(sFieldValue))=0)
            End
            Else If (iType=DF_BCD) Begin
                Function_Return (Number(sFieldValue)=0)
            End
            Function_Return (sFieldValue="")
        End_Function
    
    Procedure InsertDefaultValues Integer iTable
      Integer iRow iMax 
      Get Row_Count to iMax
      Decrement imax
      For iRow from 0 to iMax
        If ((pbEvenIfNotEmpty.i(Self,iRow)<>0) or _FieldIsEmpty(Self,iTable,piField.i(Self,iRow))) Begin
          Set_Field_Value iTable (piField.i(Self,iRow)) to (psValue.i(Self,iRow))
        End
      Loop
    End_Procedure
  end_object

  object oTableUpdater is a cTableUpdater
    set phTableUpdateParameters to (oTableUpdateParameters(self))
    function iUpdateRow returns integer
      integer lhMapper lhTextDataReader liRow liMax liFile liColumn liField
      integer lhDefaultValues liType
      integer liResult
      boolean bOk
      string lsValue

      move (oTextDataReader(self)) to lhTextDataReader
      move (oMapper(self)) to lhMapper
      get piFile to liFile
      clear liFile
      get row_count of lhMapper to liMax
      decrement liMax
//      showln "New row in file:"
      for liRow from 0 to liMax
        get piIdent1.i of lhMapper liRow to liColumn
        get piIdent2.i of lhMapper liRow to liField
//        showln ("File: "+string(liFile)+", field: "+string(liField)) (" Column: "+string(liColumn)) ("  "+value(lhTextDataReader,liColumn))
        get sConvertedValue.i of lhTextDataReader liColumn to lsValue
        set_field_value liFile liField to lsValue
      loop

      move (oTableDefaultValues(self)) to lhDefaultValues
      get row_count of lhDefaultValues to liMax
      decrement liMax
      for liRow from 0 to liMax
        get piField.i of lhDefaultValues liRow to liField

        get pbEvenIfNotEmpty.i of lhDefaultValues liRow to bOk

        if (not(bOk)) begin
          get_field_value liFile liField to lsValue
          get_attribute DF_FIELD_TYPE of liFile liField to liType
          if (liType=DF_BCD) begin
            move (lsValue="0") to bOk
          end
          else begin
            move (lsValue="") to bOk
          end
        end

        if (bOk) begin
          Set_Field_Value liFile liField to (psValue.i(lhDefaultValues,liRow))
        end
      Loop
      
      Send InsertDefaultValues of oTableDefaultValues liFile


      get iSaveRecord to liResult
//      showln ("SAVE "+string(liResult)+" errors")
      function_return 0 // Do not cancel
    end_function
    procedure DoUpdate string lsFileName string lsTableName
      integer lhObj lhTextDataReader liResult
      move (oTextDataReader(self)) to lhTextDataReader
      move self to lhObj
      set piFile         to 37
      set psFilePathName to lsTableName
      get iBeginTransaction to liResult
      if (liResult=TUPD_ILOCK_RTN_OK) begin
        send DoCallback to lhTextDataReader lsFileName get_iUpdateRow lhObj
        get iEndTransaction to liResult // Always returns 0
      end
      close 37
    end_procedure
  end_object // oTableUpdater

  on_key kCancel send close_panel
  object oGrp1 is a aps.Group label "Input file"
    object oInputFile is a aps.Form abstract AFT_ASCII80 label "File Name"
      set p_extra_internal_width to -250
      procedure prompt
        string lsFileName
        get SEQ_SelectInFile "Select text data file" "Text files|*.txt|FDX data files|*.txd|All files|*.*" to lsFileName
        if lsFileName ne "" set value item 0 to lsFileName
      end_procedure
      on_key kprompt send prompt
    end_object
    object oBtn1 is a aps.Button snap SL_RIGHT_SPACE
      on_item "Browse" send prompt to (oInputFile(self))
    end_object
    object oBtn2 is a aps.Button snap SL_DOWN
      on_item "Properties" send DoInputFileProperties
    end_object
    procedure DoInputFileProperties
      integer liIsFdxData
      string lsFileName
      get value of (oInputFile(self)) item 0 to lsFileName
      if (lsFileName<>"") begin
        if (SEQ_FileExists(lsFileName)=SEQIT_FILE) begin
          get lbIsFdxDataFile of (oFDXDataFileImport(self)) lsFileName to liIsFdxData
          if liIsFdxData send obs "Display table definition"
          else send Popup_TextDataProperties lsFileName (oTextDataReader(self))
        end
        else send obs "File not found" ("("+lsFileName+")")
      end
    end_procedure
  end_object

  send aps_goto_max_row
  object oGrp2 is a aps.Group label "Target table"
    Property Integer piFile 0
    object oRootName is a aps.Form abstract AFT_ASCII80 label "Table name"
      set p_extra_internal_width to -250
      procedure prompt
        string lsFileName
        get SEQ_SelectInFile "Select data file" "DataFlex data files|*.dat|Intermediate files|*.int" to lsFileName
        if lsFileName ne "" set value item 0 to lsFileName
      end_procedure
      procedure OnChange
        send delete_data of (oTableDefaultValues(self))
      end_procedure
      on_key kprompt send DoSelectDataFile
    end_object
    procedure DoSelectDataFile
      integer liFile liCanOpen
      string lsRootName
      get piFile to liFile
      get iFdxSelectOneFile 0 liFile to liFile
      if liFile begin
        set piFile to liFile
        close liFile // In the (hopefully) unlikely event that it should be open
        move (DBMS_OpenFile(liFile,DF_SHARE,0)) to liCanOpen
        if liCanOpen begin
          get DBMS_Rootname_Path liFile to lsRootName
          set value of (oRootName(self)) item 0 to (lowercase(lsRootName))
          close liFile
        end
        else send obs "Table can not be opened"
      end
    end_procedure
    object oBtn1 is a aps.Button snap SL_RIGHT_SPACE
      on_item "Filelist" send DoSelectDataFile
    end_object
//    object oDirectory is a aps.Form abstract AFT_ASCII30 label "Directory"
//    end_object
    object oBtn2 is a aps.Button snap SL_DOWN
      on_item "Browse" send prompt to (oRootName(self))
    end_object
    object oBtn3 is a aps.Button snap SL_DOWN
      procedure DoTableProperties
        integer liIsFdxData liCanOpen
        string lsFileName
        get value of (oRootName(self)) item 0 to lsFileName
        if (lsFileName<>"") begin
          if (SEQ_FileExists(lsFileName)=SEQIT_FILE) begin
            close 37
            move (DBMS_OpenFileAs(lsFileName,37,DF_SHARE,0)) to liCanOpen
            if liCanopen begin
              send FDX_ModalDisplayFileAttributes 0 37
              close 37
            end
          end
          else send obs "File not found" ("("+lsFileName+")")
        end
      end_procedure
      on_item "Properties" send DoTableProperties
    end_object
    object oBtn4 is a aps.Button snap SL_DOWN
      object oAppDb is a cAppDb
      end_object

      procedure DoCreateTable
        integer lhObj
        string lsRootName
        get sPopup of oFdxImport_RootName to lsRootName
        if (lsRootName<>"") begin
          Send DoReset of oAppDb
          Get iCreateNewTableObject of oAppDb  to lhObj
        end
      end_procedure
      on_item "Create table" send DoCreateTable
    end_object
  end_object
  send aps_goto_max_row
  object oGrp3 is a aps.Group label "Table update parameters"
    send tab_column_define 1 30 25 jmode_left // Default column setting
    object oCb1 is a aps.CheckBox label "Create new table"
      set enabled_state to DFFALSE
    end_object
    object oCb2 is a aps.CheckBox label "Reset table data before reading"
    end_object
    object oCb3 is a aps.CheckBox label "Overwrite existing records"
      set enabled_state to DFFALSE
    end_object
    object oCb4 is a aps.CheckBox label "Do not check indices"
      set enabled_state to DFFALSE
    end_object
    object oCb5 is a aps.CheckBox label "Switch indices off-line"
    end_object

    set p_cur_row to (p_top_margin(self))
    Object oLockMode is a aps.RadioGroup Label "Lock mode" snap SL_RIGHT_SPACE relative_to (oCb1(self))
      set enabled_state to DFFALSE
      object oRad1 is a aps.Radio label "Open exclusive"
      end_object
      object oRad2 is a aps.Radio label "All in one transaction"
      end_object
      object oRad3 is a aps.Radio label "Unlock every"
      end_object
      object oRad3 is a aps.Radio label "No lock"
      end_object
      object oFrm is a aps.Form abstract AFT_NUMERIC4.0 snap SL_RIGHT relative_to (oRad3(self))
      end_object
      object oTxt is a aps.TextBox label "record" snap SL_RIGHT
      end_object
    End_Object
  end_object

  procedure DoTransferDialogToTableUpdParameters
    integer lhGrp lhTableUpdateParameters liLM
    move (oTableUpdateParameters(self)) to lhTableUpdateParameters
    move (oGrp3(self)) to lhGrp
    set value of lhTableUpdateParameters item TUPD_CREATE_NEW_TABLE     to (select_state(oCb1(lhGrp)))
    set value of lhTableUpdateParameters item TUPD_ZEROFILE_TABLE       to (select_state(oCb2(lhGrp)))
    set value of lhTableUpdateParameters item TUPD_OVERWRITE_EXISTING   to (select_state(oCb3(lhGrp)))
    set value of lhTableUpdateParameters item TUPD_DO_NOT_CHECK_INDEX   to (select_state(oCb4(lhGrp)))
    set value of lhTableUpdateParameters item TUPD_SWITCH_INDEX_OFFLINE to (select_state(oCb5(lhGrp)))
    get current_radio of (oLockMode(lhGrp)) to liLM

    if liLM eq 0 set value of lhTableUpdateParameters item TUPD_LOCK_MODE to TUPD_LOCK_MODE_OPEN_EXCLUSIVE
    if liLM eq 1 set value of lhTableUpdateParameters item TUPD_LOCK_MODE to TUPD_LOCK_MODE_ONE_TRANSACTION
    if liLM eq 2 set value of lhTableUpdateParameters item TUPD_LOCK_MODE to TUPD_LOCK_MODE_UNLOCK_EVERY
    if liLM eq 3 set value of lhTableUpdateParameters item TUPD_LOCK_MODE to TUPD_LOCK_MODE_NO_LOCK

    set value of lhTableUpdateParameters item TUPD_UNLOCK_COUNT to (value(oFrm(oLockMode(lhGrp)),0))
  end_procedure

  function sTableName returns string
    string lsFileName
    get value of (oRootName(oGrp2(self))) item 0 to lsFileName
    if (lsFileName<>"") begin
      if (SEQ_FileExists(lsFileName)=SEQIT_FILE) begin
        ifnot (DBMS_CanOpenFileAs(lsFileName,37)) begin
          move "" to lsFileName
          send obs "Table can not be opened" ("("+lsFileName+")")
        end
      end
      else begin
        move "" to lsFileName
        send obs "Table not found" ("("+lsFileName+")")
      end
    end
    function_return lsFileName
  end_function
  function sFileName returns string
    string lsFileName
    get value of (oInputFile(oGrp1(self))) item 0 to lsFileName
    if (lsFileName<>"") begin
      if (SEQ_FileExists(lsFileName)<>SEQIT_FILE) begin
        move "" to lsFileName
        send obs "File not found" ("("+lsFileName+")")
      end
    end
    function_return lsFileName
  end_function

  send aps_size_identical_max (oGrp1(self)) (oGrp2(self)) SL_HORIZONTAL
  send aps_size_identical_max (oGrp2(self)) (oGrp3(self)) SL_HORIZONTAL
  send aps_align_inside_container_by_moving (oLockMode(oGrp3(self))) SL_ALIGN_RIGHT
  procedure DoFieldMap
    integer lhMapper liOpen
    string lsFileName lsTableName
    // First we setup the SEQ file mapper
    get sFileName to lsFileName
    if (lsFileName="") begin
      send obs "Input file not found"
      procedure_return
    end
    send DoSetup to (oTextDataReader(self)) lsFileName
    send DoTransferToMapableObject to (oTextDataReader(self)) (oFileMapObject(self))
    // Then we setup the table object
    get sTableName to lsTableName
    if (lsTableName="") begin
      send obs "Table not found"
      procedure_return
    end

    move (DBMS_OpenFileAs(lsTableName,37,DF_SHARE,0)) to liOpen
    ifnot liOpen begin
      send obs "Table could not be opened"
      procedure_return
    end

    send Read_File_Definition.i to (oTableFDX(self)) 37

    send DoTransferToMapableObject to (oTableFDX(self)) (oTableMapObject(self))

    move (oMapper(self)) to lhMapper
    send DoMapperDialog "Field map" lhMapper "" "" ""
  end_procedure

  Procedure DoDefaults
    Integer iTable hDefaultValues liCanOpen
    String sFileName

    Get Value of oRootName to sFileName
    
    Move 37 to iTable
    Close iTable
    Move (DBMS_OpenFileAs(sFileName,iTable,DF_SHARE,0)) to liCanOpen
    If liCanopen Begin
        Move (oTableDefaultValues(Self)) to hDefaultValues
        Send PopupDefaultValues of oImportDataDefaultValuesPanel iTable hDefaultValues
    End
    Close 37
  End_Procedure

  function sConfigurationFileName returns string
    string lsFileName lsExt
    get sFileName to lsFileName
    if (lsFileName<>"") begin
      get SEQ_ExtractExtensionFromFileName lsFileName to lsExt
      if (lsExt<>"") move (StringLeftBut(lsFileName,length(lsExt))) to lsFileName
      else move (lsFileName+".") to lsFileName
      move (lsFileName+"icf") to lsFileName
    end
    function_return lsFileName
  end_function

  procedure DoSaveDialogValues
    string lsConfFile
    get sConfigurationFileName to lsConfFile
    send obs "Config file:" lsConfFile
  end_procedure
  procedure DoOpenDialogValues
  end_procedure

  procedure DoImportFile
    integer lhMapper liOpen
    string lsFileName lsTableName
    // First we setup the SEQ file mapper
    get sFileName to lsFileName
    if (lsFileName="") begin
      send obs "Input file not found"
      procedure_return
    end
    send DoSetup to (oTextDataReader(self)) lsFileName
////    send DoTransferToMapableObject to (oTextDataReader(self)) (oFileMapObject(self))
    // Then we setup the table object
    get sTableName to lsTableName
    if (lsTableName="") begin
      send obs "Table not found"
      procedure_return
    end

    move (DBMS_OpenFileAs(lsTableName,37,DF_SHARE,0)) to liOpen
    ifnot liOpen begin
      send obs "Table could not be opened"
      procedure_return
    end
    send DoTransferDialogToTableUpdParameters
    // Until this point its been identical to top of DoFieldMap procedure
    send DoUpdate to (oTableUpdater(self)) lsFileName lsTableName
  end_procedure

  on_key KEY_CTRL+KEY_S send DoSaveDialogValues
  on_key KEY_CTRL+KEY_O send DoOpenDialogValues

  object oBtn1 is a aps.multi_button
    on_item "Field map" send DoFieldMap
  end_object
  object oBtn2 is a aps.multi_button
    on_item "Default values" send DoDefaults
  end_object
  object oBtn3 is a aps.multi_button
    on_item "Read data" send DoImportFile
  end_object
  object oBtn4 is a aps.multi_button
    on_item "Cancel"    send Close_Panel
  end_object
  send aps_locate_multi_buttons
end_object
