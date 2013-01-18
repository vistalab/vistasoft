# Camino output directory
mkdir camino

# Make scheme file
fsl2scheme -bvecfile raw/dti_g150_b2500_aligned_trilin.bvecs -bvalfile raw/dti_g150_b2500_aligned_trilin.bvals -bscale 1E9 -flipz -flipy -flipx > microtrack_cc/rb090930.scheme2
fsl2scheme -bvecfile raw/dti_g13_b800_aligned_trilin.bvecs -bvalfile raw/dti_g13_b800_aligned_trilin.bvals -bscale 1E9 -flipz -flipy -flipx > microtrack/grad.scheme2

# Get raw data into camino format
cp raw/dti_g150_b2500_aligned_trilin.nii.gz camino/raw.nii.gz
fslchfiletype ANALYZE camino/raw.nii.gz
analyzeheader -readheader camino/raw # Displays really good info
cat camino/raw.img | shredder `analyzeheader -printprogargs camino/raw.hdr shredder` | scanner2voxel `analyzeheader -printprogargs camino/raw.hdr scanner2voxel` > camino/raw.Bfloat 
cat camino/clean.img | shredder `analyzeheader -printprogargs camino/clean.hdr shredder` | scanner2voxel `analyzeheader -printprogargs camino/clean.hdr scanner2voxel` > camino/clean.Bfloat 
cat camino/noisy.img | shredder `analyzeheader -printprogargs camino/noisy.hdr shredder` | scanner2voxel `analyzeheader -printprogargs camino/noisy.hdr scanner2voxel` > camino/noisy.Bfloat 
cat camino/raw.img | shredder 0 -2 0  | scanner2voxel -voxels 652536 -components 156 -inputdatatype short > camino/raw.Bfloat 

# Check a slice for processing times
# 156*81*106*37*4 = 198233568
# 156*81*106*4 = 5357664
# 156*81*106*37*4 = 407182464
shredder 198233568 5357664 407182464 <  ../camino/raw.Bfloat > slice38.Bfloat
# Test to make sure I got the slice
dtfit slice38.Bfloat rb090930.scheme2 | fa -outputdatatype float > slice38_FA.img 
analyzeheader -datadims 81 106 1 -voxeldims 2 2 2 -datatype float > slice38_FA.hdr
# Test to make sure the coordinate frames match for tracking
dtfit slice38.Bfloat rb090930.scheme2 | dteig | pdview -datadims 81 106 76
# Check mesd time
time mesd -schemefile rb090930.scheme2 -filter PAS 1.4 -fastmesd -mepointset 5 -bgthresh 200 < slice38.Bfloat > slice38_PAS05.Bdouble 

# Create tensors
dtfit camino/raw.Bfloat camino/rb090930.scheme2 -bgmask camino/masks/bgmask.nii.gz > camino/dt.Bdouble
# Weighted Linear Tensor Fitting
modelfit -model ldt_wtd -inputfile camino/raw.Bfloat -schemefile camino/rb090930.scheme2 -bgmask camino/masks/bgmask.nii.gz -noisemap camino/wdt_noise.Bdouble -residualmap camino/wdt_res.Bdouble -outputfile camino/wdt.Bdouble
# Weighted Linear Two Tensor Fitting
modelfit -model cylcyl ldt_wtd -inputfile camino/raw.Bfloat -schemefile camino/rb090930.scheme2 -bgmask camino/masks/bgmask.nii.gz -noisemap camino/wdt2_noise.Bdouble -residualmap camino/wdt2_res.Bdouble -outputfile camino/wdt2.Bdouble
# Weighted Linear Three Tensor Fitting
modelfit -model cylcylcyl ldt_wtd -inputfile camino/raw.Bfloat -schemefile camino/rb090930.scheme2 -bgmask camino/masks/bgmask.nii.gz -noisemap camino/wdt3_noise.Bdouble -residualmap camino/wdt3_res.Bdouble -outputfile camino/wdt3.Bdouble
# Doing spherical harmonics
shfit -order 4 -inputfile camino/raw.Bfloat -schemefile camino/rb090930.scheme2 -bgmask camino/masks/bgmask.nii.gz > camino/sh.Bdouble
cat camino/sh.Bdouble | sfpeaks -inputmodel sh -order 4 -density 100 -searchradius 1.0 > camino/sfpeaks.Bdouble
track < camino/sfpeaks.Bdouble -datadims 81 106 76 -voxeldims 2.0 2.0 2.0 -inputmodel pds -seedfile camino/masks/wm_lowres.nii.gz -anisthresh 0.05 -outputfile camino/tracts_pds_all.Bfloat

# Get noise into an image (HAVE TO CHANGE THE HEADER IN MATLAB CURRENTLY)
cp camino/wdt_noise.Bdouble camino/wdt_noise.img
analyzeheader -initfromheader camino/b0 -networkbyteorder -datatype double > camino/wdt_noise.hdr
fslchfiletype NIFTI_GZ camino/wdt_noise

# Process residuals
cat camino/wdt_res.Bdouble | voxel2scanner -voxels 652536 -components 156 -inputdatatype double -outputdatatype float  > camino/wdt_res.img
analyzeheader -initfromheader camino/raw -networkbyteorder -datatype float > camino/wdt_res.hdr
fslmaths camino/wdt_res -sqr camino/wdt_sqr
fslmaths camino/wdt_sqr -Tmean camino/wdt_msqr
fslmaths camino/wdt_msqr -sqrt camino/wdt_rmsqr
fslchfiletype NIFTI_GZ camino/wdt_rmsqr
  

