function se = bivariateSE(z,p)
%
% se = bivariateSE(z,[p])
%
% Calculates the pth (e.g., 95th) percentile confidence interval
% for (circularly distributed) bivariate data
%
% z: bivariate data, either a complex-valued vector or two columns
% p: desired confidence interval (default .95)
%
% se: pth confidence interval on the mean
%
% djh and gmb

if ~exist('p','var')
  p=.95;
end

if size(z,2) == 2 %z has two columns, x and y.
  wasTwoCol = 1;
  z = z(:,1)+i*z(:,2); %turn it into a complex vector
else
  wasTwoCol = 0;
end

% mean, sd, and se
n = length(z);
m = mean(z);
sd = sqrt(2/pi)*mean(sqrt((abs(z-m).^2)));
se = sd/sqrt(n-1);
se = se*sqrt(-2*log(1-p));

if wasTwoCol
  m = [real(m),imag(m)];
end
return 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Debug

% Example
nSamps = 20;
trueMean = 0;
trueSD = 10;
z = trueSD*((randn(1,nSamps)+sqrt(-1)*randn(1,nSamps)))+trueMean;
m = mean(z);
se = bivariateSE(z); 
clf
plot(z,'.','MarkerSize',20)
hold on
plot(m,'g.','MarkerSize',40)
plot([0,m],'g','LineWidth',2)
circleSE(m,se,'g');
axis equal
hold off

% Check that p% of the means are within the se
nSamps = 100;
nReps = 500;
trueMean = 0;
trueSD = 10;
p = 0.95;
count =0;
for rep=1:nReps
  z = trueSD*((randn(1,nSamps)+sqrt(-1)*randn(1,nSamps)))+trueMean;
  m = mean(z);
  se = bivariateSE(z,p); 
  count = count + (abs(m)<se);
end
disp(sprintf('Percent in %dth confidence interval: %5.1f',...
    p*100,100*(count/nReps)));


