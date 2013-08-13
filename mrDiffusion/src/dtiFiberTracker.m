fibers = dtiFiberTracker(dt6, seedPoints, mmPerVox, trackAlgo, interpAlgo, stepSize, faThresh, angleThresh, wPuncture, lengthLim, xform)
%
% fibers = dtiFiberTracker(dt6, seedPoints, mmPerVox, trackAlgo, interpAlgo, stepSize, faThresh, angleThresh, wPuncture, lengthLim, xform)
%
% Mexified TensorLine/FACT fiber tracking.
%
% dt6: XxYxZx6 tensor in 'dt6' format (Dxx Dyy Dzz Dxy Dxz Dyz)
%
% seedPoints: 3xN list of seed point coords (double)
%
% mmPerVox: 3x1 array specifying the mmPerVox in (X,Y,Z)
%
% Tracking algorithm: 0=STT Euler, 1=STT RK4, 2=TEND Euler, 3=TEND RK4
%                     The default method '1' most closely resembles the STT algorithm described in Basser et. al., (2000), 
%                     In Vivo Fiber Tractography Using DT-MRI Data, MRM.  It uses a Runge-Kutta path-integral method. 
%
% Interpolation type: 0=nearest neighbor, 1=tri-linear
%
% stepSize (mm): eg. 1.0
%
% FA threshold: eg. 0.15
%
% Angle threshold (deg): eg. 45.0
%
% Puncture coefficient (TensorLines only): eg. 0.2
% NOTE: TensorLines with a puncture coefficient of 1 is equivalent to TEND.
%
% LengthLim (mm; optional): scalar specifying minimum length, or a 1x2
% specifying the min and max length. Fibers shorter than the min length
% will be discarded. If a max length is specified, fibers will stop
% tracking when they reach this threshold. Ie., minLength is a filter to
% get rid of short fibers, but maxlength is an additional stopping
% criteria. If not specified, no limits are applied.
%
% xfrom (4x4 affine; optional): applies this transform to each fiber
% coordinate. Defaults to eye(4). 
%
%
%
% To compile, cd to the mrDiffusion code dir and try the following:
%    mex -O -I./jama dtiFiberTracker.cxx
%
% HISTORY: 2004.06.24 RFD: wrote it, using some code from Dave Akers.

help(mfilename);
error('This function must be compiled!');
return;
