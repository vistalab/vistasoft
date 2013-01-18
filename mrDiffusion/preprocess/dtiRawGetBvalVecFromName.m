function [bvalue, gradDirsCode] = dtiRawGetBvalVecFromName(filename)
%
% [bvalue, gradDirsCode] = dtiRawGetBvalVecFromName(filename)
%
% Gets the bvalue and the grad dir code from the file. 
%
% HISTORY
% 2009.05.20 RFD pulled code from dtiRawPreprocess
%

doBvecs = true;
bvalue = [];
s = strfind(filename,'_b');
if(~isempty(s)&&length(s)==1&&length(filename)>s+1)
    tmp = filename(s+2:end);
    s = strfind(tmp,'_');
    if(~isempty(s)), tmp = tmp(1:s(1)-1); end
    bvGuess = str2double(tmp);
    % sanity-check
    if(bvGuess>=10&&bvGuess<=15000)
        bvalue = bvGuess/1000;
    end
end
if(isempty(bvalue))
    bvalue = 0.8;
    resp = inputdlg('b-value (in millimeters^2/msec):','b-value',1,{num2str(bvalue*1000)});
    if(isempty(resp)), error('canceled'); end
    bvalue = str2double(resp)/1000;
end

mrDiffusionDir = fileparts(which('mrDiffusion.m'));
gradsDir = fullfile(mrDiffusionDir,'gradFiles');
gradDirsCode = [];
s = strfind(filename,'_g');
if(~isempty(s)&&length(s)==1&&length(filename)>s+1)
    tmp = filename(s+2:end);
    s = strfind(tmp,'_');
    if(~isempty(s)), tmp = tmp(1:s(1)-1); end
    gcGuess = str2double(tmp);
    % sanity-check
    if(gcGuess>0&&gcGuess<=10000)
        gradDirsCode = gcGuess;
    end
end

return;

