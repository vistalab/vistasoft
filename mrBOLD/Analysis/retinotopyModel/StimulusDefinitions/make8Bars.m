function params = make8Bars(params,id)
% Make moving (8) bar visual field mapping stimulus
%
%   params = make8Bars(stimparams,stimulus_id);
%
% We use bars of eight different orientations, moving through the visual
% field, to estimate pRFs.  This function creates the set of stimulus
% apertures corresponding to these moving, flickering, contrast bars.
%
% These apertures are then used by the pRF modeling software to estimate
% the pRF.
% 
% params: A retinotopy model parameter structure
% stimulus_id: Which scan is associated with this stimulus
%
% (largely copied from makeRetinotopyStimulus_bars (v1.1))
%
% See also: makeWedges.m
%
% Example:
%    PLEASE INSERT AN EXAMPLE HERE
%

 
%% 2006/06 SOD: wrote it.

if notDefined('params');     error('Need params'); end;
if notDefined('id');         id = 1;                   end;

outerRad   = params.stim(id).stimSize;
innerRad   = 0;
ringWidth  = outerRad .* params.stim(id).stimWidth ./ 360;
numImages  = params.stim(id).nFrames ./ params.stim(id).nCycles;
mygrid = -params.analysis.fieldSize:params.analysis.sampleRate:params.analysis.fieldSize; 	 
[x,y]=meshgrid(mygrid,mygrid);
r          = sqrt (x.^2  + y.^2);
theta      = atan2 (y, x);	% atan2 returns values between -pi and pi
theta      = mod(theta,2*pi);	% correct range to be between 0 and 2*pi

%% we need to update the sampling grid to reflect the sample points used
% ras 06/08: this led to a subtle bug in which (in rmMakeStimulus) multiple
% operations of a function would modify the stimulus images, but not the
% sampling grid. These parameters should always be kept very closely
% together, and never modified separately.
params.analysis.X = x(:);
params.analysis.Y = y(:);

% loop over different orientations and make checkerboard
% first define which orientations
orientations = [0:45:360]./360*(2*pi); % degrees -> rad
orientations = orientations([1 6 3 8 5 2 7 4]);
remake_xy    = zeros(1,numImages)-1;
remake_xy(1:length(remake_xy)./length(orientations):length(remake_xy)) = orientations;
original_x   = x;
original_y   = y;

% step size of the bar
step_nx      = numImages/8;
step_x       = (2*outerRad) ./ step_nx;
step_startx  = (step_nx-1)./2.*-step_x - (ringWidth./2);

images = zeros(prod([size(x,2) size(x,1)]),numImages);

% Loop that creates the final images
% fprintf(1,'[%s]:Creating images:',mfilename);
for imgNum=1:numImages
    img        = zeros(size(x,2),size(x,1));
    if remake_xy(imgNum) >=0,
        x = original_x .* cos(remake_xy(imgNum)) - original_y .* sin(remake_xy(imgNum));
        y = original_x .* sin(remake_xy(imgNum)) + original_y .* cos(remake_xy(imgNum));

        % reset starting point
        loX = step_startx-step_x;
    end;

    loEcc = innerRad;
    hiEcc = outerRad;
    loX   = loX + step_x;
    hiX   = loX + ringWidth;

    % Can we do this just be removing the second | from the window expression? so...
    window = ( (x>=loX & x<=hiX) & r<outerRad);
    img(window) = 1;
    if isfield(params.stim(id),'fliprotate'),
        if params.stim(id).fliprotate(1),
            img = fliplr(img);
        end;
        if params.stim(id).fliprotate(2),
            img = flipud(img);
        end;
        if params.stim(id).fliprotate(3)~=0,
            img = rot90(img,params.stim(id).fliprotate(3));
        end;
    end;
        
    images(:,imgNum) = img(:);
%     fprintf('.');drawnow;
end

% repeat across cycles
img    = repmat(images,[1 params.stim(id).nCycles]);

% on off
if params.stim(id).nStimOnOff>0,
%     fprintf(1,'(with Blanks)');
    nRep = params.stim(id).nStimOnOff;
    offBlock = round(12./params.stim(id).framePeriod);
    onBlock  = params.stim(id).nFrames./nRep-offBlock;
    onoffIndex = repmat(logical([zeros(onBlock,1); ones(offBlock,1)]),nRep,1);
    img(:,onoffIndex)    = 0;
end;

preimg = img(:,1+end-params.stim(id).prescanDuration:end);
params.stim(id).images = cat(2,preimg,img);
% fprintf(1,'Done.\n');


return;
  


