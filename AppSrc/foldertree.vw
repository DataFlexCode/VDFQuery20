// use foldertree.pkg // cFolderTree class
use foldertree.nui // cFolderTree class
//************************************************************************************

use treenode_treeview_class.pkg // cTreeNodeView class
Use Files.utl    // Utilities for handling file related stuff
Use Dates.nui    // Date routines (No User Interface)
use Strings.nui  // String manipulation for VDF (No User Interface)
Use HTML.utl     // HTML functions
Use GridUtil.utl // Grid and List utilities (not for dbGrid's or Table's)

object oFolderSizeTree is a cFolderTree
end_object

object oFolderSizeArray is a cArray
  item_property_list
    item_property string   psName.i
    // On its own:
    item_property integer  piFiles.i
    item_property number   pnSize.i
    item_property number   pnMinSz.i
    item_property number   pnMaxSz.i
    item_property number   pnOlder.i
    item_property number   pnNewer.i
  end_item_property_list
  procedure AddToArray integer lhData integer lbIncludeSubFolders
    integer liRow
    get row_count to liRow
    set psName.i   liRow to (value(lhData,FLDS_FOLDER_NAME_PATH))

    if lbIncludeSubFolders begin
      set piFiles.i liRow to (value(lhData,FLDSX_FILE_COUNT))
      set pnSize.i  liRow to (value(lhData,FLDSX_FOLDER_SIZE))
      set pnMinSz.i liRow to (value(lhData,FLDSX_MIN_FILESZ))
      set pnMaxSz.i liRow to (value(lhData,FLDSX_MAX_FILESZ))
      set pnOlder.i liRow to (value(lhData,FLDSX_MIN_TIME))
      set pnNewer.i liRow to (value(lhData,FLDSX_MAX_TIME))
    end
    else begin
      set piFiles.i  liRow to (value(lhData,FLDS_FILE_COUNT))
      set pnSize.i   liRow to (value(lhData,FLDS_FOLDER_SIZE))
      set pnMinSz.i  liRow to (value(lhData,FLDS_MIN_FILESZ))
      set pnMaxSz.i  liRow to (value(lhData,FLDS_MAX_FILESZ))
      set pnOlder.i  liRow to (value(lhData,FLDS_MIN_TIME))
      set pnNewer.i  liRow to (value(lhData,FLDS_MAX_TIME))
    end
  end_procedure
end_object

