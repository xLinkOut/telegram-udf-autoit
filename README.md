# Telegram UDF for AutoIt <img src="https://s30.postimg.org/h95ulyoap/telegram_icon.png" width="28"> <img src="https://s27.postimg.org/3oe3w5l4j/autoit_icon.png" width="28">

<p align="center">
  <img src="https://s27.postimg.org/8nstpg3v7/Def_Banner.png"><br>
</p>
<p align="center">
<b>If you want to control your Telegram Bot with AutoIt, this is for you!</b><br>
</p>
<p align="center">
  <img src="http://icons.iconarchive.com/icons/paomedia/small-n-flat/1024/star-icon.png" width="20">
  Telegram UDF is on the official AutoIt Script UDFs list! Check it <a href="https://www.autoitscript.com/wiki/User_Defined_Functions#Social_Media_and_other_Website_API">here!</a></b>
  <img src="http://icons.iconarchive.com/icons/paomedia/small-n-flat/1024/star-icon.png" width="20">
</p>

## Setup:

1. _Telegram.au3_ is the main file that you have to include in your project, but it also need the _include_ folder. Adjust the path as you want.
2. Include it in your script: `#include "Telegram.au3"`
3. **First**, initialize your bot: `_InitBot(12345678:AbCdEfGh....)`
4. **Then** you can use all the bot functions.

## How it works:
After initializing the bot, you can do whatever you need to do. (Almost) all the API are coded, read the wiki for details about all the functions. To put the bot in _Polling state_ (mean a blocking function that wait for incoming messages) read below.

### How to wait for incoming messages:

To wait incoming messages you have to put the bot in Polling State. This state is **blocking**, therefore your script wait here until it's closed or it exit from the while, maybe if a certain condition is verified.

A basic example:

```autoit
While 1 ;Create a While that restart Polling
	$msgData = _Polling() ;_Polling function return an array with information about a message
	_SendMsg($msgData[2],$msgData[5]) ;Send a message to the same user with the same text
WEnd
```
For a simple text message, the array returned by _Polling() is:
*	$msgData[0] = Offset of the current update (used to 'switch' to next update)
*	$msgData[1] = Message ID
*	$msgData[2] = Chat ID, use for interact with the user
*	$msgData[3] = Username of the user
*	$msgData[4] = First name of the user
*	$msgData[5] = Text of the message
	
## What you need to know:
I'm writing a wiki, you can find it [here](https://github.com/xLinkOut/telegram-udf-autoit/wiki).

## To Do:

- [ ] Complete the test file
- [ ] Add some example file
- [ ] Full message decode support
- [ ] Write all the missing endpoints
- [ ] Write all the missing comments
- [x] CreateInlineKeyboard function
- [ ] Full Callback support
- [ ] Full Inline support
- [ ] Limit to GetUserProfilePicture
- [ ] Match all functions name to original Endpoint name
- [ ] Check file for \_\_DownloadFile
- [ ] Write. The. WIKI!

### Changelog:
_03/01/2016_ - v1.0 - First Release.

_07/01/2016_ - v1.1 - Added cURL prompt.

_09/01/2016_ - v2.0 - cURL no more needed, functions now use http api; fix minor bugs.

_16/10/2017_ - v3.0 - Well, a lot of things: Full rewrite of the code; Finally a JSON Parser; _InitBot require only one string with the token, not ID and Token separatly; Added a Const for line break in message; More internal errors catch; All the functions return array or string of information, not JSON formatted; For custom keyboard use CreareKeybord function that return an already encoded keyboard, then pass it to the send function; Coming CreateInlineKeyboard as well; All function now check if everything is ok by reading the JSON and return false + set @error if not; SendMsg and ForwardMsg return the Message ID; All the Send function support optional param as reply\_markup, reply\_to\_message and disable\_notification; Added SendVenue and SendVideoNote; In-code wiki for SendChatAction; LivePeriod param for SendLocation function; LastName param for SendContact; AnswerCallbackQuery is now available; a lot of new (and also not finished) functions; JSONDecode now is MsgDecode and can return custom array if message came from a private chat, a group chat, from a channel, from an inline query or callback query. Finally, I'm not good with changelog.


### Credits:
Thanks to dragana-r (trancexx on AutoIt Forum) for WinHttp UDF: https://www.autoitscript.com/forum/topic/84133-winhttp-functions/ and https://github.com/dragana-r/autoit-winhttp

Thanks to zserge for JSON UDF: http://zserge.com/jsmn.html

Thanks to J2TeamM: https://github.com/J2TeaM/AutoIt-Imgur-UDF/tree/master/include


### Bots:
If you have made a bot with this UDF, pm me and I'll insert the bot in this list, if you want. 🚀

### Legal:
**License: GPL v3.0 ©** : Feel free to use this code and adapt it to your software; just mention this page if you share your software (free or paid).  
This code is in no way affiliated with, authorized, maintained, sponsored or endorsed by Telegram and/or AutoIt or any of its affiliates or subsidiaries. This is independent and unofficial. Use at your own risk.

### About:
If you want to donate for support my (future) works, use this: https://www.paypal.me/LCirillo  
I'll appreciate. Also, names of those who donated will be written in an **'Awesome list'** (if you agree).

For support, just contact me! Enjoy 🎉