# Checking tensor orientations
cat camino/dt.Bdouble | dteig | pdview -datadims 81 106 76
cat camino/dt.Bdouble | dteig | pdview `analyzeheader -printprogargs camino/raw.hdr pdview`
cat camino/dt.Bdouble | dteig | pdview `analyzeheader -printprogargs camino/clean.hdr pdview`
cat camino/noisy_peaks20.Bdouble | pdview `analyzeheader -printprogargs camino/clean.hdr pdview` -inputmodel pds -numpds 4 -scalarfile camino/fa.Bdouble 

# Getting tensor stats
fa < camino/dt.Bdouble > camino/fa.Bdouble
# Converting doubles to images
cp camino/fa.Bdouble camino/fa.img
analyzeheader -initfromheader camino/raw -networkbyteorder -nimages 1 -datatype double > camino/fa.hdr
#analyzeheader -initfromheader camino/b0 -networkbyteorder -datatype double > camino/fa.hdr
fslchfiletype NIFTI_GZ camino/fa

# Get raw data dims
 analyzeheader -printimagedims camino/raw.hdr
# Must copy and paste because the voxel coordinates are negative
-datadims 81 106 76 -voxeldims 2.0 2.0 2.0

# Tracking
track < camino/dt.Bdouble -datadims 81 106 76 -voxeldims 2.0 2.0 2.0 -inputmodel dt -seedfile camino/masks/wm_lowres.nii.gz -anisthresh 0.05 -outputfile camino/tracts.Bfloat


# Deterministic tracking within occipital lobe
# The anisotropy file must be the same dimensions as the diffusion data, only the seed file can be different
track < camino/dt.Bdouble `analyzeheader -printprogargs camino/raw.hdr track` -inputmodel dt -seedfile camino/masks/wm_lowres.nii.gz -anisthresh 0.05 -outputfile camino/tracts_all.Bfloat
track < camino/dt.Bdouble -datadims 81 106 76 -voxeldims 2.0 2.0 2.0 -inputmodel dt -seedfile camino/masks/wm_lowres.nii.gz -anisthresh 0.05 -outputfile camino/tracts_all.Bfloat
# Force connectivity between exit plane and GM
procstreamlines -inputfile camino/tracts_all.Bfloat -endpointfile camino/masks/occ_exit.nii.gz > camino/tracts_clip.Bfloat
# Throw away segments that leave the occipital lobe
procstreamlines -inputfile camino/tracts_clip.Bfloat -exclusionfile camino/masks/not_occ_mask.nii.gz > camino/tracts_occ_exit.Bfloat

# Find all fibers in the occipital lobe and clip endpoints
procstreamlines -inputfile camino/tracts_all.Bfloat -exclusionfile camino/masks/occ_exit.nii.gz -truncateinexclusion > camino/tracts_occ_clip.Bfloat
# Throw away segments that leave the occipital lobe
procstreamlines -inputfile camino/tracts_occ_clip.Bfloat -exclusionfile camino/masks/not_occ_mask.nii.gz > camino/tracts_occ.Bfloat


# Probabilistic Tractography
dtlutgen -schemefile  camino/rb090930.scheme2 -snr 16.0 -inversion 1 > camino/pico_table.dat

cat camino/dt.Bdouble | picopdfs -inputmodel dt -luts camino/pico_table.dat > camino/pdf.Bdouble

track < camino/pdf.Bdouble -datadims 81 106 76 -voxeldims 2.0 2.0 2.0 -inputmodel pico -iterations 10 -seedfile camino/masks/wm_exit.nii.gz -anisfile camino/masks/occ_mask.nii.gz -anisthresh 0.1 -outputfile camino/tracts.Bfloat

track < camino/pdf.Bdouble -datadims 81 106 76 -voxeldims 2.0 2.0 2.0 -inputmodel pico -iterations 10 -seedfile camino/masks/gm.nii.gz -outputfile camino/tracts_pico.Bfloat

procstreamlines -inputfile camino/tracts_pico.Bfloat -exclusionfile camino/masks/occ_exit_mask.nii.gz -truncateinexclusion > camino/tracts_pico_clip.Bfloat
procstreamlines -inputfile camino/tracts_pico.Bfloat -targetfile camino/masks/occ_mask.nii.gz -outputacm > camino/tracts_pico_acm.img


# Segmenting Exit Plane
# 1 Track (Short Test)
track -datadims 81 106 76 -voxeldims 2.0 2.0 2.0 -inputmodel pico -inputfile camino/pdf.Bdouble -seedfile camino/masks/wm_exit.nii.gz -iterations 10 -anisfile camino/masks/occ_mask.nii.gz -anisthresh 0.1 | procstreamlines -waypointfile camino/masks/atlas_mask.nii.gz -exclusionfile camino/masks/atlas_mask.nii.gz -truncateinexclusion > camino/tracts.Bfloat  
# 2 Track (Long Run)
track -datadims 81 106 76 -voxeldims 2.0 2.0 2.0 -inputmodel pico -inputfile camino/pdf.Bdouble -seedfile camino/masks/wm.nii.gz -iterations 10 -anisfile camino/masks/occ_mask.nii.gz -anisthresh 0.1 > camino/tracts_all.Bfloat
# 3 Only keep fibers that reach cortical data
procstreamlines -inputfile camino/tracts_all.Bfloat -waypointfile camino/masks/atlas_mask.nii.gz -exclusionfile camino/masks/atlas_mask.nii.gz -truncateinexclusion > camino/tracts.Bfloat
#procstreamlines -inputfile camino/tracts_all.Bfloat -waypointfile camino/masks/gm.nii.gz -exclusionfile camino/masks/gm.nii.gz -truncateinexclusion > camino/tracts.Bfloat

