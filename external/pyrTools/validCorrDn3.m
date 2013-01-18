% RES = validCorrDn3(IM, FILT, STEP);
%
% Correlate 3D FILT with 3D IM.  FILT must be smaller than IM.  The 
% result dimensions [size(IM)-size(FILT)+1].
% STEP is an optional 3-vector that specifies subsampling factors.

% EPS, 7/96.

%%% This function is implemented as a MEX file.
warning('Compile the MEX file validCorrDn3.c');

