function mtrPlotBayesianTractModels()

% Helper for cycling plots
plotTypes = {'k','b','r','g','y','m'};

% Distribution of Likelihood of PDD given true tangent and FA
angle = linspace(-pi/2,pi/2,400);
fa = [0.88, 0.68, 0.48, 0.28];

% Convert FA values into stds
stdevs = 1.0978*exp(-1.9567*fa) - 0.1437;

figure(1);
hold off;
p=1;
% Get gaussians
for s = 1:length(stdevs)
    %like(s,:) = normpdf(angle,0,stdevs(s))/(normcdf(pi/2,0,stdevs(s))-normcdf(-pi/2,0,stdevs(s)));
    like(s,:) = normpdf(angle,0,stdevs(s))/(normcdf(pi/2,0,stdevs(s))-0.5);
    plot(angle,like(s,:),plotTypes{p},'LineWidth',2); hold on;
    p=p+1;
end
legend('FA = 0.88','FA = 0.68','FA = 0.48','FA = 0.28');
xlabel('Angle between t and d (radians)');
ylabel('Likelihood');
title('Distribution of PDD given tangent and FA');
hold off;

% Distribution on FA values within white matter
fa = linspace(0,1,200);
distrib_fa = ones(length(fa),1)/0.88;
distrib_fa(fa > 0.88) = 0;

figure(2);
plot(fa,distrib_fa,'LineWidth',2);
xlabel('FA');
title('Distribution of FA');

% Distribution of Prior
angle = linspace(-pi,pi,400);
%prior = 1/(2*pi)*normpdf(angle,0,pi/5)/(normcdf(pi,0,pi/5)-normcdf(-pi,0,pi/5));
prior = 1*normpdf(angle,0,pi/5)/(normcdf(pi,0,pi/5)-0.5);
%angle = cos(angle);

figure(3);
plot(angle,prior,'k','LineWidth',2);
xlabel('Theta (radians)');
ylabel('Prior');
title('p(Theta)');

% Convert continuous FA values into stds
stdevs = 1.0978*exp(-1.9567*fa) - 0.1437;
figure(4);
plot(fa,stdevs,'LineWidth',2);
xlabel('FA');
ylabel('Standard Deviation (radians)');
title('Function mapping FA to Std. for Local Likelihood');


% Plot mesh of gaussian

theta = linspace(0,0,200);
cos_phi = linspace(-1,1,200);
fa = linspace(0,0.88,200);
pdd = [0,pi];
%[X,Y] = meshgrid(cos_phi,theta);
[X,FA] = meshgrid(cos_phi,fa);
stdevs = 1.0978*exp(-1.9567*FA) - 0.1437;
%normalizer = normcdf(pi/2,0,diag(stdevs(:,1)))-normcdf(-pi/2,0,diag(stdevs(:,1)));
normalizer = normcdf(pi/2,0,diag(stdevs(:,1)))-0.5;
NORM = repmat(diag(normalizer),1,size(X,2));
%Z = pdd(1).*X.*cos(pdd(2)).*cos(X) + sin(acos(pdd(1))).*sin(acos(X)).*cos(pdd(2)).*cos(Y+pi) + sin(pdd(2)).*sin(Y+pi);
Z = pdd(1).*X.*cos(pdd(2)).*cos(pi) + sin(acos(pdd(1))).*sin(acos(X)).*cos(pdd(2)).*cos(pi) + sin(pdd(2)).*sin(pi);
Z(Z < 0) = 0;
%Z = normpdf(acos(Z),0,stdevs(1))/(normcdf(pi/2,0,stdevs(1))-normcdf(-pi/2,0,stdevs(1)));
Z = 1 ./ (sqrt(2*pi).*stdevs).*exp(-acos(Z).^2 ./ (2*stdevs.^2) ) ./ NORM;
figure(5)
surf(acos(X)-pi/2,FA,Z,FA,'EdgeColor','none');
axis([-pi/2, pi/2, 0, 0.88, 0, 15]);
%ylabel('FA');
%xlabel('AE(radians)');
%title('p(PDD|t,FA)');
box on;
