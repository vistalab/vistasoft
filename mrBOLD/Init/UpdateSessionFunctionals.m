function mrSESSION = UpdateSessionFunctionals(mrSESSION,scanParams,doCrop);
% mrSESSION = UpdateSessionFunctionals(mrSESSION,scanParams,doCrop);
%
% Set the fields of mrSESSION.functionals
%
% djh & dbr, 9/2001
% ras, 4/04: fixed (in a somewhat ugly way) a bug that
% occurs when you don't want to crop -- it sometimes
% ends up setting the cropSize off by 0.5, for some
% really weird reason I don't get.
if ~exist('doCrop','var')   doCrop = 1;     end

if isfield(mrSESSION, 'functionals')
    nOldScans = length(mrSESSION.functionals);
    nNewScans = length(scanParams);
    if nOldScans > 0
        oldNames = {mrSESSION.functionals(:).PfileName};
    else
        oldNames = {};
    end
    for iNew=1:nNewScans
        newName = scanParams(iNew).PfileName;
        if ~any(strcmp(newName, oldNames))
            % If the Pfile name is new, append it
            mrSESSION.functionals = [mrSESSION.functionals scanParams(iNew)];
        end
    end
else
    mrSESSION.functionals = scanParams;
end

% Update functionals.crop & cropSize
% (This is very confusing, and doesn't
% seem to work if you don't want to crop:
% e.g. if your crop is [1 1; 128 128], it
% makes the cropSize [128.5 128.5], and
% breaks everything.
%   Therefore, if doCrop is not selected,
% don't do this). -ras, 04/04
if doCrop
    ipCrop = mrSESSION.inplanes.crop;
    ipCrop(1,:) = ipCrop(1,:)-1;
    ipFullSize = mrSESSION.inplanes.fullSize;
    for iScan = 1:length(mrSESSION.functionals)
        funcFullSize = mrSESSION.functionals(iScan).fullSize;
        sizeRatio = ipFullSize ./ funcFullSize;
        crop(1,:) = ipCrop(1,:)./sizeRatio;
        crop(2,:) = ipCrop(2,:)./sizeRatio;
        if any(sizeRatio - floor(sizeRatio) <0)
            FatalInitError('Crop is busted, inplane size not a multiple of functional size. Start over and redo the crop.');
        end
        if any(crop - floor(crop) <0)
            FatalInitError('Crop is busted, inplane crop not a multiple of sizeRatio. Start over and redo the crop.');
        end
        crop(1,:) = crop(1,:) + 1;
        mrSESSION.functionals(iScan).crop = crop;
        cropSize = diff(fliplr(crop)) + 1;
        mrSESSION.functionals(iScan).cropSize = cropSize;
    end
else
    for iScan = 1:length(mrSESSION.functionals)
        cropSize = mrSESSION.functionals(iScan).crop(2,:);
        mrSESSION.functionals(iScan).cropSize = cropSize;
    end
end

