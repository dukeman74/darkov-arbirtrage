#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=data\icon.ico
#AutoIt3Wrapper_UseX64=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <Constants.au3>
#include <MsgBoxConstants.au3>
#include <WinAPI.au3>
#include <GUIConstantsEx.au3>
#include <GuiButton.au3>
#include <Date.au3>
#include <Debug.au3>
#include <ScreenCapture.au3>
#include <GDIPlus.au3>
#Include <Misc.au3>
#include <string.au3>
#include <WinAPIHObj.au3>

HotKeySet("^!q", "Quit")
$strat = 0
Func read($scale)
   $array=readBox()
   return(getText($array[0],$array[1],$array[2],$array[3],$scale))
EndFunc

Global $all_data
Global $cost_of_top=100000
Global $this_item_rarity
Global $rarity_buys[8]
Global $total_spent = 0

func readBox()
   $flag=1
   $dll = DllOpen("user32.dll")
   sleep(100)
   while ($flag)
	  If _IsPressed("01", $dll) Then
		 $MousePos = MouseGetPos()
		 While _IsPressed("01", $dll)
			$mousePos2 = MouseGetPos()
			$flag = 0
		 WEnd
	  EndIf
   WEnd
   local $arr[4]=[$mousePos[0],$mousePos[1],$mousePos2[0],$mousePos2[1]]
   return($arr)
EndFunc

Global $picture

Func InRange($iNumber, $iRange, $iPlus = 25, $iMinus = 25)
    If $iNumber > ($iRange - $iMinus) And $iNumber < ($iRange + $iPlus) Then Return 1
    Return 0
EndFunc

Func RGB2HSL($iColor)
    Local $r = BitAND(BitShift($iColor, 16), 255) / 255, $g = BitAND(BitShift($iColor, 8), 255) / 255, $b = BitAND($iColor, 255) / 255
    Local $Cmax = Max(Max($r, $g), $b), $Cmin = Min(Min($r, $g), $b), $deltaChroma = $Cmax - $Cmin
    Local $L = ($Cmin + $Cmax) / 2, $H, $S
    If $deltaChroma = 0 Then
        $H = 0
        $S = 0
    Else
        $S = $deltaChroma / (1 - Abs(2 * $L - 1))
        If $r = $Cmax Then ;r is max
            $H = Mod(($g - $b) / $deltaChroma, 6)
        ElseIf $g = $Cmax Then ;g is max
            $H = ($b - $r) / $deltaChroma + 2
        Else ;else b is max
            $H = ($r - $g) / $deltaChroma + 4
        EndIf
        $H *= 60
        If $H < 0 Then $H += 360
    EndIf
    Local $aHSL[3] = [$H, $S, $L]
    Return $aHSL
EndFunc

Func Min($a, $b)
    Return ($a < $b) ? $a : $b
EndFunc

Func Max($a, $b)
    Return ($a > $b) ? $a : $b
EndFunc

Func get_cleaned_pic($hbitmap)
    ;color replace part
    Local $iW = _GDIPlus_ImageGetWidth($hbitmap), $iH = _GDIPlus_ImageGetHeight($hbitmap) ;get width and height of the image
    Local $hContext = _GDIPlus_ImageGetGraphicsContext($hBitmap)
    ;;_GDIPlus_GraphicsDrawImageRect($hContext, $hImage, 0, 0, $iW, $iH)

    Local $tBitmapData = _GDIPlus_BitmapLockBits($hBitmap, 0, 0, $iW, $iH, BitOR($GDIP_ILMWRITE, $GDIP_ILMREAD), $GDIP_PXF32ARGB) ;locks a portion of a bitmap for reading and writing. More infor at http://msdn.microsoft.com/en-us/library/windows/desktop/ms536298(v=vs.85).aspx
    Local $iScan0 = DllStructGetData($tBitmapData, "Scan0") ;get scan0 (pixel data) from locked bitmap
    Local $tPixel = DllStructCreate("int argb[" & $iW * $iH & "];", $iScan0)
    Local $iRGBA, $iRowOffset, $aHSL

    For $iY = 0 To $iH - 1
        $iRowOffset = $iY * $iW + 1
        For $iX = 0 To $iW - 1 ;get each pixel in each line and row
            $iRGBA = DllStructGetData($tPixel, 1, $iRowOffset + $iX)
            $aHSL = RGB2HSL($iRGBA) ;convert color to HSL color space
            ;check if HSL color is in the red / purple range -> see http://hslpicker.com for details
            If ($aHSL[1]>.1) Then
                DllStructSetData($tPixel, 1, 0xFF000000, $iRowOffset + $iX) ;if yes then set black pixel
            Else
                DllStructSetData($tPixel, 1, 0xFFFFFFFF, $iRowOffset + $iX) ;else black pixel 
            EndIf
        Next
    Next
    _GDIPlus_BitmapUnlockBits($hBitmap, $tBitmapData) ;unlocks a portion of a bitmap that was locked by _GDIPlus_BitmapLockBits

    ;crop part
    $canvas = _GDIPlus_ImageLoadFromFile("data/blank_canvas.bmp")
    $hGraphics = _GDIPlus_ImageGetGraphicsContext($canvas)
    _GDIPlus_GraphicsDrawImageRect($hGraphics, $hbitmap, 10, 10,76,20)
    _GDIPlus_GraphicsDispose($hGraphics)
    return $canvas


