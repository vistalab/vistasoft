function npResults

load('safirData.mat');
load('safirResult.mat');

col = hsv(256);
Omega = [1 1];
m = 2^maxLevel * [1 1];
X = getGrid(Omega,m);
Y = stg2center(yOpt,m,'Py');


OV = ip2mat(interpolation(areasImg,Omega,X),m);
OV(isnan(OV))=0;
OV = double(edge(OV, 'sob', 0.005));
OV(OV>1) = 0.2;


M1i=interpolation(RD1,Omega,X);
M2i=interpolation(RD2,Omega,X);
A1i=interpolation(TD1,Omega,X);
A2i=interpolation(TD2,Omega,X);
A1ti=interpolation(TD1,Omega,Y);
A2ti=interpolation(TD2,Omega,Y);
OVi=interpolation(OV,Omega,X);
OVti=interpolation(OV,Omega,Y);
W1i=interpolation(WD1,Omega,X);
W1ti=interpolation(WD1,Omega,Y);
W2i=interpolation(WD2,Omega,X);
W2ti=interpolation(WD2,Omega,Y);

M1t=ip2mat(M1i,m);
M2t=ip2mat(M2i,m);
A1t=ip2mat(A1ti,m);
A2t=ip2mat(A2ti,m);
OVt=ip2mat(OVti,m);
W1t=ip2mat(W1ti,m);


figure(51)
image(mergedImage(A1t,OVt,col));
axis off;axis image;

figure(52)
h = Omega./m;
MM=flipdim(mergedImage(A2t,OVt,col),1);
image(h(1)/2:h(1):1,h(2)/2:h(2):1,MM);
axis image; axis xy;
 

figure(53)
image(mergedImage(M2t,OVt,col));
axis off;axis image;

figure(54)
image(mergedImage(M2t,OVt,col));
axis off;axis image;

% A1t(isnan(A1t))=0;
% A2t(isnan(A2t))=0;
% 
% if maskflag==1
%   D1=mergedImage2(abs(RD1-A1t),OVt,(WD1>0),1-gray);
%   D2=mergedImage2(abs(RD2-A2t),OVt,(WD2>0),1-gray);
% else
%   D1=mergedImage2(abs(M1-A1t),OVt,(A1>0),1-gray);
%   D2=mergedImage2(abs(M2-A2t),OVt,(A2>0),1-gray);
% end

return

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------

