function rx = rxEditSize(rx)
%
% rx = rxEditSize(rx);
%
% Put up a dialog to set the size and resolution of the prescription
% in a mrRx session, as well as the resolution of the prescribed and
% reference volumes.
%
% ras, 01/2007.
if notDefined('rx'), rx = get(findobj('Tag', 'rxControlFig'), 'UserData'); end

ttl = 'Set Prescription Size Parameters';
prompt = {'Prescription dimensions in voxels?' ...
          'Prescription voxel size (mm)?' ...
          'Voxel size (mm) of prescribed volume?' ...
          'Voxel size(mm) of reference volume?'};
def = {num2str(rx.rxDims) num2str(rx.rxVoxelSize) ...
       num2str(rx.volVoxelSize) num2str(rx.refVoxelSize)};

resp = inputdlg(prompt, ttl, 1, def);

rx.rxDims       = str2num(resp{1}); %#ok<*ST2NM>
rx.rxVoxelSize  = str2num(resp{2});
rx.volVoxelSize = str2num(resp{3});
rx.refVoxelSize = str2num(resp{4});

rx.rxSizeMM  = rx.rxDims  .* rx.rxVoxelSize;
rx.volSizeMM = rx.volDims .* rx.volVoxelSize;
rx.refSizeMM = rx.refDims .* rx.refVoxelSize;

% update some GUI controls to be consistent with these settings
rx.ui.rxSlice.range(2) = rx.rxDims(3);
nVals = floor(diff(rx.ui.rxSlice.range));
step = [1/(nVals+1) 3/(nVals+1)];
set(rx.ui.rxSlice.sliderHandle, 'Max', rx.rxDims(3), 'SliderStep', step);

rx = rxRefresh(rx);

return