object oFolderSizeGridPanel is a aps.ModalPanel label "Folder sizes (expanded as in tree view)"
  set locate_mode to CENTER_ON_SCREEN
  set Border_Style to BORDER_THICK   // Make panel resizeable
  on_key kcancel send close_panel
  object oGrid is a aps.Grid
    set size to 200 0
    set peAnchors to (anTop+anLeft+anRight+anBottom)
    set peResizeColumn to rcSelectedColumn // Resize mode (rcAll or rcSelectedColumn)
    set piResizeColumn to 0                // This is the column to resize
    set select_mode to NO_SELECT
    send GridPrepare_AddColumn "Folder"             AFT_ASCII40
    send GridPrepare_AddColumn "Files"              AFT_NUMERIC6.0
    send GridPrepare_AddColumn "Folder size"        AFT_ASCII8
    send GridPrepare_AddColumn "Largest file"       AFT_ASCII8
    send GridPrepare_AddColumn "Most recent update" AFT_ASCII20
    send GridPrepare_Apply self
    on_key kEnter send DoExplorer

    procedure mouse_click integer liItem integer liGrb
      if ((liItem-1)<item_count(self)) send DoExplorer
    end_procedure

    function iSpecialSortValueOnColumn.i integer liColumn returns integer
      if (liColumn>0) function_Return 1
    end_function

    function sSortValue.ii integer liColumn integer liItem returns string
      integer liRow liBase lhArray
      number lnValue
      if (liColumn>0) begin
        move (oFolderSizeArray(self)) to lhArray
        get Grid_ItemBaseItem self liItem to liBase
        get aux_value item liBase to liRow
        if (liColumn=1) get piFiles.i of lhArray liRow to lnValue
        if (liColumn=2) get pnSize.i  of lhArray liRow to lnValue
        if (liColumn=3) get pnMaxSz.i of lhArray liRow to lnValue
        if (liColumn=4) get pnNewer.i of lhArray liRow to lnValue
        function_return (IntToStrR(lnValue,14))
      end
    end_function

    procedure sort_data.i integer liColumn
      send Grid_SortByColumn self liColumn
    end_procedure

    procedure sort_data
      integer liCurrentColumn
      get Grid_CurrentColumn self to liCurrentColumn
      send sort_data.i liCurrentColumn
    end_procedure
    procedure header_mouse_click integer liItem
      send sort_data.i liItem
      forward send header_mouse_click liItem
    end_procedure

    procedure fill_list
      integer lhArray liMax liRow lbSubFoldersIncluded liBase
      integer liFiles
      number lnSz lnMinSz lnMaxSz lnMinTime lnMaxTime
      move (oFolderSizeArray(self)) to lhArray
      set dynamic_update_state to false
      send delete_data
      get row_count of lhArray to liMax
      decrement liMax
      for liRow from 0 to liMax
        get item_count to liBase
        send add_item MSG_NONE (psName.i(lhArray,liRow))
        set aux_value item liBase to liRow
        get piFiles.i of lhArray liRow to liFiles
        get pnSize.i  of lhArray liRow to lnSz
        get pnMinSz.i of lhArray liRow to lnMinSz
        get pnMaxSz.i of lhArray liRow to lnMaxSz
        get pnOlder.i of lhArray liRow to lnMinTime
        get pnNewer.i of lhArray liRow to lnMaxTime
        send add_item MSG_NONE liFiles
        if liFiles begin
          send add_item MSG_NONE (replace(",",SEQ_FileSizeToString(lnSz),"."))
          send add_item MSG_NONE (replace(",",SEQ_FileSizeToString(lnMaxSz),"."))
          send add_item MSG_NONE (TS_ConvertToString(lnMaxTime))
        end
        else begin
          send add_item MSG_NONE ""
          send add_item MSG_NONE ""
          send add_item MSG_NONE ""
        end
      loop
      send Grid_SetEntryState self false
      set dynamic_update_state to true
    end_procedure
  end_object
  procedure DoExplorer
    integer liBase
    string lsPath
    get Grid_BaseItem oGrid to liBase
    get value of oGrid item liBase to lsPath
    send html_StartDoc lsPath
  end_procedure
  procedure DoWriteToFile
    send Grid_DoWriteToFile (oGrid(self))
  end_procedure
  on_key KEY_CTRL+KEY_W send DoWriteToFile
  object oBtn1 is a aps.Multi_Button
    set size to 14 50
    on_item "Explorer" send DoExplorer
    set peAnchors to (anBottom+anRight)
  end_object
  object oBtn2 is a aps.Multi_Button
    on_item "Write to file" send DoWriteToFile
    set peAnchors to (anBottom+anRight)
  end_object
  object oBtn3 is a aps.Multi_Button
    set size to 14 40
    on_item "Close" send close_panel
    set peAnchors to (anBottom+anRight)
  end_object
  send aps_locate_multi_buttons
  procedure popup
    send fill_list of oGrid
    forward send popup
  end_procedure
end_object // oFolderSizeGridPanel
send aps_SetMinimumDialogSize (oFolderSizeGridPanel(self)) // Set minimum size

