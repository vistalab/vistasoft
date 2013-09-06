function [volCc,dims] = mrAnatGetBrainVolume(brainMask)
%
% [volCc,dims] = mrAnatGetbrainVolume([brainMask=uigetfile])
%
% Returns the brain volume (in cubic centimeters) for the specified brain
% mask. Optionally also returns the left-right, anterior-posterior and
% superior-inferior dimensions (in centimeters) of the brain.
%
% If you don't have a brain mask, use mrAnatExtractBrain. 
%
% 2008.08.14 RFD wrote it.
% 2008.09.09 RFD fixed x,y bug in dims- the first two dims were flipped.

if(~exist('brainMask','var')||isempty(brainMask))
    [f,p] = uigetfile({'*.nii.gz';'*.*'},'Select a brain mask NIFTI file...');
    if(isnumeric(f)), disp('User canceled.'); return; end
    brainMask = fullfile(p,f); 
end

if(ischar(brainMask))
    % It's a nifti file
    brainMask = niftiRead(brainMask);
end

mm = brainMask.pixdim(1:3);
ccPerPixel = prod(mm)/1000;
volCc = numel(find(brainMask.data)) * ccPerPixel;

if(nargout>1)
    tmp = sum(brainMask.data,3);
    y = find(sum(tmp,1)); 
    y = [y(1) y(end)];
    x = find(sum(tmp,2)); 
    x = [x(1) x(end)];
    tmp = squeeze(sum(brainMask.data,1));
    z = find(sum(tmp,1)); 
    z = [z(1) z(end)];
    dims = [diff(x)*mm(1) diff(y)*mm(2) diff(z)*mm(3)];
    dims = dims./10;
end

return;


bd = '/biac3/wandell4/data/reading_longitude/dti_y1';
d = dir(fullfile(bd,'*04*'));
n = 0;
for(ii=1:numel(d))
    f = fullfile(bd,d(ii).name,'t1','t1_mask.nii.gz');
    if(exist(f,'file'))
        n = n+1;
        [volCc(n),dims(n,:)] = mrAnatGetBrainVolume(f);
        sc{n} = d(ii).name;
    end
end

[behData,colNames] = dtiGetBehavioralData(sc);

sexInd = strmatch('Sex (1=male)',colNames);
boys = behData(:,sexInd)==1;
fprintf('boys = %0.1fcc (%0.2f), girls = %0.1fcc (%0.2f)\n', mean(volCc(boys)), std(volCc(boys)), mean(volCc(~boys)), std(volCc(~boys)));

brInd = strmatch('Basic reading (W-J)',colNames);
necrosisControls = ~boys & behData(:,brInd)>=90;
mn = mean(volCc(necrosisControls));
sd = std(volCc(necrosisControls));

[sVol, sDims] = mrAnatGetBrainVolume('/biac1/wandell/data/radiationNecrosis/dti/al060406/t1/t1_mask.nii.gz');
% Compute the percentile:
[hcnt,hcent] = hist(volCc(necrosisControls),50);
pctile = sum(hcnt(find(sVol>hcent)))/sum(hcnt)*100;
fprintf('Controls: mean = %0.0fcc (%0.1f); S = %0.0fcc (%0.0f %%tile)\n', mn, sd, sVol, pctile);


