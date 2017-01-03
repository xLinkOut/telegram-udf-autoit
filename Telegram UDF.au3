Global Const $HTTP_STATUS_OK = 200
Global $BOT_ID = ""
Global $TOKEN  = ""
Global $URL	   = "https://api.telegram.org/bot"
Global $cURL   = @AppDataDir & "\curl.exe"
Global $fOut   = @TempDir & "\telegramOutput.dat"
Global $offset = 0

; @INIT CHECK =======================================================================================
If Not FileExists(@AppDataDir & "\curl.exe") Then
   InetGet("https://dl.uxnr.de/build/curl/curl_winssl_msys2_mingw32_stc/curl-7.52.1/curl-7.52.1.zip",@AppDataDir & "\TelegramCurl.zip")
   $oApp = ObjCreate("Shell.Application")
   $hFolderitem = $oApp.NameSpace(@AppDataDir & "\TelegramCurl.zip\src\").Parsename("curl.exe")
   $oApp.NameSpace(@AppDataDir).Copyhere($hFolderitem)
   FileDelete(@AppDataDir & "\TelegramCurl.zip")
EndIf

; @BOT MAIN FUNCTION ================================================================================
Func _InitBot($BotID,$BotToken)
   $BOT_ID = $BotID
   $TOKEN  = $BotToken
   $URL   &= $BOT_ID & ':' & $TOKEN
   Return True
EndFunc

Func _Polling()
   While 1
	  Sleep(1000) ;Prevent CPU Overloading
	  $newUpdates = _GetUpdates()
	  If Not StringInStr($newUpdates,'update_id') Then ContinueLoop
	  $msgData = _JSONDecode($newUpdates)
	  $offset = $msgData[0] + 1
	  Return $msgData
   WEnd
EndFunc

Func _GetUpdates()
   Return HttpGet($URL & "/getUpdates?offset=" & $offset)
EndFunc ;==> _GetUpdates

Func _GetMe()
   Return HttpGet($URL & "/getMe")
EndFunc ;==>_GetMe

Func _SendMsg($ChatID, $Text, $ParseMode = Default, $KeyboardMarkup = Default, $ResizeKeyboard = False, $OneTimeKeyboard = False, $DisableWebPreview = False, $DisableNotification = False)
   Local $Query = $URL & "/sendMessage?chat_id=" & $ChatID &"&text=" & $Text
   If $ParseMode = "Markdown" Then $Query &= "&parse_mode=markdown"
   If $ParseMode = "HTML" Then $Query &= "&parse_mode=html"
   If $KeyboardMarkup <> Default   Then $Query &= "&reply_markup=" & $KeyboardMarkup
   If $ResizeKeyboard 		= True Then $Query &= "&resize_keyboard=True"
   If $OneTimeKeyboard 		= True Then $Query &= "&one_time_keyboard=True"
   If $DisableWebPreview 	= True Then $Query &= "&disable_web_page_preview=True"
   If $DisableNotification 	= True Then $Query &= "&disable_notification=True"
   Local $Response = HttpPost($Query)
   ;Return $Response
   Return True
EndFunc ;==> _SendMsg

Func _ForwardMsg($ChatID, $OriginalChatID, $MsgID, $DisableNotification = False)
   Local $Query = $URL & "/forwardMessage?chat_id=" & $ChatID & "&from_chat_id=" & $OriginalChatID & "&message_id=" & $MsgID
   If $DisableNotification = True Then $Query &= "&disable_notification=True"
   Local $Response = HttpPost($Query)
   ;Return $Response
   Return True
EndFunc ;== _ForwardMsg

; @SEND MEDIA FUNCTION ================================================================================
Func _SendPhoto($ChatID, $Path, $Caption = "")
   Local $Query = $cURL & ' --output "' & $fOut & '" -s -X POST ' & $URL & '/sendPhoto' & ' -F chat_id=' & $ChatID
   If $Caption <> "" Then $Query &= ' -F caption="' & $Caption & '" '
   $Query &= ' -F photo="@' & $Path & '"'
   Local $PID = Run($Query, @ScriptDir, @SW_HIDE)
   ProcessWaitClose($PID)
  Return _GetFileID()
EndFunc ;==> _SendPhoto

Func _SendAudio($ChatID, $Path, $Caption = "")
   Local $Query = $cURL & ' --output "' & $fOut & '" -s -X POST ' & $URL & '/sendAudio' & ' -F chat_id=' & $ChatID
   If $Caption <> "" Then $Query &= ' -F caption="' & $Caption & '" '
   $Query &= ' -F audio="@' & $Path & '"'
   Local $PID = Run($Query, @ScriptDir, @SW_HIDE,0x2)
   ProcessWaitClose($PID)
   Return _GetFileID()
EndFunc ;==> _SendAudio

Func _SendVideo($ChatID, $Path, $Caption = "")
   Local $Query = $cURL & ' --output "' & $fOut & '" -s -X POST ' & $URL & '/sendVideo' & ' -F chat_id=' & $ChatID
   If $Caption <> "" Then $Query &= ' -F caption="' & $Caption & '" '
   $Query &= ' -F video="@' & $Path & '"'
   Local $PID = Run($Query, @ScriptDir, @SW_HIDE)
   ProcessWaitClose($PID)
   Return _GetFileID()
EndFunc ;==> _SendVideo

Func _SendDocument($ChatID, $Path, $Caption = "")
   Local $Query = $cURL & ' --output "' & $fOut & '" -s -X POST ' & $URL & '/sendDocument' & ' -F chat_id=' & $ChatID
   If $Caption <> "" Then $Query &= ' -F caption="' & $Caption & '" '
   $Query &= ' -F document="@' & $Path & '"'
   Local $PID = Run($Query, @ScriptDir, @SW_HIDE)
   ProcessWaitClose($PID)
   Return _GetFileID()
EndFunc ;==> _SendDocument

Func _SendVoice($ChatID, $Path, $Caption = "")
   Local $Query = $cURL & ' --output "' & $fOut & '" -s -X POST ' & $URL & '/sendVoice' & ' -F chat_id=' & $ChatID
   If $Caption <> "" Then $Query &= ' -F caption="' & $Caption & '" '
   $Query &= ' -F voice="@' & $Path & '"'
   Local $PID = Run($Query, @ScriptDir, @SW_HIDE)
   ProcessWaitClose($PID)
   Return _GetFileID()
EndFunc ;==> _SendVoice

Func _SendSticker($ChatID,$Path)
   Local $Query = $cURL & ' --output "' & $fOut & '" -s -X POST ' & $URL & '/sendSticker' & ' -F chat_id=' & $ChatID
   $Query &= ' -F sticker="@' & $Path & '"'
   Local $PID = Run($Query, @ScriptDir, @SW_HIDE)
   ProcessWaitClose($PID)
   Return _GetFileID()
EndFunc

Func _SendChatAction($ChatID, $Action)
   ;typing ;upload_photo ;record_video ;upload_video ;record_audio ;upload_audio ;upload_document ; find_location
   Local $Query = $URL & "/sendChatAction?chat_id=" & $ChatID & "&action=" & $Action
   Local $Response = HttpPost($Query)
   Return True
EndFunc ;==> _SendChatAction

Func _SendLocation($ChatID, $Latitude, $Longitude)
   Local $Query = $URL & "/sendLocation?chat_id=" & $ChatID & "&latitude=" & $Latitude & "&longitude=" & $Longitude
   Local $Response = HttpPost($Query)
   Return True
EndFunc ;==> _SendLocation

Func _SendContact($ChatID,$Phone,$Name)
   Local $Query = $URL & "/sendContact?chat_id=" & $ChatID & "&phone_number=" & $Phone & "&first_name=" & $Name
   Local $Response = HttpPost($Query)
   Return True
EndFunc ;==> _SendContact

; @CHAT FUNCTION ======================================================================================
Func _GetUserProfilePhotos($ChatID,$Offset = "")
   $Query = $URL & "/getUserProfilePhotos?user_id=" & $ChatID
   If $Offset <> "" Then $Query &= "&offset=" & $Offset
   Local $Response = HttpPost($Query)
   Local $firstSplit  = StringSplit($Response,'{')

   ;Get Photos Count
   Local $tmpCount = StringSplit($firstSplit[3],',')
   Local $tmpCount_2 = StringSplit($tmpCount[1],':')
   Local $count = $tmpCount_2[2]

   ;Init Array
   Local $photoArray[$count + 1]
   $photoArray[0] = $count
   $fileidPosition = 6

   ;Get fileid for each photo
   For $i=1 to $count
	  Local $secondSplit = StringSplit($firstSplit[$fileidPosition],',')
	  Local $thirdSplit  = StringSplit($secondSplit[1],':')
	  Local $FileID = StringTrimLeft($thirdSplit[2],1)
	  $FileID = StringTrimRight($FileID,1)
	  $photoArray[$i] = $FileID
	  $fileidPosition += 3
   Next
   Return $photoArray
EndFunc ;==> _GetUserProfilePhotos

Func _GetChat($ChatID)
   Local $Query = $URL & "/getChat?chat_id=" & $ChatID
   Local $Response = HttpGet($Query)
   Return $Response
EndFunc

; @BACKGROUND FUNCTION ================================================================================
Func _GetFilePath($FileID)
   Local $Query = $URL & "/getFile?file_id=" & $FileID
   Local $Response = HttpPost($Query)
   Local $firstSplit = StringSplit($Response,':')
   Local $FilePath = StringTrimLeft($firstSplit[6],1)
   $FilePath = StringTrimRight($FilePath,3)
   Return $FilePath
EndFunc

Func _GetFileID()
   Local $outputFile = FileOpen($fOut)
   Local $Output = FileRead($outputFile)
   FileClose($outputFile)
   FileDelete("output.dat")

   If StringInStr($Output,"photo",1) and StringInStr($Output,"width",1) Then
	  Local $firstSplit  = StringSplit($Output,'[')
	  Local $secondSplit = StringSplit($firstSplit[2],',')
	  Local $thirdSplit  = StringSplit($secondSplit[9],':')
	  Local $FileID = StringTrimLeft($thirdSplit[2],1)
	  $FileID = StringTrimRight($FileID,1)
      Return $FileID

   ElseIf StringInStr($Output,'audio":',1) And StringInStr($Output,'mime_type":"audio',1) Then
	  Local $firstSplit = StringSplit($Output,':')
	  Local $secondSplit = StringSplit($firstSplit[20],',')
	  Local $FileID = StringTrimLeft($secondSplit[1],1)
	  $FileID = StringTrimRight($FileID,1)
	  Return $FileID

   ElseIf StringInStr($Output,'video":',1) and StringInStr($Output,"width",1) Then
	  Local $firstSplit = StringSplit($Output,',')
	  For $i=1 to $firstSplit[0]
		 If StringInStr($firstSplit[$i],"file_id",1) and not StringInStr($firstSplit[$i],"thumb",1) Then Local $secondSplit = StringSplit($firstSplit[$i],':')
	  Next
	  Local $FileID = StringTrimLeft($secondSplit[2],1)
	  $FileID = StringTrimRight($FileID,1)
	  Return $FileID

   ElseIf StringInStr($Output,'document":',1) and StringInStr($Output,"text/plain",1) Then
  	  Local $firstSplit = StringSplit($Output,',')
  	  For $i=1 to $firstSplit[0]
		 If StringInStr($firstSplit[$i],"file_id",1) Then Local $secondSplit = StringSplit($firstSplit[$i],':')
      Next
      Local $FileID = StringTrimLeft($secondSplit[2],1)
	  $FileID = StringTrimRight($FileID,1)
	  Return $FileID

   ElseIf StringInStr($Output,'voice":',1) and StringInStr($Output,"audio/ogg",1) Then
	  Local $firstSplit = StringSplit($Output,',')
	  For $i=1 to $firstSplit[0]
		 If StringInStr($firstSplit[$i],"file_id",1) Then Local $secondSplit = StringSplit($firstSplit[$i],':')
	  Next
      Local $FileID = StringTrimLeft($secondSplit[2],1)
	  $FileID = StringTrimRight($FileID,1)
	  Return $FileID

   ElseIf StringInStr($Output,'sticker":',1) and StringInStr($Output,"width",1) Then
	  Local $firstSplit = StringSplit($Output,',')
  	  For $i=1 to $firstSplit[0]
		 If StringInStr($firstSplit[$i],"file_id",1) Then Local $secondSplit = StringSplit($firstSplit[$i],':')
      Next
	  Local $FileID = StringTrimLeft($secondSplit[2],1)
	  $FileID = StringTrimRight($FileID,1)
	  Return $FileID
   EndIf
EndFunc

Func _DownloadFile($FilePath)
   Local $firstSplit = StringSplit($FilePath,'/')
   Local $fileName = $firstSplit[2]
   Local $Query = "https://api.telegram.org/file/bot" & $BOT_ID & ":" & $TOKEN & "/" & $FilePath
   InetGet($Query,$fileName)
EndFunc

Func _JSONDecode($JSONMsg)
   Local $firstSplit = StringSplit($JSONMsg,"update_id",1)
   Local $secondSplit = StringSplit($firstSplit[2], ",") ;1=BUFFER - 6=CHATID - 7=FIRSTNAME - 8=USERNAME - 9=TYPE - 10=DATE - 11=TEXT
   Local $dataArray[4]
   For $i=1 to $secondSplit[0]
	  Local $data = $secondSplit[$i]
	  If StringLeft($data,2) = '":' Then $dataArray[0] = StringTrimLeft($data,2)
	  If StringInStr($data,'username') Then
		 $tmpUsername = StringSplit($data,':')
		 $tmpUsername[2] = StringTrimLeft($tmpUsername[2],1)
		 $tmpUsername[2] = StringTrimRight($tmpUsername[2],1)
		 $dataArray[1] = $tmpUsername[2]
	  EndIf
	  If StringInStr($data,'chat') Then
		 $tmpChatID = StringSplit($data,':')
		 $dataArray[2] = $tmpChatID[3]
	  EndIf
	  If StringInStr($data,'text') Then
		 $tmpText = StringSplit($data,':')
		 If StringInStr($tmpText[2],'"}}]}') Then
			$tmpText[2] = StringTrimLeft($tmpText[2],1)
			$tmpText[2] = StringTrimRight($tmpText[2],5)
			$dataArray[3] = $tmpText[2]
		 ElseIf StringInStr($tmpText[2],'"}}') Then
			$tmpText[2] = StringTrimLeft($tmpText[2],1)
			$tmpText[2] = StringTrimRight($tmpText[2],3)
			$dataArray[3] = $tmpText[2]
		 ElseIf StringRight($tmpText[2],1) = '"' Then
			$tmpText[2] = StringTrimLeft($tmpText[2],1)
			$tmpText[2] = StringTrimRight($tmpText[2],1)
			$dataArray[3] = $tmpText[2]
		 EndIf
	  EndIf
   Next
   If $dataArray[3] = '' Then
	  For $i=1 to $secondSplit[0]
		 If StringInStr($secondSplit[$i],'first_name') Then
			$tmpUsername = StringSplit($secondSplit[$i],':')
			$tmpUsername[2] = StringTrimLeft($tmpUsername[2],1)
			$tmpUsername[2] = StringTrimRight($tmpUsername[2],1)
			$dataArray[3] = $tmpUsername[2]
		 EndIf
	  Next
   EndIf
   Return $dataArray
EndFunc ;==> _JSONDecode

Func HttpPost($sURL, $sData = "")
   Local $oHTTP = ObjCreate("WinHttp.WinHttpRequest.5.1")
   $oHTTP.Open("POST", $sURL, False)
   If (@error) Then Return SetError(1, 0, 0)
   $oHTTP.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded")
   $oHTTP.Send($sData)
   If (@error) Then Return SetError(2, 0, 0)
   If ($oHTTP.Status <> $HTTP_STATUS_OK) Then Return SetError(3, 0, 0)
   Return SetError(0, 0, $oHTTP.ResponseText)
EndFunc

Func HttpGet($sURL, $sData = "")
   Local $oHTTP = ObjCreate("WinHttp.WinHttpRequest.5.1")
   $oHTTP.Open("GET", $sURL & "?" & $sData, False)
   If (@error) Then Return SetError(1, 0, 0)
   $oHTTP.Send()
   If (@error) Then Return SetError(2, 0, 0)
   If ($oHTTP.Status <> $HTTP_STATUS_OK) Then Return SetError(3, 0, 0)
   Return SetError(0, 0, $oHTTP.ResponseText)
EndFunc