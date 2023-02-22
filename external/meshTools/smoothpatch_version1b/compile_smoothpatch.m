function compile_smoothpatch
% Compile smoothpatch mex files
%
% See Readme.txt in meshTools for more compilation notes
%
% BW (c) VISTASOFT

%% Compile mex files
mex smoothpatch_curvature_double.c -v
mex smoothpatch_inversedistance_double.c -v
mex vertex_neighbours_double.c -v

%% End