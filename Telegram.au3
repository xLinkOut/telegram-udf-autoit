#include-once
#include "include/WinHttp.au3"
#include "include/JSON.au3"

Global $TOKEN  = ""
Global $URL	   = "https://api.telegram.org/bot"
Global $Offset = 0
Global $Debug = True

#Region "@BOT MAIN FUNCTIONS"
Func _InitBot($Token)
	$TOKEN = $Token
	$URL &= $Token
    If($Debug) Then ConsoleWrite("Token: "&$Token&@CRLF)
    If(_GetMe() == False) Then
        ConsoleWrite("Connection error: Token invalid/Webhook setted/Internet connection"&@CRLF)    
        Return SetError(1,0,False)
    Else
        Return True
    EndIf
EndFunc ;==> _InitBot

Func _GetUpdates()
    Return HttpGet($URL & "/getUpdates?offset=" & $Offset)
EndFunc ;==> _GetUpdates

Func _GetMe()
	Local $json = Json_Decode(HttpGet($URL & "/getMe"))
	If Not (Json_IsObject($json)) Then Return SetError(1,0,False) ;Check if json is valid    
	Local $data[3] = [Json_Get($json,'[result][id]'), _
				   	  Json_Get($json,'[result][username]'), _
			   		  Json_Get($json,'[result][first_name]')]
	Return $data
EndFunc ;==>_GetMe

Func _Polling()
    While 1
        Sleep(1000) ;Prevent CPU Overloading
        $newUpdates = _GetUpdates()
        If Not StringInStr($newUpdates,'update_id') Then ContinueLoop
        $msgData = __MsgDecode($newUpdates)
        $Offset = $msgData[0] + 1
        Return $msgData
    WEnd
EndFunc ;==> _Polling

Func _CreateKeyboard(ByRef $Keyboard, $Resize = False, $OneTime = False)
    
    ;reply_markup={"keyboard":[["Yes","No"],["Maybe"],["1","2","3"]],"one_time_keyboard":true,"resize_keyboard":true}
    Local $jsonKeyboard = '{"keyboard":['
    For $i=0 to UBound($Keyboard)-1
        If($Keyboard[$i] <> '') Then
            If(StringRight($jsonKeyboard,1) = '"') Then
                $jsonKeyboard &= ',"'&$Keyboard[$i]&'"'
            Else
                $jsonKeyboard &= '["'&$Keyboard[$i]&'"'
            EndIf
        Else
            $jsonKeyboard &= '],'
        EndIf
    Next
    $jsonKeyboard &= ']]'

    If $Resize = True Then $jsonKeyboard &= ',"resize_keyboard":true'
    If $OneTime = True Then $jsonKeyboard &= ',"one_time_keyboard":true'

    $jsonKeyboard &= '}'

    Return $jsonKeyboard
EndFunc
#EndRegion

#Region "@SEND AND MEDIA FUNCTIONS"
Func _SendMsg($ChatID, $Text, $ParseMode = Default, $KeyboardMarkup = Default, $DisableWebPreview = False, $DisableNotification = False)
    Local $Query = $URL & "/sendMessage?chat_id=" & $ChatID & "&text=" & $Text
    If StringLower($ParseMode) = "markdown" Then $Query &= "&parse_mode=markdown"
    If StringLower($ParseMode) = "html" Then $Query &= "&parse_mode=html"
    If $DisableWebPreview = True Then $Query &= "&disable_web_page_preview=True"
    If $DisableNotification = True Then $Query &= "&disable_notification=True"
    If $KeyboardMarkup <> Default Then $Query &= "&reply_markup=" & $KeyboardMarkup    
    Local $Response = Json_Decode(HttpPost($Query))
	If Not (Json_IsObject($Response)) Then Return SetError(1,0,False) ;Check if json is valid
    If Not (Json_Get($Response,'[ok]') = 'true') Then Return SetError(2,0,False) ;Return false if send message faild
    Return Json_Get($Response,'[result][message_id]') ;Return message_id instead
EndFunc ;==> _SendMsg

