function params = makeRoughBars(params,id)
% makeRoughBars - make rough bar mapping stimulus
%
% params = makeRoughBars(stimparams,stimulus_id);
%
% Hack: copied almost straight from stimulus code. Little
% flexibility - good enough for now.
%
% 2007/09 SOD: wrote it.

if notDefined('params');     error('Need params'); end;
if notDefined('id');         id = 1;                   end;

fprintf(1,'[%s]:Processing:...',mfilename);drawnow;

fixMov = -5;
eyeMov = [20 10 20./180*pi]./2; 
X = params.analysis.X;
Y = params.analysis.Y;

stimlimits = [14 14/600*800];

% make images
images=zeros(numel(X),21);
imii  = 1;

%--- fix: left up
X2 = X-fixMov;
Y2 = Y-fixMov;
% stim: right
X3 = X2 - eyeMov(1);
Y3 = Y2;
t  = atan2 (Y3, X3);
mask = t>=-pi/2+eyeMov(3) & t<=pi/2-eyeMov(3) &...
       abs(X)<=stimlimits(2) & ...
       abs(Y)<=stimlimits(1);
images(:,imii) = mask(:);
imii = imii+2;

% stim: bottom
X3 = X2;
Y3 = Y2 - eyeMov(2);
t  = atan2 (Y3, X3);
mask = t>=0+eyeMov(3) & t<=pi-eyeMov(3) &...
       abs(X)<=stimlimits(2) & ...
       abs(Y)<=stimlimits(1);
images(:,imii) = mask(:);
imii = imii+2;

%-- fix: right up
X2 = X+fixMov;
Y2 = Y-fixMov;
% stim: left
X3 = X2 + eyeMov(1);
Y3 = Y2;
t  = atan2 (Y3, X3);
mask = (t<=-pi/2-eyeMov(3) | t>=pi/2+eyeMov(3)) &...
       abs(X)<=stimlimits(2) & ...
       abs(Y)<=stimlimits(1);
images(:,imii)= mask(:);
imii = imii+2;

% stim: bottom
X3 = X2;
Y3 = Y2 - eyeMov(2);
t  = atan2 (Y3, X3);
mask = t>=0+eyeMov(3) & t<=pi-eyeMov(3)&...
       abs(X)<=stimlimits(2) & ...
       abs(Y)<=stimlimits(1);
images(:,imii) = mask(:);
imii=imii+2;



%--- fix: center
X2 = X;
Y2 = Y;
% vertical
mask = abs(X2)<=eyeMov(1)./2 & ...
       abs(X)<=stimlimits(2) & ...
       abs(Y)<=stimlimits(1);
images(:,imii) =  mask(:);
imii=imii+2;
% horizontal
mask = abs(Y2)<=eyeMov(2)./2 &...
       abs(X)<=stimlimits(2) & ...
       abs(Y)<=stimlimits(1);
images(:,imii) =  mask(:);
imii=imii+2; 

%--- fix: left down
X2 = X-fixMov;
Y2 = Y+fixMov;
% stim: right
X3 = X2 - eyeMov(1);
Y3 = Y2;
t  = atan2 (Y3, X3);
mask = t>=-pi/2+eyeMov(3) & t<=pi/2-eyeMov(3)&...
       abs(X)<=stimlimits(2) & ...
       abs(Y)<=stimlimits(1);
images(:,imii) =  mask(:);
imii=imii+2;
% stim: top
X3 = X2;
Y3 = Y2 + eyeMov(2);
t  = atan2 (Y3, X3);
mask = t>=-pi+eyeMov(3) & t<=0-eyeMov(3)&...
       abs(X)<=stimlimits(2) & ...
       abs(Y)<=stimlimits(1);
images(:,imii) = mask(:);
imii=imii+2;


%-- fix: right down
X2 = X+fixMov;
Y2 = Y+fixMov;
% stim: left
X3 = X2 + eyeMov(1);
Y3 = Y2;
t  = atan2 (Y3, X3);
mask = (t<=-pi/2-eyeMov(3) | t>=pi/2+eyeMov(3)) &...
       abs(X)<=stimlimits(2) & ...
       abs(Y)<=stimlimits(1);
images(:,imii) = mask(:);
imii=imii+2;

% stim: top
X3 = X2;
Y3 = Y2 + eyeMov(2);
t  = atan2 (Y3, X3);
mask = t>=-pi+eyeMov(3) & t<=0-eyeMov(3) &...
       abs(X)<=stimlimits(2) & ...
       abs(Y)<=stimlimits(1);
images(:,imii) = mask(:);
%imii=imii+2;


