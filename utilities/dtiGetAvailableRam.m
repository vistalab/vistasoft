function mbytesAvail = dtiGetAvailableRam

try
    [junk,str] = system('free -m');
    % Hack to get the 'free' column from the output of str. On windows, try
    % the undocumented matlab command 'memstats'.
    str = str(strfind(str,'buffers/cache:')+15:end);
    [junk,str] = strtok(str);
    str = strtok(str);
    mbytesAvail = str2double(str);
catch
    % everyone should have at least this much?
    maxMemoryToUse = 500;
end

return