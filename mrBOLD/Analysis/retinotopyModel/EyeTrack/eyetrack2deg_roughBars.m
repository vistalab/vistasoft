function eyeInDeg = eyetrack2deg_roughBars(eyeTrackMatFile)
% eyetrack2deg_roughBars - convert fMRI pixel based eyemovement data 
% with the roughBars stimuli to degrees of visual angle
%
% eyeInDeg = eyetrack2deg_roughBars(eyeTrackMatFile);
%
% 2007/08 SOD: wrote it.

if ~exist('eyeTrackMatFile','var') || isempty(eyeTrackMatFile)
    error('need eyeTrackMatFile');
end

% frames per second
framerate = 30; 

% calculate number of time points
stimrep = 5;
tr      = 1.5;
%prescan = 1
%ntime = (14.*stimrep.*tr).*framerate;

% copied from makeRetinotopyStimulus_roughBars, but we removed the
% last mean luminance presentation because we clipped the eye movie
% from the first stimulus presentation to the last.
sequence = [5:8 9:12 13:16 21,21 17:20 9:12 3,4,1,2 21,21 15,16 13,14 11,12 9,10 7,8 5,6 21,21 19,20 17,18 11,12 9,10 1:4];
fixseq   = ceil(sequence./4);
fixseq = reshape(fixseq,2,numel(fixseq)./2)';% pair up
fixseq = fixseq(:,1);
fixseq = repmat(fixseq,1,tr.*framerate.*stimrep);
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

% load eyetrackdata
if ischar(eyeTrackMatFile)
    load(eyeTrackMatFile);
else
    et = eyeTrackMatFile;
end

% compute error:
slip = abs(numel(fixseq)-size(et,1));
fprintf(1,'[%s]:Timing error (difference) is about: %.2f seconds.\n',mfilename,slip/framerate);

% simply cut the difference
if numel(fixseq)<size(et,1)
    et = et(1:numel(fixseq),:);
else
    et = [et; zeros(slip,size(et,2))];
end

% interpolate missing data
t  = (0:numel(fixseq)-1)'./framerate;
eyeClosed = et(:,1)==0 | et(:,2)==0 | ~isfinite(sum(et(:,1:2),2));

% interpolate single points (probably due to fit failure)
singlePoints = eyeClosed + ...
               [eyeClosed(2:end); 0]+...
               [0; eyeClosed(1:end-1)];
singlePoints = singlePoints==1;
et(:,1) = interp1(t(~singlePoints),et(~singlePoints,1),t,'linear',mean(et(~singlePoints,1)));
et(:,2) = interp1(t(~singlePoints),et(~singlePoints,2),t,'linear',mean(et(~singlePoints,2)));
eyeClosed = eyeClosed & ~singlePoints;

% ignore 10 seconds around eyeblick
goodData = 1-min(eyeClosed+...
                [eyeClosed(2:end); 0]+...
                [eyeClosed(3:end); 0; 0]+...
                [eyeClosed(4:end); 0; 0; 0]+...
                [eyeClosed(5:end); 0; 0; 0; 0]+...
                [eyeClosed(6:end); 0; 0; 0; 0; 0]+...
                [0; eyeClosed(1:end-1)]+...
                [0; 0; eyeClosed(1:end-2)]+...
                [0; 0; 0; eyeClosed(1:end-3)]+...
                [0; 0; 0; 0; eyeClosed(1:end-4)]+...
                [0; 0; 0; 0; 0; eyeClosed(1:end-5)],1);%sigh...
goodData = logical(goodData);
%et_old = et;
et(:,1) = interp1(t(goodData),et(goodData,1),t,'linear',mean(et(goodData,1)));
et(:,2) = interp1(t(goodData),et(goodData,2),t,'linear',mean(et(goodData,2)));


% smooth estimates
% 1: median filter (jumps of 1/30th of seconds are unlikely)
% 2: gaussian filter (smoothness constraint fwhm=100ms)
met = ones(size(et,1),1)*mean(et(:,1:2));
et(:,1:2) = blurTC(et(:,1:2)-met,3,3,10)+met;

% remove data around fixation changes = 0; remove [-1 2] seconds
% find fixation changes 
lim = [-1 2];
fc = find(diff(fixseq)~=0)-framerate*abs(min(lim));
fcii = fc(:)*ones(1,framerate*diff(lim))+...
    ones(size(fc(:)))*(0:framerate*diff(lim)-1);
fcii = fcii';
fcii = fcii(:);
badCalData = false(size(fixseq));
badCalData(fcii) = true;


% find good calibration data
goodCalData = goodData & ~badCalData;

%--- limit to good calibration data
f =fixseq(goodCalData);
% measured fixation in pixels
X = et(goodCalData,1:2);
% time
t = t(goodCalData);

Y = [-1 -1;...
     +1 -1;...
      0  0;...
     -1 +1;...
     +1 +1].*5;
Xsummary = zeros(max(fixseq),2); 
fixseq_deg = zeros(size(fixseq,1),2);
for n=1:5,
    ii = fixseq==n;
    fixseq_deg(ii,:) = ones(sum(ii),1)*Y(n,:);
    ii = f==n;
    Xsummary(n,:) = mean(X(ii,:));
end