object oFolderSizeTreePanel is a aps.View label "Explore folder size"
  set Border_Style to BORDER_THICK   // Make panel resizeable
  on_key kcancel send close_panel

  object oTree is a aps.TreeNodeView
    set peAnchors to (anTop+anLeft+anRight+anBottom)
    set size to 200 310
    set phTreeNode to (oFolderSizeTree(self))

    Object oImageList is a cImageList
      Set piMaxImages To 3
      Procedure OnCreate // add the images
        Integer iImage
        Get AddTransparentImage 'closfold.bmp' clFuchsia To iImage
        Get AddTransparentImage 'openfold.bmp' clFuchsia To iImage
      End_Procedure
    End_Object
    Set ImageListObject To (oImageList(self))

    function iImageItems integer lhData returns integer // complex hi: "Image" low: "Selected Image"
      function_return (1*65536+0)
    end_function

    procedure DoGotoTop
      send DoMakeItemVisible (RootItem(self))
    end_procedure

    procedure DoReset
      send DoDeleteItem (RootItem(self))
      send DoDeleteItem 0
    end_procedure

              function hDataObject integer lhItem returns integer
                integer lhNode lhData
                get ItemData lhItem to lhNode
                if lhNode begin
                  get phDataObject of lhNode to lhData
                end
                else move 0 to lhData
                function_return lhData
              end_function

    procedure OnItemCollapsed handle lhItem
      integer lhData
      string lsValue
      get hDataObject lhItem to lhData
      get FolderTree_DataTreeLabel lhData false to lsValue
      set ItemLabel lhItem to lsValue
    end_procedure
    procedure OnItemExpanded handle lhItem
      integer lhData
      string lsValue
      get hDataObject lhItem to lhData
      get FolderTree_DataTreeLabel lhData true to lsValue
      set ItemLabel lhItem to lsValue
    end_procedure
    procedure OnItemChanging handle lhItem handle lhOldItem
      integer lhData
      get hDataObject lhItem to lhData
      send ItemInfo_Display lhData
    end_procedure

    function hCurrentDataObject returns integer
      integer lhItem
      get CurrentTreeItem to lhItem
      if lhItem function_return (hDataObject(self,lhItem))
      function_return 0
    end_function

              procedure ExportDataToArray_Help integer lhItem integer liLevel
                integer lbVisible lhData lbExpanded lbExpandable
                get ItemVisibleState lhItem to lbVisible
                if lbVisible begin
                  get hDataObject lhItem to lhData
                  if lhData begin
                    get ItemChildCount lhItem to lbExpandable
                    if lbExpandable move (ItemExpandedState(self,lhItem)) to lbExpanded
                    else move 1 to lbExpanded
                    send AddToArray of oFolderSizeArray lhData (not(lbExpanded))
                  end
                end
              end_procedure
    procedure ExportDataToArray
      send delete_data of oFolderSizeArray
      send DoEnumerateTree MSG_ExportDataToArray_Help (RootItem(self)) 0
