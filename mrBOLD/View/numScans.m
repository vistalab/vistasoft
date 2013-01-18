function nScans = numScans(vw, dataType)
% Number of scans in current view (for selected data type, or 
% current data type if the second argument is omitted).
%
% nScans = numScans(vw, [dataType])
%
% djh, 2/21/2001
% ras, 1/9/2006, added dataType argument
% 
% Obsolete. New usage should be
%  nScans = viewGet(view, 'nscans', [dt]);

warning('vistasoft:obsoleteFunction', 'numScans.m is obsolete.\nUsing\n\tnScans = viewGet(vw, ''numScans'', [dataType])\ninstead.');

if exist('dataType', 'var'), 
    nScans = viewGet(vw, 'numScans', dataType); 
    return
else
    nScans = viewGet(vw, 'numScans'); 
    return
end

% global dataTYPES;
% 
% if notDefined('dataType'),	dataType = view.curDataType;		end
% 
% if ischar(dataType)
% 	dataType = existDataType(dataType);
% end
% 
% if dataType==0
% 	error('Invalid data type specified: %i', dataType);
% end
% 
% nScans = length(dataTYPES(dataType).scanParams);
% 
% return;
% 
