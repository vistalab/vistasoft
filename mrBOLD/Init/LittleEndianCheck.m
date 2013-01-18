function endianFlag = LittleEndianCheck(mrSESSION);
%
% endianFlag = LittleEndianCheck(mrSESSION);
%
% Code for Initializing data collected at Stanford Lucas Center:
% Checks whether functional data is likely to use big- or 
% little-endian format. The issue is this: around March 1,
% 2005, the 3T scanner was updated, and Gary Clover's spiral 
% recon code updated, to use Little-Endian format. Prior to 
% this, it was big-endian. This code simply checks the
% date stored for the first functional in mrSESSION, compares 
% it against March 1, and sets the endian flag appropriately
% for downstream reconning. 
%
% However, since there's a chance older data may be reconned 
% using the newer little-endian scripts, if the date is 
% before 03/01/05, the code prompts the user first.
%
% If endianFlag is 1, downstream code will treat functionals
% as little-endian; otherwise, will treat it as big-endian.
%
% ras, 05/05
if ~checkfields(mrSESSION,'functionals','date')
    endianFlag = 1; % little endian
    return
end

date = mrSESSION.functionals(1).date;
mo = str2num(date(1:2));
da = str2num(date(4:5));
yr = str2num(date(7:8));

if (yr==5 & mo<3) | (yr<5)
    % older data: prompt
    q = ['This data is before March 2005, so is likely ' ...
         'in Big-Endian format. However, it''s possible ' ...
         'that it''s in Little-Endian format, e.g. if the P*.7 ' ...
         'files were reconned later. How should the data ' ...
         'be read?   (type "help LittleEndianCheck" for more info)'];
    resp = questdlg(q,'mrInitRet','LittleEndian','BigEndian',...
                      'Quit','BigEndian');
    switch lower(resp)
        case 'littleendian', endianFlag = 1;
        case 'bigendian', endianFlag = 0;
        otherwise, error('User aborted');
    end
else
    % newer data: little endian
    endianFlag = 1;
end

return