function [uData, h] = dwiPlot(dwi,pType,varargin)
% Gateway routine for plotting diffusion weighted images
%
%   [uData, h]  = dwiPlot(dwi,pType,varargin)
%
% dwi is a struct with fields containing
%  .ni
%  .bvecs
%  .bvals
%
% Types of plots
%   bvecs:   The bvecs
%   bvals:   Bvals.
%   adc:     The ADC shown as lengths of the corresponding bvecs
%            If a tensor is also passed, then the predicted ADC is shown as
%            a surface
%   'dsig distance image xy'
%   'dsig distance image azel'
%   'dsig distance image polar'
%   'diffusion distance image xy'
%   'diffusion distance image azel'
%   'diffusion distance image polar'
%   'diffusion distance'  - Points and a surface
%   'adc image xy'
%   'adc image azel'
%   'adc image polar'
%   'dsig image xy'
%   'dsig image azel'
%   'dsig image polar'

% Examples:
%   dwiPlot(dwi,'bvals');
%   dwiPlot(dwi,'bvecs');
%   dwiPlot(dwi,'adc',ADC);
%   dwiPlot(dwi,'adc',ADC,Q);
%   dwiPlot(dwi,'adc flat image',ADC);
%   dwiPlot(dwi,'dsig flat image',dSig);
%
%   dwiPlot(dwi,'adc azel image',ADC);
%
% See also:
%
% (c) Stanford VISTA Team, 2011

if notDefined('pType'), pType = 'bvecs'; end

% Generic parameters
pType = mrvParamFormat(pType);
if length(varargin) == 2, figTitle = varargin{2};
else                      figTitle = pType;
end

% Initialize returns and possibly open the graph window
uData = []; h = []; doPlot = 0;

% Only make the plot if there are no output arguments
if nargout == 0, h = mrvNewGraphWin(figTitle); doPlot = 1;end

% Generic parameters
dx = 0.1;   % Spatial resolution for images
pType = mrvParamFormat(pType);

