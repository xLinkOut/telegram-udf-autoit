# Telegram UDF fot AutoIT

If you want to control a Telegram Bot in AutoIT, this UDF is for you! 

## How it work:

1. Download "Telegram UDF.au3";
2. Include it in your main script with: `#include "Telegram UDF.au3";`
3. Initialize your bot **BEFORE** use Telegram function: `_InitBot($BOT_ID,$BOT_TOKEN)` , where:
	* $BOT_ID = 12345678 (ID of your bot)
	* $BOT_TOKEN = AbCdFgH... (Token of your bot));
4. Now you can use all the function provided in the file.

## How to wait for incoming messages:

To wait incoming messages you have to put the bot in Polling State, as this
```autoit
While 1 ;Create a While to restart Polling after processed a message
	$msgData = _Polling() ;_Polling function return an array with info about message
	_SendMsg($msgData[2],$msgData[3]) ;Like Echo, send a message to the same user with the same text (see below)
WEnd
```

The array returned by _Polling function contain:
*	$msgData[0] = Offset of the current update (used to 'switch' to next update)
*	$msgData[1] = Username of the user
*	$msgData[2] = ChatID, use for interact with the user
*	$msgData[3] = Text of the message
	
## Functions:
* **_InitBot:** _Initialize bot;_
* **_Polling:** _Wait for incoming messages;_
* **_GetUpdates:** _Get new messages from Telegram Server;_
* **_GetMe:** _Get information about the bot;_
* **_SendMsg:** _Send simple text message (support Markdown/HTML, Keyboard ecc..);_
* **_ForwardMsg:** _Forward a message from a chat to another;_
.
.
.

