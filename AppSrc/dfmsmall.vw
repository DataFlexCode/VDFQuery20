Use aps.pkg      // Auto Positioning and Sizing classes for VDF
Use Buttons.utl  // Button texts
Use GridUtil.utl // Grid and List utilities (not for dbGrid's or Table's)
Use Collate.nui

activate_view Activate_SmallDfmThings_Vw for oSmallDfmThings_Vw
object oSmallDfmThings_Vw is a aps.View label "Miscellaneous"
  on_key KCANCEL send close_panel
  object oTabs is a aps.TabDialog
    object oTab1 is a aps.TabPage label "Collate sequence"
      set p_auto_column to FALSE
      object oTestArray is a cCollateArray
        send fill_current_sort_order
      end_object
      object oLst is a aps.Grid
        send GridPrepare_AddColumn "Order"     AFT_ASCII5
        send GridPrepare_AddColumn "ASCII"     AFT_ASCII5
        send GridPrepare_AddColumn "Character" AFT_ASCII5
        send GridPrepare_AddColumn "Uppercase" AFT_ASCII5
        send GridPrepare_Apply self
        set select_mode to NO_SELECT
        on_key KNEXT_ITEM send switch
        on_key KPREVIOUS_ITEM send switch_back
        procedure fill_list
          integer lhObj liMax liItem
          set dynamic_update_state to DFFALSE
          send delete_data
          move (oTestArray(self)) to lhObj
          get item_count of lhObj to liMax
          decrement liMax
          for liItem from 0 to liMax
            send add_item msg_none (string(liItem+1))
            send add_item msg_none (ascii(value(lhObj,liItem)))
            send add_item msg_none (value(lhObj,liItem))
            send add_item msg_none (uppercase(value(lhObj,liItem)))
          loop
          send Grid_SetEntryState self DFFALSE
          set dynamic_update_state to DFTRUE
        end_procedure
        send fill_list
        on_key KEY_CTRL+KEY_R send sort_data
        on_key KEY_CTRL+KEY_W send DoWriteToFile
        procedure DoWriteToFile
          send Grid_DoWriteToFile self
        end_procedure

        function iSpecialSortValueOnColumn.i integer column# returns integer
          if column# eq 0 function_Return 1
          if column# eq 1 function_Return 1
        end_function

        function sSortValue.ii integer column# integer itm# returns string
          if column# eq 0 function_return (IntToStrR(value(self,itm#),3))
          if column# eq 1 function_return (IntToStrR(value(self,itm#),3))
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
      end_object // oLst
    end_object
  end_object
  object oBtn is a aps.Multi_Button
    on_item t.btn.close send close_panel
  end_object
  send aps_locate_multi_buttons
  set Border_Style to BORDER_THICK   // Make panel resizeable
  procedure aps_onResize integer delta_rw# integer delta_cl#
    send aps_resize (oTabs(self)) delta_rw# 0 // delta_cl#
    send aps_resize (oLst(oTab1(oTabs(self)))) delta_rw# 0 // delta_cl#
    send aps_register_multi_button (oBtn(self))
    send aps_locate_multi_buttons
    send aps_auto_size_container
  end_procedure
end_object
