function plotHistory(hist,histstr,varargin)

fig     = 2;
col     = 'krgbcmykrgbcmy';
figname = mfilename;

for k=1:1:length(varargin)/2,
  %disp([varargin{2*k-1},'=varargin{',int2str(2*k),'};']);
  eval([varargin{2*k-1},'=varargin{',int2str(2*k),'};']);
end;

dum = abs(max(hist,[],1));
dum = dum + (dum==0);
if ~isempty(fig),
  fig = figure(fig); clf; hold on;
else  
  fig = figure;      clf; hold on
end;

set(fig,'numbertitle','off','name',sprintf('[JM-%d] %s',fig,figname));
hold on;
for j=size(hist,2)-1:-1:1,
  pp(j) = plot(hist(:,1),hist(:,j+1)/dum(j+1),'color',col(j)); 
end;
set(pp,'linewidth',2);
title(histstr{1});
xlabel('iter')
legend(pp,histstr{2:end});
return;
