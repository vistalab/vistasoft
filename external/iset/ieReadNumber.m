function val = ieReadNumber(str,defNumber,fmt)
% Query the user for a number or vector
%
%  val = ieReadNumber(str,defNumber,fmt)
%
% You can enter a single number or you can enter a vector.  If you enter a
% vector, you must use [] around the list.
%  fmt specifies the format. Default is integer.
%
% Examples
%   val = ieReadNumber('Enter column number')
%   val = ieReadNumber('Enter frames', [3 2 1])
%   val = ieReadNumber('Enter value', 3.1, ' %.2f')
%

if notDefined('str'), str = 'Enter'; end
if notDefined('defNumber'), defNumber = 1; end
if notDefined('fmt'), fmt = '  %.0f'; end

prompt={str}; def = {num2str(defNumber,fmt)}; 
dlgTitle= sprintf('Enter number'); lineNo=1;
answer = inputdlg(prompt,dlgTitle,lineNo,def);

if   isempty(answer),  val = [];
else                   val = eval(answer{1});
end

return;

