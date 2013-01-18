function pen = dtiRoiEditGetPen(penStyleStr)
% 
% pen = dtiRoiEditGetPen(penStyleStr)
%
% penStyleStr is a string specifying the desired pen style and size. Run this
% function with no args to get a list of valid styles. Passing 'default'
% will return a default style. PenStyleStr can also simply be an index into
% the list of penStyle strings.
%
% HISTORY:
% 2006.11.09 RFD wrote it.

styles = {'cube 1','cube 2','cube 3','cube 5','cube 9','cube 15','sphere 2','sphere 3','sphere 5','sphere 9','sphere 15'};
if(nargin<1)
   % then return a list of pen names
   pen = styles;
   return;
end
if(~isnumeric(penStyleStr)&strcmpi(penStyleStr,'default'))
    penStyle = 'cube';
    penSize = 2;
else
    if(isnumeric(penStyleStr))
        penStyleStr = styles{penStyleStr};
    end
    tmp = sscanf(penStyleStr,'%s %d');
    penSize = tmp(end);
    penStyle = char(tmp(1:end-1)');
end
if(strcmpi(penStyle,'cube'))
    if(penSize==1)
        pen.x = 0; pen.y = 0; pen.z = 0;
    else
        r = (penSize-1);
        [pen.x,pen.y,pen.z] = meshgrid([-r:+r],[-r:+r],[-r:+r]);
        pen.x = pen.x(:)./2;
        pen.y = pen.y(:)./2;
        pen.z = pen.z(:)./2;
    end
elseif(strcmpi(penStyle,'sphere'))
    if(penSize==1)
        pen.x = 0; pen.y = 0; pen.z = 0;
    else
        r = penSize.*2;
        [pen.x,pen.y,pen.z] = meshgrid([-r:+r],[-r:+r],[-r:+r]);
        dSq = pen.x.^2+pen.y.^2+pen.z.^2;
        keep = dSq(:) < r.^2;
        pen.x = pen.x(keep)./2;
        pen.y = pen.y(keep)./2;
        pen.z = pen.z(keep)./2;
    end
else
    error('invalide pen style string.');
end
return;