# 4 Connectivity Based Segmentation
track -datadims 81 106 76 -voxeldims 2.0 2.0 2.0 -inputmodel pico -inputfile camino/pdf.Bdouble -seedfile camino/masks/wm.nii.gz -iterations 100 -anisfile camino/masks/occ_mask.nii.gz -anisthresh 0.1 -outputtracts voxels -gzip > camino/tracts_all.Bfloat.gz

procstreamlines -inputfile camino/tracts_all.Bfloat.gz -inputmodel voxels -outputcp -iterations 100 -seedfile camino/masks/wm.nii.gz -targetfile camino/masks/atlas.nii.gz -waypointfile camino/masks/atlas_mask.nii.gz -exclusionfile camino/masks/atlas_mask.nii.gz -truncateinexclusion -outputroot camino/cbs_ -outputcbs 
# Change to nifti
fslchfiletype NIFTI_GZ camino/cbs_


# Examining how well the single tensor fits will model our data
voxelclassify -inputfile camino/raw.Bfloat -bgthresh 500 -schemefile camino/rb090930.scheme2 -order 4 > camino/voxel_classify.Bdouble

# Interactively choose the ftest for the voxels of each order
vcthreshselect -inputfile camino/voxel_classify.Bdouble -datadims 81 106 76 -order 4

# Now that we have our ftest threshold for each number lets apply it to classify the voxels
voxelclassify -inputfile camino/raw.Bfloat -bgthresh 500 -schemefile camino/rb090930.scheme2 -order 4 -ftest 1.0E-20 1.0E-30 1.0E-7 > camino/voxel_classify.Bint

# Spherical Deconvolution
mesd -inputfile camino/raw.Bfloat -schemefile camino/rb090930.scheme2 -fastmesd -mepointset 10 -filter SPIKE 1.0 -bgmask camino/masks/bgmask.nii.gz > camino/mesd.Bdouble
mesd -inputfile camino/raw.Bfloat -schemefile camino/rb090930.scheme2 -fastmesd -mepointset 20 -filter PAS 1.4 -bgmask camino/masks/bgmask.nii.gz > camino/mesd_pas.Bdouble

# Must find the peaks of the spherical distributions of possible maximal diffusion directions
cat camino/mesd_pas20_rh.Bdouble | sfpeaks -inputmodel maxent -filter PAS 1.4 -mepointset 20 -schemefile camino/rb090930.scheme2 -inputdatatype double -numpds 4 > camino/mesd_pas20_rh_peaks.Bdouble
cat camino/clean_mesd_pas10.Bdouble | sfpeaks -inputmodel maxent -filter PAS 1.4 -mepointset 10 -schemefile camino/All.scheme1 -inputdatatype double -numpds 4 > camino/clean_peaks10.Bdouble
cat camino/mesd_peaks.Bdouble | pdview -datadims 81 106 76 -inputmodel pds -numpds 4 

# Tracking from every gray matter voxel to either occipital lobe GM or exit occipital lobe
track < camino/pdf.Bdouble -datadims 81 106 76 -voxeldims 2.0 2.0 2.0 -inputmodel pico -iterations 10 -seedfile camino/masks/gm.nii.gz -outputfile camino/tracts_pico_gm.Bfloat
track < camino/clean_peaks10.Bdouble `analyzeheader -printprogargs camino/noisy.hdr track` -inputmodel pds -numpds 4 -interpolate -stepsize 0.05 -seedfile camino/fa.nii.gz -outputfile camino/tracts_mesd_wm.Bfloat
track < camino/noisy_peaks10.Bdouble `analyzeheader -printprogargs camino/noisy.hdr track` -inputmodel pds -numpds 4 -interpolate -stepsize 0.5 -seedfile camino/masks/wm.nii.gz -outputfile camino/tracts_mesd_wm.Bfloat
# From WM
track < camino/mesd_peaks.Bdouble -datadims 81 106 76 -voxeldims 2.0 2.0 2.0 -inputmodel pds -numpds 4 -interpolate -stepsize 0.5 -seedfile camino/masks/wm.nii.gz -outputfile camino/tracts_mesd_gm.Bfloat

# Compute a probability image for each GM seed
procstreamlines -inputfile camino/tracts_pico_gm.Bfloat -outputacm -outputsc -iterations 10 -seedfile camino/masks/gm.nii.gz -outputroot camino/acm/tracts_pico_gm_ 
# Reaches GM or exits and is greater than 1cm
procstreamlines -inputfile camino/tracts_pico_gm.Bfloat -projectome -mintractlength 10 -noresample -endpointfile camino/masks/occ_exit.nii.gz -outputfile camino/tracts_pico_gm_1cm.Bfloat
procstreamlines `analyzeheader -printimagedims camino/masks/t1.nii.gz` -inputfile camino/tracts_pico_gm_1cm.Bfloat -outputacm -outputsc -outputroot camino/acm/tracts_pico_gm_1cm_
fslchfiletype NIFTI_GZ camino/acm/tracts_pico_gm_1cm_acm_sc
# Must exit and is greater than 1cm
# PICO
procstreamlines -inputfile camino/tracts_pico_gm.Bfloat -noresample -endpointfile camino/masks/occ_exit.nii.gz -outputfile camino/tracts_pico_gm_exit.Bfloat
procstreamlines -inputfile camino/tracts_pico_gm_exit.Bfloat -noresample -mintractlength 10 -outputfile camino/tracts_pico_gm_exit_1cm.Bfloat
procstreamlines `analyzeheader -printimagedims camino/masks/t1.nii.gz` -inputfile camino/tracts_pico_gm_exit_1cm.Bfloat -outputacm -outputsc -outputroot camino/acm/tracts_pico_gm_exit_1cm_
fslchfiletype NIFTI_GZ camino/acm/tracts_pico_gm_exit_1cm_acm_sc
# MESD
procstreamlines -inputfile camino/tracts_mesd_gm.Bfloat -noresample -endpointfile camino/masks/occ_exit.nii.gz -outputfile camino/tracts_mesd_gm_exit.Bfloat
procstreamlines -inputfile camino/tracts_mesd_gm_exit.Bfloat -noresample -mintractlength 10 -outputfile camino/tracts_mesd_gm_exit_1cm.Bfloat
procstreamlines `analyzeheader -printimagedims camino/masks/t1.nii.gz` -inputfile camino/tracts_mesd_gm_exit_1cm.Bfloat -outputacm -outputsc -outputroot camino/acm/tracts_mesd_gm_exit_1cm_
fslchfiletype NIFTI_GZ camino/acm/tracts_mesd_gm_exit_1cm_acm_sc

