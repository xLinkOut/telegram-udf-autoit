#include "../src/Telegram.au3"

Const $sConfigFilePath = @ScriptDir & "\config.ini"
ConsoleWrite("Using config file located at " & $sConfigFilePath & @CRLF)

Global Const $sValidToken = IniRead($sConfigFilePath, "Init", "ValidToken", "")
Global Const $sInvalidToken = IniRead($sConfigFilePath, "Init", "InvalidToken", "")
Global Const $sChatId = IniRead($sConfigFilePath, "Init", "ChatId", "")

; Check if the config file read was successful
If @error Then
    ConsoleWrite("An error occurred while reading the config file" & @CRLF)
    Exit 1
EndIf

; Check if the config file is missing required parameters
If $sValidToken = "" Or $sChatId = "" Then
    ConsoleWrite("The config file is missing required parameters" & @CRLF)
    Exit 2
EndIf

Func UTAssert(Const $bResult, Const $sMsg = "Assert Failure", Const $iError = @error, Const $iExtended = @extended, Const $iSln = @ScriptLineNumber)
	ConsoleWrite("(" & $iSln & ") " & ($bResult ? "Passed" : "Failed (" & $iError & "/" & $iExtended & ")") & ": " & $sMsg & @LF)
	Return $bResult
EndFunc ;==>UTAssert

Func _Validate_Telegram_Response($oResponse, Const $iError = @error)
    Return (Not @error And $oResponse <> Null And Json_IsObject($oResponse))
EndFunc

Func _Test_Telegram_Init()
    Local $bResult

    ; Test with valid token without validation
    $bResult = _Telegram_Init($sValidToken)
    UTAssert($bResult = True, "Init with valid token, no validate")

    ; Test with valid token with validation
    $bResult = _Telegram_Init($sValidToken, True)
    UTAssert($bResult = True, "Init with valid token, validate")

    ; Test with invalid token without validation
    $bResult = _Telegram_Init($sInvalidToken)
    UTAssert($bResult = True, "Init with invalid token, no validate")

    ; Test with invalid token with validation
    $bResult = _Telegram_Init($sInvalidToken, True)
    UTAssert($bResult = False And @error = $TG_ERR_INIT, "Init with invalid token, validate")

    ; Test with empty token without validation
    $bResult = _Telegram_Init("")
    UTAssert($bResult = False And @error = $TG_ERR_INIT, "Init with empty token, no validate")

    ; Test with null token without validation
    $bResult = _Telegram_Init(Null)
    UTAssert($bResult = False And @error = $TG_ERR_INIT, "Init with null token, no validate")
EndFunc ;==> _Test_Telegram_Init

Func _Test_Telegram_GetMe()
    ; Get information about the bot
    Local $oMe = _Telegram_GetMe()

    ; Test if there are no errors during the call
    UTAssert(_Validate_Telegram_Response($oMe), "Test_GetMe: Validate Telegram response")

    ; Test if the 'is_bot' field is set to true
    UTAssert(Json_Get($oMe, "[is_bot]") = True, "Test_GetMe: Bot status is 'is_bot'")

    ; Test if the 'id' field is an integer value
    UTAssert(IsInt(Json_Get($oMe, "[id]")), "Test_GetMe: 'id' field is an integer")

    ; Test if the 'username' field is not empty
    UTAssert(Json_Get($oMe, "[username]") <> Null, "Test_GetMe: 'username' field is not empty")

    ; Test if the 'first_name' field is not empty
    UTAssert(Json_Get($oMe, "[first_name]") <> Null, "Test_GetMe: 'first_name' field is not empty")
EndFunc ;==> _Test_Telegram_GetMe

