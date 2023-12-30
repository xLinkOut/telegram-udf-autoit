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
Global $URL	   = ""
Global $TOKEN  = ""
Global $OFFSET = 0

;@CONST
Const $BASE_URL = "https://api.telegram.org/bot"
Const $BOT_CRLF = __UrlEncode(@CRLF)

;@ERRORS
;TODO: move to another file, if needed
Const $ERR_INVALID_TOKEN = 1
Const $ERR_WIN_HTTP = 2
Const $INVALID_TOKEN_ERROR = 1
Const $FILE_NOT_DOWNLOADED = 2
Const $OFFSET_GRATER_THAN_TOTAL = 3
Const $INVALID_JSON_RESPONSE = 4

; Initialization errors
Const $TG_ERR_INIT = 1 ;@error
Const $TG_ERR_INIT_MISSING_TOKEN = 1 ;@extended
Const $TG_ERR_INIT_INVALID_TOKEN = 2 ;@extended

; Telegram API Call errors
Const $TG_ERR_API_CALL = 2 ;@error
Const $TG_ERR_API_CALL_OPEN = 1 ;@extended
Const $TG_ERR_API_CALL_SEND = 2 ;@extended
Const $TG_ERR_API_CALL_HTTP_NOT_SUCCESS = 3 ;@extended
Const $TG_ERR_API_CALL_NOT_DECODED = 4 ;@extended
Const $TG_ERR_API_CALL_INVALID_JSON = 5 ;@extended
Const $TG_ERR_API_CALL_NOT_SUCCESS = 6 ;@extended

; Missing or invalid input errors
Const $TG_ERR_BAD_INPUT = 3 ;@error

#cs ======================================================================================
    Name .........: _Telegram_Init
    Description...: Initializes a Telegram connection using the provided token
    Syntax .......: _Telegram_Init($sToken[, $bValidate = False])
    Parameters....: 
                    $sToken    - Token to authenticate with Telegram API
                    $bValidate - [optional] Boolean flag to indicate whether 
                                to validate the token (Default is False)
    Return values.: 
                    Success - Returns True upon successful initialization
                    Error   - Returns False, sets @error flag to $TG_ERR_INIT and set 
                              @extended flag to:
                              - $TG_ERR_INIT_MISSING_TOKEN if token is not provided
                              - $TG_ERR_INIT_INVALID_TOKEN if token is invalid
#ce ======================================================================================
Func _Telegram_Init($sToken, $bValidate = False)
    ; Check if provided token is not empty
    If ($sToken = "" Or $sToken = Null) Then
        Return SetError($TG_ERR_INIT, $TG_ERR_INIT_MISSING_TOKEN, False)
    EndIf

    ; Save token
	$TOKEN = $sToken
    ; Form URL as BASE_URL + TOKEN
    $URL = $BASE_URL & $TOKEN

    if ($bValidate) Then
        ; Validate token calling GetMe endpoint
        Local $aData = _Telegram_GetMe()
        ; Double control on error flag and return value
        If (@error Or Not Json_IsObject($aData)) Then
            Return SetError($TG_ERR_INIT, $TG_ERR_INIT_INVALID_TOKEN, False)
        EndIf
    EndIf

    Return True
EndFunc ;==> _Telegram_Init

#Region "@ENDPOINT FUNCTIONS"

#cs ======================================================================================
    Name .........: _Telegram_GetMe
    Description...: Retrieves information about the current bot using Telegram API
    Syntax .......: _Telegram_GetMe()
    Parameters....: None
    Return values.: 
                    Success - Returns an object with information about the bot upon a 
                              successful API call
                    Error   - Returns Null and sets @error flag to the encountered error code
#ce ======================================================================================
Func _Telegram_GetMe()
	Local $oResponse = _Telegram_API_Call($URL, "/getMe")
    If (@error) Then Return SetError(@error, @extended, Null)

    Return $oResponse
EndFunc ;==>_Telegram_GetMe

#cs ======================================================================================
    Name .........: _Telegram_GetUpdates
    Description...: Retrieves updates from the Telegram API, optionally updating the offset
    Syntax .......: _Telegram_GetUpdates([$bUpdateOffset = True])
    Parameters....: 
                    $bUpdateOffset - [optional] Boolean flag indicating whether to update 
                                     the offset (Default is True)
    Return values.: 
                    Success - Returns an object containing updates retrieved from the 
                              Telegram API. If $bUpdateOffset is True, the offset might 
                              get updated based on the retrieved updates.
                    Error   - Returns Null and sets @error flag to the encountered error code
#ce ======================================================================================
Func _Telegram_GetUpdates($bUpdateOffset = True)
    ; Get updates
    Local $oResponse = _Telegram_API_Call($URL, "/getUpdates", "GET", "offset=" & $OFFSET)
    If (@error) Then Return SetError(@error, @extended, Null)

    If ($bUpdateOffset) Then
        ; Get messages count
        Local $iMessageCount = UBound($oResponse)
        if ($iMessageCount > 0) Then
            ; Set offset as last message id
            $OFFSET = Json_Get($oResponse, "[result][" & $iMessageCount - 1 & "][update_id]") + 1
        EndIf
	EndIf

    Return $oResponse
EndFunc ;==> _Telegram_GetUpdates

