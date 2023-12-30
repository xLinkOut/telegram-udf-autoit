#include "../src/Telegram.au3"

Global Const $sValidToken = "" ; TODO: Environment variable or config.ini
Global Const $sInvalidToken = "123456789:ABCDEFGH"
Global Const $sChatId = ""

Func UTAssert(Const $bResult, Const $sMsg = "Assert Failure", Const $iError = @error, Const $iExtended = @extended, Const $iSln = @ScriptLineNumber)
	ConsoleWrite("(" & $iSln & ") " & ($bResult ? "Passed" : "Failed (" & $iError & "/" & $iExtended & ")") & ": " & $sMsg & @LF)
	Return $bResult
EndFunc ;==>UTAssert

Func _Test_Init()
    UTAssert(_Telegram_Init($sValidToken) = True, "Test_Init: valid token, no validate", @error)
    UTAssert(_Telegram_Init($sValidToken, True) = True, "Test_Init: valid token, validate", @error)

    UTAssert(_Telegram_Init($sInvalidToken) = True, "Test_Init: invalid token, no validate", @error)
    UTAssert(_Telegram_Init($sInvalidToken, True) = False And @error = $INVALID_TOKEN_ERROR, "Test_Init: invalid token, validate", @error)

    UTAssert(_Telegram_Init("") = False And @error = $INVALID_TOKEN_ERROR, "Test_Init: empty token, no validate", @error)
    UTAssert(_Telegram_Init(Null) = False And @error = $INVALID_TOKEN_ERROR, "Test_Init: null token, no validate", @error)
EndFunc ;==> _Test_Init

Func _Test_GetMe()
    ; TODO: A `beforeEach` test that initialize the bot with a valid token should be added
    Local $oMe = _Telegram_GetMe()
    UTAssert(Not @error, "Test_GetMe: no error", @error)
    UTAssert(Json_IsObject($oMe), "Test_GetMe: is object", @error)
    UTAssert(Json_Get($oMe, "[is_bot]") = True, "Test_GetMe: is bot", @error)
    UTAssert(IsInt(Json_Get($oMe, "[id]")), "Test_GetMe: id is int", @error)
    UTAssert(Json_Get($oMe, "[username]") <> Null, "Test_GetMe: username", @error)
    UTAssert(Json_Get($oMe, "[first_name]") <> Null, "Test_GetMe: first name", @error)
EndFunc

Func _Test_SendMessage()
    Local $oMessage = _Telegram_SendMessage($sChatId, "Test message")
    ; TODO: The two following checks should be done in another function
    UTAssert(Not @error, "Test_SendMessage: no error", @error)
    UTAssert(Json_IsObject($oMessage), "Test_SendMessage: is object", @error)
    UTAssert(IsInt(Json_Get($oMessage, "[message_id]")), "Test_SendMessage: message id", @error)

    ; Parse Mode
    $oMessage = _Telegram_SendMessage($sChatId, "*Test* _message_", "Markdown")
    UTAssert(Not @error, "Test_SendMessage: no error", @error)
    UTAssert(UBound(Json_Get($oMessage, "[entities]")) > 0, "Test_SendMessage: entities", @error)
EndFunc

Func _Test_ForwardMessage()
    ; Send a message that will be forwarded
    Local $oSentMessage = _Telegram_SendMessage($sChatId, "Test forward message")
    ; Get its message id
    Local $iMessageId = Json_Get($oSentMessage, "[message_id]")

    Local $oForwardedMessage = _Telegram_ForwardMessage($sChatId, $sChatId, $iMessageId)
    UTAssert(Not @error, "Test_ForwardMessage: no error", @error)
    UTAssert(Json_IsObject($oForwardedMessage), "Test_ForwardMessage: is object", @error)
    UTAssert(IsInt(Json_Get($oForwardedMessage, "[message_id]")), "Test_ForwardMessage: message id", @error)

    ; Invalid parameters
    UTAssert(_Telegram_ForwardMessage("123", $sChatId, $iMessageId) = Null And @error = $TG_ERR_BAD_INPUT, "Test_ForwardMessage: invalid chat id", @error)
    UTAssert(_Telegram_ForwardMessage($sChatId, "123", $iMessageId) = Null And @error = $TG_ERR_BAD_INPUT, "Test_ForwardMessage: invalid from chat id", @error)
    UTAssert(_Telegram_ForwardMessage($sChatId, $sChatId, 1) = Null And @error = $TG_ERR_BAD_INPUT, "Test_ForwardMessage: invalid message id", @error)
    
EndFunc

; TODO: Test runner
_Test_Init()

_Telegram_Init($sValidToken, True)
If (@error) Then Exit(@error)

_Test_GetMe()
_Test_SendMessage()
_Test_ForwardMessage()
