function [rot, trans, Mf] = regEstRot4(rot, trans, scaleFac, volume, numSlices, sagSize, NCoarseIter, coarseFlag, fineFlag);
%
% regEstRotFunction -   Function to compute automatically the rotation and translation,
%                       to be used as a callback.
%                       It returns the rotation and translation in workspace variables
%                       rot and trans.
%
%  Oscar Nestares - 5/99
%  ON - Added option to use the rotation and translation in bestrotvol
%       as initial alignment (useful to recompute automatically previous
%       manual alignments).
%  AB 4/21    - added NCoarseIter = [];
%  SL 7/15/02 - Created regEstRot4 for use in mrAlign4 (based largely on regEstRot).
%               Changed it from a script into a function and eliminated the need for
%               'Usebestrotvol' parameter and the function regParamInit.
%  SL 7/29/02 - removed NCoarseIter = [];
%  SL 8/02/02 - added coarseFlag and fineFlag parameters

global INPLANE

% registering
[rot, trans, Mf]=regVolInp4(...
                 reshape(volume,[sagSize, numSlices]),...   % volume
                 INPLANE.anat,...                           % inplanes
                 scaleFac,...                               % inverse voxel size for inplanes and volume
                 rot,...                                    % initial rotation
                 trans,...                                  % initial translation
                 NCoarseIter,...                            % number of coarse iterations
                 coarseFlag,...                             % coarse iterations flag
                 fineFlag,...                               % fine iterations flag
                 'regEstFilIntGrad',...                     % function to estimate the intensity grad.
                 0);                                        % Plane by Plane flag = 0 (=>works globaly)

% done

msgbox('Automatic computation done');
