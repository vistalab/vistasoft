function vw = selectDataType(vw,n)
%
% vw = selectDataType(vw,n)
%
% Selects the Nth dataType in the global dataTYPES variable 
% to be the current data type for a view. 
% - Sets vw.curDataType=n;
% - Blasts co, amp, ph, & map
% - Resets the dataType popup and the scan slider
% You can also enter the name of the data type.
%
% djh, 1/26/98
% ras, 01/05: also now allows you to select by name.

global dataTYPES

if ischar(n)
    % find the # of the data type w/ that name
    % mrGlobals;
    names = {dataTYPES.name};
    tmp = cellfind(names,n);
    
    % warn, but do nothing, if the
    % specified name wasn't found:
    if isempty(tmp)
        warning('No Data type found with name %s. Making no changes...',n); %#ok<WNTAG>
        return
    else
        n = tmp;
    end
end
    
if (viewGet(vw, 'Cur Data Type') ~= n)
    vw.curDataType = n;
    vw = clearData(vw);
end

% Set popup slider
if checkfields(vw, 'ui', 'dataType')
    setDataTypePopup(vw);
    vw = initScanSlider(vw);	
	vw = setDisplayMode(vw, 'anat');  % no data loaded yet
end

return


