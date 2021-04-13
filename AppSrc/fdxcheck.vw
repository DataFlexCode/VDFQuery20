// Use FdxCheck.vw  // View for interfacing validity check of table definitions

Use FdxCheck.pkg // Classes for displaying validity check of table definitions

register_object oGrp
register_object oFrm_ErrorText
object oFdxCheck_Vw is a aps.View label "Check definitions"
  property integer piDoRunOnActivate 0
  on_key KCANCEL send close_panel
  object oLst is a cFdxCheckErrorList
    procedure OnErrorChange string full_error_text# integer error_class#
      set value of (oFrm_ErrorText(oGrp(self))) item 0 to full_error_text#
      set label of (oFrm_ErrorText(oGrp(self))) to (sErrorClassText.i(self,error_class#)+":")
    end_procedure
    procedure update_display_counter integer errors# integer warnings# string detail_level_text#
      string str#
      move "# error(s) and # warning(s), displaying #" to str#
      replace "#" in str# with errors#
      replace "#" in str# with warnings#
      replace "#" in str# with (lowercase(detail_level_text#))
      send UpdateTotal str#
    end_procedure
  end_object
  object oTotal is a aps.TextBox snap SL_DOWN
    set fixed_size to 0 200
    set auto_size_state to DFFALSE
    set Justification_Mode to JMODE_LEFT
  end_object
  procedure UpdateTotal string str#
    set label of (oTotal(self)) to str#
  end_procedure
  object oGrp is a aps.Group label "Current error info" snap SL_DOWN
    object oFrm_ErrorText is a aps.Form abstract AFT_ASCII60 label "Error:"
      set enabled_state to DFFALSE
      Set Fontweight to 900
    end_object
  end_object
  send aps_align_by_sizing (oGrp(self)) (oLst(self)) SL_ALIGN_RIGHT
  procedure update_display
    integer iObj
    move (oFdxCheck(self)) to iObj
    send fill_list.i to (oLst(self)) iObj
  end_procedure

  procedure Callback_Filelist_Entry integer file# integer selected# integer shaded#
    send DoFdxCheckTable (fdx.object_id(0)) file#
  end_procedure

  procedure DoRun
    integer select_count#
    send cursor_wait to (cursor_control(self))
    send DoFdxCheckReset
    send DFMatrix_CallBack_Selected_Files msg_Callback_Filelist_Entry self -1 0 1 // Selected=Dont care, shaded=0, master tables only
    send update_display
    send cursor_ready to (cursor_control(self))
  end_procedure

  procedure OnChangeFDX_Broadcasted
    set delegation_mode to DELEGATE_TO_PARENT
    if (active_state(self)) send DoRun
    else set piDoRunOnActivate to DFTRUE
  end_procedure

  procedure DoDisplayDefinitionFromCheckView
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
  object oBtn1 is a aps.Multi_Button
    on_item "Show &definition" send DoDisplayDefinitionFromCheckView
  end_object
  object oBtn2 is a aps.Multi_Button
    on_item "Severity level" send Toggle_DetailLevel to (oLst(self))
  end_object
  object oBtn3 is a aps.Multi_Button
    on_item "Close" send close_panel
  end_object
  send aps_locate_multi_buttons
  set Border_Style to BORDER_THICK   // Make panel resizeable
  procedure aps_onResize integer delta_rw# integer delta_cl#
    send aps_resize (oLst(self)) delta_rw# 0 // delta_cl#
    send aps_auto_locate_control (oTotal(self)) SL_DOWN
    send aps_auto_locate_control (oGrp(self)) SL_DOWN
    send aps_register_multi_button (oBtn1(self))
    send aps_register_multi_button (oBtn2(self))
    send aps_register_multi_button (oBtn3(self))
    send aps_locate_multi_buttons
    send aps_auto_size_container
  end_procedure
  procedure popup
    forward send popup
    if (piDoRunOnActivate(self)) send DoRun
    set piDoRunOnActivate to DFFALSE
  end_procedure
end_object // oFdxCheck_Vw

procedure Activate_FdxCheck_Vw
  send popup to (oFdxCheck_Vw(self))
end_procedure
