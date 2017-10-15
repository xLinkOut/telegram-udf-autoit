#include-once
#include "include/WinHttp.au3"
#include "include/JSON.au3"

;@GLOBAL
Global $TOKEN  = ''
Global $URL	   = "https://api.telegram.org/bot"
Global $Offset = 0

;@CONST
Const $BOT_CRLF = __UrlEncode(@CRLF)

#Region "@BOT MAIN FUNCTIONS"
Func _InitBot($Token)
	$TOKEN = $Token
	$URL &= $Token
    If(_GetMe() == False) Then
        ConsoleWrite("Ops! Error: reason may be invalid token, webhook active, internet connection..."&@CRLF)    
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

Func _CreateKeyboard(ByRef $Keyboard,$Resize = False,$OneTime = False)
    
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
EndFunc ;==> _CreateKeyboard

;@TODO
Func _CreateInlineKeyboard(ByRef $Keyboard)
    Local $jsonKeyboard = '{"inline_keyboard":[['
    Return $jsonKeyboard
#EndRegion

#Region "@SEND AND MEDIA FUNCTIONS"
Func _SendMsg($ChatID,$Text,$ParseMode = Default,$ReplyMarkup = Default,$ReplyToMessage = '',$DisableWebPreview = False,$DisableNotification = False)
    Local $Query = $URL & "/sendMessage?chat_id=" & $ChatID & "&text=" & $Text
    If StringLower($ParseMode) = "markdown" Then $Query &= "&parse_mode=markdown"
    If StringLower($ParseMode) = "html" Then $Query &= "&parse_mode=html"
    If $DisableWebPreview = True Then $Query &= "&disable_web_page_preview=True"
    If $DisableNotification = True Then $Query &= "&disable_notification=True"
    If $ReplyToMessage <> '' Then $Query &= "&reply_to_message_id=" & $ReplyToMessage
    If $ReplyMarkup <> Default Then $Query &= "&reply_markup=" & $ReplyMarkup    
    Local $Json = Json_Decode(HttpPost($Query))
	If Not (Json_IsObject($Json)) Then Return SetError(1,0,False) ;Check if json is valid
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False) ;Return false if send message faild
    Return Json_Get($Json,'[result][message_id]') ;Return message_id instead
EndFunc ;==> _SendMsg