EndFunc
 
func send_sniffer()
    RunWait('data\snif.bat', NULL,NULL,@SW_HIDE)
    ;Sleep(200)
EndFunc

func catch_packets()
    $cost_of_top=100000
    ;ConsoleWrite("e" & @CRLF)
    send_sniffer()
    ;RunWait('\"Program Files\Wireshark\tshark.exe"', '-i ethernet -f \"src host 35.71.175.214\" -w packets -c 200', NULL,NULL)
    $packets = fileopen("data\packets", $FO_BINARY)
    Local $b
    $already_matched = false
    $matching = 0
    $match_str = "DesignDataItem:"
    $match_len = StringLen($match_str)
    $item_name = ""
    $end = Binary("0x18")
    ;ConsoleWrite((StringMid($match_str,1,1)))
    ;ConsoleWrite(@CRLF)
    $add=true
    Global $des[12]
    Global $namedsd[12]
    $prop=0
    $building=""
    $databuild = ""
    $gotname = false
    $stop=false
    $juststop=0
    $protect=0
    $read_a_property=false
    Global $costbytes[2]
    For $i = 0 To 2000 Step +1
        $b = FileRead($packets,1)
        ;if $gotname Then
        ;    if $b >= 0x30 And $b < 0x7b then
        ;        ConsoleWrite(BinaryToString($b))
        ;    Else
        ;        ;ConsoleWrite(StringRight(StringToBinary($b),2) & " ")
        ;        ConsoleWrite(" " & $b & " ")
        ;    EndIf
        ;EndIf
        if(not $already_matched) then
            if($juststop<2 AND $stop) Then
                $des[$prop] = "cost"
                ;$namedsd[$prop] = int($b)
                $costbytes[$juststop]=$b
                $juststop+=1
                If ($juststop==2) Then
                    if int($costbytes[1]) == 0x20 Then
                        $namedsd[$prop] = int($costbytes[0])
                    Else
                        $namedsd[$prop] = int($costbytes[0]) + 128 * (int($costbytes[1])-1)
                    EndIf
                EndIf
            ENDIF   
            if $b == StringToBinary(StringMid($match_str,1+$matching,1)) Then
                $matching+=1
                if ($matching >= $match_len) Then
                    ;ConsoleWrite(" MATCHED! ")
                    $add=true
                    $already_matched = true
                    If ($gotname) Then
                        $namedsd[$prop-1]=$databuild
                        $databuild=" " & ($end) & " "
                    EndIf
                    if $gotname Then $read_a_property=True
                    $gotname=true
                    $protect=2
                EndIf
            Else
                $matching = 0
                if $gotname Then
                    If ($read_a_property and $protect == 0 ) Then
                        if ( $b == Binary("0x18")) Then
                            $namedsd[$prop-1]=$databuild
                            if $stop then ExitLoop
                            $stop = true
                            ;ConsoleWrite(" -- DONE -- ")
                        EndIf
                    Else
                        $protect-=1
                    EndIf
                    
                    $databuild &= " " & ($b) & " "
                    
                EndIf
            EndIf

        ElseIf(not $stop) Then
            if($b == $end) Then
                $add = false
                if $prop==0 Then
                    $des[$prop] =  $building
                Else
                    $des[$prop] =  StringMid($building,28)
                EndIf
                
                $prop+=1
                $building = ""
                $matching = 0
                $already_matched=false
                $match_str = "DataItemPropertyType:"
                $match_len = StringLen($match_str)
                $end = Binary("0x10")
            EndIf
            if($add) Then
                $building&=BinaryToString($b)
            EndIf
        EndIf

    Next
    ;ConsoleWrite(@CRLF)
    ;For $e=0 to $prop
    ;    ConsoleWrite($des[$e] & ": " & $namedsd[$e] & @CRLF)
    ;Next

    $namedsd[0]=StringMid($des[0],9)
    $des[0] = "Item name"
    
    $rarity = StringRight($namedsd[0],4)
    $namedsd[0] = StringLeft($namedsd[0],StringLen($namedsd[0])-5)
    $rarity = StringLeft($rarity,1)
    $this_item_rarity=Int($rarity)-1
    Switch $rarity
        Case "1"
            $rarity = "Gray"
        Case "2"
            $rarity = "White"
        Case "3"
            $rarity = "Green"
        Case "4"
            $rarity = "Blue"
        Case "5"
            $rarity = "Purple"
        Case "6"
            $rarity = "Legi"
        Case "7"
            $rarity = "Unique"
    EndSwitch
    $to_data = $des[0] & ": " & $rarity & " " & $namedsd[0] & @CRLF
    For $e=1 to $prop-1
        $to_data &= $des[$e] & ": " & Int(StringMid($namedsd[$e],8,4)) & @CRLF
    Next
    $to_data &= $des[$prop] & ": " & $namedsd[$prop] & @CRLF
    if $namedsd[$prop] <> "" Then
        $cost_of_top=Int($namedsd[$prop])
    EndIf
    GUICtrlSetData($all_data,$to_data)
    ;ConsoleWrite(@CRLF & "Item name: " & $item_name)
    ;ConsoleWrite($packetsstr)
	FileClose($packets)