switch pType
    case {'bvals'}
        bvals = dwi.bvals;
        plot(1:length(bvals),bvals,'-x');
        xlabel('Scan')
        ylabel('B-value')
        set(gca,'ylim',[min(bvals(:)),max(bvals(:))*1.05])
        grid on
        
    case {'bvecs'}
        % To become a dwiGet(dwi,'bvals positive')
        % Find the positive values
        bvals = dwi.bvals;
        bvecs = dwi.bvecs;
        lst   = (bvals == 0);
        bvals = bvals(~lst);
        bvecs = bvecs(~lst,:);
        
        X = diag(bvals)*bvecs; X = unique(X,'rows');
        T = DelaunayTri(X(:,1),X(:,2),X(:,3));
        
        % From the Mathworks doc tetramesh example
        %    dt = DelaunayTri(x,y,z);
        %    Tes = dt(:,:);
        %    X = [x(:) y(:) z(:)];
        %    tetramesh(Tes,X);
        colormap(gray(256))
        tetramesh(T(:,:),X);
        axis on; grid on; axis equal;
        
    case {'ddist','diffusiondistance'}
        % dwiPlot(dwi,'dDist',dDist,Q) - Shows prediction and data
        % dwiPlot(dwi,'adc',dDist)     - Shows just the data
        % Plot the diffusion distance values along the bvec directions.
        % If a Q is passed in as the 2nd argument, use that tensor to plot
        % the predicted surface.
        
        if isempty(varargin), error('ADC data required.');
        else dDist = varargin{1};
        end
        
        t = sprintf('dDist: ');
        % Start the figure
        cmap = autumn(255);
        
        % We use this to get the predicted ADC values from the tensor
        % We plot the surface if available.
        if length(varargin) > 1
            % User passed in Q, make the predicted distances
            Q = varargin{2};
            
            % This should be a function like dtiPlotDist(Q)
            %
            [X,Y,Z] = sphere(15);
            [r,c] = size(X);
            
            v = [X(:),Y(:),Z(:)];
            adcPredicted = diag(v*Q*v');
            % The diffusion distance is the length of the vector, v, such
            % that v' Q v = 1.  We know that for unit length vectors, the
            % adc = u' Q u.  So, v = u / sqrt(adc).
            v = diag(1./sqrt(adcPredicted))*v;
            
            x = reshape(v(:,1),r,c);
            y = reshape(v(:,2),r,c);
            z = reshape(v(:,3),r,c);
            surf(x,y,z,repmat(256,r,c),'EdgeAlpha',0.1);
            axis equal, colormap([cmap; .25 .25 .25]), alpha(0.5)
            camlight; lighting phong; material shiny;
            set(gca, 'Projection', 'perspective');
            hold on
            t = sprintf('%s Predicted (surf) and',t);
        end
        
        % Compute and plot vectors of measured distances
        bvecs = dwiGet(dwi,'diffusion bvecs');
        dDistV = diag(dDist)*bvecs;
        plot3(dDistV(:,1),dDistV(:,2),dDistV(:,3),'.')
        grid on
        title(sprintf('%s Measured (points)',t));
        
    case {'adc'}
        % dwiPlot(dwi,'adc',adc,[Q]) - Shows prediction and data
        % dwiPlot(dwi,'adc',ADC)     - Shows just the data
        % Plot the adc values along the bvec directions.
        % If a Q is passed in as the 2nd argument, use that tensor to plot
        % the predicted surface.
        
        if isempty(varargin), error('ADC data required.');
        else adc = varargin{1};
        end
        
        t = sprintf('ADC: ');
        % Start the figure
        cmap = autumn(255);
        
        % We use this to get the predicted ADC values from the tensor
        % We plot the surface if available.
        if length(varargin) > 1
            % User passed in Q, make the predicted peanut
            Q = varargin{2};
            
            % This is dangerous
            if isvector(Q), Q = reshape(Q,3,3); end
                
            [X,Y,Z] = sphere(15);
            [r,c] = size(X);
            
            v = [X(:),Y(:),Z(:)];
            adcPredicted = diag(v*Q*v');
            v = diag(adcPredicted)*v;
            
            x = reshape(v(:,1),r,c);
            y = reshape(v(:,2),r,c);
            z = reshape(v(:,3),r,c);
            surf(x,y,z,repmat(256,r,c),'EdgeAlpha',0.1);
            axis equal, colormap([cmap; .25 .25 .25]), alpha(0.5)
            camlight; lighting phong; material shiny;
            set(gca, 'Projection', 'perspective');
            hold on
            t = sprintf('%s Predicted (surf) and',t);
        end
        
        % The diffusion weighted bvecs
        bvecs = dwiGet(dwi,'diffusion bvecs');
         
        % Compute and plot vector of measured adcs
        adcV = diag(adc)*bvecs;
        uData.adcV = adcV;
        uData.adcPredicted = diag(bvecs*Q*bvecs');
        if doPlot
            h = plot3(adcV(:,1),adcV(:,2),adcV(:,3),'o');
            set(h,'MarkerFaceColor',[0 0 1]);
            grid on
            title(sprintf('%s Measured (points)',t));
        end
        
    case {'adcimagexy','adcimageazel','adcimagepolar'}
        % Create an image of the ADC data, as if you were looking down at
        % the data from the Z-axis
        
        if isempty(varargin), error('ADC data required.');
        else adc = varargin{1};
        end
        
        % This is the flat method
        fType = pType((1+length('adcimage')):end);
        
        % Create the 2D representation
        bvecs = dwiGet(dwi,'diffusion bvecs');
        bFlat = sphere2flat(bvecs,fType);
        
        % Interpolating function on the 2D representation
        F = TriScatteredInterp(bFlat,adc(:));
        
        % Set the (x,y) range and interpolate
        x = min(bFlat(:,1)):dx:max(bFlat(:,1));
        y = min(bFlat(:,2)):dx:max(bFlat(:,2));
        [X Y] = meshgrid(x,y);
        est = F(X,Y);
        
        % Limit the ADC range
        est(1,1) = 4;     % Force peak
        est(end,end) = 1; % Force trough
        l = isnan(est); est(l) = 0;  % Make extrapolated 0 rather than NaN
        
        uData.x = X;
        uData.y = Y;
        uData.data = est;
        
        if doPlot
            % Show it
            mp = hsv; mp(1,:) = [0 0 0]; colormap(mp);
            imagesc(x,y,est);
            axis image;
            switch fType
                case 'xy'
                    xlabel('x'), ylabel('y');
                case 'polar'
                    xlabel('theta'), ylabel('rho');
                case 'azel'
                    xlabel('azimuth'), ylabel('elevation');
                otherwise
                    error('Unknown fType %s\n',fType);
            end
            set(gca,'userdata',uData);
            title('ADC image'); colorbar
            set(get(colorbar,'xlabel'),'string','um^2/ms')
        end
        
    case {'dsigimagexy','dsigimageazel','dsigimagepolar'}
        % dwiPlot(dwi,'dsig image xy',dSig)
        %
        % Create an image of the ADC data, as if you were looking down at
        % the data from the Z-axis
        
        if isempty(varargin), error('dSig data required.');
        else dSig = varargin{1};
        end
        
        % This is the flat method
        fType = pType((1+length('dsigimage')):end);
        
        % Create the 2D representation
        bvecs = dwiGet(dwi,'diffusion bvecs');
        bFlat = sphere2flat(bvecs,fType);
        
        % Interpolating function on the 2D representation
        F = TriScatteredInterp(bFlat,dSig(:));
        
        % Set the (x,y) range and interpolate
        x = min(bFlat(:,1)):dx:max(bFlat(:,1));
        y = min(bFlat(:,2)):dx:max(bFlat(:,2));
        [X Y] = meshgrid(x,y);
        est = F(X,Y);
        
        % Limit the dSig range
        l = isnan(est); est(l) = 0;  % Make extrapolated 0 rather than NaN
        
        uData.x = X;
        uData.y = Y;
        uData.data = est;
        
        if doPlot
            mp = hsv; mp(1,:) = [0 0 0]; colormap(mp);
            imagesc(x,y,est);
            axis image;
            switch fType
                case 'xy'
                    xlabel('x'), ylabel('y');
                case 'polar'
                    xlabel('theta'), ylabel('rho');
                case 'azel'
                    xlabel('azimuth'), ylabel('elevation');
                otherwise
                    error('Unknown fType %s\n',fType);
            end
            
            set(gca,'userdata',uData);        
            title('dSig image'); colorbar
            set(get(colorbar,'xlabel'),'string','Raw signal')
        end
        
    case {'diffusiondistanceimagexy','diffusiondistanceimageazel','diffusiondistanceimagepolar'}
        % dwiPlot(dwi,'diffusion distance image xy',dDist);
        % Show the diffusion distance, which has an ellipsoidal shape for
        % Brownian motion.
        %
        % This is related to 1/sqrt(ADC)
        % The diffusion distance in each bvec direction should be returned
        % by this:
        %
        % dDist = dwiGet(dwi,'diffusion distance',coord,'um')
        
        if isempty(varargin), error('diffusion distance data required.');
        else dDist = varargin{1};
        end
        
        % This is the flat method
        fType = pType((1+length('diffusiondistanceimage')):end);
        
        % Create the 2D representation
        bvecs = dwiGet(dwi,'diffusion bvecs');
        bFlat = sphere2flat(bvecs,fType);
        
        % Interpolating function on the 2D representation
        F = TriScatteredInterp(bFlat,dDist(:));
        
        % Set the (x,y) range and interpolate
        x = min(bFlat(:,1)):dx:max(bFlat(:,1));
        y = min(bFlat(:,2)):dx:max(bFlat(:,2));
        [X Y] = meshgrid(x,y);
        est = F(X,Y);
        
        % Limit the dSig range
        l = isnan(est); est(l) = 0;  % Make extrapolated 0 rather than NaN
        
        % Show it
        mp = hsv; mp(1,:) = [0 0 0]; colormap(mp);
        imagesc(x,y,est);
        axis image;
        switch fType
            case 'xy'
                xlabel('x'), ylabel('y');
            case 'polar'
                xlabel('theta'), ylabel('rho');
            case 'azel'
                xlabel('azimuth'), ylabel('elevation');
            otherwise
                error('Unknown fType %s\n',fType);
        end
        
        title('Diffusion distance'); colorbar;
        set(get(colorbar,'xlabel'),'string','um')
        
        
    case {'dsigspiral'}
        % dwiPlot(dwi,'dsig spiral',iCoord);
        % We flatten the diffusion signal onto a plane.  We then plot a
        % linear graph of the diffusion as we spiral out from the center of
        % the plane to the edge.
        %    iCoord = [44 54 43];
        %    dwiPlot(dwi,'dsig spiral',iCoord)
        % This is equivalent to reorganizing the directions in the original
        % data, as if we were peeling an orange.
        
        if isempty(varargin), error('Image coordinate required');
        else iCoord = varargin{1};
        end
        
        % Create the 2D representation
        bvecs = dwiGet(dwi,'diffusion bvecs');
        bFlat = sphere2flat(bvecs,'xy');
        dSig  = dwiGet(dwi,'dsig image', iCoord);
        
        % Interpolating function on the 2D representation
        F = TriScatteredInterp(bFlat,dSig(:));
        
        % Set the (x,y) range and interpolate
        nSamp = round(sqrt(size(bvecs(:,1),1)));
        x = linspace(min(bFlat(:,1)),max(bFlat(:,1)),nSamp);
        y = linspace(min(bFlat(:,2)),max(bFlat(:,2)),nSamp);
        
        
        [X Y] = meshgrid(x,y);
        est = F(X,Y);
        % est = F(bFlat(:,1),bFlat(:,2));

        inData.x = X; inData.y = Y; inData.data = est;
        
        dwiSpiralPlot(inData);
        
    case{'dsigortho'}
        % Not running
        % Seems to require the mapping toolbox.
        % Orhtographic projection onto a globe
        % dwiPlot(dwi,'dsig ortho',dSig);
        v = ver;
        for ii=1:length(v)
            if strncmp(v(ii).Name,'Mapping',7), HaveMapping = 1; end
        end
        if ~HaveMapping, error('No Mapping Toolbox'); end
        if isempty(varargin), error('dSig data required.');
        else dSig = varargin{1};
        end
        % fType = pType((1+length('dsigimage')):end);
        
        % Create the 2D representation
        bvecs = dwiGet(dwi,'diffusion bvecs');
        % bFlat = sphere2flat(bvecs,fType);
        
        [theta, phi, ~] = cart2sph(bvecs(:,1), bvecs(:,2), bvecs(:,3));
        lat = rad2deg(theta - pi/2);
        lon = rad2deg(phi - pi);
        set(gca,'Projection','ortho')
        % , 'Frame', 'on')
        hold on
        cmap = hot;
        for b=1:length(lat)
            red = cmap(round((dSig(b)/max(dSig))*length(cmap)),1);
            green = cmap(round((dSig(b)/max(dSig))*length(cmap)),2);
            blue = cmap(round((dSig(b)/max(dSig))*length(cmap)),3);
            geoshow(lon(b), lat(b), 'Color', [red green blue], 'Marker','.', 'MarkerSize',20)
        end
        caxis auto
        % cax = caxis;
        colorbar
        caxis([0 max(dSig)]);
        colormap(hot)
        
    case {'dome'}
        % Not running
        if isempty(varargin), error('diffusion distasnce data required.');
        else dSig = varargin{1};
        end
        
        % Matlab version without the mapping toolbox
        [X,Y,Z] = sphere(15);
        [r,c]   = size(X);
        s       = [X(:),Y(:),Z(:)];
        l       = (s(:,3) < 0);
        s(l,:)  = NaN;
        X       = reshape(s(:,1),r,c);
        Y       = reshape(s(:,2),r,c);
        Z       = reshape(s(:,3),r,c);
        
        mrvNewGraphWin('dome plot');
        cmap = autumn;
        surf(X,Y,Z,repmat(size(cmap,1),r,c),'EdgeAlpha',0.1);
        g = 0.5;
        axis equal, colormap([cmap; g g g]), alpha(0.5)
        camlight; lighting phong; material shiny;
        set(gca, 'Projection', 'perspective');
        hold on
        
        % Create the 2D representation
        bvecs = dwiGet(dwi,'diffusion bvecs');
        l = (bvecs(:,3) < 0);
        bvecs(l,:) = NaN;
        dSigN = dSig/max(dSig(:));
        red = cmap(round((dSigN)*length(cmap)),1);
        green = cmap(round((dSigN)*length(cmap)),2);
        blue = cmap(round((dSigN)*length(cmap)),3);
        for ii=1:size(bvecs,1)
            if ~isnan(bvecs(ii,1))
                plot3(bvecs(ii,1),bvecs(ii,2),bvecs(ii,3),'s',...
                    'Color', [red(ii) green(ii) blue(ii)], ...
                    'Marker','.', 'MarkerSize',20)
            end
        end
        colormap(cmap); grid off; axis on;
        set(gca,'xticklabels',[],'yticklabels',[],'zticklabels',[]);
        colorbar
        view(2), set(gca,'Projection','ortho')
        
    otherwise
        error('Unknown plot type: %s\n',pType);
end

return
