function nocancel = cinchGenerateData (dt6file, datapath)
nocancel = true;
if ~exist(datapath, 'dir')
        r = questdlg ('CINCH data has not yet been created for this subject. Do this now? (Warning: This could take a minute or two!)');
        if (~strcmp (r,'Yes'))
            nocancel = false;
            return;
        end;
    h = mrvWaitbar(0,'Please wait...');
    dtiConvertDT6ToBinaries (dt6file, datapath);
    close(h);
end;
return;