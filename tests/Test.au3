#include "../src/Telegram.au3"
#include <Array.au3>

ConsoleWrite("Test file for Telegram UDF (https://github.com/xLinkOut/telegram-udf-autoit)." & @CRLF & _
             "This file need a valid ChatID of a Telegram user who has already sent at least a message to the bot, and a valid token given by @BotFather." & @CRLF & _
             "Insert this data in the source code." & @CRLF & @CRLF)

Local $ChatID = '' ;Your ChatID here (take this from @MyTelegramID_bot)
Local $Token  = '' ;Token here

If(($ChatID = '') or ($Token = '')) Then
    ConsoleWrite("Warning! ChatID or Token not specified!")
    Exit -1
EndIf

ConsoleWrite("! Initializing bot... " & _InitBot($Token) & @CRLF & @CRLF)

ConsoleWrite("Who am I? ")
Local $myData = _GetMe()
ConsoleWrite("Oh, yeah, my name is " & $myData[2] & ", you can find me at @" & $myData[1] & ". For developers, my Telegram ID is " & $myData[0] & @CRLF)

ConsoleWrite("Let's do some test:" & @CRLF)
ConsoleWrite(@TAB & "Sending a simple text message. The function _SendMsg return the Message ID: ")
$MsgID = _SendMsg($ChatID,"Hi! I'm " & $myData[2] & " :)")
ConsoleWrite($MsgID & @CRLF)
ConsoleWrite(@TAB & "Now I'll forward the same message to you, with the message id saved before: " & _ForwardMsg($ChatID,$ChatID,$MsgID) & @CRLF)
ConsoleWrite(@TAB & "Awesome. Use the other _Send functions to send photos, videos, documents. Each function return the FileID assigned by Telegram." & @CRLF)
ConsoleWrite("!" & @TAB & @TAB & "Sending photo: " & _SendPhoto($ChatID,'media/image.png',"This is a photo.") & @CRLF)
ConsoleWrite("!" & @TAB & @TAB & "Sending video: " & _SendVideo($ChatID,'media/video.mp4',"This is a video.") & @CRLF)
ConsoleWrite("!" & @TAB & @TAB & "Sending audio: " & _SendAudio($ChatID,'media/audio.mp3',"This is an audio.") & @CRLF)
ConsoleWrite("!" & @TAB & @TAB & "Sending documents: " & _SendDocument($ChatID,'media/text.txt',"This is a document.") & @CRLF)
ConsoleWrite("!" & @TAB & @TAB & "Sending voice: " & _SendVoice($ChatID,'media/voice.ogg',"This is a voice.") & @CRLF)
ConsoleWrite("!" & @TAB & @TAB & "Sending sticker: " & _SendSticker($ChatID,'media/sticker.webp') & @CRLF)
ConsoleWrite("!" & @TAB & @TAB & "Sending video note: " & _SendVideoNote($ChatID,'media/video.mp4') & @CRLF)
ConsoleWrite("!" & @TAB & @TAB & "Sending location: " & _SendLocation($ChatID,"74.808889","-42.275391") & @CRLF)
ConsoleWrite("!" & @TAB & @TAB & "Sending contact: " & _SendContact($ChatID,"0123456789","John","Doe") & @CRLF & @CRLF)

ConsoleWrite("You can send a 'Chat Action', that mean the user see 'Bot is typing...' or 'Bot is sending a photo...'." & @CRLF & @CRLF)
_SendChatAction($ChatID,'typing')

ConsoleWrite("To use a custom keyboard, there is an useful function that contruct and encode the keyboard itself." & @CRLF & _
             "You have to create an array and insert the text of your buttons. To line break, leave a position empty. " & @CRLF & _
             "Example, try to pass this array $keyboard[4] = ['TopLeft','TopRight','','SecondRow'] to the _CreateKeyboard function, then send the message." & @CRLF & @CRLF)

Local $keyboard[4] = ['TopLeft','TopRight','','SecondRow']
Local $markup = _CreateKeyboard($keyboard)
ConsoleWrite("In encoded format, the $keyboard look like " & $markup & @CRLF & _
             "I'll send this keyboard to you as this: _SendMsg($ChatID,'Hey! Choose one:',Default,$markup)" & @CRLF)
_SendMsg($ChatID,'Hey! Choose one:',Default,$markup)
ConsoleWrite("_CreateKeyboard function accept two other boolean args, resize and one time keyboard, both false by default." & @CRLF & @CRLF)

ConsoleWrite("This is all folks! For all the other methods read the Telegram Documentation and the Telegram.au3 file, it's commented. You can find some examples in the example folder." & @CRLF)
ConsoleWrite("Don't forget to ì star this repo on GitHub, this mean a lot for me.")