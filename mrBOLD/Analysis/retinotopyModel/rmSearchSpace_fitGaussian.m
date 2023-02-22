function [G fit mu sigma] = rmSearchSpace_fitGaussian(V, X, Y, S, v, plotFlag);
% Fit a 3D Gaussian function to the pRF search space for a voxel.
%
%   [G fit mu sigma] = rmSearchSpace_fitGaussian(V, X, Y, S, v, [plotFlag=0]);
%
% 
% 
%
% ras, 01/2009.
if notDefined('v'),		v = 1;			end
V = V(:,:,:,v);
V( isnan(V) | isinf(V) ) = 0;

if notDefined('plotFlag'),	plotFlag = 0;		end

%% estimate mu 
maxVal = nanmax(V(:));
iMax = find( V == maxVal );
mu(1) = mean(X(iMax));
mu(2) = mean(Y(iMax));
mu(3) = mean(S(iMax));

%% estimate sigma
% here I do something fairly crude:
% since I've observed that the data are fairly smooth and fall off from the
% center, I take one 'line' each for the X, Y, and S dimensions, passing
% through the center point. I then fit that line of data to a 1D Gaussian,
% and take the sigma for that dimension.
[iY iX iS] = ind2sub(size(V), iMax);
iY = round(mean(iY));  
iX = round(mean(iX));  
iS = round(mean(iS));

% find sigma(1): fit a line along the X == mu(1) direction
line{1} = squeeze( V(iY,:,iS) );
pts{1}  = squeeze( X(iY,:,iS) );
sigma(1) = fitSigma(pts{1}', line{1}');

% find sigma(2): fit a line along the Y == mu(2) direction
line{2} = squeeze( V(:,iX,iS) );
pts{2}  = squeeze( Y(:,iX,iS) );
sigma(2) = fitSigma(pts{2}', line{2}');

% find sigma(2): fit a line along the S == mu(3) direction
line{3} = squeeze( V(iY,iX,:) );
pts{3}  = squeeze( S(iY,iX,:) );
sigma(3) = fitSigma(pts{3}', line{3}');


%% construct the 3D Gaussian
G = rfGaussian3d(mu, sigma, X, Y, S);

% go ahead and scale G to match V
[t df rss beta] = rmGLM(V(:), [G(:) ones(size(G(:)))]);
% G = G .* beta(1) + beta(2);
G = rescale2(G, [], mrvMinmax(V), 0);

%% compute the fit
R = corrcoef( [G(:) V(:)] );
fit = R(2) ^ 2;

%% visualize the fitting if requested
if plotFlag==1
	hFig = figure('Color', 'w', 'Units', 'norm', 'Position', [.2 .1 .5 .8]);
	
	% show the fit for each of the three lines
	xys = {'X' 'Y' '\sigma'};
% 	for n = 1:3
% 		subplot(4, 3, n);  hold on
% 		plot(pts{n}, line{n}, 'k', 'LineWidth', 2);
% 		plot(pts{n}, normpdf(pts{n}, mu(n), sigma(n)), 'b', 'LineWidth', 2);
% 		xlabel(xys{n});  ylabel('Variance Explained');
% 	end

	subplot(4, 3, 1);  hold on
	plot(pts{1}, line{1}, 'k', 'LineWidth', 2);
	plot(pts{1}, squeeze( G(iY,:,iS) ), 'b', 'LineWidth', 2);  axis tight
	xlabel(xys{1});  ylabel('Variance Explained');
% 	title( sprintf('Fit: R^2 = %1.2f', fit), 'FontWeight', 'bold' );
	title( sprintf('X = %2.2f %s %2.2f', mu(1), char(177), sigma(1)), 'FontWeight', 'bold' );


	subplot(4, 3, 2);  hold on
	plot(pts{2}, line{2}, 'k', 'LineWidth', 2);
	plot(pts{2}, squeeze( G(:,iX,iS) ), 'b', 'LineWidth', 2);   axis tight
	xlabel(xys{2});  
	title( sprintf('Y = %2.2f %s %2.2f', mu(2), char(177), sigma(2)), 'FontWeight', 'bold' );	
	
	subplot(4, 3, 3);  hold on
	plot(pts{3}, line{3}, 'k', 'LineWidth', 2);
	plot(pts{3}, squeeze( G(iY,iX,:) ), 'b', 'LineWidth', 2);   axis tight
	xlabel(xys{3});  
	title( sprintf('\\sigma = %2.2f %s %2.2f', mu(3), char(177), sigma(3)), 'FontWeight', 'bold' );
	
	
	% show a 3-axis view of the search space
	clim = mrvMinmax(V);
	
	subplot(4, 3, 4);
	imagesc( squeeze(V(:,iX,:)), clim );	axis image;
	xlabel('\sigma');  ylabel('Y');
	title('Search Space', 'FontWeight', 'bold');
	
	subplot(4, 3, 5);
	imagesc( [squeeze(V(iY,:,:))]', clim );	axis image;
	xlabel('X');  ylabel('\sigma');

	subplot(4, 3, 6);
	imagesc( squeeze(V(:,:,iS)), clim );	axis image;
	xlabel('X');  ylabel('Y');
	
	
	% show a 3-axis view of the fit
	subplot(4, 3, 7);
	imagesc( squeeze(G(:,iX,:)), clim );	axis image;
	xlabel('\sigma');  ylabel('Y');
	title('Gaussian Fit', 'FontWeight', 'bold');
	
	subplot(4, 3, 8);
	imagesc( [squeeze(G(iY,:,:))]', clim );	axis image;
	xlabel('X');  ylabel('\sigma');

	subplot(4, 3, 9);
	imagesc( squeeze(G(:,:,iS)), clim );	axis image;
	xlabel('X');  ylabel('Y');
	
	
	% show a 3-axis view of the difference between the search and fit
	D = abs( V - G );
	
	subplot(4, 3, 10);
	imagesc( squeeze(D(:,iX,:)), clim );	axis image;
	xlabel('\sigma');  ylabel('Y');
	title('Search Space - Fit', 'FontWeight', 'bold');
	
	subplot(4, 3, 11);
	imagesc( [squeeze(D(iY,:,:))]', clim );	axis image;
	xlabel('X');  ylabel('\sigma');

	subplot(4, 3, 12);
	imagesc( squeeze(D(:,:,iS)), clim );	axis image;
	xlabel('X');  ylabel('Y');
	title( sprintf('Fit: R^2 = %1.2f', fit), 'FontWeight', 'bold' );
	
	% add a colorbar panel
	cbarPanel(clim, 'Variance Explained');
end

return
% /------------------------------------------------------------------/ %




% /------------------------------------------------------------------/ %
function sigma = fitSigma(x, y);
% fit a 1D Gaussian PDF to a probability function in
% (x, y), and return the standard deviation (sigma) of the fitted function.

%% input check
% remove NaNs
y(isnan(y) | isinf(y)) = 0;

%% define a function handle to the metric:
% we want to minimize the difference between the data (y) and a 1-D
% Gaussian with the parameters p = {mu, sigma}:
metric = @(s) sum( sqrt( [y - normalize( normpdf(x, s(1), s(2)), min(y), max(y) )] .^ 2 ) );

%% do the optimization
s = fminsearch(metric, [0 1]);

sigma = s(2);


return