#cs ======================================================================================
    Name .........: _Telegram_SendMessage
    Description...: Sends a message via the Telegram API to a specified chat ID
    Syntax .......: _Telegram_SendMessage($sChatId, $sText, $sParseMode = Null, $sReplyMarkup = Null, $iReplyToMessage = Null, $bDisableWebPreview = False, $bDisableNotification = False)
    Parameters....: 
                    $sChatId               - ID of the chat where the message will be sent
                    $sText                 - Text content of the message
                    $sParseMode            - [optional] Parse mode for the message (Default is Null)
                    $sReplyMarkup          - [optional] Reply markup for the message (Default is Null)
                    $iReplyToMessage       - [optional] ID of the message to reply to (Default is Null)
                    $bDisableWebPreview    - [optional] Boolean flag to disable web preview 
                                             (Default is False)
                    $bDisableNotification  - [optional] Boolean flag to disable notification 
                                             (Default is False)
    Return values.: 
                    Success - Returns an object containing information about 
                                             the sent message upon a successful API call
                    Error   - Returns Null and sets @error flag to the encountered error code
#ce ======================================================================================
Func _Telegram_SendMessage($sChatId, $sText, $sParseMode = Null, $sReplyMarkup = Null, $iReplyToMessage = Null, $bDisableWebPreview = False, $bDisableNotification = False)
    ; TODO: Enum for ParseMode
    If ($sChatId = "" Or $sChatId = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)
    If ($sText = "" Or $sText = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)
    If ($sParseMode <> Null And $sParseMode <> "MarkdownV2" And $sParseMode <> "HTML") Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)

    Local $sParams = _
        "chat_id=" & $sChatId & _
        "&text=" & $sText & _
        "&disable_notification=" & $bDisableNotification & _
        "&disable_web_page_preview=" & $bDisableWebPreview
    
    If $sParseMode <> Null Then $sParams &= "&parse_mode=" & $sParseMode
    If $sReplyMarkup <> Null Then $sParams &= "&reply_markup=" & $sReplyMarkup
    If $iReplyToMessage <> Null Then $sParams &= "&reply_to_message_id=" & $iReplyToMessage

    Local $oResponse = _Telegram_API_Call($URL, "/sendMessage", "POST", $sParams)
    If (@error) Then Return SetError(@error, @extended, Null)

    Return $oResponse
EndFunc ;==> _Telegram_SendMessage

#cs ======================================================================================
    Name .........: _Telegram_ForwardMessage
    Description...: Forwards a message from one chat to another using the Telegram API
    Syntax .......: _Telegram_ForwardMessage($sChatId, $sFromChatId, $iMessageId, $bDisableNotification = False)
    Parameters....: 
                    $sChatId               - ID of the chat where the message will be forwarded
                    $sFromChatId           - ID of the chat where the original message is from
                    $iMessageId            - ID of the message to be forwarded
                    $bDisableNotification  - [optional] Boolean flag to disable notification 
                                             (Default is False)
    Return values.: 
                    Success                - Returns an object containing information about 
                                             the forwarded message upon a successful API call
                    Error                  - Returns Null and sets @error flag to the encountered error code
#ce ======================================================================================
Func _Telegram_ForwardMessage($sChatId, $sFromChatId, $iMessageId, $bDisableNotification = False)
    If ($sChatId = "" Or $sChatId = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)
    If ($sFromChatId = "" Or $sFromChatId = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)
    If ($iMessageId = "" Or $iMessageId = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)
    
    Local $sParams = _
        "chat_id=" & $sChatId & _
        "&from_chat_id=" & $sFromChatId & _ 
        "&message_id=" & $iMessageId & _
        "&disable_notification=" & $bDisableNotification

    Local $oResponse = _Telegram_API_Call($URL, "/forwardMessage", "POST", $sParams)
    If (@error) Then Return SetError(@error, @extended, Null)

    Return $oResponse
EndFunc ;==> _Telegram_ForwardMessage

Func _Telegram_SendPhoto($sChatId, $sPhoto, $sCaption = "", $sReplyMarkup = "", $iReplyToMessage = Null, $bDisableNotification = False)
    If ($sChatId = "" Or $sChatId = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)
    If ($sPhoto = "" Or $sPhoto = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)
    
    Local $sParams = _
        "chat_id=" & $sChatId & _
        "&caption=" & $sCaption & _
        "&photo=" & $sPhoto & _
        "&disable_notification=" & $bDisableNotification

    If $sReplyMarkup <> "" Then $sParams &= "&reply_markup=" & $sReplyMarkup
    If $iReplyToMessage <> Null Then $sParams &= "&reply_to_message_id=" & $iReplyToMessage

    Local $oResponse = _Telegram_SendMedia($URL, "/sendPhoto", $sParams, $sPhoto, "photo")
    If (@error) Then Return SetError(@error, @extended, Null)

    Return $oResponse
EndFunc ;==> _Telegram_SendPhoto

Func _Telegram_SendAudio($sChatId,$sAudio,$sCaption = '',$sReplyMarkup = "",$iReplyToMessage = Null,$bDisableNotification = False)
    If ($sChatId = "" Or $sChatId = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)
    If ($sAudio = "" Or $sAudio = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)
    
    Local $sParams = _
        "chat_id=" & $sChatId & _
        "&caption=" & $sCaption & _
        "&disable_notification=" & $bDisableNotification
    
    If $sReplyMarkup <> Default Then $sParams &= "&reply_markup=" & $sReplyMarkup
    If $iReplyToMessage <> Null Then $sParams &= "&reply_to_message_id=" & $iReplyToMessage
    
    Local $oResponse = _Telegram_SendMedia($URL, "/sendAudio", $sParams, $sAudio, "audio")
    If (@error) Then Return SetError(@error, @extended, Null)
    
    Return $oResponse
EndFunc ;==> _Telegram_SendAudio

Func _Telegram_SendDocument($sChatId,$Document,$sCaption = '',$sReplyMarkup = "",$iReplyToMessage = Null,$bDisableNotification = False)
    If ($sChatId = "" Or $sChatId = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)
    If ($Document = "" Or $Document = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)
    
    Local $sParams = _
        "chat_id=" & $sChatId & _
        "&caption=" & $sCaption & _
        "&disable_notification=" & $bDisableNotification
    
    If $sReplyMarkup <> Default Then $sParams &= "&reply_markup=" & $sReplyMarkup
    If $iReplyToMessage <> Null Then $sParams &= "&reply_to_message_id=" & $iReplyToMessage
    
    Local $oResponse = _Telegram_SendMedia($URL, "/sendDocument", $sParams, $Document, "document")
    If (@error) Then Return SetError(@error, @extended, Null)
    
    Return $oResponse
    
