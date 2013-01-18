function [handles,msh] = dtiMrMeshAddImages(handles,msh,imOrigin,xIm,yIm,zIm,textures)
%   Add the images to the mrMesh window
%
%   [handles,msh] = ...
%      dtiMrMeshAddImages(handles,msh,imOrigin,xIm,yIm,zIm,textures)
%
% HISTORY:
% Authors: Dougherty, Wandell
% 2005.01.17 RFD: fixed minor inefficiency in how mrMesh params were
% passed.
%
% Stanford VISTA Team

if ieNotDefined('handles'), error('dtiFiberUI handles required.'); end
if ieNotDefined('msh'), msh = dtiGet(handles,'mrMesh'); end
if ieNotDefined('imOrigin'), error('imOrigin required.'); end
if ~exist('xIm','var'), error('xIm required.'); end
if ~exist('yIm','var'), error('yIm required.'); end
if ~exist('zIm','var'), error('zIm required.'); end
if ieNotDefined('textures'), textures = []; end

if ~isempty(xIm) && ~iscell(xIm), tmp{1} = xIm; clear xIm; xIm = tmp; end
if ~isempty(yIm) && ~iscell(yIm), tmp{1} = yIm; clear yIm; yIm = tmp;  end
if ~isempty(zIm) && ~iscell(zIm), tmp{1} = zIm; clear zIm; zIm = tmp; end
if ~iscell(imOrigin), tmp = imOrigin; clear imOrigin; imOrigin{1} = tmp; end

xSize = length(xIm);
ySize = length(yIm);
zSize = length(zIm);

if xSize + ySize + zSize == 0, return, end
if xSize == 0, xSize = max([xSize,ySize,zSize]); end
if ySize == 0, ySize = max([xSize,ySize,zSize]); end
if zSize == 0, zSize = max([xSize,ySize,zSize]); end

if (xSize ~= ySize) || (xSize ~= zSize) || (ySize ~= zSize)
    error('You should have to same number of images to display');
end

nImages = xSize;

if (length(imOrigin) ~= nImages)
    error('You should have an origin specified for each image');
end

% sbOffset = 10;

% imSize must be 2^n (openGL requirement)
% 
imSize = 0;
for i = 1:nImages
    if ~isempty(xIm), imSize = max([imSize,2.^ceil(log2(size(xIm{i}')))]); end;
    if ~isempty(yIm), imSize = max([imSize,2.^ceil(log2(size(yIm{i})))]); end;
    if ~isempty(zIm), imSize = max([imSize,2.^ceil(log2(size(zIm{i}')))]); end;
end

imSize = [imSize imSize];
imTemplate.class = 'image';
imTemplate.width = imSize(1); 
imTemplate.height = imSize(2);
imTemplate.tex_width = imSize(2);
imTemplate.tex_height = imSize(1);

% 1 is opaque. 0 is completely transparent.
% We need to set this parameter in the GUI at some point.  Leave it like
% this for now so Bob and Michal see the effect and comment.
imTemplate.transparency = msh.transparency;

if ~isempty(xIm)
    for i = 1:nImages
        im = imTemplate;
        [id,s,r] = mrMesh(msh.host, msh.id, 'add_actor', im);
        msh.imgActors(3*i) = r.actor;
        im.actor = r.actor;
        sz = size(xIm{i}');
        pos = floor((imSize-sz)./2)+1;
        imData = zeros(imSize);
        imData(pos(1):pos(1)+sz(1)-1, pos(2):pos(2)+sz(2)-1) = xIm{i}';
        im.texture = repmat(imData(:)', 4, 1);

        if isempty(textures)
            im.texture(4,:) = im.transparency*ones(size(im.texture(1,:)));
        else
            textures.xIm{i} = textures.xIm{i}';
            if(any(size(textures.xIm{i})~=imSize))
                imData = zeros(imSize);
                imData(pos(1):pos(1)+sz(1)-1, pos(2):pos(2)+sz(2)-1) = textures.xIm{i};
                im.texture(4,:) = imData(:);
            else
                im.texture(4,:) = textures.xIm{i}(:);
            end
        end

        im.rotation = [0 0 1; 0 1 0; 1 0 0];
        im.origin = imOrigin{i}.x;
        [id,s,r] = mrMesh(msh.host, msh.id, 'set', im);
    end
end

if~isempty(yIm)
    for i = 1:nImages
        im = imTemplate;
        [id,s,r] = mrMesh(msh.host, msh.id, 'add_actor', im);
        msh.imgActors(2 + 3*(i - 1)) = r.actor;
        im.actor = r.actor;
        sz = size(yIm{i});
        pos = floor((imSize-sz)./2)+1;
        imData = zeros(imSize);
        imData(pos(1):pos(1)+sz(1)-1, pos(2):pos(2)+sz(2)-1) = yIm{i};
        im.texture = repmat(imData(:)', 4, 1);

        if isempty(textures)
            im.texture(4,:) = im.transparency*ones(size(im.texture(1,:)));
        else
            %textures.yIm{i} = textures.yIm{i}';
            if(any(size(textures.yIm{i})~=imSize))
                imData = zeros(imSize);
                imData(pos(1):pos(1)+sz(1)-1, pos(2):pos(2)+sz(2)-1) = textures.yIm{i};
                im.texture(4,:) = imData(:);
            else
                im.texture(4,:) = textures.yIm{i}(:);
            end
        end

        im.rotation = [1 0 0; 0 0 1; 0 1 0];
        im.origin = imOrigin{i}.y;
        [id,s,r] = mrMesh(msh.host, msh.id, 'set', im);
    end
end      

if ~isempty(zIm) 
    for i = 1:nImages
        im = imTemplate;
        [id,s,r] = mrMesh(msh.host, msh.id, 'add_actor', im);
        msh.imgActors(1 + 3*(i - 1)) = r.actor;
        im.actor = r.actor;
        sz = size(zIm{i}');        pos = floor((imSize-sz)./2)+1;
        imData = zeros(imSize);
        imData(pos(1):pos(1)+sz(1)-1, pos(2):pos(2)+sz(2)-1) = zIm{i}';
        im.texture = repmat(imData(:)', 4, 1);

        if isempty(textures)
            im.texture(4,:) = im.transparency*ones(size(im.texture(1,:)));
        else
            textures.zIm{i} = textures.zIm{i}';
            if(any(size(textures.zIm{i})~=imSize))
                imData = zeros(imSize);
                imData(pos(1):pos(1)+sz(1)-1, pos(2):pos(2)+sz(2)-1) = textures.zIm{i};
                im.texture(4,:) = imData(:);
            else
                im.texture(4,:) = textures.zIm{i}(:);
            end
        end
        
        im.rotation = [1 0 0; 0 1 0; 0 0 1];
        im.origin = imOrigin{i}.z;
        [id,s,r] = mrMesh(msh.host, msh.id, 'set', im);
        %msh.img(1) = im;
    end
end

return;
