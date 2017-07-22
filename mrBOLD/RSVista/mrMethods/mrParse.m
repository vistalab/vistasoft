function mr = mrParse(mr)
% Parse an mr object specification, returning a struct array.
% Useful for flexible argument specification.
%
% mr = mrParse(mr);
%
% The mr argument can be specified as (1) an mr struct; (2) a path to an
% mr file; or (3) a cell of (1) or (2). This function disambiguates the
% specification format and always returns an mr struct array.
%
% ras, 10/2005.
if ~iscell(mr)
    if ischar(mr), mr = mrLoad(mr);
    elseif ~isstruct(mr),
        help(mfilename);
        error('mr is specified in the wrong format');
    end
else
    hwait = mrvWaitbar(0, 'Loading mr files ...');

    for i = 1:length(mr)
        if ischar(mr{i}), mr{i} = mrLoad(mr{i});
        elseif ~isstruct(mr{i}),
            help(mfilename);
            close(hwait);
            error('mr{%i} is specified in the wrong format\n',i);
        end
        tmp(i) = mr{i};
        
        mrvWaitbar(i/length(mr), hwait);
    end   
    mr = tmp;
    
    close(hwait);
end

return
