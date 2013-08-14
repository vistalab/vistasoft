function camTrackProjectomeCandidates(cdb_filename,step_size,min_track_length,pds_filename,seed_filename,notseed_filename,ends_filename,raw_filename,pd_model_type)
% Set up Camino call to process streamlines from a NIFTI defined file
%
% The arguments here are sent to procstreamlines
% These are defined by "man procstreamlines"
%
%  We need real comments here.
%


%
% Lets create the other filenames that are derived from the candidate
% database

if notDefined('pd_model_type')
    pd_model_type = 'dt'; % 'dt' or 'pds'
end

[pathstr, name, ext] = fileparts(cdb_filename);
t1_filename =  fullfile(pathstr,[name '_-2' ext]);
t2_filename =  fullfile(pathstr,[name '_-1' ext]);
str_pd_model_type = ['-inputmodel ' pd_model_type];

cmd1 = sprintf('track %s  `analyzeheader -printprogargs %s track` -seedfile %s -outputfile %s -interpolate -stepsize %f < %s', str_pd_model_type, raw_filename, seed_filename,  t1_filename, step_size, pds_filename);
display(cmd1);
system(cmd1,'-echo');

if ~notDefined('notseed_filename')
    
    cmd2 = sprintf('procstreamlines -inputfile %s -noresample -exclusionfile %s -truncateinexclusion -outputfile %s',t1_filename, notseed_filename, t2_filename);
    display(cmd2);
    system(cmd2,'-echo');
    
    if ~notDefined('ends_filename')
        
        ends = niftiRead(ends_filename);
        
        if max(ends.data(:)>1)
            cmd3 = sprintf('procstreamlines -inputfile %s -mintractlength %f -noresample -endpointfile %s -outputfile %s',t2_filename, min_track_length, ends_filename, cdb_filename);
        else
            cmd3 = sprintf('procstreamlines -inputfile %s -projectome -mintractlength %f -noresample -endpointfile %s -outputfile %s',t2_filename, min_track_length, ends_filename, cdb_filename);
        end
        display(cmd3);
        system(cmd3,'-echo');
        
    end
    
end
