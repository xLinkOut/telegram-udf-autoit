#cs ------------------------------------------------------------------------------
   UDF:
	  Author		->	Luca aka LinkOut
	  Description	->	Control Telegram Bot with AutoIT
	  Language		->	English
	  Status		->	Fully functional, but some functions are missing (like group function)

   Documentation:
	  Telegram API	->	https://core.telegram.org/bots/api
	  GitHub Page	->	https://github.com/xLinkOut/telegram-udf-autoit/

   Author Information:
	  GitHub	->	https://github.com/xLinkOut
	  Telegram	->	https://t.me/LinkOut
	  Instagram	->	https://instagram.com/lucacirillo.jpg
	  Email		->	mailto:luca.cirillo5@gmail.com

   Extra:
	  WinHttp UDF provided by trancexx	->	https://www.autoitscript.com/forum/topic/84133-winhttp-functions/
#ce ------------------------------------------------------------------------------

#include-once
#include "WinHttp.au3"

Global $BOT_ID = ""
Global $TOKEN  = ""
Global $URL	   = "https://api.telegram.org/bot"
Global $offset = 0

#Region "@BOT MAIN FUNCTION"
#cs ===============================================================================
   Function Name..:    	_InitBot()
   Description....:	   	Initialize your Bot with BotID and Token
   Parameter(s)...:    	$BotID - Your Bot ID (12345..)
						$BotToken - Your Bot Token (AbCdEf...)
   Return Value(s):	   	Return True
#ce ===============================================================================
Func _InitBot($BotID,$BotToken)
   $BOT_ID = $BotID
   $TOKEN  = $BotToken
   $URL   &= $BOT_ID & ':' & $TOKEN
   Return True
EndFunc

#cs ===============================================================================
   Function Name..:    	_Polling()
   Description....:     Wait for incoming messages from user
   Parameter(s)...:     None
   Return Value(s):		Return an array with information about messages:
						   $msgData[0] = Offset of the current update (used to 'switch' to next update)
						   $msgData[1] = Username of the user
						   $msgData[2] = ChatID used to interact with the user
						   $msgData[3] = Text of the message
#ce ===============================================================================
Func _Polling()
   While 1
	  Sleep(1000) ;Prevent CPU Overloading
	  $newUpdates = _GetUpdates()
	  If Not StringInStr($newUpdates,'update_id') Then ContinueLoop
	  $msgData = _JSONDecode($newUpdates)
	  $offset = $msgData[0] + 1
	  Return $msgData
   WEnd
EndFunc

#cs ===============================================================================
   Function Name..:    	_GetUpdates()
   Description....:     Used by _Polling() to get new messages
   Parameter(s)...:     None
   Return Value(s): 	Return string with information encoded in JSON format
#ce ===============================================================================
Func _GetUpdates()
   Return HttpGet($URL & "/getUpdates?offset=" & $offset)
EndFunc ;==> _GetUpdates

#cs ===============================================================================
   Function Name..:    	_GetMe()
   Description....:     Get information about the bot (like name, @botname...)
   Parameter(s)...:     None
   Return Value(s):		Return string with information encoded in JSON format
#ce ===============================================================================
Func _GetMe()
   Return HttpGet($URL & "/getMe")
EndFunc ;==>_GetMe

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
Func _SendMsg($ChatID, $Text, $ParseMode = Default, $KeyboardMarkup = Default, $ResizeKeyboard = False, $OneTimeKeyboard = False, $DisableWebPreview = False, $DisableNotification = False)
   Local $Query = $URL & "/sendMessage?chat_id=" & $ChatID &"&text=" & $Text
   If $ParseMode = "Markdown" Then $Query &= "&parse_mode=markdown"
   If $ParseMode = "HTML" Then $Query &= "&parse_mode=html"
   If $KeyboardMarkup <> Default   Then $Query &= "&reply_markup=" & $KeyboardMarkup
   If $ResizeKeyboard 		= True Then $Query &= "&resize_keyboard=True"
   If $OneTimeKeyboard 		= True Then $Query &= "&one_time_keyboard=True"
   If $DisableWebPreview 	= True Then $Query &= "&disable_web_page_preview=True"
   If $DisableNotification 	= True Then $Query &= "&disable_notification=True"
   Local $Response = HttpPost($Query)
   ;Return $Response
   Return True