EndFunc ;==> _Telegram_SendDocument

Func _Telegram_SendVideo($sChatId,$Video,$sCaption = '',$sReplyMarkup = "",$iReplyToMessage = Null,$bDisableNotification = False)
    If ($sChatId = "" Or $sChatId = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)
    If ($Video = "" Or $Video = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)
    
    Local $sParams = _
        "chat_id=" & $sChatId & _
        "&caption=" & $sCaption & _
        "&disable_notification=" & $bDisableNotification
    
    If $sReplyMarkup <> Default Then $sParams &= "&reply_markup=" & $sReplyMarkup
    If $iReplyToMessage <> Null Then $sParams &= "&reply_to_message_id=" & $iReplyToMessage
    
    Local $oResponse = _Telegram_SendMedia($URL, "/sendVideo", $sParams, $Video, "video")
    If (@error) Then Return SetError(@error, @extended, Null)
    
    Return $oResponse
EndFunc ;==> _Telegram_SendVideo

Func _Telegram_SendAnimation($sChatId,$Animation,$sCaption = '',$sReplyMarkup = "",$iReplyToMessage = Null,$bDisableNotification = False)
    If ($sChatId = "" Or $sChatId = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)
    If ($Animation = "" Or $Animation = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)
    
    Local $sParams = _
        "chat_id=" & $sChatId & _
        "&caption=" & $sCaption & _
        "&disable_notification=" & $bDisableNotification
    
    If $sReplyMarkup <> Default Then $sParams &= "&reply_markup=" & $sReplyMarkup
    If $iReplyToMessage <> Null Then $sParams &= "&reply_to_message_id=" & $iReplyToMessage
    
    Local $oResponse = _Telegram_SendMedia($URL, "/sendAnimation", $sParams, $Animation, "animation")
    If (@error) Then Return SetError(@error, @extended, Null)
    
    Return $oResponse
EndFunc ;==> _Telegram_SendAnimation

Func _SendVoice($sChatId,$Path,$sCaption = '',$sReplyMarkup = "",$iReplyToMessage = Null,$bDisableNotification = False)
    If ($sChatId = "" Or $sChatId = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)
    If ($Path = "" Or $Path = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)
    
    Local $sParams = _
        "chat_id=" & $sChatId & _
        "&caption=" & $sCaption & _
        "&disable_notification=" & $bDisableNotification
    
    If $sReplyMarkup <> Default Then $sParams &= "&reply_markup=" & $sReplyMarkup
    If $iReplyToMessage <> Null Then $sParams &= "&reply_to_message_id=" & $iReplyToMessage
    
    Local $oResponse = _Telegram_SendMedia($URL, "/sendVoice", $sParams, $Path, "voice")
    If (@error) Then Return SetError(@error, @extended, Null)
    
    Return $oResponse
EndFunc ;==> _SendVoice

Func _SendVideoNote($sChatId,$VideoNote,$sReplyMarkup = "",$iReplyToMessage = Null,$bDisableNotification = False)
    If ($sChatId = "" Or $sChatId = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)
    If ($VideoNote = "" Or $VideoNote = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)
    
    Local $sParams = _
        "chat_id=" & $sChatId & _
        "&disable_notification=" & $bDisableNotification
    
    If $sReplyMarkup <> Default Then $sParams &= "&reply_markup=" & $sReplyMarkup
    If $iReplyToMessage <> Null Then $sParams &= "&reply_to_message_id=" & $iReplyToMessage
    
    Local $oResponse = _Telegram_SendMedia($URL, "/sendVideoNote", $sParams, $VideoNote, "video_note")
    If (@error) Then Return SetError(@error, @extended, Null)
    
    Return $oResponse
EndFunc ;==> _SendVideoNote

#cs ===============================================================================
   Function Name..:		_SendMediaGroup
   Description....:     Send a voice file
   Parameter(s)...:     $sChatId: Unique identifier for the target chat
						$Media: JSON-serialized array describing photos and videos to be sent, must include 2–10 items
                        $iReplyToMessage (optional): If the message is a reply, ID of the original message
                        $bDisableNotification (optional): Sends the message silently. User will receive a notification with no sound
   Return Value(s):  	Return an array with all File IDs of the medias sent
#ce ===============================================================================
Func _SendMediaGroup($sChatId,$Media,$iReplyToMessage = Null,$bDisableNotification = False)
    Local $Query = $URL & '/sendMediaGroup'
    Local $hOpen = _WinHttpOpen()
    Local $Form = '<form action="' & $Query & '" method="post" enctype="multipart/form-data">' & _
                  '<input type="text" name="chat_id"/>' & _
                  '<input type="file" name="mediagroup"/>'
    If $iReplyToMessage <> '' Then $Query &= '<input type="text" name="reply_to_message_id"/>'
    If $bDisableNotification Then $Form &= ' <input type="text" name="disable_notification"/>'
    $Form &= '</form>'
    Local $Response = _WinHttpSimpleFormFill($Form,$hOpen,Default, _
                       "name:chat_id", $sChatId, _
                       "name:media", $Media, _
                       "name:reply_to_message_id", $iReplyToMessage, _
                       "name:disable_notification", $bDisableNotification)

    _WinHttpCloseHandle($hOpen)
    Local $Json = Json_Decode($Response)
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    Return __GetFileID($Json,'mediagroup')
EndFunc ;==> _SendMediaGroup

