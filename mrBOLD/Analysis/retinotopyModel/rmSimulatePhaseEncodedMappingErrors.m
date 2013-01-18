function rmSimulatePhaseEncodedMappingErrors;
% rmSimulatePhaseEncodedMappingErrors - well... just that
% 
%

if ieNotDefined('view'), view = []; end;

% define parameters structure used in the rest of the program
[params, view] = rmDefineParameters(view,1);

% make stimuli
params = rmMakeStimulus(params);

% make RF
sigmaMajor = 1; sigmaMinor = 1; theta = 0;  y0 = 0; x0 = .2;
%x0=[0:9]/9*3;
nrep       = 10;
sigmaMajor = [.01 .25 .5 1].*pi%[1:nrep]/nrep*3%.*0+2.5;
sigmaMinor = sigmaMajor;
theta      = sigmaMajor.*0;
x0         = [0:.1:3];%[1:nrep]/nrep.*3%.*0+.2;
y0         = x0.*0;%[1:nrep]/nrep.*3.*0;
for iii = 1:length(x0),
  for ii=1:length(sigmaMajor),
    [pred,w,RF] = rfMakePrediction(params,...
                            [sigmaMajor(ii) ...
                             sigmaMinor(ii) ...
                             theta(ii)...
                             x0(iii)...
                             y0(iii)]);
    
    response = reshape(pred,[96 2]);
    response = response-ones(size(response,1),1)*mean(response);
    fftr = fft(response);
    phaseW(ii,iii) = angle(fftr(6+1,1));
    phaseR(ii,iii) = angle(fftr(6+1,2));
    figure(1);clf
%    subplot(2,1,1);imagesc(RF(:,:,1));axis off image;colormap gray;
    
    subplot(2,1,2);plot(response);
    drawnow;    pause(.1);
  end
end;

%figure(2);clf;imagesc(phaseW);axis image off;
%figure(3);clf;imagesc(phaseR);axis image off;
%figure(4);clf;plot(phaseW');axis square;
x = x0./max(x0).*2*pi;
ph = phaseR'.*-1;
ph = ph-ph(end,1)+2*pi-0.000001;
ph = mod(ph,2*pi);
ph = ph - mean(ph(:,1))+pi;
figure(1);clf;plot(x,ph);axis([0 2*pi 0 2*pi]);axis square;
hold on
plot(x,x,'k:')



% now plot RF and summed circular response
acc  = 20;
range = [-pi:.01:pi];
[x,y] = meshgrid(range,range);
s = round(pi/4*acc)/acc;
rf =  rfGaussian2d(x,y,s,s,0,0.5,0);
rf = rf./max(rf(:));
rf(x==0) = 1;
rf(y==0) = 1;

figure(2);clf;
imagesc(rf);axis image square off;colormap('gray');


dist = round(sqrt(x.^2+y.^2)*acc)/acc;
keep = unique(dist);
keep = keep(keep<=max(range));

pp = zeros(size(keep));
for n=1:length(keep);
  ring  = find(dist == keep(n));
  pp(n) = sum(rf(ring));
end;


figure(3);clf;
plot(keep,pp,'k');hold on;
trueP = find(keep==0.5);
trueP = trueP(1);
plot([1 1]*0.5,[0 pp(trueP)],'k:');
findP = find(pp==max(pp));
findP = findP(ceil(length(findP)./2));
plot([1 1]*keep(findP),[0 pp(findP)],'k:');
axis([0 pi 0 max(pp)]);
set(gca,'YTick',[]);
