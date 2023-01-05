function mrSESSION = SetCropFields(mrSESSION);

% mrSESSION = SetCropFields(mrSESSION);
%
% Set the mrSESSION.crop & cropSize fields
%
% djh & dbr, 9/2001

% Update functionals.crop & cropSize
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
