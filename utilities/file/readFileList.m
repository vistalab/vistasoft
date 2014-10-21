function FileList= readFileList(filename)

%Reads list of files line by line into a cell array
fid=fopen(filename, 'r');
count=0;
FileList = {};
while 1
    count=count+1;
    tline=fgetl(fid);
    if ~ischar(tline)
        break
    end
       
FileList(count, 1)=cellstr(tline);
end
    
fclose(fid); 