//      send DoEnumerateTree MSG_ExportDataToArray_Help (CurrentTreeItem(self)) 0
    end_procedure
  end_object // oTree

  procedure OnReadFolder string lsParentFolder string lsFolder
    set Message_Text of ghoStatusPanel to lsParentFolder
    set Action_Text  of ghoStatusPanel to lsFolder
  end_procedure

  procedure ItemInfo_Display integer lhData
    //send DoUpdate of oGroup lhData
  end_procedure

  property string psFolder ""

            procedure DoReadFolder string lsFolder
              set label to ("Explore folder size ("+lsFolder+")")
              set psFolder to lsFolder

              send FolderTreeSetup_Reset

              set FolderTreeSetup_Value FTSU_READ_FOLDER_CB_OBJECT  to self
              set FolderTreeSetup_Value FTSU_READ_FOLDER_CB_MESSAGE to MSG_OnReadFolder

              set Caption_Text of ghoStatusPanel to ("Reading "+lsFolder)
              send Start_StatusPanel of ghoStatusPanel
              set allow_cancel_state of ghoStatusPanel to FALSE

              send DoReset of oFolderSizeTree
              send DoReset of oTree
              send build_folder_tree of oFolderSizeTree lsFolder

              send Stop_StatusPanel of ghoStatusPanel

              send OnCreateTree of oTree
              send DoGotoTop of oTree
              send activate of oTree
            end_procedure

  procedure DoNewFolder
    string lsFolder
    get SEQ_SelectDirectory "Select folder" to lsFolder
    if (lsFolder<>"") send DoReadFolder lsFolder
  end_procedure

  procedure DoRefresh
    string lsFolder
    get psFolder to lsFolder
    if (lsFolder<>"") send DoReadFolder lsFolder
    else send obs "Folder has not been selected"
  end_procedure


  procedure DoExpandLevel
    integer lhItem lhOrigItem lhData
    string lsFolder lsPath lsValue
    get psFolder to lsFolder
    if (lsFolder<>"") begin
      get CurrentTreeItem of oTree to lhItem
      move lhItem to lhOrigItem
      if lhItem begin
        send DoExpandItem of oTree lhItem
             // Otherwise the labels wont reflect it:
             get hDataObject of oTree lhItem to lhData
             get FolderTree_DataTreeLabel lhData TRUE to lsValue
             set ItemLabel of oTree lhItem to lsValue
        get ChildItem of oTree lhItem to lhItem
        while lhItem
          send DoCollapseItem of oTree lhItem
               // Otherwise the labels wont reflect it:
               get hDataObject of oTree lhItem to lhData
               get FolderTree_DataTreeLabel lhData FALSE to lsValue
               set ItemLabel of oTree lhItem to lsValue
          get NextSiblingItem of oTree lhItem to lhItem
        end
        send DoMakeItemVisible of oTree lhOrigItem
      end
      else send obs "You are not pointing to a folder"
    end
    else send obs "Folder has not been selected"
  end_procedure

  procedure DoExplorer
    integer lhData
    string lsFolder lsPath
    get psFolder to lsFolder
    if (lsFolder<>"") begin
      get hCurrentDataObject of oTree to lhData
      if lhData begin
        get value of lhData item FLDS_FOLDER_NAME_PATH to lsPath
        send html_StartDoc lsPath
      end
      else send obs "You are not pointing to a folder"
    end
    else send obs "Folder has not been selected"
  end_procedure

  procedure DoGrid
    string lsFolder
    get psFolder to lsFolder
    if (lsFolder<>"") begin
      send ExportDataToArray of oTree
      send popup of oFolderSizeGridPanel
    end
    else send obs "Folder has not been selected"
  end_procedure

  object oBtn1 is a aps.Multi_Button
    on_item "Select folder" send DoNewFolder
    set peAnchors to (anBottom+anRight)
  end_object
  object oBtn2 is a aps.Multi_Button
    set size to 14 40
    on_item "Refresh" send DoRefresh
    set peAnchors to (anBottom+anRight)
  end_object
  object oBtn3 is a aps.Multi_Button
    set size to 14 50
    on_item "Expand level" send DoExpandLevel
    set peAnchors to (anBottom+anRight)
  end_object
  object oBtn4 is a aps.Multi_Button
    set size to 14 40
    on_item "Explorer" send DoExplorer
    set peAnchors to (anBottom+anRight)
  end_object
  object oBtn5 is a aps.Multi_Button
    on_item "Display in grid" send DoGrid
    set peAnchors to (anBottom+anRight)
  end_object
  object oBtn6 is a aps.Multi_Button
    set size to 14 40
    on_item "Close" send close_panel
    set peAnchors to (anBottom+anRight)
  end_object
  send aps_locate_multi_buttons

end_object // oFolderSizeTreePanel
send aps_SetMinimumDialogSize (oFolderSizeTreePanel(self)) // Set minimum size

procedure activate_oFolderSizeTreePanel
  send popup of oFolderSizeTreePanel
end_procedure


