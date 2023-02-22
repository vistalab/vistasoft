function [fdImg] = dtiComputeFiberDensityNoGUI(fiberGroups, xformImgToAcpc, imSize, normalize, fiberGroupNum, endptFlag, fgCountFlag, weightVec, weightBins)
%Compute fiber density from the command line.
%
% [fdImg] = dtiComputeFiberDensityNoGUI(fiberGroups, xformImgToAcpc,
% imSize, [normalize], [fiberGroupNum=1], [endptFlag], [fgCountFlag], [weightVec])
%
% Calculate how many fibers pass through each of the voxels. Return the
% values as a 3D image.
% 
% Input:
%   fiberGroups: an array of fiber groups
%   xformToAcpc: transformation matrix for img to acpc, i.e. dt.xformToAcpc
%   imSize: i.e. size(dt.b0)
%   normalize: 1 if you want fiber density normalized to one, 0 for fiber
%       counts. Default is fiber counts.
%   fiberGroupNum: list (vector) of indices pointing to the array elements in the 
%                  fiberGroups for fg(s) whose density you want to compute.
%                  E.g.: if fiberGroups array contains 10 fiber groups and
%                  you want to look at first two, use fiberGroupNum=[1 2].
%   endptFlag: 1 if you'd just like to use fiber endpoints
%   fgCountFlag: 1 if you input >1 FG and you'd like the function to return
%       the number of fiber groups passing through each voxel
%   weightVec: ?? 
%   weightBins: column 1 is lower bound, column 2 is upper bound, creates a
%       density image for each weight bin based on weightVec value for each
%       fiber, ignores weights that are not within the bins.
% 
% Example:
% [dt,t1] = dtiLoadDt6('dti30/dt6');
% fg = dtiReadFibers('dti30/fibers/someFibers.mat');
% fd =  dtiComputeFiberDensityNoGUI(fg, dt.xformToAcpc, size(dt.b0), 1, 1);
% fdT1 = mrAnatOverlayMontage(fd, dt.xformToAcpc, double(t1.img), t1.xformToAcpc, autumn(256), [1 10], [-20:2:50]);
% fdB0 = mrAnatOverlayMontage(fd, dt.xformToAcpc, mrAnatHistogramClip(double(dt.b0),.4,.98), dt.xformToAcpc, autumn(256), [1 10], [-20:2:50]);
%
% % To save the fiber density map in a NIFTI file: 
% dtiWriteNiftiWrapper(single(fd./max(fd(:))),dt.xformToAcpc,'someFibers');
%
% % To find the core of the fiber group, thresholded to a binary image:
% thresh = 0.1;
% fdCore = dtiCleanImageMask(fd./max(fd(:))>thresh), 2, 1);
% dtiWriteNiftiWrapper(uint8(fdCore),dt.xformToAcpc,'someFibersCore');
%
% See also: dtiComputeFiberDensity, dtiFiberGroupPropertyWeightedAverage

% HISTORY:
% 2003.12.18 RFD (bob@white.stanford.edu) wrote it.
% 2006.06.09 RFD: removed fiber density normalization in here. THis allows
% dtiAddBackground to do the normalization and save the original fiber
% counts so that we don't lose these values.
% 2006.11.07 AJS: separated gui from computation.
% 2009.11.15 JMT: added normalization as an option.
% 

% Programming Notes:
%
%  Probably we should return the normalizing variable so that we know
%  literally the number, not just the density.  At least this should be an
%  option.
%
%  We want to arrange the fiber density so that it is like a fiber group
%  that can be displayed using a hot map, say, and is shown on top of a T1
%  background image.
%

if(isempty(fiberGroups))
    error('No fiber groups.');
end

if ~exist('fiberGroupNum','var') || isempty(fiberGroupNum) 
   if length(fiberGroups)>1
    fiberGroupNum = dtiSelectFGs(h, 'Select fiber group(s) for density calculation');
   else
    fiberGroupNum=1; 
   end
end
if(any(fiberGroupNum>length(fiberGroups)))
    error('Invalid fiber group.');
end
if(~exist('normalize','var') || isempty(normalize))
    normalize = false;
end
if(~exist('endptFlag','var') || isempty(endptFlag))
    endptFlag = false;
end
if(~exist('fgCountFlag','var') || isempty(fgCountFlag))
    fgCountFlag = false;
end

% Used for the fgCount option- the count for a fiber group must be >=
% countThresh for that fg to be added to a bin.
countThresh = 1;

% don't try to process empty fiber groups
for ii=1:length(fiberGroupNum)
    if length(fiberGroups(fiberGroupNum(ii)).fibers)<1
        fiberGroupNum(ii) = NaN;
    end
