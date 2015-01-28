function fg = read_trk_to_fg( filename )
% Read Trackvis format into fg
%
%   fg = read_trk_to_fg( filename)
%
% Creates fiber fg structure from trackvis file.
%
% Input:
%       filename: Name of trk file output from trackvis
%                 The extension of file is .trk
% Output:
%       fg is a mrDiffusion fiber group structure.
%       It contains the following additional field:
%           header: is a matlab structure. It contains all header information
%                   requires to visualize fiber fg in trackvis.
%
% For details about header fields and fileformat see:
% http://www.trackvis.org/docs/?subsect=fileformat
%
% Example;
%
%   fg = read_trk_to_fg('hardiO10.trk');
%
% HISTORY:
% 2009.09.21 RFD wrote it, based on code by Sudhir K Pathak (read_trk).
%
% for PghBC2009 competition 2009 url:http://sfcweb.lrdc.pitt.edu/pbc/2009/
%
% PROGRAMMING TODO
%
%  This program reads a binary fiber tracking file output from
% TrackVIS in native format. If you are reading .trk file on big endian
% machine change fopen function: fid = fopen(filename ,'r', 'ieee-le');
%
% This should be called from dtiImportFibers or some more general place
% rather than this routine.  Like fgRead would be good!
%
% We need a unit test.  Say read a .trk file in and check the hash on the
% return or something, to verify that this code is running right.  We
% should put the trk file in the vistadata directory.  And we should figure
% out a good way to maintain that directory!
%
% Vistasoft Team, Copyright

[p,f,e] = fileparts(filename);
fg = dtiNewFiberGroup(f);

fid = fopen(filename ,'r');

fg.header.id_string                  = fread(fid,6,'char=>char');
fg.header.dim                        = fread(fid,3,'int16=>int16');
fg.header.voxel_size                 = fread(fid,3,'float');
fg.header.origin                     = fread(fid,3,'float');
fg.header.n_scalars                  = fread(fid,1,'int16=>int16');
fg.header.scalar_name                = fread(fid,200,'char=>char');
fg.header.n_properties               = fread(fid,1,'int16=>int16');
fg.header.property_name              = fread(fid,200,'char=>char');
fg.header.vox_to_ras                 = reshape(fread(fid,16,'float'), [4,4])';
fg.header.reserved                   = fread(fid,444,'char=>char');
fg.header.voxel_order                = fread(fid,4,'char=>char');
fg.header.pad2                       = fread(fid,4,'char=>char');
fg.header.image_orientation_patient  = fread(fid,6,'float');
fg.header.pad1                       = fread(fid,2,'char=>char');
fg.header.invert_x                   = fread(fid,1,'uchar');
fg.header.invert_y                   = fread(fid,1,'uchar');
fg.header.invert_z                   = fread(fid,1,'uchar');
fg.header.swap_xy                    = fread(fid,1,'uchar');
fg.header.swap_yz                    = fread(fid,1,'uchar');
fg.header.swap_zx                    = fread(fid,1,'uchar');
fg.header.n_count                    = fread(fid,1,'int');
fg.header.version                    = fread(fid,1,'int');
fg.header.hdr_size                   = fread(fid,1,'int');

no_fibers = fg.header.n_count;
tmp = fread(fid,inf,'*float32')';
% Sometimes number of fibers doesn't get stored (and that field gets set to 0...)
% in which case we need to do something else:
if no_fibers == 0
    % It's certain to be smaller than the size of the entire thing, so
    % we can safely set it to that and just not report it to the user:
    no_fibers = length(tmp);
    fprintf(1,'Reading fiber data for unknown number of fibers...\n');
    
    
else
    fprintf(1,'Reading fiber data for %d fibers...\n',no_fibers);
end

fclose(fid);

pct = 10;
n = 1;
for(ii=1:no_fibers)
    num_points = typecast(tmp(n),'int32');
    n = n+1;
    fg.fibers{ii} = reshape(tmp(n:num_points*3+n-1),3,num_points);
    n = n + num_points*3;
    if mod(ii,floor(no_fibers/10)) ==  0
        fprintf(1,'\n%3d percent fibers processed...', pct);
        pct = pct + 10;
    end
    % We need to check if there's anything left to read, for the case in
    % which fiber_no was not set in the header
    if n>=length(tmp)
        % We can now set the number of fibers based on our experience:
        fg.header.n_count = ii;
        % and then break out:
        break
    end
end

fprintf(1,'\n');

%     for i=1:no_fibers
%         fg.fiber{i}.num_points = fread(fid,1,'int');
%         fg.fiber{i}.points = fread(fid,[3,fg.fiber{i}.num_points],'float')';
%         %dummy = zeros(fg.fiber{i}.num_points, 3);
%         %for j=1:fg.fiber{i}.num_points
%         %    p = fread(fid,3,'float');
%         %    dummy(j,:) = p;
%         %end;
%         %fg.fiber{i}.points = dummy;
%
%         % progress report
%         if mod(i,floor(no_fibers/10)) ==  0
%             fprintf(1,'\n%3d percent fibers processed...', pct);
%             pct = pct + 10;
%         end;
%
%     end;
%     fprintf(1,'\n');


