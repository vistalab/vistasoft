function vec = colorLookup(str);
% looks up the character in string and returns
% an appropriate 1 x 3 RGB vector.
if isnumeric(str) & length(str)==3, vec = str; return; end

switch lower(str(1))
    case 'r', vec = [1 0 0]; % red
    case 'g', vec = [0 1 0]; % green
    case 'b', vec = [0 0 1]; % blue
    case 'w', vec = [1 1 1]; % white
    case 'k', vec = [0 0 0]; % black
    case 'c', vec = [0 .75 .75]; % cyan
    case 'y', vec = [.75 .75 0]; % yellow
    case 'm', vec = [.75 0 .75]; % magenta
    case 'e', vec = [.25 .25 .25]; % gray
    otherwise, 
        msg = sprintf('color lookup: strange color specified? -- %s\n',str);
        msg = sprintf('%s defaulting to black...\n',msg);
        warning(msg);
        vec = [0 0 0];
end
return
   