EndFunc


Func getText($xs,$ys,$xe,$ye,$s)
    $bruh = _ScreenCapture_Capture("", $xs, $ys, $xe, $ye)
    $hbitmap = _GDIPlus_BitmapCreateFromHBITMAP($bruh)
    $fname = "data/output.bmp"
	;_ScreenCapture_SaveImage("GSI.jpg",$bruh)
    $goodmap=get_cleaned_pic($hbitmap)
    
    
    ;_ScreenCapture_SaveImage ($fname, $bruh)
    _GDIPlus_ImageSaveToFile( $hbitmap, "data/start.bmp")
    _GDIPlus_ImageSaveToFile( $goodmap, $fname)
    _GDIPlus_BitmapDispose($hbitmap)
    _GDIPlus_BitmapDispose($goodmap)
    ;while(FileExists ( $fname ) == 0)
    ;    Sleep(10)
    ;WEnd
    ShellExecuteWait('\Program Files\Tesseract-OCR\tesseract', $fname & " data/ex --psm 7", NULL,NULL,@SW_HIDE)
	$number = fileopen("data/ex.txt")
    $numberstr = FileReadLine($number)
	_WinAPI_DeleteObject($bruh)
	FileClose($number)
    ;FileDelete ( "GSI.jpg" )
    ;while(FileExists ( "ex.txt" ) == 1)
    ;    Sleep(10)
    ;    FileDelete ( "ex.txt" )
    ;WEnd
    _GUICtrlButton_SetImage($picture,$fname)
    
    return($numberstr)
  EndFunc   ;getText

Enum $NAME, $SX, $SY, $READINGS

$picsize = 1
$pictureroot = ($picsize * 2 + 1)
$cutoff = 0.95

Global $states[200][5][$pictureroot * $pictureroot]

$states[0][$NAME][0] = "No idea"

