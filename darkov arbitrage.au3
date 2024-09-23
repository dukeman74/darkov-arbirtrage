#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
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

Func read($scale)
   $array=readBox()
   return(getText($array[0],$array[1],$array[2],$array[3],$scale))
EndFunc

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
    $canvas = _GDIPlus_ImageLoadFromFile("blank_canvas.bmp")
    $hGraphics = _GDIPlus_ImageGetGraphicsContext($canvas)
    _GDIPlus_GraphicsDrawImageRect($hGraphics, $hbitmap, 10, 10,76,20)
    _GDIPlus_GraphicsDispose($hGraphics)
    return $canvas


EndFunc


Func getText($xs,$ys,$xe,$ye,$s)
    $bruh = _ScreenCapture_Capture("", $xs, $ys, $xe, $ye)
    $hbitmap = _GDIPlus_BitmapCreateFromHBITMAP($bruh)
    $fname = "output.bmp"
	;_ScreenCapture_SaveImage("GSI.jpg",$bruh)
    $goodmap=get_cleaned_pic($hbitmap)
    
    
    ;_ScreenCapture_SaveImage ($fname, $bruh)
    _GDIPlus_ImageSaveToFile( $hbitmap, "start.bmp")
    _GDIPlus_ImageSaveToFile( $goodmap, $fname)
    _GDIPlus_BitmapDispose($hbitmap)
    _GDIPlus_BitmapDispose($goodmap)
    ;while(FileExists ( $fname ) == 0)
    ;    Sleep(10)
    ;WEnd
    ShellExecuteWait('\Program Files\Tesseract-OCR\tesseract', $fname & " ex --psm 7", NULL,NULL,@SW_HIDE)
	$number = fileopen("ex.txt")
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
    $defs = FileOpen($fileheader & "/def.txt", $FO_READ)
    $x=int(FileReadLine($defs))
    $y=int(FileReadLine($defs))
    $high_num=int(FileReadLine($defs))
    FileClose($defs)
	$guu = GUICreate("XP time", 230, 200,$x, $y)
    Opt("GUICloseOnESC",0)
    WinSetOnTop($guu,"",$WINDOWS_ONTOP)
    GUISetState(@sw_show, $guu)
    $menu=GUICtrlCreateLabel("buy when under:", 5, 10)
    $high = GUICtrlCreateInput($high_num, 100, 7)
    $buy = GUICtrlCreateButton("   buy   ", 10, 40)
    $readameme = GUICtrlCreateButton("read anywhere", 10, 130)
    $res = GUICtrlCreateButton("read cheapest price", 10, 160)
    $readmeme = GUICtrlCreateLabel("", 130, 140, 200, 26)
    $scaledmeme = GUICtrlCreateInput("1", 10, 90,20,20)
    $go_button = GUICtrlCreateButton("engage", 120, 160)
    $picture = GUICtrlCreateButton("",70,70,120,50,$BS_BITMAP)
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
		 $word=read(GUICtrlRead($scaledmeme))
		 GUICtrlSetData($readmeme,$word)
      ElseIf $in = $res Then
            price_check()
      ElseIf $in = $buy Then
        buy_cheapest()
      ElseIf $in = $go_button Then
        $going= Not $going
        if($going) Then
            GUICtrlSetColor($go_button, 0x8CD248)
            get_current_gold()
        Else
            GUICtrlSetColor($go_button, 0x0)
        EndIf
      EndIf
      if($going) Then
        $cost = price_check()
        if $cost < Int(GUICtrlRead($high)) Then
            buy_cheapest()
            ConsoleWrite("buying a pair for " & $cost & @CRLF)
        EndIf
        refresh_prices()
      EndIf
	WEnd
Until true

Func check_menu_adherance($menu_to_check)

EndFunc

Func refresh_prices()
    MouseClick("Primary",1790, 278,1,0)
    Sleep(400)
EndFunc

Func buy_cheapest()
    MouseClick("Primary",1794, 360,1,0)
    Sleep(40)
    MouseClick("Primary",951, 765,1,0)
    Sleep(40)
    MouseClick("Primary",957, 848,1,0)
    Sleep(200)
    MouseClick("Primary",959, 621,1,0)
    sleep(200)
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

Func Quit()
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
	FileClose($defs)
	Exit
EndFunc

Func price_check()
    $word = getText(1488, 348, 1563, 367, GUICtrlRead($scaledmeme))
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
    if $word == "m" then
        Return(1000000)
    EndIf
    if $word == "rr" then
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