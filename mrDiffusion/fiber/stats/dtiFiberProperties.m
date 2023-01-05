function [sfgProperties, partialVolumeImg] = dtiFiberProperties(fg, dt, roi, fiberDiameter)
%Computes several properties of fibers in a fiber subgroups
%
%   [sfgProperties, partialVolumeImg] = ...
%         dtiFiberProperties(fg, dt, [roi], [fiberDiameter])
%
% N.B. The fiber subgroup concept needs explanation in more places
% throughout the code.  It was an ER concept inserted without much planning
% or object structures, and never communicated clearly to all the other
% people using the code.  It has no object methods (e.g.,
% sfgGet/Set/Create) and thus the code is hard to read. This is one place
% where we could do better. (BW)
%
% Reports fiber length, numfibers, fa, md, axial d, rd, linearity,
% planarity and fiber group volume. Encapsulates and adds to the
% functionality from dtiFiberSummary/dtiFiberSummaryNOGUI.
%
% If 'roi' parameter is provided, then the fiber properties will be
% computed over the portion of the fiber group limited to that ROI. Fiber
% count (numberOfFibers) will not change.
%
% Length reported will refer to the average length of the fiber segments
% limited by the ROI (computed using a very crude approximation).  (BW - I
% don't understand this).
%
% If no 'fiberDiameter' input parameter is provided, then the volume of the
% fiber group is estimated by counting unique voxels occupied by this fiber
% group. If several fiber groups share same voxels, these voxels will
% partially contribute to the respective subgroup volume estimates
% (contribution amount reflects the number of fibers in each subgroup).
% Otherwise, if fiberDiameter is provided, the volume is computed by
% representing the fibers as tubes with the corresponding fiberDiameter.
% The value for fiberDiameter may come from dtiCullFibers as
% Tt+distanceCrit, or from parameters used when running Blue Matter. For
% the volume measure given fiberDiameter to be meaningful, the fiber group
% is expected to have no duplicates (duplicates are defined as two fibers
% with fiber-to-fiber distance (distance metrics vary) less than
% fiberDiameter). To remove the duplicates, use dtiCullFibers or density
% regularization using Blue Matter.
%
% Output:
% sfgProperties  - a structure with properties for each subgroup of
%    fibers specified in fg.subgroup field. The first element of the
%    structure refers to all the fibers (the union of the fiber subgroups).
%    The second element refers to the first subgroup, etc. The properties
%    reported in the structure: numberOfFibers, fiberLength, FA, MD,
%    axialADC, radialADC, linearity, planarity, fiberGroupVolume
%
% PartialVolumeImg - 4D image with maps of partial volume contribution
%     across fiber groups (identified with fg.subgroup). If fiberDiameter
%     was specified, these maps are NOT computed. (TODO: think if it makes
%     sense to). To save ouput partial volume maps as 4D image
%        dtiWriteNiftiWrapper(double(partialVolumeImg), ...
%        t1.qto_xyz, partialVolumeMapsFilename) ;

% HISTORY:
% 12/8/2008 ER wrote it (code pulled from dtiFiberSummary)
% 01/29/2008 ER (1) added an option to compute properties of a PORTION
%            (instead of the whole length) of a fiber within an interval
%             limited by an ROI in 3D space.
%            (2) added an option to report fiber properties computed
%            separately for different subgroups (if the FG passed has
%            "subgroups" field); (3) Changed output format to return a
%            structure, not a set of variables.
% 04/2009 ER updated volume computation. Note: input parameter has changed
%            from distanceCrit (above-threshold distance) to fiberDiameter
%            (threshold+above-threshold distance)
% 04/2009 ER made fiberDiameter optional: if not supplied, the value is
%             determined from the culling parameters saved with culled fg,
%             or a default value of 1 is offered.
% 11/2009: ER updated the volume computation to be a function of pathway
%             arclegth & diameter
% 01/2010: ER revised the situation with no diberDiameter supplied:
%             by default, the volume is now estimated by counting unique voxels.
%             Correction for partial volume effects included.
% Elena (c) Stanford VISTASOFT 2012

%% Check variables
if(~exist('fiberDiameter', 'var')|| isempty(fiberDiameter))
    if(isfield(fg, 'cullingParams'))
        fiberDiameter=fg.cullingParams{2}+fg.cullingParams{4};
        fprintf('Using the value of fiber diameter saved in fg.cullingParams d=%f \n', fiberDiameter);
        %Note: culling (dtiCullFibers) with default parameters Tt=1; distanceCrit=1
        %would produce fibers with fiberDiameter=2.
    else
        %Use volume approximation by counting unique voxels occupied by the
        %fiber group.
        fiberDiameter=NaN;
        fprintf('Using volume approximation by counting unique voxels occupied by the fibergroup \n');
    end
    
end

if (~exist('roi', 'var')|| isempty(roi))
    roi.coords=[]; %Empty ROI will suggest that ROI includes the FG fully. The truly empty ROI parameter case is treated below--aborting the function
elseif isempty(roi.coords);
    error('ROI you passed is empty');
else %Roi has been passed in and it is not empty
    %need to trim the fibers that dont even cross the ROI anyways
    fg  = dtiIntersectFibersWithRoi([], 'and', 1, roi, fg);
    if isempty(fg.fibers)
        error('The fibergroup does not pass through this ROI');
    end
end

%% This function runs over fiber subgroups.
% The subgroup concept needs explanation in more places throughout the
% code.  It was an ER concept that was inserted without much planning or
% object structures, and never communicated clearly to all the other people
% using the code.  It has no object methods (e.g., sfgGet/Set/Create) and
% thus the code is hard to read.
%
% The fiber group manipulations  be via fgGet rather than this stuff.

if (~isfield(fg, 'subgroup'))
    fg.subgroup=ones([1 length(fg.fibers)]);
end
sgInds=unique(fg.subgroup);
nfg = numel(sgInds);
fgName=fg.name;

%For subgroups - Good example of a comment that doesn't help much.
% Better would be:
%  Calls the workhorse function dtiSubFGProperties for each of the
%  subgroups.  That function is in this file, below.
% This function should preallocate the sizes of the structures.
for subgroupID=1:nfg
    sfg.fibers=fg.fibers(fg.subgroup==sgInds(subgroupID));
    
    if ~isfield(fg, 'subgroupNames')
        subgname=sprintf('%s_%02d',fg.name,subgroupID);
    else
        subgname=[fg.name '--' fg.subgroupNames(vertcat(fg.subgroupNames.subgroupIndex)==sgInds(subgroupID)).subgroupName];
    end
    sfgProperties(subgroupID+1).name = subgname;
    
    fprintf('Computing properties for %s\n', subgname);
    [sfgProperties(subgroupID+1).numberOfFibers, ...
        sfgProperties(subgroupID+1).fiberLength, ...
        sfgProperties(subgroupID+1).FA, sfgProperties(subgroupID+1).MD, ...
        sfgProperties(subgroupID+1).axialADC, sfgProperties(subgroupID+1).radialADC, ...
        sfgProperties(subgroupID+1).linearity, sfgProperties(subgroupID+1).planarity] = ...
        dtiSubFGProperties(sfg, dt, roi);
end

%% FIBER VOLUME
% Compute the volume of fg.fibers in each subgroup while removing partial
% volume contribution by other fibers in fg. In case fiberDiameter is
% provided we assume the fibers are density-regularized (or culled) hence
% no partial volume correction is needed. In case no fiber Diameter is
% provided, we will output maps of partial volume.

if ~isnan(fiberDiameter)
    % fiber diameter is specified.  What units?
    for subFgID = 1:nfg
        if isempty(roi.coords)
            sfgProperties(subFgID+1).fiberGroupVolume=sum(cellfun(@arclength, fg.fibers(fg.subgroup==subFgID)))*pi*(fiberDiameter/2)^2;
        else
            sfgProperties(subFgID+1).fiberGroupVolume=(sfgProperties(subFgID+1).fiberLength(2)*numberOfFibers)*pi*(fiberDiameter/2)^2;
        end
    end
    partialVolumeImg=NaN;
else
    % In case fiberDiameter is not provided as input parameter, we need to
    % recompute volume to properly treat patial volume effects. (Hunh? BW).
    if nfg>1
        fg = dtiFiberGroupToFgArray(fg);
    end
    t1 = niftiRead(dt.files.t1);
    
    for iF=1:length(fg)
        [fdImg(:, :, :, iF)] = dtiComputeFiberDensityNoGUI(fg, t1.qto_xyz, t1.dim, 0, iF);
    end
    
    if ~isempty(roi.coords) %Drop the coordinates that are not within the ROI.
        bb = mrAnatXformCoords(t1.qto_xyz, [ 1 1 1; t1.dim]);
        roiImg = dtiRoiToImg(roi.coords, t1.qto_xyz, bb);
        for iF=1:length(fg)
            [fdImg(:, :, :, iF)] = fdImg(:, :, :, iF).*roiImg;
        end        
    end
    
    % fdImg(fdImg<5)=0; %disregard for volume comps voxels that have only 5 or less fibers going thru them
    
    partialVolumeImg=zeros(size(fdImg));
    fdImgTotal=sum(fdImg, 4);
    for iF=1:length(fg)
        partialVolumeImg(:, :, :, iF)=fdImg(:, :, :, iF)./fdImgTotal;
        partialVolumeImg(isnan(partialVolumeImg))=0;
        k=sum(partialVolumeImg(:,:, :, iF));
        sfgProperties(iF+1).fiberGroupVolume=sum(k(:));
    end
    
end

if length(fg)>1 
    %Fg is an array, no subgroups.  (???, BW)
    %Properties for all the fibers combined across the subgroups
    fg = dtiFgArrayToFiberGroup(fg, fgName);  %this code is redundant and needs to be cleaned up
    sfgProperties(1).name=fg.name;
    fprintf('Computing properties for all fibers combined \n');
    [sfgProperties(1).numberOfFibers, sfgProperties(1).fiberLength, sfgProperties(1).FA, sfgProperties(1).MD, sfgProperties(1).axialADC, sfgProperties(1).radialADC, sfgProperties(1).linearity, sfgProperties(1).planarity] = dtiSubFGProperties(fg, dt, roi);
    sfgProperties(1).fiberGroupVolume=sum(vertcat(sfgProperties(2:end).fiberGroupVolume)); %Volume of "all fibers" is a sum of subgroup volume
else
    %Move your only su-fg result from sfgID+1 to 1.
    sfgProperties(1)=sfgProperties(2);
    sfgProperties(2)=[];
end
end %function

%% Why isn't this a separate function?   And why does it have this format?
% It is only called inside of this function.
function [numberOfFibers, fiberLength, FA, MD, axialADC, radialADC, linearity, planarity] = dtiSubFGProperties(fg, dt, roi)

numberOfFibers=length(fg.fibers);
fiberLength=NaN(1, 3);

% Measure the step size of the first fiber. They *should* all be the same!
stepSize = mean(sqrt(sum(diff(fg.fibers{1},1,2).^2)));

coords = horzcat(fg.fibers{:})';
if ~isempty(roi.coords)
    %Limit the coordinates of FG to those within roi passed as an argument --
    %CRUDE (no nearpoints or anything used
    [c, ia, ib] = intersect(round(coords), round(roi.coords),'rows');
    coords=coords(ia, :);
    fiberLength(2) = length(coords)/numel(fg.fibers)*stepSize; %Approximation, of course.
else
    %Actually estimate the range of length for the fibers, as well
    fiberLengths = cellfun('length',fg.fibers);
    fiberLength(2) = mean(fiberLengths)*stepSize;
    fiberLength(1) = min(fiberLengths)*stepSize;
    fiberLength(3) = max(fiberLengths)*stepSize;
end

%The rest of the computation does not require remembering which node
%belongs to which fiber.
[val1,val2,val3,val4,val5,val6] = ...
    dtiGetValFromTensors(dt.dt6, coords, inv(dt.xformToAcpc),'dt6','nearest');
dt6 = [val1,val2,val3,val4,val5,val6];


% Clean the data in two ways.
% Some fibers extend a little beyond the brain mask. Remove those points by
% exploiting the fact that the tensor values out there are exactly zero.
dt6 = dt6(~all(dt6==0,2),:);

% There shouldn't be any nans, but let's make sure:
dt6Nans = any(isnan(dt6),2);
if(any(dt6Nans))
    dt6Nans = find(dt6Nans);
    for ii=1:6
        dt6(dt6Nans,ii) = 0;
    end
    fprintf('\ NOTE: %d fiber points had NaNs. These will be ignored...',length(dt6Nans));
    disp('Nan points (ac-pc coords):');
    for ii=1:length(dt6Nans)
        fprintf('%0.1f, %0.1f, %0.1f\n',coords(dt6Nans(ii),:));
    end
end

% We now have the dt6 data from all of the fibers.  We extract the
% directions into vec and the eigenvalues into val.  The units of val are
% um^2/sec or um^2/msec ... somebody answer this here, please.

[vec,val] = dtiEig(dt6);

% Tragically, some of the ellipsoid fits are wrong and we get negative eigenvalues.
% These are annoying. If they are just a little less than 0, then clipping
% to 0 is not an entirely unreasonable thing. Maybe we should check for the
% magnitude of the error?
nonPD = find(any(val<0,2));
if(~isempty(nonPD))
    fprintf('\n NOTE: %d fiber points had negative eigenvalues. These will be clipped to 0...\n',length(nonPD));
    val(val<0) = 0;
end

threeZeroVals=find(sum(val, 2)==0);
if ~isempty (threeZeroVals)
    fprintf('\n NOTE: %d of these fiber points had all three negative eigenvalues. These will be excluded from analyses\n', length(threeZeroVals));
end

val(threeZeroVals, :)=[];

% Now we have the eigenvalues just from the relevant fiber positions - but
% all of them.  So we compute for every single node on the fibers, not just
% the unique nodes.

[fa,md,rd,ad] = dtiComputeFA(val);

%Some voxels have all the three eigenvalues equal to zero (some of them
%probably because they were originally negative, and were forced to zero).
%These voxels will produce a NaN FA

FA(1)=min(fa(~isnan(fa))); FA(2)=mean(fa(~isnan(fa))); FA(3)=max(fa(~isnan(fa))); %isnan is needed  because sometimes if all the three eigenvalues are negative, the FA becomes NaN. These voxels are noisy.
MD(1)=min(md); MD(2)=mean(md); MD(3)=max(md);
radialADC(1)=min(rd); radialADC(2)=mean(rd); radialADC(3)=max(rd);
axialADC(1)=min(ad); axialADC(2)=mean(ad); axialADC(3)=max(ad);

[cl, cp] = dtiComputeWestinShapes(val); %Linearity, Planarity, ...
linearity(1)=min(cl); linearity(2)=mean(cl); linearity(3)=max(cl);
planarity(1)=min(cp); planarity(2)=mean(cp); planarity(3)=max(cp);

end

%% Sigh.  BW
function [arcL] = arclength(fc)
arcL = sum(sqrt(sum((fc(:,2:end) - fc(:,1:end-1)).^2,1)));
end