#procstreamlines -inputfile camino/tracts_pico_gm_1cm.Bfloat -outputacm -ouputsc -iterations 10 -seedfile camino/masks/gm.nii.gz -outputroot camino/acm/tracts_pico_gm_1cm_ 
# next ??
procstreamlines -inputfile camino/tracts_pico_gm.Bfloat -mintractlength 10 -iterations 10 -seedfile camino/masks/gm.nii.gz -outputfile camino/tracts_pico_gm_1cm.Bfloat
procstreamlines -inputfile camino/tracts_pico_gm_1cm.Bfloat -outputacm -ouputsc -iterations 10 -seedfile camino/masks/gm.nii.gz -outputroot camino/acm/tracts_pico_gm_1cm_ 


########## BOTH HEMISPHERES ##########
# generate lookup table for all probabilistic tractography using tensor fit
dtlutgen -schemefile  camino/rb090930.scheme2 -snr 16.0 -inversion 1 > camino/pico_dt16_table.dat

########## RH ##########
#### PICO ####
# tensor fits
dtfit camino/raw.Bfloat camino/rb090930.scheme2 -bgmask camino/masks/bgmask_rh.nii.gz > camino/dt_rh.Bdouble
# generate pico pdfs
cat camino/dt_rh.Bdouble | picopdfs -inputmodel dt -luts camino/pico_dt16_table.dat > camino/pdf_rh.Bdouble
# track
track < camino/pdf_rh.Bdouble -datadims 81 106 76 -voxeldims 2.0 2.0 2.0 -inputmodel pico -iterations 40 -stepsize 0.5 -seedfile camino/masks/gm_rh.nii.gz -outputfile camino/tracts/t_pico_gm_rh.Bfloat
# reaches GM or exits and is greater than 1cm
procstreamlines -inputfile camino/tracts/t_pico_gm_rh.Bfloat -noresample -endpointfile camino/masks/occ_rh_exit.nii.gz -outputfile camino/tracts/t_pico_gm_rh_exit.Bfloat
procstreamlines -inputfile camino/tracts/t_pico_gm_rh_exit.Bfloat -noresample -mintractlength 10 -outputfile camino/tracts/t_pico_gm_rh_exit_1cm.Bfloat
procstreamlines `analyzeheader -printimagedims camino/masks/t1.nii.gz` -inputfile camino/tracts/t_pico_gm_rh_exit_1cm.Bfloat -outputacm -outputsc -outputroot camino/acm/t_pico_gm_rh_exit_1cm_
fslchfiletype NIFTI_GZ camino/acm/t_pico_gm_rh_exit_1cm_acm_sc

#### MESD ####
# spherical deconvolution
mesd -inputfile camino/raw.Bfloat -schemefile camino/rb090930.scheme2 -fastmesd -mepointset 20 -filter PAS 1.4 -bgmask camino/masks/bgmask_rh.nii.gz > camino/mesd_pas20_rh.Bdouble
# find the peaks of the spherical deconvolution output
cat camino/mesd_pas20_rh.Bdouble | sfpeaks -inputmodel maxent -filter PAS 1.4 -mepointset 20 -schemefile camino/rb090930.scheme2 -inputdatatype double -numpds 4 > camino/mesd_pas20_rh_peaks.Bdouble
# make sure the peaks look reasonable
cat camino/mesd_pas10_rh_peaks.Bdouble | pdview -datadims 81 106 76 -inputmodel pds -numpds 4 
# track
track < camino/mesd_pas20_rh_peaks.Bdouble -datadims 81 106 76 -voxeldims 2.0 2.0 2.0 -inputmodel pds -numpds 4 -interpolate -stepsize 0.5 -seedfile camino/masks/wm_rh.nii.gz -outputfile camino/tracts/t_mesd_pas20_wm_rh.Bfloat
# projectome
procstreamlines -inputfile camino/tracts/t_mesd_pas20_wm_rh.Bfloat -noresample -projectome -endpointfile camino/masks/occ_rh_exit_mask.nii.gz -outputfile camino/tracts/t_mesd_pas20_wm_rh_proj.Bfloat
# reaches GM or exits and is greater than 1cm
procstreamlines -inputfile camino/tracts/t_mesd_pas20_wm_rh_proj.Bfloat -noresample -endpointfile camino/masks/occ_rh_exit.nii.gz -outputfile camino/tracts/t_mesd_pas20_wm_rh_exit.Bfloat
procstreamlines -inputfile camino/tracts/t_mesd_pas20_wm_rh_exit.Bfloat -noresample -mintractlength 20 -outputfile camino/tracts/t_mesd_pas20_wm_rh_exit_2cm.Bfloat
procstreamlines `analyzeheader -printimagedims camino/masks/t1.nii.gz` -inputfile camino/tracts/t_mesd_pas20_wm_rh_exit_2cm.Bfloat -outputacm -outputsc -outputroot camino/acm/t_mesd_pas20_wm_rh_exit_2cm_
fslchfiletype NIFTI_GZ camino/acm/t_mesd_pas20_wm_rh_exit_2cm_acm_sc
# Quench
contrack_score -i ctr_params.txt -p camino/tracts/t_mesd_pas20_wm_rh_exit_2mm.pdb --thresh 100000 --seq --bfloat_no_stats camino/tracts/t_mesd_pas20_wm_rh_exit_2mm.Bfloat
~/src/dtiTools/quench/Quench.app/Contents/MacOS/Quench  dti150/fibers/qmasks\* camino/tracts/t_mesd_pas20_wm_rh_exit_1cm.pdb  anatomy/right_inflated.bin

