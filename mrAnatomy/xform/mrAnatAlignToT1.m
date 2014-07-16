function [xform,acpcXform] = mrAnatAlignToT1(t1Align, t1Ref, intensityNorm, figNum)
%
% [xform,acpcXform] = mrAnatAlignToT1(t1Align, t1Ref, [intensityNorm=true], [figNum=99]);
%
% Compute an xform 
%
% The inplanes and functionals should be stored in NIFTI format with a
% standard qto_xyz xform that specified how to align them to the t1.
%
% rfd & ras, 10/08.
if notDefined('t1Align') || notDefined('t1Ref')
	error('Need 2 whole-brain volumes or file names.')
end

if notDefined('intensityNorm')
	intensityNorm = true;  % set to true if t1_align was acquired with a surface coil
end

if notDefined('figNum')
	figNum = 99;           % 0 will disable output figures.
end

estParams.cost_fun = 'nmi';
estParams.sep = [4 2];
estParams.tol =  [2e-2 2e-2 2e-2 1e-3 1e-3 1e-3 1e-2 1e-2 1e-2 1e-3 1e-3 1e-3];
estParams.fwhm = [7 7];

if(ischar(t1Align)), 
	% is it NIFTI or a directory of DICOMs?
	[p f ext] = fileparts(t1Align);
	if ismember( lower(ext), {'.nii' '.gz'} )
		t1Align = niftiRead(t1Align); 
	else
		% assume DICOM dir
        s = dicomLoadAllSeries(t1Align);
        if(strcmpi(s.phaseEncodeDir,'ROW')), fpsDim = [2 1 3];
        else fpsDim = [1 2 3]; end
        TR = s.TR/1000;
        t1Align = niftiGetStruct(s.imData, s.imToScanXform, 1, s.seriesDescription, [], [], fpsDim, [], TR);
	end
end
%t1Align = niftiApplyCannonicalXform(t1Align);

[t1RefImg,t1RefMm] = readVolAnat(t1Ref);

src.uint8 = uint8(mrAnatHistogramClip(double(t1RefImg), 0.4, 0.99)*255+0.5);
src.mat = mrAnatXform(t1RefMm,size(t1RefImg),'vanatomy2acpc');

alignImg = double(t1Align.data);
if(intensityNorm)
    % intensity estimation
    [intGrad, noise] = regEstFilIntGrad(alignImg);
    % intensity normalization
    alignImg = regCorrIntGradWiener(alignImg, intGrad, noise);
    % robust mean and contrast normalization
    alignImg = regCorrContrast(alignImg,4);
end
dst.uint8 = uint8(mrAnatHistogramClip(alignImg, 0.4, 0.99)*255+0.5);
dst.mat = t1Align.qto_xyz;
if(figNum>0)
  figure(figNum);
  dtiShowAlignFigure(figNum, dst, src, [], [], ['initial align']);
end

if prefsVerboseCheck
    transRot = spm_coreg(src,dst,estParams);
else
    % suppress the verbose optimizer output.
    msg = evalc('transRot = spm_coreg(src,dst,estParams);');
end

acpcXform = spm_matrix(transRot(end,:))*src.mat;
src.mat = acpcXform;
if(figNum>0)
  figure(figNum);
  dtiShowAlignFigure(figNum, dst, src, [], [], ['final align']);
end

%% compute the final transform
% the acpcXform is just the adjustment for the source matrix after the
% saved alignment info has been applied. Combine these to get the final
% matrix:
xform = inv(dst.mat) * src.mat;

return



