#include "Telegram.au3"
#include <Array.au3>

ConsoleWrite("Test file for Telegram UDF by LinkOut. (https://github.com/xLinkOut)" & @CRLF & _
             "This file need a valid ChatID of a Telegram User to send messages to, and a valid bot's token given by BotFather.\n" & @CRLF & _
             "Insert this data in the source code" & @CRLF)

Local $ChatID = ''
Local $Token = ''

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
ConsoleWrite("Sending video note..." & _SendVideoNote($ChatID,'C:\video.mp4') & " ...Done!" & @CRLF)

ConsoleWrite("And also, send location and contact:" & @CRLF)
ConsoleWrite("Sending location... " & _SendLocation($ChatID,"74.808889","-42.275391") & "...Done! " & @CRLF)
ConsoleWrite("Sending contact... "& _SendContact($ChatID,"0123456789","Josh","Doe") & "... Done!" @CRLF)

ConsoleWrite("You can send a 'Chat Action', that mean the user see 'Bot is typing...' or 'Bot is sending a photo...'." & @CRLF)
_SendChatAction($ChatID,'typing')

ConsoleWrite("To use the custom keyboard, I wrote an useful function that contruct and encode the keyboard." & _
             "You have to create an array e simply put in the text of your button. To line break, leave an array position empty." & _
             "Example, try to pass this array $keyboard[4] = ['TopLeft','TopRight','','SecondRow'] to the _CreateKeyboard function, then send a message.")

Local $keyboard[4] = ['TopLeft','TopRight','','SecondRow']
Local $markup = _CreateKeyboard($keyboard)
ConsoleWrite("In encoded format, the $keyboard look like " & $markup & @CRLF & _
             "Well, now I'll send this keyboard to you as this: _SendMsg($ChatID,'This is the text',Default,$markup)" & @CRLF)
_SendMsg($ChatID,'This is the text',Default,$markup)
ConsoleWrite("_CreateKeyboard function accept two other boolean args, resize and one time keyboard, both false by default." & @CRLF)

ConsoleWrite("Well.. this is all folks! For the other method read the Telegram Documentation and the Telegram.au3 file, it's commented ;) and see the others example in the folder." & @CRLF)

ConsoleWrite("If you enjoy this UDF, star this repo on GitHub. This mean a lot for me. And if you want to donate me a coffe, there is a PayPal link in the ReadMe, I'll appreciate this. Bye <3")