EndFunc ;==> _SendMsg

#cs ===============================================================================
   Function Name..:		_ForwardMsg()
   Description....:     Forward message from a chat to another
   Parameter(s)...:     $ChatID: Unique identifier for the target chat
						$OriginalChatID: Unique identifier for the chat where the original message was sent
						$MsgID: Message identifier in the chat specified in from_chat_id
   Return Value(s):  	Return True (to debug, uncomment 'return $response')
#ce ===============================================================================
Func _ForwardMsg($ChatID, $OriginalChatID, $MsgID, $DisableNotification = False)
   Local $Query = $URL & "/forwardMessage?chat_id=" & $ChatID & "&from_chat_id=" & $OriginalChatID & "&message_id=" & $MsgID
   If $DisableNotification = True Then $Query &= "&disable_notification=True"
   Local $Response = HttpPost($Query)
   ;Return $Response
   Return True
EndFunc ;== _ForwardMsg
#EndRegion

#Region "@SEND MEDIA FUNCTION"
#cs ===============================================================================
   Function Name..:		_SendPhoto()
   Description....:     Send a photo
   Parameter(s)...:     $ChatID: Unique identifier for the target chat
						$Path: Path to local file
						$Caption: Caption to send with photo (optional)
   Return Value(s):  	Return File ID of the photo as string
#ce ===============================================================================
Func _SendPhoto($ChatID, $Path, $Caption = "")
   Local $Query = $URL & '/sendPhoto'
   Local $hOpen = _WinHttpOpen()
   Local $Form = '<form action="' & $Query & '" method="post" enctype="multipart/form-data">' & _
				  ' <input type="text" name="chat_id"/>' & _
				  ' <input type="file" name="photo"/>'   & _
				  ' <input type="text" name="caption"/>' & _
			     '</form>'
   Local $Response = _WinHttpSimpleFormFill($Form, $hOpen, Default, _
						"name:chat_id", $ChatID, _
						"name:photo"  , $Path,   _
						"name:caption", $Caption)
   _WinHttpCloseHandle($hOpen)
   Return _GetFileID($Response)
EndFunc ;==> _SendPhoto

#cs ===============================================================================
   Function Name..:		_SendAudio()
   Description....:     Send an audio
   Parameter(s)...:     $ChatID: Unique identifier for the target chat
						$Path: Path to local file
						$Caption: Caption to send with audio (optional)
   Return Value(s):  	Return File ID of the audio as string
#ce ===============================================================================
Func _SendAudio($ChatID, $Path, $Caption = "")
   Local $Query = $URL & '/sendAudio'
   Local $hOpen = _WinHttpOpen()
   Local $Form = '<form action="' & $Query & '" method="post" enctype="multipart/form-data">' & _
				  ' <input type="text" name="chat_id"/>' & _
				  ' <input type="file" name="audio"/>'   & _
				  ' <input type="text" name="caption"/>' & _
			     '</form>'
   Local $Response = _WinHttpSimpleFormFill($Form, $hOpen, Default, _
						"name:chat_id", $ChatID, _
						"name:audio"  , $Path,   _
						"name:caption", $Caption)
   _WinHttpCloseHandle($hOpen)
   Return _GetFileID($Response)
EndFunc ;==> _SendAudio

#cs ===============================================================================
   Function Name..:		_SendVideo()
   Description....:     Send a video
   Parameter(s)...:     $ChatID: Unique identifier for the target chat
						$Path: Path to local file
						$Caption: Caption to send with video (optional)
   Return Value(s):  	Return File ID of the video as string
