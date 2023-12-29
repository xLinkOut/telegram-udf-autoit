#include "../src/Telegram.au3"

Global Const $sValidToken = "[redacted]" ; TODO: Environment variable or config.ini
Global Const $sInvalidToken = "123456789:ABCDEFGH"

Func UTAssert(Const $bResult, Const $sMsg = "Assert Failure", Const $iError = @error, Const $iSln = @ScriptLineNumber)
	ConsoleWrite("(" & $iSln & ") " & ($bResult ? "Passed" : "Failed (" & $iError & ")") & ": " & $sMsg & @LF)
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

; TODO: Test runner
;_Test_Init()
_Telegram_Init($sValidToken, True)
If (@error) Then Exit(@error)

_Test_GetMe()
