%% This script bandpass filters unfiltered nifti files with a butterworth
% filter. And detrend to k order

% DEPENDENCIES:
% Tools for NIfTI and ANALYZE image: https://de.mathworks.com/matlabcentral/fileexchange/8797-tools-for-nifti-and-analyze-image
% spm_detrend function
% S_detrend_2D.m

close all;
clearvars;
path1=uigetdir('/STUDYFOLDER/');
tp = {'ses-01'};

fmri = 'taskname';

feat = {'FEAT.feat'};

subj_temp=select_input([path1 '/preproc/'],'all');
sublist = subj_temp{1}';

DATAPATH = [path1 '/preproc/'];

subjID = sublist;

for n = 1: numel(subjID)
    for m = 1: numel(tp)
        for j = 1:length(feat)
            fmrifile = dir([DATAPATH subjID{n} filesep tp{m} filesep '/func/' fmri filesep feat{j} filesep subjID{n} '_FEAT_detrend_filt.nii.gz']);
            if exist([fmrifile.folder filesep fmrifile.name], 'file') == 2
                fprintf('\n##### %s detrend data has been done for %s,%s,%s\n',fmri,subjID{n},tp{m},feat{j});
            else
                
                SUBPATH = [DATAPATH, subjID{n}, '/' ,tp{m}];
                featfile=[SUBPATH , '/func/' fmri filesep feat{j} '/filtered_func_data.nii.gz'] ;
                if exist (featfile,'file') == 0
                    fprintf('\n##### %s Data is NOT available for %s,%s,%s\n',fmri,subjID{n},tp{m},feat{j});
                    continue;
                else
                    fprintf('\n...... %s detrend data is running for %s,%s,%s\n',fmri,subjID{n},tp{m},feat{j});
                end
                
                
                %% load nifti
                
                img = load_untouch_nii ([SUBPATH, '/func/' fmri filesep feat{j} '/filtered_func_data.nii.gz']);
                
                nii = double(reshape(img.img, [], img.hdr.dime.dim(5)));
                
                %TR
                TR = img.hdr.dime.pixdim(5);
                
                %%load mask
                mask = load_untouch_nii ([SUBPATH, '/func/' fmri filesep feat{j} '/mask.nii.gz']);
                mask = double(reshape(mask.img,  [], mask.hdr.dime.dim(5)));
                mask_coords = find(mask);
                
                % mask image
                nii_masked = nii(mask_coords,:);
                
                
                %% Detrend
                k = 3;           % linear , quadratic and cubic detrending
                
                % get TS voxel means
                nii_means = mean(nii_masked,2);
                
                [ nii_masked ] = S_detrend_data2D( nii_masked, k );
                
                
                %% readd TS voxel means
                for i=1:size(nii_masked,2)
                    nii_masked(:,i) = nii_masked(:,i)+nii_means;
                end
                
                disp ([subjID{n}, ': add mean back done']);
                
                
                %% filter
                % parameters, for detail see help NoseGenerator.m
                
                LowCutoff = 0.01;
                HighCutoff = 0.1;
                filtorder = 8;
                samplingrate = 1/TR;         %in Hz, TR=2s, FS=1/(TR=2)
                
                
                for i = 1:size(nii_masked,1)
                    
                    [B,A] = butter(filtorder,LowCutoff/(samplingrate/2),'high');
                    nii_masked(i,:)  = filtfilt(B,A,nii_masked(i,:)); clear A B;
                    
                    [B,A] = butter(filtorder,HighCutoff/(samplingrate/2),'low');
                    nii_masked(i,:)  = filtfilt(B,A,nii_masked(i,:)); clear A B
                    
                end
                
                
                %% readd TS voxel means
                for i=1:size(nii_masked,2)
                    nii_masked(:,i) = nii_masked(:,i)+nii_means;
                end
                
                
                disp ([subjID{n}, ': detrending + bandpass filtering + add mean back done']);
                                
                
                %% save file
                
                nii(mask_coords,:)= nii_masked;
                
                img.img = nii;
                save_untouch_nii (img, [SUBPATH, '/func/' fmri filesep feat{j} filesep, subjID{n},'_FEAT_detrend_filt.nii.gz'])
                disp (['saved as: ',[SUBPATH , '/func/' fmri filesep feat{j} filesep subjID{n},'_',tp{m},'_FEAT_detrend_filt.nii.gz']])
                
            end
        end
    end
end
