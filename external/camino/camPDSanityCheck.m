function camPDSanityCheck(pds_filename,fa_filename,model_type)

if notDefined('model_type')
    model_type = 'dteig';
end

cmd = ['pdview -inputmodel ' model_type ' `analyzeheader -printprogargs ' fa_filename ' pdview` -scalarfile ' fa_filename ' < ' pds_filename];
display(cmd);
system(cmd,'-echo');
