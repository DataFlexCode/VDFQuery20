// Embedpre.vw
// a DataFlex/VPE Preview view

Use APS.pkg      // Auto Positioning and Sizing classes for VDF
Use ObjGroup.utl // Defining groups of objects

#IFDEF gsVdfQuery_Icon#
#ELSE
 string gsVdfQuery_Icon#
 move "" to gsVdfQuery_Icon#
#ENDIF

use cWinControl.pkg

Class VPE_Preview is a cWinControl
  Procedure Construct_Object
    Set External_Class_Name "VPE_Preview" to "Static"
    forward send construct_object
  End_Procedure // Construct_Object
End_Class // VPE_Preview

External_Function VPE_MoveWindow "MoveWindow" User32.DLL dword hwnd integer x integer y integer width integer height integer repaint returns integer

DEFINE_OBJECT_GROUP OG_VpePreview
  Object VPE_Embedded_Preview is a aps.View Label (OG_Param(0))
    Set Border_Style to BORDER_THICK   // Make panel resizeable
    Set pMinimumSize to 110 200 // Resize to no less than this!
    Set p_Top_Margin to 0
    Set p_Left_Margin to 0
    Send Aps_Init
    if gsVdfQuery_Icon# ne "" set icon to gsVdfQuery_Icon#

    Property Integer phDoc 0
    on_key kCancel send close_panel

    Object oCont is a VPE_Preview //aps.Container3D
      Set Size to 280 504
      Send Aps_Auto_Locate_Control Self

      Procedure Key Integer iKey
        Integer hDoc iJunk

        Forward Send Key iKey

        Get phDoc to hDoc

        If (iKey = KEY_LEFT_ARROW)              Move (VpeSendKey(hDoc,VKEY_SCROLL_LEFT)) to iJunk
        If (iKey = (KEY_CTRL+KEY_LEFT_ARROW))   Move (VpeSendKey(hDoc,VKEY_SCROLL_PAGE_LEFT)) to iJunk
        If (iKey = KEY_RIGHT_ARROW)             Move (VpeSendKey(hDoc,VKEY_SCROLL_RIGHT)) to iJunk
        If (iKey = (KEY_CTRL+KEY_RIGHT_ARROW))  Move (VpeSendKey(hDoc,VKEY_SCROLL_PAGE_RIGHT)) to iJunk
        If (iKey = KEY_UP_ARROW)                Move (VpeSendKey(hDoc,VKEY_SCROLL_UP)) to iJunk
        If (iKey = (KEY_CTRL+KEY_UP_ARROW))     Move (VpeSendKey(hDoc,VKEY_SCROLL_PAGE_UP)) to iJunk
        If (iKey = KEY_DOWN_ARROW)              Move (VpeSendKey(hDoc,VKEY_SCROLL_DOWN)) to iJunk
        If (iKey = (KEY_CTRL+KEY_DOWN_ARROW))   Move (VpeSendKey(hDoc,VKEY_SCROLL_PAGE_DOWN)) to iJunk
        If (iKey = KEY_HOME)                    Move (VpeSendKey(hDoc,VKEY_SCROLL_TOP)) to iJunk
        If (iKey = KEY_END)                     Move (VpeSendKey(hDoc,VKEY_SCROLL_BOTTOM)) to iJunk
        If (iKey = KEY_F2)                      Move (VpeSendKey(hDoc,VKEY_PRINT)) to iJunk
        If (iKey = KEY_F3)                      Move (VpeSendKey(hDoc,VKEY_MAIL)) to iJunk
#IFDEF VKEY_1_1
        If (iKey = (KEY_CTRL+KEY_INSERT))       Move (VpeSendKey(hDoc,VKEY_1_1)) to iJunk
#ENDIF
        If (iKey = (KEY_CTRL+KEY_DELETE))       Move (VpeSendKey(hDoc,VKEY_FULL_PAGE)) to iJunk
        If (iKey = KEY_INSERT)                  Move (VpeSendKey(hDoc,VKEY_ZOOM_IN)) to iJunk
        If (iKey = KEY_DELETE)                  Move (VpeSendKey(hDoc,VKEY_ZOOM_OUT)) to iJunk
        If (iKey = KEY_G)                       Move (VpeSendKey(hDoc,VKEY_GRID)) to iJunk
        If (iKey = (KEY_CTRL+KEY_PGUP))         Move (VpeSendKey(hDoc,VKEY_PAGE_FIRST)) to iJunk
        If (iKey = KEY_PGUP)                    Move (VpeSendKey(hDoc,VKEY_PAGE_LEFT)) to iJunk
        If (iKey = KEY_PGDN)                    Move (VpeSendKey(hDoc,VKEY_PAGE_RIGHT)) to iJunk
        If (iKey = (KEY_CTRL+KEY_PGDN))         Move (VpeSendKey(hDoc,VKEY_PAGE_LAST)) to iJunk
        If (iKey = KEY_F1)                      Move (VpeSendKey(hDoc,VKEY_HELP)) to iJunk
        If (iKey = KEY_I)                       Move (VpeSendKey(hDoc,VKEY_INFO)) to iJunk
        If (iKey = KEY_ENTER)                   Move (VpeSendKey(hDoc,VKEY_GOTO_PAGE)) to iJunk
      End_Procedure // Key

      Procedure KeyEnter
        Integer hDoc iJunk
        Get phDoc to hDoc
        Move (VpeSendKey(hDoc,VKEY_GOTO_PAGE)) to iJunk
      End_Procedure // KeyEnter

      On_Key kEnter Send KeyEnter
    End_Object // Cont

    Function Target returns Integer
      Function_Return (Window_Handle(oCont(Self)))
    End_Function // Target

    Procedure Make_Visible
      integer hWnd iVoid
      Set Visible_State to True
      // This piece of code does not work unfortunately. It makes sure
      // that the view starts up in maximazed mode, but the initial paint
      // does not look good.
//    Set View_Mode to viewmode_zoom
//    Get Window_Handle of (oCont(self)) To hWnd
//    If hWnd Move (InvalidateRect(hWnd, 0, True)) To iVoid
    End_Procedure // Make_Visible

    Procedure Make_Invisible
      Set Visible_State to False
    End_Procedure // Make_Invisible
    send Make_Invisible

    Procedure Aps_OnResize integer delta_rw# integer delta_cl#
      Integer hwnd# junk# size#

      send aps_resize (oCont(Self)) delta_rw# delta_cl#
      send aps_auto_size_container

      Move (VpeGetWindowHandle(phDoc(Self))) to hwnd#
      Get GuiSize of (oCont(self)) to size#
      Move (VPE_MoveWindow(hwnd#,0,0,Low(size#),Hi(Size#),true)) to junk#
    End_Procedure

    Procedure Popup
      Set Window_Style to WS_MAXIMIZEBOX 1
      Forward Send Popup
    End_Procedure // Popup

    Procedure Close_Panel // Release when closed!
      Forward Send Close_Panel
      //send Deferred_Request_Destroy_Object
      send Request_Destroy_Object
    End_Procedure
    Move self to OG_Current_Object# // global integer
  End_Object // VPE_Embedded_Preview
END_DEFINE_OBJECT_GROUP
