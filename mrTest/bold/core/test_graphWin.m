function test_graphWin()
%Validate opening and closing of graph windows
%
%   test_graphWin()
% 
% Tests: newGraphWin(), closeGraphWin()
%
% INPUTS
%  No inputs
%
% RETURNS
%  No returns
%
% Example:  test_graphWin()
%
% See also MRVTEST
%
% Copyright Stanford team, mrVista, 2015

% Because the figure handles changed from numbers (Matlab2014a and prior)
% to a FIGURE class (Matlab 2014b and later), it is important to ensure
% that opening and closing of figures works properly.

% open a figure using the newGraphWin command
newGraphWin();

% close the figure using closeGraphWin
closeGraphWin;

return