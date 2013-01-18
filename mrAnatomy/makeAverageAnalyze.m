function makeAverageAnalyze(ifileDirs, outBaseName)
% makeAverageAnalyze(ifileDirs, [outBaseName])
%
% Converts the Ifiles found in the ifileDirs cell array into analyze-format
% files stored in outDir (defaults to pwd). Will also try to launch
% the FSL coregistration algorithm (FLIRT) to coregister multiple volumes, then
% averages them and saves the averaged, coregistered dataset in analyze format.
%
% REQUIRES:
%  * Stanford anatomy tools (eg. /usr/local/matlab/toolbox/mri/Anatomy)
%  * spm99 tools (eg. /usr/local/matlab/toolbox/mri/spm99)
%  * FSL FLIRT executable (assumed to be /usr/local/fsl/bin/flirt)
%
% HISTORY:
% 2002.05.10 RFD (bob@white.stanford.edu) wrote it.
% 2004.06.17 RFD & MBS: Major change- now uses spm2 functions for
%            coregistration & reslicing.

if(~exist('outBaseName','var') | isempty(outBaseName))
    outBaseName = fullfile(pwd, 'analyze');
end

% Create Analyze-format files
%
figure;
for(ii=1:length(ifileDirs))
    fname{ii} = [outBaseName, '_', num2str(ii)];
    img = makeAnalyzeFromIfiles(fullfile(ifileDirs{ii},'I'), fname{ii});
    img = double(img);
    m = makeMontage(img, [10:4:size(img,3)-10]);
    % histogram-based clipping
    [count,value] = hist(m(:),100);
    clipVal = value(min(find(cumsum(count)./sum(count)>=0.99)));
    m(m>clipVal) = clipVal;
    subplot(length(ifileDirs),1,ii);
    imagesc(m); axis image; colormap gray;
    title(['Image # ' num2str(ii) ' (from ' fname{ii} ')']);
    fname{ii} = [fname{ii} '.img'];
end

resp = inputdlg('Which images to average?', 'Select Average List', 1, {num2str([1:length(fname)])});
keepers = str2num(resp{1});
if(~isempty(keepers))
    fname = {fname{keepers}};
    averageAnalyze(fname, [outBaseName,'_avg']); 
end

return;

pNum = round(size(img)./2);
% HARD-CODED CLIP VALUES
img(img>11000) = 11000;
img(img<2000) = 2000;
img = img-min(img(:));
%p = zeros(max(size(img)),max(size(img)),3);
figure(2);
subplot(2,2,1); imagesc(squeeze(img(pNum(1),:,:))); colormap(gray); axis image; axis off;
subplot(2,2,2); imagesc(squeeze(img(:,pNum(2),:))); colormap(gray); axis image; axis off;
subplot(2,2,3); imagesc(squeeze(img(:,:,pNum(3)))); colormap(gray); axis image; axis off;
subplot(2,2,4); hist(img(:),100);