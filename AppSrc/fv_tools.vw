Use ToolUtilities.pkg // aps.YellowBox class
Use Files.utl    // Utilities for handling file related stuff

//class aps.YellowText is a aps.Edit
//  procedure construct_object
//    forward send construct_object
//    set object_shadow_state to true
//    set border_style to BORDER_NONE
//    set color to (RGB_Brighten(clYellow,75))
//    set scroll_bar_visible_state to false
//    property integer private.piImage 0
//  end_procedure
//  procedure set piImage integer liImg
//    string lsText
//    set private.piImage to liImg
//    if liImg get sTextFromDfImage liImg to lsText
//    else move "" to lsText
//    send Text_SetEditObjectValue self lsText
//  end_procedure
//end_class // aps.YellowText

/FvTool01.Description.01
Save definitions of the currently opened tables to a file. Such a file is called a FDX file (for File Definition, eXtended).

Such a file may be opened in the DFMatrix program for further processing (and that's about the only thing it can be used for).
/*
activate_view activate_fvtool_01 for oFV_Tool_01_View
object oFV_Tool_01_View is a aps.View label "Save snap shot of table definitions (FDX file)"
//  set Border_Style to BORDER_THICK   // Make panel resizeable
  on_key kCancel send close_panel
  object oDescription is a aps.YellowBox
    set peAnchors to (anRight+anLeft+anTop)
    set size to 60 200
    set piTextSourceImage to FvTool01.Description.01.N
  end_object


  procedure DoSave
    string lsFile lsPath
    get FastView_HomeDirectory to lsPath
    get SEQ_SelectOutFileStartDir "Save FDX file" "FDX files|*.fdx" lsPath to lsFile
    if (lsFile<>"") begin
      send FV_FastLoadRefresh
      send cursor_wait to (cursor_control(self))
      send FDXGL_WriteFile lsFile
      send cursor_ready to (cursor_control(self))
      send obs "FDX file has been saved!" ("("+lsFile+")")
      send close_panel
    end
  end_procedure

  object oBtn1 is a aps.Multi_Button
    on_item "Save" send DoSave
    set peAnchors to (anRight+anBottom)
  end_object
  object oBtn2 is a aps.Multi_Button
    on_item "Cancel" send close_panel
    set peAnchors to (anRight+anBottom)
  end_object
  send aps_locate_multi_buttons
end_object
send aps_SetMinimumDialogSize (oFV_Tool_01_View(self))



