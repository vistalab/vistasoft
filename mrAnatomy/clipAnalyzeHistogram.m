function s=clipAnalyzeHistogram(inFile,outFile,clipRange,includeBG)
% s=clipAnalyzeHistogram(inFile,[outFile],[clipRange],[includeBG])
% 
% PURPOSE: Clips and rescales the values in an Analyze image.
% INPUTS: inFile: File name to process
%         outFile: Output file name (Optional: defaults to
%         [inFile,'_clipped']
%         clipRange: Range of values to clip. This is a 2x1 vector
%                   containing 2 percentage values. These are the low
%                   and high ends of the intensity histogram that we 
%                   will clip. In fact, the low value >excludes< the 
%                   large peak due to values outside the skull. 
%                   Optional. Defaults to [5 95] 
%         includeBG: Flag (0 or 1 : Default 0). If set, the histogram 
%                   calculations (see above) will include the large peak
%                   due to the background. 
% OUPUT: outFile: The output file is saved in Analyze format
% HISTORY: ARW 100202: Wrote it
% $Author: wade $
% $Date: 2002/10/02 19:49:04 $

% Check inputs
if (~exist('inFile','var'))
    error('Must enter an input Analyze filename root');
end
 
if (~exist('outFile','var'))
    outFile=[inFile,'_clipped'];
end

if (~exist('clipRange','var'))
    clipRange=[5 98]; % Clip in the 5 to 98% range by default
end

clipRange=clipRange(:);
clipRange(clipRange>100)=100;
clipRange(clipRange<0)=0;

if (length(clipRange)~=2)
    error('clipRange must be a 2x1 vector');
end

if (~exist('includeBG','var'))
    includeBG=0; % Off by default
end

% Read in the spm volume
V=spm_vol(inFile);
[img]=spm_read_vols(V);

% We calculate histograms on a sub-sampled version of the original image to
% speed things up...

nSubVox=128000;
voxIndices=fix(linspace(1,length(img(:)),nSubVox));

smallImg=img(voxIndices);
% 
% 
% minVal=min(img1(:));
% maxVal=max(img1(:));
% smImg1=smImg1-minVal;
% smImg1=smImg1/maxVal;
% img1=img1-minVal;
% img1=img1/maxVal;

% Set lowest x% to zero
lowPercentToCut=clipRange(1);
lHist=hist(smallImg(:),100);

if (includeBG)
    cumHist=cumsum(lHist(1:end));
else
    cumHist=cumsum(lHist(2:end));
end

loBins=find(cumHist<(nSubVox/100*lowPercentToCut));
loVal=0.01*length(loBins)

% Update img
img=img-loVal;
img(img<0)=0;
img=img/max(img(:));

% Also update smallImg - we still want to calculate another hist
smallImg=smallImg-loVal;
smallImg(smallImg<0)=0;
smallImg=smallImg/max(smallImg(:));

% Now crop the highest x% as well...
hiPercentToCut=clipRange(2);
hiHist=hist(smallImg(:),100);
cumHist=cumsum(hiHist(2:end));
hiBins=find(cumHist<(nSubVox/100*hiPercentToCut));
hiVal=0.01*length(hiBins)
img=img./hiVal;
img(img>1)=1;
 

img=round(img*(2^15-1)); % Rescale to about 16 bits
V.fname=[outFile,'.img'];
s=spm_write_vol(V,img);


