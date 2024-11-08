function [eVec,h,ptsAndCrv] = covEllipsoid(xyData,nSD,h, nSamp)
% Caclculate the covariance ellipse for an xy-data set
%
%    [eVec,h,ptsAndCrv] = covEllipsoid(xyData,nSD,h, nSamp)
%
% eVec: Function returns a set of vectors that define the ellipsoid (eVec).
%       These are plotted if no return is requested.  The data can be 2 or
%       3 dimensional
% h: is the handle to the plot figure.
%
% Example
%  xyData = [68.5 533; 39.5 618; 79 655; 58 546;35 635; 62 720; 92 529];
%  nSD = 2;
%  covEllipsoid(xyData,nSD,figure(1))
%
%  eVec = covEllipsoid(xyData,nSD);
%  figure; plot(eVec(:,1),eVec(:,2),'--'); axis equal
%
%  xyzData = randn(20,3);
%  nSD = 2;
%  [eVec,h,pc] = covEllipsoid(xyzData,nSD,figure(1));
%
% (c) Stanford VISTA Team

% TODO:  This is covEllipse, not covEllipsoid, as things stand.
% We should handle the 3D case.

if notDefined('xyData'), error('xyData required'); end
if notDefined('nSD'), nSD = 1; end
if notDefined('nSamp'), nSamp = 20; end

dimensionality = size(xyData,2);

switch dimensionality
    case 2
        % Two dimension - ellipse case.
        % Create a circle of unit vectors to transform into the data covariance format
        [x,y] = circlePoints(2*pi*0.01);
        uVec = [x; y]';
    case 3
        % Ellipsoid case.
        [x,y,z] = sphere(nSamp);
        sz = size(x);
        uVec = [x(:), y(:), z(:)];
    otherwise
        error('Bad dimensionality of data %d\n',dimensionality);
end

% This is the quadratic (positive-definite) form that describes the
% covariance of the data
E = cov(xyData);

eVec = zeros(size(uVec));
mn = mean(xyData);
for ii=1:size(uVec,1)
    len = uVec(ii,:)*(E\uVec(ii,:)');
    eVec(ii,:) = nSD*(uVec(ii,:)/sqrt(len)) + mn;
end

% Plot on return, or not
if notDefined('h'), return;  % No figure handle
else
    figure(h); clf
    switch dimensionality
        case 2
            pts = plot(xyData(:,1),xyData(:,2),'.'); hold on;
            crv = plot(eVec(:,1),eVec(:,2),'--');
            if nargout == 3
                ptsAndCrv.pts = pts;
                ptsAndCrv.crv = crv;
            end

        case 3
            pts = plot3(xyData(:,1),xyData(:,2),xyData(:,3),'.'); 
            hold on;
            s = surfl(reshape(eVec(:,1),sz(1),sz(2)),...
                reshape(eVec(:,2),sz(1),sz(2)),...
                reshape(eVec(:,3),sz(1),sz(2)));
            % eVec = unique(eVec,'rows');
            % T = delaunay3(eVec(:,1),eVec(:,2),eVec(:,3));
            % colormap(0.5*ones(256,3));
            % tetramesh(T,eVec,'FaceAlpha',0.01,'EdgeAlpha',0.01);
            axis on, grid on; axis equal
            set(gca, 'Projection', 'perspective');
            set(s,'EdgeAlpha',0.05)
            hold off
            
            camlight;
            alpha(0.3); lighting phong; material shiny; shading interp
            cmap = autumn(255); colormap([cmap; .25 .25 .25]);
            if nargout == 3
                ptsAndCrv.pts = pts;
                ptsAndCrv.surf = s;
            end
            
        otherwise
            error('Bad dimensionality of data %d\n',dimensionality);
    end
    axis equal, hold off

end




return;



