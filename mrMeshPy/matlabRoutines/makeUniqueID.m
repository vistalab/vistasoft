function uID = makeUniqueID;
% function uID = makeUniqueID(clockString)
% 
% takes the system clock and creates a unique (hopefully) string to label
% the mesh and allow us to keep track between processes

a = num2str(fix(clock)); % get clock string
a = strrep(a,'    ','_'); % tidy it up 1
a = strrep(a,'__','_'); % ang again

uID = a;
