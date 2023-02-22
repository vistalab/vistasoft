data = load('splenium');

% This will double the number of ADC points by reflection. 
% It's useful for visually 'filling-out' sparse and/or clustered gradient dirs.
reflectADCs = true;
% The bvecs are all unit vectors pointed in three space. 
%plot3(data.bvecs(1,:),data.bvecs(2,:),data.bvecs(3,:),'.'); axis equal

figure(1)
dirADC = data.bvecs*diag(data.splAdc);
if(reflectADCs), dirADC = [dirADC, -1*dirADC]; end
dirADC = dirADC';
subplot(1,2,1)
plot3(dirADC(:,1),dirADC(:,2),dirADC(:,3),'.'); axis equal; grid on

% 
% dirADC2 = data.bvecs*diag(sqrt(data.splAdc));
% if(reflectADCs) dirADC2 = [dirADC2, -1*dirADC2]; end
% dirADC2 = dirADC2';
% subplot(1,2,2)
% plot3(dirADC2(:,1),dirADC2(:,2),dirADC2(:,3),'.'); axis equal; grid on

% Compute the diffusion tensor D using a least-squares fit.
bv = data.bvecs';
m = [bv(:,1).^2 bv(:,2).^2 bv(:,3).^2 bv(:,1).*bv(:,2) bv(:,1).*bv(:,3) bv(:,2).*bv(:,3)];
coef = pinv(m)*data.splAdc;
D = [coef(1) coef(4)/2 coef(5)/2; coef(4)/2 coef(2) coef(6)/2; coef(5)/2 coef(6)/2 coef(3)]; 

% Compute the error of the predicted ADC based on the tensor model.
pADC = m*coef;
adcError = pADC-data.splAdc;
sqrt(sum(adcError.^2))
pDirADC = [data.bvecs*diag(pADC)]';
if(reflectADCs)
   pDirADC = [pDirADC; -1*pDirADC];
   adcError = [adcError; adcError];
end
figure(1);
plot3(dirADC(:,1),dirADC(:,2),dirADC(:,3),'k.')
axis equal; grid on;

figure(2)
plot3(dirADC(:,1),dirADC(:,2),dirADC(:,3),'k.',...
    pDirADC(:,1),pDirADC(:,2),pDirADC(:,3),'r.')
axis equal; grid on;

%% Compute the diffusion ellipsoid
% This ellipsoidal surface represents the RMS diffusion distance traversed 
% in time T. The length of each of the ellipsoid axes is 2*lambda_i*T, 
% where lambda_i is the eigenvalue for that axis and T is the diffusion time. 
% Since the ADCs are per unit time, we set T to 1. 
% (See, e.g., Le Bihan et. al. 2001, JMRI) 

% First make the unit sphere vectors
[x,y,z] = sphere(15);
sz = size(x);
u = [x(:), y(:), z(:)];

% scale the unit vectors according to the eigensystem of D to make the ellipsoid 
[vec,val] = eig(D);
% 2*lambda_i*T; T=1
e = u*(2*val)*vec';

% Now reshape and plot
x = reshape(e(:,1),sz); y = reshape(e(:,2),sz); z = reshape(e(:,3),sz);
 
figure(2);
cmap = autumn(255);
surf(x,y,z,repmat(1,size(z)));
axis equal, colormap([.25 .25 .25; cmap]), alpha(0.5)

% Add the points
errInd = abs(adcError); errInd = round(errInd./max(errInd).*(size(cmap,1)-1)+2);
hold on; 
for(ii=1:length(errInd))
   [sx sy sz] = ellipsoid(dirADC(ii,1),dirADC(ii,2),dirADC(ii,3),.05,.05,.05);
   h(ii) = surf(sx,sy,sz,repmat(errInd(ii),size(sx)),'EdgeAlpha',0);
end
lighting phong;
material shiny;
line([0;3.5],[0;0],[0;0],'Color','r','LineWidth',2);
line([0;0],[0;1.5],[0;0],'Color','g','LineWidth',2);
line([0;0],[0;0],[0;1.5],'Color','b','LineWidth',2);
axis off; grid off;
%scatter3(dirADC(:,1),dirADC(:,2),dirADC(:,3),24,cmap(errInd,:),'.'); 
hold off
% At this point, turn on the lighing from the figure's 'camera' toolbar.
% How do we do this from the command line?
mrUtilMakeColorbar(autumn(254),{'0.0',0.25','0.5','0.75','1.0'},'ADC error (\mum^2/msec)');
