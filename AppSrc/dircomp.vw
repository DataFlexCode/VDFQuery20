// Use DirComp.vw   // Activate_Dircomp_Vw

/DirComp.Vw.Intro
 $Title$ Comparing directory contents

 With this utility you may compare two folders. Either or both
 folders may be updated with the newest version of each file.

 This function is a stand-alone utility that does not interact with any
 other functions in DFMatrix. Consequently, it does not care what you
 have loaded in the table selector, or which work space (VDF) you may
 have selected.

/*

Use DirComp.pkg  // List class for comparing directory contents (cDirCompList)
Use Files.utl    // Utilities for handling file related stuff
Use Spec0011.utl // Floating menues on the fly
Use API_Attr.utl // Functions for querying API attributes
Use WildCard.pkg // vdfq_WildCardMatch function

activate_view Activate_Dircomp_Vw for oDirComp_Vw
object oDirComp_Vw is a aps.View label "Compare directory contents (based on file time stamps)"
  set p_auto_column to 1
  on_key kcancel send close_panel
  register_object oDir2
  on_key kuser send DoDoubleTSE
  object oSetOfMasks is a cSetOfMasks
    set psName to "File masks, comparing folders"
  end_object

  procedure DoSetFilter
    send DoEditSetOfMasks (oSetOfMasks(self))
  end_procedure

  object oDir1 is a aps.SelectDirForm label "Left directory:" abstract AFT_ASCII80
    set p_extra_internal_width to -100
    set value item 0 to (API_OtherAttr_Value(OA_WORKDIR))
    procedure next
      send activate to (oDir2(self))
    end_procedure
  end_object
  register_object oLst
  register_object oBtn1
  object oToleranceButton is a aps.Button snap SL_RIGHT_SPACE
    on_item "Tolerance" send DoSetTimeTolerance to (oLst(self))
  end_object
  object oDir2 is a aps.SelectDirForm label "Right directory:" abstract AFT_ASCII80
    set p_extra_internal_width to -100
    procedure OnSetFocus
      if (value(self,0)="") set value item 0 to (value(oDir1(self),0))
    end_procedure
    procedure next
      send activate to (oBtn1(self))
    end_procedure
  end_object
  object oFilterButton is a aps.Button snap SL_RIGHT_SPACE
    on_item "Filter" send DoSetFilter to (oLst(self))
  end_object
  set p_auto_column to 0
  send aps_goto_max_row
  send aps_make_row_space 4
  object oTxt1 is a aps.TextBox label ""
    set fixed_size to 10 100
    set Fontweight to 900
    set justification_mode to JMODE_LEFT
  end_object
  object oTxtLeft is a aps.TextBox label ""
    set fixed_size to 10 200
    set Fontweight to 900
    set justification_mode to JMODE_LEFT
  end_object
  object oTxtRight is a aps.TextBox label ""
    set fixed_size to 10 200
    set Fontweight to 900
    set justification_mode to JMODE_LEFT
  end_object
  send aps_goto_max_row
  object oLst is a cDirCompList
    set size to 150 0
  end_object
  set location of (oTxtLeft(self)) to (hi(location(oTxtLeft(self)))) (aps_grid_column_start(self,oLst(self),1))
  set location of (oTxtRight(self)) to (hi(location(oTxtRight(self))))  (aps_grid_column_start(self,oLst(self),3))
  procedure DoDoubleTSE
    integer lhArray liRow lhLst liBase
    string lsPath1 lsPath2 lsFileName lsCommand
    // Deep at the heart of this is a global array called oDirectoryCompareArray:
    move (oDirectoryCompareArray(self)) to lhArray
    move (oLst(self)) to lhLst

    if (item_count(lhLst)) begin
      // We start by figuring out which row in that array we should examine:
      get Grid_BaseItem lhLst to liBase
      get aux_value of lhLst item liBase to liRow

      get psPath1 of lhArray to lsPath1
      get psPath2 of lhArray to lsPath2
      get psFileName.i of lhArray liRow to lsFileName

      get Files_AppendPath lsPath1 lsFileName to lsPath1
      get Files_AppendPath lsPath2 lsFileName to lsPath2

      if (pos(" ",lsPath1)) move ('"'+lsPath1+'"') to lsPath1
      if (pos(" ",lsPath2)) move ('"'+lsPath2+'"') to lsPath2

      move "e.exe %1 %2" to lsCommand

      move (replace("%1",lsCommand,lsPath1)) to lsCommand
      move (replace("%2",lsCommand,lsPath2)) to lsCommand

      send obs lsCommand
//      runprogram wait lsCommand
//      runprogram BACKGROUND lsCommand

    end
  end_procedure
  procedure DoShowChanges
    set value of (oTxt1(self)) to " Changes only:"
    send fill_list.i to (oLst(self)) 1
  end_procedure
  procedure DoShowAll
    set value of (oTxt1(self)) to " All files:"
    send fill_list.i to (oLst(self)) 0
  end_procedure
  procedure DoCompare
    string sPath1 sPath2
    get value of (oDir1(self)) to sPath1
    get value of (oDir2(self)) to sPath2
    if (SEQ_FileExists(sPath1)) eq SEQIT_DIRECTORY begin
      if (SEQ_FileExists(sPath2)) eq SEQIT_DIRECTORY begin
        if (lowercase(sPath1)<>lowercase(sPath2)) begin
          send cursor_wait to (cursor_control(self))
          set value of (oTxtLeft(self)) to (" "+SEQ_TranslatePathToAbsolute(sPath1))
          set value of (oTxtRight(self)) to (" "+SEQ_TranslatePathToAbsolute(sPath2))
          send DirComp_DoCompare sPath1 sPath2 (oSetOfMasks(self))
          set value of (oTxt1(self)) to " All files:"
          send fill_list.i to (oLst(self)) 0
          send cursor_ready to (cursor_control(self))
        end
        else send obs "You can't compare a directory to itself"
      end
      else send obs "Directory not found!" ("("+sPath2+")")
    end
    else send obs "Directory not found!" ("("+sPath1+")")
  end_procedure
  object oBtn1 is a aps.Multi_Button
    on_item "Refresh" send DoCompare
  end_object
  object oBtn2 is a aps.Multi_Button
    procedure PopupFM
      send FLOATMENU_PrepareAddItem msg_DoShowChanges "Changes only"
      send FLOATMENU_PrepareAddItem msg_DoShowAll     "Show all"
      send popup to (FLOATMENU_Apply(self))
    end_procedure
    on_item "Show" send PopupFM
  end_object
  procedure DoCopyNew
    send DoCopyNew to (oLst(self))
  end_procedure
  procedure DoCopyLeft
    send DoCopyLeft to (oLst(self))
  end_procedure
  procedure DoCopyRight
    send DoCopyRight to (oLst(self))
  end_procedure
  procedure DoCopyAdvanced
    send DoCopyAdvanced to (oLst(self))
  end_procedure
  object oBtn3 is a aps.Multi_Button
    procedure PopupFM
      send FLOATMENU_PrepareAddItem msg_DoCopyNew      "Copy newer file"
      send FLOATMENU_PrepareAddItem msg_DoCopyLeft     "Copy left to right"
      send FLOATMENU_PrepareAddItem msg_DoCopyRight    "Copy right to left"
      send FLOATMENU_PrepareAddItem msg_none           ""
      send FLOATMENU_PrepareAddItem msg_DoCopyAdvanced "Advanced"
      send popup to (FLOATMENU_Apply(self))
    end_procedure
    on_item "Copy file" send PopupFM
  end_object
  object oBtn4 is a aps.Multi_Button
    on_item "Close" send close_panel
  end_object
  send aps_locate_multi_buttons
  set Border_Style to BORDER_THICK   // Make panel resizeable
  procedure aps_onResize integer delta_rw# integer delta_cl#
    send aps_resize (oLst(self)) delta_rw# 0 // delta_cl#
    send aps_register_multi_button (oBtn1(self))
    send aps_register_multi_button (oBtn2(self))
    send aps_register_multi_button (oBtn3(self))
    send aps_register_multi_button (oBtn4(self))
    send aps_locate_multi_buttons
    send aps_auto_size_container
  end_procedure
end_object
