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
#include <Array.au3>
#include <String.au3>
#include "include/JSON.au3"
#include "include/WinHttp.au3"

;@GLOBAL
Global $URL	   = ""
Global $TOKEN  = ""
Global $OFFSET = 0

;@CONST
Const $BASE_URL = "https://api.telegram.org/bot"
Const $BOT_CRLF = _Telegram_UrlEncode(@CRLF)

;@ERRORS
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
    Name .......: _Telegram_Init
    Description.: Initializes a Telegram connection using the provided token
    Parameters..:
                    $sToken - Token to authenticate with Telegram API
                    $bValidate - [optional] Boolean flag to indicate whether to validate 
                        the token (Default is False)
    Return......:
                    Success - True upon successful initialization
                    Failure - False, sets @error to $TG_ERR_INIT and set @extended to:
 - $TG_ERR_INIT_MISSING_TOKEN if token is empty
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

#Region "API Implementation"

#cs ======================================================================================
    Name .......: _Telegram_GetMe
    Description.: Retrieves information about the current bot using Telegram API
    Reference...: https://core.telegram.org/bots/api#getme
    Parameters..: None
    Return......:
                    Success - An object with information about the bot
                    Failure - Null, sets @error/@extended to the encountered error code
#ce ======================================================================================
Func _Telegram_GetMe()
	Local $oResponse = _Telegram_API_Call($URL, "/getMe")
    If (@error) Then Return SetError(@error, @extended, Null)

    Return $oResponse
EndFunc ;==>_Telegram_GetMe

#cs ======================================================================================
    Name .......: _Telegram_GetUpdates
    Description.: Retrieves updates from the Telegram API, optionally updating the offset
    Reference...: https://core.telegram.org/bots/api#getupdates
    Parameters..:
                    $bUpdateOffset - [optional] Boolean flag indicating whether to update
                        the offset (Default is True)
    Return......:
                    Success - A list of Message objects. If $bUpdateOffset is True, the 
                        offset might get updated based on the retrieved updates
                    Failure - Null, sets @error/@extended to the encountered error code
#ce ======================================================================================
Func _Telegram_GetUpdates($bUpdateOffset = True)
    ; Get updates
    Local $aMessages = _Telegram_API_Call($URL, "/getUpdates", "GET", "offset=" & $OFFSET)
    If (@error) Then Return SetError(@error, @extended, Null)

    If ($bUpdateOffset) Then
        ; Get messages count
        Local $iMessageCount = UBound($aMessages)
        if ($iMessageCount > 0) Then
            ; Set offset as last message id + 1
            $iUpdateId = Json_Get($aMessages[$iMessageCount - 1], "[update_id]")
            $OFFSET = $iUpdateId + 1
        EndIf
	EndIf

    Return $aMessages
EndFunc ;==> _Telegram_GetUpdates

#cs ======================================================================================
    Name .......: _Telegram_LogOut
    Description.: Logs out from the cloud Bot API server before launching the bot locally
    Reference...: https://core.telegram.org/bots/api#logout
    Parameters..: None
    Return......: 
                    Success - True
                    Failure - False, sets @error/@extended to the encountered error code
#ce ======================================================================================
Func _Telegram_LogOut()
    Local $oResponse = _Telegram_API_Call($URL, "/logOut", "GET", "")
    If (@error) Then Return SetError(@error, @extended, Null)

    Return True
EndFunc ;==> _Telegram_LogOut

#cs ======================================================================================
    Name .......: _Telegram_Close
    Description.: Close the bot instance before moving it from one local server to another
    Reference...: https://core.telegram.org/bots/api#close
    Parameters..: None
    Return......: 
                    Success - True
                    Failure - False, sets @error/@extended to the encountered error code
#ce ======================================================================================
Func _Telegram_Close()
    Local $oResponse = _Telegram_API_Call($URL, "/close", "GET", "")
    If (@error) Then Return SetError(@error, @extended, Null)
    Return True
EndFunc ;==> _Telegram_Close

#cs ======================================================================================
    Name .......: _Telegram_SendMessage
    Description.: Sends a message via the Telegram API to a specified chat ID
    Reference...: https://core.telegram.org/bots/api#sendmessage
    Parameters..:
                    $sChatId - ID of the chat where the message will be sent
                    $sText - Text content of the message
                    $sParseMode - [optional] Parse mode for the message (Default is Null)
                    $sReplyMarkup - [optional] Reply markup for the message (Default is Null)
                    $iReplyToMessage - [optional] ID of the message to reply to (Default is Null)
                    $bDisableWebPreview - [optional] Boolean flag to disable web preview (Default is False)
                    $bDisableNotification - [optional] Boolean flag to disable notification (Default is False)
    Return......:
                    Success - An object containing information about the sent message
                    Failure - Null,, sets @error/@extended to the encountered error code