Func _Test_Telegram_SendMessage()
    ; Test if the message is successfully sent
    Local $oMessage = _Telegram_SendMessage($sChatId, "Test message")
    UTAssert(_Validate_Telegram_Response($oMessage), "Test_SendMessage: valid response")
    UTAssert(IsInt(Json_Get($oMessage, "[message_id]")), "Test_SendMessage: message id")

    ; Test with Parse Mode
    $oMessage = _Telegram_SendMessage($sChatId, "*Test* _message_", "MarkdownV2")
    UTAssert(_Validate_Telegram_Response($oMessage), "Test_SendMessage: valid response with Parse Mode")
    UTAssert(UBound(Json_Get($oMessage, "[entities]")) = 2, "Test_SendMessage: entities")

    ; Test with Keyboard Markup
    Local $sKeyboardMarkup = '{"keyboard":[["Button 1"],["Button 2"]],"one_time_keyboard":true}'
    $oMessage = _Telegram_SendMessage($sChatId, "Test with Keyboard Markup", Null, $sKeyboardMarkup)
    UTAssert(_Validate_Telegram_Response($oMessage), "Test_SendMessage: valid response with Keyboard Markup")

    ; Test with Inline Keyboard Markup
    Local $sInlineKeyboardMarkup = '{"inline_keyboard":[[{"text":"Button 1","callback_data":"data_1"}],[{"text":"Button 2","callback_data":"data_2"}]]}'
    $oMessage = _Telegram_SendMessage($sChatId, "Test with Inline Keyboard Markup", Null, $sInlineKeyboardMarkup)
    UTAssert(_Validate_Telegram_Response($oMessage), "Test_SendMessage: valid response with Inline Keyboard Markup")

    ; Test with Reply To Message
    Local $iPreviousMesssageId = Json_Get($oMessage, "[message_id]")
    $oMessage = _Telegram_SendMessage($sChatId, "Test with Reply To Message", Null, Null, $iPreviousMesssageId)
    UTAssert(_Validate_Telegram_Response($oMessage), "Test_SendMessage: valid response with Reply To Message")

    ; Test with Disable Web Preview
    $oMessage = _Telegram_SendMessage($sChatId, "Test with Disable Web Preview (https://github.com)", Null, Null, Null, True)
    UTAssert(_Validate_Telegram_Response($oMessage), "Test_SendMessage: valid response with Disable Web Preview")

    ; Test with Disable Notification
    $oMessage = _Telegram_SendMessage($sChatId, "Test with Disable Notification", Null, Null, Null, False, True)
    UTAssert(_Validate_Telegram_Response($oMessage), "Test_SendMessage: valid response with Disable Notification")
EndFunc ;==> _Test_Telegram_SendMessage

Func _Test_Telegram_ForwardMessage()
    ; Sending a test message
    Local $oMessage = _Telegram_SendMessage($sChatId, "Test message for forwarding")
    ; Check if message was sent successfully
    UTAssert(_Validate_Telegram_Response($oMessage), "Test_ForwardMessage: Sent message successfully")
    ; Forwarding the sent message
    Local $oForwardedMessage = _Telegram_ForwardMessage($sChatId, $sChatId, Json_Get($oMessage, "[message_id]"))
    ; Check if message was forwarded successfully
    UTAssert(_Validate_Telegram_Response($oForwardedMessage), "Test_ForwardMessage: Forwarded message successfully")
EndFunc

Func _Test_Telegram_SendPhoto()
    Local Const $sLocalMedia = "media/image.png"
    Local Const $sRemoteMedia = "https://picsum.photos/200"

    ; Sending a local photo
    Local $oLocalPhotoMessage = _Telegram_SendPhoto($sChatId, $sLocalMedia, "Test caption")
    ; Check if the local photo was sent successfully
    UTAssert(_Validate_Telegram_Response($oLocalPhotoMessage), "Test_SendPhoto: Sent local photo successfully")

    ; Sending a photo from a URL
    Local $oRemotePhotoMessage = _Telegram_SendPhoto($sChatId, $sRemoteMedia, "Test caption")
    ; Check if the photo from URL was sent successfully
    UTAssert(_Validate_Telegram_Response($oRemotePhotoMessage), "Test_SendPhoto: Sent photo from URL successfully")

    ; Get File ID of the last sent photo
    Local $sFileID = Json_Get($oLocalPhotoMessage, "[photo][0][file_id]")
    ; Resend the photo using the File ID
    Local $oRecentPhotoMessage = _Telegram_SendPhoto($sChatId, $sFileID, "Test caption")
    ; Check if the photo sent via File ID was successful
    UTAssert(_Validate_Telegram_Response($oRecentPhotoMessage), "Test_SendPhoto: Sent photo via File ID successfully")
EndFunc

