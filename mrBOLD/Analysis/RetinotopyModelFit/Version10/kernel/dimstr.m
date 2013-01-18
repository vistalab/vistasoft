function str = dimstr(value)
str = sprintf('%s = [%s',inputname(1),num2str(value(1)));
for j=2:length(value),
  str = [str,sprintf(',%s',num2str(value(j)))];
end;
str = sprintf('%s]',str);