#ce ======================================================================================
Func _Telegram_SendMessage($sChatId, $sText, $sParseMode = Null, $sReplyMarkup = Null, $iReplyToMessage = Null, $bDisableWebPreview = False, $bDisableNotification = False)
    ; TODO: Enum for ParseMode
    If ($sChatId = "" Or $sChatId = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)
    If ($sText = "" Or $sText = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)
    If ($sParseMode <> Null And $sParseMode <> "MarkdownV2" And $sParseMode <> "HTML") Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)

    Local $sParams = _Telegram_BuildCommonParams($sChatId, $sParseMode, $sReplyMarkup, $iReplyToMessage, $bDisableNotification, $bDisableWebPreview)
    $sParams &= "&text=" & $sText

    Local $oResponse = _Telegram_API_Call($URL, "/sendMessage", "POST", $sParams)
    If (@error) Then Return SetError(@error, @extended, Null)

    Return $oResponse
EndFunc ;==> _Telegram_SendMessage

#cs ======================================================================================
    Name .......: _Telegram_ForwardMessage
    Description.: Forwards a message from one chat to another using the Telegram API
    Reference...: https://core.telegram.org/bots/api#forwardmessage
    Parameters..:
                    $sChatId - ID of the chat where the message will be forwarded
                    $sFromChatId - ID of the chat where the original message is from
                    $iMessageId - ID of the message to be forwarded
                    $bDisableNotification - [optional] Boolean flag to disable notification (Default is False)
    Return......:
                    Success - An object containing information about the forwarded message
                    Failure - Null, sets @error/@extended to the encountered error code
#ce ======================================================================================
Func _Telegram_ForwardMessage($sChatId, $sFromChatId, $iMessageId, $bDisableNotification = False)
    If ($sChatId = "" Or $sChatId = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)
    If ($sFromChatId = "" Or $sFromChatId = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)
    If ($iMessageId = "" Or $iMessageId = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)

    Local $sParams = _Telegram_BuildCommonParams($sChatId, Null, Null, Null, $bDisableNotification)
    $sParams &= _
        "&from_chat_id=" & $sFromChatId & _
        "&message_id=" & $iMessageId

    Local $oResponse = _Telegram_API_Call($URL, "/forwardMessage", "POST", $sParams)
    If (@error) Then Return SetError(@error, @extended, Null)

    Return $oResponse
EndFunc ;==> _Telegram_ForwardMessage

#cs ======================================================================================
    Name .......: _Telegram_Send<Type>
    Description.: Sends a <Type> via the Telegram API to a specified chat ID
    Reference...: https://core.telegram.org/bots/api#sendphoto
    Parameters..:
                    $sChatId - ID of the chat where the <Type> will be sent
                    $<Type> - <Type> to be sent, a string representing a local path to a file, 
                        a remote URL or a Telegram File ID. Supported objects are: photo,
                        audio, document, video, animation, voice, videonote, mediagroup
                    $sCaption - [optional] Caption for the <Type> (Default is "")
                    $sParseMode - [optional] Parse mode for the caption (Default is "")
                    $sReplyMarkup - [optional] Reply markup for the <Type> (Default is "")
                    $iReplyToMessage - [optional] ID of the message to reply to (Default is Null)
                    $bDisableNotification - [optional] Boolean flag to disable notification (Default is False)
    Return......:
                    Success - An object containing information about
                                             the sent <Type>
                    Failure - Null, sets @error/@extended to the encountered error code
#ce ======================================================================================
Func _Telegram_SendPhoto($sChatId, $sPhoto, $sCaption = "", $sParseMode = "", $sReplyMarkup = "", $iReplyToMessage = Null, $bDisableNotification = False)
    Local $oResponse = _Telegram_SendMedia($sChatId, $sPhoto, "photo", $sCaption, $sParseMode, $sReplyMarkup, $iReplyToMessage, $bDisableNotification)
    If (@error) Then Return SetError(@error, @extended, Null)
    Return $oResponse
EndFunc ;==> _Telegram_SendPhoto

Func _Telegram_SendAudio($sChatId,$sAudio,$sCaption = '', $sParseMode = "", $sReplyMarkup = "",$iReplyToMessage = Null,$bDisableNotification = False)
    Local $oResponse = _Telegram_SendMedia($sChatId, $sAudio, "audio", $sCaption, $sReplyMarkup, $iReplyToMessage, $bDisableNotification)
    If (@error) Then Return SetError(@error, @extended, Null)
    Return $oResponse
EndFunc ;==> _Telegram_SendAudio

Func _Telegram_SendDocument($sChatId,$Document,$sCaption = '',$sParseMode = "", $sReplyMarkup = "",$iReplyToMessage = Null,$bDisableNotification = False)
    Local $oResponse = _Telegram_SendMedia($sChatId, $Document, "document", $sCaption, $sParseMode, $sReplyMarkup, $iReplyToMessage, $bDisableNotification)
    If (@error) Then Return SetError(@error, @extended, Null)
    Return $oResponse