#ce ===============================================================================
Func _SendVideo($ChatID, $Path, $Caption = "")
   Local $Query = $URL & '/sendVideo'
   Local $hOpen = _WinHttpOpen()
   Local $Form = '<form action="' & $Query & '" method="post" enctype="multipart/form-data">' & _
				  ' <input type="text" name="chat_id"/>' & _
				  ' <input type="file" name="video"/>'   & _
				  ' <input type="text" name="caption"/>' & _
			     '</form>'
   Local $Response = _WinHttpSimpleFormFill($Form, $hOpen, Default, _
						"name:chat_id", $ChatID, _
						"name:video"  , $Path,   _
						"name:caption", $Caption)
   _WinHttpCloseHandle($hOpen)
   Return _GetFileID($Response)
EndFunc ;==> _SendVideo

#cs ===============================================================================
   Function Name..:		_SendDocument()
   Description....:     Send a document
   Parameter(s)...:     $ChatID: Unique identifier for the target chat
						$Path: Path to local file
						$Caption: Caption to send with document (optional)
   Return Value(s):  	Return File ID of the video as string
#ce ===============================================================================
Func _SendDocument($ChatID, $Path, $Caption = "")
   Local $Query = $URL & '/sendDocument'
   Local $hOpen = _WinHttpOpen()
   Local $Form = '<form action="' & $Query & '" method="post" enctype="multipart/form-data">' & _
				  ' <input type="text" name="chat_id"/>'  & _
				  ' <input type="file" name="document"/>' & _
				  ' <input type="text" name="caption"/>'  & _
			     '</form>'
   Local $Response = _WinHttpSimpleFormFill($Form, $hOpen, Default, _
						"name:chat_id",  $ChatID, _
						"name:document", $Path,   _
						"name:caption",  $Caption)
   _WinHttpCloseHandle($hOpen)
   Return _GetFileID($Response)
EndFunc ;==> _SendDocument

#cs ===============================================================================
   Function Name..:		_SendVoice()
   Description....:     Send a voice file
   Parameter(s)...:     $ChatID: Unique identifier for the target chat
						$Path: Path to local file (format: .ogg)
						$Caption: Caption to send with voice (optional)
   Return Value(s):  	Return File ID of the video as string
#ce ===============================================================================
Func _SendVoice($ChatID, $Path, $Caption = "")
   Local $Query = $URL & '/sendVoice'
   Local $hOpen = _WinHttpOpen()
   Local $Form = '<form action="' & $Query & '" method="post" enctype="multipart/form-data">' & _
				  ' <input type="text" name="chat_id"/>' & _
				  ' <input type="file" name="voice"/>'   & _
				  ' <input type="text" name="caption"/>' & _
			     '</form>'
   Local $Response = _WinHttpSimpleFormFill($Form, $hOpen, Default, _
						"name:chat_id", $ChatID, _
						"name:voice"  , $Path,   _
						"name:caption", $Caption)
   _WinHttpCloseHandle($hOpen)
   Return _GetFileID($Response)
EndFunc ;==> _SendVoice

#cs ===============================================================================
   Function Name..:		_SendSticker()
   Description....:     Send a sticker
   Parameter(s)...:     $ChatID: Unique identifier for the target chat
						$Path: Path to local file (format: .webp)
   Return Value(s):  	Return File ID of the video as string
#ce ===============================================================================
Func _SendSticker($ChatID,$Path)
   Local $Query = $URL & '/sendSticker'
   Local $hOpen = _WinHttpOpen()
   Local $Form = '<form action="' & $Query & '" method="post" enctype="multipart/form-data">' & _
				  ' <input type="text" name="chat_id"/>' & _
				  ' <input type="file" name="sticker"/>'   & _
			     '</form>'
   Local $Response = _WinHttpSimpleFormFill($Form, $hOpen, Default, _
						"name:chat_id", $ChatID, _
						"name:sticker", $Path)
   _WinHttpCloseHandle($hOpen)
   Return _GetFileID($Response)
EndFunc

#cs ===============================================================================
   Function Name..:		_SendChatAction()
   Description....:     Display 'chat action' on specific chat (like Typing...)
   Parameter(s)...:     $ChatID: Unique identifier for the target chat
						$Action: Type of the action, can be: 'typing','upload_photo','upload_video','upload_audio',upload_document','find_location'
   Return Value(s):  	Return True (to debug uncomment 'Return $Response')
