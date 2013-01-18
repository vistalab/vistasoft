function name=prefix(filename, vararg)

%A utulity that strips of extension
%By default keeps path+filename
%If flag is defined as "short" then path is also stripped off. 
%name=prefix(filename, flag)

%ER 2008

if nargin==2
    flag=vararg(1, :);
else flag='full';
end


[pathstr, name]=fileparts(filename);
if(~strcmp(flag, 'short'))
    name=fullfile(pathstr, name); 
end
