function data = getCurData(vw,fieldname,scanNum)
%
% data = getCurData(vw,fieldname,scanNum)
%
% Returns either co, amp, or ph for given scan number.
% Data is returned as a 3D array.
% 
% Beware of running this function on VOLUMEs and GRAYs. Data 
% for a given scan is stored as a vector of length
% nVoxels. This is converted to a 3D array that may be
% mostly filled with NaNs.
%
% scanNum: integer
% fieldname: 'co', 'amp', or 'ph'
%
% djh and baw, 7/98 

tmp = viewGet(vw,fieldname);
if isempty(tmp)
    myErrorDlg([fieldname,' is empty']);
end

if strcmp(viewGet(vw,'View Type'),'Volume') || strcmp(viewGet(vw,'View Type'),'Gray')
    volSize = viewGet(vw,'Size');
    tmp = tmp{scanNum}(:);
    data = NaN*ones(volSize);
    volCoords = viewGet(vw,'Coords');
    volIndices = coords2Indices(volCoords,volSize);
    data(volIndices) = tmp; 
else
    data = tmp{scanNum};
end

return;

% Debug/test

% get co for volume and inplane
coInplane = getCurData(INPLANE{1},'co',1);
coVolume  = getCurData(VOLUME{1},'co',1);
coFlat    = getCurData(FLAT{1},'co',1);

% toss NaNs and compare means (similar but not identical)
volIndices = find(~isnan(coVolume));
mean(coVolume(volIndices))
mean(coInplane(:))
