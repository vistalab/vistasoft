% fixedSegmentation = removeBridgesMex(segmentation, anatomicalData, 
%			 averageWhiteIntensity, thresholdIntensity, averageGrayIntensity)
%
% Mex function implementing the bridge removal algorithm described
% in Kriegeskorte & Goebel (2001) An Efficient Algorithm for 
% Topologically Correct Segmentation of the Cortical Sheet in Anatomical 
% MR Volumes. Neuroimage, 14, 329-346.
%
% To compile, try:
% mex removeBridgesMex.cpp CRemoveBridges.cpp
%
% On linux, this might make faster code:
% mex -O COPTIMFLAGS='-O3 -march=i686 -DNDEBUG' removeBridgesMex.cpp CRemoveBridges.cpp
%
% HISTORY (from the source code):
% 2002.08.?? Niko & Rainer kindly gave us their code from BrainVoyager. 
% 2002.09.?? Ian Spiro modified the BV code to build a DLL that takes
%            data rather than filenames. He also wrote a simple mex wrapper
%            to call this DLL.
% 2002.11.13 Bob Dougherty: overhauled the code to make it cleaner (no more
%            globals!) and platform-independent. To do this, I had to remove
%            all the GUI stuff and the threading. The code now runs serially
%            and uses printf for progress reporting (although this can be
%            easily changed by modifying the updateProgress method). I also
%            wrote a mex wrapper for this class. 
