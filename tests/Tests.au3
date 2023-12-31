#include "../src/Telegram.au3"

Global Const $sValidToken = "" ; TODO: Environment variable or config.ini
Global Const $sInvalidToken = "123456789:ABCDEFGH"
Global Const $sChatId = ""

Func UTAssert(Const $bResult, Const $sMsg = "Assert Failure", Const $iError = @error, Const $iExtended = @extended, Const $iSln = @ScriptLineNumber)
	ConsoleWrite("(" & $iSln & ") " & ($bResult ? "Passed" : "Failed (" & $iError & "/" & $iExtended & ")") & ": " & $sMsg & @LF)
	Return $bResult
EndFunc ;==>UTAssert

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
    UTAssert($bResult = False And @error = $INVALID_TOKEN_ERROR, "Init with invalid token, validate")

    ; Test with empty token without validation
    $bResult = _Telegram_Init("")
    UTAssert($bResult = False And @error = $INVALID_TOKEN_ERROR, "Init with empty token, no validate")

    ; Test with null token without validation
    $bResult = _Telegram_Init(Null)
    UTAssert($bResult = False And @error = $INVALID_TOKEN_ERROR, "Init with null token, no validate")
EndFunc ;==> _Test_Telegram_Init


Func _Test_GetMe()
    ; TODO: A `beforeEach` test that initialize the bot with a valid token should be added
    Local $oMe = _Telegram_GetMe()
    UTAssert(Not @error, "Test_GetMe: no error", @error, @extended)
    UTAssert(Json_IsObject($oMe), "Test_GetMe: is object", @error, @extended)
    UTAssert(Json_Get($oMe, "[is_bot]") = True, "Test_GetMe: is bot", @error, @extended)
    UTAssert(IsInt(Json_Get($oMe, "[id]")), "Test_GetMe: id is int", @error, @extended)
    UTAssert(Json_Get($oMe, "[username]") <> Null, "Test_GetMe: username", @error, @extended)
    UTAssert(Json_Get($oMe, "[first_name]") <> Null, "Test_GetMe: first name", @error, @extended)
EndFunc

Func _Test_SendMessage()
    Local $oMessage = _Telegram_SendMessage($sChatId, "Test message")
    ; TODO: The two following checks should be done in another function
    UTAssert(Not @error, "Test_SendMessage: no error", @error, @extended)
    UTAssert(Json_IsObject($oMessage), "Test_SendMessage: is object", @error, @extended)
    UTAssert(IsInt(Json_Get($oMessage, "[message_id]")), "Test_SendMessage: message id", @error, @extended)

    ; Parse Mode
    $oMessage = _Telegram_SendMessage($sChatId, "*Test* _message_", "Markdown")
    UTAssert(Not @error, "Test_SendMessage: no error", @error, @extended)
    UTAssert(UBound(Json_Get($oMessage, "[entities]")) > 0, "Test_SendMessage: entities", @error, @extended)
EndFunc

Func _Test_ForwardMessage()
    ; Send a message that will be forwarded
    Local $oSentMessage = _Telegram_SendMessage($sChatId, "Test forward message")
    ; Get its message id
    Local $iMessageId = Json_Get($oSentMessage, "[message_id]")

    Local $oForwardedMessage = _Telegram_ForwardMessage($sChatId, $sChatId, $iMessageId)
    UTAssert(Not @error, "Test_ForwardMessage: no error", @error, @extended)
    UTAssert(Json_IsObject($oForwardedMessage), "Test_ForwardMessage: is object", @error, @extended)
    UTAssert(IsInt(Json_Get($oForwardedMessage, "[message_id]")), "Test_ForwardMessage: message id", @error, @extended)

    ; Invalid parameters
    UTAssert(_Telegram_ForwardMessage("123", $sChatId, $iMessageId) = Null And @error = $TG_ERR_BAD_INPUT, "Test_ForwardMessage: invalid chat id", @error, @extended)
    UTAssert(_Telegram_ForwardMessage($sChatId, "123", $iMessageId) = Null And @error = $TG_ERR_BAD_INPUT, "Test_ForwardMessage: invalid from chat id", @error, @extended)
    UTAssert(_Telegram_ForwardMessage($sChatId, $sChatId, 1) = Null And @error = $TG_ERR_BAD_INPUT, "Test_ForwardMessage: invalid message id", @error, @extended)
EndFunc

Func _Test_SendPhoto()
    Local Const $sPhotoPath = "media/image.png"
    Local Const $sPhotoURL = "https://picsum.photos/200"

    ; Send a local photo
    Local $oPhoto = _Telegram_SendPhoto($sChatId, $sPhotoPath)
    UTAssert(Not @error, "Test_SendPhoto: no error", @error, @extended)
    UTAssert(Json_IsObject($oPhoto), "Test_SendPhoto: is object", @error, @extended)
    UTAssert(IsInt(Json_Get($oPhoto, "[message_id]")), "Test_SendPhoto: message id", @error, @extended)

    ; Send a photo by URL (N.B.: This currently not works)
    Local $oPhoto = _SendPhoto($sChatId, $sPhotoURL)
    UTAssert(Not @error, "Test_SendPhoto: no error", @error, @extended)
    UTAssert(Json_IsObject($oPhoto), "Test_SendPhoto: is object", @error, @extended)
    UTAssert(IsInt(Json_Get($oPhoto, "[message_id]")), "Test_SendPhoto: message id", @error, @extended)

EndFunc

; @ TEST RUNNER
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
        ConsoleWrite("Running test: " & $aTestFunctions[$i] & @CRLF)
        Call($aTestFunctions[$i])
    Next
EndFunc

_RunAllTests()