#procstreamlines `analyzeheader -printimagedims camino/masks/t1.nii.gz` -inputfile camino/tracts/t_mesd_gm_rh_exit_1cm.Bfloat -outputacm -outputsc -outputroot camino/acm/t_mesd_gm_rh_exit_1cm_
#fslchfiletype NIFTI_GZ camino/acm/t_mesd_gm_rh_exit_1cm_acm_sc

########## LH ##########
#### PICO ####
# tensor fits
dtfit camino/raw.Bfloat camino/rb090930.scheme2 -bgmask camino/masks/bgmask_lh.nii.gz > camino/dt_lh.Bdouble
# generate pico pdfs
cat camino/dt_lh.Bdouble | picopdfs -inputmodel dt -luts camino/pico_dt16_table.dat > camino/pdf_lh.Bdouble
# track
track < camino/pdf_lh.Bdouble -datadims 81 106 76 -voxeldims 2.0 2.0 2.0 -inputmodel pico -iterations 40 -stepsize 0.5 -seedfile camino/masks/gm_lh.nii.gz -outputfile camino/tracts/t_pico_gm_lh.Bfloat
# reaches GM or exits and is greater than 1cm
procstreamlines -inputfile camino/tracts/t_pico_gm_lh.Bfloat -noresample -endpointfile camino/masks/occ_lh_exit.nii.gz -outputfile camino/tracts/t_pico_gm_lh_exit.Bfloat
procstreamlines -inputfile camino/tracts/t_pico_gm_lh_exit.Bfloat -noresample -mintractlength 10 -outputfile camino/tracts/t_pico_gm_lh_exit_1cm.Bfloat
procstreamlines `analyzeheader -printimagedims camino/masks/t1.nii.gz` -inputfile camino/tracts/t_pico_gm_lh_exit_1cm.Bfloat -outputacm -outputsc -outputroot camino/acm/t_pico_gm_lh_exit_1cm_
fslchfiletype NIFTI_GZ camino/acm/t_pico_gm_lh_exit_1cm_acm_sc

#### MESD ####
# spherical deconvolution
mesd -inputfile camino/raw.Bfloat -schemefile camino/rb090930.scheme2 -fastmesd -mepointset 10 -filter PAS 1.4 -bgmask camino/masks/bgmask_lh.nii.gz > camino/mesd_pas10_lh.Bdouble
# find the peaks of the spherical deconvolution output
cat camino/mesd_pas10_lh.Bdouble | sfpeaks -inputmodel maxent -filter PAS 1.4 -mepointset 10 -schemefile camino/rb090930.scheme2 -inputdatatype double -numpds 4 > camino/mesd_pas10_lh_peaks.Bdouble
# make sure the peaks look reasonable
cat camino/mesd_pas10_lh_peaks.Bdouble | pdview -datadims 81 106 76 -inputmodel pds -numpds 4 
# track
track < camino/mesd_pas20_lh_peaks.Bdouble -datadims 81 106 76 -voxeldims 2.0 2.0 2.0 -inputmodel pds -numpds 4 -interpolate -stepsize 0.5 -seedfile camino/masks/wm_lh.nii.gz -outputfile camino/tracts/t_mesd_pas20_wm_lh.Bfloat
# projectome
procstreamlines -inputfile camino/tracts/t_mesd_pas20_wm_lh.Bfloat -mintractlength 10 -noresample -projectome -endpointfile camino/masks/occ_lh_exit_mask.nii.gz -outputfile camino/tracts/t_mesd_pas20_wm_lh_proj.Bfloat
# reaches GM or exits and is greater than 1cm
procstreamlines -inputfile camino/tracts/t_mesd_pas20_wm_lh_proj.Bfloat -noresample -endpointfile camino/masks/occ_lh_exit.nii.gz -outputfile camino/tracts/t_mesd_pas20_wm_lh_exit.Bfloat
procstreamlines -inputfile camino/tracts/t_mesd_pas20_wm_lh_exit.Bfloat -noresample -mintractlength 20 -outputfile camino/tracts/t_mesd_pas20_wm_lh_exit_2cm.Bfloat
procstreamlines `analyzeheader -printimagedims camino/masks/t1.nii.gz` -inputfile camino/tracts/t_mesd_pas20_wm_lh_exit_2cm.Bfloat -outputacm -outputsc -outputroot camino/acm/t_mesd_pas20_wm_lh_exit_2cm_
fslchfiletype NIFTI_GZ camino/acm/t_mesd_pas20_wm_lh_exit_2cm_acm_sc
# Quench
contrack_score -i ctr_params.txt -p camino/tracts/t_mesd_pas20_wm_lh_exit_2mm.pdb --thresh 1000000 --seq --bfloat_no_stats camino/tracts/t_mesd_pas20_wm_lh_exit_2mm.Bfloat
~/src/dtiTools/quench/Quench.app/Contents/MacOS/Quench  dti150/fibers/qmasks\* camino/tracts/t_mesd_pas20_wm_lh_exit_2cm.pdb  anatomy/left_inflated.bin


