function dtiRawMakeVectorRgb(dt6File, outFileName)
%
% dtiRawMakeVectorRgb(dt6File, [outFileName='vectorRGB'])
%
% This function provides a fix for those vectorRGB.nii.gz files whose image
% values were wiped due to a bug in dtiRawPreprocess.m. 
%
% The user can run the fuction and select the dt6.mat file via the pop-up
% window or pass in the path to the dt6.mat. 
%
%
% History:
% 04/02/2009 RFD & LMP wrote the thing.
%

if(~exist('dt6File','var')||isempty(dt6File))
    [f,p] = uigetfile({'*.mat';'*.*'},'Select a dt6.mat file for input...');
    if(isnumeric(f)), disp('User canceled.'); return; end
    dt6File = fullfile(p,f); 
end

dt = dtiLoadDt6(dt6File);
binDir = fullfile(fileparts(dt.dataFile),'bin');

if(~exist('outFileName','var')||isempty(outFileName))
outFileName = fullfile(binDir,'vectorRGB.nii.gz');
end


[eigVec, eigVal] = dtiSplitTensor(dt.dt6);
eigVal(isnan(eigVal)|eigVal<0) = 0;
fa = dtiComputeFA(eigVal);
fa(isnan(fa)) = 0; fa(fa>1) = 1; fa(fa<0) = 0;

pdd = squeeze(eigVec(:,:,:,[1 2 3],1));
pdd(isnan(pdd)) = 0;
pdd = abs(pdd);

for(ii=1:3) 
    pdd(:,:,:,ii) = pdd(:,:,:,ii).*fa; 
end

dtiWriteNiftiWrapper(uint8(round(pdd.*255)), dt.xformToAcpc, outFileName, 1/255, '', 'PDD/FA');
showMontage(pdd);
disp(['The file ' outFileName ' was written successfully.']);

return;


