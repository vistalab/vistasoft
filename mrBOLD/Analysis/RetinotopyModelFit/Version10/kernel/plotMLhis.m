function plotMLhis(his,str,fig)

dum = max(his,[],1);
dum = dum + (dum==0);
if ~isempty(fig),
  fig = figure(fig); clf; hold on;
else  
  fig = figure;      clf; hold on
end;

set(fig,'numbertitle','off','name',sprintf('[JM-%d] %s',fig,str));
hold on;


aa = max(his,[],1);
KK = 1:size(his,1);
JJ = find(his(:,1) == 0);

pp(1)=plot(KK(JJ),his(JJ,2),'s'); 
set(pp(1),'markerfacecolor','b','markersize',10);

pp(2) = plot(KK,his(:,2),'x'); 
set(pp(2),'linewidth',3,'color','b','markersize',10);

pp(3) = plot(KK,his(:,2),'-'); 
set(pp(3),'linewidth',3,'color','b','markersize',10);

% pp=plot(KK(JJ),his(JJ,2),'s',KK,his(:,2),'x'); 

%tt = title('multi-level iteration history: ');
%set(tt,'fontsize',15,'fontweight','bold');
ll = legend(pp(1:2),{'J(y^h_0)','J(y^h_k)'},2);
set(ll,'fontsize',15,'fontweight','bold');
q = max(his(:,2));

for j=1:length(JJ),
  plot(KK(JJ(j))*[1,1],1.2*q*[0,1],'b--');
%   tt(1) = text(KK(JJ(j))+0.25,3.5e5,sprintf('%s{-%d}','h=2^',j+2));
  tt(2) = text(KK(JJ(j))+0.25,q,sprintf('level=%d',j+2));
  set(tt(2),'fontsize',8,'fontweight','normal');
end

pp(4)=plot(KK(JJ(end):end),his(KK(JJ(end):end),2),'-');
pp(5)=plot(KK(JJ(end)),his(KK(JJ(end)),2),'s');
pp(6)=plot(KK(JJ(end):end),his(KK(JJ(end):end),2),'x');

set(pp(4:6),'linewidth',3,'color','r','markersize',10);
plot(KK(JJ(j))*[1,1],1.2*q*[0,1],'r--');
ll = xlabel('k');
set(ll,'fontsize',15,'fontweight','bold');
set(gca,'fontsize',15,'fontweight','bold');