Do
    
    _GDIPlus_Startup()
    $fileheader = "data"
    
    $summary = FileOpen("summary.txt", $FO_OVERWRITE)
    For $i = 0 To UBound($rarity_buys)-1
        $rarity_buys[$i] = 0
     Next
    if FileExists($fileheader & "/def.txt") Then
        $defs = FileOpen($fileheader & "/def.txt", $FO_READ)
        $x=int(FileReadLine($defs))
        $y=int(FileReadLine($defs))
        $high_num=int(FileReadLine($defs))
        $strat = int(FileReadLine($defs))
        FileClose($defs)
    Else
        $x=10
        $y=10
        $high_num=50
        $strat = 0
    EndIf
	$guu = GUICreate("XP time", 230, 350,$x, $y)
    Opt("GUICloseOnESC",0)
    WinSetOnTop($guu,"",$WINDOWS_ONTOP)
    GUISetState(@sw_show, $guu)
    $menu=GUICtrlCreateLabel("buy when under:", 5, 10)
    $high = GUICtrlCreateInput($high_num, 100, 7)
    $buy = GUICtrlCreateButton("   buy   ", 10, 40)
    $readameme = GUICtrlCreateButton("read anywhere", 10, 130)
    $res = GUICtrlCreateButton("read cheapest price", 10, 160)
    $readmeme = GUICtrlCreateLabel("", 130, 140, 200, 26)
    $go_button = GUICtrlCreateButton("engage", 120, 160)
    $sniff = GUICtrlCreateButton("sniff", 170, 160)
    $picture = GUICtrlCreateButton("",70,70,120,50,$BS_BITMAP)
    $all_data = GUICtrlCreateLabel("", 10, 220, 200, 240)
    $kind = GUICtrlCreateButton("switch strat", 10, 190)
    $active_kind = GUICtrlCreateLabel("OCR", 80, 195, 97)
    If $strat Then GUICtrlSetData($active_kind,"Packets")
    $going = False
    ;GUICtrlSetColor($go_button, 0x8CD248)
    If True Then ;read in states from files
    $statecount = 1
    $search = FileFindFirstFile($fileheader & "/states/*")
    ;ConsoleWrite("did search" & @CRLF)
    While True
        $FileName = FileFindNextFile($search)
        If @error Then ExitLoop
        ;ConsoleWrite("loop, fname is " & String($FileName) & @CRLF)
        $fhand = FileOpen($fileheader & "/states/" & $FileName)
        $namein = StringSplit($FileName, ".")[1]
        $states[$statecount][$NAME][0] = $namein
        $states[$statecount][$SX][0] = FileReadLine($fhand)
        $states[$statecount][$SY][0] = FileReadLine($fhand)
        $num = 0
        $i = -$picsize
        While ($i < $picsize + 1)
            $j = -$picsize
            While ($j < $picsize + 1)

                $states[$statecount][$READINGS][$num] = Int(FileReadLine($fhand))
                $num += 1

                $j += 1
            WEnd
            $i += 1
        WEnd

        FileClose($fhand)
        ;ConsoleWrite("added a state named " & $states[$statecount][$NAME][0] & @CRLF)
        $statecount += 1
    WEnd
    FileClose($search)
    ;ConsoleWrite("total states: " & $statecount & @CRLF)
EndIf
   While True
	   Sleep(10)
	   $in = GUIGetMsg()
	  if($in = $GUI_EVENT_CLOSE) Then
		 Quit()
	  ElseIf $in = $readameme Then
		 $word=read(1)
		 GUICtrlSetData($readmeme,$word)
      ElseIf $in = $res Then
            price_check()
      ElseIf $in = $buy Then
        buy_cheapest()
      ElseIf $in = $sniff Then
        ;send_sniffer()
        ;Sleep(100)
        refresh_prices(false)
        catch_packets()
      ElseIf $in = $go_button Then
        $going= Not $going
        if($going) Then
            GUICtrlSetColor($go_button, 0x8CD248)
            get_current_gold()
        Else
            GUICtrlSetColor($go_button, 0x0)
        EndIf
      ElseIf $in = $kind Then
        If $strat Then 
            $strat=0
            GUICtrlSetData($active_kind,"OCR")
        Else
            $strat=1
            GUICtrlSetData($active_kind,"Packets")
            
        EndIf
      EndIf
      if($going) Then
        if $strat Then
            refresh_prices(false)
            catch_packets()
            if $cost_of_top < Int(GUICtrlRead($high)) Then
                buy_cheapest()
                ConsoleWrite("buying: " & @CRLF & GUICtrlRead($all_data) & @CRLF)
                FileWrite($summary,"buying: " & @CRLF & GUICtrlRead($all_data) & @CRLF)
                $rarity_buys[$this_item_rarity]+=1
                $total_spent+=$cost_of_top
            EndIf
        Else
            $cost = price_check()
            if $cost < Int(GUICtrlRead($high)) Then
                buy_cheapest()
                ConsoleWrite("buying item for " & $cost & @CRLF)
            EndIf
            refresh_prices()
        EndIf
      EndIf
	WEnd
