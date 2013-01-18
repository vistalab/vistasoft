function c=rmCoarseSamples(coords,whichmethod)
% rmCoarseSamples - coarsely sample volume (coordinates structure);
%
%  coarseIndex=rmCoarseSamples(coords,whichmethod);
%
% Inputs:
%  coords: (3,n) coordinate matrix
%  whichmethod: 
%     0: all coords, 
%     1: every other (odd and even) 
%        maximum distance to estimated point (1 voxel)
%     other: every other point
%        maximum distance to estimated point (sqrt(3*other.^2)/2 voxel)
%     
%
% 2007/03 SOD: wrote it.

if notDefined('coords'),
  error('Need coords variable');
end;

% don't bother for very small ROIs
if size(coords,2) < 50 || whichmethod==0,
  c = true(1,size(coords,2));
  return;
end;

% switch to type double
coords = double(coords);

if whichmethod==1,
    % every point is included if x&y&z = even|odd
    c=logical(prod(rem(coords,2)) + prod(rem(coords+1,2)));
else
    % every 
    count = 0;
    for n=0:whichmethod,
        % every 'whichmethod' point
        tmp=logical(prod(single(rem(coords+n,whichmethod)==0)));
        % although the sampling distance may be the same we choose the starting
        % coordinate based on which gives the most hits.
        if count<sum(tmp),
            c=tmp;
            count=sum(tmp);
        end
    end
end
    
% sanity check
if ~sum(c),
  c = true(1,size(coords,2));
end

return;
