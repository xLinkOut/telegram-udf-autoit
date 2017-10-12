#cs ------------------------------------------------------------------------------
   About:
		Author: Luca aka LinkOut
		Description: Control Telegram Bot with AutoIt
		Language: English
		Status: Fully functional, but some functions are missing (like group function)

   Documentation:
		Telegram API: https://core.telegram.org/bots/api
		GitHub Page: https://github.com/xLinkOut/telegram-udf-autoit/

   Author Information:
		GitHub: https://github.com/xLinkOut
		Telegram: https://t.me/LinkOut
		Instagram: https://instagram.com/lucacirillo.jpg
		Email: mailto:luca.cirillo5@gmail.com

   Extra:
		WinHttp UDF provided by trancexx: https://www.autoitscript.com/forum/topic/84133-winhttp-functions/
		JSON UDF provided by zserge: http://zserge.com/jsmn.html (Downloaded from here https://github.com/J2TeaM/AutoIt-Imgur-UDF/tree/master/include)
#ce ------------------------------------------------------------------------------

#cs ===============================================================================
   Function Name..:    	_InitBot()
   Description....:	   	Initialize your Bot with BotID and Token
   Parameter(s)...:    	$Token: Your bot's token (123456789:AbCdEf...)
   Return Value(s):	   	Return True if success, False and @error otherwise
#ce ===============================================================================

#cs ===============================================================================
   Function Name..:    	_Polling()
   Description....:     Wait for incoming messages from user
   Parameter(s)...:     None
   Return Value(s):		Return an array with information about messages
#ce ===============================================================================

#cs ===============================================================================
   Function Name..:    	_GetUpdates()
   Description....:     Used by _Polling() to get new messages
   Parameter(s)...:     None
   Return Value(s): 	Return string with information encoded in JSON format
#ce ===============================================================================

#cs ===============================================================================
   Function Name..:    	_GetMe()
   Description....:     Get information about the bot (like name, @botname...)
   Parameter(s)...:     None
   Return Value(s):		Return array with information about the bot
#ce ===============================================================================

#cs ===============================================================================
   Function Name..:		_SendMsg()
   Description....:     Send simple text message
   Parameter(s)...:     $ChatID: Unique identifier for the target chat
						$Text: Text of the message
						$ParseMode: Markdown/HTML (optional)- https://core.telegram.org/bots/api#sendmessage
						$KeyboardMarkup: Custom Keyboards (optional) - https://core.telegram.org/bots/api#replykeyboardmarkup
						$ResizeKeyboard: True/False (optional) - Requests clients to resize the keyboard vertically for optimal fit
						$OneTimeKeyboard: True/False (optional) - Requests clients to hide the keyboard as soon as it's been used
						$DisableWebPreview: True/False (optional) - Disables link previews for links in this message
						$DisableNotification: True/False (optional) - Sends the message silently
   Return Value(s):  	Return True (to debug, uncomment 'Return $Response')
#ce ===============================================================================


#cs ===============================================================================
   Function Name..:		_ForwardMsg()
   Description....:     Forward message from a chat to another
   Parameter(s)...:     $ChatID: Unique identifier for the target chat
						$OriginalChatID: Unique identifier for the chat where the original message was sent
						$MsgID: Message identifier in the chat specified in from_chat_id
   Return Value(s):  	Return True (to debug, uncomment 'return $response')
#ce ===============================================================================

#cs ===============================================================================
   Function Name..:		_SendPhoto()
   Description....:     Send a photo
   Parameter(s)...:     $ChatID: Unique identifier for the target chat
						$Path: Path to local file
						$Caption: Caption to send with photo (optional)
   Return Value(s):  	Return File ID of the photo as string
#ce ===============================================================================


#cs ===============================================================================
   Function Name..:		_SendAudio()
   Description....:     Send an audio
   Parameter(s)...:     $ChatID: Unique identifier for the target chat
						$Path: Path to local file
						$Caption: Caption to send with audio (optional)
   Return Value(s):  	Return File ID of the audio as string
#ce ===============================================================================


#cs ===============================================================================
   Function Name..:		_SendVideo()
   Description....:     Send a video
   Parameter(s)...:     $ChatID: Unique identifier for the target chat
						$Path: Path to local file
						$Caption: Caption to send with video (optional)
   Return Value(s):  	Return File ID of the video as string
