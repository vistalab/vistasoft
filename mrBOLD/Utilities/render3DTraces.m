function render3DTraces(mtx,colors);
% render3DTraces(mtx,[colors]);
%
% Using plot3, render the columns in a 2D matrix mtx
% as a set of traces in a 3D graph (in current axes).
%
% colors: optional cell specifying the color to use for
% each column (string -- see help plot -- or 3-vector).
%
% 07/04 ras.
if ~exist('colors','var')
    colOrder = 'rbgcky';
    for i = 1:size(mtx,2)
        colors{i} = colOrder(mod(i,length(colOrder))+1);
    end
end

cla;
hold on;

X = 1:size(mtx,1);

for i = 1:size(mtx,2)
    Y = i*ones(1,size(mtx,1));
    htmp = plot3(X,Y,mtx(:,i)');
    set(htmp,'LineWidth',1.5,'Color',colors{i});
end

axis auto;
view(-8,60);
grid on;
hold off;

return