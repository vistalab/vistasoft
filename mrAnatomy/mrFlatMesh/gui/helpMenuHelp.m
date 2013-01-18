function helpMenuHelp()

web1 = 'web([''file:///'' which(''vFbHelp.html'')],''-browser'')';
web2 = 'web([''file:///'' which(''vFbHelp.html'')])';

eval(web1,web2);
% EVAL(s1,s2) provides the ability to catch errors.  It
%     executes string s1 and returns if the operation was
%     successful. If the operation generates an error,
%     string s2 is evaluated before returning.
% Useful here because the -browser option does not work all the time

return;
