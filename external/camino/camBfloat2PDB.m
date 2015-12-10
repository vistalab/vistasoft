function camBfloat2PDB(bfloat_filename,pdb_filename,ctr_filename,fa_filename)

opt_ctr = [' -i ' ctr_filename];
opt_bfloat = [' ' bfloat_filename];
opt_pdb = [' -p ' pdb_filename];

if ~exist(ctr_filename,'file') && exist(fa_filename,'file')
    % Create contrack parameters script if it doesn't exist
    % Bfloat conversion currently uses contrack so we need ctr file
    ctr = ctrCreate();
    % Must set pdb image, but can be anything
    % XXX
    % Must be absolute pathway or something is going wrong with relative
    % naming
    % XXX
    [pathstr, name, ext] = fileparts(fa_filename);
    ctr.pdf_filename = [name ext];
    ctr.image_directory = [pathstr '/'];
    ctrSave(ctr,ctr_filename);
    
end

cmd = ['contrack_score.glxa64' opt_ctr opt_pdb '  --thresh 100000 --seq --bfloat_no_stats' opt_bfloat];
display(cmd);
system(cmd,'-echo');

end
