function reconList = SelectPfiles(scanParams)
% Choose from the list of Pfiles for reconning
%  
%  reconList = SelectPfiles(scanParams)
%
% Display a list of raw Pfiles in the scanParams input, and
% return those selected by the user.
% Inputs
%   scanParams  struct array of Pfile-addressed scan parameters
%               from the mrSESSION.functionals field.
%               
% Outputs:
%   reconList   binary vector of that holds the user's selection.
%
% DBR  5/99  Rewritten from the old selectPfiles.m

PfileList = {scanParams(:).PfileName};
reconList = buttondlg('Choose Pfiles',PfileList);

return;
