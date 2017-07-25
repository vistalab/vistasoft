function rxSaveVolume(rx,savePath,format);
%
% rxSaveVolume([rx],[savePath],[format]):
%
% Take the current transformation specified
% by a mrRx rx struct, apply it to the current
% volume, and save it in the specified save path
% and format.
%
% If savePath is omitted, brings up a dialog.
%
% 
% ras 03/05
if notDefined('rx')
    cfig = findobj('Tag','rxControlFig');
    rx = get(cfig,'UserData');
end


if notDefined('savePath')
	savePath = '';  % we'll let the mrSave dialog ask for the path
%     % put up a dialog
%     opts = {...
%             '*.dat' 'mrVista vAnatomy files' ...
%             '*.img' 'ANALYZE fies' ...
%             '*.dcm' 'DICOM files' ...
%             'I*'  'I files' ...
%         };
%     [fname pth] = uiputfile(opts,'Save Xformed Volume...');
%     savePath = fullfile(pth,fname);
end

if notDefined('format'), format = ''; end

% initalize an empty mr struct for the output volume
mr = mrCreateEmpty;

% % TODO: make this work 
% % perform high-quality spline interpolation on the mr data
% altData = mrAnatResliceSpm(rx.vol, rx.xform, [], rx.volVoxelSize);

% perform lower-quality, but consistent, resampling (linear
% interpolation) on the image
if prefsVerboseCheck, h_wait = mrvWaitbar(0, 'Interpolating...'); end
for z = 1:rx.rxDims(3)
	mr.data(:,:,z) = rxInterpSlice(rx, z);
	
	if prefsVerboseCheck, mrvWaitbar(z/rx.rxDims(3), h_wait); end
end
if prefsVerboseCheck, close(h_wait); end
mr.data( isnan(mr.data) ) = 0;

% set other fields
mr.voxelSize = rx.volVoxelSize;
mr.dims = rx.volDims;
mr.extent = mr.voxelSize .* mr.dims;
mr.dimUnits = 'mm';
mr.hdr.note = sprintf('Created by %s %s.', mfilename, datestr(now));
mr.dataRange = [min(mr.data(:)) max(mr.data(:))];
mr.spaces = mrStandardSpaces(mr);

% for saving NIFTI/ANALYZE-format files, we'll rotate the data into the
% standard L->R/ P->A / I->S coordinate system 
if ismember( lower(format), {'nifti' 'analyze'} )
	mr.data = mrAnatRotateVAnat(mr.data);
end

% save the file (will provide a dialog for path/format)
mrSave(mr, savePath, format);

return

