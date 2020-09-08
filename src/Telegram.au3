#cs ------------------------------------------------------------------------------
   About:
		Author: Luca (@LinkOut)
		Description: Control Telegram Bot with AutoIt

   Documentation:
		Telegram API: https://core.telegram.org/bots/api
		GitHub Page:  https://github.com/xLinkOut/telegram-udf-autoit/

   Author Information:
		GitHub: https://github.com/xLinkOut

#ce ------------------------------------------------------------------------------

#include-once
#include "include/WinHttp.au3"
#include "include/JSON.au3"
#include <String.au3>
#include <Array.au3>

;@GLOBAL
Global $TOKEN  = ""
Global $URL	   = "https://api.telegram.org/bot"
Global $OFFSET = 0

;@CONST
Const $BOT_CRLF = _Telegram_UrlEncode(@CRLF)
Const $INVALID_TOKEN_ERROR = 1
Const $FILE_NOT_DOWNLOADED = 2
Const $OFFSET_GRATER_THAN_TOTAL = 3
Const $INVALID_JSON_RESPONSE = 4

;@ObjEvents
$oMyError = ObjEvent("AutoIt.Error","_Telegram_HttpCrashHandler")

#Region "@ENDPOINT FUNCTIONS"

#cs ===============================================================================
   Function Name..:    	_TelegramGetUpdates
   Description....:     Used by _Polling() to get new messages
   Parameter(s)...:     None
   Return Value(s): 	Return string with information encoded in JSON format
#ce ===============================================================================
Func _TelegramGetUpdates()
    Return _Telegram_HttpGet($URL & "/getUpdates?offset=" & $OFFSET)
EndFunc ;==> _TelegramGetUpdates

#cs ===============================================================================
   Function Name..:    	_TelegramGetMe
   Description....:     Get information about the bot (ID,Username,First name,Last name)
   Parameter(s)...:     None
   Return Value(s):		Return an array with information
#ce ===============================================================================
Func _TelegramGetMe()
	Local $json = Json_Decode(_Telegram_HttpGet($URL & "/getMe"))
	If Not (Json_IsObject($json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ;Check if json is valid
	Local $data[4] = [Json_Get($json,'[result][id]'), _
				   	  Json_Get($json,'[result][username]'), _
			   		  Json_Get($json,'[result][first_name]'), _
			   		  Json_Get($json,'[result][last_name]')]
	Return $data
EndFunc ;==>_TelegramGetMe

#cs ===============================================================================
   Function Name..:		_SendMsg
   Description....:     Send a text message
   Parameter(s)...:     $ChatID: Unique identifier for the target chat
						$Text: Text of the message
						$ParseMode (optional): Markdown/HTML (optional)- https://core.telegram.org/bots/api#sendmessage
                        $ReplyMarkup (optional): Custom keyboard markup;
						$ReplyToMessage (optional): If the message is a reply, ID of the original message
                        $DisableWebPreview (optional): Disables link previews for links in this message
                        $DisableNotification (optional): Sends the message silently. User will receive a notification with no sound
   Return Value(s):  	Return the Message ID if no error encountered, False otherwise
#ce ===============================================================================
Func _TelegramSendMsg($ChatID,$Text,$ParseMode = Default,$ReplyMarkup = Default,$ReplyToMessage = '',$DisableWebPreview = False,$DisableNotification = False)
    Local $Query = $URL & "/sendMessage?chat_id=" & $ChatID & "&text=" & $Text
    If StringLower($ParseMode) = "markdown" Then $Query &= "&parse_mode=markdown"
    If StringLower($ParseMode) = "html" Then $Query &= "&parse_mode=html"
    If $DisableWebPreview = True Then $Query &= "&disable_web_page_preview=True"
    If $DisableNotification = True Then $Query &= "&disable_notification=True"
    If $ReplyToMessage <> '' Then $Query &= "&reply_to_message_id=" & $ReplyToMessage
    If $ReplyMarkup <> Default Then $Query &= "&reply_markup=" & $ReplyMarkup
    Local $Json = Json_Decode(_Telegram_HttpPost($Query))
	If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ;Check if json is valid
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False) ;Return false if send message faild
    Return Json_Get($Json,'[result][message_id]') ;Return message_id instead
EndFunc ;==> _SendMsg

#cs ===============================================================================
   Function Name..:		_ForwardMessage
   Description....:     Forward a message from a chat to another
   Parameter(s)...:     $ChatID: Unique identifier for the target chat
						$OriginalChatID: Unique identifier for the chat where the original message was sent
						$MsgID: Message identifier in the chat specified in from_chat_id
                        $DisableNotification (optional): Sends the message silently. User will receive a notification with no sound
   Return Value(s):  	Return the new Message ID if no error encountered, False otherwise
#ce ===============================================================================
Func _TelegramForwardMessage($ChatID,$OriginalChatID,$MsgID,$DisableNotification = False)
    Local $Query = $URL & "/forwardMessage?chat_id=" & $ChatID & "&from_chat_id=" & $OriginalChatID & "&message_id=" & $MsgID
    If $DisableNotification Then $Query &= "&disable_notification=True"
    Local $Json = Json_Decode(_Telegram_HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ;Check if json is valid
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return Json_Get($Json,'[result][message_id]') ;Return message_id instead
EndFunc ;==> _ForwardMessage

#cs ===============================================================================
   Function Name..:		_SendPhoto
   Description....:     Send a photo
   Parameter(s)...:     $ChatID: Unique identifier for the target chat
						$Photo: Path to a local file, a File ID as string or an HTTP URL
						$Caption (optional): Caption to send with photo
                        $ReplyMarkup (optional): Custom keyboard markup;
                        $ReplyToMessage (optional): If the message is a reply, ID of the original message
                        $DisableNotification (optional): Sends the message silently. User will receive a notification with no sound
   Return Value(s):  	Return the File ID of the photo as string
#ce ===============================================================================
Func _TelegramSendPhoto($ChatID,$Photo,$Caption = '',$ReplyMarkup = Default,$ReplyToMessage = '',$DisableNotification = False)
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
                       "name:photo"  , $Photo,   _
                       "name:caption", $Caption, _
                       "name:reply_markup", $ReplyMarkup, _
                       "name:reply_to_message_id", $ReplyToMessage, _
                       "name:disable_notification", $DisableNotification)
    _WinHttpCloseHandle($hOpen)
    Local $Json = Json_Decode($Response)
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    Return _Telegram_GetFileID($Json,'photo')
EndFunc ;==> _SendPhoto

#cs ===============================================================================
   Function Name..:		_SendAudio
   Description....:     Send an audio
   Parameter(s)...:     $ChatID: Unique identifier for the target chat
                        $Audio: Path to a local file, a File ID as string or an HTTP URL
                        $Caption (optional): Caption to send with audio
                        $ReplyMarkup (optional): Custom keyboard markup;
                        $ReplyToMessage (optional): If the message is a reply, ID of the original message
                        $DisableNotification (optional): Sends the message silently. User will receive a notification with no sound
   Return Value(s):  	Return the File ID of the audio as string
#ce ===============================================================================
Func _TelegramSendAudio($ChatID,$Audio,$Caption = '',$ReplyMarkup = Default,$ReplyToMessage = '',$DisableNotification = False)
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
                       "name:audio"  , $Audio,   _
                       "name:caption", $Caption, _
                       "name:reply_markup", $ReplyMarkup, _
                       "name:reply_to_message_id", $ReplyToMessage, _
                       "name:disable_notification", $DisableNotification)
    _WinHttpCloseHandle($hOpen)
    Local $Json = Json_Decode($Response)
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    Return _Telegram_GetFileID($Json,'audio')
EndFunc ;==> _SendAudio

