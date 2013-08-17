function mtrExportFiberGroupToMetrotrac(outFile, fgFile, faNiftiFile)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% mtrExportFiberGroupToMetrotrac(outFile, [fgFile], [faNiftiFile])
%%
%% outFile - filename for metrotrac pathways
%%
%%
%% Author: Anthony Sherbondy
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ieNotDefined('fgFile')
    [f,p] = uigetfile({'*.mat';'*.*'},'Select a fiber group file for input...');
    if(isnumeric(f)), disp('Conversion canceled.'); return; end
    fgFile = fullfile(p,f); 
end
fg = dtiNewFiberGroup();
fg = dtiReadFibers(fgFile);

if ieNotDefined('faNiftiFile')
    [f,p] = uigetfile({'*.nii.gz';'*.*'},'Select a FA file for reference to DTI space input...');
    if(isnumeric(f)), disp('Conversion canceled.'); return; end
    faNiftiFile = fullfile(p,f); 
end
nifa = niftiRead(faNiftiFile);
mmPerVox = nifa.pixdim;
xformToAcpc = nifa.qto_xyz;
scene_dim = size(nifa.data);


% Matrix for converting fiber group coords into the metrotrac pathway space
xformFromAcpc = diag([(mmPerVox(:)') 1])*inv(xformToAcpc);

% HACK: Unchecked and can be bogus because DTIQuery doesn't use this
% Get ACPC from transform
ACPC = [xformToAcpc(1,4)/xformToAcpc(1,1) xformToAcpc(2,4)/xformToAcpc(2,2) xformToAcpc(3,4)/xformToAcpc(3,3)];


% Create blank database for finding some of the sizes to write out
pdb = mtrPathwayDatabase();

numstats = length( pdb.pathway_statistic_headers );

% Redo offset
offset = 5*4 + 6*8 + numstats * getStatisticsHeaderSizeWordAligned(pdb); % 5 uint,6 doubles
%5* sizeof (int) + 6 * sizeof(double) + pathways->getNumPathStatistics()*sizeof (DTIPathwayStatisticHeader);
% bool == char, but not guaranteed on all platforms

fid = fopen(outFile, 'wb');

% Writing header
fwrite(fid,offset,'uint');

fwrite(fid,scene_dim,'uint');
fwrite(fid,mmPerVox,'double');
fwrite(fid,ACPC,'double');
fwrite(fid,numstats,'uint');

% Write Stat Header
saveStatisticsHeader(pdb,fid);

%Writing path info
numpaths = length(fg.fibers);
fwrite(fid,numpaths,'uint');

for ff = 1:numpaths
    path_offset = 3 * 4  + numstats*8; % 3 int, numstats double
    fwrite(fid,path_offset,'int');
    
    %nn = size( fg.fibers{ff}.coords, 2 );
    nn = size( fg.fibers{ff}, 2 );
    
    fwrite(fid,nn,'int');
    fwrite(fid,1,'int'); % algo type HACK
    fwrite(fid,1,'int'); % seedpointindex HACK ???
    
    % Stats
    if( numstats ~= 0 )
        error('Can not handle nonzero statistics with path.');
    end
    
    % Writing path nodes
    %pos = fg.fibers{ff}.coords;
    pos = fg.fibers{ff};
    pos = mrAnatXformCoords(xformFromAcpc, pos')';
    % Change from 1 based to 0 based positions in mm space
    pos = pos - repmat(mmPerVox(:),1,size(pos,2));
    fwrite(fid,pos,'double');
    
    % HACK: Don't worry numstats has to be zero right now
% %     % Writing stats values per position
% %     for as = 1:numstats
% %         if( this.pathway_statistic_headers(as).is_computed_per_point )
% %             fwrite(fid,this.pathways(p).point_stat_array(as,:),'double');
% %         end
% %     end   

end

disp('Saved Database.');
fclose(fid);

function pos = asMatrixStruct(this)
pos = [this.xpos; this.ypos; this.zpos];
return