#cs ===============================================================================
   ; DEPRECATED?
   Function Name..:		_SendSticker
   Description....:     Send a sticker
   Parameter(s)...:     $sChatId: Unique identifier for the target chat
						$Path: Path to a local file (format: .webp)
                        $sReplyMarkup (optional): Custom keyboard markup;
                        $iReplyToMessage (optional): If the message is a reply, ID of the original message
                        $bDisableNotification (optional): Sends the message silently. User will receive a notification with no sound
   Return Value(s):  	Return the File ID of the sticker as string
#ce ===============================================================================
Func _SendSticker($sChatId,$Path,$sReplyMarkup = "",$iReplyToMessage = Null,$bDisableNotification = False)
    Local $Query = $URL & '/sendSticker'
    Local $hOpen = _WinHttpOpen()
    Local $Form = '<form action="' & $Query & '" method="post" enctype="multipart/form-data">' & _
                  '<input type="text" name="chat_id"/>' & _
                  '<input type="file" name="sticker"/>'
    If $sReplyMarkup <> Default Then $Form &= ' <input type="text" name="reply_markup"/>'
    If $iReplyToMessage <> '' Then $Query &= '<input type="text" name="reply_to_message_id"/>'
    If $bDisableNotification Then $Form &= ' <input type="text" name="disable_notification"/>'
    $Form &= '</form>'
   Local $Response = _WinHttpSimpleFormFill($Form,$hOpen,Default, _
                       "name:chat_id", $sChatId, _
                       "name:sticker", $Path, _
                       "name:reply_markup", $sReplyMarkup, _
                       "name:reply_to_message_id", $iReplyToMessage, _
                       "name:disable_notification", $bDisableNotification)

    _WinHttpCloseHandle($hOpen)
    Local $Json = Json_Decode($Response)
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    Return __GetFileID($Json,'sticker')
EndFunc ;==> _SendSticker

#cs ===============================================================================
   Function Name..:		_SendLocation
   Description....:     Send a location object
   Parameter(s)...:     $sChatId: Unique identifier for the target chat
						$Latitude: Latitute of the location
						$Longitude: Longitude of the location
						$LivePeriod : Period in seconds for which the location will be updated, should be between 60 and 86400
                        $sReplyMarkup (optional): Custom keyboard markup;
                        $iReplyToMessage (optional): If the message is a reply, ID of the original message
                        $bDisableNotification (optional): Sends the message silently. User will receive a notification with no sound
   Return Value(s):  	Return True if no error encountered, False otherwise