EndFunc ;==> _Telegram_SendDocument

Func _Telegram_SendVideo($sChatId,$Video,$sCaption = '', $sParseMode = "", $sReplyMarkup = "",$iReplyToMessage = Null,$bDisableNotification = False)
    Local $oResponse = _Telegram_SendMedia($sChatId, $Video, "video", $sCaption, $sParseMode, $sReplyMarkup, $iReplyToMessage, $bDisableNotification)
    If (@error) Then Return SetError(@error, @extended, Null)
    Return $oResponse
EndFunc ;==> _Telegram_SendVideo

Func _Telegram_SendAnimation($sChatId,$Animation,$sCaption = '',$sParseMode = "", $sReplyMarkup = "",$iReplyToMessage = Null,$bDisableNotification = False)
    Local $oResponse = _Telegram_SendMedia($sChatId, $Animation, "animation", $sCaption, $sParseMode, $sReplyMarkup, $iReplyToMessage, $bDisableNotification)
    If (@error) Then Return SetError(@error, @extended, Null)
    Return $oResponse
EndFunc ;==> _Telegram_SendAnimation

Func _Telegram_SendVoice($sChatId,$Path,$sCaption = '',$sParseMode = "", $sReplyMarkup = "",$iReplyToMessage = Null,$bDisableNotification = False)
    Local $oResponse = _Telegram_SendMedia($sChatId, $Path, "voice", $sCaption, $sParseMode, $sReplyMarkup, $iReplyToMessage, $bDisableNotification)
    If (@error) Then Return SetError(@error, @extended, Null)
    Return $oResponse
EndFunc ;==> _Telegram_SendVoice

Func _Telegram_SendVideoNote($sChatId,$VideoNote,$sParseMode = "", $sReplyMarkup = "",$iReplyToMessage = Null,$bDisableNotification = False)
    Local $oResponse = _Telegram_SendMedia($sChatId, $VideoNote, "video_note", $sParseMode, $sReplyMarkup, $iReplyToMessage, $bDisableNotification)
    If (@error) Then Return SetError(@error, @extended, Null)
    Return $oResponse
EndFunc ;==> _Telegram_SendVideoNote

Func _Telegram_SendMediaGroup($sChatId,$aMedias,$bDisableNotification = False)
    Local $oResponse = _Telegram_SendMedia($sChatId, $aMedias, "media_group", $bDisableNotification)
    If (@error) Then Return SetError(@error, @extended, Null)
    Return $oResponse
EndFunc

#cs ======================================================================================
    Name .......: _Telegram_SendLocation
    Description.: Sends a location to the specified chat.
    Parameters..:
                    $sChatId - The chat ID.
                    $fLatitude - The latitude of the location.
                    $fLongitude - The longitude of the location.
                    $fHorizontalAccuracy - [optional] The radius of uncertainty for the location, measured in meters.
                    $iLivePeriod - [optional] Period in seconds for which the location will be updated (for live locations).
                    $iProximityAlertRadius - [optional] The radius for triggering proximity alerts.
                    $sReplyMarkup - [optional] Additional interface options. Default is an empty string.
                    $iReplyToMessage - [optional] ID of the message to reply to.
                    $bDisableNotification - [optional] Disables notifications if set to True. Default is False.
    Return......:
                    Success - Returns the API response.
                    Failure - Returns @error flag along with @extended flag if an error occurs.
                                   Possible @error values:
                                      $TG_ERR_BAD_INPUT - Invalid input parameters.
                                      Other errors based on the API response.
#ce ======================================================================================
Func _Telegram_SendLocation($sChatId,$fLatitude,$fLongitude,$fHorizontalAccuracy = Null, $iLivePeriod = Null,$iProximityAlertRadius = Null, $sReplyMarkup = "",$iReplyToMessage = Null,$bDisableNotification = False)
    If ($sChatId = "" Or $sChatId = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)
    If ($fLatitude = "" Or $fLatitude = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)
    If ($fLongitude = "" Or $fLongitude = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)

    Local $sParams = _Telegram_BuildCommonParams($sChatId, Null, $sReplyMarkup, $iReplyToMessage, $bDisableNotification)
    $sParams &= _
        "&latitude=" & $fLatitude & _
        "&longitude=" & $fLongitude

    If $iLivePeriod <> Null Then $sParams &= "&live_period=" & $iLivePeriod
    If $fHorizontalAccuracy <> Null Then $sParams &= "&horizontal_accuracy=" & $fHorizontalAccuracy
    If $iProximityAlertRadius <> Null Then $sParams &= "&proximity_alert_radius=" & $iProximityAlertRadius

    Local $oResponse = _Telegram_API_Call($URL, "/sendLocation", "GET", $sParams)
    If (@error) Then Return SetError(@error, @extended, Null)
    Return $oResponse

