function rxCoarseIfiles(rx,ifilePath);
% 
% rxCoarseIfiles([rx],[ifilePath]);
%
% Use the vista toolbox code to compute
% a coarse alignment. 
%
% The function 'computeCannonicalXformFromIfile'
% returns a 4x4 matrix for transforming an ifile
% into a canonical space (R,A,S coordinates). 
% However, this is in fact the inverse of the xform
% mrRx looks at, the way it is usually set up -- 
% it tries to transform the volume to match the 
% inplanes in an alignment. (But then when the 
% alignment is saved, it does another inverse to
% get in line w/ the mrVista tools -- so if no
% further alignment is done after this, you'd get
% the original img2std matrix saved in the mrSESSION
% alignment field.)
%
%
%
% 03/05 ras.
if ieNotDefined('rx')
    cfig = findobj('Tag','rxControlFig');
    rx = get(cfig,'UserData');
end

if ieNotDefined('ifilePath')
    % leave empty for now;
    % will look for it down the line
    % (well, let's try something trivial for now)
    ifilePath = fullfile(pwd,'Raw','Anatomy','Inplane'); % '';
end

[img2std mmPerVox] = computeXformFromIfile(ifilePath);
                    
% The xform computed from the I-files tells how
% to get the ref into the volume space -- for now,
% we want to use the inverse:
rx = rxSetXform(rx, inv(img2std));      

% store this for posterity :)
rx = rxStore(rx,'Coarse');

% rxRefresh(rx);

return
