function dtiCinchToQuenchCst(cinchCstFile, quenchCstFile)

%Convert a cinch-generated state file to a quench-generated
cinch=readTab(cinchCstFile); 
cinch(1:3)% Keep these --  %Camera Position, View Up, and Camera Focal Point
cinch{7}(17:end) %Tomo.Position ->Volume Sections's Position
cinch{8}(19:end) %Tomo. Visibility -> Volume Section's Visibility
numFibers=sum(cellfun(@isnumeric, cinch)); 

fid=fopen(quenchCstFile, 'w'); 
fprintf(fid, '%s\n', cinch{1}); 
fprintf(fid, '%s\n',  cinch{2}); 
fprintf(fid, '%s\n',  cinch{3});
fprintf(fid, 'Volume Sections''s Position: %s\n', cinch{7}(17:end));
fprintf(fid, 'Volume Sections''s Visibility: %s\n', cinch{8}(19:end));
fprintf(fid,  '%d\n',  numFibers);
fprintf(fid, '%d\n', cinch{11:end})
fclose(fid); 