EndFunc ;==> _Telegram_SendLocation

#cs ======================================================================================
    Name .......: _Telegram_SendVenue
    Description.: Sends information about a venue to a specified chat.
    Parameters..:
                    $sChatId - The chat ID.
                    $fLatitude - Latitude of the venue.
                    $fLongitude - Longitude of the venue.
                    $sTitle - Name of the venue.
                    $sAddress - Address of the venue.
                    $sFoursquareId - [optional] Foursquare identifier of the venue (Default is "").
                    $sFoursquareType - [optional] Foursquare type of the venue (Default is "").
                    $sGooglePlaceId - [optional] Google Places identifier of the venue (Default is "").
                    $sGooglePlaceType - [optional] Google Places type of the venue (Default is "").
                    $sReplyMarkup - [optional] Additional interface options (Default is "").
                    $iReplyToMessage - [optional] ID of the message to reply to (Default is Null).
                    $bDisableNotification - [optional] Disables notifications if set to True (Default is False).
    Return......:
                    Success - Returns the API response.
                    Failure - Returns @error flag along with @extended flag if an error occurs.
                                   Possible @error values:
                                      $TG_ERR_BAD_INPUT - Invalid input parameters.
                                      Other errors based on the API response.
#ce ======================================================================================
Func _Telegram_SendVenue($sChatId, $fLatitude, $fLongitude, $sTitle, $sAddress, $sFoursquareId = "", $sFoursquareType = "", $sGooglePlaceId = "", $sGooglePlaceType = "", $sReplyMarkup = "", $iReplyToMessage = Null, $bDisableNotification = False)
    If ($sChatId = "" Or $sChatId = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)
    If ($fLatitude = "" Or $fLatitude = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)
    If ($fLongitude = "" Or $fLongitude = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)
    If ($sTitle = "" Or $sTitle = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)
    If ($sAddress = "" Or $sAddress = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)

    Local $sParams = _Telegram_BuildCommonParams($sChatId, Null, $sReplyMarkup, $iReplyToMessage, $bDisableNotification)
    $sParams &= _
        "&latitude=" & $fLatitude & _
        "&longitude=" & $fLongitude & _
        "&title=" & $sTitle & _
        "&address=" & $sAddress

    If $sFoursquareId <> "" Then $sParams &= "&foursquare_id=" & $sFoursquareId
    If $sFoursquareType <> "" Then $sParams &= "&foursquare_type=" & $sFoursquareType
    If $sGooglePlaceId <> "" Then $sParams &= "&google_place_id=" & $sGooglePlaceId
    If $sGooglePlaceType <> "" Then $sParams &= "&google_place_type=" & $sGooglePlaceType

    Local $oResponse = _Telegram_API_Call($URL, "/sendVenue", "POST", $sParams)
    If (@error) Then Return SetError(@error, @extended, Null)
    Return $oResponse
EndFunc ;==> _Telegram_SendVenue

#cs ======================================================================================
    Name .......: _Telegram_SendContact
    Description.: Sends a contact to the specified chat.
    Parameters..:
                    $sChatId - The chat ID.
                    $sPhoneNumber - Contact's phone number.
                    $sFirstName - Contact's first name.
                    $sLastName - [optional] Contact's last name. Default is an empty string.
                    $vCard - [optional] Additional data about the contact in the form of a vCard. Default is an empty string.
                    $sReplyMarkup - [optional] Additional interface options. Default is an empty string.
                    $iReplyToMessage - [optional] ID of the message to reply to. Default is Null.
                    $bDisableNotification - [optional] Disables notifications if set to True. Default is False.
    Return......:
                    Success - Returns the API response.
                    Failure - Returns @error flag along with @extended flag if an error occurs.
                                   Possible @error values:
                                      $TG_ERR_BAD_INPUT - Invalid input parameters.
                                      Other errors based on the API response.
#ce ======================================================================================
Func _Telegram_SendContact($sChatId, $sPhoneNumber, $sFirstName, $sLastName = "", $vCard = "", $sReplyMarkup = "", $iReplyToMessage = Null, $bDisableNotification = False)
    If ($sChatId = "" Or $sChatId = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)
    If ($sPhoneNumber = "" Or $sPhoneNumber = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)
    If ($sFirstName = "" Or $sFirstName = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)

    Local $sParams = _Telegram_BuildCommonParams($sChatId, Null, $sReplyMarkup, $iReplyToMessage, $bDisableNotification)
    $sParams &= _
        "&phone_number=" & $sPhoneNumber & _
        "&first_name=" & $sFirstName

    If $sLastName <> "" Then $sParams &= "&last_name=" & $sLastName
    If $vCard <> "" Then $sParams &= "&vcard=" & $vCard

    Local $oResponse = _Telegram_API_Call($URL, "/sendContact", "GET", $sParams)
    If (@error) Then Return SetError(@error, @extended, Null)
    Return $oResponse
