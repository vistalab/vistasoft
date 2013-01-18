function newProgStat=updateBusybar(handle,currentProgressStatus)
%function progressStatus=updateProgressbar(handle,currentProgressStatus)
%GUIs can have a text box that acts as a progress bar. This routine updates 
% one by adding a new character to the box and zeroing it at the end.

%% ras, 01/07: this code seems inexpicably to cause the whole unfold
% process to die on some systems, so I'm just commenting it out. 
% It's probably a MATLAB 7 thing, or a linux thing, or some combination
% of the two. We lose time callling the empty function, but at least it
% works (and MUCH better than w/ the bug).

% posit=get(handle,'Position');
% 
% boxLen=fix(posit(3));
% newProgStat=mod(currentProgressStatus+1,boxLen);
% set(handle,'String',repmat('|',1,newProgStat));

return
