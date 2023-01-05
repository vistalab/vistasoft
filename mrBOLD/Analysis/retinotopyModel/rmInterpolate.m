function model=rmInterpolate(view,model,params)
% rmInterpolate - interpolate missing values across the Gray surface
% that were not sampled with the coarse sampling
%
% model = rmInterpolate(view,model,params);
%
% 2007/03 SOD: wrote it.

if notDefined('view'),   error('Need view');   end;
if notDefined('model'),  error('Need model');  end;
if notDefined('params'), error('Need params'); end;

numNeighbors = double(view.nodes(4,:));
myzeros      = zeros(size(numNeighbors));
grayConMat   = [];

roiCoords = rmGet(params,'roiCoords');
if ~isempty(roiCoords),
    % find the index' that cover the roi
    doROI = true;
    inROI = rmGet(params,'roiIndex');
    % coords with data within roi
    coarseIndex     = rmCoarseSamples(roiCoords,params.analysis.coarseSample);
    withData        = logical(myzeros);
    withData(inROI(coarseIndex)) = true;

    % coords without data within roi
    toInterp        = logical(myzeros);
    toInterp(inROI(~coarseIndex)) = true;
else
    doROI    = false;
    coarseIndex     = rmCoarseSamples(viewGet(view,'coords'),params.analysis.coarseSample);
    % coords with data
    withData = coarseIndex;
    % coords without data
    toInterp = ~coarseIndex;
end;

% Sanity check: we only need interpolation if there are points to
% interpolate, e.g. very small ROIs will not be coarsely sampled.
if all(coarseIndex), % if all data points have estimates,
    return;
end;


% now we have to loop over models and parameters
%rp = {'x','y','s','rss','rawrss','x02','y02','s2','rss2','rawrss2', 'exponent','sigmamajor','sigmaminor'};
for n=1:numel(model),
    if strcmp(model{n}.description,'radial oval 2D pRF fit (x,y,sigma_major,sigma_minor)')
        rp = {'x','y','rss','rawrss','x02','y02','rss2','rawrss2', 'exponent','sigmamajor','sigmaminor','theta'};
    else
        rp = {'x','y','s','rss','rawrss','x02','y02','s2','rss2','rawrss2', 'exponent'};
    end

    % reset for different models (should be the same i think)
    fulval = myzeros;
    for p=1:numel(rp),
        val = rmGet(model{n},rp{p});
        if ~isempty(val) && numel(val)==sum(coarseIndex),
            % put data in full datastructure and fill the rest with zeros
            if doROI,
                fulval(inROI(coarseIndex)) = double(val);
            else
                fulval(coarseIndex)        = double(val);
            end;
            % now interpolate the data to some voxels without data
            %newval = myinterp(fulval,withData,toInterp,edges,numNeighbors,edgeOffsets);
            [newval grayConMat] = myinterp(fulval,withData,toInterp,view,grayConMat);
            % if roi we should store the roi voxels only otherwise store
            % the whole thing
            if doROI,
                model{n} = rmSet(model{n},rp{p},newval(inROI));
            else
                model{n} = rmSet(model{n},rp{p},newval);
            end;
        elseif ~isempty(val) && numel(val)==numel(fulval),
            model{n} = rmSet(model{n},rp{p},val);
        end;        
    end;
    if isfield(model{n}, 'exponent') && ~isempty(model{n}.exponent) && ~strcmp(model{n}.description,'radial oval 2D pRF fit (x,y,sigma_major,sigma_minor)')
        model{n} = rmSet(model{n}, 's', model{n}.sigma.major .* sqrt(model{n}.exponent));
    end
end;

% separate loop for the betas, because they are saved in a different way
for n=1:numel(model),
    % reset for different models (should be the same i think)
    fulval = myzeros;
    val = double(rmGet(model{n},'b'));
    nBetas  = size(val,3);
    newBeta = zeros(size(val,1),numel(coarseIndex),nBetas);

    for ii=1:nBetas,
        if doROI,
            fulval(inROI(coarseIndex)) = double(val(:,:,ii));
        else
            fulval(coarseIndex) = double(val(:,:,ii));
        end
        newval = myinterp(fulval,withData,toInterp,view,grayConMat);
        % if roi we should store the roi voxels only otherwise store
        % the whole thing
        if doROI,
            newBeta(:,:,ii) = newval(inROI);
        else
            newBeta(:,:,ii) = newval;
        end;
    end; 
    model{n} = rmSet(model{n},'b',newBeta);
end;

return;
%---------------------------------------


%---------------------------------------
function [val grayConMat] = myinterp(val,withData,toInterp,view,grayConMat)
% actual interpolation function

lzeros     = false(size(withData));
doTouch    = toInterp;  % keep refining these estimates
oldtoInterp = toInterp;  
while (1),
    % 'smooth' data. Points without data are zero and do contribute to this
    % initial estimate:
    [tmp grayConMat] = dhkGraySmooth(view,val,[1 1],grayConMat);
    
    % Now check which surrounding points had data, 0=no data in
    % neighborhood, 1=all neighbors have data, intermediate is the weight
    % that should have been used to create the new estimate and will be
    % used to remove the contributions of no-data neighbors (0).
    c2               = dhkGraySmooth(view,double(withData),[1 1],grayConMat);
    
    % All point that we want to interpolate (doTouch) that have neighbors
    % with data and that thus will have a new estimate.
    toInterp          = lzeros;
    toInterp(doTouch) = c2(doTouch)>0.001;

    % Compute new final values taking into account the number of points
    % that had data (c2)
    val(toInterp)     = tmp(toInterp)./c2(toInterp);
    
    % update toInterp: find voxels that still need interpolating
    toInterp       = (oldtoInterp-toInterp)>0;

    % sanity check: if no changes in toInterp than quit. Ideally
    % toInterp should go to zero but this does not have to be the
    % case if some voxels are not connected to voxels with data.
    if any(oldtoInterp-toInterp) || sum(toInterp)==0,
        break;
    else
        % 'grow' logical matrix that keeps track of which voxels have data
        withData       = toInterp | withData;
        % update
        oldtoInterp = toInterp;
    end;
end;

return;
%---------------------------------------


