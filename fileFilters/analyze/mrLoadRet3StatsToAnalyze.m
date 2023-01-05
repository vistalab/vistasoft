function V=mrLoadRet3StatsToAnalyze(outFileName,scanNum,mapName)
% 
% V=mrLoadRet3StatsToAnalyze(outFileName,scanNum,mapName)
% 
% AUTHOR:  Wade
% DATE: 06.10.03
% PURPOSE: 
% Converts a statistical map in a mrLoadRet 3 Gray view into a 8 bit
% analyze file. Data are scaled from 0 to 2^8-1% Uses the current scan if no scanNum is passed
% mapName can be 'co', 'amp', 'ph' or any other similar statistical map in% the VOLUME structure.
% If no mapName is passed, it defaults to writing out 'co'.
% If embedDimensions are passed, the data are embedded into an even larger% volume. This is useful when 
% dealing with BV volume anatomies that have been embedded into 256x256x256
%
% RETURNS: 
% Number of bytes written in main data block.
% 
% EXAMPLE:
% 1) V=mrLoadRet3StatsToAnalyze('temp');
% 2) V=mrLoadRet3StatsToAnalyze('temp_ph','ph');
%
% NOTES
% Originall coded to transfer mrLoadRet gray stats into SSI's EMSE / mrViewer
% $Author: wade $
% $Date: 2003/09/09 21:18:59 $mrGlobals;
if (isempty(selectedVOLUME))
    error('You must select (click within) a volume window before proceeding');
end

if ((~exist('scanNum','var')) | (isempty(scanNum)))    scanNum=getCurScan(VOLUME{selectedVOLUME});end
% Get a coherence threshold
coThresh=getCothresh(VOLUME{selectedVOLUME});


if ((~exist('outFileName','var')) | (isempty(outFileName)))    a=dataTYPES(VOLUME{selectedVOLUME}.curDataType).name;    outFileName=[a,'_',int2str(scanNum),'_co_',int2str(coThresh*100)];endif ((~exist('mapName','var')) | (isempty(mapName)))
    mapName='co';
end
volAnatSize=size(VOLUME{selectedVOLUME}.anat);% We need to permute this into the correct format. volAnatSize=volAnatSize([2 1 3]);if ((~exist('embedDimensions','var')) | (isempty(embedDimensions)))    embedDimensions=volAnatSize;end
if ((~exist('VOLUME','var')) | (isempty(VOLUME{selectedVOLUME}.co)))    error('mrLoadRet must be running and the GRAY corAnal must be loaded');endif (isempty(VOLUME{selectedVOLUME}.anat))
    error('The anatomy must be loaded');
end
% % Find the size of the full anatomycoords=VOLUME{selectedVOLUME}.coords;coords=coords';% % minVals=min(coords);% maxVals=max(coords);% bbSize=maxVals-minVals+1% 
% if(find(bbSize<=0))%     error('The GRAY data are in an invalid VOI');% enddataVolume=uint8(ones(size(VOLUME{selectedVOLUME}.anat)));[ySiz xSiz zSiz]=size(VOLUME{selectedVOLUME}.anat);
% Do the mother of all sub2inds to get a linear index into dataVolumecoords=sub2ind([ySiz xSiz zSiz],coords(:,1),coords(:,2),coords(:,3));
if (~strcmp(mapName,'co'))
    error('Only co maps allowed for now');
end
co=(VOLUME{selectedVOLUME}.co(scanNum));co=co{1};

% Now threshold according to the current cothresh
co(co<coThresh)=0;


blurKern=ones(3,3,3);
blurKern=blurKern./sum(blurKern(:));
blurKern=blurKern*20;

co=convn(co,blurKern,'same');co(co>=1)=0.9999; % Just to make sureco(co<=0)=0;



% Scale co from 0 to 2^8-1
max(co);
min(co);
% co=log10(co*10);
co(co<=0)=0;
co=co*((2^8)-1);



max(co)
min(co)
% Send it into the large data volumedataVolume(coords)=(co);dataVolume=permute(dataVolume,[3 2 1]);dataVolume=flipdim(dataVolume,3);%dataVolume=flipdim(dataVolume,2);
dataVolume=flipdim(dataVolume,1);
% Call SPM writevol routine to write out the data.


    s=spm_hwrite(outFileName,[ySiz xSiz zSiz],[1 1 1],1,spm_type('uint8'),0);
    V=spm_vol(outFileName);
      
    
    V.descrip=['Converted from tSeries file in session',mrSESSION.sessionCode,' : ',mrSESSION.subject,':  on ',datestr(now)];
    
    s=spm_write_vol(V,double(dataVolume));
return;


