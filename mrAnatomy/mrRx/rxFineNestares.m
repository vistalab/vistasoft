function rx = rxFineNestares(rx);
%
% rx = rxFineNestares(rx);
%
% Perform a fine alignment using Oscar Nestares' [99 ref?]
% registration code.
%
% ras 08/05
if ieNotDefined('rx')
    cfig = findobj('Tag','rxControlFig');
    rx = get(cfig,'UserData');
end

h = msgbox('Using Nestares Code to Compute Alignment...');

% build an interpolated volume to compare to
% the reference volume:
for slice = 1:rx.refDims(3)
    rxVol(:,:,slice) = rxInterpSlice(rx,slice);
end

%%%%%params
coarseIterations = 4; % number of coarse iterations
gradFunction = 'regEstFilIntGrad'; % func. to estimate intensity gradient
pbyp = 0;  % Plane by Plane flag = 0 (=>works globaly)
xform = rx.xform;
A = xform(1:3,1:3);
b = xform(1:3,4)';
scaleFac(1,:) = 1./rx.rxVoxelSize;  % inverse voxel size for reference and
scaleFac(2,:) = 1./rx.volVoxelSize; % prescribed volumes
rot = diag(1./scaleFac(2,:))*A*diag(scaleFac(1,:)); % rot matrix
trans = b ./ scaleFac(2,:);         % translation factors

%%%%%registering
% ensure the volumes are double-precision: the Nestares code requires this
if ~isa(rx.vol, 'double')
	rx.vol = double(rx.vol);
end

if ~isa(rx.ref, 'double')
	rx.ref = double(rx.ref);
end

% go
[rot, trans, Mf] = regVolInp(rx.vol, rx.ref, scaleFac, rot, trans, ...
							 coarseIterations, gradFunction, pbyp);   

%%%%% convert into a 4x4 affine xform matrix
A = diag(scaleFac(2,:))*rot*diag(1./scaleFac(1,:));
b = (scaleFac(2,:).*trans)';

newXform = zeros(4,4);
newXform(1:3,1:3)=A;
newXform(1:3,4)=b;
newXform(4,4)=1;

% % apply on top of existing xform
% newXform = newXform * rx.xform;

% set in rx struct and mark the settings
rx = rxSetXform(rx, newXform);

rxStore(rx,'Nestares Align');

close(h)

return