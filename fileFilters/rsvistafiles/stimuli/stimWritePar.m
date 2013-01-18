function stimWritePar(stim,parfiles);
% Write out stimulus information in .par files.
%
% stimWritePar(stim,[parfiles]);
%
% stim: stim struct -- see stimFormatDescription.
% parfiles: paths in which to save the parfiles. If omitted,
% uses paths specified in stim.stimFiles.
%
% ras, 10/2005.
if notDefined('parfiles'), parfiles=stim.stimFiles; end

if ischar(parfiles), parfiles = {parfiles}; end

for i = 1:length(parfiles)
    fid = fopen(parfiles{i},'w');
    
    for j = 1:length(stim.onsetSecs)
        fprintf(fid,'%3.2f\t%i',stim.onsetSecs(j),stim.conds(j));

        if isfield(stim,'labels') & length(stim.labels) >= j &...
                ~isempty(stim.labels{j})
            fprintf(fid,'\t%s',stim.labels{j});
        end
        
        if isfield(stim,'colors') & length(stim.colors) >= j &...
                ~isempty(stim.colors{j})
            fprintf(fid,'\t%s',stim.colors{j});
        end
        
        if isfield(stim,'images') & length(stim.images) >= j &...
                ~isempty(stim.images{j})
            fprintf(fid,'\t%s',stim.images{j});
        end
        
        if isfield(stim,'user1') & length(stim.user1) >= j &...
                ~isempty(stim.user1{j})
            fprintf(fid,'\t%s',stim.user1{j});
        end
        
        if isfield(stim,'user2') & length(stim.user2) >= j &...
                ~isempty(stim.user2{j})
            fprintf(fid,'\t%s',stim.user2{j});
        end        
        
        fprintf(fid,'\n');                        
    end

    status = fclose(fid);

    fprintf('Wrote %s.\n',parfiles{i});
end

return