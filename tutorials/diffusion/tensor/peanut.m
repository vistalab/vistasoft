%% Part of discussion on ADC quadratic form calculations
% Probably old between Bob and Brian years ago.
%
% Could be fixed up or deprecated.
%

% Here is a standard ellipsoid.
[X,Y,Z] = ellipsoid(0,0,0,3,1,1);
figure(1), subplot(1,2,1), surf(X,Y,Z)
axis equal

sz = size(X);

% Here is how an ellipse looks like a peanut
%
% Assign a length equal to the square of their length on the ellipsoid.
% This corresponds to what I believe are the ADC (variance) values.  Notice
% the peanut shape. 

% The length of each ellipsoid vector
tmp = [X(:),Y(:),Z(:)];
l = sqrt(diag(tmp*tmp'));   
% Multiply each vector by its own length
tmp = diag(l)*tmp;          

X2 = reshape(tmp(:,1),sz);
Y2 = reshape(tmp(:,2),sz);
Z2 = reshape(tmp(:,3),sz);
figure(1), subplot(1,2,2), surf(X2,Y2,Z2)

