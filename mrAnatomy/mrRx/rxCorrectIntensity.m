function [interp, ref] = rxCorrectIntensity(interp,ref);
%
% [interp, ref] = rxCorrectIntensity(interp,ref);
%
% Given two image volumes, interp and ref, perform
% the intensity-correction steps used by mrAlign to 
% compare them, relatively free of differences caused
% by mean and contrast differences.
%
% ras 02/05.

% % mask out low value parts
% thresh = 0.1*(max(ref(:))-min(ref(:)));
% ref(ref<thresh) = 0;
% thresh = 0.1*(max(interp(:))-min(interp(:)));
% interp(interp<thresh) = 0;

verbose = 0;

% mrAlign parts
Limit = 4;
IntFunc = 'regEstFilIntGrad'; PbyPflag = 0;

if size(ref,3) > 1
    % for the purpose of having a single
    % interpolated slice, this is unnecessary,
    % but keep it for down the line...
    verbose = 1;
    hwait = mrvWaitbar(0,'Correcting For Intensity Differences...');
    ref = regCorrMeanInt(ref);
	mrvWaitbar(1/6,hwait);
end

% intensity estimation
[Int Noise] = feval(IntFunc, ref, PbyPflag); 
if verbose, mrvWaitbar(2/6,hwait); end

% intensity normalization
ref = regCorrIntGradWiener(ref, Int, Noise);
if verbose, mrvWaitbar(3/6,hwait); end

% robust mean and contrast normalization
ref = regCorrContrast(ref,Limit); 
if verbose, mrvWaitbar(4/6,hwait); end

% intensity estimation
[IntM NoiseM] = feval(IntFunc, interp, PbyPflag);
if verbose, mrvWaitbar(5/6,hwait); end

% intensity normalization
interp = regCorrIntGradWiener(interp, IntM, NoiseM);
if verbose, mrvWaitbar(1,hwait); end

% robust mean and contrast normalization
[interp, pM] = regCorrContrast(interp,Limit); 
if verbose, close(hwait); end

return

