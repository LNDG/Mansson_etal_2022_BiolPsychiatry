# Mansson_etal_2021_BiolPsychiatry
In this repository you will find the code/scripts we used to produce results reported in "Moment-to-moment brain signal variability reliably predicts psychiatric treatment outcome" by Kristoffer N T Månsson, Leonhard Waschke, Amirhossain Manzouri, Tomas Furmark, Håkan Fischer and Douglas D Garrett [https://doi.org/10.1016/j.biopsych.2021.09.026]. You will also find detailed statistical output from all the results presented in the paper. Please reference this paper if you intend to reuse this code.

Due to ethics constraints, we cannot at present make the raw patient data openly available. Please contact the first author (K.M.) to discuss potential routes to data access.

**/figures**: Code to reproduce figures are presented here.

**/GLM**: Output from the supplementary GLM analysis can be found here. 

**/PLS**: Scripts and output from PLS can be found here.

**/PLS/batch**: These scripts prepare subjects' files (i.e., “sessiondata.mat”), and here you also find the scripts to run the behavioral PLS models.

**PLS/output**: Here you will find detailed output from PLS, as presented in the paper.

**/preproc**: Scripts we used for the preprocessing pipeline can be found in this folder. Preprocessing was performed with both FSL5 and MATLAB functions. Settings of key variables for preprocessing can be found (and adjusted if desired) here.

**/reliability_prediction**: Here you find the script we developed to run the two-step reliability-based cross-validation.

**/STATA**: Detailed statistical outputs from STATA are presented here.

**/test_retest**: Code and output from the test-retest results are presented here.


* PLS toolbox for matab found [here](https://www.rotman-baycrest.on.ca/index.php?section=84 "Title")
* FSL found [here](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki "Title")
* Nifti toolbox for matlab found [here](https://de.mathworks.com/matlabcentral/fileexchange/8797-tools-for-nifti-and-analyze-image "Title")
* Matlab statistics and machine learning toolbox found [here](https://de.mathworks.com/products/statistics.html "Title")