function A=ip2mat(B,m)
A=flipud(reshape(B,m)');
return
% -------------------------------------------------------------------------
function out = edge(T,mode,tresh)

out = zeros(size(T));

Sx = 0.125*[1 2 1; 0 0 0; -1 -2 -1];
Sy = Sx';

Tx =  conv2(T,Sx,'same');
Ty =  conv2(T,Sy,'same');

out = Tx.^2 + Ty.^2;

out(out<tresh) = 0;
return

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------


% function displayResults8(Y,his,maskflag,alpha,beta,reg)
Omega=[1 1];
m=sqrt(length(Y)/2);
level=log2(m);
m=[m m];

load('warp-data');
switch maskflag
  case 1
    W1=(areasImg>0);W2=W1;
  case 2
    W1=(A1>0);W2=(A2>0);
  otherwise
    W1=ones(size(A1));W2=W1;
end

filename=['a' num2str(alpha) '_b' num2str(beta) '_' reg '_m' num2str(maskflag) '_'];
path=['H:\Masterarbeit\Images\'];

ML=getMultiLevel8('dlinear-p',M1,A1,M2,A2,W1,W2,areasImg,level,level);

% % % menustr={'Originale','Transformiert','Distanzen','Merged','Ende'};
% % % last=length(menustr);
% % % choice=menu('W?Ë?hle',menustr)
% % % while choice<last
% % % disp(menustr{choice})
% % % switch choice
% % %     case 1
% % %     case 2
% % %     case 3
% % %     case 4
% % %
% % %     otherwise break;
% % % end
% % % choice=menu('W?Ë?hle',menustr)
% % % end
close(gcf);
% keyboard
X=getGrid(Omega,m);
col=colormap(hsv(256));
M1=ML{level}.M1;
M2=ML{level}.M2;
A1=ML{level}.A1;
A2=ML{level}.A2;
OV=ML{level}.OV;
W1=ML{level}.W1;
W2=ML{level}.W2;

M1i=interpolation('dlinear-smooth',M1,Omega,X);
M2i=interpolation('dlinear-smooth',M2,Omega,X);
A1i=interpolation('dlinear-smooth',A1,Omega,X);
A2i=interpolation('dlinear-smooth',A2,Omega,X);
A1ti=interpolation('dlinear-smooth',A1,Omega,Y);
A2ti=interpolation('dlinear-smooth',A2,Omega,Y);
OVi=interpolation('dlinear-smooth',OV,Omega,X);
OVti=interpolation('dlinear-smooth',OV,Omega,Y);
W1i=interpolation('dlinear-smooth',W1,Omega,X);
W1ti=interpolation('dlinear-smooth',W1,Omega,Y);
W2i=interpolation('dlinear-smooth',W2,Omega,X);
W2ti=interpolation('dlinear-smooth',W2,Omega,Y);
A1t=ip2mat(A1ti,m);
A2t=ip2mat(A2ti,m);
OVt=ip2mat(OVti,m);
W1t=ip2mat(W1ti,m);
W2t=ip2mat(W2ti,m);


% figure(1)
% image(mergedImage(M1,zeros(size(M1)),col));
% axis off;axis image;
% figure(2)
% image(mergedImage(M2,zeros(size(M2)),col));
% axis off;axis image;
% figure(3)
% image(mergedImage(A1,OV,col));
% axis off;axis image;
% figure(4)
% image(mergedImage(A2,OV,col));
% axis off;axis image;
% figure(5)
% image(mergedImage(M1,OV,col));
% axis off;axis image;
% figure(6)
% image(mergedImage(M2,OV,col));
% axis off;axis image;
figure(7)
image(mergedImage(A1t,OVt,col));
axis off;axis image;
%hgsave([path filename 'A1.fig']);[path filename 'A1.fig']
figure(8)
image(mergedImage(A2t,OVt,col));
axis off;axis image;
%hgsave([path filename 'A2.fig']);
figure(9)
image(mergedImage(M1,OVt,col));
axis off;axis image;
%hgsave([path filename 'M1.fig']);
figure(10)
image(mergedImage(M2,OVt,col));
axis off;axis image;
%hgsave([path filename 'M2.fig']);
A1t(isnan(A1t))=0;
A2t(isnan(A2t))=0;
if maskflag==1
  D1=mergedImage2(abs(M1-A1t),OVt,(W1>0),1-gray);
  D2=mergedImage2(abs(M2-A2t),OVt,(W2>0),1-gray);
else
  D1=mergedImage2(abs(M1-A1t),OVt,(A1>0),1-gray);
  D2=mergedImage2(abs(M2-A2t),OVt,(A2>0),1-gray);
end
% figure(11)
% image(D1);
% axis off;axis image;
% hgsave([path filename 'D1.fig']);
% figure(12)
% image(D2);
% axis off;axis image;
% hgsave([path filename 'D2.fig']);
% plotHis8(his,alpha,beta);
% hgsave([path filename 'His.fig']);
%
return


function rgb = mergedImage(img, overlay, cmap)
% transform the image into RGB
overlay=1-overlay;
img = ceil(img*size(cmap,1)/pi/2);
img(isnan(img)) = 1;
img(img<1) = 1;
img(img>size(cmap,1)) = size(cmap,1);
cmap(1,:)=[1 1 1];
rgb(:,:,1) = reshape(cmap(img,1),size(img));
rgb(:,:,2) = reshape(cmap(img,2),size(img));
rgb(:,:,3) = reshape(cmap(img,3),size(img));
rgb(:,:,1) = rgb(:,:,1).*overlay;
rgb(:,:,2) = rgb(:,:,2).*overlay;
rgb(:,:,3) = rgb(:,:,3).*overlay;
return;
function rgb = mergedImage2(img, overlay,A , cmap)
% transform the image into RGB
overlay=1-overlay;
img = ceil(img*size(cmap,1)/pi/2);
img(isnan(img)) = 1;
img(img<1) = 1;
img(img>size(cmap,1)) = size(cmap,1);
cmap(1,:)=[1 1 1];
rgb(:,:,1) = reshape(cmap(img,1),size(img));
rgb(:,:,2) = reshape(cmap(img,2),size(img));
rgb(:,:,3) = reshape(cmap(img,3),size(img));
% keyboard
R1=rgb(:,:,1);
R1(A)=R1(A)/2;
rgb(:,:,1)=R1;
rgb(:,:,1) = rgb(:,:,1).*overlay;
rgb(:,:,2) = rgb(:,:,2).*overlay;
rgb(:,:,3) = rgb(:,:,3).*overlay;
return;