Xt = et(:,1:2);
Xt2 = Xt(goodCalData,:);
for n=1:5,
    ii = f==n;
    Xsummary(n,:) = mean(Xt2(ii,:));
end

% linear xfm
[Xi xfm] = linear_xfm(Xsummary,Y);
xfm(abs(xfm)<eps) = 0;
X2  = [Xt(:,1:2) ones(size(et,1),1)];
Xt = X2*xfm;
Xt = Xt(:,1:2);
xfm1 = [xfm';0 0 1];
xfm2 = xfm1;

c = logical([ones(2,3); zeros(1,3); 1 1 0]);

id = [eye(3); 0 0 1];

a=zeros(1001,9);
a(1,:)=[xfm1(c)' sqrt(sum(skewness(Xt(goodCalData,1:2)).^2))];

% now carefully add perspective scaling with boosting and monitoring the
% skewness we like it if the skewness goes down but not up.
iii = 1;
while(1),    
    Xt2 = Xt(goodCalData,:);
    for n=1:5,
        ii = f==n;
        Xsummary(n,:) = mean(Xt2(ii,:));
    end

    % perspective xfm
    [Xi xfm] = perspective_xfm(Xsummary,Y);
    
    tmp = xfm(c)-id(c);
    tmp(abs(tmp)<10*eps)=0;
    if ~any(tmp), break; end
    [vM iM]  = max(abs(tmp));
    iM  = iM(1);
    vM  = tmp(iM);
    tmp = zeros(size(tmp));
    tmp(iM) = min(abs(vM),1e-3).*sign(vM);
    tmp = tmp + id(c);
    
    xfm = id;
    xfm(c) = tmp;
    
    X2  = [Xt(:,1:2) ones(size(et,1),1)]';
    Xtt = ((xfm(1:3,1:3)*X2) ./ (ones(3,1)*(xfm(4,:)*X2)))';
    Xtt = Xtt(:,1:2);
    
    a(iii+1,:) = [xfm2(c)' sqrt(sum(skewness(Xtt(goodCalData,1:2)).^2))];
    
    % monitor the skewness
    if round(a(iii+1,9)*1e4)>round(max(1.05*a(iii,9)*1e4,0.2*1e4))
        %[xfm1 xfm2],
        break
    else
        Xt = Xtt;
        xfm2 = xfm2 + xfm - id;
    end
    iii = iii + 1;
end
% % linear xfm
% [Xi xfm] = linear_xfm(Xsummary,Y);
% X2  = [et(:,1:2) ones(size(et,1),1)];
% Xt = (X2*xfm);
% Xt = Xt(:,1:2);
% 
% Xt2 = Xt(goodCalData,:);
% for n=1:5,
%     ii = f==n;
%     Xsummary(n,:) = mean(Xt2(ii,:));
% end
% % perspective xfm
% [Xi xfm] = perspective_xfm(Xsummary,Y);
% xfm{1} = 
% xfm{2}
% X2  = [Xt(:,1:2) ones(size(et,1),1)]';
% %Xt = ((xfm{1}*X2) ./ (ones(3,1)*(xfm{2}*X2)))';
% Xt = Xt(:,1:2);
% 
% 

Xi = Xt(goodCalData,:);


% output
eyeInDeg.blinks    = eyeClosed;
eyeInDeg.eye       = Xt;
eyeInDeg.framerate = framerate;
eyeInDeg.fixation  = fixseq_deg;
eyeInDeg.goodData  = goodCalData;

% compute derivative
der = diff(eyeInDeg.eye)*framerate;
der = ([ones(1,size(der,2));der] + [der; ones(1,size(der,2))])./2;
vel = hypot(der(:,1),der(:,2));

eyeInDeg.velocity = vel;

% plot
if ~nargout,
    colors = {'m.','y.','b.','g.','r.'};
    
    figure(1);clf;hold on;
    for n=1:5,
        plot(X(f==n,1),X(f==n,2),colors{n},'markersize',5);
    end
    ylabel('y (pixels)');
    xlabel('x (pixels)');

    figure(2);clf;hold on;
    for n=1:5,
        plot(Xi(f==n,1),Xi(f==n,2),colors{n},'markersize',5);
    end
    for n=1:5,
        plot(Y(n,1),Y(n,2),'kx','markersize',15,'linewidth',5);
        plot(mean(Xi(f==n,1)),mean(Xi(f==n,2)),'ko','markersize',15,'linewidth',3);
    end
    ylabel('y (deg)');
    xlabel('x (deg)');
    axis([-20 20 -20 20])


    figure(3);clf;
    subplot(2,1,1);hold on;
    for n=1:5,
        plot(t(f==n),Xi(f==n,1),colors{n},'markersize',5);
    end
    title('x');
    ylabel('position (deg)');
    axis([1 max(t) -20 20]);

    subplot(2,1,2);hold on;
    for n=1:5,
        plot(t(f==n),Xi(f==n,2),colors{n},'markersize',5);
    end
    title('y')
    xlabel('time (sec)');
    ylabel('position (deg)');
    axis([1 max(t) -20 20]);
    
    figure(4);clf;
    subplot(2,1,1);plot(a(1:iii,1:8)-ones(iii,1)*a(1,1:8));
    subplot(2,1,2);plot(a(1:iii,9),'k');
    h=axis;
    axis([h(1) h(2) 0-.01 max(h(4),0.2)+.01]);
end