# ALLMAN
image2voxel -4dimage camino/raw.nii.gz > camino/raw.Bfloat
# fsl2scheme
dtfit camino/raw.Bfloat camino/scheme.scheme2 -bgmask camino/masks/bgmask.nii.gz > camino/dt.Bdouble
cat camino/dt.Bdouble | dteig | pdview `analyzeheader -printprogargs camino/raw.nii.gz pdview`
fa < camino/dt.Bdouble > camino/fa.img
analyzeheader -initfromheader sim_dwi.nii.gz -networkbyteorder -datatype double -nimages 1 > camino/fa.hdr
fslchfiletype NIFTI_GZ camino/fa
track -inputfile camino/dt.Bdouble `analyzeheader -printprogargs camino/raw.nii.gz track` -inputmodel dt -seedfile camino/all_seeds.nii.gz -anisthresh 0.1 -outputfile camino/tracts_dt_all.Bfloat
procstreamlines -inputfile camino/tracts_dt_all.Bfloat -noresample -mintractlength 30 -outputfile camino/tracts_dt_all_gt3cm.Bfloat
procstreamlines `analyzeheader -printimagedims camino/raw.nii.gz` -inputfile camino/tracts_dt_all_gt3cm.Bfloat -outputacm -outputsc -outputroot camino/tracts_dt_all_gt3cm_
fslchfiletype NIFTI_GZ camino/tracts_dt_all_gt3cm_acm_sc


# RB MICROTRACK CC
# Get voxelwise data format
image2voxel -4dimage microtrack_cc/raw.nii.gz > microtrack_cc/raw.Bfloat
# Fit tensors
dtfit microtrack_cc/raw.Bfloat microtrack_cc/rb090930.scheme2 > microtrack_cc/dt.Bdouble
# track, no curvature constraint
track < microtrack_cc/dt.Bdouble -datadims 81 106 76 -voxeldims 2.0 2.0 2.0 -inputmodel dt -seedfile microtrack_cc/cc_seed.nii.gz -anisthresh 0.05 -anisfile microtrack_cc/cc_fa.nii.gz -ipthresh -1 -outputfile microtrack_cc/tracts.Bfloat
# reaches GM or exits and is greater than 1cm
procstreamlines -inputfile microtrack_cc/tracts/t_pico_gm_rh.Bfloat -noresample -endpointfile microtrack_cc/masks/occ_rh_exit.nii.gz -outputfile microtrack_cc/tracts/t_pico_gm_rh_exit.Bfloat
procstreamlines -inputfile microtrack_cc/tracts/t_pico_gm_rh_exit.Bfloat -noresample -mintractlength 10 -outputfile microtrack_cc/tracts/t_pico_gm_rh_exit_1cm.Bfloat
procstreamlines `analyzeheader -printimagedims microtrack_cc/masks/t1.nii.gz` -inputfile microtrack_cc/tracts/t_pico_gm_rh_exit_1cm.Bfloat -outputacm -outputsc -outputroot microtrack_cc/acm/t_pico_gm_rh_exit_1cm_
fslchfiletype NIFTI_GZ microtrack_cc/acm/t_pico_gm_rh_exit_1cm_acm_sc


# MICCAI (to be run in phantom directory)
# Get voxelwise data format
image2voxel -4dimage optimize/meas-dwi.nii.gz > optimize/meas-dwi.Bfloat
# Tensor processing
dtfit optimize/meas-dwi.Bfloat optimize/All.scheme1 > optimize/dt.Bdouble
# Visualization check
cat optimize/dt.Bdouble | dteig | pdview `analyzeheader -printprogargs optimize/meas-dwi.nii.gz pdview`
fa < optimize/dt.Bdouble > optimize/fa.img
analyzeheader -initfromheader optimize/meas-dwi.nii.gz -networkbyteorder -datatype double -nimages 1 > optimize/fa.hdr
fslchfiletype NIFTI_GZ optimize/fa
# Tracking
track -inputfile optimize/dt.Bdouble `analyzeheader -printprogargs optimize/meas-dwi.nii.gz track` -inputmodel dt -seedfile optimize/dti/bin/wm.nii.gz -anisfile optimize/dti/bin/wm.nii.gz -anisthresh 0.1 -outputfile optimize/tracts_dt_all.Bfloat
# Force streamlines to connect to GM
procstreamlines -inputfile optimize/tracts_dt_all.Bfloat -projectome -mintractlength 0.5 -noresample -endpointfile optimize/dti/bin/gm.nii.gz -outputfile optimize/tracts_dt_gm.Bfloat


############### G300 g300 ########################
# SEE TUTORIAL
## Fit the DT.
#dtfit All.Bfloat All.scheme1 -flipx > microtrack_cc/dt.Bdouble
#dteig < microtrack_cc/dt.Bdouble | pdview -datadims 128 141 30
#dtfit All.Bfloat All.scheme1 -bgmask microtrack_cc/mask.nii.gz > microtrack_cc/dt_mask.Bdouble
#fa < microtrack_cc/dt_mask.Bdouble -outputdatatype float > microtrack_cc/fa_mask.img
#trd < microtrack_cc/dt_mask.Bdouble -outputdatatype float > microtrack_cc/trd_mask.img
#analyzeheader -datadims 128 141 30 -voxeldims 0.5 0.5 0.5 -datatype float > microtrack_cc/fa_mask.hdr
#fslchfiletype NIFTI_GZ microtrack_cc/fa_mask
#analyzeheader -datadims 128 141 30 -voxeldims 0.5 0.5 0.5 -datatype float > microtrack_cc/trd_mask.hdr
#fslchfiletype NIFTI_GZ microtrack_cc/trd_mask

