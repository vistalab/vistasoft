function rx = rxUpdateHistory(rx, historySize); 
% Update the history of a mrRx field, for undoing
% 
% rx = rxUpdateHistory(rx, <historySize=5>); 
%
% Saves the current xform in a mrRx prescription to the
% rx.history field (making it if it doesn't exist). historySize
% determines the max # of edits to save. [default 5]
%
% ras, 01/10/06
if nargin<2, historySize = 5; end

if ~isfield(rx, 'history'), rx.history = {}; end
n = length(rx.history)+1; 
if n<historySize,   
    rx.history{n} = rx.xform;
else,               
    rx.history