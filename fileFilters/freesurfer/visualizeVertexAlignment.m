function visualizeVertexAlignment(points1,points2,rangeToVisualize,titleStr);
% visualizeVertexAlignment(grayNodes,vertex',rangeToVisualize);
%Plots a restricted subset of points from both datasets within the range to visualize on axis 2
% Points should be nDims  x  nPoints
if (ieNotDefined('titleStr'))
    titleStr='Plot';
end

figure(100);
title(titleStr);

for t=1:3
    
a=((points1(t,:)>rangeToVisualize(1)) .* (points1(t,:)<rangeToVisualize(2)));
b=find(a);
c=((points2(t,:)>rangeToVisualize(1)) .* (points2(t,:)<rangeToVisualize(2)));
d=find(c);

subplot(3,1,t);
title(titleStr);
disp(titleStr);

otherdims=setdiff([1 2 3],t);

plot(squeeze(points1(otherdims(1),b)),squeeze(points1(otherdims(2),b)),'r.');
hold on;
plot(squeeze(points2(otherdims(1),d)),squeeze(points2(otherdims(2),d)),'b.');
hold off;
title(titleStr);
% 
end

