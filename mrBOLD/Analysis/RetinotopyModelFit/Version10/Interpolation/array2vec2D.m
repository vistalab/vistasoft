% function X = array2vec2D(x1,x2,mode)
%
% (c) NP, JM; SAFIR, Luebeck, 2006
%
% performs the inverse basis change of vec2array for 2D grids
% try   help vec2array    for more information
function X = array2vec2D(x1,x2,mode)

X = [x1(:);x2(:)];

return;