#cs ===============================================================================
   Function Name..:		_SendDocument
   Description....:     Send a document
   Parameter(s)...:     $ChatID: Unique identifier for the target chat
                        $Document: Path to a local file, a File ID as string or an HTTP URL
                        $Caption (optional): Caption to send with document
                        $ReplyMarkup (optional): Custom keyboard markup;
                        $ReplyToMessage (optional): If the message is a reply, ID of the original message
                        $DisableNotification (optional): Sends the message silently. User will receive a notification with no sound
   Return Value(s):  	Return the File ID of the document as string
#ce ===============================================================================
Func _TelegramSendDocument($ChatID,$Document,$Caption = '',$ReplyMarkup = Default,$ReplyToMessage = '',$DisableNotification = False)
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
                       "name:document", $Document,   _
                       "name:caption",  $Caption, _
                       "name:reply_markup", $ReplyMarkup, _
                       "name:reply_to_message_id", $ReplyToMessage, _
                       "name:disable_notification", $DisableNotification)
    _WinHttpCloseHandle($hOpen)
    Local $Json = Json_Decode($Response)
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    Return _Telegram_GetFileID($Json,'document')
EndFunc ;==> _SendDocument

#cs ===============================================================================
   Function Name..:		_SendVideo
   Description....:     Send a video
   Parameter(s)...:     $ChatID: Unique identifier for the target chat
						$Video: Path to a local file, a File ID as string or an HTTP URL
						$Caption (optional): Caption to send with video
                        $ReplyMarkup (optional): Custom keyboard markup;
                        $ReplyToMessage (optional): If the message is a reply, ID of the original message
                        $DisableNotification (optional): Sends the message silently. User will receive a notification with no sound
   Return Value(s):  	Return the File ID of the video as string
#ce ===============================================================================
Func _TelegramSendVideo($ChatID,$Video,$Caption = '',$ReplyMarkup = Default,$ReplyToMessage = '',$DisableNotification = False)
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
                       "name:video"  , $Video,   _
                       "name:caption", $Caption, _
                       "name:reply_markup", $ReplyMarkup, _
                       "name:reply_to_message_id", $ReplyToMessage, _
                       "name:disable_notification", $DisableNotification)
    _WinHttpCloseHandle($hOpen)
    Local $Json = Json_Decode($Response)
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    Return _Telegram_GetFileID($Json,'video')
EndFunc ;==> _SendVideo

#cs ===============================================================================
   Function Name..:		_SendAnimation
   Description....:     Send animation file (GIF or video without sound)
   Parameter(s)...:     $ChatID: Unique identifier for the target chat
						$Animation: Path to a local file, a File ID as string or an HTTP URL
						$Caption (optional): Caption to send with;
                        $ReplyMarkup (optional): Custom keyboard markup;
                        $ReplyToMessage (optional): If the message is a reply, ID of the original message
                        $DisableNotification (optional): Sends the message silently. User will receive a notification with no sound
   Return Value(s):  	Return the File ID of the video as string
#ce ===============================================================================
Func _TelegramSendAnimation($ChatID,$Animation,$Caption = '',$ReplyMarkup = Default,$ReplyToMessage = '',$DisableNotification = False)
    Local $Query = $URL & '/sendAnimation'
    Local $hOpen = _WinHttpOpen()
    Local $Form = '<form action="' & $Query & '" method="post" enctype="multipart/form-data">' & _
                  '<input type="text" name="chat_id"/>' & _
                  '<input type="file" name="animation"/>'   & _
                  '<input type="text" name="caption"/>'
    If $ReplyMarkup <> Default Then $Form &= ' <input type="text" name="reply_markup"/>'
    If $ReplyToMessage <> '' Then $Query &= '<input type="text" name="reply_to_message_id"/>'
    If $DisableNotification Then $Form &= ' <input type="text" name="disable_notification"/>'
    $Form &= '</form>'
    Local $Response = _WinHttpSimpleFormFill($Form,$hOpen,Default, _
                       "name:chat_id", $ChatID, _
                       "name:animation", $Animation,   _
                       "name:caption", $Caption, _
                       "name:reply_markup", $ReplyMarkup, _
                       "name:reply_to_message_id", $ReplyToMessage, _
                       "name:disable_notification", $DisableNotification)
    _WinHttpCloseHandle($hOpen)
    Local $Json = Json_Decode($Response)
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    Return _Telegram_GetFileID($Json,'animation')
EndFunc ;==> _SendAnimation


#cs ===============================================================================
   Function Name..:		_SendVoice
   Description....:     Send a voice file
   Parameter(s)...:     $ChatID: Unique identifier for the target chat
						$Path: Path to a local file (format: .ogg)
						$Caption (optional): Caption to send with voice
                        $ReplyMarkup (optional): Custom keyboard markup;
                        $ReplyToMessage (optional): If the message is a reply, ID of the original message
                        $DisableNotification (optional): Sends the message silently. User will receive a notification with no sound
   Return Value(s):  	Return the File ID of the voice as string