#ce ===============================================================================
Func _SendLocation($sChatId,$Latitude,$Longitude,$LivePeriod = '',$sReplyMarkup = "",$iReplyToMessage = Null,$bDisableNotification = False)
    Local $Query = $URL & "/sendLocation?chat_id=" & $sChatId & "&latitude=" & $Latitude & "&longitude=" & $Longitude
    If $LivePeriod <> '' Then $Query &= "&live_period=" & $LivePeriod
    If $sReplyMarkup <> Default Then $Query &= "&reply_markup=" & $sReplyMarkup
    If $iReplyToMessage <> '' Then $Query &= "&reply_to_message_id=" & $iReplyToMessage
    If $bDisableNotification Then $Query &= "&disable_notification=true"
    Local $Json = Json_Decode(__HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _SendLocation

Func _EditMessageLiveLocation($sChatId,$Latitude,$Longitude,$sReplyMarkup = "")
    $Query = $URL & "/editMessageLiveLocation?chat_id=" & $sChatId & "&latitude=" & $Latitude & "&longitude=" & $Longitude
    If $sReplyMarkup <> Default Then $Query &= "&reply_markup=" & $sReplyMarkup
    Local $Json = Json_Decode(__HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc  ;==> _EditMessageLiveLocation

Func _StopMessageLiveLocation($sChatId,$sReplyMarkup = "")
    $Query = $URL & "/stopMessageLiveLocation?chat_id=" & $sChatId
    If $sReplyMarkup <> Default Then $Query &= "&reply_markup=" & $sReplyMarkup
    Local $Json = Json_Decode(__HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _StopMessageLiveLocation


Func _SendVenue($sChatId,$Latitude,$Longitude,$Title,$Address,$Foursquare = '',$sReplyMarkup = "",$iReplyToMessage = Null,$bDisableNotification = False)
    Local $Query = $URL & "/sendVenue?chat_id=" & $sChatId & "&latitude=" & $Latitude & "&longitude=" & $Longitude & "&title=" & $Title & "&address=" & $Address
    If $Foursquare <> '' Then $Query &= "&foursquare=" & $Foursquare
    If $sReplyMarkup <> Default Then $Query &= "&reply_markup=" & $sReplyMarkup
    If $iReplyToMessage <> '' Then $Query &= "&reply_to_message_id=" & $iReplyToMessage
    If $bDisableNotification Then $Query &= "&disable_notification=true"
    Local $Json = Json_Decode(__HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _SendVenue

#cs ===============================================================================
   Function Name..:		_SendContact
   Description....:     Send a contact object
   Parameter(s)...:     $sChatId: Unique identifier for the target chat
						$Phone: Phone number of the contact;
						$FirstName: First name of the contact;
						$LastName (optional): Last name of the contact;
						$sReplyMarkup (optional): Custom keyboard markup;
						$iReplyToMessage (optional): If is a reply to another user's message;
						$bDisableNotification (optional): Sends the message silently. User will receive a notification with no sound
   Return Value(s):  	Return True if no error encountered, False otherwise
#ce ===============================================================================
Func _SendContact($sChatId,$Phone,$FirstName,$LastName = '',$sReplyMarkup = "",$iReplyToMessage = Null,$bDisableNotification = False)
    Local $Query = $URL & "/sendContact?chat_id=" & $sChatId & "&phone_number=" & $Phone & "&first_name=" & $FirstName
    If $LastName <> '' Then $Query &= "&last_name=" & $LastName
    If $sReplyMarkup <> Default Then $Query &= "&reply_markup=" & $sReplyMarkup
    If $iReplyToMessage <> '' Then $Query &= "&reply_to_message_id=" & $iReplyToMessage
    If $bDisableNotification = True Then $Query &= "&disable_notification=True"
    Local $Json = Json_Decode(__HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _SendContact

#cs ===============================================================================
   Function Name..:		_SendChatAction
   Description....:     tell the user that something is happening on the bot's side (Bot is typing...)
   Parameter(s)...:     $sChatId: Unique identifier for the target chat
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
Func _SendChatAction($sChatId,$Action)
    Local $Query = $URL & "/sendChatAction?chat_id=" & $sChatId & "&action=" & $Action
    Local $Json = Json_Decode(__HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _SendChatAction

#cs ===============================================================================
   Function Name..:		_GetUserProfilePhotos
   Description....:     Get (all) the profile pictures of an user
   Parameter(s)...:     $sChatId: Unique identifier for the target chat
						$Offset (optional): if you want a specific photo
						$Limit (optional): if you want only an x number of photos ;@TODO
   Return Value(s):  	Return an array with photo's count and File ID of the photos
#ce ===============================================================================
Func _GetUserProfilePhotos($sChatId,$Offset = '',$Limit = '')
    $Query = $URL & "/getUserProfilePhotos?user_id=" & $sChatId
    If $Offset <> '' Then $Query &= "&offset=" & $Offset
    If $Limit <> '' Then $Query &= "&limit=" & $Limit
    Local $Json = Json_Decode(__HttpPost($Query))
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

Func _KickChatMember($sChatId,$UserID,$UntilDate = '')
    $Query = $URL & "/kickChatMember?chat_id=" & $sChatId & "&user_id=" & $UserID
    If $UntilDate <> '' Then $Query &= "&until_date=" & $UntilDate
    Local $Json = Json_Decode(__HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _KickChatMember

Func _UnbanChatMember($sChatId,$UserID)
    $Query = $URL & "/unbanChatMember?chat_id=" & $sChatId & "&user_id=" & $UserID
    Local $Json = Json_Decode(__HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _UnbanChatMember

Func _ExportChatInviteLink($sChatId)
    $Query = $URL & "/exportChatInviteLink?chat_id=" & $sChatId
    Local $Json = Json_Decode(__HttpGet($Query))
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return Json_Get($Json,'[result]')
EndFunc ;==> _ExportChatInviteLink

Func _SetChatPhoto($sChatId,$Path)
    Local $Query = $URL & '/setChatPhoto'
    Local $hOpen = _WinHttpOpen()
    Local $Form = '<form action="' & $Query & '" method="post" enctype="multipart/form-data">' & _
                  '<input type="text" name="chat_id"/>' & _
                  '<input type="file" name="photo"/>'   & _
                  '</form>'
    Local $Response = _WinHttpSimpleFormFill($Form,$hOpen,Default, _
                       "name:chat_id", $sChatId, _
                       "name:photo"  , $Path)
    _WinHttpCloseHandle($hOpen)
    Local $Json = Json_Decode($Response)
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _SetChatPhoto

Func _DeleteChatPhoto($sChatId)
    $Query = $URL & "/deleteChatPhoto?chat_id=" & $sChatId
    Local $Json = Json_Decode(__HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _DeleteChatPhoto

Func _SetChatTitle($sChatId,$Title)
    $Query = $URL & "/setChatTitle?chat_id=" & $sChatId & "&title=" & $Title
    Local $Json = Json_Decode(__HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _SetChatTitle

Func _SetChatDescription($sChatId,$Description)
    $Query = $URL & "/setChatDescription?chat_id=" & $sChatId & "&description=" & $Description
    Local $Json = Json_Decode(__HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _SetChatDescription

Func _PinChatMessage($sChatId,$MsgID,$bDisableNotification = False)
    $Query = $URL & "/pinChatMessage?chat_id=" & $sChatId & "&message_id=" & $MsgID
    If $bDisableNotification Then $Query &= "&disable_notification=true"
    Local $Json = Json_Decode(__HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _PinChatMessage

Func _UnpinChatMessage($sChatId)
    $Query = $URL & "/unpinChatMessage?chat_id=" & $sChatId
    Local $Json = Json_Decode(__HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _UnpinChatMessage

Func _LeaveChat($sChatId)
    $Query = $URL & "/leaveChat?chat_id=" & $sChatId
    Local $Json = Json_Decode(__HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _LeaveChat

#cs ===============================================================================
   Function Name..:		_GetChat
   Description....:     Get information about the specified chat, like username and id of the user, or group name for group chat
   Parameter(s)...:     $sChatId: Unique identifier for the target chat
   Return Value(s):  	Return an array ;@TODO group support
#ce ===============================================================================
Func _GetChat($sChatId)
    Local $Query = $URL & "/getChat?chat_id=" & $sChatId
    Local $Json = Json_Decode(__HttpGet($Query))
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Local $chatData[4] = [ Json_Get($Json,'[result][id]'), _
                        Json_Get($Json,'[result][username]'), _
                        Json_Get($Json,'[result][first_name]'), _
                        Json_Get($Json,'[result][photo][big_file_id]')]
    Return $chatData
EndFunc ;==> _GetChat

Func _getChatAdministrators($sChatId)
    Local $Query = $URL & "/getChatAdministrators?chat_id=" & $sChatId
    ConsoleWrite(__HttpGet($Query))
EndFunc ;==> _getChatAdministrators

Func _getChatMembersCount($sChatId)
    Local $Query = $URL & "/getChatMembersCount?chat_id=" & $sChatId
    ConsoleWrite(__HttpGet($Query))
EndFunc ;==> _getChatMembersCount

Func _getChatMember($sChatId)
    Local $Query = $URL & "/getChatMember?chat_id=" & $sChatId
    ConsoleWrite(__HttpGet($Query))
EndFunc ;==> _getChatMember

Func _setChatStickerSet($sChatId)
    Local $Query = $URL & "/setChatStickerSet?chat_id=" & $sChatId
    ConsoleWrite(__HttpGet($Query))
EndFunc ;==> _setChatStickerSet

Func _deleteChatStickerSet($sChatId)
    Local $Query = $URL & "/deleteChatStickerSet?chat_id=" & $sChatId
    ConsoleWrite(__HttpGet($Query))
EndFunc ;==> _deleteChatStickerSet

; TODO: comment
Func _answerCallbackQuery($CallbackID,$Text = '',$cbURL = '',$ShowAlert = False,$CacheTime = '')
    ;In Callback context, there's a URL validation/restriction on the Telegram side
    ;Telegram Docs: https://core.telegram.org/bots/api#answercallbackquery
    ;cbURL can be a Game's URL or something like "t.me/your_bot?start=XXXX" 
    ;that open your bot with a parameter.
    Local $Query = $URL & "/answerCallbackQuery?callback_query_id=" & $CallbackID
    If $Text <> '' Then $Query &= "&text=" & $Text
    If $cbURL <> '' Then $Query &= "&url=" & $cbURL
    If $ShowAlert Then $Query &= "&show_alert=true"
    If $CacheTime <> '' Then $Query &= "&cache_time=" & $CacheTime
    Local $Json = Json_Decode(__HttpPost($Query))
    If Not (Json_IsObject($Json)) Then Return SetError($INVALID_JSON_RESPONSE,0,False) ; JSON Check
    If Not (Json_Get($Json,'[ok]') = 'true') Then Return SetError(2,0,False)
    Return True
EndFunc ;==> _answerCallbackQuery

; TODO: deletemessage
Func _deleteMessage($sChatId, $MsgID)
    Local $Query = $URL & "/deleteMessage?chat_id=" & $sChatId & "&message_id=" & $MsgID
    ConsoleWrite(__HttpGet($Query))
EndFunc ;==> _deleteMessage


#EndRegion

#Region "@EXTRA FUNCTIONS"


#cs ===============================================================================
   Function Name..:    	_Polling
   Description....:     Wait for incoming messages
   Parameter(s)...:     None
   Return Value(s):		Return an array with information about the messages
#ce ===============================================================================
Func _Polling()
    While 1
        Sleep(1000) ;Prevent CPU Overloading
        $newUpdates = _Telegram_GetUpdates()
        ;ConsoleWrite($newUpdates & @CRLF)
        If Not StringInStr($newUpdates,'update_id') Then ContinueLoop
        $msgData = __MsgDecode($newUpdates)
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

#cs ===============================================================================
   Function Name..:    	_CreateInlineKeyboard
   Description....:     Create and return a custom inline keyboard markup
   Parameter(s)...:     $Keyboard: an array with the keyboard. Use an empty position for line break.
                            Example: Local $InlineKeyboard[5] = ['Button1_Text','Button1_Data','','Button2_Text','Button2_Data']
   Return Value(s):		Return custom inline markup as string, encoded in JSON
#ce ===============================================================================
Func _CreateInlineKeyboard(ByRef $Keyboard)
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
   Function Name..:		__GetFileID
   Description....:     Get the 'File ID' of the last sent file
   Parameter(s)...:     $Json: JSON response from Telegram Server;
                        $type: File type, like photo, video, document...
   Return Value(s):  	Return the File ID as a string
#ce ===============================================================================
Func __GetFileID(ByRef $Json,$type)

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
EndFunc ;==> __GetFileID

#cs ===============================================================================
   Function Name..:		__GetFilePath()
   Description....:     Get the path of a file on Telegram Server by its File ID
   Parameter(s)...:     $FileID: Unique identifier for the file
   Return Value(s):  	Return the file path as a string
#ce ===============================================================================
Func __GetFilePath($FileID)
    Local $Query = $URL & "/getFile?file_id=" & $FileID
    Local $Json = Json_Decode(__HttpPost($Query))
    Return Json_Get($Json,'[result][file_path]')
EndFunc ;==> __GetFilePath

#cs ===============================================================================
   Function Name..:		__DownloadFile
   Description....:     Download and save a file from Telegram Server
   Parameter(s)...:     $filePath: Path of the file on Telegram Server (Get this from __GetFilePath)
   Return Value(s):  	Return file name if success, False otherwise
#ce ===============================================================================
Func __DownloadFile($filePath)
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
   Function Name..:		__UrlEncode
   Description....:     Encode text in url format
   Parameter(s)...:     $string: Text to encode
   Return Value(s):  	Return the encoded string
#ce ===============================================================================
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

#cs ===============================================================================
   Function Name..:		__MsgDecode
   Description....:     Decode message information from JSON string to an Array
   Parameter(s)...:     $Update: JSON Response from Telegram Server
   Return Value(s):  	Return an array with information about a message (check docs)
#ce ===============================================================================
Func __MsgDecode($Update)
    Local $Json = Json_Decode($Update)

    ;@PRIVATE CHAT MESSAGE
    If(Json_Get($Json,'[result][0][message][chat][type]') = 'private') Then
        Local $msgData[10] = [ _
            Json_Get($Json,'[result][0][update_id]'), _
            Json_Get($Json,'[result][0][message][message_id]'), _
            Json_Get($Json,'[result][0][message][from][id]'), _
            Json_Get($Json,'[result][0][message][from][username]'), _
            Json_Get($Json,'[result][0][message][from][first_name]') _
        ]

      If(Json_Get($Json,'[result][0][message][text]')) Then $msgData[5] = Json_Get($Json,'[result][0][message][text]')

		; TODO: Media recognition

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
         Json_Get($Json,'[result][0][message][chat][title]') _ ;[6] = Group Name
      ]

      If(Json_Get($Json,'[result][0][message][left_chat_member]')) Then
         $msgData[7] = 'left' ;[7] = Event
         $msgData[8] = Json_Get($Json,'[result][0][message][from][id]') ;[8] = Left member ID
         $msgData[9] = Json_Get($Json,'[result][0][message][from][username]') ;[9] = Left member Username
         $msgData[10] = Json_Get($Json,'[result][0][message][from][first_name]') ;[10] = Left member Firstname
      ElseIf(Json_Get($Json,'[result][0][message][new_chat_member]')) Then
         $msgData[7] = 'new' ;[7] = Event
         $msgData[8] = Json_Get($Json,'[result][0][message][from][id]') ;[8] = New member ID
         $msgData[9] = Json_Get($Json,'[result][0][message][from][username]') ;[9] = New member Username
         $msgData[10] = Json_Get($Json,'[result][0][message][from][first_name]') ;[10] = New member Firstname
      Else
         $msgData[7] = Json_Get($Json,'[result][0][message][text]') ;[7] = Text
      EndIf

      Return $msgData

   ;@EDITED PRIVATE CHAT MESSAGE
   ElseIf(Json_Get($Json,'[result][0][edited_message][chat][type]') = 'private') Then
      Local $msgData[10] = [ _
		 Json_Get($Json,'[result][0][update_id]'), _ ;[0] = Offset
		 Json_Get($Json,'[result][0][edited_message][message_id]'), _ ;[1] = Message ID
		 Json_Get($Json,'[result][0][edited_message][from][id]'), _ ;[2] = Chat ID
		 Json_Get($Json,'[result][0][edited_message][from][username]'), _ ;[3] = Username
		 Json_Get($Json,'[result][0][edited_message][from][first_name]') _ ;[4] = Firstname
	  ]

        If(Json_Get($Json,'[result][0][edited_message][text]')) Then $msgData[5] = Json_Get($Json,'[result][0][edited_message][text]') ;[5] = Text (eventually)

        ;Insert media recognition here

        Return $msgData

;@EDITED GROUP CHAT MESSAGE
   ElseIf(Json_Get($Json,'[result][0][edited_message][chat][type]') = 'group') Then
      Local $msgData[10] = [ _
		 Json_Get($Json,'[result][0][update_id]'), _ ;[0] = Offset
		 Json_Get($Json,'[result][0][edited_message][message_id]'), _ ;[1] = Message ID
		 Json_Get($Json,'[result][0][edited_message][from][id]'), _ ;[2] = Chat ID
		 Json_Get($Json,'[result][0][edited_message][from][username]'), _ ;[3] = Username
		 Json_Get($Json,'[result][0][edited_message][from][first_name]') _ ;[4] = Firstname
	  ]

        If(Json_Get($Json,'[result][0][edited_message][text]')) Then $msgData[5] = Json_Get($Json,'[result][0][edited_message][text]') ;[5] = Text (eventually)

        ;Insert media recognition here

        Return $msgData

    ;@CALLBACK QUERY
    ElseIf(Json_Get($Json,'[result][0][callback_query][id]') <> '') Then
        Local $msgData[10] = [ _
            Json_Get($Json,'[result][0][update_id]'), _ ;[0] = Offset
            Json_Get($Json,'[result][0][callback_query][id]'), _ ;[1] = Callback ID
            Json_Get($Json,'[result][0][callback_query][from][id]'), _ ;[2] = Chat ID
            Json_Get($Json,'[result][0][callback_query][from][username]'), _ ;[3] = Username
            Json_Get($Json,'[result][0][callback_query][from][first_name]'), _ ;[4] = Firstname
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
            Json_Get($Json,'[result][0][inline_query][from][first_name]'), _ ;[4] = Firstname
            Json_Get($Json,'[result][0][inline_query][query]') _ ;[5] = Inline Query Data
        ]

        Return $msgData

    ;@CHANNEL MESSAGE (Where bot is admin)
    ; Sample JSON:
    #comments-start
    {"ok":true,"result":[{
        "update_id":<int>,
        "channel_post":{
            "message_id":<int>,
            "chat":{
            "id":<int>,
            "title":"<string>",
            "type":"channel"},
            "date":<int>,
            "text":"<string>"
    }}]}
    #comments-end
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
      Local $msgData[10] = [ _
		 Json_Get($Json,'[result][0][update_id]'), _ ;[0] = Offset
		 Json_Get($Json,'[result][0][edited_message][message_id]'), _ ;[1] = Message ID
		 Json_Get($Json,'[result][0][edited_message][from][id]'), _ ;[2] = Chat ID
		 Json_Get($Json,'[result][0][edited_message][from][username]'), _ ;[3] = Username
		 Json_Get($Json,'[result][0][edited_message][from][first_name]') _ ;[4] = Firstname
	  ]

        If(Json_Get($Json,'[result][0][edited_message][text]')) Then $msgData[5] = Json_Get($Json,'[result][0][edited_message][text]') ;[5] = Text (eventually)

        ;Insert media recognition here

        Return $msgData
    EndIf

EndFunc ;==> __MsgDecode

#EndRegion

#Region "@HTTP Request"
#cs ======================================================================================
    Name .........: _Telegram_API_Call
    Description...: Sends a request to the Telegram API based on provided parameters
    Syntax .......: _Telegram_API_Call($sURL, $sPath = "", $sMethod = "GET", $sParams = "", $vBody = Null, $bValidate = True)
    Parameters....: 
                    $sURL        - URL to the Telegram API
                    $sPath       - [optional] Path to the specific API endpoint (Default is "")
                    $sMethod     - [optional] HTTP method for the request (Default is "GET")
                    $sParams     - [optional] Parameters for the request (Default is "")
                    $vBody       - [optional] Body content for the request (Default is Null)
                    $bValidate   - [optional] Boolean flag to validate Telegram response (Default is True)
    Return values.: 
                    Success      - Returns a JSON object with the 'result' field upon 
                                   successful API call and validation
                    Error        - Returns Null and sets @error flag according to encountered errors
#ce ======================================================================================
Func _Telegram_API_Call($sURL, $sPath = "", $sMethod = "GET", $sParams = "", $vBody = Null, $bValidate = True)
    ; Create HTTP request object
    Local $oHTTP = ObjCreate("WinHttp.WinHttpRequest.5.1")

    ; Set parameters, if any, and open request
    $oHTTP.Open($sMethod, $sURL & $sPath & ($sParams <> "" ? "?" & $sParams : ""), False)
    If (@error) Then Return SetError($TG_ERR_API_CALL, $TG_ERR_API_CALL_OPEN, Null)

    If ($sMethod = "POST") Then
        ; Set content type header for POST
        $oHTTP.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded")
    EndIF

    ; Send request with body if any
    If ($vBody) Then
        $oHTTP.send($vBody)
    Else
        $oHTTP.send()
    EndIf
    If (@error) Then Return SetError($TG_ERR_API_CALL, $TG_ERR_API_CALL_SEND, Null)

    ; Check status code
    If ($oHTTP.Status < 200 Or $oHTTP.Status > 299) Then Return SetError($TG_ERR_API_CALL, $TG_ERR_API_CALL_HTTP_NOT_SUCCESS, Null)

    ; Decode JSON
    Local $oBody = Json_Decode($oHTTP.ResponseText)

    ; Validate Telegram response
    If ($bValidate) Then
        ; Decoding error
        If (@error) Then Return SetError($TG_ERR_API_CALL, $TG_ERR_API_CALL_NOT_DECODED, Null)
        ; Invalid JSON
        If (Not Json_IsObject($oBody)) Then Return SetError($TG_ERR_API_CALL, $TG_ERR_API_CALL_INVALID_JSON, Null)
        ; Unsuccessful response
        If (Json_Get($oBody, "[ok]") <> True) Then Return SetError($TG_ERR_API_CALL, $TG_ERR_API_CALL_NOT_SUCCESS, Null)
    EndIF

    ; Return 'result' field as JSON object
    Return SetError(0, 0, Json_Get($oBody, "[result]"))
EndFunc

; TODO: I didn't figure out how to send a media using WinHttpRequest,
; so I'll continue using _WinHttp and form filling, but I'll try again
; to drop this dependencies and do everything with the above function.
Func _Telegram_SendMedia($sURL, $sPath, $sParams, $vMedia, $sMediaType, $bValidate = True)
    Local $hOpen = _WinHttpOpen()
    If (@error) Then Return SetError($TG_ERR_API_CALL, $TG_ERR_API_CALL_OPEN, Null)
        
    ; Params as query params and media as form data
    $sMediaType = StringLower($sMediaType)
    Local $sForm = _
        "<form action='" & $sURL & $sPath & "?" & $sParams & "' method='POST' enctype='multipart/form-data'>" & _
        "<input type='file' name='" & $sMediaType & "' /></form>"
                   
    Local $sResponse = _WinHttpSimpleFormFill($sForm, $hOpen, Default, "name:" & $sMediaType, $vMedia)
    If (@error) Then Return SetError($TG_ERR_API_CALL, $TG_ERR_API_CALL_SEND, Null)

    _WinHttpCloseHandle($hOpen)

    Local $oBody = Json_Decode($sResponse)

    ; Validate Telegram response
    ; (Same check as above)
    If ($bValidate) Then
        ; Decoding error
        If (@error) Then Return SetError($TG_ERR_API_CALL, $TG_ERR_API_CALL_NOT_DECODED, Null)
        ; Invalid JSON
        If (Not Json_IsObject($oBody)) Then Return SetError($TG_ERR_API_CALL, $TG_ERR_API_CALL_INVALID_JSON, Null)
        ; Unsuccessful response
        If (Json_Get($oBody, "[ok]") <> True) Then Return SetError($TG_ERR_API_CALL, $TG_ERR_API_CALL_NOT_SUCCESS, Null)
    EndIF

    Return SetError(0, 0, Json_Get($oBody, "[result]"))
EndFunc

Func __HttpGet($sURL,$sData = '')
    Local $oHTTP = ObjCreate("WinHttp.WinHttpRequest.5.1")
    $oHTTP.Open("GET",$sURL & "?" & $sData,False)
    If (@error) Then Return SetError(1,0,0)
    $oHTTP.Send()
    If (@error) Then Return SetError(2,0,0)
    If ($oHTTP.Status <> $HTTP_STATUS_OK) Then Return SetError(3,0,0)
    Return SetError(0,0,$oHTTP.ResponseText)
EndFunc ;==> __HttpGet

Func __HttpPost($sURL,$sData = '')
    Local $oHTTP = ObjCreate("WinHttp.WinHttpRequest.5.1")
    $oHTTP.Open("POST",$sURL,False)
    If (@error) Then Return SetError(1,0,0)
    $oHTTP.SetRequestHeader("Content-Type","application/x-www-form-urlencoded")
    $oHTTP.Send($sData)
    If (@error) Then Return SetError(2,0,0)
    If ($oHTTP.Status <> $HTTP_STATUS_OK) Then Return SetError(3,0,0)
    Return SetError(0,0,$oHTTP.ResponseText)
EndFunc ;==> __HttpPost
#EndRegion
