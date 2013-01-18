function corrected = mrgRemBridges(preWhite,anatData,params);
%
%  corrected = mrgRemBridges(preWhite,anatData,params);
%
%  preWhite and anatData should both be uint8s of the same size.
%  The bridge removal algorithm assumes that the intensity data in anatData
%  range from 0-255. 
% 
%  Note that the removeBridgesMex wants things in the range 0-225 (226-255 
%  are "reserved colors" in BrainVoyager), so we do that scaling in here.
%
% Params should be (at least) 1x3: [csf mean, gray mean, white mean]
%
% Author:  Wandell
% Purpose:
%    Core computations in removing bridges.  This routine is extracted so
%    that the computation can be called separately, without all the I/O in
%    the main calling routine, mrgRemoveBridges.
%
% See mrgRemoveBridges.
%
% HISTORY:
%  2004.02.12 RFD: moved confusing 225/255 scaling from mrgRemBridges
%  to here.
%

if ieNotDefined('preWhite'), error('Must define white matter data.'); end
if ieNotDefined('anatData'), error('Must define anatomical data.'); end

sFactor = 225/255;

if ieNotDefined('params')
    warndlg('Classification parameters not found in class file header- making some guesses...');
    avgWhite = mean(double(anatData(preWhite>0)));
    threshold = 0.9*avgWhite;
    avgGray = 0.8*avgWhite;    
elseif length(params) < 3
    error('Problem with params- must be at least 1x3: [csf mean, gray mean, white mean].');
else
    % the 6 classification params are csf mean, gray mean, white mean,
    % noise stdev, confidence and smoothness.
    avgWhite = params(3);
    avgGray = params(2);
    threshold = mean([avgWhite,avgGray]);
end

% Scale everything
avgWhite = avgWhite*sFactor;
avgGray = avgGray*sFactor;
threshold = threshold*sFactor;
anatData = uint8(round(double(anatData).*sFactor));

%-----------------------Call removeBridgesMex----------------------------

fprintf('RemoveBridgesMex: This can take a while. *** %s\n', datestr(now));
tic;
corrected = removeBridgesMex(preWhite,anatData,avgWhite,threshold,avgGray);
toc;
t = now;
fprintf('Done. *** \n%s\n', datestr(now));

% More thinking should happen here.  Like we should figure out how to make
% cuts.
%
% Voxels marked with 236 should be removed (make a cut).
% Voxels marked with 245 should be added.
% Voxels marked with 226 are 'alternative' voxels (what are they?).
% Voxels marked with 225 are unchanged voxels.
% preSegClass.data(corrected==236)=0;
% preSegClass.data(corrected==245 | corrected==225) = 16;

return;
