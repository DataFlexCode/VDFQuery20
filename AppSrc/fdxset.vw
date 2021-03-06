// Use FDXSet.vw    // Display contents of cSetOfFiles cSetOfFields
Use FdxSet.pkg   // cFdxSetOfFieldsList class
Use FdxSet.nui   // cFdxSetOfFiles, cSetOfFields, cSetOfIndices
Use FdxSelct.utl // Functions iFdxSelectOneFile and iFdxSelectOneField
Use API_Attr.pkg // UI objects for use with API_Attr.utl
Use DfmPrint.utl // Classes for printing DFMatrix reports.  

class cFdxSetReport is a cDFMatrixSimpleReport
  procedure construct_object integer img#
    forward send construct_object img#
    property integer piSOT_Server 0
  end_procedure
  procedure DoReport
  end_procedure
  procedure run
    set piFDX_Server to (piFDX_Server(piSOT_Server(self)))
    if (iStartReport(self)) begin
      send DoReport
      send EndReport
    end
  end_procedure
end_class // cFdxSetReport

/FdxSetTableReport.hdr
       # Display name                   DF name         Root name
/FdxSetTableReport.body
    ___. ______________________________ _______________ _______________
/*
class cFdxSetTableReport is a cFdxSetReport
  procedure construct_object integer img#
    forward send construct_object img#
    set psTitle to "Set of tables"
  end_procedure
  procedure DoReport
    integer oFDX# oSOT# max# row# file#
    send obs "DoReport"
    get piSOT_Server to oSOT#
    get piFDX_Server of oSOT# to oFDX#
    set pSubHeader_image  of seq.object# to FdxSetTableReport.hdr.N
    set pSubHeader_height of seq.object# to FdxSetTableReport.hdr.LINES
    get row_count of oSOT# to max#
    for row# from 0 to (max#-1)
      get piFile.i of oSOT# row# to file#
      print file# to FdxSetTableReport.body.1
      print (FDX_AttrValue_FILELIST(oFDX#,DF_FILE_DISPLAY_NAME,file#)) to FdxSetTableReport.body.2
      print (FDX_AttrValue_FILELIST(oFDX#,DF_FILE_LOGICAL_NAME,file#)) to FdxSetTableReport.body.3
      print (FDX_AttrValue_FILELIST(oFDX#,DF_FILE_ROOT_NAME,file#))    to FdxSetTableReport.body.4
      send obs "Before output"
      seq.output FdxSetTableReport.body
      send obs "After output"
    loop
    send obs "End-DoReport"
  end_procedure
end_class // cFdxSetTableReport


enumeration_list // Database meta entities
  define DME_TABLE
  define DME_FIELD
  define DME_INDEX
end_enumeration_list

function sDME_Title.i global integer dme# returns string
  if dme# eq DME_TABLE function_return "Select tables"
  if dme# eq DME_FIELD function_return "Select fields"
  if dme# eq DME_INDEX function_return "Select indices"
end_function

Use APS.pkg      // Auto Positioning and Sizing classes for VDF
Use Buttons.utl  // Button texts
object oFdxSetAttributeSelector is a aps.ModalPanel label ""
  set locate_mode to CENTER_ON_SCREEN
  on_key ksave_record send close_panel_ok
  on_key kcancel send close_panel
  property integer piResult 0
  set p_auto_column to 1
  object oAttribute is a Api_Attr.ComboFormAux label "Attribute"
    set form_margin item 0 to 20
    procedure OnChange
      send DoUpdate (Combo_Current_Aux_Value(self))
    end_procedure
  end_object
  object oComperator is a Api_Attr.ComboFormAux label "Comperator"
    set form_margin item 0 to 2
  end_object
  object oDiscreteValue is a Api_Attr.ComboFormAux label "Discrete value"
    set form_margin item 0 to 20
  end_object
  object oUserValue is a aps.Form label "User value"
    set form_margin item 0 to 20
  end_object
  procedure DoUpdate integer attr#
    send prepare_comparison_modes to (oComperator(self)) attr#
    send prepare_attr_values to (oDiscreteValue(self)) attr#
    if (API_AttrDiscreteValues(attr#)) begin
      set object_shadow_state of (oDiscreteValue(self)) to false
      set object_shadow_state of (oUserValue(self)) to true
      set value of (oUserValue(self)) item 0 to ""
    end
    else begin
      set object_shadow_state of (oDiscreteValue(self)) to true
      set object_shadow_state of (oUserValue(self)) to false
    end
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
  function iPopup.i integer dme# returns integer
    set piResult to 0
    set label to (sDME_Title.i(dme#))
    send Combo_Delete_Data to (oAttribute(self))
    send Combo_Delete_Data to (oComperator(self))
    send Combo_Delete_Data to (oDiscreteValue(self))
    if dme# eq DME_TABLE begin
      send fill_list_attrtype to (oAttribute(self)) ATTRTYPE_FILELIST
      send fill_list_attrtype to (oAttribute(self)) ATTRTYPE_FILE
    end
    if dme# eq DME_FIELD begin
      send fill_list_attrtype to (oAttribute(self)) ATTRTYPE_FIELD
    end
    if dme# eq DME_INDEX begin
      send fill_list_attrtype to (oAttribute(self)) ATTRTYPE_INDEX
      send fill_list_attrtype to (oAttribute(self)) ATTRTYPE_IDXSEG
    end
    send DoUpdate (Combo_Current_Aux_Value(oAttribute(self)))
    send popup
    function_return (piResult(self))
  end_function
end_object // oFdxSetAttributeSelector

object oSelectAttributesContainer is a cArray
  object oSetOfTables is a cFdxSetOfTables 
    set psTitle to "Table search result"
  end_object
  object oSetOfFields is a cFdxSetOfFields 
    set psTitle to "Field search result"
  end_object
  object oSetOfIndices is a cFdxSetOfIndices 
    set psTitle to "Index search result"
  end_object
  procedure PopupSelector integer dme#
    integer rval# set# attr# comp# panel#
    string value#
    move (oFdxSetAttributeSelector(self)) to panel#
    if dme# eq DME_TABLE move (oSetOfTables(self)) to set#
    if dme# eq DME_FIELD move (oSetOfFields(self)) to set#
    if dme# eq DME_INDEX move (oSetOfIndices(self)) to set#
    get iPopup.i of panel# dme# to rval#
    if rval# begin
      set piFDX_Server of set# to (fdx.object_id(0))
      set piTestAttribute of set# to (iAttribute(panel#))
      set piTestCompMode  of set# to (iComperator(panel#))
      set psTestValue     of set# to (sValue(panel#))
      send Traverse_All to set#
      if dme# eq DME_TABLE send Display_FdxSetOfTables set#
      if dme# eq DME_FIELD send Display_FdxSetOfFields set#
      if dme# eq DME_INDEX send Display_FdxSetOfIndices set#
    end
  end_procedure
end_object // oSelectAttributesContainer

procedure PopupFdxTableSearch
  send PopupSelector to (oSelectAttributesContainer(self)) DME_TABLE
end_procedure
procedure PopupFdxFieldSearch
  send PopupSelector to (oSelectAttributesContainer(self)) DME_FIELD
end_procedure
procedure PopupFdxIndicesSearch
  send PopupSelector to (oSelectAttributesContainer(self)) DME_INDEX
end_procedure

object oSelectFieldsAdvanced is a aps.ModalPanel label "Select 'connected' fields"
  set locate_mode to CENTER_ON_SCREEN
  property integer piField 0
  property integer piFile  0
  on_key ksave_record send close_panel_ok
  on_key kcancel send close_panel
  property integer piResult 0
  object oFrm is a aps.Form abstract AFT_ASCII30 label "Select fields connected to:"
    on_key kprompt send prompt
    set entry_state item 0 to false
    procedure prompt
      integer file# field# oFDX#
      get piFile to file#
      get piField to field#
      move (fdx.object_id(0)) to oFDX#
      get iFdxSelectOneField oFDX# 0 (file#*65536+field#) to field#
      if field# begin
        move (field#/65536) to file#
        move (field#-(file#*65536)) to field#
        set value item 0 to (FDX_FieldName(oFDX#,file#,field#,1))
        set piFile to file#
        set piField to field#
      end
    end_procedure
  end_object
  object oBtn1 is a aps.Multi_Button
    on_item t.btn.ok send close_panel_ok
  end_object
  object oBtn2 is a aps.Multi_Button
    on_item t.btn.prompt send prompt to (oFrm(self))
  end_object
  object oBtn3 is a aps.Multi_Button
    on_item t.btn.cancel send close_panel
  end_object
  send aps_locate_multi_buttons
  procedure close_panel_ok
    set piResult to 1
    send close_panel
  end_procedure
  function iPopup returns integer
    set piResult to 0
    send popup
    function_return (piResult(self) and piFile(self))
  end_function
end_object // oSelectFieldsAdvanced

object oSetOfFields is a cFdxSetOfFields 
  set psTitle to "Advanced search result"
  procedure PopupAdv
    integer rval# panel# co#
    set piFDX_Server to (fdx.object_id(0))
    move (oSelectFieldsAdvanced(self)) to panel#
    get iPopup of panel# to rval#
    if rval# begin
      send Traverse_ConnectedFields (piFile(panel#)) (piField(panel#))
      move self to co#
      send Display_FdxSetOfFields co#
    end
  end_procedure
end_object // oSetOfFields

procedure Popup_SelectFieldsAdvanced
  if (DFMatrix_Primary_Origin()) ne FDX_EMPTY send PopupAdv to (oSetOfFields(self))
end_procedure

register_object oTxt
object oFdxSetOfTables_Vw is a aps.View label "Set of tables"
  set Border_Style to BORDER_THICK   // Make panel resizeable
  on_key kcancel send close_panel
  on_key kprompt send DoSelect
  on_key kclear  send DoReset
  object oLst is a cFdxSetOfTablesList
    set piAllowDelete to dfTrue
    set size to 180 0
    procedure update_display_counter integer files#
      string str#
      if files# move (string(files#)+" tables") to str#
      else move "(empty)" to str#
      move (RightShift(str#,30)) to str#
      set value of (oTxt(self)) item 0 to str#
    end_procedure
  end_object
  object oTxt is a aps.TextBox snap SL_DOWN
  end_object
  set auto_size_state of (oTxt(self)) to true
  object oBtn1 is a aps.Multi_Button
    on_item "Select tables" send DoSelect
  end_object
  object oBtn2 is a aps.Multi_Button
    on_item "Export" send DoExport
  end_object
  object oBtn3 is a aps.Multi_Button
    on_item t.btn.reset  send DoReset
  end_object
  object oBtn4 is a aps.Multi_Button
    on_item t.btn.close  send close_panel
  end_object
  send aps_locate_multi_buttons
  object oReport is a cFdxSetTableReport
    procedure run
      set piSOT_Server to (piSOT_Server(oLst(self)))
      forward send run
    end_procedure
  end_object
  procedure DoPrint
    send run to (oReport(self))
  end_procedure
  procedure DoExport
    send PopupFdxSetExport WAY_SET_OF_TABLES_VW
  end_procedure
  procedure DoSelect
    send PopupFdxTableSearch
  end_procedure
  procedure DoReset
    send reset to (oFdxSetOfTables(self))
    send update_display
  end_procedure
  procedure aps_onResize integer delta_rw# integer delta_cl#
    send aps_resize (oLst(self)) delta_rw# 0
    send aps_auto_locate_control (oTxt(self)) sl_down (oLst(self))
    send aps_align_inside_container_by_moving (oTxt(self)) SL_ALIGN_CENTER
    send aps_register_multi_button (oBtn1(self))
    send aps_register_multi_button (oBtn2(self))
    send aps_register_multi_button (oBtn3(self))
    send aps_register_multi_button (oBtn4(self))
    send aps_locate_multi_buttons
    send aps_auto_size_container
  end_procedure
  procedure update_display
    send fill_list.i to (oLst(self)) (oFdxSetOfTables(self))
  end_procedure
  procedure OnChangeFdx
    send reset to (oFdxSetOfTables(self))
    send update_display
  end_procedure
  procedure aps_beautify
    send aps_align_inside_container_by_moving (oTxt(self)) SL_ALIGN_CENTER
  end_procedure
  send DFMatrix_Vw_Register WAY_SET_OF_TABLES_VW self
end_object // oFdxSetOfTables_Vw

procedure Activate_SetOfTables
  send popup to (oFdxSetOfTables_Vw(self))
end_procedure

register_object oTxt
object oFdxSetOfTablesModal is a aps.ModalPanel
  set locate_mode to CENTER_ON_SCREEN
  set Border_Style to BORDER_THICK   // Make panel resizeable
  on_key kcancel send close_panel
  on_key ksave_record send none
  on_key key_ctrl+key_u send DoUnion
  on_key key_ctrl+key_i send DoIntersection
  property integer piFdxSetOfTables 0
  object oLst is a cFdxSetOfTablesList
    set size to 180 0
    procedure update_display_counter integer files#
      string str#
      if files# move (string(files#)+" tables") to str#
      else move "" to str#
      move (RightShift(str#,30)) to str#
      set value of (oTxt(self)) item 0 to str#
    end_procedure
  end_object
  object oTxt is a aps.TextBox snap SL_DOWN
  end_object
  set auto_size_state of (oTxt(self)) to true
  object oBtn1 is a aps.Multi_Button
    on_item "Union"        send DoUnion
  end_object
  object oBtn2 is a aps.Multi_Button
    on_item "Intersection" send DoIntersection
  end_object
  object oBtn3 is a aps.Multi_Button
    on_item "Complement"   send DoComplement
  end_object
  object oBtn4 is a aps.Multi_Button
    on_item t.btn.cancel send close_panel
  end_object
  send aps_locate_multi_buttons
  procedure DoIntersection
    send DoIntersection.i to (oFdxSetOfTables(self)) (piFdxSetOfTables(self))
    send update_display to (oFdxSetOfTables_Vw(self))
    send close_panel
  end_procedure
  procedure DoUnion
    send DoUnion.i to (oFdxSetOfTables(self)) (piFdxSetOfTables(self))
    send update_display to (oFdxSetOfTables_Vw(self))
    send close_panel
  end_procedure
  procedure DoComplement
    send DoComplement.i to (oFdxSetOfTables(self)) (piFdxSetOfTables(self))
    send update_display to (oFdxSetOfTables_Vw(self))
    send close_panel
  end_procedure
  procedure update_display integer oFdxSetOfTables#
    set label to (psTitle(oFdxSetOfTables#))
    set piFdxSetOfTables to oFdxSetOfTables#
    send fill_list.i to (oLst(self)) oFdxSetOfTables#
  end_procedure
  procedure aps_onResize integer delta_rw# integer delta_cl#
    send aps_resize (oLst(self)) delta_rw# 0
    send aps_auto_locate_control (oTxt(self)) sl_down (oLst(self))
    send aps_align_inside_container_by_moving (oTxt(self)) SL_ALIGN_CENTER
    send aps_register_multi_button (oBtn1(self))
    send aps_register_multi_button (oBtn2(self))
    send aps_register_multi_button (oBtn3(self))
    send aps_register_multi_button (oBtn4(self))
    send aps_locate_multi_buttons
    send aps_auto_size_container
  end_procedure
  procedure aps_beautify
    send aps_align_inside_container_by_moving (oTxt(self)) SL_ALIGN_CENTER
  end_procedure
end_object

procedure Display_FdxSetOfTables global integer oFdxSetOfTables#
  send update_display to (oFdxSetOfTablesModal(self)) oFdxSetOfTables#
  send popup to (oFdxSetOfTablesModal(self))
end_procedure

register_object oTxt
object oFdxSetOfFields_Vw is a aps.View label "Set of fields"
  set Border_Style to BORDER_THICK   // Make panel resizeable
  on_key kcancel send close_panel
  on_key kprompt send DoSelect
  on_key kclear  send DoReset
  object oLst is a cFdxSetOfFieldsList
    set piAllowDelete to dfTrue
    set size to 180 0
    procedure update_display_counter integer files# integer fields#
      string str#
      if fields# move (string(fields#)+" fields from "+string(files#)+" tables") to str#
      else move "(empty)" to str#
      move (RightShift(str#,30)) to str#
      set value of (oTxt(self)) item 0 to str#
    end_procedure
  end_object
  object oTxt is a aps.TextBox snap SL_DOWN
  end_object
  set auto_size_state of (oTxt(self)) to true
  object oBtn1 is a aps.Multi_Button
    on_item "Select fields" send DoSelect
  end_object
  object oBtn2 is a aps.Multi_Button
    on_item "Spec. select"  send Popup_SelectFieldsAdvanced
  end_object
  object oBtn3 is a aps.Multi_Button
    on_item "Export" send DoExport
  end_object
  object oBtn4 is a aps.Multi_Button
    on_item t.btn.reset  send DoReset
  end_object
  object oBtn5 is a aps.Multi_Button
    on_item t.btn.close  send close_panel
  end_object
  send aps_locate_multi_buttons
  procedure DoExport
    send PopupFdxSetExport WAY_SET_OF_FIELDS_VW
  end_procedure
  procedure DoSelect
    send PopupFdxFieldSearch
  end_procedure
  procedure DoReset
    send reset to (oFdxSetOfFields(self))
    send update_display
  end_procedure
  procedure DoPrint
  end_procedure
  procedure aps_onResize integer delta_rw# integer delta_cl#
    send aps_resize (oLst(self)) delta_rw# 0
    send aps_auto_locate_control (oTxt(self)) sl_down (oLst(self))
    send aps_align_inside_container_by_moving (oTxt(self)) SL_ALIGN_CENTER
    send aps_register_multi_button (oBtn1(self))
    send aps_register_multi_button (oBtn2(self))
    send aps_register_multi_button (oBtn3(self))
    send aps_register_multi_button (oBtn4(self))
    send aps_register_multi_button (oBtn5(self))
    send aps_locate_multi_buttons
    send aps_auto_size_container
  end_procedure
  procedure update_display
    send fill_list.i to (oLst(self)) (oFdxSetOfFields(self))
  end_procedure
  procedure OnChangeFdx
    send reset to (oFdxSetOfFields(self))
    send update_display
  end_procedure
  procedure aps_beautify
    send aps_align_inside_container_by_moving (oTxt(self)) SL_ALIGN_CENTER
  end_procedure
  send DFMatrix_Vw_Register WAY_SET_OF_FIELDS_VW self
end_object // oFdxSetOfFields_Vw

procedure Activate_SetOfFields
  send popup to (oFdxSetOfFields_Vw(self))
end_procedure

register_object oTxt
object oFdxSetOfFieldsModal is a aps.ModalPanel
  set locate_mode to CENTER_ON_SCREEN
  set Border_Style to BORDER_THICK   // Make panel resizeable
  on_key kcancel send close_panel
  on_key ksave_record send none
  on_key key_ctrl+key_u send DoUnion
  on_key key_ctrl+key_i send DoIntersection
  property integer piFdxSetOfFields 0
  object oLst is a cFdxSetOfFieldsList
    set size to 180 0
    procedure update_display_counter integer files# integer fields#
      string str#
      if fields# move (string(fields#)+" fields from "+string(files#)+" tables") to str#
      else move "" to str#
      move (RightShift(str#,30)) to str#
      set value of (oTxt(self)) item 0 to str#
    end_procedure
  end_object
  object oTxt is a aps.TextBox snap SL_DOWN
  end_object
  set auto_size_state of (oTxt(self)) to true
  object oBtn1 is a aps.Multi_Button
    on_item "Union"        send DoUnion
  end_object
  object oBtn2 is a aps.Multi_Button
    on_item "Intersection" send DoIntersection
  end_object
  object oBtn3 is a aps.Multi_Button
    on_item "Complement"   send DoComplement
  end_object
  object oBtn4 is a aps.Multi_Button
    on_item t.btn.cancel send close_panel
  end_object
  send aps_locate_multi_buttons
  procedure DoIntersection
    send DoIntersection.i to (oFdxSetOfFields(self)) (piFdxSetOfFields(self))
    send update_display to (oFdxSetOfFields_Vw(self))
    send close_panel
  end_procedure
  procedure DoUnion
    send DoUnion.i to (oFdxSetOfFields(self)) (piFdxSetOfFields(self))
    send update_display to (oFdxSetOfFields_Vw(self))
    send close_panel
  end_procedure
  procedure DoComplement
    send DoComplement.i to (oFdxSetOfFields(self)) (piFdxSetOfFields(self))
    send update_display to (oFdxSetOfFields_Vw(self))
    send close_panel
  end_procedure
  procedure update_display integer oFdxSetOfFields#
    set label to (psTitle(oFdxSetOfFields#))
    set piFdxSetOfFields to oFdxSetOfFields#
    send fill_list.i to (oLst(self)) oFdxSetOfFields#
  end_procedure
  procedure aps_onResize integer delta_rw# integer delta_cl#
    send aps_resize (oLst(self)) delta_rw# 0
    send aps_auto_locate_control (oTxt(self)) sl_down (oLst(self))
    send aps_align_inside_container_by_moving (oTxt(self)) SL_ALIGN_CENTER
    send aps_register_multi_button (oBtn1(self))
    send aps_register_multi_button (oBtn2(self))
    send aps_register_multi_button (oBtn3(self))
    send aps_register_multi_button (oBtn4(self))
    send aps_locate_multi_buttons
    send aps_auto_size_container
  end_procedure
  procedure aps_beautify
    send aps_align_inside_container_by_moving (oTxt(self)) SL_ALIGN_CENTER
  end_procedure
end_object

procedure Display_FdxSetOfFields global integer oFdxSetOfFields#
  send update_display to (oFdxSetOfFieldsModal(self)) oFdxSetOfFields#
  send popup to (oFdxSetOfFieldsModal(self))
end_procedure

register_object oTxt
object oFdxSetOfIndices_Vw is a aps.View label "Set of Indices"
  set Border_Style to BORDER_THICK   // Make panel resizeable
  on_key kcancel send close_panel
  on_key kprompt send DoSelect
  on_key kclear  send DoReset
  object oLst is a cFdxSetOfIndicesList
    set piAllowDelete to dfTrue
    set size to 180 0
    procedure update_display_counter integer files# integer indices#
      string str#
      if indices# move (string(indices#)+" Indices in "+string(files#)+" tables") to str#
      else move "(empty)" to str#
      move (RightShift(str#,30)) to str#
      set value of (oTxt(self)) item 0 to str#
    end_procedure
  end_object
  object oTxt is a aps.TextBox snap SL_DOWN
  end_object
  set auto_size_state of (oTxt(self)) to true
  object oBtn1 is a aps.Multi_Button
    on_item "Select Indices" send DoSelect
  end_object
  object oBtn2 is a aps.Multi_Button
    on_item "Export" send DoExport
  end_object
  object oBtn3 is a aps.Multi_Button
    on_item t.btn.reset  send DoReset
  end_object
  object oBtn4 is a aps.Multi_Button
    on_item t.btn.close  send close_panel
  end_object
  send aps_locate_multi_buttons
  procedure DoExport
    send PopupFdxSetExport WAY_SET_OF_INDICES_VW
  end_procedure
  procedure DoSelect
    send PopupFdxIndicesSearch
  end_procedure
  procedure DoReset
    send reset to (oFdxSetOfIndices(self))
    send update_display
  end_procedure
  procedure DoPrint
  end_procedure
  procedure aps_onResize integer delta_rw# integer delta_cl#
    send aps_resize (oLst(self)) delta_rw# 0
    send aps_auto_locate_control (oTxt(self)) sl_down (oLst(self))
    send aps_align_inside_container_by_moving (oTxt(self)) SL_ALIGN_CENTER
    send aps_register_multi_button (oBtn1(self))
    send aps_register_multi_button (oBtn2(self))
    send aps_register_multi_button (oBtn3(self))
    send aps_register_multi_button (oBtn4(self))
    send aps_locate_multi_buttons
    send aps_auto_size_container
  end_procedure
  procedure update_display
    send fill_list.i to (oLst(self)) (oFdxSetOfIndices(self))
  end_procedure
  procedure OnChangeFdx
    send reset to (oFdxSetOfIndices(self))
    send update_display
  end_procedure
  procedure aps_beautify
    send aps_align_inside_container_by_moving (oTxt(self)) SL_ALIGN_CENTER
  end_procedure
  send DFMatrix_Vw_Register WAY_SET_OF_INDICES_VW self
end_object // oFdxSetOfIndices_Vw

register_object oTxt
object oFdxSetOfIndicesModal is a aps.ModalPanel
  set locate_mode to CENTER_ON_SCREEN
  set Border_Style to BORDER_THICK   // Make panel resizeable
  on_key kcancel send close_panel
  on_key ksave_record send none
  on_key key_ctrl+key_u send DoUnion
  on_key key_ctrl+key_i send DoIntersection
  property integer piFdxSetOfIndices 0
  object oLst is a cFdxSetOfIndicesList
    set size to 180 0
    procedure update_display_counter integer files# integer indices#
      string str#
      if indices# move (string(indices#)+" Indices in "+string(files#)+" tables") to str#
      else move "" to str#
      move (RightShift(str#,30)) to str#
      set value of (oTxt(self)) item 0 to str#
    end_procedure
  end_object
  object oTxt is a aps.TextBox snap SL_DOWN
  end_object
  set auto_size_state of (oTxt(self)) to true
  object oBtn1 is a aps.Multi_Button
    on_item "Union"        send DoUnion
  end_object
  object oBtn2 is a aps.Multi_Button
    on_item "Intersection" send DoIntersection
  end_object
  object oBtn3 is a aps.Multi_Button
    on_item "Complement"   send DoComplement
  end_object
  object oBtn4 is a aps.Multi_Button
    on_item t.btn.cancel send close_panel
  end_object
  send aps_locate_multi_buttons
  procedure DoIntersection
    send DoIntersection.i to (oFdxSetOfIndices(self)) (piFdxSetOfIndices(self))
    send update_display to (oFdxSetOfIndices_Vw(self))
    send close_panel
  end_procedure
  procedure DoUnion
    send DoUnion.i to (oFdxSetOfIndices(self)) (piFdxSetOfIndices(self))
    send update_display to (oFdxSetOfIndices_Vw(self))
    send close_panel
  end_procedure
  procedure DoComplement
    send DoComplement.i to (oFdxSetOfIndices(self)) (piFdxSetOfIndices(self))
    send update_display to (oFdxSetOfIndices_Vw(self))
    send close_panel
  end_procedure
  procedure update_display integer oFdxSetOfIndices#
    set label to (psTitle(oFdxSetOfIndices#))
    set piFdxSetOfIndices to oFdxSetOfIndices#
    send fill_list.i to (oLst(self)) oFdxSetOfIndices#
  end_procedure
  procedure aps_onResize integer delta_rw# integer delta_cl#
    send aps_resize (oLst(self)) delta_rw# 0
    send aps_auto_locate_control (oTxt(self)) sl_down (oLst(self))
    send aps_align_inside_container_by_moving (oTxt(self)) SL_ALIGN_CENTER
    send aps_register_multi_button (oBtn1(self))
    send aps_register_multi_button (oBtn2(self))
    send aps_register_multi_button (oBtn3(self))
    send aps_register_multi_button (oBtn4(self))
    send aps_locate_multi_buttons
    send aps_auto_size_container
  end_procedure
  procedure aps_beautify
    send aps_align_inside_container_by_moving (oTxt(self)) SL_ALIGN_CENTER
  end_procedure
end_object

procedure Display_FdxSetOfIndices global integer oFdxSetOfIndices#
  send update_display to (oFdxSetOfIndicesModal(self)) oFdxSetOfIndices#
  send popup to (oFdxSetOfIndicesModal(self))
end_procedure

procedure Activate_SetOfIndices
  send popup to (oFdxSetOfIndices_Vw(self))
end_procedure

Use APS.pkg      // Auto Positioning and Sizing classes for VDF
Use Buttons.utl  // Button texts
object oFdxSetTransfer is a aps.ModalPanel label "Export set to"
  set locate_mode to CENTER_ON_SCREEN
  on_key kcancel send close_panel
  property integer piOrigin 0
  property integer piResult 0
  object oRadio is a aps.RadioContainer
    object oRad1 is a aps.Radio label "Table selector"
    end_object
    object oRad2 is a aps.Radio label "Set of tables" snap sl_right_space
    end_object
    object oRad3 is a aps.Radio label "Set of fields" snap sl_right_space
    end_object
  end_object
  object oBtn1 is a aps.Multi_Button
    on_item "Union" send close_panel_ok1
  end_object
  object oBtn2 is a aps.Multi_Button
    on_item "Intersection" send close_panel_ok2
  end_object
  object oBtn3 is a aps.Multi_Button
    on_item t.btn.cancel send close_panel
  end_object
  send aps_locate_multi_buttons
  function private.target returns integer
    if (current_radio(oRadio(self))) eq 0 function_return WAY_TABLE_SELECTOR_VW
    if (current_radio(oRadio(self))) eq 1 function_return WAY_SET_OF_TABLES_VW
    if (current_radio(oRadio(self))) eq 2 function_return WAY_SET_OF_FIELDS_VW
  end_function
  procedure DoUnion
    send DFMatrix_Transfer_Set (piOrigin(self)) (private.target(self)) 0
  end_procedure
  procedure DoIntersection
    send DFMatrix_Transfer_Set (piOrigin(self)) (private.target(self)) 1
  end_procedure
  procedure DoPrepare.i integer origin#
    integer rad#
    set piOrigin to origin#
    move (oRadio(self)) to rad#
    set current_radio of rad# to 0
    set object_shadow_state of (oRad2(rad#)) to false
    set object_shadow_state of (oRad3(rad#)) to false
    if origin# eq WAY_SET_OF_TABLES_VW begin
      set object_shadow_state of (oRad2(rad#)) to true
      set object_shadow_state of (oRad3(rad#)) to true
    end
    if origin# eq WAY_SET_OF_FIELDS_VW begin
      set object_shadow_state of (oRad3(rad#)) to true
    end
  end_procedure
  procedure close_panel_ok1
    set piResult to 1
    send close_panel
  end_procedure
  procedure close_panel_ok2
    set piResult to 2
    send close_panel
  end_procedure
  procedure popup
    set piResult to 0
    forward send popup
    if (piResult(self)) eq 1 send DoUnion
    if (piResult(self)) eq 2 send DoIntersection
  end_procedure
end_object // oFdxSetTransfer

procedure PopupFdxSetExport global integer origin#
  send DoPrepare.i to (oFdxSetTransfer(self)) origin#
  send popup to (oFdxSetTransfer(self))
end_procedure

