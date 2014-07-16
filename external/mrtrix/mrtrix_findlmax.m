function lmax = mrtrix_findlmax(nbvecs)
% Finds the maximum number of harmonic order that can be used for a
% diffusion data set. This number depends on the numer of directions
% acquired. We decide the max number of harmonic order by usign the formula
% reproted here:
% http://www.brain.org.au/software/mrtrix/tractography/preprocess.html
%
% lmax = mrtrix_findlmax(nbvecs)
%
% INPUTS:
%  nbvecs - number of directions acquired for a data set. For example the
%  size of the bvecs: nbvecs = size(bvecs,2)
%
% OUPUTS:
%  lmax  - the Maximum harmonic order that can be used given the number of
%  measued diffusion directions (size
%
% EXAMPLE:
%  bvecs  = dlmread('path/to/bvecs/file/in/mrdiffusion/formatbv.bvec')
%  nbvecs = size(bv,2);
%  lmax   = mrtrix_findlmax(nbvecs)
%
% Copyright 2014 Franco Pestilli Stanford University,
% pestillifranco@gmail.com

% We initialize a vector of potential Lmax, this number can never be larger
% than the number of directions.
alllmax = [2:2:nbvecs];
% We compute the number of parameters that each Lmax would require to be
% supproted by the data. We want less parameters than data.
nparams = .5*(alllmax+1).*(alllmax+2);

% We find the largest Lmax requiring less parameters than the number of
% diffusion directions minus one. So that we are sure that we have at least
% one additional data point (diffusion direction) to supporting each
% parameter of the deconvolution.
lmax = alllmax( find(nparams < (nbvecs-1),1,'last') );
end
