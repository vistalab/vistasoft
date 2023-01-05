function xfm = xfmPoints(x,y)

% add third dimension
x = [x zeros(size(x,1),1)];
x(1,3) =1;
y = [y ones(size(y,1),1)];

% linear tranformation 
b = pinv(y)*x;
xfm = b;

% plot results
if ~nargout,
   figure;
   subplot(2,1,1);hold on;
   plot(x(:,1),x(:,2),'bo');
   plot(y(:,1),y(:,2),'rx');
   title('original data');
   legend('x','y');
   
   % interpolate
   yi=y*b;
   subplot(2,1,2);hold on;
   plot(x(:,1),x(:,2),'bo');
   plot(yi(:,1),yi(:,2),'rx');
   title('original data');
   legend('x','y interpolated');
end

return
