function  fixDcm2NiiQto(dti_raw_file, dti_raw_file_F)

%LIttle fix for dc2mnii -generated fti files
%fixDcm2NiiQto(dti_raw_file, dti_raw_file_F)
%ER based on a script by KS w/BD help 08/2008

%Pass dti_raw_file name and the "fixed" dti_raw_file_F name
ni_dti = niftiRead(dti_raw_file);

ni_dti.fname=dti_raw_file_F;

if (abs(ni_dti.qto_xyz - ni_dti.sto_xyz) < 0.0001) 
    disp('dti matched'); 
else
    ni_dti.qto_xyz
    ni_dti.sto_xyz
    ni_dti = niftiSetQto(ni_dti, ni_dti.sto_xyz);      
    writeFileNifti(ni_dti);
end

end 