#ce ===============================================================================
Func _SendChatAction($ChatID, $Action)
   Local $Query = $URL & "/sendChatAction?chat_id=" & $ChatID & "&action=" & $Action
   Local $Response = HttpPost($Query)
   ;Return $Response
   Return True
EndFunc ;==> _SendChatAction

#cs ===============================================================================
   Function Name..:		_SendLocation()
   Description....:     Send a location
   Parameter(s)...:     $ChatID: Unique identifier for the target chat
						$Latitude: Latitute of location
						$Longitude: Longitude of location
   Return Value(s):  	Return True (to debug, uncomment 'Return $Response')
#ce ===============================================================================
Func _SendLocation($ChatID, $Latitude, $Longitude)
   Local $Query = $URL & "/sendLocation?chat_id=" & $ChatID & "&latitude=" & $Latitude & "&longitude=" & $Longitude
   Local $Response = HttpPost($Query)
   ;Return $Response
   Return True
EndFunc ;==> _SendLocation

#cs ===============================================================================
   Function Name..:		_SendContact()
   Description....:     Send contact
   Parameter(s)...:     $ChatID: Unique identifier for the target chat
						$Phone: Phone number of the contact
						$Name: Name of the contact
   Return Value(s):  	Return True (to debug, uncomment 'Return $Response')
#ce ===============================================================================
Func _SendContact($ChatID,$Phone,$Name)
   Local $Query = $URL & "/sendContact?chat_id=" & $ChatID & "&phone_number=" & $Phone & "&first_name=" & $Name
   Local $Response = HttpPost($Query)
   ;Return $Response
   Return True
EndFunc ;==> _SendContact
#EndRegion

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
Func _GetUserProfilePhotos($ChatID,$Offset = "")
   $Query = $URL & "/getUserProfilePhotos?user_id=" & $ChatID
   If $Offset <> "" Then $Query &= "&offset=" & $Offset
   Local $Response = HttpPost($Query)
   Local $firstSplit  = StringSplit($Response,'{')

   ;Get Photos Count
   Local $tmpCount = StringSplit($firstSplit[3],',')
   Local $tmpCount_2 = StringSplit($tmpCount[1],':')
   Local $count = $tmpCount_2[2]

   ;Init Array
   Local $photoArray[$count + 1]
   $photoArray[0] = $count
   $fileidPosition = 6

   ;Get FileID for each photo
   For $i=1 to $count
	  Local $secondSplit = StringSplit($firstSplit[$fileidPosition],',')
	  Local $thirdSplit  = StringSplit($secondSplit[1],':')
	  Local $FileID = StringTrimLeft($thirdSplit[2],1)
	  $FileID = StringTrimRight($FileID,1)
	  $photoArray[$i] = $FileID
	  $fileidPosition += 3
   Next
   Return $photoArray
EndFunc ;==> _GetUserProfilePhotos

#cs ===============================================================================
   Function Name..:		_GetChat()
   Description....:     Get basic information about chat, like username of the user, id of the user
   Parameter(s)...:     $ChatID: Unique identifier for the target chat
   Return Value(s):  	Return string with information encoded in JSON format
#ce ===============================================================================
Func _GetChat($ChatID)
   Local $Query = $URL & "/getChat?chat_id=" & $ChatID
   Local $Response = HttpGet($Query)
   Return $Response
EndFunc
#EndRegion

#Region "@BACKGROUND FUNCTION"
#cs ===============================================================================
   Function Name..:		_GetFilePath()
   Description....:     Get path of a specific file (specified by FileID) on Telegram Server
   Parameter(s)...:     $FileID: Unique identifie for the file
   Return Value(s):  	Return FilePath as String
#ce ===============================================================================
Func _GetFilePath($FileID)
   Local $Query = $URL & "/getFile?file_id=" & $FileID
   Local $Response = HttpPost($Query)
   Local $firstSplit = StringSplit($Response,':')
   Local $FilePath = StringTrimLeft($firstSplit[6],1)
   $FilePath = StringTrimRight($FilePath,3)
   Return $FilePath
