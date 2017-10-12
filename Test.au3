#include "Telegram.au3"
#include <Array.au3>

ConsoleWrite("Test file for Telegram UDF by LinkOut. (https://github.com/xLinkOut)" & @CRLF & _
             "This file need a valid ChatID of a Telegram User to send messages to, and a valid bot's token given by BotFather.\n" & @CRLF & _
             "Insert this data in the source code" & @CRLF)

Local $ChatID = '89966355'
Local $Token = '298715981:AAETeK8Lt-dYg76Qy-VAX_KLXnqQnKY8TyQ'

If(($ChatID = '') or ($Token = '')) Then
    ConsoleWrite("Warning! ChatID or Token not specified!")
    Exit -1
EndIf

ConsoleWrite("Initializing bot... " & _InitBot($Token) & " ...Done!" & @CRLF)

ConsoleWrite("Who am I? Well..." & @CRLF)
Local $myData = _GetMe()
ConsoleWrite("Oh, yeah, my name is " & $myData[2] & ", you can find me at @" & $myData[1] & ". For developers, my Telegram ID is " & $myData[0] & ". That's it!" & @CRLF)

ConsoleWrite("Let's do some test:" & @CRLF)
ConsoleWrite("Sending a simple text message. The function _SendMsg return the Message ID: ")
$MsgID = _SendMsg($ChatID,"Hi! I'm " & $myData[2] & " :)")
ConsoleWrite($MsgID & @CRLF)
ConsoleWrite("Now I'll forward the same message to you, with the message id saved before.")
_ForwardMsg($ChatID,$ChatID,$MsgID)
ConsoleWrite("Awesome. Now use the other _Send function to send photos, videos, documents and other. Each of this function return the FileID assigned by Telegram." & @CRLF)
ConsoleWrite("Sending photo..." & _SendPhoto($ChatID,'C:\image.jpg',"This is a photo.") & " ...Done!" & @CRLF)
ConsoleWrite("Sending video..." & _SendVideo($ChatID,'C:\video.mp4',"This is a video.") & " ...Done!" & @CRLF)
ConsoleWrite("Sending audio..." & _SendVideo($ChatID,'C:\audio.mp3',"This is an audio.") & " ...Done!" & @CRLF)
ConsoleWrite("Sending documents..." & _SendDocument($ChatID,'C:\text.txt',"This is a document.") & " ...Done!" & @CRLF)
ConsoleWrite("Sending voice..." & _SendVoice($ChatID,'C:\voice.ogg',"This is a voice.") & " ...Done!" & @CRLF)
ConsoleWrite("Sending sticker..." & _SendSticker($ChatID,'C:\sticker.webp',"This is a voice.") & " ...Done!" & @CRLF)

ConsoleWrite("You can send a 'Chat Action', that mean the user see 'Bot is typing...' or 'Bot is sending a photo...'." & @CRLF)
_SendChatAction($ChatID,'typing')

ConsoleWrite("And also, send location and contact:" & @CRLF)
ConsoleWrite("Sending location... " & _SendLocation($ChatID,"74.808889","-42.275391") & "...Done! " & @CRLF)
ConsoleWrite("Sending contact... "& _SendContact($ChatID,"0123456789","Josh") & "... Done!" @CRLF)
;ConsoleWrite(_GetFilePath('AgADBAADBqoxG23F8FIpebM6YBBqcio-9RkABJXMl3YNNMAIbh4BAAEC'))

;reply_markup={"keyboard":[["Yes","No"],["Maybe"],["1","2","3"]],"one_time_keyboard":true}
;_SendMsg(89966355,"Ciao",Default,'{"keyboard":[["Yes","No"],["Maybe"],["1","2","3"]]}',True,True)
;_ForwardMsg($ChatID,$ChatID,10729,True)
;ConsoleWrite("Test _GetMe        -> "  & @TAB & _ArrayToString(_GetMe()) & @CRLF)
#cs
ConsoleWrite("Test _GetUpdates   -> "  & @TAB & _GetUpdates() & @CRLF)

ConsoleWrite("Test _SendMsg      -> "  & @TAB & _SendMsg($ChatID,"Test _SendMsg") & @CRLF)
ConsoleWrite("Test _ForwardMsg   -> "  & @TAB & _ForwardMsg($ChatID,$ChatID,'MsgID') & @CRLF)

ConsoleWrite("Test _GetUserProfilePhotos -> " & @TAB & _GetUserProfilePhotos($ChatID) & @CRLF)
ConsoleWrite("Test _GetChat              -> " & @TAB & _GetChat($ChatID) & @CRLF)

While 1
   $msgData = _Polling()
   _SendMsg($msgData[2],$msgData[3])
WEnd
#ce

Local $Kb[7] = ["ciao","come","","stai","bene","","si"]
Local $markup = _CreateKeyboard($Kb,True,False)
ConsoleWrite($markup)
_SendMsg($ChatID,'ciao',Default,$markup)