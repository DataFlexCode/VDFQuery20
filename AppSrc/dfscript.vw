// Use DFScript.vw  // DFScript test
Use DFScript.utl // DF-Script interpreter
Use Edit.utl     // Edit class for character mode DataFlex

/DFScript.Sample1
integer i
move 0 to i
while i le 7
  input "Enter integer value: " i
end
showln "Finally you entered something larger than 7!"
showln "Goodbye"
pause // Pause program to let us see the exit message
/DFScript.Sample2
integer i
for i from 0 to 99
  show i " "
loop
pause // Pause program to let us see the result
/DFScript.Sample3
 // The IF command differs from that of standard DATAFLEX
 // in that it does not use BEGIN/END commands to define
 // the range of the branches. Nor is it possible to put
 // a conditioned command on the same command line as the
 // IF statement itself.

integer i

for i from 0 to 10
  show i " is "
  if i gt 5
    show "GT 5"
    if i le 8 // Nested IF command
      show " but it is not GT 8"
    else
      show " and GT 8 too"
    endif
  else
    show "not GT 5"
  endif
  showln
loop
showln
showln "Press any key to continue..."
pause // Pause program to let us see the result
/DFScript.Sample4
integer i
repeat
  input "Enter integer value: " i
until i gt 7
showln "Finally you entered something larger than 7!"
showln "Goodbye"
pause // Pause program to let us see the exit message
/DFScript.Sample5
integer guesses
string title

showln "Now, who is he?"
move 1 to guesses
repeat
  input "He's a real " title
  increment guesses
  if (uppercase(title)) ne (uppercase("Nowhere Man"))
    if title eq ""
      showln "You are supposed to make a guess..."
    else
      showln "Maybe, but that's not the song I'm thinking about"
    endif
    if guesses eq 3
      showln "I'll hint you: It's by the Beatles"
    endif
    if guesses eq 4
      showln "I'll hint you (again): Nowhere Man"
    endif
    if guesses eq 5
      showln "My god, you're stupid! Enter 'Nowhere Man'"
    endif
    if guesses eq 6
      showln "I give up. You're out of here!"
      showln
      showln "He's a real NOWHERE MAN"
      move "Nowhere Man" to title
    endif
  endif
until (uppercase(title)) eq (uppercase("Nowhere Man"))
showln "Sitting in his nowhere land"
showln "Making all his nowhere plans for nobody"
showln
showln "Press any key..."

pause
abort // Clean up memory taken up by variables and stuff"
/DFScript.Sample6
showln "This example shows what happens if a regular DF error"
showln "occurs while a DFScript is running."
showln
showln "Right, are you ready?"
pause
integer i
move "ABC" to i // This generates an error
showln
showln "OK! So the next time, take care not to make such"
showln "stupid mistakes"
pause
abort
/DFScript.Sample7
integer i
repeat
  move (i+1) to i
  showln i
until i gt 5
pause

/DFScript.Sample8
integer iFile

move 0 to iFile
showln "Filelist.cfg"
showln "------------"
repeat
  move (API_AttrValue_FLSTNAV(DF_FILE_NEXT_USED,iFile)) to iFile
  if iFile
    show (IntToStrR(iFile,4)) ": "
    showln (API_AttrValue_FILELIST(DF_FILE_DISPLAY_NAME,iFile))
  endif
until (iFile=0)
showln "Press any key..."
pause
/DFScript.Sample9
integer i
move 399 to i
while (i+2) gt 1
  show i " "
  move (i-1) to i
end
showln "Press any key..."
pause
/DFScript.Sample10
integer i
log_open "dfscript.log" 0 // 0 means overwrite, 1 means append
move 399 to i
while (i+2) gt 1
  show i " "
  move (i-1) to i
  log_writeln i
