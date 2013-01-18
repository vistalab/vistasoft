
n = 48;
dir = spherePoints(n);
dir = round(dir*1000)/1000;

numB0 = ceil(n/11.3);
fname = sprintf('dwepi.%2.0d.grads',n+numB0);
fid = fopen([fname],'w');
for(ii=1:numB0)
  fprintf(fid, '0.00 0.00 0.00\n');
end
for(ii=1:size(dir,2))
  fprintf(fid, '%0.3f %0.3f %0.3f\n', dir(:,ii));
end
fclose(fid);

%figure;plot3(dir(1,:),dir(2,:),dir(3,:),'.'); grid on; axis([-1 1 -1 1 -1 1])
T = delaunay3(dir(1,:),dir(2,:),dir(3,:));
figure; tetramesh(T,dir');

%u = points(:,1)';
% v is a unit vector perpendicular to u:
%v = [-u(2),u(1),0]/sqrt(u(1)^2+u(2)^2);
% w is a unit vector perpendicular to u and v:
%w = cross(u,v);
% to translate into the (u,v,w) coordinate system:
%xform =  [u; v; w];
%points = xform*points;

% e = 0;
% for(ii=1:n)
%   for(jj=ii+1:n)
%     e = e+1./sqrt(sum((dir(:,ii)-dir(:,jj)).^2));
%   end
% end
% e