# Track fibers from within small mask around CC
track -inputmodel pds -seedfile cc_plus_mask.nii.gz -outputfile cc_plus_mask_tracks.Bfloat -interpolate -stepsize 0.5 < PDs.Bdouble
# Clip fibers as they exit the mask
procstreamlines -inputfile cc_plus_mask_tracks.Bfloat -noresample -exclusionfile cc_plus_not_mask.nii.gz -truncateinexclusion -outputfile cc_plus_clip_tracks.Bfloat
# Keep only fibers that connect the end ROIs
procstreamlines -inputfile cc_plus_clip_tracks.Bfloat -mintractlength 5 -noresample -endpointfile cc_plus_ends_mask.nii.gz -outputfile cc_plus_ends_tracks.Bfloat
#procstreamlines -inputfile cc_plus_mask_tracks.Bfloat -projectome -mintractlength 2 -noresample -endpointfile cc_plus_ends_mask.nii.gz -outputfile cc_plus_ends_tracks.Bfloat

################# Probabilistic Tracking with HARDI #################
sfpicocalibdata -schemefile dti_g150_b2500_aligned_trilin.scheme2 -snr 12 -infooutputfile CalibData.info > CalibData.Bfloat
#nohup time mesd -schemefile dti_g150_b2500_aligned_trilin.scheme2 -filter PAS 1.4 -fastmesd -mepointset 16 < CalibData.Bfloat > CalibDataPAS16.Bdouble &> calib_mesd_out.txt &
nohup time mesd -schemefile dti_g150_b2500_aligned_trilin.scheme2 -filter PAS 1.4 -fastmesd -mepointset 5 < CalibData.Bfloat > CalibDataPAS05.Bdouble &> calib_mesd_out_05.txt &
sfpeaks -schemefile  dti_g150_b2500_aligned_trilin.scheme2 -inputmodel maxent -filter PAS 1.4 -mepointset 5 -inputdatatype double < CalibDataPAS05.Bdouble > CalibDataPAS05_PDs.Bdouble
sflutgen -infofile CalibData.info -outputstem PAS05_LUT -pdf watson < CalibDataPAS05_PDs.Bdouble

picopdfs -inputmodel pds -numpds 3 -pdf watson -luts PAS05_LUT_oneFibreLineCoeffs.Bdouble PAS05_LUT_twoFibreLineCoeffs.Bdouble PAS05_LUT_twoFibreLineCoeffs.Bdouble < PAS05_PDs.Bdouble > PAS05_PDsWatsonPDFs.Bdouble
#track -inputmodel pico -pdf watson -numpds 3 -iterations 10 -seedfile $SEEDFILEROOT -outputroot ${DSID}_${SEEDFILEROOT}_PAS${REID}10 -outputtracts oogl < PAS${REID}_${DSID}/PDsWatsonPDFs.Bdouble
#geomview ${DSID}_${SEEDFILEROOT}_PAS${REID}101.oogl &

################# LOWRES --- Probabilistic Tracking with HARDI #################
sfpicocalibdata -schemefile b04609.scheme1 -snr 1000 -infooutputfile CalibData_snr1000_lowres.info -twodtfarange 0.3 0.5 -twodtfastep 0.2 -twodtanglerange 0 0.785 -twodtanglestep 0.3925 -twodtmixmax 0.8 -twodtmixstep 0.2 > CalibData_snr1000_lowres.Bfloat
time mesd -schemefile b04609.scheme1 -filter PAS 1.4 -fastmesd -mepointset 16 < CalibData_snr1000_lowres.Bfloat > CalibData_snr1000_lowres_pas16.Bdouble

sfpeaks -schemefile b04609.scheme1 -inputmodel maxent -filter PAS 1.4 -mepointset 16 -inputdatatype double < CalibData_snr1000_lowres_pas16.Bdouble > CalibData_snr1000_lowres_pas16_pds.Bdouble

sflutgen -infofile CalibData_snr1000_lowres.info -outputstem CalibData_snr1000_lowres_pas16_lut -pdf watson < CalibData_snr1000_lowres_pas16_pds.Bdouble

################# Probabilistic Tracking with DTI for Retinotopy #################
dtlutgen -schemefile dti_g150_b2500_aligned_trilin.scheme2 -snr 12.0 -inversion 1 > DT_LUT.Bdouble
cat dt.Bfloat | picopdfs -inputmodel dt -luts DT_LUT.Bdouble > dt_PDFs.Bdouble

#track `analyzeheader -printprogargs ../raw/dti_g150_b2500_aligned_trilin.nii.gz track` -inputmodel pico -inputfile dt_PDFs.Bdouble -seedfile ../masks/retinotopy/wm_rh_exit.nii.gz -iterations 1 -outputtracts raw -anisfile ../masks/retinotopy/occ_rh_mask.nii.gz -anisthresh 0.5 > picoTracts-1.Bfloat


#export ATLAS="ecc_var_0.1"
#export ATLAS="rois"
#export ATLAS="ecc_var_0.1_vo"