EndFunc

#cs ===============================================================================
   Function Name..:		_GetFileID()
   Description....:     Get file ID of the last uploaded file
   Parameter(s)...:     $Output: Response from HTTP Request
   Return Value(s):  	Return FileID as String
#ce ===============================================================================
Func _GetFileID($Output)
   If StringInStr($Output,"photo",1) and StringInStr($Output,"width",1) Then
	  Local $firstSplit  = StringSplit($Output,'[')
	  Local $secondSplit = StringSplit($firstSplit[2],',')
	  Local $thirdSplit  = StringSplit($secondSplit[9],':')
	  Local $FileID = StringTrimLeft($thirdSplit[2],1)
	  $FileID = StringTrimRight($FileID,1)
      Return $FileID

   ElseIf StringInStr($Output,'audio":',1) And StringInStr($Output,'mime_type":"audio',1) Then
	  Local $firstSplit = StringSplit($Output,',')
	  For $i=1 to $firstSplit[0]
		 If StringInStr($firstSplit[$i],"file_id",1) Then Local $secondSplit = StringSplit($firstSplit[$i],':')
	  Next
	  Local $FileID = StringTrimLeft($secondSplit[2],1)
	  $FileID = StringTrimRight($FileID,1)
	  Return $FileID

   ElseIf StringInStr($Output,'video":',1) and StringInStr($Output,"width",1) Then
	  Local $firstSplit = StringSplit($Output,',')
	  For $i=1 to $firstSplit[0]
		 If StringInStr($firstSplit[$i],"file_id",1) and not StringInStr($firstSplit[$i],"thumb",1) Then Local $secondSplit = StringSplit($firstSplit[$i],':')
	  Next
	  Local $FileID = StringTrimLeft($secondSplit[2],1)
	  $FileID = StringTrimRight($FileID,1)
	  Return $FileID

   ElseIf StringInStr($Output,'document":',1) and StringInStr($Output,"text/plain",1) Then
  	  Local $firstSplit = StringSplit($Output,',')
  	  For $i=1 to $firstSplit[0]
		 If StringInStr($firstSplit[$i],"file_id",1) Then Local $secondSplit = StringSplit($firstSplit[$i],':')
      Next
      Local $FileID = StringTrimLeft($secondSplit[2],1)
	  $FileID = StringTrimRight($FileID,1)
	  Return $FileID

   ElseIf StringInStr($Output,'voice":',1) and StringInStr($Output,"audio/ogg",1) Then
	  Local $firstSplit = StringSplit($Output,',')
	  For $i=1 to $firstSplit[0]
		 If StringInStr($firstSplit[$i],"file_id",1) Then Local $secondSplit = StringSplit($firstSplit[$i],':')
	  Next
      Local $FileID = StringTrimLeft($secondSplit[2],1)
	  $FileID = StringTrimRight($FileID,1)
	  Return $FileID

   ElseIf StringInStr($Output,'sticker":',1) and StringInStr($Output,"width",1) Then
	  Local $firstSplit = StringSplit($Output,',')
  	  For $i=1 to $firstSplit[0]
		 If StringInStr($firstSplit[$i],"file_id",1) Then Local $secondSplit = StringSplit($firstSplit[$i],':')
      Next
	  Local $FileID = StringTrimLeft($secondSplit[2],1)
	  $FileID = StringTrimRight($FileID,1)
	  Return $FileID
   EndIf
EndFunc

#cs ===============================================================================
   Function Name..:		_DownloadFile()
   Description....:     Download and save locally a file from the Telegram Server by FilePath
   Parameter(s)...:     $FilePath: Path of the file on Telegram Server
   Return Value(s):  	Return True
#ce ===============================================================================
Func _DownloadFile($FilePath)
   Local $firstSplit = StringSplit($FilePath,'/')
   Local $fileName = $firstSplit[2]
   Local $Query = "https://api.telegram.org/file/bot" & $BOT_ID & ":" & $TOKEN & "/" & $FilePath
   InetGet($Query,$fileName)
   Return True
