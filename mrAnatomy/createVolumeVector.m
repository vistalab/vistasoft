% createVolumeVector.m
% --------------------
%
% function vol = createVolumeVector(mat)
%
%
%  AUTHOR: Brian Wandell 
%    DATE: July 7, 1995
% PURPOSE:
%          This is a routine that converts a matrix whose columns are 
%          images into a single row vector representing the volume.  
%          This routine is usefull because if the volume-vector format 
%          is changed then you won't have to change lots of separate 
%          pieces of code.
%
% ARGUMENTS:
%          mat: Matrix each of whose columns is an image in the volume.
%
% RETURNS:
%          vol: A volume vector.
%
%

function vol = createVolumeVector(mat)


%% Use the command 'reshape' to convert matrix into a row vector.
%
 vol = reshape(mat,1,prod(size(mat)));


%%%%