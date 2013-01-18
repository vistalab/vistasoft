function checkSize(vw,map)
%
% function checkSize(vw,map)
%
% Checks to make sure map has the appropriate size for the view
%
% djh, 2/22/2001
% ras, 03/04/2004: a tentative change: for some event-related analyses,
% new scans are introduced into the 'Deconvolved' data type as new analyses
% are conducted. Since this does not invalidate the old analyses (and it's
% a significant pain to keep re-generating the same maps recursively with
% each new analysis), I've made the size check forgive a map if it's not
% padded to the proper number of empty scans, and pad it.
nScans = viewGet(vw, 'numScans');

if length(map) > nScans
    disp(['Warning: Parameter map should be a cell array of length: ',num2str(nScans)]);
	map = map(1:nScans);
elseif length(map) < nScans
    warnmsg = sprintf('This map only specifies %i scans, but the vw has %i scans.',length(map),nScans);
    warnmsg = [warnmsg sprintf(' Am padding out to the proper number, but check that this is an appropriate map.')];
    warning(warnmsg);
    map{nScans} = [];
end

for scan = 1:length(map)
    correctSize = dataSize(vw,scan);
    if ~isempty(map{scan})
		mapSize = size(map{scan});
		
		% check for single-slice (or 1D)? maps: pad extra dims w/ 1		
		if length(mapSize) < length(correctSize)
			mapSize = [mapSize ones(1, length(correctSize)-length(mapSize))];
        end
        
		
        if (mapSize ~= correctSize)
            myErrorDlg(['Parameter map must be size:  ',num2str(correctSize)]);
        end
    end
end

return
