# Telegram UDFs for AutoIt <img src="https://github.com/xLinkOut/telegram-udf-autoit/blob/master/assets/telegram_icon.png" width="28"> <img src="https://github.com/xLinkOut/telegram-udf-autoit/blob/master/assets/autoit_icon.png" width="28">

<p align="center">
  <img src="https://github.com/xLinkOut/telegram-udf-autoit/blob/master/assets/banner.png"><br>
</p>
<p align="center">
<b>If you want to control your Telegram Bot with AutoIt, this is for you!</b><br>
</p>
<p align="center">
  <img src="https://github.com/xLinkOut/telegram-udf-autoit/blob/master/assets/star_icon.png" width="20">
  Telegram UDF is on the official AutoIt Script UDFs list! Check it <a href="https://www.autoitscript.com/wiki/User_Defined_Functions#Social_Media_and_other_Website_API">here!</a></b>
  <img src="https://github.com/xLinkOut/telegram-udf-autoit/blob/master/assets/star_icon.png" width="20">
</p>

## Setup
_Telegram.au3_ is the main file that you have to include in your code, but it also need the _include_ folder. Adjust the path as you want. Include the library in your script with `#include "Telegram.au3"`.
**First** initialize your bot with `_InitBot(12345678:AbCdEfGh....)`, **then** you can use all the bot functions.
Check the _@error_ flag after invoking _\_Initbot()_ (or its return value) to make sure everything is working: `@error == 1` mean error, and in this case the _InitBot() return False.

## How it works
After initializing the bot, you can do whatever you need to do. (Almost) all the APIs are coded, read the wiki for details about all the functions. To put the bot in _polling state_ (i.e. wait for incoming messages) read below.

### How to wait for incoming messages
To wait incoming messages you have to put the bot in Polling State. This state is **blocking**, therefore your script will wait here until it's closed or it exit from the main while, maybe if a certain condition is verified.

#### Example:
```autoit
While 1 ;Create a While that restart Polling
	$msgData = _Polling() ;_Polling function return an array with information about a message
	_SendMsg($msgData[2],$msgData[5]) ;Send a message to the same user with the same text
WEnd
```

For a simple text message, the array returned by _Polling() is:
```
$msgData[0] = Offset of the current update (used to 'switch' to the next update)
$msgData[1] = Message ID
$msgData[2] = Chat ID, use for interact with the user
$msgData[3] = Username of the user
$msgData[4] = First name of the user
$msgData[5] = Text of the message
```

If you want to try all the available features, use the Test file into /tests folder. Open it, insert your bot's token, your chat id **(make sure you have sent at least one message to the bot)** and then execute it.

## What you need to know
I'm writing a wiki, you can find it [here](https://github.com/xLinkOut/telegram-udf-autoit/wiki).

## Todos
- [ ] Complete the test file
- [ ] Add some example file
- [ ] Full message decode support
- [ ] Write all the missing endpoints
- [ ] Write all the missing comments
- [ ] Full Callback support
- [ ] Full Inline support
- [ ] Limit to GetUserProfilePicture
- [ ] Match all functions name to original Endpoint name
- [ ] Check file for \_\_DownloadFile
- [ ] Write. The. WIKI!

### Changelog:
_03/01/2016_ - v1.0 - First Release.

_07/01/2016_ - v1.1 - Added cURL prompt.

_09/01/2016_ - v2.0 - cURL no more needed, functions now use HTTP APIs; fix minor bugs.

_16/10/2017_ - v3.0 - Full rewrite of the code; Finally a JSON Parser; _InitBot require only one string with the token, not ID and Token separatly; Added a Const for line break in message; More internal errors catch; All the functions return array or string of information, not JSON formatted; For custom keyboard use CreareKeybord function that return an already encoded keyboard, then pass it to the send function; Coming CreateInlineKeyboard as well; All function now check if everything is ok by reading the JSON and return false + set @error if not; SendMsg and ForwardMsg return the Message ID; All the Send function support optional param as reply\_markup, reply\_to\_message and disable\_notification; Added SendVenue and SendVideoNote; In-code wiki for SendChatAction; LivePeriod param for SendLocation function; LastName param for SendContact; AnswerCallbackQuery is now available; a lot of new (and also not finished) functions; JSONDecode now is MsgDecode and can return custom array if message came from a private chat, a group chat, from a channel, from an inline query or callback query. Finally, I'm not good with changelog.

## Bots:
If you have made a bot with this UDF, pm me and I'll insert the bot in this list, if you want. 🚀

## Credits:
+ Thanks to dragana-r (trancexx on AutoIt Forum) for [WinHttp UDF](https://github.com/dragana-r/autoit-winhttp)/[Forum thread](https://www.autoitscript.com/forum/topic/84133-winhttp-functions/)
+ Thanks to zserge for [JSON UDF](http://zserge.com/jsmn.html)
+ Thanks to J2TeamM for [JSON/Base64 UDF](https://github.com/J2TeaM/AutoIt-Imgur-UDF/tree/master/include)
+ Thanks to Sergey Flakon for fixing [issue #8](https://github.com/xLinkOut/telegram-udf-autoit/issues/8)

## Legal:
**License: GPL v3.0 ©** : Feel free to use this code and adapt it to your software; just mention this page if you share your software (free or paid).
This code is in no way affiliated with, authorized, maintained, sponsored or endorsed by Telegram and/or AutoIt or any of its affiliates or subsidiaries. This is independent and unofficial. Use at your own risk.

## About:
If you want to donate for support my (future) works, use this: https://www.paypal.me/LCirillo. ❤️

For support, just contact me! Enjoy 🎉