Func _Test_SendVenue()
    Local Const $fLatitude = 40.7128
    Local Const $fLongitude = -74.0060
    Local Const $sTitle = "Central Park"
    Local Const $sAddress = "New York City, NY, USA"

    Local $oResponse = _Telegram_SendVenue($sChatId, $fLatitude, $fLongitude, $sTitle, $sAddress)
    
    UTAssert(_Validate_Telegram_Response($oResponse), "Test_SendVenue: Sending venue")
EndFunc

Func _Test_SendContact()
    Const $sPhoneNumber = "123456789"
    Const $sFirstName = "John"
    Const $sLastName = "Doe"

    Local $oResponse = _Telegram_SendContact($sChatId, $sPhoneNumber, $sFirstName, $sLastName)
    
    UTAssert(_Validate_Telegram_Response($oResponse), "Test_SendContact: Sending contact")
EndFunc

Func _Test_SendChatAction()
    Const $sTestAction = "typing"

    UTAssert(_Validate_Telegram_Response(_Telegram_SendChatAction($sChatId, $sTestAction)), "Test_SendChatAction: sending action")
    UTAssert(_Telegram_SendChatAction("", $sTestAction) = Null And @error = $TG_ERR_BAD_INPUT, "Test_SendChatAction: empty chat ID")
    UTAssert(_Telegram_SendChatAction($sChatId, "") = Null And @error = $TG_ERR_BAD_INPUT, "Test_SendChatAction: empty action")
    
    ; Invalid action
    UTAssert(_Telegram_SendChatAction($sChatId, "invalid_action") = Null And @error = $TG_ERR_BAD_INPUT, "Test_SendChatAction: invalid action")
EndFunc ;==> _Test_SendChatAction

Func _Test_GetChat()
    ; Valid parameters
    UTAssert(_Telegram_GetChat($sChatId), "Test_GetChat: valid parameters")
    
    ; Invalid parameters
    UTAssert(Not _Telegram_GetChat(""), "Test_GetChat: empty chat ID")
EndFunc

Func _Test_DeleteMessage()
    Local $sText = "Test message for deletion"

    ; Sending a test message to be deleted
    Local $oMessage = _Telegram_SendMessage($sChatId, $sText)
    UTAssert(Not @error, "Test_DeleteMessage: message sent successfully")
    Local $iMessageId = Json_Get($oMessage, "[message_id]")

    ; Deleting the sent message
    Local $oResponse = _Telegram_DeleteMessage($sChatId, $iMessageId)
    UTAssert(Not @error, "Test_DeleteMessage: message deleted successfully")
EndFunc

#Region "Test runner"
#cs ======================================================================================
    Name .........: __GetTestFunctions
    Description...: Retrieves the names of the test functions present in the current script.
    Syntax .......: __GetTestFunctions()
    Parameters....: None
    Return values.:
                    Success - Returns an array containing the names of test functions
                              based on the specified prefix.
                    Failure - Returns an empty array if no test functions are found.
#ce ======================================================================================
Func __GetTestFunctions()
    Local $sTestPrefix = "_Test_"
    Local $aFunctions = StringRegExp(FileRead(@ScriptFullPath), "(?i)(?s)Func\s+" & $sTestPrefix &"(\w+)\s*\(", 3)

    For $i = 0 To UBound($aFunctions) - 1
        $aFunctions[$i] = $sTestPrefix & $aFunctions[$i]
    Next

    Return $aFunctions
EndFunc

#cs ======================================================================================
    Name .........: _RunAllTests
    Description...: Executes all test functions found in the current script.
    Syntax .......: _RunAllTests()
    Parameters....: None
    Return values.:
                    Success - Executes all test functions present in the script.
                    Failure - None.
#ce ======================================================================================
Func _RunAllTests()
    Local $aTestFunctions = __GetTestFunctions()
    For $i = 0 To UBound($aTestFunctions) - 1
        ; Like a beforeEach, initialize the bot with a valid token
        _Telegram_Init($sValidToken)
        ; Execute the test
        Call($aTestFunctions[$i])
    Next
EndFunc
#EndRegion

_RunAllTests()

; Here for debug purposes (run tests manually)
;_Telegram_Init($sValidToken)
;_Test_Telegram_SendPhoto()
