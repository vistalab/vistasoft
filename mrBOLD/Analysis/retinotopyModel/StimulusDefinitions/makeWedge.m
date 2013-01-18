function params = makeWedge(params,id);
% makeWedge - regular retinotopic 'wedge' stimulus
%
% params = makeWedge(params,id);
%
% largely copied from makeRetinotopyStimulus. 
% params should be a retinotopy model parameter structure.
% id is the index of the stimulus (e.g., which scan in the data type is the
% wedge scan we are constructing now?)
%
% 2006/06 SOD

if notDefined('params');     error('Need params'); end;
if notDefined('id');         id = 1;               end;

% Loop that creates the final images
fprintf(1,'[%s]:Creating images:',mfilename);

type       = 'wedge';
outerRad   = params.stim(id).stimSize;
innerRad   = 0;
wedgeWidth = params.stim(id).stimWidth .* (pi/180);
ringWidth  = outerRad .* params.stim(id).stimWidth ./ 360;
numImages  = params.stim(id).nFrames ./ params.stim(id).nCycles;
mygrid     = -params.analysis.fieldSize:params.analysis.sampleRate:params.analysis.fieldSize; 	 
[x,y]      = meshgrid(mygrid, -mygrid);
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

if isnumeric(params.stim(id).stimDir)
    if params.stim(id).stimDir==0,
        wedgeDir   = 'ccw';
    else,
        wedgeDir   = 'cw';
    end
end
startTheta = params.stim(id).stimStart .* (pi/180);

%  images     = zeros(size(x,2),size(x,1),numImages);
images     = zeros(prod([size(x,2) size(x,1)]),numImages);
for imgNum=1:numImages
    img        = zeros(size(x,2), size(x,1));

    if isequal(wedgeDir, 'ccw')
        loAngle = 2*pi*((imgNum-1)/numImages) + startTheta;
        hiAngle = loAngle + wedgeWidth;
    else
        loAngle = 2*pi*((numImages-imgNum+1)/numImages) + startTheta;
        hiAngle = loAngle + wedgeWidth;
    end
    loAngle = mod(loAngle, 2*pi);
    hiAngle = mod(hiAngle, 2*pi);
    loEcc   = innerRad;
    hiEcc   = outerRad;


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

%     if isfield(params.stim(id),'fliprotate'),
% 		% make sure we have at least 3 entries
% 		params.stim(id).fliprotate(4) = 0;
% 		
%         if params.stim(id).fliprotate(1),
%             img = fliplr(img);
%         end;
%         if params.stim(id).fliprotate(2),
%             img = flipud(img);
%         end;
% %         if params.stim(id).fliprotate(3)~=0,
% %             img = rot90(img,params.stim(id).fliprotate(3));
% %         end;
%     end;
    
    images(:,imgNum) = img(:);
    fprintf('.'); drawnow;

end;

% if isfield(params.stim(id),'fliprotate'),
%     if numel(params.stim(id).fliprotate)>3,
%         if params.stim(id).fliprotate(4),
%             images = fliplr(images);
%         end;
%     end;
% end;
% 
%  img    = repmat(images,[1 1 params.stim(id).nCycles]);
%  preimg = img(:,:,1+end-params.stim(id).prescanDuration:end);
%  params.stim(id).images = cat(3,preimg,img);
img    = repmat(images,[1 params.stim(id).nCycles]);
% on off
if params.stim(id).nStimOnOff>0,
    fprintf(1,'(with Blanks)');
    nRep = params.stim(id).nStimOnOff;
%     offBlock = round(12./params.stim(id).framePeriod);
    offBlock = round(numImages/2);
    onBlock  = params.stim(id).nFrames./nRep-offBlock;
    onoffIndex = repmat(logical([zeros(onBlock,1); ones(offBlock,1)]),nRep,1);
    img(:,onoffIndex)    = 0;
end;
preimg = img(:,1+end-params.stim(id).prescanDuration:end);
params.stim(id).images = cat(2,preimg,img);

fprintf(1,'Done.\n'); drawnow;

return;
