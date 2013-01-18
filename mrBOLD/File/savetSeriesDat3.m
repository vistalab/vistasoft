function fid=savetSeriesDat3(fileName,tSeries,nRows,nCols,scaleFactor)
%function savetSeriesDat3(fileName,tSeries,[nRows,nCols]) 
%
%98.12.23 - Written by Bill and Bob.  Save the tSeries in the new
%uint16 format, including writing out header information.
%nRows and nCols are optional arguments.  If not supplied, the
%header will contain: nRows=1, nCols=real#rows * real#cols.
% 01/02/02 - ARW , changed to allow passing of a scale factor
if nargin==2
    nRows = 1;
    nCols = size(tSeries,2);

end

nFrames = size(tSeries,1);

if (exist('scaleFactor','var'))
    if (length(scaleFactor(:))==1)
        resampleFlag=[scaleFactor,scaleFactor];
    end
    % If a resample flag was set, run through the tSeries data resizeing it...
    
    oldTSeries=tSeries;
    
    nRows=nRows*scaleFactor(1);
    nCols=nCols*scaleFactor(2);
    
    tSeries=zeros(nFrames,nRows,nCols);
    
    fprintf('\nApplying scale factor\n');
    
    for thisFrame=1:nFrames
        imSlice=squeeze(oldTSeries(thisFrame,:,:));
        tSeries(thisFrame,:,:)=imresize(imSlice,[nRows,nCols],'nearest');
        fprintf('.');
        
    end
end % End if scaleFactor


fprintf('\nWriting tSeries\n');


fid = fopen(fileName,'w','b');
fwrite(fid, nFrames, 'uint16');
fwrite(fid, nRows, 'uint16');
fwrite(fid, nCols, 'uint16');
fwrite(fid, tSeries ,'uint16');
fclose(fid);



