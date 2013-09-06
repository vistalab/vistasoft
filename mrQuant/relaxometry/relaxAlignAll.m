function [s,xform] = relaxAlignAll(s, refImg, outMm, bb, interp)
%
% [s,xform] = relaxAlignAll(s, refImg, [outMm=refImg.pixdim], [bb=true], [interp=7])
% 
% Aligns all the series in s to the NIFTI file (or struct) refImg.
% If refImg is empty, all series are aligned to the first series.
%
% If bb==true, then the bounding box will be taken from the reference
% image. If bb==false, it will be taken from the first image in the series.
% If bb is a valid bounding box, then that will be used.
%
%
% HISTORY:
% 2008.01.01 RFD: wrote it.
% 2008.10.06 RFD: fixed bug where s(1) was getting zeroed-out when refImg
% was empty.
% 2009.12.07 RFD: no longer set NANs to 0. NANs are useful for knowing what
% regions are outside the FOV. Also, changed it to use the actual transform
% from the dicom header.

if(~exist('refImg','var'))
  refImg = [];
end
if(ischar(s))
  s = dicomLoadAllSeries(s);
end
if(~exist('outMm','var'))
  outMm = [];
end
if(~exist('bb','var')||isempty(bb))
  bb = true;
end
if(~exist('interp','var')||isempty(interp))
  interp = 1;
end
if(numel(interp)<6)
   interp = [interp(1) interp(1) interp(1) 0 0 0];
end

% Don't try to process localizers...
locInds = ~cellfun('isempty',regexp({s.seriesDescription},'LOCALIZER'));
if(any(locInds))
    fprintf('Discarding series [%d] since they appear to be localizers.\n', find(locInds));
    s = s(~locInds);
end

nSeries = numel(s);

disp('Applying cannonical xform to all series...');
for(ii=1:nSeries)
    canXform = mrAnatComputeCannonicalXformFromDicomXform(s(ii).imToScanXform,size(s(ii).imData));
    [s(ii).imData,s(ii).mmPerVox] = applyCannonicalXform(s(ii).imData, canXform, s(ii).mmPerVox, false);
    % Now that the data have been flipped to our cannonical (axial)
    % orientation, we need to flip the imToScanXform to also reflect this
    % new orientation:
    s(ii).imToScanXform = inv(canXform*inv(s(ii).imToScanXform));
end

disp(['Aligning images to the first series "' s(1).seriesDescription '"...']);
s(1).xformToFirst = inv(s(1).imToScanXform);
Vfirst.uint8 = uint8(round(mrAnatHistogramClip(double(s(1).imData),0.3,0.99).*255));
Vfirst.mat = s(1).imToScanXform;

for(ii=2:nSeries)
    Vin.uint8 = uint8(round(mrAnatHistogramClip(double(s(ii).imData),0.3,0.99).*255));
    Vin.mat = s(ii).imToScanXform;
    evalc('transRot = spm_coreg(Vfirst, Vin);');
    fprintf('Series %d (%s) alignment: trans = [%0.4f %0.4f %0.4f], rot = [%0.4f %0.4f %0.4f].\n',ii,s(ii).seriesDescription,transRot);
    % Vin.mat\spm_matrix(transRot(end,:))*Vfirst.mat
    s(ii).xformToFirst = inv(Vin.mat)*spm_matrix(transRot(end,:));
end

if(~isempty(refImg))
    if(ischar(refImg))
        refImg = niftiRead(refImg);
    end
    disp(['Aligning first image to the template image in ' refImg.fname '...']);
    img = double(refImg.data);
    Vref.uint8 = uint8(round(mrAnatHistogramClip(img,0.4,0.98).*255));
    Vref.mat = refImg.qto_xyz;
    if(isempty(outMm)) 
        outMm = refImg.pixdim([1:3]); 
    end
    
    if(numel(bb)~=6)
        if(bb)
            bb = mrAnatXformCoords(Vref.mat, [1 1 1; size(img)]);
        else
            bb = mrAnatXformCoords(Vref.mat, [1 1 1; size(s(1).imData)]);
        end
    end
        
    % Align to ref
    evalc('transRot = spm_coreg(Vref, Vfirst);');
    fprintf('Ref alignment: trans = [%0.4f %0.4f %0.4f], rot = [%0.4f %0.4f %0.4f].\n',transRot);
    % Vin.mat\spm_matrix(transRot(end,:))*Vfirst.mat
    disp('Resampling all series...');
    % Now resample
    for(ii=1:nSeries)
        fprintf('   resampling series %d...\n',ii);
        xf = s(ii).xformToFirst*spm_matrix(transRot(end,:));
        [s(ii).imData,s(ii).imToScanXform] = mrAnatResliceSpm(double(s(ii).imData), xf, bb, outMm, interp, 0);
    	s(ii).mmPerVox = outMm;
    end
else
    % No ref image- just resample everything to be aligned to the first
    % series and at outMm voxel size.
    if(numel(bb)~=6)
        bb = mrAnatXformCoords(Vfirst.mat, [1 1 1; size(s(1).imData)]);
    end
    if(isempty(outMm))
        outMm = s(1).mmPerVox;
    end
    disp('Resampling all series...');
    for(ii=1:nSeries)
        [s(ii).imData,s(ii).imToScanXform] = mrAnatResliceSpm(double(s(ii).imData), s(ii).xformToFirst, bb, outMm, interp, 0);
    	s(ii).mmPerVox = outMm;
    end
end
xform = s(1).imToScanXform;

return;


