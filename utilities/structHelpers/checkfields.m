function bool = checkfields(s,varargin)
%
%  bool = checkfields(s,varargin)
%
%Author:  Wandell
%Purpose:
%   We often need to check for a nest sequence of fields within a structure.  
% We have been doing this with a series of nested or grouped isfield statements.
% This got annoying, so I wrote this routine as a replacement.
%
% Suppose there is a structure, pixel.OP.pd.type
% You can verify that the sequence of nested structures is present via the
% call
%
%      checkfields(pixel,'OP','pd','type')
%
% A return value of 1 means the field sequence is present * and nonempty*.
% A return value of 0 means the sequence is absent or empty.
%

% ras, 12/06: made so it checks if the field is nonempty as well.

% note this function has been duplicated in vistasoft and vistadisp. if one
% is updated, please update the other.
nArgs = length(varargin);
str = 's';
tst = eval(str);

bool = false;
for ii=1:nArgs
    if isfield(tst,varargin{ii})
        % Append the argument to the current string (default to the first
        % item if more exist - otherwise eval crashes).
        if numel(tst) == 1
            str = sprintf('%s.%s',str,varargin{ii});
        else
            if iscell(tst)
                str = sprintf('%s{1}.%s',str,varargin{ii});
            else
                str = sprintf('%s(1).%s',str,varargin{ii});
            end
        end

        % If this is the last one, return succesfully
        if ii==nArgs  
            % the field exists -- is it nonempty?
            if isempty( eval(str) )
                % exists but is empty -- return false
                bool = false;
            else
                % exists and is nonempty -- return true
                bool = true;
            end
            return;
        else 
            tst = eval(str);
        end
    else
        return;
    end
end

% Should never get here
error('checkfields: Error')

return;


