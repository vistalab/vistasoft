function dtiFractionizeFiberDataSet(fgFile, NumFibersPerPartition)

%function FractionizeFiberDataSet(FiberGroupFile, NumFibersPerPartitions)
%Splits the original data (on disk) into subsets of specific size (saves on
%disk)

%So for the full brain we have about 300,000 fibers and we want to form
%perhaps 500-600 partitions (that would allow submitting 500-600 jobs to the
%cluster at once). Hence an obvious NumFibersPerPartitions choice for the
%full brain is to include 500 fibers in each partition.

%ER 02/2008 SCSNL

if  ischar(NumFibersPerPartition)
    NumFibersPerPartition=str2num(NumFibersPerPartition);
end

[pathstr, fgFile, ext, versn] = fileparts(fgFile);

if isempty(pathstr)
    pathstr=['.' filesep ];
end

parentFgfile=fullfile(pathstr, fgFile);

load(fgFile); 


fgtotal=fg;     
fg.fibers=[]; %Memory management

numFibers=size(fgtotal.fibers,1); 
partitionCount=0; 


mkdir(pathstr, 'fgFile_Parts');
fid=fopen(['Partitions_of_' fgFile '.txt'], 'w'); 

for partition=1:NumFibersPerPartition:numFibers
    fg.name=[fg.name '_' num2str(partition) 'to' num2str(min(partition+(NumFibersPerPartition-1), numFibers))];
    partitionCount=partitionCount+1;
    %a crude hack check: if there is a field fg.fibervarcovs, this is a
    %SuperfiberSet, so propagate fibervarcovs. Otherwise - seeds
    if isfield(fgtotal, 'seeds')
    fg.seeds=fgtotal.seeds(partition:min(partition+(NumFibersPerPartition-1), numFibers), :); 
    end
    if isfield(fgtotal, 'n')
    fg.n=fgtotal.n(partition:min(partition+(NumFibersPerPartition-1), numFibers)); 
    end
    if isfield(fgtotal, 'fibervarcovs')
    fg.fibervarcovs=fgtotal.fibervarcovs(partition:min(partition+(NumFibersPerPartition-1), numFibers), :); 
    end
    %%%
    
    fg.fibers=fgtotal.fibers(partition:min(partition+(NumFibersPerPartition-1), numFibers));
    outputfilename=fullfile(pathstr, 'fgFile_Parts',  [fgFile '_' num2str(partition) 'to' num2str(min(partition+(NumFibersPerPartition-1), numFibers))]);
    save(outputfilename, 'fg', 'versionNum', 'coordinateSpace', 'parentFgfile'); 
    display([outputfilename ' saved']); 
    fprintf(fid,'%s\n',[fgFile '_' num2str(partition) 'to' num2str(min(partition+(NumFibersPerPartition-1), numFibers)) '.mat']); 
end

fclose(fid);     