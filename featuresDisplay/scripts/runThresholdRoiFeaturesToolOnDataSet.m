% runThresholdRoiFeaturesToolOnDataSet.m
% brief: 
%
%
% references:
%
%
% input:
% arg1: ...
% arg2: ... 
% output:
%
% arg3: ...
% arg4: ...
%
%
% keywords:
% author: C.Daviller
% date: 27-Mar-2018 


 function [arg3, arg4] = runThresholdRoiFeaturesToolOnDataSet(arg1, arg2)

%  rootPath = 'D:\02_Matlab\Data\deconvTool\patientData\02_CHUSE\1.5T';
 rootPath = 'D:\02_Matlab\Data\deconvTool\patientData\02_CHUSE\clustering';
 
 PatientList = dir(rootPath); 
 dimKS = {'AUC', 'maxSlope', 'TTP'}; 
 tic
 for k = 3 : length(PatientList)
     if strncmp(PatientList(k).name, '0000', 4)
         % folder starting by 0000 are not patients folder
         continue;
     end
     %following line does not work well.
     % use
     % D:\02_Matlab\Data\deconvTool\patientData\02_CHUSE\clustering\0000_Scripts\emptyThresholdRoiFeaturesToolFolders.sh
     % instead
     %emptyDir(fullfile(rootPath, PatientList(k).name, 'featuresDisplay', 'thresholdRoiFeaturesTool'));
     
     featTool = thresholdRoiFeaturesTool();
     opt.dataPath = fullfile(rootPath, PatientList(k).name);
     opt.dimKS = dimKS;
     featTool = featTool.prepare(opt);
     featTool = featTool.run();
     %save results data
     savePath = fullfile(rootPath, PatientList(k).name, 'featuresDisplay', 'autoRoiClustering');
     isKS = featTool.getSliceKS();
     for m = 1 : length(isKS)
         isName = char(isKS(m));
         emptyDir(fullfile(savePath, isName));
         savemat (fullfile(savePath, isName, 'roisMask.mat'), featTool.getRoisMask(isName));
     end
 end
 elapsedtime = toc;
 fprintf('done in %dsec\n', round(elapsedtime));
 
end