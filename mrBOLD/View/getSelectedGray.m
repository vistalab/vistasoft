function gray = getSelectedGray
%
% gray = getSelectedGray
%
%Purpose:
% Returns the currently selected gray view.
%
% If no gray view is selected, but there are view structures in the 
% global VOLUME variable, this functino returns the last (presumably
% most recent) gray view.
%
% If the VOLUME variable is empty, initializes a hidden gray view.
%
%
% HISTORY:
% ARW 081203 - Added default gray return.
% ras 092605 - made it return the most recent gray if there are more than
% one; I figure this is right enough times that it's better than erroring.
% ras 100907 - now, if it doesn't find an open gray view in VOLUME,
% initializes a hidden gray view.
mrGlobals
if notDefined('VOLUME') | isempty(cellfind(VOLUME))
	verbose = prefsVerboseCheck;
	if verbose
		disp('No open gray views found. Initializing a hidden gray view...');
	end
	gray = initHiddenGray;
	
	% let's go ahead and assign the gray to the VOLUME variable,
	% so if this is called again, we won't need to re-initialize
	% the hidden gray, and save time:
	VOLUME{getNewViewIndex(VOLUME)} = gray;
    return
end
if ~isempty(selectedVOLUME) & strcmp(VOLUME{selectedVOLUME}.viewType,'Gray')
    gray = VOLUME{selectedVOLUME};
	
else
    grayList = cellfind(VOLUME);
    gray = VOLUME{grayList(end)};	
	
end
return;
