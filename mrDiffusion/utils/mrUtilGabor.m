function img = mrUtilGabor(radiusPix, sigmaPix, cyclesPerSigma, contrast, phase, orient)
% 
% img = mrUtilGabor(radiusPix, sigmaPix, cyclesPerSigma, [contrast=0.25], [phase=0],[orient=0])
%
% Make a gobor image. Orientation (0=vertical) and phase are in radians.
% E.g.: 
%   img = mrUtilGabor(200, 100, 2);
%   image(img); truesize; colormap gray(256);
%
% Also see the end of this file for more examples.
% 
% HISTORY:
% 2006.01 RFD wrote it.
% 2006.11.07 RFD: added drift demo.


if(~exist('contrast','var') | isempty(contrast))
    contrast = 0.25;
end
if(~exist('phase','var') | isempty(phase))
    phase = 0;
end
if(~exist('orient','var') | isempty(orient))
    orient = 0;
end
sigmasPerImage = 2*radiusPix/sigmaPix;
[x,y] = meshgrid(-radiusPix:radiusPix,-radiusPix:radiusPix);
imgPix = size(x,1);
% cycles per pixel
sf = (sigmasPerImage*cyclesPerSigma)/imgPix*2*pi;
a = cos(orient)*sf;
b = sin(orient)*sf;
spatialWindow = exp(-((x/sigmaPix).^2)-((y/sigmaPix).^2));
img = spatialWindow.*contrast.*sin(a*x+b*y+phase);
img = img/2+.5;
img = uint8(round(img*255));
return;

%%%%%%%%%%%%%%%%%%%%%%
% MORE EXAMPLES
%%%%%%%%%%%%%%%%%%%%%%
% Drifing grating demo
contrast = 0.25;
sf = 2;
nFrames = 31;
ph = linspace(0,8*pi,nFrames);
tw = 1-cos(linspace(0,2*pi,nFrames));
cmap = [gray(255);[1 0 0]];
isi = 10;
for(ii=1:nFrames)
  im{ii} = mrUtilGabor(127.5,64,sf,tw(ii)*contrast,ph(ii));
end
for(ii=1:isi)
  im{nFrames+ii} = im{1};
end
ph = linspace(6*pi,0,nFrames);
for(ii=1:nFrames)
  im{nFrames+isi+ii} = mrUtilGabor(127.5,64,sf,tw(ii)*contrast,ph(ii));
end
for(ii=1:length(im))
  % add a fixation mark
  im{ii}(im{ii}==255) = 254; im{ii}(im{ii}==0) = 1;
  for(jj=-1:1) for(kk=-1:1)
    im{ii}(128+jj,128+kk) = 255;
  end; end;
  m(ii) = im2frame(im{ii},cmap);
end

movie(m,1,30);
movie2avi(m,'drift.avi','FPS',30,'COMPRESSION','Cinepak','QUALITY',100);
% Other compression methods don't seem to work