EndFunc ;==> _Telegram_SendContact

; TODO: sendPoll (https://core.telegram.org/bots/api#sendpoll)

; TODO: sendDice (https://core.telegram.org/bots/api#senddice)

#cs ======================================================================================
    Name .......: _Telegram_SendChatAction
    Description.: Use this method when you need to tell the user that something is happening on the bot's side
    Parameters..:
                    $sChatId - Unique identifier for the target chat or username of the target channel (in the format @channelusername).
                    $sAction - Type of action to broadcast.
                                  Choose one, depending on what the user is about to receive: 
                                  typing, upload_photo, record_video, upload_video, record_voice, upload_voice, 
                                  upload_document, choose_sticker, find_location, record_video_note, upload_video_note.
    Return......:
                    Success - Returns True on success.
                    Failure - Null and sets @error flag if an error occurs.
                                  Possible @error values:
                                    $TG_ERR_BAD_INPUT - Invalid input parameters.
                                    Other errors based on the API response.
#ce ======================================================================================
Func _Telegram_SendChatAction($sChatId, $sAction)
    If ($sChatId = "" Or $sChatId = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)
    If ($sAction = "" Or $sAction = Null Or StringInStr("typing,upload_photo,record_video,upload_video,record_voice,upload_voice,upload_document,choose_sticker,find_location,record_video_note,upload_video_note", $sAction) = 0) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)

    Local $sParams = _Telegram_BuildCommonParams($sChatId)
    $sParams &= "&action=" & $sAction

    Local $oResponse = _Telegram_API_Call($URL, "/sendChatAction", "GET", $sParams)
    If (@error) Then Return SetError(@error, @extended, Null)
    Return $oResponse
EndFunc ;==> _Telegram_SendChatAction

; TODO: setMessageReaction (https://core.telegram.org/bots/api#setmessagereaction)

; TODO: getUserProfilePhotos (https://core.telegram.org/bots/api#getuserprofilephotos)

; TODO: getFile (https://core.telegram.org/bots/api#getfile)

; TODO: banChatMember (https://core.telegram.org/bots/api#banchatmember)

; TODO: unbanChatMember (https://core.telegram.org/bots/api#unbanchatmember)

; TODO: restrictChatMember (https://core.telegram.org/bots/api#restrictchatmember)

; TODO: propoteChatMember (https://core.telegram.org/bots/api#promotechatmember)

; TODO: setChatAdministratorCustomTitle (https://core.telegram.org/bots/api#setchatadministratorcustomtitle)

; TODO: banChatSenderChat (https://core.telegram.org/bots/api#banchatsenderchat)

; TODO: unbanChatSenderChat (https://core.telegram.org/bots/api#unbanchatsenderchat)

; TODO: setChatPermissions (https://core.telegram.org/bots/api#setchatpermissions)

; TODO: exportChatInviteLink (https://core.telegram.org/bots/api#exportchatinvitelink)

; TODO: createChatInviteLink (https://core.telegram.org/bots/api#createchatinvitelink)

; TODO: editChatInviteLink (https://core.telegram.org/bots/api#editchatinvitelink)

; TODO: revokeChatInviteLink (https://core.telegram.org/bots/api#revokechatinvitelink)

; TODO: approveChatJoinRequest (https://core.telegram.org/bots/api#approvechatjoinrequest)

; TODO: declineChatJoinRequest (https://core.telegram.org/bots/api#declinechatjoinrequest)

; TODO: setChatPhoto (https://core.telegram.org/bots/api#setchatphoto)

; TODO: deleteChatPhoto (https://core.telegram.org/bots/api#deletechatphoto)

; TODO: setChatTitle (https://core.telegram.org/bots/api#setchattitle)

; TODO: setChatDescription (https://core.telegram.org/bots/api#setchatdescription)

; TODO: pinChatMessage (https://core.telegram.org/bots/api#pinchatmessage)

; TODO: unpinChatMessage (https://core.telegram.org/bots/api#unpinchatmessage)

; TODO: unpinAllChatMessages (https://core.telegram.org/bots/api#unpinallchatmessages)

#cs ======================================================================================
    Name .......: _Telegram_LeaveChat
    Description.: Use this method for your bot to leave a group, supergroup or channel.
    Reference ..: https://core.telegram.org/bots/api#leavechat
    Parameters..:
                    $sChatId - Unique identifier for the target chat
    Return......:
                    Success - A boolean on success, depending on the Telegram response
                    Failure - Null, sets @error/@extended to the encountered error code
#ce ======================================================================================
Func _Telegram_LeaveChat($sChatId)
    If ($sChatId = "" Or $sChatId = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)

    Local $sParams = _Telegram_BuildCommonParams($sChatId)

    Local $bResponse = _Telegram_API_Call($URL, "/leaveChat", "GET", $sParams)
    If (@error) Then Return SetError(@error, @extended, Null)

    Return $bResponse
EndFunc

#cs ======================================================================================
    Name .......: _Telegram_GetChat
    Description.: Retrieves up-to-date information about a specific chat.
    Parameters..:
                    $sChatId - Unique identifier for the target chat or username of the target supergroup or channel (in the format @channelusername)
    Return......:
                    Success - A Chat object containing information about the chat
                    Failure - Null, sets @error/@extended to the encountered error code
                               Possible @error values:
                                  $TG_ERR_BAD_INPUT - Invalid input parameters
                                  Other errors based on the API response
#ce ======================================================================================
Func _Telegram_GetChat($sChatId)
    If ($sChatId = "" Or $sChatId = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)

    Local $sParams = _Telegram_BuildCommonParams($sChatId)

    Local $oResponse = _Telegram_API_Call($URL, "/getChat", "GET", $sParams)
    If (@error) Then Return SetError(@error, @extended, Null)

    Return $oResponse
EndFunc ;==> _Telegram_GetChat

#cs ======================================================================================
    Name .......: _Telegram_GetChatAdministrators
    Description.: Get a list of administrators in a chat.
    References..: https://core.telegram.org/bots/api#getchatadministrators
    Parameters..:
                    $sChatId - Unique identifier for the target chat
    Return......:
                    Success - Array of ChatMember objects
                    Failure - Null, sets @error/@extended to the encountered error code
#ce ======================================================================================
Func _Telegram_GetChatAdministrators($sChatId)
    If ($sChatId = "" Or $sChatId = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)

    Local $sParams = _Telegram_BuildCommonParams($sChatId)

    Local $aResponse = _Telegram_API_Call($URL, "/getChatAdministrators", "GET", $sParams)
    If (@error) Then Return SetError(@error, @extended, Null)

    Return $aResponse
EndFunc

#cs ======================================================================================
    Name .......: _Telegram_GetChatMemberCount
    Description.: Returns the number of members in a chat.
    References..: https://core.telegram.org/bots/api#getchatmembercount
    Parameters..:
                    $sChatId - Unique identifier for the target chat
    Return......:
                    Success - Integer number of members in the chat
                    Failure - Null, sets @error/@extended to the encountered error code
#ce ======================================================================================
Func _Telegram_GetChatMemberCount($sChatId)
    If ($sChatId = "" Or $sChatId = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)

    Local $sParams = _Telegram_BuildCommonParams($sChatId)

    Local $iResponse = _Telegram_API_Call($URL, "/getChatMemberCount", "GET", $sParams)
    If (@error) Then Return SetError(@error, @extended, Null)

    Return $iResponse
EndFunc

#cs ======================================================================================
    Name .......: _Telegram_GetChatMember
    Description.: Returns information about a member of a chat.
    References..: https://core.telegram.org/bots/api#getchatmember
    Parameters..:
                    $sChatId - Unique identifier for the target chat
                    $sUserId - Unique identifier of the target user
    Return......:
                    Success - ChatMember object
                    Failure - Null, sets @error/@extended to the encountered error code
#ce ======================================================================================
Func _Telegram_GetChatMember($sChatId, $sUserId)
    If ($sChatId = "" Or $sChatId = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)
    If ($sUserId = "" Or $sUserId = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)

    Local $sParams = _Telegram_BuildCommonParams($sChatId)
    $sParams &= "&user_id=" & $sUserId

    Local $oResponse = _Telegram_API_Call($URL, "/getChatMember", "GET", $sParams)
    If (@error) Then Return SetError(@error, @extended, Null)

    Return $oResponse
EndFunc

; TODO: setChatStickerSet (https://core.telegram.org/bots/api#setchatstickerset)

; TODO: deleteChatStickerSet (https://core.telegram.org/bots/api#deletechatstickerset)

; TODO: getForumTopicIconSticker (https://core.telegram.org/bots/api#getforumtopiciconsticker)

; TODO: createForumTopic (https://core.telegram.org/bots/api#createforumtopic)

; TODO: editForumTopic (https://core.telegram.org/bots/api#editforumtopic)

; TODO: closeForumTopic (https://core.telegram.org/bots/api#closeforumtopic)

; TODO: reopenForumTopic (https://core.telegram.org/bots/api#reopenforumtopic)

; TODO: deleteForumTopic (https://core.telegram.org/bots/api#deleteforumtopic)

; TODO: unpinAllForumTopicMessages (https://core.telegram.org/bots/api#unpinallforumtopicmessages)

; TODO: editGeneralForumTopic (https://core.telegram.org/bots/api#editgeneralforumtopic)

; TODO: closeGeneralForumTopic (https://core.telegram.org/bots/api#closegeneralforumtopic)

; TODO: reopenGeneralForumTopic (https://core.telegram.org/bots/api#reopengeneralforumtopic)

; TODO: hideGeneralForumTopic (https://core.telegram.org/bots/api#hidegeneralforumtopic)

; TODO: unhideGeneralForumTopic (https://core.telegram.org/bots/api#unhidegeneralforumtopic)

; TODO: unpinAllGeneralForumTopicMessages (https://core.telegram.org/bots/api#unpinallgeneralforumtopicmessages)

; TODO: answerCallbackQuery (https://core.telegram.org/bots/api#answercallbackquery)

; TODO: getUserChatBoosts (https://core.telegram.org/bots/api#getuserchatboosts)

; TODO: getBusinessConnection (https://core.telegram.org/bots/api#getbusinessconnection)

; TODO: setMyCommands (https://core.telegram.org/bots/api#setmycommands)

; TODO: deleteMyCommands (https://core.telegram.org/bots/api#deletemycommands)

; TODO: getMyCommands (https://core.telegram.org/bots/api#getmycommands)

; TODO: setMyName (https://core.telegram.org/bots/api#setmyname)

; TODO: getMyName (https://core.telegram.org/bots/api#getmyname)

; TODO: setMyDescription (https://core.telegram.org/bots/api#setmydescription)

; TODO: getMyDescription (https://core.telegram.org/bots/api#getmydescription)

; TODO: setMyShortDescription (https://core.telegram.org/bots/api#setmyshortdescription)

; TODO: getMyShortDescription (https://core.telegram.org/bots/api#getmyshortdescription)

; TODO: setChatMenuButton (https://core.telegram.org/bots/api#setchatmenubutton)

; TODO: getChatMenuButton (https://core.telegram.org/bots/api#getchatmenubutton)

; TODO: setMyDefaultAdministratorRights (https://core.telegram.org/bots/api#setmydefaultadministratorrights)

; TODO: getMyDefaultAdministratorRights (https://core.telegram.org/bots/api#getmydefaultadministratorrights)

; TODO: editMessageLiveLocation (https://core.telegram.org/bots/api#editmessagelivelocation)

; TODO: stopMessageLiveLocation (https://core.telegram.org/bots/api#stopmessagelivelocation) 

; TODO: editMessageText (https://core.telegram.org/bots/api#editmessagetext)

; TODO: editMessageCaption (https://core.telegram.org/bots/api#editmessagecaption)

; TODO: editMessageMedia (https://core.telegram.org/bots/api#editmessagemedia)

; TODO: editMessageLiveLocation (https://core.telegram.org/bots/api#editmessagelivelocation)

; TODO: stopMessageLiveLocation (https://core.telegram.org/bots/api#stopmessagelivelocation)

; TODO: editMessageReplyMarkup (https://core.telegram.org/bots/api#editmessagereplymarkup)

; TODO: stopPoll (https://core.telegram.org/bots/api#stoppoll)

#cs ======================================================================================
    Name .......: _Telegram_DeleteMessage
    Description.: Deletes a message
    Reference...: https://core.telegram.org/bots/api#deletemessage
    Parameters..: 
                    $sChatId - Unique identifier for the target chat or username of the target channel
                    $iMessageId - Identifier of the message to edit
    Return......: 
                    Success - An object with information about the edited message
                    Failure - Null, sets @error/@extended to the encountered error code
#ce ======================================================================================
Func _Telegram_DeleteMessage($sChatId, $iMessageId)
    If ($sChatId = "" Or $sChatId = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)
    If ($iMessageId = "" Or $iMessageId = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)
    
    Local $sParams = _Telegram_BuildCommonParams($sChatId)
    $sParams &= "&message_id=" & $iMessageId
    
    Local $oResponse = _Telegram_API_Call($URL, "/deleteMessage", "POST", $sParams)
    If (@error) Then Return SetError(@error, @extended, Null)
    
    Return $oResponse
EndFunc ;==> _Telegram_DeleteMessage

; TODO: deleteMessages (https://core.telegram.org/bots/api#deletemessages)

#EndRegion

#Region "Extra"

#cs ===============================================================================
    Name .......: _Telegram_Polling
    Description.: Wait for incoming messages
    Parameters..:     
                        $iSleep - The time to wait in milliseconds between polling requests
                            (Default is 1000 ms.)
    Return......: An array of JSON objects with information about messages
#ce ===============================================================================
Func _Telegram_Polling($iSleep = 1000)
    While 1
        Sleep($iSleep) ;Wait for $iSleep ms between polling requests
        $newMessages = _Telegram_GetUpdates()
        If (UBound($newMessages) > 0) Then Return $newMessages
    WEnd
EndFunc ;==> _Telegram_Polling

#cs ===============================================================================
   Name .......:    	_CreateKeyboard
   Description.:     Create and return a custom keyboard markup
   Parameters..:     $Keyboard: an array with the keyboard. Use an empty position for line break.
                            Example: Local $Keyboard[4] = ['Top Left','Top Right','','Second Row']
                        $Resize: Set true if you want to resize the buttons of the keyboard
                        $OneTime: Set true if you want to use the keyboard once
   Return......:		Return custom markup as string, encoded in JSON
#ce ===============================================================================
Func _Telegram_CreateKeyboard(ByRef $Keyboard,$Resize = False,$OneTime = False)
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
EndFunc ;==> _Telegram_CreateKeyboard

#EndRegion

#cs ===============================================================================
   Name .......:    	_Telegram_CreateInlineKeyboard
   Description.:     Create and return a custom inline keyboard markup
   Parameters..:     $Keyboard: an array with the keyboard. Use an empty position for line break.
                            Example: Local $InlineKeyboard[5] = ['Button1_Text','Button1_Data','','Button2_Text','Button2_Data']
   Return......:		Return custom inline markup as string, encoded in JSON
#ce ===============================================================================
Func _Telegram_CreateInlineKeyboard(ByRef $Keyboard)
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

#Region "Internal functions"

Func _Telegram_BuildCommonParams($sChatId = Null, $sParseMode = Null, $sReplyMarkup = Null, $iReplyToMessage = Null, $bDisableNotification = Null, $bDisableWebPreview = Null)
    Local $sParams = ""

    If($sChatId <> Null) Then $sParams = "&chat_id=" & $sChatId
    If($sParseMode <> Null) Then $sParams &= "&parse_mode=" & $sParseMode
    If($sReplyMarkup <> Null) Then $sParams &= "&reply_markup=" & $sReplyMarkup
    If($iReplyToMessage <> Null) Then $sParams &= "&reply_to_message_id=" & $iReplyToMessage
    If($bDisableNotification <> Null) Then $sParams &= "&disable_notification=" & $bDisableNotification
    If($bDisableWebPreview <> Null) Then $sParams &= "&disable_web_page_preview=" & $bDisableWebPreview

    ; Remove the first "&" character
    Return StringTrimLeft($sParams, 1)
EndFunc ;==> _Telegram_BuildCommonParams

#cs ===============================================================================
   Name .......:		_Telegram_UrlEncode
   Description.:     Encode text in url format
   Parameters..:     $string: Text to encode
   Return......:  	Return the encoded string
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

#Region "HTTP Request"
#cs ======================================================================================
    Name .......: _Telegram_API_Call
    Description.: Sends a request to the Telegram API based on provided parameters
    Parameters..:
                    $sURL - URL to the Telegram API
                    $sPath - [optional] Path to the specific API endpoint (Default is "")
                    $sMethod - [optional] HTTP method for the request (Default is "GET")
                    $sParams - [optional] Parameters for the request (Default is "")
                    $vBody - [optional] Body content for the request (Default is Null)
                    $bValidate - [optional] Boolean flag to validate Telegram response (Default is True)
    Return......:
                    Success - A JSON object with the 'result' field upon
                                   successful API call and validation
                    Failure - Null and sets @error flag according to encountered errors
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
Func _Telegram_SendMedia($sChatId, $vMedia, $sMediaType, $sCaption = "", $sParseMode = "", $sReplyMarkup = "", $iReplyToMessage = Null, $bDisableNotification = False, $bValidate = True)
    ; Mandatory inputs validation
    If ($sChatId = "" Or $sChatId = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)
    If ($vMedia = "" Or $vMedia = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)
    If ($sMediaType = "" Or $sMediaType = Null) Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)
    If ($sParseMode <> "" And $sParseMode <> "MarkdownV2" And $sParseMode <> "HTML") Then Return SetError($TG_ERR_BAD_INPUT, 0, Null)

    Local $sParams = _Telegram_BuildCommonParams($sChatId, $sParseMode, $sReplyMarkup, $iReplyToMessage, $bDisableNotification)
    $sParams &= "&caption=" & $sCaption

    Local $hOpen = _WinHttpOpen()
    If (@error) Then Return SetError($TG_ERR_API_CALL, $TG_ERR_API_CALL_OPEN, Null)

    ; Params as query params and media as form data
    $sMediaType = StringLower($sMediaType)
    Local $sForm = _
        "<form action='" & $URL & "/send" & _StringTitleCase(StringReplace($sMediaType, "_", "")) & "?" & $sParams & "' method='POST' enctype='multipart/form-data'>" & _
        "<input type='file' name='" & $sMediaType & "'/></form>"

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

#EndRegion
