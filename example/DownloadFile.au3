#include "../src/Telegram.au3"

$TOKEN  = "" ;Token here
_InitBot($TOKEN)

$FileID = "" ;Send a media to the bot, then catch this id from the $msgData returned by _Polling()
$fileName = __DownloadFile(__GetFilePath($FileID))
If $fileName Then
    MsgBox($MB_ICONINFORMATION,"Telegram Bot","File downloaded: " & $fileName)
Else
    MsgBox($MB_ICONWARNING,"Telegram Bot","Error: check your file ID and your file path.")
Endif
