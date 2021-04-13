Use StrucTrc.utl // Object for tracing a restructure operation

// 2013/10/27 Updated according til WvA's message: http://support.dataaccess.com/Forums/showthread.php?54843-DFMatrix-save-rst-trace-file-as-text&p=285202#post285202


activate_view Activate_RestructureTracer for oRestructureTracer
object oRestructureTracer is a aps.View label "Trace restructure operation"
  set Border_Style to BORDER_THICK   // Make panel resizeable
  on_key kcancel send close_panel
  object oLst is a cRSTraceList
    on_key kenter send display_definition
    set size to 150 400
  end_object
  object oBtn0 is a aps.Multi_Button // Wil
    on_item "Save trace as txt" send save_txt_trace to (oLst(self))
  end_object
  object oBtn1 is a aps.Multi_Button
    on_item "Load trace" send load_trace to (oLst(self))
  end_object
  object oBtn2 is a aps.Multi_Button
    on_item t.btn.close send close_panel
  end_object
  send aps_locate_multi_buttons
  procedure aps_onResize integer delta_rw# integer delta_cl#
    send aps_resize (oLst(self)) delta_rw# 0
    send aps_register_multi_button (oBtn1(self))
    send aps_register_multi_button (oBtn2(self))
    send aps_locate_multi_buttons
    send aps_auto_size_container
  end_procedure
// procedure popup
//   send fill_list to (oLst(self))
//   forward send popup
// end_procedure
end_object

procedure Activate_RestructureTracer_With_File string fn#
  send load_trace_file to (oFdxTraceArray(self)) fn#
  send fill_list to (oLst(oRestructureTracer(self)))
  send popup to (oRestructureTracer(self))
  send activate_scope to (oRestructureTracer(self))
end_procedure
