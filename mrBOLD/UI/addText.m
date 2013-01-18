function txt = addText(txt,str)
%
%   txt = addText(txt,str)
%
% Author: BW
% Purpose:
%   Utility for combining strings before sending to an mrMessage
%   
% Example:
%  txt = 'Hello World! ';
%  txt = addText(txt,'What a beautiful day!');
%  mrMessage(txt);
%  
txt = [txt,sprintf(str)];

return;
