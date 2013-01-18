function txt = mrvAddText(txt,str)
%Add text to an existing text string
%
%   txt = mrvAddText(txt,str)
%
% Utility for combining strings before sending to an mrMessage
% Pretty useless.
%
% Example:
%  txt = 'Hello World! ';
%  txt = addText(txt,'What a beautiful day!');
%  

txt = [txt,str];

return;
