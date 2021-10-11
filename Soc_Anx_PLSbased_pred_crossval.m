%%
clc
clear
close all
%% Initialize things for model runs...

basepath = '/Volumes/TEMPLATE/Projects/SocAnx/';
toolpath = [basepath 'tools/'];

%set data paths
datapath = [basepath 'data/'];
fmri_datapath= [datapath 'preproc/conditions_n28/'];
mask_path = [datapath 'Relevant Masks/'];

% we'll also need the PLS toolbox
addpath(genpath([basepath 'software/PLS/']));
% also need Crossval_error
addpath('/Volumes/TEMPLATE/Projects/SocAnx/scripts/CrossVal_Error/')
%% set up things
% random seed spcification
rand_seed = rng(25);
% load behavioural info of allusable participants
LSAS_table = readtable([datapath 'SocAnx_LSAS_table.csv']);
% random order of participants
id_list_rand_idx = randperm(numel(LSAS_table.ID))';
% which conditions to use for masking and which conditions to apply masks
% to (test)
mask_conds = [1:3, 15:21];
test_conds = [8:10, 22:28];
% load overview of conditions
Cond_table = readtable([datapath 'SocAnx_cond_table.csv']);
% also load insomnia scores
load([datapath 'Insomnia_data']);
% Which baseline to compare to
b = 2;
% number and size of folds
k_folds = 5;
test_fold_n = {1:9,10:18,19:27,28:36,37:numel(id_list_rand_idx)};
%% load cluster results from B1 data
% one subject as a placeholder structure
load([fmri_datapath,LSAS_table.ID{1},'_BfMRIsessiondata.mat'],'st_datamat', 'st_coords');

% load results from b1 for different conditions
for c = 1:size(mask_conds,2)
    load([fmri_datapath 'condition_' num2str(mask_conds(c)),...
        '_behav_lsassr_delta_post_b1_BfMRIresult'], 'result');
    % load mask info based on BSR cutoff
    load([mask_path,...
        'condition_' num2str(mask_conds(c))  '_behav_lsassr_delta_post_b1',...
        '_BSR2_TH20_BfMRIcluster'])
    
    % get indices of positive and negative clusters
    neg_clus_indx{c} = cluster_info.data{1}.idx(cluster_info.data{1}.mask<0);
    pos_clus_indx{c} = cluster_info.data{1}.idx(cluster_info.data{1}.mask>0);
    if size(neg_clus_indx{c},2)>=1
        for ss = 1:size(neg_clus_indx{c},2)
            [~ ,real_neg_clus_indx{c}(ss)] = find(st_coords==neg_clus_indx{c}(ss));
        end
    else
        real_neg_clus_indx{c}=[];
    end
    
    if size(pos_clus_indx{c},2)>=1
        for ss = 1:size(pos_clus_indx{c},2)
            [~ ,real_pos_clus_indx{c}(ss)] = find(st_coords==pos_clus_indx{c}(ss));
        end
    else
        real_pos_clus_indx{c}=[];
    end
end
%% load single subject data and extract values from the clusters specified above
for s = 1:size(LSAS_table.ID,1)
    
    load([fmri_datapath,LSAS_table.ID{s},'_BfMRIsessiondata.mat'],'st_datamat', 'st_coords');
    
    for c = 1:size(mask_conds,2)
        load([fmri_datapath 'condition_' num2str(mask_conds(c)),...
            '_behav_lsassr_delta_post_b1_BfMRIresult'],...
            'result');
        all_voxls{c} = [real_neg_clus_indx{c}, real_pos_clus_indx{c}];
        % no need to load test and training data anymore, just pull out of big
        % array and sum the SDs at the respective cluster positions
        % training goes first
        weightdum = zeros(size(result.u));
        weightdum = result.u(all_voxls{c});
        % apply weights to fMRI data to get BSR
        BSR(s,c) = st_datamat(test_conds(c),all_voxls{c})*weightdum;
        % also extract BSR of B1 data
        BSR1(s,c) = st_datamat(mask_conds(c),all_voxls{c})*weightdum;
    end
