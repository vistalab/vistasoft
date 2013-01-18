function params = makeRing(params,id);
% makeRing - regular retinotopic 'ring' stimulus
%
% params = makeRing(params,id);
%
% largely copied from makeRetinotopyStimulus.
% params should be a retinotopy model parameter structure.
% id is the index of the stimulus (e.g., which scan in the data type is the
% ring scan we are constructing now?)
%
% 2006/06 SOD

if notDefined('params');     error('Need params'); end;
if notDefined('id');         id = 1;               end;


% Loop that creates the final images
fprintf(1,'[%s]:Creating images:',mfilename);

type       = 'ring';
outerRad   = params.stim(id).stimSize;
innerRad   = 0;
wedgeWidth = params.stim(id).stimWidth .* (pi/180);
ringWidth  = outerRad .* params.stim(id).stimWidth ./ 360;
numImages  = params.stim(id).nFrames ./ params.stim(id).nCycles;
mygrid = -params.analysis.fieldSize:params.analysis.sampleRate:params.analysis.fieldSize; 	 
[x,y]=meshgrid(mygrid,mygrid);
r          = sqrt (x.^2  + y.^2);
theta      = atan2 (y, x);	  % atan2 returns values between -pi and pi
theta      = mod(theta,2*pi); % correct range to be between 0 and 2*pi

%% we need to update the sampling grid to reflect the sample points used
% ras 06/08: this led to a subtle bug in which (in rmMakeStimulus) multiple
% operations of a function would modify the stimulus images, but not the
% sampling grid. These parameters should always be kept very closely
% together, and never modified separately.
params.analysis.X = x(:);
params.analysis.Y = y(:);

try,
    if params.stim(id).stimDir == 0,
        ringDir = 'out';
    else,
        ringDir = 'in';
    end
    startTheta = deg2rad( -(params.stim(id).stimStart - 90) );
catch,
    % Make defaults so we get original definitions back.
    wedgeDir   = 'cw';
    ringDir    = 'out';
    startTheta = wedgeWidth/2;
end;

%  images     = zeros(size(x,2),size(x,1),numImages);
images     = zeros(prod([size(x,2) size(x,1)]),numImages);
for imgNum=1:numImages
    img        = zeros(size(x,2), size(x,1));
    switch lower(type)
        case 'wedge',
            if isequal(wedgeDir, 'cw')
                loAngle = 2*pi*((imgNum-1)/numImages) + startTheta - wedgeWidth/2;
                hiAngle = loAngle + wedgeWidth;
            else
                loAngle = 2*pi*((numImages-imgNum+1)/numImages) + startTheta;
                hiAngle = loAngle + wedgeWidth;
            end
            loAngle = mod(loAngle, 2*pi);
            hiAngle = mod(hiAngle, 2*pi);
            loEcc   = innerRad;
            hiEcc   = outerRad;

        case 'ring',
            loAngle = 0;
            hiAngle = 2*pi;
            if isequal(ringDir, 'out')
                loEcc   = outerRad * (imgNum-1)/numImages;
                hiEcc   = loEcc + ringWidth;
            else
                loEcc   = outerRad * (numImages-imgNum+1)/numImages;
                hiEcc   = loEcc + ringWidth;
            end

        otherwise,
            error('Unknown stimulus type!');
    end

    if hiAngle > loAngle
        window = ( (theta>=loAngle & theta<hiAngle)  & ...
            ((r>=loEcc & r<=hiEcc)) & ...
            r<outerRad ...
            );

    else
        window = ( (theta>=loAngle | theta<hiAngle)  & ...
            (r>=loEcc & r<=hiEcc) & ...
            r<outerRad ...
            );

    end

    img(window) = 1;

    if isfield(params.stim(id),'fliprotate'),
        if params.stim(id).fliprotate(1),
            img = fliplr(img);
        end;
        if length(params.stim(id).fliprotate >= 2) & ...
				params.stim(id).fliprotate(2),
            img = flipud(img);
        end;
        if length(params.stim(id).fliprotate >= 3) & ...
				params.stim(id).fliprotate(3)~=0,
            img = rot90(img,params.stim(id).fliprotate(3));
        end;
    end;

    images(:,imgNum) = img(:);
    fprintf('.'); drawnow;

end;

if isfield(params.stim(id),'fliprotate'),
    if numel(params.stim(id).fliprotate)>3,
        if params.stim(id).fliprotate(4),
            images = fliplr(images);
        end;
    end;
end;

img    = repmat(images,[1 params.stim(id).nCycles]);

% on off
if params.stim(id).nStimOnOff>0,
    fprintf(1,'(with Blanks)');
    nRep = params.stim(id).nStimOnOff;
%    offBlock = round(12./params.stim(id).framePeriod);
    offBlock = round(numImages/2);
    onBlock  = params.stim(id).nFrames./nRep-offBlock;
    onoffIndex = repmat(logical([zeros(onBlock,1); ones(offBlock,1)]),nRep,1);
    img(:,onoffIndex)    = 0;
end;

preimg = img(:,1+end-params.stim(id).prescanDuration:end);
params.stim(id).images = cat(2, preimg, img);

fprintf(1,'Done.\n'); drawnow;

return;
