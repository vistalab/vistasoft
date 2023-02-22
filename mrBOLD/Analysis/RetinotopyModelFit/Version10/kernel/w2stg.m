function yt = w2stg(model,Omega,m,wt)
grid = getGrid(Omega,m,'nodal');
y0 = feval(model,wt,grid);
[y1,y2,y3] = vec2array(y0,m,'nodal');

y1 = 0.5*(y1(:,1:end-1,:)+y1(:,2:end,:));
y2 = 0.5*(y2(1:end-1,:,:)+y2(2:end,:,:));
if length(m) == 3,
  y1 = 0.5*(y1(:,:,1:end-1)+y1(:,:,2:end));
  y2 = 0.5*(y2(:,:,1:end-1)+y2(:,:,2:end));
  y3 = 0.5*(y3(1:end-1,:,:)+y3(2:end,:,:));
  y3 = 0.5*(y3(:,1:end-1,:)+y3(:,2:end,:));
end;
yt = [y1(:);y2(:);y3(:)];
return;