end
%% Prediction
% Estimate linear models for each training fold, apply them to testing
% fold, calculate difference between predicted and observed scores.
% get relevant delta LSAS
rel_delta_LSAS = LSAS_table.Delta_LSAS_b2_post;
rel_baseline_LSAS = LSAS_table.Baseline_2_LSAS;
for i = 1:k_folds
    test_fold_idx{i} = sort(id_list_rand_idx(test_fold_n{i}));
    %generate test set ID list for each fold from full id list
    id_test_fold{i} = LSAS_table.ID(test_fold_idx{i});
    %get logical index against test set to get training set
    train_fold = ~ismember(id_list_rand_idx, test_fold_idx{i});
    %get fold-based training set indices and sort
    train_fold_idx{i} = sort(id_list_rand_idx(train_fold));
    %generate training set ID list for each fold from full id list
    id_train_fold{i} = LSAS_table.ID(train_fold_idx{i});
    
    
    for c = 1:size(mask_conds,2)
        %generate intercept and beta coefficients from training data.
        Coefs.Training.brain{i,c}          = regress(rel_delta_LSAS(train_fold_idx{i}),...
            [ones(length(train_fold_idx{i}),1),...
            (BSR(train_fold_idx{i},c)) ]);
        
        %BRAIN-ONLY MODEL
        PredScore.Training.brain{i,c}          = Coefs.Training.brain{i,c}(1) +...
            (Coefs.Training.brain{i,c}(2).* (BSR(train_fold_idx{i},c)'));
        PredScore.Test.brain{i,c}              = Coefs.Training.brain{i,c}(1) +...
            (Coefs.Training.brain{i,c}(2).* (BSR(test_fold_idx{i},c)')) ;
        
        PredDiff.Training.brain{i,c}           = abs(rel_baseline_LSAS(train_fold_idx{i})...
            - PredScore.Training.brain{i,c});
        PredDiff.Test.brain{i,c}               = abs(rel_baseline_LSAS(test_fold_idx{i})...
            - PredScore.Test.brain{i,c});
    end
    
    % same thing for baseline and insomnia models (no need to run multiple times)
    Coefs.Training.intercept{i}      = regress(rel_delta_LSAS(train_fold_idx{i}),...
        ones(length(train_fold_idx{i}),1));
    %generate intercept and beta coefficients from training data.
    Coefs.Training.baseline{i}       = regress(rel_delta_LSAS(train_fold_idx{i}),...
        [ones(length(train_fold_idx{i}),1),...
        rel_baseline_LSAS(train_fold_idx{i})]);
    Coefs.Training.Insom{i}           = regress(rel_delta_LSAS(train_fold_idx{i}),...
        [ones(length(train_fold_idx{i}),1),...
        insom_dat(train_fold_idx{i})]);
    
    % INTERCEPT MODEL
    % generate predicted Tx score in test set from brain score in test data
    % (using model weights from training data)
    PredScore.Training.intercept{i}      = repmat(Coefs.Training.intercept{i}(1),...
        length(train_fold_idx{i}),1);
    PredScore.Test.intercept{i}          = repmat(Coefs.Training.intercept{i}(1),...
        length(test_fold_idx{i}),1);
    % Differnce between predicted and observed delta LSAS scores
    PredDiff.Training.intercept{i}       = abs(rel_delta_LSAS(train_fold_idx{i})...
        - Coefs.Training.intercept{i}(1));
    PredDiff.Test.intercept{i}           = abs(rel_delta_LSAS(test_fold_idx{i})...
        - Coefs.Training.intercept{i}(1));
    %BASELINE LSASSR model
    PredScore.Training.baseline{i}       = Coefs.Training.baseline{i}(1) +...
        (Coefs.Training.baseline{i}(2).*rel_baseline_LSAS(train_fold_idx{i}));
    PredScore.Test.baseline{i}           = Coefs.Training.baseline{i}(1) +...
        (Coefs.Training.baseline{i}(2).*(rel_baseline_LSAS(test_fold_idx{i}))');
    PredDiff.Training.baseline{i}        = abs(rel_delta_LSAS(train_fold_idx{i})...
        - PredScore.Training.baseline{i}); %
    PredDiff.Test.baseline{i}            = abs(rel_delta_LSAS(test_fold_idx{i})...
        - PredScore.Test.baseline{i});
    % INSOMNIA model
    PredScore.Training.Insom{i}           = Coefs.Training.Insom{i}(1) + ...
        (Coefs.Training.Insom{i}(2).* insom_dat(train_fold_idx{i}));
    PredScore.Test.Insom{i}            = Coefs.Training.Insom{i}(1) +...
        (Coefs.Training.Insom{i}(2).*(insom_dat(test_fold_idx{i}))');
    PredDiff.Training.Insom{i}            = abs(rel_delta_LSAS(train_fold_idx{i})...
        - PredScore.Training.Insom{i});
    PredDiff.Test.Insom{i}                = abs(rel_delta_LSAS(test_fold_idx{i})...
        - PredScore.Test.Insom{i});
    PredDiff.Training.Insom{i}            = abs(rel_baseline_LSAS(train_fold_idx{i})...
        - PredScore.Training.Insom{i});
    PredDiff.Test.Insom{i}                = abs(rel_baseline_LSAS(test_fold_idx{i})...
        - PredScore.Test.Insom{i});
    
    
    % Combine baseline LSAS, resting state, and task SD into one model
    Coefs.Training.multmodel{i} = regress(rel_delta_LSAS(train_fold_idx{i}),...
        [ones(length(train_fold_idx{i}),1),...
        rel_baseline_LSAS(train_fold_idx{i}),...
        (BSR(train_fold_idx{i},(find(test_conds ==22)))),...
        (BSR(train_fold_idx{i},(find(test_conds ==25)))) ]);
    
    
    PredScore.Test.multmodel{i}     = Coefs.Training.multmodel{i}(1)...
        + (Coefs.Training.multmodel{i}(2).*(rel_baseline_LSAS(test_fold_idx{i}))')  +...
        (Coefs.Training.multmodel{i}(3).*(BSR(test_fold_idx{i},(find(test_conds ==22)))'))+...
        (Coefs.Training.multmodel{i}(4).*(BSR(test_fold_idx{i},(find(test_conds ==25)))'));
    
    PredDiff.Test.multmodel{i}      = abs(rel_delta_LSAS(test_fold_idx{i})  -...
        PredScore.Test.multmodel{i});
end


%% exactly same thing as above but now for a 1000 permuted version of behaviour
% set up pemuted delta LSAS scores
nperm = 1000;
perm_mat = NaN(length(id_list_rand_idx), nperm);

for p = 1:nperm
    perm_mat(:,p) = randperm(length(id_list_rand_idx));
end
perm_delta_LSAS_b2 = rel_delta_LSAS(perm_mat);
% loop across permutations
for p = 1:nperm
    for i = 1:k_folds
        
        for c = 1:size(mask_conds,2)
            
            %generate intercept and beta coefficients from training data.
            Coefs_perm.Training.brain{p,i,c}          = regress(perm_delta_LSAS_b2(train_fold_idx{i},p),...
                [ones(length(train_fold_idx{i}),1),...
                (BSR(train_fold_idx{i},c)) ]);
            %BRAIN-ONLY MODEL
            Predscore_perm.Training.brain{p,i,c}          = Coefs_perm.Training.brain{p,i,c}(1) +...
                (Coefs_perm.Training.brain{p,i,c}(2).* (BSR(train_fold_idx{i},c)'));
            Predscore_perm.Test.brain{p,i,c}              = Coefs_perm.Training.brain{p,i,c}(1) +...
                (Coefs_perm.Training.brain{p,i,c}(2).* (BSR(test_fold_idx{i},c)')) ;
            
            PredDiff_perm.Training.brain{p,i,c}           = abs(rel_delta_LSAS(train_fold_idx{i}) -...
                Predscore_perm.Training.brain{p,i,c});
            PredDiff_perm.Test.brain{p,i,c}               = abs(rel_delta_LSAS(test_fold_idx{i})  -...
                Predscore_perm.Test.brain{p,i,c});
            
        end
        
        %BASELINE LSASSR model
        Coefs_perm.Training.baseline{p,i}       = regress(perm_delta_LSAS_b2(train_fold_idx{i},p),...
            [ones(length(train_fold_idx{i}),1),...
            rel_baseline_LSAS(train_fold_idx{i})]);
        
        Predscore_perm.Training.baseline{p,i}       = Coefs_perm.Training.baseline{p,i}(1) +...
            (Coefs_perm.Training.baseline{p,i}(2).*...
            rel_baseline_LSAS(train_fold_idx{i}));
        
        Predscore_perm.Test.baseline{p,i}           = Coefs_perm.Training.baseline{p,i}(1) +...
            (Coefs_perm.Training.baseline{p,i}(2).*...
            (rel_baseline_LSAS(test_fold_idx{i}))');
        
        PredDiff_perm.Training.baseline{p,i}        = abs(rel_delta_LSAS(train_fold_idx{i}) -...
            Predscore_perm.Training.baseline{p,i});
        PredDiff_perm.Test.baseline{p,i}            = abs(rel_delta_LSAS(test_fold_idx{i})  -...
            Predscore_perm.Test.baseline{p,i});
        
        % multiple predictor model
        Coefs_perm.Training.multmodel{p,i} = regress(perm_delta_LSAS_b2(train_fold_idx{i},p),...
            [ones(length(train_fold_idx{i}),1),...
            rel_baseline_LSAS(train_fold_idx{i}),...
            (BSR(train_fold_idx{i},(find(test_conds ==22)))),...
            (BSR(train_fold_idx{i},(find(test_conds ==25)))) ]);
        
        
        PredScore_perm.Test.multmodel{p,i}     = Coefs_perm.Training.multmodel{p,i}(1)...
            + (Coefs_perm.Training.multmodel{p,i}(2).*(rel_baseline_LSAS(test_fold_idx{i}))')  +...
            (Coefs_perm.Training.multmodel{p,i}(3).*(BSR(test_fold_idx{i},(find(test_conds ==22)))'))+...
            (Coefs_perm.Training.multmodel{p,i}(4).*(BSR(test_fold_idx{i},(find(test_conds ==25)))'));
        
        PredDiff_perm.Test.multmodel{p,i}      = abs(rel_delta_LSAS(test_fold_idx{i})  -...
            PredScore_perm.Test.multmodel{p,i} );
    end
end
%% Correlate predicted and observed change scores

for c = 1:size(mask_conds,2)
    Pred_delta_lsas.brain(c,:) = (cat(2,PredScore.Test.brain{:,c}))';
    
    [brainr, brainp, lo, up] = corrcoef(rel_delta_LSAS(horzcat(test_fold_idx{:})),...
        (cat(2,PredScore.Test.brain{:,c}))');
    brainpred_corr.r(c)     = brainr(2);
    brainpred_corr.ul(c)    = up(2);
    brainpred_corr.ll(c)    = lo(2);
    
    % get cross validation metrics
    Crossval_stats.brain{c} = CrossVal_Error_LEO(rel_delta_LSAS(vertcat(test_fold_idx{:})),...
        (cat(2,PredScore.Test.brain{:,c}))');
end

Pred_delta_lsas.baseline(:) = (cat(2,PredScore.Test.baseline{:}))';

[bliner, blinep, blinelo, blineup] = corrcoef(rel_delta_LSAS(horzcat(test_fold_idx{:})),...
    (cat(2,PredScore.Test.baseline{:}))');
blinepred_corr.r     = bliner(2);
blinepred_corr.ul    = blineup(2);
blinepred_corr.ll   = blinelo(2);

Crossval_stats.baseline = CrossVal_Error_LEO(rel_delta_LSAS(vertcat(test_fold_idx{:})),...
    (cat(2,PredScore.Test.baseline{:}))');


Pred_delta_lsas.multmodel(:) = (cat(2,PredScore.Test.multmodel{:}))';
[multr, multp, multlo, multup] = corrcoef(rel_delta_LSAS(horzcat(test_fold_idx{:})),...
    (cat(2,PredScore.Test.multmodel{:}))');
multpred_corr.r     = multr(2);
multpred_corr.ul    = multup(2);
multpred_corr.ll   = multlo(2);

Crossval_stats.multmodel = CrossVal_Error_LEO(rel_delta_LSAS(vertcat(test_fold_idx{:})),...
    (cat(2,PredScore.Test.multmodel{:}))');

%% same thing for all permutations
for p = 1:nperm
    for c = 1:size(mask_conds,2)
        Pred_perm_delta_lsas.brain(p,c,:) = (cat(2,Predscore_perm.Test.brain{p,:,c}))';
        
        [brainr, brainp, lo, up] = corrcoef(perm_delta_LSAS_b2(:,p),...
            (cat(2,Predscore_perm.Test.brain{p,:,c}))');
        brainpred_perm_corr.r(p,c)     = brainr(2);
        
    end
    % baseline prediction only has to happen once per permutation
    Pred_perm_delta_lsas.baseline(p,:) = (cat(2,Predscore_perm.Test.baseline{p,:}))';
    [bliner, blinep, blinelo, blineup] = corrcoef(rel_delta_LSAS(horzcat(test_fold_idx{:})),...
        (cat(2,Predscore_perm.Test.baseline{p,:}))');
    blinepred_perm_corr.r(p)     = bliner(2);
    
    Pred_perm_delta_lsas.multmodel(p,:) = (cat(2,PredScore_perm.Test.multmodel{p,:}))';
    [multr, multp, multlo, multup] = corrcoef(rel_delta_LSAS(horzcat(test_fold_idx{:})),...
        (cat(2,PredScore_perm.Test.multmodel{p,:}))');
    multpred_perm_corr.r     = multr(2);
    multpred_perm_corr.ul    = multup(2);
    multpred_perm_corr.ll   = multlo(2);
end
%% extract empirical p-value
for c = 1:size(mask_conds,2)
    brainpred_corr.emp_p(c) = length(find(brainpred_perm_corr.r(:,c)>brainpred_corr.r(c)))/nperm;
end
blinepred_corr.emp_p = length(find(blinepred_perm_corr.r(:)>blinepred_corr.r))/nperm;
multpred_corr.emp_p = length(find(multpred_perm_corr.r(:)>multpred_corr.r))/nperm;
%% plot dots with error bars showing 95% CI
brain_col = [29 153 148]/ 255;
baseline_col = [40 80 118]/ 255;
insom_col = [100 10 80]/ 255;
figure
test_conds = [8:10, 22:28];
scatter(1:size(mask_conds,2)+1,[brainpred_corr.r, multpred_corr.r],...
    [120],brain_col,'filled', 'MarkerFaceAlpha', .5)
hold on
plotdat = [brainpred_corr.ll(:) brainpred_corr.ul(:); ...
        multpred_corr.ll multpred_corr.ul];
for c = 1:size(mask_conds,2)+1
    plot([c c], plotdat(c,:),...
        'Color', [.8 .8 .8], 'LineWidth',1)
end
xlim([0 12])
xticks([1:11])
xxs = xlim; plot(xxs, [0 0], '--K', 'LineWidth', 1)
hold on


xticklabels({'8','9', '10', '22', '23', '24', '25',...
    '26', '27', '28', 'Multiple Predictors'})
xlabel('Condition number')
ylabel('r(predicted, observed)')
title('Prediction based on different predictors (abs(BSR>2))    ..')
ylim([-1 1])



% also plot MASE

figure
for l = 1:size(mask_conds,2)
    p1= scatter(l,Crossval_stats.brain{l}.MASE,...
        [90],brain_col,'filled', 'MarkerFaceAlpha', .5);
    hold on
    
    
end
p2 =scatter(l+1,Crossval_stats.baseline.MASE,...
    [90],baseline_col,'filled', 'MarkerFaceAlpha', .5);
p3 = scatter(l+2,Crossval_stats.multmodel.MASE,...
    [90],baseline_col,'filled', 'MarkerFaceAlpha', .5);
xlim([0 13])
xticks([1:12])
xticklabels({'8','9', '10', '22', '23', '24', '25',...
    '26', '27', '28', 'Baseline', 'Multiple Predictors'})
xlabel('Condition')
ylabel('MASE')
title('Mean absolute scaled error across different predictors')
