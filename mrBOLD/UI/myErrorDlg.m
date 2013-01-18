function myErrorDlg(errstr)
%
% myErrorDlg(errstr)
%
% Matlab's errordlg doesn't actually signal an error and return
% to the Matlab prompt.  This is a hack to fix that.
%
% djh, 7/98

errordlg(errstr,'Error!');
error(errstr);

return;
