// Dims, der kan lave hul i b‘lter
//
//
//
// Am7    Dm7    G7    Cmaj/C7
// Fmaj7  Bm7b5  G7    Am/A7
// Dm7    G7     Cmaj  Gm7/A7
// Dm7    G7     Cmaj  Dm7b5/E7

// Am7    Dm7    G7    Cmaj/C7
// Fmaj7  Bm7b5  G7    Am/A7
// Dm7    G7     Em7   A7
// Dm7    G7     Cmaj  Dm7b5/E7

use aps.pkg
use pkgdoc.nui
use setdir.pkg   // cSetOfDirectories class
use Masks_DF.nui // DataFlex related file masks

object oPkgDocSetOfDirectories is a cSetOfDirectories 
  object oWait is a cProcessStatusPanel
    set allow_cancel_state to DFFALSE
  end_object
  procedure OnWait_On string lsCaption
    set caption_text of (oWait(self)) to lsCaption
    set title_text   of (oWait(self)) to ""
    set message_text of (oWait(self)) to ""
    set action_text  of (oWait(self)) to ""
    send Start_StatusPanel to (oWait(self))
  end_procedure
  procedure OnWait_SetText1 string lsValue
    set Message_Text of (oWait(self)) to lsValue
  end_procedure
  procedure OnWait_SetText2 string lsValue
    set Action_Text of (oWait(self)) to lsValue
  end_procedure
  procedure OnWait_Off
    send Stop_StatusPanel to (oWait(self))
  end_procedure
end_object

object oPkgDocSetOfFiles is a cSetOfFilesNew
  set piSOD_Object to (oPkgDocSetOfDirectories(self))
end_object

activate_view Popup_PkgDoc_View for oPkgDoc_View
object oPkgDoc_View is a aps.View label "Document your source code"
   set Border_Style to BORDER_THICK   // Make panel resizeable
   object oDirLstHeader is a aps.Textbox label "Folders in search path:"
   end_object
   object oDirLst is a cSetOfDirectoriesList snap SL_DOWN
     set size to 70 0
     set peAnchors to (anLeft+anRight+anTop)
     set peResizeColumn to rcSelectedColumn // Resize mode (rcAll or rcSelectedColumn)
     set piResizeColumn to 0                // This is the column to resize
     set piSetOfDirectoriesObject to (oPkgDocSetOfDirectories(self))
     register_object oDirLstTotal
     set Horz_Scroll_Bar_Visible_State to false

     procedure OnListChanged integer liItems
       set value of (oDirLstTotal(self)) to ("  "+string(liItems)+" folders")
     end_procedure
   end_object
   object oDirLstTotal is a aps.Textbox label "  0 folders         "
     set peAnchors to (anRight+anTop)
   end_object

   procedure DoAddOne
     send DoAddDirectory to (oDirLst(self))
   end_procedure
   procedure DoAddSub
     send DoAddSubDirectories to (oDirLst(self))
   end_procedure
   procedure DoMakePath
     integer lhoWorkSpace
     string lsPath
     get_profile_string "DfComp" "MakePath" to lsPath
#IFDEF get_DFMatrix_WorkSpaceLoaded
     if (DFMatrix_WorkSpaceLoaded()) begin
       get phoWorkspace of ghoApplication To lhoWorkSpace
       move (psAppSrcPath(lhoWorkSpace)+";"+psProgramPath(lhoWorkSpace)+";"+psDataPath(lhoWorkSpace)+";"+psDdSrcPath(lhoWorkSpace)+";"+psHelpPath(lhoWorkSpace)+";"+psSystemMakePath(lhoWorkSpace)) to lsPath
     end
#ENDIF
     send DoAddSearchPath to (oDirLst(self)) lsPath
   end_procedure
   procedure DoDFPath
     integer lhoWorkSpace
     string lsPath
#IFDEF get_DFMatrix_WorkSpaceLoaded
     get phoWorkspace of ghoApplication To lhoWorkSpace
     if (DFMatrix_WorkSpaceLoaded()) move (psDfPath(lhoWorkSpace)) to lsPath
     else move (API_AttrValue_GLOBAL(DF_OPEN_PATH)) to lsPath // Oem fixed!
     move (ToOem(lsPath)) to lsPath
