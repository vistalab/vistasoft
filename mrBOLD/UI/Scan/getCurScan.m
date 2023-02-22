function curScan = getCurScan(vw)
%
%   curScan = getCurScan(vw)
%
% Gets curScan from the scanButtons handles
% If the window is hidden, then we have to ask the user.
%
% BW, 12.23.00
% ras, 05/05: added a 'curScan' field in setCurScan;
% correspondingly, this checks if it exists first, and
% checks the UI as a fallback.
%
% jw, 6/2010: obsolete. use curScan = viewGet(vw, 'curScan');

warning('vistasoft:obsoleteFunction', 'curScan.m is obsolete.\nUsing\n\tcurScan = viewGet(vw, ''curScan'')\ninstead.');

curScan = viewGet(vw, 'curScan');

return
% 
% if checkfields(view,'curScan')
%     curScan = view.curScan;
% else
% 	if checkfields(view,'ui','scan','sliderHandle')
%         curScan = round(get(view.ui.scan.sliderHandle,'value'));
% 	else
%         % Sometimes there is no window interface (it is hidden).  Then, we have
%         % to find another way to determine the current scan.  Here, we ask the
%         % user.  It would be possible to store this information in the VIEW
%         % structure.  But we don't.  Ugh.
%         curScan = 1; ieReadNumber('Enter scan number');
% 	end
% end
% return;
