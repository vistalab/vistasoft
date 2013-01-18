function val = dtiGetImageCoordsFromFibers(dt, fg)
%Obsolete
%
%  Returns the image coordinates of the fibers in fg
%
% WARNING:  Doesn't work.  See notes below.  Should be obsolete soon.
%
%  val = dtiGetImageCoordsFromFibers(dt, fg)
%
% The data in val are Nx3
%
% (c) Stanford VISTA Team

% Written by Sherbondy and Dougherty.  It doesn't seem to do what it says. 
% It is not called by any other functions. We need a function that does
% just this properly.  It should be inside of dtiGet(), I think.

error('Obsolete %s\n',mfilename)

return

% Here are the coords
coords = horzcat(fg.fibers{:})';
coords = unique(round(mrAnatXformCoords(inv(dt.xformToAcpc),coords)),'rows');

% Here are the tensors as 6-vectors
inds = sub2ind(size(dt.dt6(:,:,:,1)),coords(:,1),coords(:,2),coords(:,3));
vecDt6 = zeros(size(coords,1),6);
for ii=1:6
    temp = dt.dt6(:,:,:,ii);
    vecDt6(:,ii) = temp(inds);
end

% These statistics should be computed based on nargout.  
[eigVec, eigVal] = dtiEig(vecDt6);
l2 = eigVal
[fa,md,rd] = dtiComputeFA(eigVal);
[cl, cp, cs] = dtiComputeWestinShapes(eigVal);

return