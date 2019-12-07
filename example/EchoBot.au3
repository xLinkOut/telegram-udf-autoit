#include "../src/Telegram.au3"

HotKeySet("{PAUSE}","_Exit") ;Press 'PAUSE' on your keyboard to force-exit the script

$Token = "" ;Token here
_InitBot($Token)

While 1
    $msgData = _Polling()
    ConsoleWrite("Incoming message from " & $msgData[3] & ": " & $msgData[5] & @CRLF)
    _SendMsg($msgData[2],$msgData[5])
WEnd

Func _Exit()
    Exit 0
EndFunc