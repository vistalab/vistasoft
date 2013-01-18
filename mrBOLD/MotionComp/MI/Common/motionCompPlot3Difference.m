function imageDifference = motionCompPlot3Difference(image1,image2,I,N)
%
%    gb 03/01/05
%
%    imageDifference = motionCompPlot3Difference(image1,image2,I,N)
%
% Displays in a 3D volume the difference between image1 and image2.
% In order to see something, the marker size is proportional to the
% difference. The values of I and N are optional and specify the range of
% the marker size proportionnaly to the maximum.
%
% The default values for I and N are 2 and 10. This means that are plotted
% only the points where the image difference is between 20% and 100% of the
% maximum.
%
% The color of the markers is red if the image difference is positive, and
% blue if the image difference is negative.
%
% In case the image2 is not passed in, the difference image becomes image1.
%

if ieNotDefined('image2')
    image2 = zeros(size(image1,1),size(image1,2),size(image1,3));
end

if ~isequal(size(image1),size(image2))
    fprintf('The images must have the same size');
end

if ieNotDefined('I')
    I = 2;
end

if ieNotDefined('N')
    N = 10;
end

imageDifference = image1 - image2;
%[X,Y] = meshgrid(1:size(image1,2),1:size(image1,1));
%figure,
%mesh(X,Y,imageDifference);

Colors = 'mgrbkkkkkkkkkkkk';

hold off
plot3(0,0,0);
axis([0 126 0 106 -1 27]);
hold on
mx = max(imageDifference(:));
for i = I:N
    imageDifference(find(abs(imageDifference) < i/N*mx)) = 0;

    [x,C] = find(imageDifference > 0);
    z = floor(C/size(image1,2));
    y = C - z.*size(image1,2);
    z = (27 - z);
    plot3(x,y,z,'.','Color','r','MarkerSize',((i - I + 1)/N*mx)/100)
 
    [x,C] = find(imageDifference < 0);
    z = floor(C/size(image1,2));
    y = C - z.*size(image1,2);
    z = (27 - z);
    plot3(x,y,z,'.','Color','b','MarkerSize',((i - I + 1)/N*mx)/100 + 1);
   
end

hold off