#ce ===============================================================================
Func _TelegramSendVoice($ChatID,$Path,$Caption = '',$ReplyMarkup = Default,$ReplyToMessage = '',$DisableNotification = False)
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
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    Return _Telegram_GetFileID($Json,'voice')
EndFunc ;==> _SendVoice

#cs ===============================================================================
   Function Name..:		_SendVideoNote
   Description....:     Send a voice file
   Parameter(s)...:     $ChatID: Unique identifier for the target chat
						$VideoNote: Path to a local file, a File ID as string or an HTTP URL
                        $ReplyMarkup (optional): Custom keyboard markup;
                        $ReplyToMessage (optional): If the message is a reply, ID of the original message
                        $DisableNotification (optional): Sends the message silently. User will receive a notification with no sound
   Return Value(s):  	Return the File ID of the videonote as string
#ce ===============================================================================
Func _TelegramSendVideoNote($ChatID,$VideoNote,$ReplyMarkup = Default,$ReplyToMessage = '',$DisableNotification = False)
    Local $Query = $URL & '/sendVideoNote'
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
                       "name:video_note"  , $VideoNote,   _
                       "name:reply_markup", $ReplyMarkup, _
                       "name:reply_to_message_id", $ReplyToMessage, _
                       "name:disable_notification", $DisableNotification)
    _WinHttpCloseHandle($hOpen)
    Local $Json = Json_Decode($Response)
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    Return _Telegram_GetFileID($Json,'videonote')
EndFunc ;==> _SendVideoNote

#cs ===============================================================================
   Function Name..:		_SendMediaGroup
   Description....:     Send a voice file
   Parameter(s)...:     $ChatID: Unique identifier for the target chat
						$Media: JSON-serialized array describing photos and videos to be sent, must include 2–10 items
                        $ReplyToMessage (optional): If the message is a reply, ID of the original message
                        $DisableNotification (optional): Sends the message silently. User will receive a notification with no sound
   Return Value(s):  	Return an array with all File IDs of the medias sent
#ce ===============================================================================
Func _TelegramSendMediaGroup($ChatID,$Media,$ReplyToMessage = '',$DisableNotification = False)
    Local $Query = $URL & '/sendMediaGroup'
    Local $hOpen = _WinHttpOpen()
    Local $Form = '<form action="' & $Query & '" method="post" enctype="multipart/form-data">' & _
                  '<input type="text" name="chat_id"/>' & _
                  '<input type="file" name="mediagroup"/>'
    If $ReplyToMessage <> '' Then $Query &= '<input type="text" name="reply_to_message_id"/>'
    If $DisableNotification Then $Form &= ' <input type="text" name="disable_notification"/>'
    $Form &= '</form>'
    Local $Response = _WinHttpSimpleFormFill($Form,$hOpen,Default, _
                       "name:chat_id", $ChatID, _
                       "name:media", $Media, _
                       "name:reply_to_message_id", $ReplyToMessage, _
                       "name:disable_notification", $DisableNotification)

    _WinHttpCloseHandle($hOpen)
    Local $Json = Json_Decode($Response)
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    Return _Telegram_GetFileID($Json,'mediagroup')
EndFunc ;==> _SendMediaGroup

#cs ===============================================================================
   ; DEPRECATED?
   Function Name..:		_SendSticker
   Description....:     Send a sticker
   Parameter(s)...:     $ChatID: Unique identifier for the target chat
						$Path: Path to a local file (format: .webp)
                        $ReplyMarkup (optional): Custom keyboard markup;
                        $ReplyToMessage (optional): If the message is a reply, ID of the original message
                        $DisableNotification (optional): Sends the message silently. User will receive a notification with no sound
   Return Value(s):  	Return the File ID of the sticker as string
#ce ===============================================================================
Func _TelegramSendSticker($ChatID,$Path,$ReplyMarkup = Default,$ReplyToMessage = '',$DisableNotification = False)
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
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    Return _Telegram_GetFileID($Json,'sticker')
EndFunc ;==> _SendSticker

#cs ===============================================================================
   Function Name..:		_SendLocation
   Description....:     Send a location object
   Parameter(s)...:     $ChatID: Unique identifier for the target chat
						$Latitude: Latitute of the location
						$Longitude: Longitude of the location
						$LivePeriod : Period in seconds for which the location will be updated, should be between 60 and 86400
                        $ReplyMarkup (optional): Custom keyboard markup;
                        $ReplyToMessage (optional): If the message is a reply, ID of the original message
                        $DisableNotification (optional): Sends the message silently. User will receive a notification with no sound
   Return Value(s):  	Return True if no error encountered, False otherwise