#ELSE
     move (API_AttrValue_GLOBAL(DF_OPEN_PATH)) to lsPath
#ENDIF
     send DoAddSearchPath to (oDirLst(self)) lsPath
   end_procedure
   send DoDFPath // Default value
   procedure DoPath
     send DoAddSearchPath to (oDirLst(self)) (API_OtherAttr_Value(OA_PATH))
   end_procedure
   procedure DoReset
     send DoReset to (oDirLst(self))
   end_procedure
   object oDirBtn1 is a aps.Button snap SL_RIGHT relative_to (oDirLst(self))
     set peAnchors to (anRight+anTop)
     set size to 14 70
     procedure PopupFM
       send FLOATMENU_PrepareAddItem msg_DoAddOne   "One folder"
       send FLOATMENU_PrepareAddItem msg_DoAddSub   "Sub-folders"
       send FLOATMENU_PrepareAddItem msg_DoMakePath "MakePath"
       send FLOATMENU_PrepareAddItem msg_DoDFPath   "DFPath"
       send FLOATMENU_PrepareAddItem msg_DoPath     "EXE search path"
       send FLOATMENU_PrepareAddItem msg_none       ""
       send FLOATMENU_PrepareAddItem msg_DoReset    "Reset list"
       send popup to (FLOATMENU_Apply(self))
     end_procedure
     on_item "Add folders" send PopupFM
   end_object
   object oDirBtn2 is a aps.Button snap SL_DOWN
     set peAnchors to (anRight+anTop)
     set size to 14 70
     on_item "Remove from list" send DoRemoveDirectory to (oDirLst(self))
   end_object
   object oDirBtn3 is a aps.Button snap SL_DOWN
     set peAnchors to (anRight+anTop)
     set size to 14 70
     on_item "Reset list" send DoReset
   end_object

   send aps_goto_max_row
   object oFrm is a aps.Form abstract AFT_ASCII80 label "Search file:"
     set p_extra_internal_width to -340
     on_key kenter send goto_search_button
     set peAnchors to (anLeft+anRight+anTop)
   end_object
   object oFindBtn1 is a aps.Button snap SL_RIGHT
     set size to 14 30
     on_item "Find" send DoFindFile
     set peAnchors to (anRight+anTop)
   end_object
   object oFindBtn2 is a aps.Button snap SL_RIGHT_SPACE
     set peAnchors to (anRight+anTop)
     set size to 14 70
     register_procedure DoFindDFSource
     register_procedure DoFindDFData
     register_procedure DoFindDFRuntime
     register_procedure DoFindDFAll
     procedure PopupFM
       send FLOATMENU_PrepareAddItem msg_DoFindDFSource  "DF source code"
       send FLOATMENU_PrepareAddItem msg_DoFindDFData    "DF data files"
       send FLOATMENU_PrepareAddItem msg_DoFindDFRuntime "DF runtime files"
       send FLOATMENU_PrepareAddItem msg_DoFindDFAll     "All DF files"
       send popup to (FLOATMENU_Apply(self))
     end_procedure
     on_item "Find all source" send PopupFM
   end_object
   procedure goto_search_button
     send activate to (oFindBtn1(self))
   end_procedure
   object oFindBtn3 is a aps.Button snap SL_RIGHT
     set peAnchors to (anRight+anTop)
     set size to 14 70
     on_item "Scan PR? file" send DoFindPrnFile
   end_object
   object oFirstOccuranceOnly is a aps.CheckBox label "1st occur. only" snap SL_RIGHT_SPACE
     set peAnchors to (anRight+anTop)
     set checked_state to true
     set enabled_state to false
   end_object
   procedure DoFindFile
     integer lbFirstOnly
     string lsFileMask
     get value of (oFrm(self)) item 0 to lsFileMask
     if (lsFileMask<>"") begin
       get select_state of (oFirstOccuranceOnly(self)) to lbFirstOnly
       send DoFindFile to (oPkgDocSetOfFiles(self)) lsFileMask lbFirstOnly
       send Update_ResultList
     end
     else begin
       send obs "You must enter a file name before finding."
       send activate to (oFrm(self))
     end
   end_procedure
   procedure DoFindDFSource
     integer lbFirstOnly
     get select_state of (oFirstOccuranceOnly(self)) to lbFirstOnly
     send DoFindFileBySetOfMasks to (oPkgDocSetOfFiles(self)) (oSetOfMasks_DFSource(self)) lbFirstOnly
     send Update_ResultList
   end_procedure
   procedure DoFindDFData
     integer lbFirstOnly
     get select_state of (oFirstOccuranceOnly(self)) to lbFirstOnly
     send DoFindFileBySetOfMasks to (oPkgDocSetOfFiles(self)) (oSetOfMasks_DFData(self)) lbFirstOnly
     send Update_ResultList
   end_procedure
   procedure DoFindDFRuntime
     integer lbFirstOnly
     get select_state of (oFirstOccuranceOnly(self)) to lbFirstOnly
     send DoFindFileBySetOfMasks to (oPkgDocSetOfFiles(self)) (oSetOfMasks_DFRuntime(self)) lbFirstOnly
     send Update_ResultList
   end_procedure
   procedure DoFindDFAll
     integer lbFirstOnly
     get select_state of (oFirstOccuranceOnly(self)) to lbFirstOnly
     send DoFindFileBySetOfMasks to (oPkgDocSetOfFiles(self)) (oSetOfMasks_DFAll(self)) lbFirstOnly
     send Update_ResultList
   end_procedure
   procedure DoFindPrnFile
     integer lbFirstOnly
     string lsPrnFile
     get SEQ_SelectFile "Select compiler listing file" "Compiler listing (*.prn)|*.PRN|Precompile listing (*.prp)|*.PRP" to lsPrnFile
     if lsPrnFile ne "" begin
       get select_state of (oFirstOccuranceOnly(self)) to lbFirstOnly
       send DoFindFilesCompilerListing to (oPkgDocSetOfFiles(self)) lsPrnFile lbFirstOnly
       send Update_ResultList
     end
   end_procedure
   procedure aps_beautify
