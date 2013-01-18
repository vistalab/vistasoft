%script:  tensorFun
%
% Render an ellipsoid with specified eigenvalues
%
%
%

%% Set up the eigenvectors
% clear all; close all
ev = [1 1 3];

% Render an ellipsoid with specified eigenvalues
[px py pz] = ellipsoid(1,1,1,ev(1),ev(2),ev(3),32);
surf(px,pz,py,repmat(256,size(px)),'EdgeAlpha',0.2,'EdgeColor',[0 0 0]);
camlight; 
lighting phong; material shiny; 
set(gca, 'Projection', 'perspective');
axis equal vis3d off; colormap(copper);
view(-20,60);
set(gcf,'Position',[400 30 600 600]);
whitebg(gcf,'white')

%% Save it as a png file in the current directory
mrUtilPrintFigure('ellipsoid.png',gcf,0);
disp('Saved as ellipsoid.png in current dir');

%% Add an axis
axLen = ev.*2+.2;
hold on;
line([0;axLen(1)],[0;0],[0;0],'Color','r','LineWidth',2);
line([0;0],[0;axLen(2)],[0;0],'Color','g','LineWidth',2);
line([0;0],[0;0],[0;axLen(3)],'Color','b','LineWidth',2);
hold off;

%% First we'll build a diffusion tensor from a simple 6-direction encoding
% scheme. By using 6 directions, we guarantee that the tensor will
% perfectly fit the data. (But the code below will work for any number of
% directions.)
bvecs = [1,1,0; 1,0,1; 0,1,1; -1,1,0; -1,0,1; 0,-1,1];
% Make sure bvecs are unit vectors
bvecs = bvecs./repmat(sqrt(sum(bvecs.^2,2)),1,3);
adc = [1 2 3 1 2 1];
% Solve for the diffusion tensor D:
m = [bvecs(:,1).^2 bvecs(:,2).^2 bvecs(:,3).^2 2*bvecs(:,1).*bvecs(:,2) 2*bvecs(:,1).*bvecs(:,3) 2*bvecs(:,2).*bvecs(:,3)];
coef = pinv(m)*adc';
D = [coef(1) coef(4) coef(5); coef(4) coef(2) coef(6); coef(5) coef(6) coef(3)]; 

% Confirm that D can accurately predict the ADC data
for(ii=1:length(adc))
  pAdc(ii) = bvecs(ii,:)*D*bvecs(ii,:)';
end
fprintf('max diff between ADC and predicetd ADC: %g\n',max(abs(pAdc-adc)));

%% Compute the surfaces
%
[x,y,z] = sphere(32);
sz = size(x);
u = [x(:), y(:), z(:)];

[vec,val] = eig(D);

dirADC = diag(adc)*bvecs;
% The probability that a spin at the origin will move to position v at time
% t given diffusion tensor D is:
%p_x = 1./sqrt(det(D)*(4*pi*t).^3) * exp(-(v*D-1*v')./(4*t));
 
% Using the diffusion tensor to transform the unit sphere coords
% produces an ellipsoid, even if there are non-zero off-diagonals in D.
e{1} = u*D;

% But using D to get predicted ADC values for each direction and then
% scaling the unit sphere points by that predicted ADC produces a
% peanut. This is the proper way to predicted ADC profile. This is clear
% when we render the surface along with the original ADC values.
for(ii=1:size(u,1))
    sphAdc(ii) = u(ii,:)*D*u(ii,:)';
end
% scale the unit vectors by the predicted ADC for each vector
e{2} = diag(sphAdc)*u;

% Using the eigenvalue decomposition also produces an ellipsoid. This
% ellipsoid DOES NOT represent the predicted ADC profile. Rather, it
% represents the RMS diffusion distance of spins that began at the center
% of the voxel. Note that this surface will accurately predict the ADC
% values that happen to fall exactly on one of the three axes of the
% ellipsoid. (They'd better, since the eigenvalues are taken as the ADC's
% along the three axes of the ellipsoid.) This surface does not, however,
% predict the ADC profile.
e{3} = u*sqrt(2*val)*vec';


%% Render the surfaces
%
figure;
titles = {'u*D','Predicted ADC','Eigen'};
cmap = [autumn(255); [.25 .25 .25]];
for(ii=1:length(e))
    subplot(1,length(e),ii);
    x = reshape(e{ii}(:,1),sz); y = reshape(e{ii}(:,2),sz); z = reshape(e{ii}(:,3),sz);
    surf(x,y,z,'EdgeAlpha',0.1);
    hold on;
    for(jj=1:length(adc))
        [px py pz] = ellipsoid(dirADC(jj,1),dirADC(jj,2),dirADC(jj,3),.1,.1,.1,8);
        surf(px,py,pz,repmat(256,size(pz)),'EdgeAlpha',0);
    end
    hold off;
    axis equal vis3d; colormap(cmap); alpha 0.5;
    title(titles{ii});
    xlabel('x');ylabel('y');zlabel('z');
end

%% Tony stuff

% Drawing the ellipsoid that our ADC measurements correspond with
[xmesh, ymesh, zmesh] = meshgrid(-3:0.1:3,-3:0.1:3,-3:0.1:3);
vmesh = coef(1)*xmesh.^2 + coef(2)*ymesh.^2 + coef(3)*zmesh.^2 + coef(4)*2*xmesh.*ymesh + coef(5)*2*xmesh.*zmesh + coef(6)*2*ymesh.*zmesh;
figure; 
p = patch(isosurface(xmesh,ymesh,zmesh,vmesh,1));
isonormals(xmesh,ymesh,zmesh,vmesh,p)
set(p,'FaceColor','red','EdgeColor','none','EdgeAlpha',0.1);%
daspect([1 1 1])
hold on;

% Drawing the ellipsoid that corresponds with our covariance matrix of the
% gaussian pdf on the water molecule movement
[U S V] = svd(D);
Dinv = U*diag(1./diag(2*S))*V';
coef_inv = [Dinv(1,1) Dinv(2,2) Dinv(3,3) Dinv(1,2) Dinv(1,3) Dinv(2,3)];
vmesh = coef_inv(1)*xmesh.^2 + coef_inv(2)*ymesh.^2 + coef_inv(3)*zmesh.^2 + coef_inv(4)*2*xmesh.*ymesh + coef_inv(5)*2*xmesh.*zmesh + coef_inv(6)*2*ymesh.*zmesh;
p = patch(isosurface(xmesh,ymesh,zmesh,vmesh,1));
isonormals(xmesh,ymesh,zmesh,vmesh,p)
set(p,'FaceColor','blue','EdgeColor','none','EdgeAlpha',0.1);%
daspect([1 1 1])

% Putting the ADC measurement points onto the ellipsoid
dirADC = diag(1./sqrt(adc))*bvecs;
for(jj=1:length(adc))
    [px py pz] = ellipsoid(dirADC(jj,1),dirADC(jj,2),dirADC(jj,3),.1,.1,.1,8);
    surf(px,py,pz,repmat(256,size(pz)),'EdgeAlpha',0);
end

hold off;
view(3);
camlight 
lighting gouraud
axis equal vis3d; colormap(cmap); alpha 0.5;
xlabel('x');ylabel('y');zlabel('z');
