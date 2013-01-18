function handles = dtiMrMesh3AxisImage(handles, imOrigin, xIm, yIm, zIm)
%
%  handles = dtiMrMesh3AxisImage(handles, imOrigin, xIm, yIm, zIm)
%
% Author: Dougherty
%   Create or update a mrMesh window view
%
% HISTORY:
%   2003.10.29 RFD (bob@white.stanford.edu) wrote it.
%   2004.06    BW   integrated with meshGet/mrm/ and various other changes
%   2005.10    GB   slights changes to fix the image transparency
% 

% Programming notes:
%    We need to create a structure that contains all of the information
%    needed to display the dtiMrMesh data.  Then we need to call a routine
%    that displays these data.  This routine will need to be re-written to
%    be consistent with this.
%    Specifically, the dtiMsh structure should have
%       .xIm, .yIm, .zIm, .fiberGroups, .rois
%    and perhaps other information from the dtiMeshInit structure.
%    Then we should be able to call a routine:  dtiDisplayMrMesh(dtiMsh)
%    This routine is the right starting place.
%    The next level is to integrate the msh structures used in mrVista more
%    completely with the mrMesh structures in dti.  Perhaps through the
%    mrmViewer. (BW)
%
% (c) Stanford VISTA Team, 2008

% Code for this is commented out below
% persistent slicesName;
% persistent slicesLoc;

if ~exist('handles','var')||isempty(handles), error('dtiFiberUi handles required.'); end
if ~exist('imOrigin','var')||isempty(imOrigin), error('imOrigin required.'); end

if(~exist('xIm','var')), xIm = []; end
if(~exist('yIm','var')), yIm = []; end
if(~exist('zIm','var')), zIm = []; end

% Will determine transparency re: brain 
brainMaskFlag = 1;

splitImagesFlag = 1;

% Could use this for caching slices. Set to dirty by default.
slicesDirty = 1;

% mrMesh should always exist!
if ~isfield(handles,'mrMesh'), error('mrMesh must be initialized'); 
else msh = handles.mrMesh; 
end

% Make sure the mrMesh server is running
if ~mrmCheckServer('localhost')
    mrmStart(msh.id,msh.host);
    msh = dtiInitMrMeshWindow(msh);
    slicesDirty = 1;
end

% The server is running.  We probably have the window running.  So, we
% clear out the actors but add back in the lights.  Wish we had some
% way to check that the window properties are OK.  If we don't have the
% window up, then the origin lines, cursor, and background color are wrong.
% The user has to initialize them through the View | MrMesh pulldown menu.
mrmSet(msh,'refresh');

% Ideally, we could check to see if the window was still open. Then, we
% could avoid doing some things again (like turning off the origin) and
% we could more intelligently update the actors (eg. set slicesDirty=1
% if the window was not open).

% Make sure the large, annoying yellow origin arrows are turned off
mrmSet(msh,'originlines',0);

% Remove current actors in the mesh
msh = dtiMrMeshRemoveActors(msh,slicesDirty);

% Check that the lights are on.
if ~checkfields(msh,'Actors','lights')
    msh = dtiAddLights(msh); 
elseif isempty(mrmGet(msh,'actordata',msh.Actors.lights(1)))
    msh = dtiAddLights(msh);
end

% Render the ROIs
[handles,msh] = dtiMrMeshAddROIs(handles,msh);

% Render the FGs.
[handles,msh] = dtiMrMeshAddFGs(handles,msh);

% Add the image
if(slicesDirty==1)
    if(brainMaskFlag)
        [xTexture,yTexture,zTexture] = dtiTextureImage(xIm,yIm,zIm,msh.transparency);
        if ~isempty(zIm), zTexture = dtiAddScaleBar(zTexture); zIm = dtiAddScaleBar(zIm);
        elseif ~isempty(yIm), yTexture = dtiAddScaleBar(yTexture); yIm = dtiAddScaleBar(yIm);
        elseif ~isempty(xIm), xTexture = dtiAddScaleBar(xTexture); xIm = dtiAddScaleBar(xIm);
        end
    else
        % Never used
        if ~isempty(zIm), zIm = dtiAddScaleBar(zIm);
        elseif ~isempty(yIm), yIm = dtiAddScaleBar(yIm);
        elseif ~isempty(xIm), xIm = dtiAddScaleBar(xIm);
        end
    end

    if(splitImagesFlag)
        if(brainMaskFlag)
            textures = dtiSplitFourImages(handles,xTexture,yTexture,zTexture);
        else
            textures = [];
        end
        [images,imOrigin] = dtiSplitFourImages(handles,xIm,yIm,zIm);
        [handles,msh]  = dtiMrMeshAddImages(handles,msh,imOrigin,images.xIm,images.yIm,images.zIm,textures);
    else
        textures.xIm{1} = xTexture; 
        textures.yIm{1} = yTexture; 
        textures.zIm{1} = zTexture; 
        [handles,msh]  = dtiMrMeshAddImages(handles,msh,imOrigin,xIm,yIm,zIm,textures);
    end
end


% We have to explicitly enable transparency for mesh structures (eg. ROIs).
% The texture transparency is always turned on. Note that we should only
% enable transparency if needed- it slows things down quite a bit.
clear t; 
if (msh.transparency == 1), t.enable = 0; else t.enable = 1; end

[id,s,r] = mrMesh(msh.host, msh.id, 'transparency', t);

% Use the window ID and mesh name in the title bar of the window.
mrmSet(msh,'title',sprintf('%s (ID %d)',meshGet(msh,'name'),msh.id));

% Save the modified mesh
handles = dtiSet(handles,'mrmesh',msh);

return;
