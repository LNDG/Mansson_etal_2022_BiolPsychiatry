function Result=CrossVal_Error_LEO(Reference,Test)
% INPUT 
% Refernce M x N
% Test M x N
% Output
% Result-struct
% 1.MSE (Mean Squared Error)
% 2.PSNR (Peak signal-to-noise ratio)
% 3.R Value
% 4.RMSE (Root-mean-square deviation)
% 5.NRMSE (Normalized Root-mean-square deviation)
% 6.MAPE (Mean Absolute Percentage Error)

% Developer Abbas Manthiri S
% Mail Id abbasmanthiribe@gmail.com
% Updated 27-03-2017
% Matlab 2014a

% adapted by Leo Waschke, summer 2020

%% getting size and condition checking
[row_R,col_R,dim_R]=size(Reference);
[row_T,col_T,dim_T]=size(Test);
if row_R~=row_T || col_R~=col_T || dim_R~=dim_T
    error('Input must have same dimensions')
end
%% Common function for matrix
% Mean for Matrix
meanmat=@(a)(mean(mean(a)));
% Sum for Matrix
summat=@(a)(sum(sum(a)));
% Min  for Matrix
minmat=@(a)(min(min(a)));
% Max  for Matix
maxmat=@(a)(max(max(a)));
%% MSE Mean Squared Error
Result.MSE = meanmat((Reference-Test).^2);
%% PSNR Peak signal-to-noise ratio
range=[1,255];
if max(Reference(:))>1
    maxI=range(2);
else
    maxI=range(1);
end
Result.PSNR= 10* log10(maxI^2/Result.MSE);
%% R Value
Result.Rvalue=1-abs( summat((Test-Reference).^2) / summat(Reference.^2) );
%% RMSE Root-mean-square deviation
Result.RMSE=abs( sqrt( meanmat((Test-Reference).^2) ) );
%% Normalized RMSE Normalized Root-mean-square deviation - Max-min baseline
Result.NRMSE_maxmin=Result.RMSE/(maxmat(Reference)-minmat(Reference));
%% Normalized RMSE Normalized Root-mean-square deviation - std baseline
Result.NRMSE_std=Result.RMSE/std(Reference);
%% MAPE Mean Absolute Percentage Error
Result.Mape=meanmat(abs(Test-Reference)./Reference)*100;
% scale RMSE with range of predictions
Result.scaledRMSE = Result.RMSE/(maxmat(Test)-minmat(Test));
% scale RMSE with difference in range between predicted and actual scores
Result.relscaledRMSE = Result.RMSE*(maxmat(Reference)-minmat(Reference))/(maxmat(Test)-minmat(Test));
% symmetric mean absolute percentage error
% This still is not symmetric regarding over and under forecasting but
% already much better than MAPE itself. Scaled between 0 and 100%
Result.symMape = (100/size(Reference,1))* (summat(abs(Reference-Test)./(abs(Test)+abs(Reference))));
% Mean absolute scaled error.
% Does not penalize high predictions more than low predictions, good boi.
ref_diffmat = Reference(2:end,:)-Reference(1:end-1,:);
Result.MASE = meanmat((abs(Reference-Test))./(1/size(ref_diffmat,1)*(summat(abs(ref_diffmat)))));

