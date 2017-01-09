#include "Telegram UDF.au3"

$ChatID = "Your_Chat_ID_For_Test"
_InitBot("Bot_ID","Bot_Token")

ConsoleWrite("Test _GetUpdates   -> "  & @TAB & _GetUpdates() & @CRLF)
ConsoleWrite("Test _GetMe        -> "  & @TAB & _GetMe() & @CRLF)

ConsoleWrite("Test _SendMsg      -> "  & @TAB & _SendMsg($ChatID,"Test _SendMsg") & @CRLF)
ConsoleWrite("Test _ForwardMsg   -> "  & @TAB & _ForwardMsg($ChatID,$ChatID,'MsgID') & @CRLF)

ConsoleWrite("Test _SendPhoto    -> "  & @TAB & _SendPhoto($ChatID,"C:\image.jpg","Test _SendPhoto") & @CRLF)
ConsoleWrite("Test _SendVideo    -> "  & @TAB & _SendVideo($ChatID,"C:\video.mp4","Test _SendVideo") & @CRLF)
ConsoleWrite("Test _SendAudio    -> "  & @TAB & _SendAudio($ChatID,"C:\audio.mp3","Test _SendAudio") & @CRLF)
ConsoleWrite("Test _SendDocument -> "  & @TAB & _SendDocument($ChatID,"C:\document.txt","Test _SendDocument") & @CRLF)
ConsoleWrite("Test _SendVoice    -> "  & @TAB & _SendVoice($ChatID,"C:\voice.ogg","Test _SendVoice") & @CRLF)
ConsoleWrite("Test _SendSticker  -> "  & @TAB & _SendSticker($ChatID,"C:\sticker.webp") & @CRLF)
ConsoleWrite("Test _SendLocation -> "  & @TAB & _SendLocation($ChatID,"74.808889","-42.275391") & @CRLF)
ConsoleWrite("Test _SendContact  -> "  & @TAB & _SendContact($ChatID,"0123456789","Josh") & @CRLF)
ConsoleWrite("Test _SendChatAction -> " & @TAB & _SendChatAction($ChatID,"typing") & @CRLF)

ConsoleWrite("Test _GetUserProfilePhotos -> " & @TAB & _GetUserProfilePhotos($ChatID) & @CRLF)
ConsoleWrite("Test _GetChat              -> " & @TAB & _GetChat($ChatID) & @CRLF)

While 1
   $msgData = _Polling()
   _SendMsg($msgData[2],$msgData[3])
WEnd