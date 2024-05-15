# Telegram UDFs for AutoIt
A collection of user defined functions to seamlessly control your Telegram Bot with AutoIt.
It support [most](https://github.com/xLinkOut/telegram-udf-autoit/wiki/Supported-APIs) of the Telegram Bot API and offer a whole set of useful features to interact with them.

> [!NOTE]
> This library is listed in the official [AutoIt Script Wiki!](https://www.autoitscript.com/wiki/User_Defined_Functions#Social_Media_and_other_Website_API). Also, refer to the [original forum topic](https://www.autoitscript.com/forum/topic/186381-telegram-bot-udf/) for more details.

> [!IMPORTANT]  
> I've rewritten the library code from scratch after years of inactivity. The aim is to update, optimize it, fix all reported issues accumulated over the years, and support the latest Telegram features. It's still in work in progress and, obviously, there are breaking changes. You can find the development in the dev branch; I appreciate any kind of contribution. Also, in the release section, you can find the previous version for backward compatibility. Thank you for the support!

## How to use
The library itself is in the `src/Telegram.au3` file. It need all the dependencies in the `src/include` folder: [WinHttp](https://www.autoitscript.com/forum/topic/84133-winhttp-functions/), [JSON](https://www.autoitscript.com/forum/topic/148114-a-non-strict-json-udf-jsmn).

First, include the library in your script with `#include "path/to/Telegram.au3"`. Then, you can initialize the bot with the `_Telegram_Init` function: it take the bot token as first parameter (given to you by BotFather), and a boolean that validate the token as second parameter. I recommend to always validate your token, so the script fail immediately if it is invalid.
The function return True if everything is ok, or False otherwise, and set `@error` and `@extended` accordingly.

After this initialization step, you can use all the other functions. Refer to the [wiki](https://github.com/xLinkOut/telegram-udf-autoit/wiki/) for more examples.

## What functions return
The main difference from previous version of this library is that every Telegram API call return the response object almost as-is; it check the response status and return the `result` inner object to the caller. If any error occurs during the HTTP request, the function return `Null` and set `@error` and `@extended` flags.

That said, when you call any Telegram-related functions, expect in return an object as described in the Telegram API documentation. Use the JSON library to retrieve the information you need.

## License
The license for this project has been updated from GPL to MIT. This means that you are now free to use this work in your projects, with the condition that you acknowledge and cite this library within your own work. Thank you for your support and cooperation.