Func _ForwardMsg($ChatID,$OriginalChatID,$MsgID,$DisableNotification = False)
    Local $Query = $URL & "/forwardMessage?chat_id=" & $ChatID & "&from_chat_id=" & $OriginalChatID & "&message_id=" & $MsgID
    If $DisableNotification Then $Query &= "&disable_notification=True"
    Local $Json = Json_Decode(HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError(1,0,False) ;Check if json is valid
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return Json_Get($Json,'[result][message_id]') ;Return message_id instead
EndFunc ;==> _ForwardMsg

Func _SendPhoto($ChatID,$Path,$Caption = '',$ReplyMarkup = Default,$ReplyToMessage = '',$DisableNotification = False)
    Local $Query = $URL & '/sendPhoto'
    Local $hOpen = _WinHttpOpen()
    Local $Form = '<form action="' & $Query & '" method="post" enctype="multipart/form-data">' & _
                  '<input type="text" name="chat_id"/>' & _
                  '<input type="file" name="photo"/>'   & _
                  '<input type="text" name="caption"/>'
    If $ReplyMarkup <> Default Then $Form &= '<input type="text" name="reply_markup"/>'
    If $ReplyToMessage <> '' Then $Query &= '<input type="text" name="reply_to_message_id"/>'
    If $DisableNotification Then $Form &= '<input type="text" name="disable_notification"/>'
    $Form &= '</form>'
    Local $Response = _WinHttpSimpleFormFill($Form,$hOpen,Default, _
                       "name:chat_id", $ChatID, _
                       "name:photo"  , $Path,   _
                       "name:caption", $Caption, _
                       "name:reply_markup", $ReplyMarkup, _
                       "name:reply_to_message_id", $ReplyToMessage, _
                       "name:disable_notification", $DisableNotification)
    _WinHttpCloseHandle($hOpen)
    Local $Json = Json_Decode($Response)
    If Not (Json_IsObject($Json)) Then Return SetError(2,0,False) ;Check if json is valid
    Return __GetFileID($Json,'photo')
EndFunc ;==> _SendPhoto

Func _SendVideo($ChatID,$Path,$Caption = '',$ReplyMarkup = Default,$ReplyToMessage = '',$DisableNotification = False)
    Local $Query = $URL & '/sendVideo'
    Local $hOpen = _WinHttpOpen()
    Local $Form = '<form action="' & $Query & '" method="post" enctype="multipart/form-data">' & _
                  '<input type="text" name="chat_id"/>' & _
                  '<input type="file" name="video"/>'   & _
                  '<input type="text" name="caption"/>'
    If $ReplyMarkup <> Default Then $Form &= ' <input type="text" name="reply_markup"/>'
    If $ReplyToMessage <> '' Then $Query &= '<input type="text" name="reply_to_message_id"/>'
    If $DisableNotification Then $Form &= ' <input type="text" name="disable_notification"/>'
    $Form &= '</form>'   
    Local $Response = _WinHttpSimpleFormFill($Form,$hOpen,Default, _
                       "name:chat_id", $ChatID, _
                       "name:video"  , $Path,   _
                       "name:caption", $Caption, _
                       "name:reply_markup", $ReplyMarkup, _
                       "name:reply_to_message_id", $ReplyToMessage, _
                       "name:disable_notification", $DisableNotification)
    _WinHttpCloseHandle($hOpen)
    Local $Json = Json_Decode($Response)
    If Not (Json_IsObject($Json)) Then Return SetError(2,0,False) ;Check if json is valid
    Return __GetFileID($Json,'video')
EndFunc ;==> _SendVideo

Func _SendAudio($ChatID,$Path,$Caption = '',$ReplyMarkup = Default,$ReplyToMessage = '',$DisableNotification = False)
    Local $Query = $URL & '/sendAudio'
    Local $hOpen = _WinHttpOpen()
    Local $Form = '<form action="' & $Query & '" method="post" enctype="multipart/form-data">' & _
                  '<input type="text" name="chat_id"/>' & _
                  '<input type="file" name="audio"/>'   & _
                  '<input type="text" name="caption"/>'
    If $ReplyMarkup <> Default Then $Form &= ' <input type="text" name="reply_markup"/>'
    If $ReplyToMessage <> '' Then $Query &= '<input type="text" name="reply_to_message_id"/>'
    If $DisableNotification Then $Form &= ' <input type="text" name="disable_notification"/>'
    $Form &= '</form>'   
    Local $Response = _WinHttpSimpleFormFill($Form,$hOpen,Default, _
                       "name:chat_id", $ChatID, _
                       "name:audio"  , $Path,   _
                       "name:caption", $Caption, _
                       "name:reply_markup", $ReplyMarkup, _
                       "name:reply_to_message_id", $ReplyToMessage, _
                       "name:disable_notification", $DisableNotification)
    _WinHttpCloseHandle($hOpen)
    Local $Json = Json_Decode($Response)
    If Not (Json_IsObject($Json)) Then Return SetError(2,0,False) ;Check if json is valid
    Return __GetFileID($Json,'audio')
EndFunc ;==> _SendAudio

Func _SendDocument($ChatID,$Path,$Caption = '',$ReplyMarkup = Default,$ReplyToMessage = '',$DisableNotification = False)
    Local $Query = $URL & '/sendDocument'
    Local $hOpen = _WinHttpOpen()
    Local $Form = '<form action="' & $Query & '" method="post" enctype="multipart/form-data">' & _
                  '<input type="text" name="chat_id"/>'  & _
                  '<input type="file" name="document"/>' & _
                  '<input type="text" name="caption"/>'
    If $ReplyMarkup <> Default Then $Form &= ' <input type="text" name="reply_markup"/>'
    If $ReplyToMessage <> '' Then $Query &= '<input type="text" name="reply_to_message_id"/>'
    If $DisableNotification Then $Form &= ' <input type="text" name="disable_notification"/>'
    $Form &= '</form>'   
    Local $Response = _WinHttpSimpleFormFill($Form,$hOpen,Default, _
                       "name:chat_id",  $ChatID, _
                       "name:document", $Path,   _
                       "name:caption",  $Caption, _
                       "name:reply_markup", $ReplyMarkup, _
                       "name:reply_to_message_id", $ReplyToMessage, _
                       "name:disable_notification", $DisableNotification)
    _WinHttpCloseHandle($hOpen)
    Local $Json = Json_Decode($Response)
    If Not (Json_IsObject($Json)) Then Return SetError(2,0,False) ;Check if json is valid
    Return __GetFileID($Json,'document')
EndFunc ;==> _SendDocument

Func _SendVoice($ChatID,$Path,$Caption = '',$ReplyMarkup = Default,$ReplyToMessage = '',$DisableNotification = False)
    Local $Query = $URL & '/sendVoice'
    Local $hOpen = _WinHttpOpen()
    Local $Form = '<form action="' & $Query & '" method="post" enctype="multipart/form-data">' & _
                  '<input type="text" name="chat_id"/>' & _
                  '<input type="file" name="voice"/>'   & _
                  '<input type="text" name="caption"/>'
    If $ReplyMarkup <> Default Then $Form &= ' <input type="text" name="reply_markup"/>'
    If $ReplyToMessage <> '' Then $Query &= '<input type="text" name="reply_to_message_id"/>'
    If $DisableNotification Then $Form &= ' <input type="text" name="disable_notification"/>'
    $Form &= '</form>'
    Local $Response = _WinHttpSimpleFormFill($Form,$hOpen,Default, _
                       "name:chat_id", $ChatID, _
                       "name:voice"  , $Path,   _
                       "name:caption", $Caption, _
                       "name:reply_markup", $ReplyMarkup, _
                       "name:reply_to_message_id", $ReplyToMessage, _
                       "name:disable_notification", $DisableNotification)
    _WinHttpCloseHandle($hOpen)
    Local $Json = Json_Decode($Response)
    If Not (Json_IsObject($Json)) Then Return SetError(2,0,False) ;Check if json is valid
    Return __GetFileID($Json,'voice')
EndFunc ;==> _SendVoice

Func _SendSticker($ChatID,$Path,$ReplyMarkup = Default,$ReplyToMessage = '',$DisableNotification = False)
    Local $Query = $URL & '/sendSticker'
    Local $hOpen = _WinHttpOpen()
    Local $Form = '<form action="' & $Query & '" method="post" enctype="multipart/form-data">' & _
                  '<input type="text" name="chat_id"/>' & _
                  '<input type="file" name="sticker"/>'
    If $ReplyMarkup <> Default Then $Form &= ' <input type="text" name="reply_markup"/>'
    If $ReplyToMessage <> '' Then $Query &= '<input type="text" name="reply_to_message_id"/>'
    If $DisableNotification Then $Form &= ' <input type="text" name="disable_notification"/>'
    $Form &= '</form>'
    Local $Response = _WinHttpSimpleFormFill($Form,$hOpen,Default, _
                       "name:chat_id", $ChatID, _
                       "name:sticker", $Path, _
                       "name:reply_markup", $ReplyMarkup, _
                       "name:reply_to_message_id", $ReplyToMessage, _
                       "name:disable_notification", $DisableNotification)
    _WinHttpCloseHandle($hOpen)
    Local $Json = Json_Decode($Response)
    If Not (Json_IsObject($Json)) Then Return SetError(2,0,False) ;Check if json is valid
    Return __GetFileID($Json,'sticker')
EndFunc ;==> _SendSticker

Func _SendVenue($ChatID,$Latitude,$Longitude,$Title,$Address,$Foursquare = '',$ReplyMarkup = Default,$ReplyToMessage = '',$DisableNotification = False)
    Local $Query = $URL & "/sendVenue?chat_id=" & $ChatID & "&latitude=" & $Latitude & "&longitude=" & $Longitude & "&title=" & $Title & "&address=" & $Address
    If $Foursquare <> '' Then $Query &= "&foursquare=" & $Foursquare    
    If $ReplyMarkup <> Default Then $Query &= "&reply_markup=" & $ReplyMarkup    
    If $ReplyToMessage <> '' Then $Query &= "&reply_to_message_id=" & $ReplyToMessage    
    If $DisableNotification Then $Query &= "&disable_notification=true"    
    Local $Json = Json_Decode(HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError(2,0,False) ;Check if json is valid
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _SendVenue

Func _SendVideoNote($ChatID,$Path,$ReplyMarkup = Default,$ReplyToMessage = '',$DisableNotification = False)
    Local $Query = $URL & '/sendPhoto'
    Local $hOpen = _WinHttpOpen()
    Local $Form = '<form action="' & $Query & '" method="post" enctype="multipart/form-data">' & _
                  '<input type="text" name="chat_id"/>' & _
                  '<input type="file" name="video_note"/>'
    If $ReplyMarkup <> Default Then $Form &= ' <input type="text" name="reply_markup"/>'
    If $ReplyToMessage <> '' Then $Query &= '<input type="text" name="reply_to_message_id"/>'
    If $DisableNotification Then $Form &= ' <input type="text" name="disable_notification"/>'
    $Form &= '</form>'
    Local $Response = _WinHttpSimpleFormFill($Form,$hOpen,Default, _
                       "name:chat_id", $ChatID, _
                       "name:video_note"  , $Path,   _
                       "name:reply_markup", $ReplyMarkup, _
                       "name:reply_to_message_id", $ReplyToMessage, _
                       "name:disable_notification", $DisableNotification)
    _WinHttpCloseHandle($hOpen)
    Local $Json = Json_Decode($Response)
    If Not (Json_IsObject($Json)) Then Return SetError(2,0,False) ;Check if json is valid
    Return __GetFileID($Json,'videonote')
EndFunc ;==> _SendVideoNote

Func _SendChatAction($ChatID,$Action)

    #cs 
        Valid action for _SendChatAction:
            typing for text messages,
            upload_photo for photos,
            record_video or upload_video for videos,
            record_audio or upload_audio for audio files,
            upload_document for general files,
            find_location for location data,
            record_video_note or upload_video_note for video notes.
    #ce

    Local $Query = $URL & "/sendChatAction?chat_id=" & $ChatID & "&action=" & $Action
    Local $Json = Json_Decode(HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError(2,0,False) ;Check if json is valid
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _SendChatAction

Func _SendLocation($ChatID,$Latitude,$Longitude,$LivePeriod = '',$ReplyMarkup = Default,$ReplyToMessage = '',$DisableNotification = False)
    Local $Query = $URL & "/sendLocation?chat_id=" & $ChatID & "&latitude=" & $Latitude & "&longitude=" & $Longitude
    If $LivePeriod <> '' Then $Query &= "&live_period=" & $LivePeriod    
    If $ReplyMarkup <> Default Then $Query &= "&reply_markup=" & $ReplyMarkup    
    If $ReplyToMessage <> '' Then $Query &= "&reply_to_message_id=" & $ReplyToMessage    
    If $DisableNotification Then $Query &= "&disable_notification=true"
    Local $Json = Json_Decode(HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError(2,0,False) ;Check if json is valid
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _SendLocation

Func _SendContact($ChatID,$Phone,$FirstName,$LastName = '',$ReplyMarkup = Default,$ReplyToMessage = '',$DisableNotification = False)
    Local $Query = $URL & "/sendContact?chat_id=" & $ChatID & "&phone_number=" & $Phone & "&first_name=" & $FirstName
    If $LastName <> '' Then $Query &= "&last_name=" & $LastName
    If $ReplyMarkup <> Default Then $Query &= "&reply_markup=" & $ReplyMarkup    
    If $ReplyToMessage <> '' Then $Query &= "&reply_to_message_id=" & $ReplyToMessage    
    If $DisableNotification = True Then $Query &= "&disable_notification=True"    
    Local $Json = Json_Decode(HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError(2,0,False) ;Check if json is valid
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _SendContact

Func _answerCallbackQuery($CallbackID,$Text = '',$URL = '',$ShowAlert = False,$CacheTime = '')
    Local $Query = $URL & "/_answerCallbackQuery?callback_query_id=" & $CallbackID
    If $Text <> '' Then $Query &= "&text=" & $Text
    If $URL <> '' Then $Query &= "&url=" & $URL    
    If $ShowAlert Then $Query &= "&show_alert=true"    
    If $CacheTime <> '' Then $Query &= "&cache_time=" & $CacheTime    
    Local $Json = Json_Decode(HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError(2,0,False) ;Check if json is valid
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _answerCallbackQuery

#EndRegion

#Region "@MISC CHAT FUNCTIONS"

Func _EditMessageLiveLocation($ChatID,$Latitude,$Longitude,$ReplyMarkup = Default)
    $Query = $URL & "/editMessageLiveLocation?chat_id=" & $ChatID & "&latitude=" & $Latitude & "&longitude=" & $Longitude 
    If $ReplyMarkup <> Default Then $Query &= "&reply_markup=" & $ReplyMarkup        
    Local $Json = Json_Decode(HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError(2,0,False) ;Check if json is valid
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc  ;==> _EditMessageLiveLocation

Func _StopMessageLiveLocation($ChatID,$ReplyMarkup = Default)
    $Query = $URL & "/stopMessageLiveLocation?chat_id=" & $ChatID
    If $ReplyMarkup <> Default Then $Query &= "&reply_markup=" & $ReplyMarkup    
    Local $Json = Json_Decode(HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError(2,0,False) ;Check if json is valid
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _StopMessageLiveLocation

Func _GetUserProfilePhotos($ChatID,$Offset = '',$Limit = '')
    $Query = $URL & "/getUserProfilePhotos?user_id=" & $ChatID
    If $Offset <> '' Then $Query &= "&offset=" & $Offset
    If $Limit <> '' Then $Query &= "&limit=" & $Limit
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

Func _KickChatMember($ChatID,$UserID,$UntilDate = '')
    $Query = $URL & "/kickChatMember?chat_id=" & $ChatID & "&user_id=" & $UserID
    If $UntilDate <> '' Then $Query &= "&until_date=" & $UntilDate    
    Local $Json = Json_Decode(HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError(2,0,False) ;Check if json is valid
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True    
EndFunc ;==> _KickChatMember

Func _UnbanChatMember($ChatID,$UserID)
    $Query = $URL & "/unbanChatMember?chat_id=" & $ChatID & "&user_id=" & $UserID
    Local $Json = Json_Decode(HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError(2,0,False) ;Check if json is valid
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True    
EndFunc ;==> _UnbanChatMember

Func _ExportChatInviteLink($ChatID)
    $Query = $URL & "/exportChatInviteLink?chat_id=" & $ChatID
    Local $Json = Json_Decode(HttpGet($Query))
    If Not (Json_IsObject($Json)) Then Return SetError(2,0,False) ;Check if json is valid
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return Json_Get($Json,'[result]')
EndFunc ;==> _ExportChatInviteLink

Func _SetChatPhoto($ChatID,$Path)
    Local $Query = $URL & '/setChatPhoto'
    Local $hOpen = _WinHttpOpen()
    Local $Form = '<form action="' & $Query & '" method="post" enctype="multipart/form-data">' & _
                  '<input type="text" name="chat_id"/>' & _
                  '<input type="file" name="photo"/>'   & _
                  '</form>'
    Local $Response = _WinHttpSimpleFormFill($Form,$hOpen,Default, _
                       "name:chat_id", $ChatID, _
                       "name:photo"  , $Path,
    _WinHttpCloseHandle($hOpen)
    Local $Json = Json_Decode($Response)
    If Not (Json_IsObject($Json)) Then Return SetError(2,0,False) ;Check if json is valid
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)    
    Return True
EndFunc ;==> _SetChatPhoto

Func _DeleteChatPhoto($ChatID)
    $Query = $URL & "/deleteChatPhoto?chat_id=" & $ChatID
    Local $Json = Json_Decode(HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError(2,0,False) ;Check if json is valid
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _DeleteChatPhoto

Func _SetChatTitle($ChatID,$Title)
    $Query = $URL & "/setChatTitle?chat_id=" & $ChatID & "&title=" & $Title
    Local $Json = Json_Decode(HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError(2,0,False) ;Check if json is valid
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _SetChatTitle

Func _SetChatDescription($ChatID,$Description)
    $Query = $URL & "/setChatDescription?chat_id=" & $ChatID & "&description=" & $Description
    Local $Json = Json_Decode(HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError(2,0,False) ;Check if json is valid
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _SetChatDescription

Func _PinChatMessage($ChatID,$MsgID,$DisableNotification = False)
    $Query = $URL & "/pinChatMessage?chat_id=" & $ChatID & "&message_id=" & $MsgID
    If $DisableNotification Then $Query &= "&disable_notification=true"    
    Local $Json = Json_Decode(HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError(2,0,False) ;Check if json is valid
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _PinChatMessage

Func _UnpinChatMessage($ChatID)
    $Query = $URL & "/unpinChatMessage?chat_id=" & $ChatID
    Local $Json = Json_Decode(HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError(2,0,False) ;Check if json is valid
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _UnpinChatMessage

Func _LeaveChat($ChatID)
    $Query = $URL & "/leaveChat?chat_id=" & $ChatID
    Local $Json = Json_Decode(HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError(2,0,False) ;Check if json is valid
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _LeaveChat

Func _GetChat($ChatID)
    Local $Query = $URL & "/getChat?chat_id=" & $ChatID
    Local $Json = Json_Decode(HttpGet($Query))
    If Not (Json_IsObject($Json)) Then Return SetError(2,0,False) ;Check if json is valid
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Local $chatData[4] = [ Json_Get($Json,'[result][id]'), _
                        Json_Get($Json,'[result][username]'), _
                        Json_Get($Json,'[result][first_name]'), _
                        Json_Get($Json,'[result][photo][big_file_id]')]
    Return $chatData
EndFunc ;==> _GetChat

;@TODO
Func _getChatAdministrators($ChatID)
    Local $Query = $URL & "/getChatAdministrators?chat_id=" & $ChatID
    ConsoleWrite(HttpGet($Query))
EndFunc ;==> _getChatAdministrators

;@TODO
Func _getChatMembersCount($ChatID)
    Local $Query = $URL & "/getChatMembersCount?chat_id=" & $ChatID
    ConsoleWrite(HttpGet($Query))
EndFunc ;==> _getChatMembersCount

;@TODO
Func _getChatMember($ChatID)
    Local $Query = $URL & "/getChatMember?chat_id=" & $ChatID
    ConsoleWrite(HttpGet($Query))
EndFunc ;==> _getChatMember

;@TODO
Func _setChatStickerSet($ChatID)
    Local $Query = $URL & "/setChatStickerSet?chat_id=" & $ChatID
    ConsoleWrite(HttpGet($Query))
EndFunc ;==> _setChatStickerSet

;@TODO
Func _deleteChatStickerSet($ChatID)
    Local $Query = $URL & "/deleteChatStickerSet?chat_id=" & $ChatID
    ConsoleWrite(HttpGet($Query))
EndFunc ;==> _deleteChatStickerSet

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
EndFunc ;==> __GetFileID

Func __GetFilePath($FileID)
    Local $Query = $URL & "/getFile?file_id=" & $FileID
    Local $Json = Json_Decode(HttpPost($Query))
    Return Json_Get($Json,'[result][file_path]')
EndFunc ;==> __GetFilePath

Func __DownloadFile($FilePath)
    Local $firstSplit = StringSplit($FilePath,'/')
    Local $fileName = $firstSplit[2]
    Local $Query = "https://api.telegram.org/file/bot" & $TOKEN & "/" & $FilePath
    InetGet($Query,$fileName)
    Return True
EndFunc ;==> __DownloadFile

Func __UrlEncode($string)
    $string = StringSplit($string, "")
    For $i=1 To $string[0]
        If AscW($string[$i]) < 48 Or AscW($string[$i]) > 122 Then
            $string[$i] = "%"&_StringToHex($string[$i])
        EndIf
    Next
    $string = _ArrayToString($string, "", 1)
    Return $string
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
        
        ;Insert media recognition here
        
        Return $msgData        
    
    ;@GROUP CHAT MESSAGE (Inlude left/new member events)
    ElseIf(Json_Get($Json,'[result][0][message][chat][type]') = 'group') or (Json_Get($Json,'[result][0][message][chat][type]') = 'supergroup') Then
        Local $msgData[10] = [ _
            Json_Get($Json,'[result][0][update_id]'), _ ;[0] = Offset
            Json_Get($Json,'[result][0][message][message_id]'), _ ;[1] = Message ID
            Json_Get($Json,'[result][0][message][from][id]'), _ ;[2] = User ID
            Json_Get($Json,'[result][0][message][from][username]'), _ ;[3] = Username
            Json_Get($Json,'[result][0][message][from][first_name]'), _ ;[4] = Firstname
            Json_Get($Json,'[result][0][message][chat][id]'), _ ;[5] = Group ID
            Json_Get($Json,'[result][0][message][chat][title]'), _ ;[6] = Group Name
        ]

        If(Json_Get($Json,'[result][0][message][left_chat_member]')) Then
            $msgData[7] = 'left' ;[7] = Event
            $msgData[8] = Json_Get($Json,'[result][0][message][from][id]') ;[8] = Left member ID
            $msgData[8] = Json_Get($Json,'[result][0][message][from][username]') ;[9] = Left member Username
            $msgData[8] = Json_Get($Json,'[result][0][message][from][first_name]') ;[10] = Left member Firstname
        ElseIf(Json_Get($Json,'[result][0][message][new_chat_member]')) Then
            $msgData[7] = 'new' ;[7] = Event
            $msgData[8] = Json_Get($Json,'[result][0][message][from][id]') ;[8] = New member ID
            $msgData[8] = Json_Get($Json,'[result][0][message][from][username]') ;[9] = New member Username
            $msgData[8] = Json_Get($Json,'[result][0][message][from][first_name]') ;[10] = New member Firstname
        Else
            $msgData[7] = Json_Get($Json,'[result][0][message][text]') ;[7] = Text
        EndIf

        Return $msgData

    ;@CALLBACK QUERY 
    ElseIf(Json_Get($Json,'[result][0][callback_query][id]') <> '') Then
        Local $msgData[10] = [ _
            Json_Get($Json,'[result][0][update_id]'), _ ;[0] = Offset
            Json_Get($Json,'[result][0][callback_query][id]'), _ ;[1] = Callback ID
            Json_Get($Json,'[result][0][callback_query][from][id]'), _ ;[2] = Chat ID
            Json_Get($Json,'[result][0][callback_query][from][username]'), _ ;[3] = Username
            Json_Get($Json,'[result][0][callback_query][from][first_name]') _ ;[4] = Firstname
            Json_Get($Json,'[result][0][callback_query][data]') _ ;[5] = Callback Data
        ]

        Return $msgData
    
    ;@INLINE QUERY
    ElseIf(Json_Get($Json,'[result][0][inline_query][id]') <> '') Then
        Local $msgData[10] = [ _
            Json_Get($Json,'[result][0][update_id]'), _ ;[0] = Offset
            Json_Get($Json,'[result][0][inline_query][id]'), _ ;[1] = Inline Query ID
            Json_Get($Json,'[result][0][inline_query][from][id]'), _ ;[2] = Chat ID
            Json_Get($Json,'[result][0][inline_query][from][username]'), _ ;[3] = Username
            Json_Get($Json,'[result][0][inline_query][from][first_name]') _ ;[4] = Firstname
            Json_Get($Json,'[result][0][inline_query][query]') _ ;[5] = Inline Query Data
        ]

        Return $msgData
    
    ;@CHANNEL MESSAGE (Where bot is admin)
    ElseIf(Json_Get($Json,'[result][0][channel_post][message_id]') <> '') Then
        Local $msgData[10] = [ _
            Json_Get($Json,'[result][0][update_id]'), _ ;[0] = Offset
            Json_Get($Json,'[result][0][channel_post][message_id]'), _ ;[1] = Message ID
            Json_Get($Json,'[result][0][channel_post][chat][id]'), _ ;[2] = Chat ID
            Json_Get($Json,'[result][0][channel_post][chat][username]'), _ ;[3] = Username
            Json_Get($Json,'[result][0][channel_post][chat][title]') _ ;[4] = Firstname
        ]

        If(Json_Get($Json,'[result][0][message][text]')) Then $msgData[5] = Json_Get($Json,'[result][0][message][text]') ;[5] = Text (eventually)

        Return $msgData

    EndIf

EndFunc ;==> __MsgDecode

#EndRegion


#Region "@HTTP Request"
Func HttpPost($sURL,$sData = '')
    Local $oHTTP = ObjCreate("WinHttp.WinHttpRequest.5.1")
    $oHTTP.Open("POST",$sURL,False)
    If (@error) Then Return SetError(1,0,0)
    $oHTTP.SetRequestHeader("Content-Type","application/x-www-form-urlencoded")
    $oHTTP.Send($sData)
    If (@error) Then Return SetError(2,0,0)
    If ($oHTTP.Status <> $HTTP_STATUS_OK) Then Return SetError(3,0,0)
    Return SetError(0,0,$oHTTP.ResponseText)
EndFunc ;==> HttpPost

Func HttpGet($sURL,$sData = '')
    Local $oHTTP = ObjCreate("WinHttp.WinHttpRequest.5.1")
    $oHTTP.Open("GET",$sURL & "?" & $sData,False)
    If (@error) Then Return SetError(1,0,0)
    $oHTTP.Send()
    If (@error) Then Return SetError(2,0,0)
    If ($oHTTP.Status <> $HTTP_STATUS_OK) Then Return SetError(3,0,0)
    Return SetError(0,0,$oHTTP.ResponseText)
EndFunc ;==> HttpGet
#EndRegion