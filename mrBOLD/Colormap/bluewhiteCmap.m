function cmap = bluewhiteCmap()
% cmap = bluewhiteCmap()
%% Make a colormap similar to matlab's pink colormap but with a blueish tint

cpink = colormap('pink');
c1 = cpink(:,1);
c2 = cpink(:,2);
c3 = cpink(:,3);
cnew = [c3 c1 c1];
cmapValuesHist = colormap(cnew);

end