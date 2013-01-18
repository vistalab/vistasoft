%   atlasNew = updateTinC(atlas,X,Y)
%
%Author: B. Fischer
%Purpose:
%   Deform an image, say atlas, so that values in the implicit function,
%   atlas(1:M,1:N) are mapped to the positions in atlas(X,Y).
%   This function is used in the elastic matching algorithms in the
%   Analysis/Atlas directory.
%
%   It was written in C- by Bernd.  It appears that the values in X,Y
%   must match the coordinates (size) of atlas.  No linear interpolation is
%   performed, just a deformation of the cartesian coordinates.
%
%  These notes by BW.
%
