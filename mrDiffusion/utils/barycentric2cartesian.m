function P=barycentric2cartesian(t, C)

%Computes cartesian coordinates of a vector of barycentric coordinates 1x3
%in the triangular space defined by C(:, 1), C(:, 2), C(:, 3) verticed in 2D space. 
%e.g., t could be planarity, linearity and sphericity. And C could be [2 0; 0 0; 1 sqrt(3)]

%ER 12/2008

if size(t)==[3 1]
    t=t';
end
P=t*C;