//     send aps_align_by_moving (oFrm(self)) (oDirLst(self)) SL_ALIGN_RIGHT
     send aps_align_by_moving (oDirLstTotal(self)) (oDirLst(self)) SL_ALIGN_BOTTOM
   end_procedure

   send aps_goto_max_row
   send aps_make_row_space 5
   object oDirLstHeader is a aps.Textbox label "Source files to be documented:"
   end_object

   send aps_goto_max_row
   object oResultList is a cSetOfFilesListNew
     set peAnchors to (anTop+anLeft+anRight+anBottom)
     set peResizeColumn to rcSelectedColumn // Resize mode (rcAll or rcSelectedColumn)
     set piResizeColumn to 4                // This is the column to resize
     set size to 100 0
     set piSOF_Object to (oPkgDocSetOfFiles(self))
     set aps_fixed_column_width item 4 to 200
     procedure OnListFilled integer liFileCount number lnBytes
       send total_display (SEQ_FileSizeToString(lnBytes)+" in "+string(liFileCount)+" files")
     end_procedure
     procedure DoReset
       forward send DoReset
//       send Activate_SetDirTestVw
     end_procedure
   end_object
   send aps_goto_max_row

   object oSelectTxt is a aps.TextBox
   end_object
   set auto_size_state of (oSelectTxt(self)) to DFTRUE
   procedure total_display string lsValue
     set value of (oSelectTxt(self)) to lsValue
   end_procedure
   object oBtn1 is a aps.Multi_Button
     set peAnchors to (anRight+anBottom)
     on_item "Reset list" send DoReset to (oResultList(self))
   end_object
   object oBtn2 is a aps.Multi_Button
     set peAnchors to (anRight+anBottom)
     on_item "Copy files" send DoCopyFilesToDirectory to (oResultList(self))
   end_object
   object oBtn3 is a aps.Multi_Button
     set peAnchors to (anRight+anBottom)
     on_item t.btn.close send close_panel
   end_object
   send aps_locate_multi_buttons

   procedure Update_ResultList
   end_procedure
end_object // oPkgDoc_View

send aps_SetMinimumDialogSize (oPkgDoc_View(self)) // Set minimum size
