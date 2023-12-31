#include "../src/Telegram.au3"

Global Const $sValidToken = "" ; TODO: Environment variable or config.ini
Global Const $sInvalidToken = "123456789:ABCDEFGH"
Global Const $sChatId = ""

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
    Json_Dump(Json_Encode($oMessage))
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
    ; Send a message that will be forwarded
    Local $oSentMessage = _Telegram_SendMessage($sChatId, "Test forward message")
    ; Get its message id
    Local $iMessageId = Json_Get($oSentMessage, "[message_id]")

    Local $oForwardedMessage = _Telegram_ForwardMessage($sChatId, $sChatId, $iMessageId)
    UTAssert(Not @error, "Test_ForwardMessage: no error")
    UTAssert(Json_IsObject($oForwardedMessage), "Test_ForwardMessage: is object")
    UTAssert(IsInt(Json_Get($oForwardedMessage, "[message_id]")), "Test_ForwardMessage: message id")

    ; Invalid parameters
    UTAssert(_Telegram_ForwardMessage("123", $sChatId, $iMessageId) = Null And @error = $TG_ERR_BAD_INPUT, "Test_ForwardMessage: invalid chat id")
    UTAssert(_Telegram_ForwardMessage($sChatId, "123", $iMessageId) = Null And @error = $TG_ERR_BAD_INPUT, "Test_ForwardMessage: invalid from chat id")
    UTAssert(_Telegram_ForwardMessage($sChatId, $sChatId, 1) = Null And @error = $TG_ERR_BAD_INPUT, "Test_ForwardMessage: invalid message id")
EndFunc

Func _Test_Telegram_SendPhoto()
    Local Const $sPhotoPath = "media/image.png"
    Local Const $sPhotoURL = "https://picsum.photos/200"

    ; Send a local photo
    Local $oPhoto = _Telegram_SendPhoto($sChatId, $sPhotoPath)
    UTAssert(Not @error, "Test_SendPhoto: no error")
    UTAssert(Json_IsObject($oPhoto), "Test_SendPhoto: is object")
    UTAssert(IsInt(Json_Get($oPhoto, "[message_id]")), "Test_SendPhoto: message id")

    ; Send a photo by URL (N.B.: This currently not works)
    Local $oPhoto = _Telegram_SendPhoto($sChatId, $sPhotoURL)
    UTAssert(Not @error, "Test_SendPhoto: no error")
    UTAssert(Json_IsObject($oPhoto), "Test_SendPhoto: is object")
    UTAssert(IsInt(Json_Get($oPhoto, "[message_id]")), "Test_SendPhoto: message id")
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

;_RunAllTests()
_Telegram_Init($sValidToken)
_Test_Telegram_SendMessage()