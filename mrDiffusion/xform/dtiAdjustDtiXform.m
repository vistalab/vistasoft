function handles = dtiAdjustDtiXform(handles, refPointName, newCoords, oldCoords)
%  handles = dtiAdjustDtiXform(handles, refPointName, newCoords, [oldCoords])
%
% TO DO:
% Change all coordinate frame transforms so that they are with respect to
% the origin (eg. image center or ac) so that rotations are easier to
% understand!
% 
% HISTORY:
%   2004.03.12 RFD (bob@white.stanford.edu) wrote it.

newXform = handles.bg(1).mat;
switch(refPointName)
    case 'ac'
        % FIX THIS! It assumes that the anatomical scale factors are all 1.
        % If we assume that the anatomicals are bg(3), then we can apply
        % that xform to correct this. But maybe there are no anatomicals?
        %handles.bg(3).mat
        %newImgCoords=mrAnatXformCoords(inv(dtiGetStandardXform(handles,handles.bg(1).mat)),newCoords)
        [t,r,s,k] = affineDecompose(newXform);
        if(~exist('oldCoords','var')) oldCoords = t; end
        t = [oldCoords-newCoords];
        newXform = affineBuild(t,r,s,k);
    case 'pc'
        if(~exist('oldCoords','var')) oldCoords = [0 -23 0]; end
        % from the PC, we can compute rotation about Z- and X-axes and the
        % Y-axis scale.
        %[t,r,s,k] = affineDecompose(newXform);
        oldXform = dtiGetStandardXform(handles,handles.bg(1).mat);
        x = [inv(oldXform)*[0,0,0,1; [oldCoords,1]]']'...
            \ [inv(oldXform)*[0,0,0,1; [newCoords,1]]']';
        % set zero scales to 1
        x([(xor(x,eye(4))).*eye(4)]>0) = 1;
        %newXform = newXform*inv(x);
        [t,r,s,k] = affineDecompose(newXform*inv(x));
        % FIX THIS
%         curAcPcDist = sqrt(sum(([0 0 0]-oldCoords).^2));
%         newAcPcDist = sqrt(sum(([0 0 0]-newCoords).^2));
%         scaleDiff = (curAcPcDist-newAcPcDist)./curAcPcDist
%         s(2) = s(2) + scaleDiff;
%         t(2) = t(2) + t(2) .* scaleDiff;
        newXform = affineBuild(t,r,s,k);
    case 'ppc'
        % FIX THIS! We aren't rotating about the proper origin.
        if(~exist('oldCoords','var')) oldCoords = [0 -102 0]; end
        x = [0,0,0,1; [oldCoords,1]] \ [0,0,0,1; [newCoords,1]];
        x([1,11]) = 1;
        [t,r,s,k] = affineDecompose(inv(x)*newXform);
        newXform = affineBuild(t,r,s,k);
    case 'rot'
        [t,r,s,k] = affineDecompose(newXform);
        r = r+newCoords;
        newXform = affineBuild(t,r,s,k);
    case 'scale'
        [t,r,s,k] = affineDecompose(newXform);
        s = s.*newCoords;
        t = t.*newCoords;
        newXform = affineBuild(t,r,s,k);

    otherwise
        error('Unrecognized refpoint name!');
end

% FIX THIS!
handles.bg(1).mat = newXform;
handles.bg(2).mat = newXform;
handles.vec.mat = newXform;

return;