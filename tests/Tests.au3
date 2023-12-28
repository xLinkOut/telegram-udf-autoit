#include "../src/Telegram.au3"

Func UTAssert(Const $bResult, Const $sMsg = "Assert Failure", Const $iError = @error, Const $iSln = @ScriptLineNumber)
	ConsoleWrite("(" & $iSln & ") " & ($bResult ? "Passed" : "Failed (" & $iError & ")") & ": " & $sMsg & @LF)
	Return $bResult
EndFunc ;==>UTAssert

Func _Test_Init()
    Local Const $sValidToken = "[redacted]" ; TODO: Environment variable or config.ini
    Local Const $sInvalidToken = "123456789:ABCDEFGH"

    UTAssert(_Telegram_Init($sValidToken) = True, "Test_Init: valid token, no validate", @error)
    UTAssert(_Telegram_Init($sValidToken, True) = True, "Test_Init: valid token, validate", @error)

    UTAssert(_Telegram_Init($sInvalidToken) = True, "Test_Init: invalid token, no validate", @error)
    UTAssert(_Telegram_Init($sInvalidToken, True) = False And @error = $INVALID_TOKEN_ERROR, "Test_Init: invalid token, validate", @error)

    UTAssert(_Telegram_Init("") = False And @error = $INVALID_TOKEN_ERROR, "Test_Init: empty token, no validate", @error)
    UTAssert(_Telegram_Init(Null) = False And @error = $INVALID_TOKEN_ERROR, "Test_Init: null token, no validate", @error)
EndFunc ;==> _Test_Init

; TODO: Test runner
_Test_Init()
