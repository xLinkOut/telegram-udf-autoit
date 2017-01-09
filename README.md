# Telegram UDF fot AutoIT <img src="https://s30.postimg.org/h95ulyoap/telegram_icon.png" width="28"> <img src="https://s27.postimg.org/3oe3w5l4j/autoit_icon.png" width="28">

<img src="https://s27.postimg.org/8nstpg3v7/Def_Banner.png">

> If you want to control your Telegram Bot with AutoIT, this UDF is for you! 

## How it work:

1. Download "Telegram UDF.au3";
2. Include it in your main script: `#include "Telegram UDF.au3";`
3. Initialize your bot **before** use other function: `_InitBot(12345...,AbCdEfGh....)`
4. Now you can use all the functions provided in the file.

### How to wait for incoming messages:

To wait incoming messages you have to put the bot in Polling State, as this

```autoit
While 1 ;Create a While to restart Polling after processed a message
	$msgData = _Polling() ;_Polling function return an array with info about message
	_SendMsg($msgData[2],$msgData[3]) ;Send a message to the same user with the same text
WEnd
```

The array returned by _Polling function contain:
*	$msgData[0] = Offset of the current update (used to 'switch' to next update)
*	$msgData[1] = Username of the user
*	$msgData[2] = ChatID, use for interact with the user
*	$msgData[3] = Text of the message
	
## Functions:
* **_InitBot:** _Initialize bot (require BotID and BotTOKEN);_
* **_Polling:** _Wait for incoming messages;_
* **_GetUpdates:** _Get new messages from Telegram Server (Return a string);_
* **_GetMe:** _Get information about the bot (Return a string);_
* **_SendMsg:** _Send simple text message (support Markdown/HTML, Keyboard ecc...)(Return True);_
* **_ForwardMsg:** _Forward a message from a chat to another(Return True);_
* **_SendPhoto:** _Send a photo to a specific chat (Return file ID);_
* **_SendVideo:** _Send a video to a specific chat (Return file ID);_
* **_SendAudio:** _Send an audio to a specific chat (Return file ID);_
* **_SendDocument:** _Send a document to a specific chat (Return file ID);_
* **_SendVoice:** _Send a voice to a specific chat (Return file ID);_
* **_SendSticker:** _Send a sticker to a specific chat (Return file ID);_
* **_SendChatAction:** _Set the 'Chat Action' for 5 seconds (Typing, Sending photo...)(Return True);_
* **_SendLocation:** _Send a location (Return True);_
* **_SendContact:** _Send a contact with Phone and First Name (Return True);_
* **_GetUserProfilePhotos:** _Get the user profile pictures (Return an Array with the FileID of each photo);_
* **_GetChat:** _Get information about specific chat (Return a string with info);_
* **_GetFileID:** _Get FileID of a the file uploaded(Return a string);_
* **_GetFilePath:** _Get the path of a specific file, require file ID (Return a string);_
* **_DownloadFile:** _Download a file from the server, require file path (Return True);_
* **_JSONDecode:** _Decode incoming message (Return an array with some information like chat ID ecc);_
* **HttpPost and HttpGet:** _Helpful function to perform Get and Post request;_

### Changelog:
03/01/2016 - v1.0 - First Release.  
07/01/2016 - v1.1 - Added cURL prompt.  
09/01/2016 - v2.0 - cURL no more needed, functions now use http api; fix minor bugs.

### Credits:
Thanks to dragana-r (trancexx on AutoIT Forum) for WinHttp UDF:  
	https://www.autoitscript.com/forum/topic/84133-winhttp-functions/  
	https://github.com/dragana-r/autoit-winhttp

### Legal:
**License: GPL v3.0 ©** : Feel free to use this code and adapt it to your software; just mention this page if you share your software (free or paid).  
This code is in no way affiliated with, authorized, maintained, sponsored or endorsed by Telegram and/or AutoIT or any of its affiliates or subsidiaries. This is independent and unofficial. Use at your own risk.

### About:
If you want to donate for support my (future) works, use this: https://www.paypal.me/LCirillo  
I'll appreciate. Also, names of those who donated will be written in an **'Awesome list'** (if you agree).

For support, just contact me! Enjoy 🎉