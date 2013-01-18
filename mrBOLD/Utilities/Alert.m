function Alert(errmsg)
% Display a modal dialog box with the specified message.
%
%  Alert(errmsg);
% 
% Example
%   Alert('Help me help you')
%
wH = msgbox(errmsg, '!', 'warn', 'modal');
waitfor(wH);

return;
