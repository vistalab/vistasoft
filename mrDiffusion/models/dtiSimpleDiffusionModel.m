% The following is derived from the sample code of Garcia's "Numerical
% Methods for Physics" (dftcs.m). See also:
%   http://webphysics.davidson.edu/Faculty/wc/WaveHTML/node17.html#SECTION00445000000000000000
%

% The following code solves the diffusion equation (also known as the heat
% equation) using the Forward Time Centered Space (FTCS) scheme.

clear;

%% Initialize parameters (time step, grid spacing, etc.).

% Diffusion coefficient
kappa = 1.9;   % micrometers^2/millisecond

% time-step. This should be short to assure a stable solution.
tau = 0.005; % milliseconds
maxTime = 40; % milliseconds

% Number of spatial grid points- determines the spatial resolution of the
% solution. If you want this to be big, you have to reduce tau.
N = 241;

% The system extends from x=-L/2 to x=L/2
L = 100;  % micrometers

h = L/(N-1);  % Grid size
coeff = kappa*tau/h^2;
if( coeff >= 0.5 )
  error('Solution is expected to be unstable');
end

%* Set initial and boundary conditions.
tt = zeros(N,1);          % Initialize temperature to zero at all points
% Initial cond. is delta function in center
%tt(round(N/2)) = 1/h;
% Rather than normalized temperature, we want the probability
tt(round(N/2)) = 1;
%% The boundary conditions are tt(1) = tt(N) = 0

%* Set up loop and plot variables.
xplot = (0:N-1)*h - L/2;   % Record the x scale for plots
iplot = 1;                 % Counter used to count plots
nstep = ceil(maxTime./tau);               % Maximum number of iterations
nplots = nstep;               % Number of snapshots (plots) to take
plot_step = nstep/nplots;  % Number of time steps between plots
tplot(iplot) = 0;
concentration(:,iplot) = tt(:);
iplot = iplot+1;
%* Loop over the desired number of time steps.
h = mrvWaitbar(0,'Computing concentrations...');
for istep=1:nstep  %% MAIN LOOP %%
    %* Compute new temperature using FTCS scheme.
    tt(2:(N-1)) = tt(2:(N-1)) + ...
        coeff*(tt(3:N) + tt(1:(N-2)) - 2*tt(2:(N-1)));
    concentration(:,iplot) = tt(:);
    tplot(iplot) = istep*tau;
    iplot = iplot+1;
    mrvWaitbar(istep/nstep,h);
end
close(h);

%* Plot temperature versus x and t in various forms.
figure;
imagesc(tplot,xplot,concentration); colormap(hot(256)); axis image; colorbar;
xlabel('Time (ms)'); ylabel('position (\mumeter)');
title(sprintf('Diffusion from a point (D=%0.2f \\mum^2/ms)',kappa));



delta = 30;
deltaInd = find(tplot==delta);
figure;
plot(xplot,concentration(:,deltaInd),'b.');
xlabel('position (\mumeter)');
ylabel('concentration');
title(sprintf('Concentration at time %0.1f ms for diffusion coefficient of (D=%0.2f \\mum^2/ms)',delta,kappa));

% A very simple cylindrical axon model. We assume everything is constant
% along the length so that we can just model a 2d cross-section of the
% axon. We further assume that the axon is radially symmetric so that we
% can use a 1d diffusion model. The basic logic is to:
%
% 1. Compute the 1d diffusion model for the range of sapce/time that we need
% 2. Select the time slice that we want to look at
% 3. Fit a gaussian to the concentration across space for that time slice.
%    Note that this is essentially a perfect fit, centered on 0, so the
%    only free param is the variance.
% 4. Plug the fitted variance parameter into the cumulative normal (cpdf).
% 5. From the cpdf model we can estimate the concvcentration in the tails,
%    which corresponds to the concentration outside the membrane, which we
%    take to be the proportion of protons that would have hit the membrane.
%
% The membrane is simply the perimeter of our circular cross-section:
% x = r*cos(theta); y = r*sin(theta);
% where r is the axon radius and theta is the angle.
% For any point in the axon, the distance to the membrane is:
% 
axonRadius = [0.25:.25:5];
theta = [-pi:.1:pi];
conc = concentration(:,deltaInd)';
% gaussiam:
%g = 1/(s*sqrt(2*pi))*exp(-(x-m).^2./2*s.^2);
gfunc = @(s,h,x,y) sqrt(mean(((h.*exp(-(x.^2)./(2.*s.^2)))-y).^2));
h = conc(find(xplot==0));
s = 10; % 25ms = 9.7
s = fminsearch(@(s) gfunc(s,h,xplot,conc), s) 
g = h.*exp(-(xplot.^2)./(2.*s.^2));
hold on;plot(xplot,g,'r-');
% Once we have the best-fitting gaussian, we can just use the cumulative
% normal form to compute the area in the tails:
% cumnorm = .5*(1+erf(10/s*sqrt(2))
% areaInBothTails = (1-.5*(1+erf(10/s*sqrt(2))))*2
pHitMembrane = zeros(length(axonRadius),1);
for(ii=[1:length(axonRadius)])
    r = axonRadius(ii);
    % Grid the circle that represents a slice through an axon
    gridPts = dtiBuildSphereCoords([0,0], r.*20)./20;
    % Grid the perimeter of the axon, which represents the cell membrane
    for(jj=1:length(theta))
        membraneX(jj) = r*sin(theta(jj)); membraneY(jj) = r*cos(theta(jj));
    end
    %figure;plot(gridPts(:,1),gridPts(:,2),'ro',membraneX,membraneY,'bo');axis equal;
    % compute distance from each point in the axon to each point on the membrane 
    pHitMembranePt = zeros(size(gridPts,1),1);
    for(jj=1:size(gridPts,1))
        d = sqrt((gridPts(jj,1)-membraneX).^2+(gridPts(jj,2)-membraneY).^2);
        % Sum the concentrations between the membrane distance and infinity.
        pHitMembranePt(jj) = mean((1-.5*(1+erf(d./(s.*sqrt(2))))).*2);
    end
    pHitMembrane(ii) = mean(pHitMembranePt);
    %xint = [find(xplot==-r) find(xplot==r)];
    %PmembraneCollision(ii) = 1-sum(conc([xint(1):xint(2)]));
end
figure; plot(axonRadius*2, pHitMembrane, 'ko');
xlabel('Axon diameter (\mumeter)');
ylabel('Proportion membrane collisions');
title(sprintf('P(membrane collision) at time %0.1f ms for ADC=%0.2f \\mum^2/ms)',delta,kappa));

%figure(2); clf; mesh(tplot,xplot,concentration);
%xlabel('Time');  ylabel('x');  zlabel('T(x,t)');
%title('Diffusion of a delta spike');

%figure(3); clf;       
%contourLevels = 0:0.1:1;  contourLabels = 0:5;     
%cs = contour(tplot,xplot,concentration,contourLevels);  % Contour plot
%clabel(cs,contourLabels);  % Add labels to selected contour levels
%xlabel('Time'); ylabel('x'); title('Temperature contour plot');
