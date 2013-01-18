function interpVol = interpInplanes(view,vAnatPath);
%
% interpVol = interpInplanes(view,[vAnatPath]);
%
% Return a volume the same size as a mrVista view's
% anat field, with 'interpolated inplanes' taken
% from the specified volume anatomy, based on the 
% currently-loaded alignment.
%
% if the vAnatPath isn't specified, it will try
% to use the global vANATOMYPATH variable.
%
% Uses Rory's mrRx tools. There is a similar mrAlign
% function, regInplanes, but it requires many more
% inputs and a bestrotvol.mat file, which we may
% not want to keep around in future iterations of the
% software.
%
% ras, 05/05
mrGlobals;

if ieNotDefined('view')
    view = getSelectedInplane;
end

if ieNotDefined('vAnatPath')
    vAnatPath = vANATOMYPATH;
end

% Inplane view check
viewType = viewGet(view,'viewType');
if ~isequal(viewType,'Inplane')
    error('Sorry, only works for Inplane views.')
end

% anat field check
if ~isfield(view,'anat') | isempty(view.anat)
    view = loadAnatomy(view);
end

% initalize an rx struct for the prescription
[vol mmPerPix] = loadVolume(vAnatPath); % ,'reorient'
refRes = mrSESSION.inplanes.voxelSize;
rx = rxInit(vol,view.anat,'volRes',mmPerPix,'refRes',refRes);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set the xform to be the mrSESSION xform (w/ some gum to
% account for different conventions):
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rx.xform = mrSESSION.alignment;

% flip to (x,y,z) instead of (y,x,z):
rx.xform(:,[1 2]) = rx.xform(:,[2 1]);
rx.xform([1 2],:) = rx.xform([2 1],:);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% get the interpolated image for each slice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nSlices = size(view.anat,3);
for slice = 1:nSlices
    interpVol(:,:,slice) = rxInterpSlice(rx,slice);
end

%voila!

return
    