end
fiberGroupNum = fiberGroupNum(~isnan(fiberGroupNum));

nFgs = length(fiberGroupNum);

fdImg = zeros(imSize);
xformAcpcToImg = inv(xformImgToAcpc);
for(ii=1:nFgs)
    nfibers = length(fiberGroups(fiberGroupNum(ii)).fibers);
    % transform fg coords to img space, round them, eliminate repeats
    % within each fiber
    for jj=1:nfibers
        fnodes=fiberGroups(fiberGroupNum(ii)).fibers{jj};
        fnodes_xformed = int32(round(mrAnatXformCoords(xformAcpcToImg,fnodes)));
        [uniquefnodes, m]=unique(fnodes_xformed,'rows', 'first'); %"unique' sorts output values
        fiberGroups(fiberGroupNum(ii)).fibers{jj}=fnodes_xformed(sort(m), :);
        clear fnodes uniquefnodes;
    end
    if(endptFlag)
        fc = zeros(nfibers*2, 3);
        for(jj=1:nfibers)
            fc((jj-1)*2+1,:) = [fiberGroups(fiberGroupNum(ii)).fibers{jj}(1, :)];
            fc((jj-1)*2+2,:) = [fiberGroups(fiberGroupNum(ii)).fibers{jj}(end, :)];
        end
    else
        totalNumFiberPts = sum(cellfun('size',fiberGroups(fiberGroupNum(ii)).fibers,1));
        if(totalNumFiberPts<1000000)
            fc = vertcat(fiberGroups(fiberGroupNum(ii)).fibers{:});
        else
            % We have to loop to avoid out-of-memory
            fc = zeros(totalNumFiberPts,3);
            cur = 1;
            for(jj=1:nfibers)
                npts = size(fiberGroups(fiberGroupNum(ii)).fibers{jj},1);
                fc(cur:cur+npts-1,:) = fiberGroups(fiberGroupNum(ii)).fibers{jj};
                cur = cur+npts;
            end
        end
    end
    % Put the fiber coords into a list of indices so that we can use 'hist'
    % to compute our density map. Implicit in this algorithm is that the
    % binning happens in the image grid (typically a 1mm grid). This also
    % assumes that the fiber points are spaced by the same amount as the
    % image grid (also typically 1mm). A more general purpose algorithm
    % might involve convolution.
    badCoords = any(fc<1,2)|(fc(:,1)>imSize(1)|fc(:,2)>imSize(2)|fc(:,3)>imSize(3));
    fc(badCoords,:) = [];
    fiberInds{ii} = sub2ind(imSize, fc(:,1), fc(:,2), fc(:,3));
end

for(ii=1:nFgs)
    nfibers = length(fiberGroups(fiberGroupNum(ii)).fibers);
    if ~notDefined('weightVec') && ~notDefined('weightBins')
        
        nbins = size(weightBins,1);
        fdImg = zeros([imSize nbins]);
        
        % We are going to use this stat to weight the counts so we cannot
        % use the histogram tool
        nIndCount = 1;
        for jj=1:nfibers
            npts = size(fiberGroups(fiberGroupNum(ii)).fibers{jj},2);
            weightVal = weightVec(jj);
            wbin = find( weightVal>weightBins(:,1) & weightVal<weightBins(:,2), 1, 'first' );
            
            if ~isempty(wbin) 
                tmpImg = zeros(imSize);
                for kk=1:npts
                    pixInd = fiberInds{ii}(nIndCount);
                    %tmpImg(pixInd) = tmpImg(pixInd) + weightVal;
                    tmpImg(pixInd) = tmpImg(pixInd) + 1;
                    nIndCount = nIndCount+1;
                end
                fdImg(:,:,:,wbin) = tmpImg;
            end
        end
    elseif 0 %~notDefined('weightVec') && ~notDefined('weightBins')
        %nbins = size(weightBins,1);
        %fdImg = zeros([imSize nbins]);
        %for bb=1:nbins
        %    inds = weigthVec > weightBins(bb,1) & weigthVec < weightBins(bb,2);
        %end
        
    else
        [count,val] = hist(fiberInds{ii}, [1:prod(imSize)]);
        if(fgCountFlag)
            % This option produces a count of the number of fiber groups that
            % had a fiber in this bin.
            fdImg(val) = fdImg(val)+(count>=countThresh);
        else
            % Otherwise, simply sum all the counts for a total density.
            fdImg(val) = fdImg(val)+count;
        end
        if normalize
            fdImg(val) = fdImg(val)/max(count);
        end
    end
end

return;