#ce ===============================================================================


#cs ===============================================================================
   Function Name..:		_SendDocument()
   Description....:     Send a document
   Parameter(s)...:     $ChatID: Unique identifier for the target chat
						$Path: Path to local file
						$Caption: Caption to send with document (optional)
   Return Value(s):  	Return File ID of the video as string
#ce ===============================================================================


#cs ===============================================================================
   Function Name..:		_SendVoice()
   Description....:     Send a voice file
   Parameter(s)...:     $ChatID: Unique identifier for the target chat
						$Path: Path to local file (format: .ogg)
						$Caption: Caption to send with voice (optional)
   Return Value(s):  	Return File ID of the video as string
#ce ===============================================================================


#cs ===============================================================================
   Function Name..:		_SendSticker()
   Description....:     Send a sticker
   Parameter(s)...:     $ChatID: Unique identifier for the target chat
						$Path: Path to local file (format: .webp)
   Return Value(s):  	Return File ID of the video as string
#ce ===============================================================================


#cs ===============================================================================
   Function Name..:		_SendChatAction()
   Description....:     Display 'chat action' on specific chat (like Typing...)
   Parameter(s)...:     $ChatID: Unique identifier for the target chat
						$Action: Type of the action, can be: 'typing','upload_photo','upload_video','upload_audio',upload_document','find_location'
   Return Value(s):  	Return True (to debug uncomment 'Return $Response')
#ce ===============================================================================


#cs ===============================================================================
   Function Name..:		_SendLocation()
   Description....:     Send a location
   Parameter(s)...:     $ChatID: Unique identifier for the target chat
						$Latitude: Latitute of location
						$Longitude: Longitude of location
   Return dValue(s):  	Return True (to debug, uncomment 'Return $Response')
#ce ===============================================================================


#cs ===============================================================================
   Function Name..:		_SendContact()
   Description....:     Send contact
   Parameter(s)...:     $ChatID: Unique identifier for the target chat
						$Phone: Phone number of the contact
						$Name: Name of the contact
   Return Value(s):  	Return True (to debug, uncomment 'Return $Response')
#ce ===============================================================================

#Region "@CHAT FUNCTION"
#cs ===============================================================================
   Function Name..:		_GetUserProfilePhotos()
   Description....:     Get all the profile pictures of an user
   Parameter(s)...:     $ChatID: Unique identifier for the target chat
						$Offset (optional): offset to use if you want to get a specific photo
   Return Value(s):  	Return an array with count and fileIDs of the photos
						$photoArray[0] = Integer, photo's count
						$photoArray[1,2...] = FileID of the profile picture (use _DownloadFile to download file)
#ce ===============================================================================

#cs ===============================================================================
   Function Name..:		_GetChat()
   Description....:     Get basic information about chat, like username of the user, id of the user
   Parameter(s)...:     $ChatID: Unique identifier for the target chat
   Return Value(s):  	Return string with information encoded in JSON format
#ce ===============================================================================

#EndRegion

#Region "@BACKGROUND FUNCTION"
#cs ===============================================================================
   Function Name..:		_GetFilePath()
   Description....:     Get path of a specific file (specified by FileID) on Telegram Server
   Parameter(s)...:     $FileID: Unique identifie for the file
   Return Value(s):  	Return FilePath as String
#ce ===============================================================================


#cs ===============================================================================
   Function Name..:		_GetFileID()
   Description....:     Get file ID of the last uploaded file
   Parameter(s)...:     $Output: Response from HTTP Request
   Return Value(s):  	Return FileID as String
#ce ===============================================================================

#cs ===============================================================================
   Function Name..:		_DownloadFile()
   Description....:     Download and save locally a file from the Telegram Server by FilePath
   Parameter(s)...:     $FilePath: Path of the file on Telegram Server
   Return Value(s):  	Return True
#ce ===============================================================================


#cs ===============================================================================
   Function Name..:		_JSONDecode()
   Description....:     Decode response from JSON format to array with information
   Parameter(s)...:     JSON Response from HTTP request
   Return Value(s):  	Return array with information about message
#ce ===============================================================================

#EndRegion