EndFunc

#cs ===============================================================================
   Function Name..:		_JSONDecode()
   Description....:     Decode response from JSON format to array with information
   Parameter(s)...:     JSON Response from HTTP request
   Return Value(s):  	Return array with information about message
#ce ===============================================================================
Func _JSONDecode($JSONMsg)
   Local $firstSplit = StringSplit($JSONMsg,"update_id",1)
   Local $secondSplit = StringSplit($firstSplit[2], ",") ;1=BUFFER - 6=CHATID - 7=FIRSTNAME - 8=USERNAME - 9=TYPE - 10=DATE - 11=TEXT
   Local $dataArray[4]
   For $i=1 to $secondSplit[0]
	  Local $data = $secondSplit[$i]
	  If StringLeft($data,2) = '":' Then $dataArray[0] = StringTrimLeft($data,2)
	  If StringInStr($data,'username') Then
		 $tmpUsername = StringSplit($data,':')
		 $tmpUsername[2] = StringTrimLeft($tmpUsername[2],1)
		 $tmpUsername[2] = StringTrimRight($tmpUsername[2],1)
		 $dataArray[1] = $tmpUsername[2]
	  EndIf
	  If StringInStr($data,'chat') Then
		 $tmpChatID = StringSplit($data,':')
		 $dataArray[2] = $tmpChatID[3]
	  EndIf
	  If StringInStr($data,'text') Then
		 $tmpText = StringSplit($data,':')
		 If StringInStr($tmpText[2],'"}}]}') Then
			$tmpText[2] = StringTrimLeft($tmpText[2],1)
			$tmpText[2] = StringTrimRight($tmpText[2],5)
			$dataArray[3] = $tmpText[2]
		 ElseIf StringInStr($tmpText[2],'"}}') Then
			$tmpText[2] = StringTrimLeft($tmpText[2],1)
			$tmpText[2] = StringTrimRight($tmpText[2],3)
			$dataArray[3] = $tmpText[2]
		 ElseIf StringRight($tmpText[2],1) = '"' Then
			$tmpText[2] = StringTrimLeft($tmpText[2],1)
			$tmpText[2] = StringTrimRight($tmpText[2],1)
			$dataArray[3] = $tmpText[2]
		 EndIf
	  EndIf
   Next
   If $dataArray[3] = '' Then
	  For $i=1 to $secondSplit[0]
		 If StringInStr($secondSplit[$i],'first_name') Then
			$tmpUsername = StringSplit($secondSplit[$i],':')
			$tmpUsername[2] = StringTrimLeft($tmpUsername[2],1)
			$tmpUsername[2] = StringTrimRight($tmpUsername[2],1)
			$dataArray[3] = $tmpUsername[2]
		 EndIf
	  Next
   EndIf
   Return $dataArray
EndFunc ;==> _JSONDecode
#EndRegion

#Region "@HTTP Request"
Func HttpPost($sURL, $sData = "")
   Local $oHTTP = ObjCreate("WinHttp.WinHttpRequest.5.1")
   $oHTTP.Open("POST", $sURL, False)
   If (@error) Then Return SetError(1, 0, 0)
   $oHTTP.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded")
   $oHTTP.Send($sData)
   If (@error) Then Return SetError(2, 0, 0)
   If ($oHTTP.Status <> $HTTP_STATUS_OK) Then Return SetError(3, 0, 0)
   Return SetError(0, 0, $oHTTP.ResponseText)
EndFunc

Func HttpGet($sURL, $sData = "")
   Local $oHTTP = ObjCreate("WinHttp.WinHttpRequest.5.1")
   $oHTTP.Open("GET", $sURL & "?" & $sData, False)
   If (@error) Then Return SetError(1, 0, 0)
   $oHTTP.Send()
   If (@error) Then Return SetError(2, 0, 0)
   If ($oHTTP.Status <> $HTTP_STATUS_OK) Then Return SetError(3, 0, 0)
   Return SetError(0, 0, $oHTTP.ResponseText)
EndFunc
#EndRegion