export HEM="rh"
export ITER=100
#export ATLAS="ecc_var_0.30"
export ATLAS="rois_cv3ab_ecc_var_0.20"
export MASKDIR="../masks/retinotopy/masks_occ80_05_Aug_2010"
export CBSDIR="ret_exit_count"
echo ${HEM}
#track `analyzeheader -printprogargs ../raw/dti_g150_b2500_aligned_trilin.nii.gz track` -stepsize 0.5 -inputmodel pico -inputfile dt_PDFs.Bdouble -seedfile ../masks/retinotopy/wm_${HEM}_exit.nii.gz -iterations $ITER -outputtracts raw > ${HEM}_pico_tracks_${ITER}_-2.Bfloat
procstreamlines -noresample -inputfile ${HEM}_pico_tracks_${ITER}_-2.Bfloat -inputmodel raw -outputcp -exclusionfile ${MASKDIR}/not_occ_${HEM}_mask.nii.gz -truncateinexclusion -seedfile ${MASKDIR}/wm_${HEM}_exit.nii.gz -targetfile ${MASKDIR}/atlas_${ATLAS}.nii.gz -outputroot ${CBSDIR}/cbs_${HEM}_${ITER}_${ATLAS}_ -outputcbs -iterations $ITER
fslchfiletype NIFTI_GZ ${CBSDIR}/cbs_${HEM}_${ITER}_${ATLAS}_labels*.hdr
fslchfiletype NIFTI_GZ ${CBSDIR}/cbs_${HEM}_${ITER}_${ATLAS}_labelcp*.hdr

#procstreamlines -noresample -inputfile ${HEM}_pico_tracks_${ITER}_-2.Bfloat -inputmodel raw -endpointfile ../masks/retinotopy/occ_${HEM}_exit.nii.gz > ${HEM}_pico_tracks_${ITER}_-1.Bfloat
#procstreamlines -noresample -inputfile ${HEM}_pico_tracks_${ITER}_-1.Bfloat -inputmodel raw -exclusionfile ../masks/retinotopy/not_occ_${HEM}_mask.nii.gz > ${HEM}_pico_tracks_${ITER}.Bfloat
#procstreamlines -noresample -inputfile ${HEM}_pico_tracks_${ITER}.Bfloat -inputmodel raw -outputcp -iterations $ITER -seedfile ../masks/retinotopy/wm_${HEM}_exit.nii.gz -targetfile ../masks/retinotopy/rois_${HEM}.nii.gz -outputroot cbs_${HEM}_${ITER} -outputcbs


contrack_score -i ctr_params.txt -p p.pdb --thresh 1000000 --seq --bfloat_no_stats ${HEM}_pico_tracks_${ITER}.Bfloat

################# Session with Jason #################
mkdir camino_jason
fsl2scheme -bvecfile raw/dti_g150_b2500_aligned_trilin.bvecs -bvalfile raw/dti_g150_b2500_aligned_trilin.bvals -bscale 1E9 -flipz -flipy -flipx > camino_jason/rb090930.scheme2
# Get raw data into camino format
cp raw/dti_g150_b2500_aligned_trilin.nii.gz camino_jason/raw.nii.gz
# Displays really good info
analyzeheader -readheader camino_jason/raw.nii.gz 
image2voxel -4dimage camino_jason/raw.nii.gz > camino_jason/raw.Bfloat
# Create tensors
dtfit camino_jason/raw.Bfloat camino_jason/rb090930.scheme2 > camino_jason/dt.Bdouble
# Visualization for getting the orientation right
cat camino_jason/dt.Bdouble | dteig | pdview -datadims 81 106 76
# Tracking
track < camino_jason/dt.Bdouble -datadims 81 106 76 -voxeldims 2.0 2.0 2.0 -inputmodel dt -seedfile camino_jason/seed.nii.gz -anisthresh 0.15 -anisfile camino_jason/fa.nii.gz -ipthresh -1 -outputfile camino_jason/tracts.Bfloat
# Get scalar img
fa < camino_jason/dt.Bdouble > camino_jason/fa.img
analyzeheader -initfromheader camino_jason/raw.nii.gz -networkbyteorder -datatype double -nimages 1 > camino_jason/fa.hdr
fslchfiletype NIFTI_GZ camino_jason/fa
# call cam_fix_header.m
# Let's get the fibers into a format that quench can load
contrack_score -i camino_jason/ctr_params.txt -p camino_jason/tracts.pdb --thresh 100000 --seq --bfloat_no_stats camino_jason/tracts.Bfloat
# Run Quench
~/src/dtiTools/quench/Quench.app/Contents/MacOS/Quench camino_jason/qimages/\* camino_jason/tracts.pdb
################# Session with Jason #################


################# Looking at DT Residuals #################
datasynth -inputfile dt.Bfloat -inputmodel dt -schemefile dti_g150_b2500_aligned_trilin.scheme2 > synth_dt.Bfloat
cat synth_dt.Bfloat | voxel2scanner -voxels 652536 -components 156 -inputdatatype float -outputdatatype float  > synth_dt.img
analyzeheader -initfromheader ../raw/dti_g150_b2500_aligned_trilin.nii.gz -networkbyteorder -datatype float > synth_dt.hdr
fslchfiletype NIFTI_GZ synth_dt

################# Looking at MESD Residuals #################
mask -schemefile dti_g150_b2500_aligned_trilin.scheme2 -bgthresh 200 -outputdatatype char < raw.Bfloat > bgmask.img
analyzeheader -initfromheader fa.nii.gz -networkbyteorder -datatype char -nimages 1 > bgmask.hdr

datasynth -inputfile PAS16_PDs.Bdouble -inputmodel pds -schemefile dti_g150_b2500_aligned_trilin.scheme2 > synth_pas16.Bfloat
pdview -inputmodel pds `analyzeheader -printprogargs fa.nii.gz pdview` -scalarfile fa.nii.gz -bgthresh 200 < PAS16_PDs.Bdouble

#### For Quench (must create a simple ctr_params.txt file that just has wm.nii.gz for all images)
# Convert to pdb
contrack_score -i ctr_params.txt -p camino_jason/tracts.pdb --thresh 100000 --seq --bfloat_no_stats optimize/tracts_dt_gm.Bfloat
# Run Quench
~/src/dtiTools/quench/Quench.app/Contents/MacOS/Quench optimize/dti/bin/ optimize/tracts_dt_gm.pdb