% make sequence
sequence = [5:8 9:12 13:16 21,21 17:20 9:12 3,4,1,2 21,21 15,16 13,14 11,12 9,10 7,8 5,6 21,21 19,20 17,18 11,12 9,10 1:4 21,21];
fixseq   = ceil(sequence./4);

sequence = reshape(sequence,2,numel(sequence)./2)';% pair up
sequence = sequence(:,1);
sequence = repmat(sequence',5,1);
sequence = sequence(:);

fixseq = reshape(fixseq,2,numel(fixseq)./2)';% pair up
fixseq = fixseq(:,1);
fixseq = repmat(fixseq,1,5);
fixseq = fixseq';
fixseq = fixseq(:);

% fill in fixseq with nearest values
while sum(fixseq==6),
    a = diff(fixseq==6);
    ii=find(a==1);
    fixseq(ii+1)= fixseq(ii);
    ii=find(a==-1);
    fixseq(ii) = fixseq(ii+1);
end

nuisance = zeros(numel(fixseq),10);
change = [0;diff(fixseq)~=0] -  [diff(fixseq)~=0;0];
counter =1;
for n=1:5,
    nuisance(:,counter) = fixseq==n & change ==1;
    if fixseq(1)==n, nuisance(1,counter) = 1; end;
    counter = counter + 1;
    nuisance(:,counter) = fixseq==n & change ==-1;
    if fixseq(end)==n, nuisance(end,counter) = 1; end;
    counter = counter + 1;
end


% all images
img = images(:,sequence);
preimg = img(:,1+end-params.stim(id).prescanDuration:end);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
doEyeCorrection = params.stim(id).stimStart(1)~=0;
doVelocityWeighting = false;
%velocityMax     = 200;
if doEyeCorrection,
    fprintf(1,'\n[%s]:Correcting for eye-movements.\n',mfilename);
else
    fprintf(1,'\n[%s]:NOT correcting for eye-movements.\n',mfilename);
end
% incorporate eyemovements
newimg = zeros(size(img));

% HACK: stored in non-used stimDir
scans = params.stim(id).stimStart;
scans = max(scans,1);
for scanid=scans,
    eyeTrackData = sprintf('%s/eyeMovements/scan%d_eyetrackdata.mat',pwd,scanid);
    e = eyetrack2deg_roughBars(eyeTrackData);
    if doVelocityWeighting,
        stepsize = mean(diff(unique(params.analysis.Y)));
        e.velocity = e.velocity/2.3548*stepsize/4;
    end
    if ~doEyeCorrection,
        % this provides a visual check of the motion correction, because
        % fixation is moved during the scan.
        e.eye = e.fixation;
        e.blinks = false(size(e.blinks));
    end

    % resample to stimulus sequence
    stimindex    = linspace(0,numel(e.blinks),numel(e.blinks)/(e.framerate.*params.stim(id).framePeriod)+1)+1;
    stimduration = e.framerate.*.2;
    X = reshape(params.analysis.X,[1 1]*sqrt(numel(params.analysis.X)));
    Y = reshape(params.analysis.Y,[1 1]*sqrt(numel(params.analysis.Y)));
    
    for n=1:size(img,2),
        if sum(img(:,n))~=0,
            tmp = zeros(size(X));
            zi  = tmp;
            tmp(:) = img(:,n);
            for n2=stimindex(n):stimindex(n)+stimduration-1,
                if ~e.blinks(n2)
                    
                    % resample to 'corrected' position + give weight based
                    % on velocity.
                    newtmp = interp2(X,Y,tmp,X+e.eye(n2,1),Y+e.eye(n2,2),'*linear',0);
                    if doVelocityWeighting && doEyeCorrection,
                        % assume velocity = fwhm
                        if e.velocity(n2) > 1,
                            f = fspecial('gaussian',ceil(e.velocity(n2)*6),e.velocity(n2));
                            newtmp = imfilter(newtmp,f,'same');
                        end
                    end
                    zi = zi + newtmp;%.*w(n); % old way
                end
            end
            newimg(:,n) = newimg(:,n) + zi(:)./stimduration;
        end
    end
end
newimg = newimg./numel(scans);

% append prestimuli
params.stim(id).images = cat(2,preimg,newimg);
% store nuisance parameters convolved with the Hrf
params.stim(id).nuisance = [nuisance(1+end-params.stim(id).prescanDuration:end,:); nuisance];
params.stim(id).nuisance = filter(params.analysis.Hrf{id},1,params.stim(id).nuisance);  
params.stim(id).nuisance = rmAverageTime(params.stim(id).nuisance, ...
                                         params.stim(id).nUniqueRep);
params.stim(id).nuisance = params.stim(id).nuisance(params.stim(id).prescanDuration+1:end,:);
params.stim(id).nuisance = params.stim(id).nuisance';
return;
  