Until true

Func check_menu_adherance($menu_to_check)

EndFunc

Func refresh_prices($sleep=true)
    MouseClick("Primary",1790, 278,1,0)
    if($sleep) Then
        Sleep(400)
    EndIf
EndFunc

Func buy_cheapest()
    MouseClick("Primary",1794, 360,1,0)
    Sleep(200)
    MouseClick("Primary",951, 765,1,0)
    Sleep(200)
    MouseClick("Primary",957, 848,1,0)
    Sleep(800)
    MouseClick("Primary",959, 621,1,0)
    sleep(300)
    $basd = PixelGetColor(843, 875)
    if($basd == 0x474330) Then
        ConsoleWrite("aids" & @CRLF)
        MouseClick("Primary",107, 38,1,0)
        sleep(200)
    EndIf
    Sleep(800)
EndFunc

Func get_price($item_name)
    
EndFunc


Func FilePrepend($szFile,$szText)

    If Not FileExists($szFile) Then Return

    $szBuffer = FileRead($szFile,FileGetSize($szFile))

    $szBuffer = $szText & $szBuffer

    FileDelete($szFile)

    Return FileWrite($szFile,$szBuffer)

EndFunc

Func Quit()
    if (Not FileExists($fileheader)) Then
        _WinAPI_CreateDirectory($fileheader)
    EndIf
    FileClose($summary)
    $out = "Total spend: " & $total_spent & @CRLF
    For $i = 0 To 7 Step +1
        if $rarity_buys[$i] <> 0 Then
            Switch $i
                Case 0
                    $out&= "Gray"
                Case 1
                    $out&= "White"
                Case 2
                    $out&= "Green"
                Case 3
                    $out&= "Blue"
                Case 4
                    $out&= "Purple"
                Case 5
                    $out&= "Legi"
                Case 6
                    $out&= "Unique"
            EndSwitch
            $out&= "s: " & $rarity_buys[$i] & "  " & @CRLF
        EndIf
    Next
    $out&= @CRLF
    FilePrepend("summary.txt", $out & @CRLF)
	$defs = FileOpen($fileheader & "/def.txt", $FO_OVERWRITE )
	$temp=WinGetPos($guu)
	$y=$temp[1]
	$x=$temp[0]
	if($x==-32000) Then
		$x=200
		$y=200
	EndIf
	FileWriteLine($defs,$x)
	FileWriteLine($defs,$y)
	FileWriteLine($defs,GUICtrlRead($high))
    FileWriteLine($defs,$strat)
	FileClose($defs)
	Exit
EndFunc

Func price_check()
    $word = getText(1488, 348, 1563, 367, 1)
    ;ConsoleWrite($word & @CRLF)
    $word = StringRegExpReplace($word, '\D', '')
    GUICtrlSetData($readmeme,$word)
    ;ConsoleWrite("word: " & $word  & @CRLF)
    ;if(StringIsInt($word)) Then
    ;    return(Int($word))
    ;EndIf
    ;ConsoleWrite("unreadable text -" & $word & "-" & @CRLF)
    ;ConsoleWrite(Int($word) &  @CRLF)
    if $word <> "" then
        Return(Int($word))
    EndIf
    if $word == "m\n" then
        Return(1000000)
    EndIf
    if $word == "rr\n" then
        Return(1000000)
    EndIf
    ConsoleWrite("Illegible: "& $word &  @CRLF)
    
    Return(1000000)
EndFunc

func get_current_gold()
    MouseClick("Primary",1067, 122,1,0)
    Sleep(1500)
    $bruh = _ScreenCapture_Capture("", 1620, 987, 1859, 1013)
	_ScreenCapture_SaveImage("starting money.jpg",$bruh)
    Sleep(100)
    MouseClick("Primary",857, 114,1,0)
    Sleep(600)
EndFunc