#ce ===============================================================================
Func _TelegramSendLocation($ChatID,$Latitude,$Longitude,$LivePeriod = '',$ReplyMarkup = Default,$ReplyToMessage = '',$DisableNotification = False)
    Local $Query = $URL & "/sendLocation?chat_id=" & $ChatID & "&latitude=" & $Latitude & "&longitude=" & $Longitude
    If $LivePeriod <> '' Then $Query &= "&live_period=" & $LivePeriod
    If $ReplyMarkup <> Default Then $Query &= "&reply_markup=" & $ReplyMarkup
    If $ReplyToMessage <> '' Then $Query &= "&reply_to_message_id=" & $ReplyToMessage
    If $DisableNotification Then $Query &= "&disable_notification=true"
    Local $Json = Json_Decode(_Telegram_HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _SendLocation

; TODO: Comments
Func _TelegramEditMessageLiveLocation($ChatID,$Latitude,$Longitude,$ReplyMarkup = Default)
    $Query = $URL & "/editMessageLiveLocation?chat_id=" & $ChatID & "&latitude=" & $Latitude & "&longitude=" & $Longitude
    If $ReplyMarkup <> Default Then $Query &= "&reply_markup=" & $ReplyMarkup
    Local $Json = Json_Decode(_Telegram_HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc  ;==> _EditMessageLiveLocation

; TODO: Comments
Func _TelegramStopMessageLiveLocation($ChatID,$ReplyMarkup = Default)
    $Query = $URL & "/stopMessageLiveLocation?chat_id=" & $ChatID
    If $ReplyMarkup <> Default Then $Query &= "&reply_markup=" & $ReplyMarkup
    Local $Json = Json_Decode(_Telegram_HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _StopMessageLiveLocation


;@TODO Comment
Func _TelegramSendVenue($ChatID,$Latitude,$Longitude,$Title,$Address,$Foursquare = '',$ReplyMarkup = Default,$ReplyToMessage = '',$DisableNotification = False)
    Local $Query = $URL & "/sendVenue?chat_id=" & $ChatID & "&latitude=" & $Latitude & "&longitude=" & $Longitude & "&title=" & $Title & "&address=" & $Address
    If $Foursquare <> '' Then $Query &= "&foursquare=" & $Foursquare
    If $ReplyMarkup <> Default Then $Query &= "&reply_markup=" & $ReplyMarkup
    If $ReplyToMessage <> '' Then $Query &= "&reply_to_message_id=" & $ReplyToMessage
    If $DisableNotification Then $Query &= "&disable_notification=true"
    Local $Json = Json_Decode(_Telegram_HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _SendVenue

#cs ===============================================================================
   Function Name..:		_SendContact
   Description....:     Send a contact object
   Parameter(s)...:     $ChatID: Unique identifier for the target chat
						$Phone: Phone number of the contact;
						$FirstName: First name of the contact;
						$LastName (optional): Last name of the contact;
						$ReplyMarkup (optional): Custom keyboard markup;
						$ReplyToMessage (optional): If is a reply to another user's message;
						$DisableNotification (optional): Sends the message silently. User will receive a notification with no sound
   Return Value(s):  	Return True if no error encountered, False otherwise
#ce ===============================================================================
Func _TelegramSendContact($ChatID,$Phone,$FirstName,$LastName = '',$ReplyMarkup = Default,$ReplyToMessage = '',$DisableNotification = False)
    Local $Query = $URL & "/sendContact?chat_id=" & $ChatID & "&phone_number=" & $Phone & "&first_name=" & $FirstName
    If $LastName <> '' Then $Query &= "&last_name=" & $LastName
    If $ReplyMarkup <> Default Then $Query &= "&reply_markup=" & $ReplyMarkup
    If $ReplyToMessage <> '' Then $Query &= "&reply_to_message_id=" & $ReplyToMessage
    If $DisableNotification = True Then $Query &= "&disable_notification=True"
    Local $Json = Json_Decode(_Telegram_HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _SendContact

; TODO: sendPoll

#cs ===============================================================================
   Function Name..:		_SendChatAction
   Description....:     tell the user that something is happening on the bot's side (Bot is typing...)
   Parameter(s)...:     $ChatID: Unique identifier for the target chat
						$Action: Type of the action:
                            typing for text messages,
                            upload_photo for photos,
                            record_video or upload_video for videos,
                            record_audio or upload_audio for audio files,
                            upload_document for general files,
                            find_location for location data,
                            record_video_note or upload_video_note for video notes.
   Return Value(s):  	Return True if no error encountered, False otherwise
#ce ===============================================================================
Func _TelegramSendChatAction($ChatID,$Action)
    Local $Query = $URL & "/sendChatAction?chat_id=" & $ChatID & "&action=" & $Action
    Local $Json = Json_Decode(_Telegram_HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _SendChatAction

#cs ===============================================================================
   Function Name..:		_GetUserProfilePhotos
   Description....:     Get (all) the profile pictures of an user
   Parameter(s)...:     $ChatID: Unique identifier for the target chat
						$Offset (optional): if you want a specific photo
						$Limit (optional): if you want only an x number of photos ;@TODO
   Return Value(s):  	Return an array with photo's count and File ID of the photos
#ce ===============================================================================
Func _TelegramGetUserProfilePhotos($ChatID,$Offset = '',$Limit = '')
    $Query = $URL & "/getUserProfilePhotos?user_id=" & $ChatID
    If $Offset <> '' Then $Query &= "&offset=" & $Offset
    If $Limit <> '' Then $Query &= "&limit=" & $Limit
    Local $Json = Json_Decode(_Telegram_HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError(2,0,False)

    Local $count = Json_Get($Json,'[result][total_count]')

    If $Offset >= $count Then Return SetError($OFFSET_GRATER_THAN_TOTAL,0,False)

    If $Limit <> '' And $Limit < $count Then
        Local $photoArray[$Limit+1]
        $photoArray[0] = $Limit
    Else
        Local $photoArray[$count + 1]
        $photoArray[0] = $count
    EndIf

    For $i=1 to $photoArray[0]
        $photoArray[$i] = Json_Get($Json,'[result][photos]['& $i-1 &'][2][file_id]')
        If $photoArray[$i] == '' Then
            $photoArray[$i] = Json_Get($Json,'[result][photos]['& $i-1 &'][1][file_id]')
            If $photoArray[$i] == '' Then
                $photoArray[$i] = Json_Get($Json,'[result][photos]['& $i-1 &'][0][file_id]')
            EndIf
        EndIf
        ;A way like pythonic len([result][photos]) to know the lenght of this sub-array?
    Next

    Return $photoArray
EndFunc ;==> _GetUserProfilePhotos

; TODO: getFile


; TODO: comment
Func _TelegramKickChatMember($ChatID,$UserID,$UntilDate = '')
    $Query = $URL & "/kickChatMember?chat_id=" & $ChatID & "&user_id=" & $UserID
    If $UntilDate <> '' Then $Query &= "&until_date=" & $UntilDate
    Local $Json = Json_Decode(_Telegram_HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _KickChatMember

; TODO: comment
Func _TelegramUnbanChatMember($ChatID,$UserID)
    $Query = $URL & "/unbanChatMember?chat_id=" & $ChatID & "&user_id=" & $UserID
    Local $Json = Json_Decode(_Telegram_HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _UnbanChatMember

; TODO: restrictChatMember

; TODO: promoteChatMember

; TODO: setChatPermission

; TODO: comment
Func _TelegramExportChatInviteLink($ChatID)
    $Query = $URL & "/exportChatInviteLink?chat_id=" & $ChatID
    Local $Json = Json_Decode(_Telegram_HttpGet($Query))
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return Json_Get($Json,'[result]')
EndFunc ;==> _ExportChatInviteLink

; TODO: comment
Func _TelegramSetChatPhoto($ChatID,$Path)
    Local $Query = $URL & '/setChatPhoto'
    Local $hOpen = _WinHttpOpen()
    Local $Form = '<form action="' & $Query & '" method="post" enctype="multipart/form-data">' & _
                  '<input type="text" name="chat_id"/>' & _
                  '<input type="file" name="photo"/>'   & _
                  '</form>'
    Local $Response = _WinHttpSimpleFormFill($Form,$hOpen,Default, _
                       "name:chat_id", $ChatID, _
                       "name:photo"  , $Path)
    _WinHttpCloseHandle($hOpen)
    Local $Json = Json_Decode($Response)
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _SetChatPhoto

; TODO: comment
Func _TelegramDeleteChatPhoto($ChatID)
    $Query = $URL & "/deleteChatPhoto?chat_id=" & $ChatID
    Local $Json = Json_Decode(_Telegram_HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _DeleteChatPhoto

; TODO: comment
Func _TelegramSetChatTitle($ChatID,$Title)
    $Query = $URL & "/setChatTitle?chat_id=" & $ChatID & "&title=" & $Title
    Local $Json = Json_Decode(_Telegram_HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _SetChatTitle

; TODO: comment
Func _TelegramSetChatDescription($ChatID,$Description)
    $Query = $URL & "/setChatDescription?chat_id=" & $ChatID & "&description=" & $Description
    Local $Json = Json_Decode(_Telegram_HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _SetChatDescription

; TODO: comment
Func _TelegramPinChatMessage($ChatID,$MsgID,$DisableNotification = False)
    $Query = $URL & "/pinChatMessage?chat_id=" & $ChatID & "&message_id=" & $MsgID
    If $DisableNotification Then $Query &= "&disable_notification=true"
    Local $Json = Json_Decode(_Telegram_HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _PinChatMessage

; TODO: comment
Func _TelegramUnpinChatMessage($ChatID)
    $Query = $URL & "/unpinChatMessage?chat_id=" & $ChatID
    Local $Json = Json_Decode(_Telegram_HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _UnpinChatMessage

; TODO: comment
Func _TelegramLeaveChat($ChatID)
    $Query = $URL & "/leaveChat?chat_id=" & $ChatID
    Local $Json = Json_Decode(_Telegram_HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _LeaveChat

#cs ===============================================================================
   Function Name..:		_GetChat
   Description....:     Get information about the specified chat, like username and id of the user, or group name for group chat
   Parameter(s)...:     $ChatID: Unique identifier for the target chat
   Return Value(s):  	Return an array ;@TODO group support
#ce ===============================================================================
Func _TelegramGetChat($ChatID)
    Local $Query = $URL & "/getChat?chat_id=" & $ChatID
    Local $Json = Json_Decode(_Telegram_HttpGet($Query))
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Local $chatData[5] = [ Json_Get($Json,'[result][id]'), _
                        Json_Get($Json,'[result][username]'), _
                        Json_Get($Json,'[result][first_name]'), _
                        Json_Get($Json,'[result][last_name]'), _
                        Json_Get($Json,'[result][photo][big_file_id]')]
    Return $chatData
EndFunc ;==> _GetChat

; TODO: getChatAdministrators
Func _TelegramgetChatAdministrators($ChatID)
    Local $Query = $URL & "/getChatAdministrators?chat_id=" & $ChatID
    ConsoleWrite(_Telegram_HttpGet($Query))
EndFunc ;==> _getChatAdministrators

; TODO: getChatMembersCount
Func _TelegramgetChatMembersCount($ChatID)
    Local $Query = $URL & "/getChatMembersCount?chat_id=" & $ChatID
    ConsoleWrite(_Telegram_HttpGet($Query))
EndFunc ;==> _getChatMembersCount

; TODO: getchatmember
Func _TelegramgetChatMember($ChatID)
    Local $Query = $URL & "/getChatMember?chat_id=" & $ChatID
    ConsoleWrite(_Telegram_HttpGet($Query))
EndFunc ;==> _getChatMember

; TODO: sertchatstrickerset
Func _TelegramsetChatStickerSet($ChatID)
    Local $Query = $URL & "/setChatStickerSet?chat_id=" & $ChatID
    ConsoleWrite(_Telegram_HttpGet($Query))
EndFunc ;==> _setChatStickerSet

; TODO: deletechatstrickerset
Func _TelegramdeleteChatStickerSet($ChatID)
    Local $Query = $URL & "/deleteChatStickerSet?chat_id=" & $ChatID
    ConsoleWrite(_Telegram_HttpGet($Query))
EndFunc ;==> _deleteChatStickerSet

; TODO: comment
Func _TelegramanswerCallbackQuery($CallbackID,$Text = '',$cbURL = '',$ShowAlert = False,$CacheTime = '')
    ;In Callback context, there's a URL validation/restriction on the Telegram side
    ;Telegram Docs: https://core.telegram.org/bots/api#answercallbackquery
    ;cbURL can be a Game's URL or something like "t.me/your_bot?start=XXXX"
    ;that open your bot with a parameter.
    Local $Query = $URL & "/answerCallbackQuery?callback_query_id=" & $CallbackID
    If $Text <> '' Then $Query &= "&text=" & $Text
    If $cbURL <> '' Then $Query &= "&url=" & $cbURL
    If $ShowAlert Then $Query &= "&show_alert=true"
    If $CacheTime <> '' Then $Query &= "&cache_time=" & $CacheTime
    Local $Json = Json_Decode(_Telegram_HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _answerCallbackQuery


; TODO: editmessagetext
; TODO: editmessagecaption
; TODO: editmessagemedia
; TODO: editmessagereplymarkup
; TODO: stoppoll
; TODO: deletemessage
; TODO: sendsticker
; TODO: getsticketset
; TODO: uploadstickerfile
; TODO: createnewstickerset
; TODO: addstickertoset
; TODO: setstickerpositioninset
; TODO: deletestickerfromset
; TODO: Inline mode
; TODO: Payments mode
; TODO: Game mode
; TODO: Passport

#EndRegion

#Region "@EXTRA FUNCTIONS"

#cs ===============================================================================
   Function Name..:    	_TelegramInitBot
   Description....:	   	Initialize the bot
   Parameter(s)...:    	$Token: Bot's token (123456789:AbCdEf...)
   Return Value(s):	   	Return True if success, False otherwise
#ce ===============================================================================
Func _TelegramInitBot($Token)
	$TOKEN = $Token
    $URL  &= $TOKEN

    If IsArray(_TelegramGetMe()) Then
        Return True
    Else
        ;ConsoleWrite("Ops! Error: reason may be invalid token, webhook active, internet connection..." & @CRLF)
        Return SetError($INVALID_TOKEN_ERROR,0,False)
    EndIf

EndFunc ;==> _TelegramInitBot

#cs ===============================================================================
   Function Name..:    	_Polling
   Description....:     Wait for incoming messages
   Parameter(s)...:     None
   Return Value(s):		Return an array with information about the messages
							$msgData[0] = Offset of the current update (used to 'switch' to the next update)
							$msgData[1] = Message ID
							$msgData[2] = Chat ID, use for interact with the user
							$msgData[3] = Username of the user
							$msgData[4] = First name of the user
							$msgData[5] = Last name of the user
							$msgData[6] = Text of the message
#ce ===============================================================================
Func _TelegramPolling()
    While 1
        Sleep(500) ;Prevent CPU Overloading
        $newUpdates = _TelegramGetUpdates()
        ;ConsoleWrite($newUpdates & @CRLF)
        If Not StringInStr($newUpdates,'update_id') Then ContinueLoop
        $msgData = _Telegram_MsgDecode($newUpdates)
        $OFFSET = $msgData[0] + 1
        ;ConsoleWrite(_ArrayToString($msgData) & @CRLF)
        Return $msgData
    WEnd
EndFunc ;==> _Polling


#cs ===============================================================================
   Function Name..:    	_CreateKeyboard
   Description....:     Create and return a custom keyboard markup
   Parameter(s)...:     $Keyboard: an array with the keyboard. Use an empty position for line break.
                            Example: Local $Keyboard[4] = ['Top Left','Top Right','','Second Row']
                        $Resize: Set true if you want to resize the buttons of the keyboard
                        $OneTime: Set true if you want to use the keyboard once
   Return Value(s):		Return custom markup as string, encoded in JSON
#ce ===============================================================================
Func _TelegramCreateKeyboard(ByRef $Keyboard,$Resize = False,$OneTime = False)
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

#cs ===============================================================================
   Function Name..:    	_CreateInlineKeyboard
   Description....:     Create and return a custom inline keyboard markup
   Parameter(s)...:     $Keyboard: an array with the keyboard. Use an empty position for line break.
                            Example: Local $InlineKeyboard[5] = ['Button1_Text','Button1_Data','','Button2_Text','Button2_Data']
   Return Value(s):		Return custom inline markup as string, encoded in JSON
#ce ===============================================================================
Func _TelegramCreateInlineKeyboard(ByRef $Keyboard)
    ;reply_markup={"inline_keyboard":[[['text':'Yes','callback_data':'pressed_yes'],['text':'No','callback_data':'pressed_no']]]}
    Local $jsonKeyboard = '{"inline_keyboard":[['
    For $i=0 to UBound($Keyboard)-1
        If($Keyboard[$i] <> '') Then
            If(StringRight($jsonKeyboard,2) = '[[') Then ;First button
                $jsonKeyboard &= '{"text":"' & $Keyboard[$i] & '",'
            ElseIf(StringRight($jsonKeyboard,2) = '",') Then ;CallbackData of a button
                $jsonKeyboard &= '"callback_data":"' & $Keyboard[$i] & '"}'
            ElseIf(StringRight($jsonKeyboard,2) = '"}') Then
                $jsonKeyboard &= ',{"text":"' & $Keyboard[$i] & '",'
            ElseIf(StringRight($jsonKeyboard,2) = '],') Then
                $jsonKeyboard &= '[{"text":"' & $Keyboard[$i] & '",'
            EndIf

        Else
            $jsonKeyboard &= '],'
        EndIf
    Next
    $jsonKeyboard &= ']]}'
    Return $jsonKeyboard
EndFunc


#EndRegion

#Region "@INTERNAL FUNCTIONS"

#cs ===============================================================================
   Function Name..:		_Telegram_GetFileID
   Description....:     Get the 'File ID' of the last sent file
   Parameter(s)...:     $Json: JSON response from Telegram Server;
                        $type: File type, like photo, video, document...
   Return Value(s):  	Return the File ID as a string
#ce ===============================================================================
Func _Telegram_GetFileID(ByRef $Json,$type)

    ;If($type = 'photo') Then Return Json_Get($Json,'[result][photo][0][file_id]')
    If($type = 'photo') Then
	  If(Json_Get($Json,'[result][photo][3][file_id]')) Then Return Json_Get($Json,'[result][photo][3][file_id]')
	  If(Json_Get($Json,'[result][photo][2][file_id]')) Then Return Json_Get($Json,'[result][photo][2][file_id]')
	  If(Json_Get($Json,'[result][photo][1][file_id]')) Then Return Json_Get($Json,'[result][photo][1][file_id]')
	  If(Json_Get($Json,'[result][photo][0][file_id]')) Then Return Json_Get($Json,'[result][photo][0][file_id]')
	EndIf

	If($type = 'video') Then Return Json_Get($Json,'[result][animation][file_id]')
    If($type = 'audio') Then Return Json_Get($Json,'[result][audio][file_id]')
    If($type = 'document') Then Return Json_Get($Json,'[result][document][file_id]')
    If($type = 'voice') Then Return Json_Get($Json,'[result][voice][file_id]')
    If($type = 'sticker') Then Return Json_Get($Json,'[result][sticker][file_id]')
    If($type = 'videonote') Then Return Json_Get($Json,'[result][document][file_id]')
EndFunc ;==> _Telegram_GetFileID

#cs ===============================================================================
   Function Name..:		__GetFilePath()
   Description....:     Get the path of a file on Telegram Server by its File ID
   Parameter(s)...:     $FileID: Unique identifier for the file
   Return Value(s):  	Return the file path as a string
#ce ===============================================================================
Func _Telegram_GetFilePath($FileID)
    Local $Query = $URL & "/getFile?file_id=" & $FileID
    Local $Json = Json_Decode(_Telegram_HttpPost($Query))
    Return Json_Get($Json,'[result][file_path]')
EndFunc ;==> __GetFilePath

#cs ===============================================================================
   Function Name..:		__DownloadFile
   Description....:     Download and save a file from Telegram Server
   Parameter(s)...:     $filePath: Path of the file on Telegram Server (Get this from __GetFilePath)
   Return Value(s):  	Return file name if success, False otherwise
#ce ===============================================================================
Func _Telegram_DownloadFile($filePath)
    Local $fileName = StringSplit($filePath,'/')[2]
    Local $query = "https://api.telegram.org/file/bot" & $TOKEN & "/" & $filePath
    Local $result = InetGet($query,$fileName)
    If $result And Not @error And FileExists($fileName) Then
        Return $fileName
    Else
        Return SetError($FILE_NOT_DOWNLOADED,0,False)
    EndIf
EndFunc ;==> __DownloadFile

#cs ===============================================================================
   Function Name..:		_Telegram_UrlEncode
   Description....:     Encode text in url format
   Parameter(s)...:     $string: Text to encode
   Return Value(s):  	Return the encoded string
#ce ===============================================================================
Func _Telegram_UrlEncode($string)
    $string = StringSplit($string, "")
    For $i=1 To $string[0]
        If AscW($string[$i]) < 48 Or AscW($string[$i]) > 122 Then
            $string[$i] = "%"&_StringToHex($string[$i])
        EndIf
    Next
    $string = _ArrayToString($string, "", 1)
    Return $string
EndFunc

#cs ===============================================================================
   Function Name..:		_Telegram_MsgDecode
   Description....:     Decode message information from JSON string to an Array
   Parameter(s)...:     $Update: JSON Response from Telegram Server
   Return Value(s):  	Return an array with information about a message (check docs)
#ce ===============================================================================
Func _Telegram_MsgDecode($Update)
    Local $Json = Json_Decode($Update)

    ;@PRIVATE CHAT MESSAGE
    If(Json_Get($Json,'[result][0][message][chat][type]') = 'private') Then
        Local $msgData[13] = [ _
            Json_Get($Json,'[result][0][update_id]'), _
            Json_Get($Json,'[result][0][message][message_id]'), _
            Json_Get($Json,'[result][0][message][from][id]'), _
            Json_Get($Json,'[result][0][message][from][username]'), _
            Json_Get($Json,'[result][0][message][from][first_name]'), _
			Json_Get($json,'[result][0][message][from][last_name]') _
        ]

      If(Json_Get($Json,'[result][0][message][text]')) Then $msgData[6] = Json_Get($Json,'[result][0][message][text]')

		; TODO: Media recognition

		 Return $msgData

   ;@GROUP CHAT MESSAGE (Inlude left/new member events)
   ElseIf(Json_Get($Json,'[result][0][message][chat][type]') = 'group') or (Json_Get($Json,'[result][0][message][chat][type]') = 'supergroup') Then
      Local $msgData[13] = [ _
         Json_Get($Json,'[result][0][update_id]'), _ ;[0] = Offset
         Json_Get($Json,'[result][0][message][message_id]'), _ ;[1] = Message ID
         Json_Get($Json,'[result][0][message][from][id]'), _ ;[2] = User ID
         Json_Get($Json,'[result][0][message][from][username]'), _ ;[3] = Username
         Json_Get($Json,'[result][0][message][from][first_name]'), _ ;[4] = Firstname
		 Json_Get($json,'[result][0][message][from][last_name]'), _ ;[5] = Lastname
         Json_Get($Json,'[result][0][message][chat][id]'), _ ;[6] = Group ID
         Json_Get($Json,'[result][0][message][chat][title]') _ ;[7] = Group Name
      ]

      If(Json_Get($Json,'[result][0][message][left_chat_member]')) Then
         $msgData[8] = 'left' ;[8] = Event
         $msgData[9] = Json_Get($Json,'[result][0][message][from][id]') ;[9] = Left member ID
         $msgData[10] = Json_Get($Json,'[result][0][message][from][username]') ;[10] = Left member Username
         $msgData[11] = Json_Get($Json,'[result][0][message][from][first_name]') ;[11] = Left member Firstname
         $msgData[12] = Json_Get($Json,'[result][0][message][from][last_name]') ;[12] = Left member Lastname
      ElseIf(Json_Get($Json,'[result][0][message][new_chat_member]')) Then
         $msgData[8] = 'new' ;[7] = Event
         $msgData[9] = Json_Get($Json,'[result][0][message][from][id]') ;[9] = New member ID
         $msgData[10] = Json_Get($Json,'[result][0][message][from][username]') ;[10] = New member Username
         $msgData[11] = Json_Get($Json,'[result][0][message][from][first_name]') ;[11] = New member Firstname
         $msgData[12] = Json_Get($Json,'[result][0][message][from][last_name]') ;[12] = Left member Lastname
      Else
         $msgData[8] = Json_Get($Json,'[result][0][message][text]') ;[8] = Text
      EndIf

      Return $msgData

   ;@EDITED PRIVATE CHAT MESSAGE
   ElseIf(Json_Get($Json,'[result][0][edited_message][chat][type]') = 'private') Then
      Local $msgData[13] = [ _
		 Json_Get($Json,'[result][0][update_id]'), _ ;[0] = Offset
		 Json_Get($Json,'[result][0][edited_message][message_id]'), _ ;[1] = Message ID
		 Json_Get($Json,'[result][0][edited_message][from][id]'), _ ;[2] = Chat ID
		 Json_Get($Json,'[result][0][edited_message][from][username]'), _ ;[3] = Username
		 Json_Get($Json,'[result][0][edited_message][from][first_name]'), _ ;[4] = Firstname
		 Json_Get($Json,'[result][0][edited_message][from][last_name]') _ ;[5] = Lastname
	  ]

        If(Json_Get($Json,'[result][0][edited_message][text]')) Then $msgData[6] = Json_Get($Json,'[result][0][edited_message][text]') ;[6] = Text (eventually)

        ;Insert media recognition here

        Return $msgData

;@EDITED GROUP CHAT MESSAGE
   ElseIf(Json_Get($Json,'[result][0][edited_message][chat][type]') = 'group') Then
      Local $msgData[13] = [ _
		 Json_Get($Json,'[result][0][update_id]'), _ ;[0] = Offset
		 Json_Get($Json,'[result][0][edited_message][message_id]'), _ ;[1] = Message ID
		 Json_Get($Json,'[result][0][edited_message][from][id]'), _ ;[2] = Chat ID
		 Json_Get($Json,'[result][0][edited_message][from][username]'), _ ;[3] = Username
		 Json_Get($Json,'[result][0][edited_message][from][first_name]'), _ ;[4] = Firstname
		 Json_Get($Json,'[result][0][edited_message][from][last_name]') _ ;[5] = Lastname
	  ]

        If(Json_Get($Json,'[result][0][edited_message][text]')) Then $msgData[6] = Json_Get($Json,'[result][0][edited_message][text]') ;[6] = Text (eventually)

        ;Insert media recognition here

        Return $msgData

    ;@CALLBACK QUERY
    ElseIf(Json_Get($Json,'[result][0][callback_query][id]') <> '') Then
        Local $msgData[13] = [ _
            Json_Get($Json,'[result][0][update_id]'), _ ;[0] = Offset
            Json_Get($Json,'[result][0][callback_query][id]'), _ ;[1] = Callback ID
            Json_Get($Json,'[result][0][callback_query][from][id]'), _ ;[2] = Chat ID
            Json_Get($Json,'[result][0][callback_query][from][username]'), _ ;[3] = Username
            Json_Get($Json,'[result][0][callback_query][from][first_name]'), _ ;[4] = Firstname
			Json_Get($Json,'[result][0][callback_query][from][last_name]'), _ ;[5] = Lastname
            Json_Get($Json,'[result][0][callback_query][data]') _ ;[6] = Callback Data
        ]

        Return $msgData

    ;@INLINE QUERY
    ElseIf(Json_Get($Json,'[result][0][inline_query][id]') <> '') Then
        Local $msgData[13] = [ _
            Json_Get($Json,'[result][0][update_id]'), _ ;[0] = Offset
            Json_Get($Json,'[result][0][inline_query][id]'), _ ;[1] = Inline Query ID
            Json_Get($Json,'[result][0][inline_query][from][id]'), _ ;[2] = Chat ID
            Json_Get($Json,'[result][0][inline_query][from][username]'), _ ;[3] = Username
            Json_Get($Json,'[result][0][inline_query][from][first_name]'), _ ;[4] = Firstname
            Json_Get($Json,'[result][0][inline_query][from][last_name]'), _ ;[5] = Lastname
            Json_Get($Json,'[result][0][inline_query][query]') _ ;[6] = Inline Query Data
        ]

        Return $msgData


    ElseIf(Json_Get($Json,'[result][0][channel_post][message_id]') <> '') Then
        Local $msgData[5] = [ _
            Json_Get($Json,'[result][0][update_id]'), _ ;[0] = Offset
            Json_Get($Json,'[result][0][channel_post][message_id]'), _ ;[1] = Message ID
            Json_Get($Json,'[result][0][channel_post][chat][id]'), _ ;[2] = Chat ID
            Json_Get($Json,'[result][0][channel_post][chat][title]') _ ;[3] = Firstname
        ]

        If(Json_Get($Json,'[result][0][channel_post][text]')) Then
            $msgData[4] = Json_Get($Json,'[result][0][channel_post][text]') ;[4] = Text (eventually)
        EndIf

        Return $msgData

      ;@EDITED CHANNEL CHAT MESSAGE
   ElseIf(Json_Get($Json,'[result][0][edited_channel_post][chat][type]') = 'channel') Then
      Local $msgData[13] = [ _
		 Json_Get($Json,'[result][0][update_id]'), _ ;[0] = Offset
		 Json_Get($Json,'[result][0][edited_message][message_id]'), _ ;[1] = Message ID
		 Json_Get($Json,'[result][0][edited_message][from][id]'), _ ;[2] = Chat ID
		 Json_Get($Json,'[result][0][edited_message][from][username]'), _ ;[3] = Username
		 Json_Get($Json,'[result][0][edited_message][from][first_name]'), _ ;[4] = Firstname
		 Json_Get($Json,'[result][0][edited_message][from][last_name]') _ ;[5] = Lastname
	  ]

        If(Json_Get($Json,'[result][0][edited_message][text]')) Then $msgData[6] = Json_Get($Json,'[result][0][edited_message][text]') ;[6] = Text (eventually)

        ;Insert media recognition here

        Return $msgData
    EndIf

EndFunc ;==> _Telegram_MsgDecode

#EndRegion


#Region "@HTTP Request"
Func _Telegram_HttpCrashHandler()
	Consolewrite("We intercepted a COM Error !"    & @CRLF  & @CRLF & _
             "err.description is: " & @TAB & $oMyError.description  & @CRLF & _
             "err.windescription:"   & @TAB & $oMyError.windescription & @CRLF & _
             "err.number is: "       & @TAB & hex($oMyError.number,8)  & @CRLF & _
             "err.lastdllerror is: "   & @TAB & $oMyError.lastdllerror   & @CRLF & _
             "err.scriptline is: "   & @TAB & $oMyError.scriptline   & @CRLF & _
             "err.source is: "       & @TAB & $oMyError.source       & @CRLF & _
             "err.helpfile is: "       & @TAB & $oMyError.helpfile     & @CRLF & _
             "err.helpcontext is: " & @TAB & $oMyError.helpcontext & @CRLF _
            )
	Return
endfunc

Func _Telegram_HttpGet($sURL,$sData = '')
    Local $oHTTP = ObjCreate("WinHttp.WinHttpRequest.5.1")
    If (@error) Then Return SetError(1,@error,0)
    $oHTTP.Open("GET",$sURL & "?" & $sData,False)
    If (@error) Then Return SetError(2,0,0)
    $oHTTP.Send()
    If (@error) Then Return SetError(3,0,0)
    If ($oHTTP.Status <> $HTTP_STATUS_OK) Then Return SetError(4,0,0)
    Return SetError(0,0,$oHTTP.ResponseText)
EndFunc ;==> _Telegram_HttpGet

Func _Telegram_HttpPost($sURL,$sData = '')
    Local $oHTTP = ObjCreate("WinHttp.WinHttpRequest.5.1")
    $oHTTP.Open("POST",$sURL,False)
    If (@error) Then Return SetError(1,0,0)
    $oHTTP.SetRequestHeader("Content-Type","application/x-www-form-urlencoded")
    $oHTTP.Send($sData)
    If (@error) Then Return SetError(2,0,0)
    If ($oHTTP.Status <> $HTTP_STATUS_OK) Then Return SetError(3,0,0)
    Return SetError(0,0,$oHTTP.ResponseText)
EndFunc ;==> _Telegram_HttpPost
#EndRegion
