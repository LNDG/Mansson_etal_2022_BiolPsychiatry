%   This script creates Heatmaps for the data which is formatted as CSV in 
%   m rows for subjects and n columns for first measurment of variables
%   followed by the second measurement. It can calculate both ICC and
%   pearson correlation to create the heatmap.
%   ICC script should be added to the path.
  
%   Author: Amirhossein Manzouri

clearvars;
close all; 

addpath('/TEMPLATE')

a1= readtable('TEMPLATE.csv');
len = size(a1,2)/2;
% len = 5;
b1 = table2array(a1(:,(1:len)));
b2 = table2array(a1(:,(len+1:end)));
corr_mat = corr(b1,b2);
names1 = a1.Properties.VariableDescriptions(1:len);
% names1 = regexprep(label_names1,'x','');
names1_odd = names1;
names1_odd(2:2:end) = {''};
names1_odd(3:4:end) = {''};

names2 = a1.Properties.VariableDescriptions(len+1:end);
% names2 = regexprep(label_names2,'x','');
names2_odd = names2;
names2_odd(2:2:end) = {''};
names2_odd(3:4:end) = {''};

ICC_mat = {};
for i=1:len
    for j=1:len
        input_dat = [b1(:,i) b2(:,j)];
        ICC_mat{i,j} = ICC(input_dat, 'C-1', 0.05, 0);
  
    end
end
ICC_mat_f = cell2mat(ICC_mat);
 
figure('Name', 'Correlation Heatmap');

set(gcf, 'Position',  [100, 100, 800, 800])

imagesc(corr_mat'); % Display correlation matrix as an image
% imagesc(ICC_mat_f'); % Display correlation matrix as an image

set(gca, 'XTick', 1:len); % center x-axis ticks on bins
set(gca, 'YTick', 1:len); % center y-axis ticks on bins
set(gca, 'XTickLabel', names1_odd); % set x-axis labels
set(gca, 'YTickLabel', names2_odd); % set y-axis labels

title('Correlation Heatmap', 'FontSize', 10); % set title
% title('ICC Heatmap', 'FontSize', 10); % set title

% colormap(redwhiteblue(-1,1)); % Choose jet or any other color scheme
colormap(coolwarm);
colorbar ;
caxis([-1 1]);