end
showln "Press any key..."
log_close
pause
/*


Use aps.pkg          // Auto Positioning and Sizing classes for VDF
object oDFScriptSampleSelector is a aps.ModalPanel label "Load DFScript sample"
  set locate_mode to CENTER_ON_SCREEN
  on_key kcancel send close_panel
  property integer piResult 0
  object oLst is a aps.List
    set size to 100 200
    on_key kenter send close_panel_ok
    procedure add_selection integer img# string str#
      send add_item msg_ok str#
      set aux_value item (item_count(self)-1) to img#
    end_procedure
    send add_selection DFScript.Sample1.N "While/End structure"
    send add_selection DFScript.Sample2.N "For/Loop structure"
    send add_selection DFScript.Sample3.N "If/Else structure"
    send add_selection DFScript.Sample4.N "Repeat/Until structure"
    send add_selection DFScript.Sample5.N "Nowhere Man"
    send add_selection DFScript.Sample6.N "Error handling"
    send add_selection DFScript.Sample7.N "Simple expression"
    send add_selection DFScript.Sample8.N "Files in Filelist.cfg"
    send add_selection DFScript.Sample9.N "Expression in while"
    send add_selection DFScript.Sample10.N "Writing to log file"
  end_object
  procedure close_panel_ok
    set piResult to true
    send close_panel
  end_procedure
  object oBtn1 is a aps.Multi_Button
      on_item t.btn.ok send close_panel_ok
  end_object
  object oBtn2 is a aps.Multi_Button
      on_item t.btn.cancel send close_panel
  end_object
  send aps_locate_multi_buttons
  function iRun returns integer // Returns the number of the image to load
    integer rval#
    set piResult to false
    send popup
    if (piResult(self)) function_return (aux_value(oLst(self),CURRENT))
    //function_return 0
  end_function
end_object

object oDFScript_DebugSetup is a aps.ModalPanel label "DFScript Debug Setup"
  set locate_mode to CENTER_ON_SCREEN
  on_key kcancel send close_panel
  property integer piResult 0
  object oGrp is a aps.Group
    on_key kenter send next
    object oCB1 is a aps.CheckBox label "Debug interpreter"
    end_object
    object oCB2 is a aps.CheckBox label "Debug while running"
    end_object
    object oCB3 is a aps.CheckBox label "Single step while running"
    end_object
  end_object
  procedure close_panel_ok
    set piResult to true
    send close_panel
  end_procedure
  object oBtn1 is a aps.Multi_Button
    on_item t.btn.ok send close_panel_ok
  end_object
  object oBtn2 is a aps.Multi_Button
    on_item t.btn.cancel send close_panel
  end_object
  send aps_locate_multi_buttons
  function iRun.iii integer i1# integer i2# integer i3# returns integer
    integer rval#
    set piResult to false
    set checked_state of (oCB1(oGrp(self))) to i1#
    set checked_state of (oCB2(oGrp(self))) to i2#
    set checked_state of (oCB3(oGrp(self))) to i3#
    send popup
    function_return (piResult(self))
  end_function
  function iDebugInterpreter returns integer
    function_return (Checked_State(oCB1(oGrp(self))))
  end_function
  function iDebugVM returns integer
    function_return (Checked_State(oCB2(oGrp(self))))
  end_function
  function iDebugSingleStepVM returns integer
    function_return (Checked_State(oCB3(oGrp(self))))
  end_function
end_object

class cScriptEditor is a cEditor
end_class

class cScriptIDE_Client is a aps.View
  procedure construct_object integer img#
    forward send construct_object img#
    property integer piDebugInterpreter  0
    property integer piDebugVM           0
    property integer piDebugSingleStepVM 0
    property integer piProgramChanged    0
    property string  psProgramFileName   ""
    property integer piEditObject        0
    object oVM is a cVirtualMachine
    end_object
    object oScriptInterpreter is a cScriptInterpreter
      // The interpreter needs a Virtual Machine object:
      set pVM_Object to (oVM(self))
    end_object
    on_key key_ctrl+key_a send open_sample
    on_key key_ctrl+key_r send run_script
    on_key key_ctrl+key_n send new_script
    on_key key_ctrl+key_s send save_script
    on_key key_ctrl+key_o send open_script
    on_key key_ctrl+key_d send setup_debug
  end_procedure
  procedure open_sample
    integer ch# oEdit# itm# seqeof# img#
    string str#
    move (piEditObject(self)) to oEdit#
    get iRun of (oDFScriptSampleSelector(self)) to img#
    if img# begin
      move 0 to itm#
      move (SEQ_DirectInput("image:"+string(img#))) to ch#
      if (ch#>=0) begin
        send delete_data to oEdit#
        repeat
          readln str#
          move (seqeof) to seqeof#
          ifnot seqeof# begin
            set value of oEdit# item itm# to str#
            increment itm#
          end
        until seqeof#
        set dynamic_update_state of oEdit# to true
        send SEQ_CloseInput ch#
        set piProgramChanged  to 0
        set psProgramFileName to "Sample"
        send activate to oEdit#
        send display_position to oEdit#
      end
    end
  end_procedure
  procedure open_script
    integer ch# oEdit# itm# seqeof#
    string fn# str#
    move (piEditObject(self)) to oEdit#
    move (SEQ_SelectFile("Open DFScript source file","DFScript source file (*.dfs)|*.DFS")) to fn#
    if fn# ne "" begin
      move 0 to itm#
      move (SEQ_DirectInput(fn#)) to ch#
      if (ch#>=0) begin
        send delete_data to oEdit#
        repeat
          readln str#
          move (seqeof) to seqeof#
          ifnot seqeof# begin
            set value of oEdit# item itm# to str#
            increment itm#
          end
        until seqeof#
        set dynamic_update_state of oEdit# to true
        send SEQ_CloseInput ch#
        set piProgramChanged  to 0
        set psProgramFileName to fn#
        send activate to oEdit#
        send display_position to oEdit#
      end
    end
  end_procedure
  procedure new_script
    send delete_data to (piEditObject(self))
    send activate to (piEditObject(self))
    set psProgramFileName to ""
    send display_position to (piEditObject(self))
    set piProgramChanged  to 0
  end_procedure
  procedure save_script
    integer ch# oEdit# itm# seqeof# max#
    string fn# str#
    move (piEditObject(self)) to oEdit#
    move (SEQ_SelectOutFile("Save DFScript source file","*.dfs")) to fn#
    if fn# ne "" begin
      move (SEQ_DirectOutput(fn#)) to ch#
      if (ch#>=0) begin
        get line_count of oEdit# to max#
        for itm# from 0 to (max#-1)
          get value of oEdit# item itm# to str#
          writeln channel ch# str#
        loop
        send SEQ_CloseOutput ch#
        set piProgramChanged to 0
        set psProgramFileName to fn#
        send activate to oEdit#
        send display_position to oEdit#
      end
    end
  end_procedure

  procedure run_script
    integer oScriptInterpreter# oEdit# itm# max# error# errobj#
    string str#
    move (piEditObject(self)) to oEdit#
    move (oScriptInterpreter(self)) to oScriptInterpreter#
    set piDebugState of oScriptInterpreter# to (piDebugInterpreter(self))
    send script_begin to oScriptInterpreter#
    get line_count of oEdit# to max#
    move 0 to error#
    send ScreenEndWait_On 0 (max#-1)
    for itm# from 0 to (max#-1)
      send ScreenEndWait_SetText ("Parsing line "+string(itm#+1)+" of "+string(max#+1))
      send ScreenEndWait_Update itm#
      get value of oEdit# item itm# to str#
      ifnot error# get iParse_Line.sis of oScriptInterpreter# str# (itm#+1) "Editor contents" to error#
    loop
    send ScreenEndWait_Off
    if error# begin
      send move_absolute to oEdit# (hi(error#)-1) (low(error#)-1)
      send activate to oEdit#
      send display_position to oEdit#
    end
    else begin
      set piDebugState      of (oVM(self)) to (piDebugVM(self))
      set piDebugSingleStep of (oVM(self)) to (piDebugSingleStepVM(self))
      send script_end to oScriptInterpreter#
      move Error_Object_Id to errobj#
      move 0 to Error_Object_Id
      clearscreen
      send run_script to oScriptInterpreter#
      move errobj# to Error_Object_Id
    end
  end_procedure
  procedure setup_debug
    if (iRun.iii(oDFScript_DebugSetup(self),piDebugInterpreter(self),piDebugVM(self),piDebugSingleStepVM(self))) begin
      set piDebugInterpreter  to (iDebugInterpreter(oDFScript_DebugSetup(self)))
      set piDebugVM           to (iDebugVM(oDFScript_DebugSetup(self)))
      set piDebugSingleStepVM to (iDebugSingleStepVM(oDFScript_DebugSetup(self)))
    end
  end_procedure
end_class // cScriptIDE_Client


object oDFScript_Vw is a cScriptIDE_Client label "DFScript IDE, RAD and Web enabled 4GL Wonder"
  set Border_Style to BORDER_THICK   // Make panel resizeable
  set pMinimumSize to 150 100
  on_key kcancel send close_panel
  object oEdit is a cScriptEditor
    set size to 200 400
    set typeface to "Courier New"
    procedure display_position integer line# integer column#
      integer pos#
      get position to pos#
      send update_cursor_info ("L"+pad(string(hi(pos#)+1),5)+" C"+pad(string(low(pos#)+1),4))
    end_procedure
  end_object
  set piEditObject to (oEdit(self))
  object oBtn1 is a aps.Multi_Button
    on_item "New"    send new_script
  end_object
  object oBtn2 is a aps.Multi_Button
    on_item "Save"   send save_script
  end_object
  object oBtn3 is a aps.Multi_Button
    on_item "Open"   send open_script
  end_object
  object oBtn4 is a aps.Multi_Button
    on_item "Sample" send open_sample
  end_object
  object oBtn5 is a aps.Multi_Button
    on_item "Debug"  send setup_debug
  end_object
  object oBtn6 is a aps.Multi_Button
    on_item "Run"    send run_script
  end_object
  object oBtn7 is a aps.Multi_Button
    on_item "Close"  send close_panel
  end_object
  object oLabel is a aps.Form abstract AFT_ASCII10
    Set Form_Justification_Mode Item 0 to Form_DisplayCenter
    #IFDEF SET_TEXTCOLOR
     Set TextColor to clRed  //JK - this works, but only in a form
    #ENDIF
    Set Object_Shadow_State to True // Make this form look like a textbox
    Set Form_Border Item 0 to Border_None
    procedure check_this
      integer self#
      move self to self#
      send aps_register_multi_button self#
    end_procedure
    send check_this
  end_object
  send aps_locate_multi_buttons sl_vertical
  procedure update_cursor_info string str#
    set value of (oLabel(self)) item 0 to str#
  end_procedure
  procedure aps_onResize integer delta_rw# integer delta_cl#
    send aps_resize (oEdit(self)) delta_rw# delta_cl#
    send aps_register_multi_button (oBtn1(self))
    send aps_register_multi_button (oBtn2(self))
    send aps_register_multi_button (oBtn3(self))
    send aps_register_multi_button (oBtn4(self))
    send aps_register_multi_button (oBtn5(self))
    send aps_register_multi_button (oBtn6(self))
    send aps_register_multi_button (oBtn7(self))
    send aps_register_multi_button (oLabel(self))
    send aps_locate_multi_buttons sl_vertical
    send aps_auto_size_container
  end_procedure
end_object

procedure activate_dfscript_ide
  send popup to (oDFScript_Vw(self))
end_procedure

function dfscript.Direct_Output global returns integer
  send new_script to (oDFScript_Vw(self))
  function_return (not(piProgramChanged(oDFScript_Vw(self))))
end_function

procedure dfscript.WriteLn global string str#
  integer oEdit# itm#
  move (oEdit(oDFScript_Vw(self))) to oEdit#
  get line_count of oEdit# to itm#
  set value of oEdit# item itm# to str#
end_procedure
