#include "../Telegram.au3"

$Token  = "" ;Token here
$ChatID = "" ;Your ChatID here (take this from @MyTelegramID_bot)
_InitBot($Token)

;Normal keyboard with one row and two buttons
Local $normalKeyboard[2] = ['Left','Right']
Local $normalMarkup = _CreateKeyboard($normalKeyboard)
;ConsoleWrite($normalMarkup & @CRLF)
_SendMsg($ChatID,"This is a message with a custom keyboard with one row and two buttons.",Default,$normalMarkup)

;Normal keyboard with two rows and three buttons
Local $normalKeyboard[4] = ['TopLeft','TopRight','','SecondRow']
Local $normalMarkup = _CreateKeyboard($normalKeyboard)
;ConsoleWrite($normalMarkup & @CRLF)
_SendMsg($ChatID,"This is a message with a custom keyboard with two rows and three buttons.",Default,$normalMarkup)

;Inline keyboard with one row and two buttons
Local $inlineKeyboard[4] = ['Yes','pressed_yes','No','pressed_no']
Local $inlineMarkup = _CreateInlineKeyboard($inlineKeyboard)
;ConsoleWrite($inlineMarkup & @CRLF)
_SendMsg($ChatID,"This is a message with an inline keyboard with one row and two buttons.",Default,$inlineMarkup)

;Inline keyboard with two rows and two buttons
Local $inlineKeyboard[5] = ['Yes','pressed_yes','','No','pressed_no']
Local $inlineMarkup = _CreateInlineKeyboard($inlineKeyboard)
;ConsoleWrite($inlineMarkup & @CRLF)
_SendMsg($ChatID,"This is a message with an inline keyboard with two rows and two buttons.",Default,$inlineMarkup)
