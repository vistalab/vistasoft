function dirText = dimFlip(dirText);
% flip direction text 'a <--> b' to read 'b <--> a'.
%
% Usage:
% dirText = dimFlip(dirText);
% 
% ras, 11/05
I = findstr(dirText, ' <--> ');
if isempty(I), return; end
lhs = dirText(1:I);
rhs = dirText(I+5:end);
dirText = [rhs '<-->' lhs];
return