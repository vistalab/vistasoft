function newFg = dtiFiberMidSagSegment(fg,nPts,clipHemi)
% Takes a fiber goup and clips the fibers to nPts of the midSagital plane.
%
%  newFg = dtiFiberMidSagSegment(fg, [nPts=10], [clipHemi='both'])
% 
% If nPts is not passed in the default is 10. 
%
% The default is to clip both left and right sides (clipHemi='both'). If
% clipHemi=='left' then only the left side (i.e. fiber coords X < 0) is
% clipped. Alternately, you can ask for just the right side (X>0) to be
% clipped.
%
% History:
% 04/29/2009 LMP wrote the function based on code from RFD
% 10/20/2010 LMP Fixed a bug when clipping fibers to the right of the
%            midline. ALSO added a check for the coordinate order of the fibers and
%            made an assumption about the coordinate order when ind=>nPts on the LEFT. 
%
% (c) Stanford VISTA Team

if(~exist('fg','var') || isempty(fg))
    error 'You must pass in fiber group (fg) struct. Use dtiReadFibers.';
end

% The number of points to keep to each side of mid-sag
if(~exist('nPts','var') || isempty(fg))
    disp('Setting number of points to 10.');
    nPts = 10;
end
if(~exist('clipHemi','var') || isempty(clipHemi))
    clipHemi = 'b';
end
if(~ischar(clipHemi)||~ismember(clipHemi(1),'blr'))
    error('clipHemi must be a char array with the first letter b|l|r.');
end

% change to a simple code: left = -1, right = 1, both = 0
if    (lower(clipHemi(1))=='l'), clipHemi = -1;
elseif(lower(clipHemi(1))=='r'), clipHemi =  1;
else                             clipHemi =  0; 
end

if clipHemi == -1, disp('Clipping left...'); end
if clipHemi == 1,  disp('Clipping right...'); end
if clipHemi == 0,  disp('Clipping both left and right...'); end

% Clean the fibers. This will ensure there is only one point that crosses
% the midline.
fg = dtiCleanFibers(fg,[],250);

newFg = dtiNewFiberGroup(sprintf('%s_midSag%02d', fg.name, nPts));

% Now find the point closest to the midline for each fiber
n = 0;
for(ii=1:numel(fg.fibers))
    curFiber = fg.fibers{ii};
    % We only operate on the first row of fiber coords (left-right coord)
    midSagDist = abs(curFiber(1,:));
    nFiberPts  = numel(midSagDist);
    meanInd    = mean(curFiber(1,:));
    ind = find(midSagDist==min(midSagDist));
    % Ensure that the order of the fiber points is always left-to-right
    leftMeanCoord  = mean(curFiber(1,1:ind-1));
    rightMeanCoord = mean(curFiber(1,ind+1:end));
    if(leftMeanCoord>rightMeanCoord)
        % fiber coordinate order needs to be flipped
        curFiber   = fliplr(curFiber);
        midSagDist = fliplr(midSagDist);
        ind = find(midSagDist==min(midSagDist));
    elseif(leftMeanCoord==rightMeanCoord)
        % if we can't tell left from right, just skip it
        continue;
    end

    % Only assign the mid sag segment to fibers that have enough points to 
    % either side of the mid-sagittal plane and are within 1mm of the midline.
    try
        if clipHemi==-1 && ind<nPts % HACK: assumption made here is that when ind is > nPts the fiber coordinate order should be flipped.
            curFiber    = fliplr(curFiber);
            midSagDist  = fliplr(midSagDist);
            ind         = find(midSagDist==min(midSagDist));
        end
        if(clipHemi==0 && ind>nPts && ind<=nFiberPts-nPts && midSagDist(ind)<1.0)
            midSagInds = [ind-nPts:ind+nPts];
            n = n+1;
            newFg.fibers{n,1} = curFiber(:,midSagInds);
        elseif(clipHemi==-1 && ind>nPts && midSagDist(ind)<1.0)
            midSagInds = [ind-nPts:ind];
            n = n+1;
            newFg.fibers{n,1} = curFiber(:,midSagInds);
        elseif(clipHemi==1 && ind<=nFiberPts-nPts && midSagDist(ind)<1.0)
            midSagInds = [ind:ind+nPts];
            n = n+1;
            newFg.fibers{n,1} = curFiber(:,midSagInds);
        end
    catch ME
        % disp(ME);
    end

end
fprintf('dtiFiberMidSagSegment: %d fibers returned.\n',numel(newFg.fibers));

return

%     %Only assign the mid sag segment to fibers that have enough points (37-41)
%     if(midSagDist(ind)<1 && ind>nPts && ind<=nFiberPts-nPts)
%         midSagInds = [ind-nPts:ind+nPts];
%         newFg.fibers{ii,1} = fg.fibers{ii}(:,midSagInds);
%     end