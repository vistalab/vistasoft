function slice = cropCurSlice(vw, field, curSlice, orientation)
%
% function slice = cropCurSlice(vw, field, curSlice, orientation)
%
% Pulls slice from vw.field.  Field can be co, amp, ph, or
% map.
%
% djh, 7/98
% ras, 3/03: allows orientation/slicenum to be entered as arguments (to be
% compatible with multi-vw option for volume and gray views).
global mrSESSION

% Get curSlice, curScan from buttons
% (unless entered)
if ~exist('curSlice','var') || isempty(curSlice),
    curSlice = viewGet(vw, 'CurSlice');
end
curScan = viewGet(vw, 'CurScan');

% For correlation coefficient or projected amplitude, run twice:
if strcmpi(field,'cor') || strcmpi(field,'projamp');
    if exist('orientation','var');
        sliceph = cropCurSlice(vw, 'ph', curSlice, orientation);
    else
        sliceph = cropCurSlice(vw, 'ph', curSlice);
    end
    if isfield(vw,'refPh');
        refPh = vw.refPh;
    else
        refPh = 0.2*pi; disp('reference phase not set, assume 0.2*pi');
    end
    sliceph = cos(sliceph-refPh);
    if strcmpi(field,'cor'); field = 'co'; end;
    if strcmpi(field,'projamp'); field = 'amp'; end;
end

if ~isfield(vw, field) 
    myErrorDlg(['Invalid display mode: ',field]);
end

% Pull out data corresponding to field.
data = vw.(field);

if isempty(data)
    slice=[];
    return
end

% pull out curScan:
% bounds check: if the data haven't been computed for this
% scan (or if a new scan was added to the data type, e.g.
% in Averages), don't error, but warn and return an empty slice:
if length(data) < curScan || isempty(data{curScan})
    slice=[];
    return
else
    dataScan = data{curScan};
end

switch vw.viewType
case 'Flat'
    % pull out curSlice
    slice = dataScan(:,:,curSlice);
    
case 'Inplane'
    % pull out curSlice
    slice = dataScan(:,:,curSlice);
    % interpolate up to the size of the anatomy image
    slice = upSampleRep(slice,viewGet(vw,'Anat Slice Dims'));
    
case {'Volume','Gray'}
    % Get slice orientation
    if ~exist('orientation','var')  
        orientation = getCurSliceOri(vw);
    end
    
    % Find indices of the appropriate VOLUME.coords, make the image,
    % and a 2xN array of image coordinates (where N is the
    % number of VOLUME.coords in the slice).
    volSize = viewGet(vw,'Size');
    
    switch orientation
    case 1 
        % axial (x-z) slice
        indices = find(vw.coords(1,:)==curSlice);
        imSize = volSize([2,3]);
        imCoords = double(vw.coords([2,3],indices));
    case 2 
        % coronal (y-z) slice				
        indices = find(vw.coords(2,:)==curSlice);
        imSize = [volSize([1,3])];
        imCoords = double(vw.coords([1,3],indices));
    case 3 
        % sagittal (y-x) slice				
        indices = find(vw.coords(3,:)==curSlice);
        imSize = volSize([1,2]);
        imCoords = double(vw.coords([1,2],indices));
    end
    
    % This variable is not used. what was it doing here?
    %dataScanSlice = dataScan(indices);
    
    % Make an image of the appropriate size.
    slice = zeros(imSize);
    
    % Compute the image indices from the image coordinates
    imIndices = coords2Indices(imCoords,imSize);
    
    % Set those image values from the data
    slice(imIndices) = dataScan(indices);
end

if exist('sliceph','var'); % this is the projected phase calculation!
    slice = slice .* sliceph;
end

return

