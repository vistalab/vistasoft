function approxAvg2fwhm(appfwhm,alpha);
% linear approximation

if ~exist('appfwhm','var') || isempty(appfwhm),
  appfwhm = 5;
end;
if ~exist('alpha','var') || isempty(alpha),
  alpha = 1;
end;

a=zeros(200,1000);
a(1,500) = 1;

space = [1:1000];
space = space-space(500);

g  = zeros(size(a));
sds = zeros(size(a,1),1);
err = sds;

w=3;
n = 0;figure;clf;
while(1),
  n = n + 1;
  tmp = a(n,:);
  b=tmp([end 1:end-1]).*alpha;
  c=tmp([2:end 1]).*alpha;
  a(n+1,:)  = sum([tmp;b*w;c*w])./(1+2*w);
  a(n+1,:)  = a(n+1,:)./max(a(n+1,:));
  
  sds(n+1) = fminsearch(@(x) gFit(x,a(n+1,:),space),1);
  [err(n+1), g(n+1,:)] = gFit(sds(n+1),a(n+1,:),space);
 
  plot(space,[a(n+1,:); g(n+1,:)]);
  title(sprintf('sd=%f',sds(n+1)));
  drawnow;
  
  %if sd2fwhm(sds(n+1)*mean([1 sqrt(2)])) >= appfwhm;
  if sd2fwhm(sds(n+1)*mean([1 1])) >= appfwhm;
    %[n sd2fwhm(sds(n+1)*[1 sqrt(2)]) err(n+1)],
    break;
  end;
end;
fprintf(1,'Number of iterations: %d (alpha = %.2f) - aproximate fwhm = %.2f\n',n,alpha,appfwhm);

% crop
a = a(1:n,:);
g = g(1:n,:);
sds = sds(1:n);
err = err(1:n);
% plot
figure;clf;
subplot(2,2,1);imagesc(a);ylabel('iter (#)');
subplot(2,2,2);plot(err,'r');ylabel('error (au)');
subplot(2,2,3);imagesc(a(2:end,:)-g(2:end,:));xlabel('space (mm)');ylabel('iter (#)');
subplot(2,2,4);hold on;
plot(mean(sd2fwhm(sds*[1 sqrt(2)])'),'g');
plot(sd2fwhm(sds),'g--');
plot(sd2fwhm(sds*sqrt(2)),'g--');
ylabel('fwhm (mm)');
xlabel('iter (#)');
plot([0 n],[appfwhm appfwhm],'k:');
plot([1:n],sd2fwhm(sqrt([1:n].*alpha)),'r:');
hold off;



% 
function g=gauss(x,sd);
g =  exp(-.5* (x/sd).^2);
return

function [e, fit] =gFit(sd,data,x);
g = gauss(x,sd);
b = pinv(g(:))*data(:);
fit = (g(:)*b)';
e = norm(data-fit);
return;
