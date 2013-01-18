function compute_masscenter_interfiber_distances(infile, range1start, range1end, range2start,  range2end)

%compute center-of-mass interfiber distances for fg.fibers structures in infile.mat 
%save distance matrix into outfile. Range1 ([Nfrst Nlasst]) and range2 specify groups of fibers among which the distances should be computed. 
%ER 12/2007 Infile: use prefix. range1/2start/end: supply as a string
%(e.g., '5') -- needed for later to pass bash string arguments. 

load(infile); 
range1start=min(max(str2num(range1start), 1), size(fg.fibers, 1));
range2start=min(max(str2num(range2start), 1), size(fg.fibers, 1)) ;

range1end=max(min(str2num(range1end), size(fg.fibers, 1)), range1start);
range2end=max(min(str2num(range2end), size(fg.fibers, 1)), range2start) ;

display(['Data: ' infile ]); 
method='masscenter_dist'; 
display(['Distance metric: ' method ]); 
display(['Fibergroups analyzed: ' num2str(range1start) ' to ' num2str(range1end) ' and ' num2str(range2start) ' to ' num2str(range2end)]);


fibergroup1=fg.fibers(range1start:range1end);
fibergroup2=fg.fibers(range2start:range2end);    

clear fg; 

if (range1start==range2start&range1end==range2end)
    display('One fiber group found');
    tic; distmsr =  InterfiberMassCenterDistances(fibergroup1);  toc; 
 
else
    display('Two distinct fiber groups found');
tic; distmsr =  InterfiberMassCenterDistances(fibergroup1, fibergroup2);  toc; 
end

outfile=[infile 'masscenterdist' num2str(range1start) 'to' num2str(range1end) 'vs' num2str(range2start) 'to' num2str(range2end) '.mat'];
save(outfile, 'distmsr', 'fibergroup1', 'fibergroup2', 'infile', 'range1start', 'range2start', 'range1end', 'range2end', 'method'); 