Func _ForwardMsg($ChatID, $OriginalChatID, $MsgID, $DisableNotification = False)
    Local $Query = $URL & "/forwardMessage?chat_id=" & $ChatID & "&from_chat_id=" & $OriginalChatID & "&message_id=" & $MsgID
    If $DisableNotification Then $Query &= "&disable_notification=True"
    Local $Response = Json_Decode(HttpPost($Query))
    If Not (Json_IsObject($Response)) Then Return SetError(1,0,False) ;Check if json is valid
    If Not (Json_Get($Response,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return Json_Get($Response,'[result][message_id]') ;Return message_id instead
EndFunc ;==> _ForwardMsg

Func _SendPhoto($ChatID, $Path, $Caption = "", $KeyboardMarkup = Default, $DisableNotification = False)
    Local $Query = $URL & '/sendPhoto'
    Local $hOpen = _WinHttpOpen()
    Local $Form = '<form action="' & $Query & '" method="post" enctype="multipart/form-data">' & _
                    ' <input type="text" name="chat_id"/>' & _
                    ' <input type="file" name="photo"/>'   & _
                    ' <input type="text" name="caption"/>'
    If $KeyboardMarkup <> Default Then $Form &= ' <input type="text" name="reply_markup"/>'
    If $DisableNotification Then $Form &= ' <input type="text" name="disable_notification"/>'
    $Form &= '</form>'
    Local $Response = _WinHttpSimpleFormFill($Form, $hOpen, Default, _
                        "name:chat_id", $ChatID, _
                        "name:photo"  , $Path,   _
                        "name:caption", $Caption, _
                        "name:reply_markup", $KeyboardMarkup, _
                        "name:disable_notification", $DisableNotification)
    _WinHttpCloseHandle($hOpen)
    Local $Json = Json_Decode($Response)
    If Not (Json_IsObject($Json)) Then Return SetError(2,0,False) ;Check if json is valid
    Return __GetFileID($Json,'photo')
EndFunc ;==> _SendPhoto

Func _SendVideo($ChatID, $Path, $Caption = "", $KeyboardMarkup = Default, $DisableNotification = False)
    Local $Query = $URL & '/sendVideo'
    Local $hOpen = _WinHttpOpen()
    Local $Form = '<form action="' & $Query & '" method="post" enctype="multipart/form-data">' & _
                    ' <input type="text" name="chat_id"/>' & _
                    ' <input type="file" name="video"/>'   & _
                    ' <input type="text" name="caption"/>'
    If $KeyboardMarkup <> Default Then $Form &= ' <input type="text" name="reply_markup"/>'
    If $DisableNotification Then $Form &= ' <input type="text" name="disable_notification"/>'
    $Form &= '</form>'   
    Local $Response = _WinHttpSimpleFormFill($Form, $hOpen, Default, _
                        "name:chat_id", $ChatID, _
                        "name:video"  , $Path,   _
                        "name:caption", $Caption, _
                        "name:reply_markup", $KeyboardMarkup, _
                        "name:disable_notification", $DisableNotification)
    _WinHttpCloseHandle($hOpen)
    Local $Json = Json_Decode($Response)
    If Not (Json_IsObject($Json)) Then Return SetError(2,0,False) ;Check if json is valid
    Return __GetFileID($Json,'video')
EndFunc ;==> _SendVideo

Func _SendAudio($ChatID, $Path, $Caption = "", $KeyboardMarkup = Default, $DisableNotification = False)
    Local $Query = $URL & '/sendAudio'
    Local $hOpen = _WinHttpOpen()
    Local $Form = '<form action="' & $Query & '" method="post" enctype="multipart/form-data">' & _
                    ' <input type="text" name="chat_id"/>' & _
                    ' <input type="file" name="audio"/>'   & _
                    ' <input type="text" name="caption"/>'
    If $KeyboardMarkup <> Default Then $Form &= ' <input type="text" name="reply_markup"/>'
    If $DisableNotification Then $Form &= ' <input type="text" name="disable_notification"/>'
    $Form &= '</form>'   
    Local $Response = _WinHttpSimpleFormFill($Form, $hOpen, Default, _
                        "name:chat_id", $ChatID, _
                        "name:audio"  , $Path,   _
                        "name:caption", $Caption, _
                        "name:reply_markup", $KeyboardMarkup, _
                        "name:disable_notification", $DisableNotification)
    Local $Json = Json_Decode($Response)
    If Not (Json_IsObject($Json)) Then Return SetError(2,0,False) ;Check if json is valid
    Return __GetFileID($Json,'audio')
EndFunc ;==> _SendAudio

Func _SendDocument($ChatID, $Path, $Caption = "", $KeyboardMarkup = Default, $DisableNotification = False)
    Local $Query = $URL & '/sendDocument'
    Local $hOpen = _WinHttpOpen()
    Local $Form = '<form action="' & $Query & '" method="post" enctype="multipart/form-data">' & _
                    ' <input type="text" name="chat_id"/>'  & _
                    ' <input type="file" name="document"/>' & _
                    ' <input type="text" name="caption"/>'
    If $KeyboardMarkup <> Default Then $Form &= ' <input type="text" name="reply_markup"/>'
    If $DisableNotification Then $Form &= ' <input type="text" name="disable_notification"/>'
    $Form &= '</form>'   
    Local $Response = _WinHttpSimpleFormFill($Form, $hOpen, Default, _
                        "name:chat_id",  $ChatID, _
                        "name:document", $Path,   _
                        "name:caption",  $Caption, _
                        "name:reply_markup", $KeyboardMarkup, _
                        "name:disable_notification", $DisableNotification)
    _WinHttpCloseHandle($hOpen)
    Local $Json = Json_Decode($Response)
    If Not (Json_IsObject($Json)) Then Return SetError(2,0,False) ;Check if json is valid
    Return __GetFileID($Json,'document')
EndFunc ;==> _SendDocument

Func _SendVoice($ChatID, $Path, $Caption = "", $KeyboardMarkup = Default, $DisableNotification = False)
    Local $Query = $URL & '/sendVoice'
    Local $hOpen = _WinHttpOpen()
    Local $Form = '<form action="' & $Query & '" method="post" enctype="multipart/form-data">' & _
                    ' <input type="text" name="chat_id"/>' & _
                    ' <input type="file" name="voice"/>'   & _
                    ' <input type="text" name="caption"/>'
    If $KeyboardMarkup <> Default Then $Form &= ' <input type="text" name="reply_markup"/>'
    If $DisableNotification Then $Form &= ' <input type="text" name="disable_notification"/>'
    $Form &= '</form>'
    Local $Response = _WinHttpSimpleFormFill($Form, $hOpen, Default, _
                        "name:chat_id", $ChatID, _
                        "name:voice"  , $Path,   _
                        "name:caption", $Caption, _
                        "name:reply_markup", $KeyboardMarkup, _
                        "name:disable_notification", $DisableNotification)
    _WinHttpCloseHandle($hOpen)
    Local $Json = Json_Decode($Response)
    If Not (Json_IsObject($Json)) Then Return SetError(2,0,False) ;Check if json is valid
    Return __GetFileID($Json,'voice')
EndFunc ;==> _SendVoice

Func _SendSticker($ChatID,$Path, $KeyboardMarkup = Default, $DisableNotification = False)
    Local $Query = $URL & '/sendSticker'
    Local $hOpen = _WinHttpOpen()
    Local $Form = '<form action="' & $Query & '" method="post" enctype="multipart/form-data">' & _
                    ' <input type="text" name="chat_id"/>' & _
                    ' <input type="file" name="sticker"/>'
    If $KeyboardMarkup <> Default Then $Form &= ' <input type="text" name="reply_markup"/>'
    If $DisableNotification Then $Form &= ' <input type="text" name="disable_notification"/>'
    $Form &= '</form>'
    Local $Response = _WinHttpSimpleFormFill($Form, $hOpen, Default, _
                        "name:chat_id", $ChatID, _
                        "name:sticker", $Path, _
                        "name:reply_markup", $KeyboardMarkup, _
                        "name:disable_notification", $DisableNotification)
    _WinHttpCloseHandle($hOpen)
    Local $Json = Json_Decode($Response)
    If Not (Json_IsObject($Json)) Then Return SetError(2,0,False) ;Check if json is valid
    Return __GetFileID($Json,'sticker')
EndFunc

Func _SendVideoNote($ChatID,$Path,$KeyboardMarkup = Default, $DisableNotification = False)
    Local $Query = $URL & '/sendPhoto'
    Local $hOpen = _WinHttpOpen()
    Local $Form = '<form action="' & $Query & '" method="post" enctype="multipart/form-data">' & _
                    ' <input type="text" name="chat_id"/>' & _
                    ' <input type="file" name="video_note"/>'
    If $KeyboardMarkup <> Default Then $Form &= ' <input type="text" name="reply_markup"/>'
    If $DisableNotification Then $Form &= ' <input type="text" name="disable_notification"/>'
    $Form &= '</form>'
    Local $Response = _WinHttpSimpleFormFill($Form, $hOpen, Default, _
                        "name:chat_id", $ChatID, _
                        "name:video_note"  , $Path,   _
                        "name:reply_markup", $KeyboardMarkup, _
                        "name:disable_notification", $DisableNotification)
    _WinHttpCloseHandle($hOpen)
    Local $Json = Json_Decode($Response)
    If Not (Json_IsObject($Json)) Then Return SetError(2,0,False) ;Check if json is valid
    Return __GetFileID($Json,'videonote')
EndFunc

Func _SendChatAction($ChatID, $Action)

    #cs 
        typing for text messages, 
        upload_photo for photos, 
        record_video or upload_video for videos, 
        record_audio or upload_audio for audio files, 
        upload_document for general files, 
        find_location for location data, 
        record_video_note
        upload_video_note for video notes.
    #ce

    Local $Query = $URL & "/sendChatAction?chat_id=" & $ChatID & "&action=" & $Action
    Local $Response = Json_Decode(HttpPost($Query))
    If Not (Json_IsObject($Response)) Then Return SetError(2,0,False) ;Check if json is valid
    If Not (Json_Get($Response,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _SendChatAction

Func _SendLocation($ChatID, $Latitude, $Longitude)
    Local $Query = $URL & "/sendLocation?chat_id=" & $ChatID & "&latitude=" & $Latitude & "&longitude=" & $Longitude
    Local $Response = Json_Decode(HttpPost($Query))
    If Not (Json_IsObject($Response)) Then Return SetError(2,0,False) ;Check if json is valid
    If Not (Json_Get($Response,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _SendLocation

Func _SendContact($ChatID,$Phone,$Name)
    Local $Query = $URL & "/sendContact?chat_id=" & $ChatID & "&phone_number=" & $Phone & "&first_name=" & $Name
    Local $Response = Json_Decode(HttpPost($Query))
    If Not (Json_IsObject($Response)) Then Return SetError(2,0,False) ;Check if json is valid
    If Not (Json_Get($Response,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _SendContact

#EndRegion

#Region "@CHAT FUNCTIONS"

Func _GetUserProfilePhotos($ChatID,$Offset = "")
    $Query = $URL & "/getUserProfilePhotos?user_id=" & $ChatID
    If $Offset <> "" Then $Query &= "&offset=" & $Offset
    Local $Json = Json_Decode(HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError(2,0,False) ;Check if json is valid
    Local $count = Json_Get($Json,'[result][total_count]')
    Local $photoArray[$count + 1]
    $photoArray[0] = $count
    For $i=1 to $count
        ;probabile che non sempre sia disponibile il 2 quindi fare un catch
        $photoArray[$i] = Json_Get($Json,'[result][photos]['& $i-1 &'][2][file_id]')
    Next

    Return $photoArray
EndFunc ;==> _GetUserProfilePhotos

Func _GetChat($ChatID)
   Local $Query = $URL & "/getChat?chat_id=" & $ChatID
   Local $Response = HttpGet($Query)
   ConsoleWrite($Response)
   Return $Response
EndFunc

#EndRegion

#Region "@INTERNAL FUNCTIONS"

Func __GetFileID(ByRef $Json,$type)
    If($type = 'photo') Then Return Json_Get($Json,'[result][photo][2][file_id]')
    If($type = 'video') Then Return Json_Get($Json,'[result][video][file_id]')
    If($type = 'audio') Then Return Json_Get($Json,'[result][audio][file_id]')
    If($type = 'document') Then Return Json_Get($Json,'[result][document][file_id]')
    If($type = 'voice') Then Return Json_Get($Json,'[result][voice][file_id]')
    If($type = 'sticker') Then Return Json_Get($Json,'[result][sticker][file_id]')
    If($type = 'videonote') Then Return Json_Get($Json,'[result][video_note][file_id]')
EndFunc

Func __GetFilePath($FileID)
    Local $Query = $URL & "/getFile?file_id=" & $FileID
    Local $Response = Json_Decode(HttpPost($Query))
    Return Json_Get($Response,'[result][file_path]')
EndFunc

Func __DownloadFile($FilePath)
    Local $firstSplit = StringSplit($FilePath,'/')
    Local $fileName = $firstSplit[2]
    Local $Query = "https://api.telegram.org/file/bot" & $TOKEN & "/" & $FilePath
    InetGet($Query,$fileName)
    Return True
EndFunc

Func __MsgDecode($Update)
    Local $Json = Json_Decode($Update)

    ;@PRIVATE CHAT MESSAGE
    If(Json_Get($Json,'[result][0][message][chat][type]') = 'private') Then
        Local $msgData[10] = [ _
            Json_Get($Json,'[result][0][update_id]'), _ ;[0] = Offset
            Json_Get($Json,'[result][0][message][message_id]'), _ ;[1] = Message ID
            Json_Get($Json,'[result][0][message][from][id]'), _ ;[2] = Chat ID
            Json_Get($Json,'[result][0][message][from][username]'), _ ;[3] = Username
            Json_Get($Json,'[result][0][message][from][first_name]') _ ;[4] = Firstname
        ] 
        
        If(Json_Get($Json,'[result][0][message][text]')) Then $msgData[5] = Json_Get($Json,'[result][0][message][text]') ;[5] = Text (eventually)
        
        Return $msgData        
    EndIf
EndFunc ;==> _JSONDecode

#EndRegion


#Region "@HTTP Request"
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
#EndRegion