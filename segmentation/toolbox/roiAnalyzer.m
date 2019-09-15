% roiAnalyzer.m
% brief: this function anaylizes ROIs established for each patients in a
% folders. It calculates means curves and upper bounds for
%       * each patient
%       * each slice
%       * the whole set of patients
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
% date: 02-Oct-2017  


 function processedPathesList = roiAnalyzer(rootPath, tissueType)
 if ~nargin
	roiAnalyzerUI();
 return;
 end 

 patientList = dir(rootPath);
 processedPathesList = {};
 for k = 3 : size(patientList, 1)
     curPatienDir = fullfile(rootPath, patientList(k).name);
     curSegPatienDir = fullfile(rootPath, patientList(k).name, 'segmentation', tissueType);
     sliceList = dir(curPatienDir);
     for l = 3 : (size(sliceList, 1) - 1) %nuber of slices folder minus fs folders (./ & ../) minus segmentation folder
         dataSetDir = fullfile(curPatienDir, sliceList(l).name);
         try 
         labeledImg = loadmat(fullfile(curSegPatienDir, sliceList(l).name, 'labeledImg001.mat'));
         curDataSet = loadDcm(dataSetDir);
         
         [avgCurve, upBound, lwBound] = processRoiMeanCurve(curDataSet, labeledImg);
         savemat(fullfile(curSegPatienDir, sliceList(l).name, 'avgCurve.mat'), avgCurve);
         savemat(fullfile(curSegPatienDir, sliceList(l).name, 'upBound.mat'), upBound);
         savemat(fullfile(curSegPatienDir, sliceList(l).name, 'lwBound.mat'), lwBound);
         %only added 
         processedPathesList = [processedPathesList fullfile(curSegPatienDir, sliceList(l).name)];
         catch e
             disp(['could not load patient data ' curPatienDir]);
             disp(['reason:' e.message]);
             disp('folder will be ignored');
         end
     end
     
     
 end
 
%   = 

 
     function [avgCurve, upBound, lwBound] = processRoiMeanCurve(dataset, mask)
         if ~max(mask(:))
             disp('roiAnalyzer:processRoiMeanCurve : mask is empty');
             avgCurve = []; upBound = []; lwBound = [];
             return;
         end
         
         [H, W, T] = size(dataset);
         avgCurve = zeros(1, T);
         [x, y] = ind2sub([H, W], find(mask == 1));
         curvesTab = zeros(length(x), T); 
         tmp = zeros(H, W);
         for k = 1 : length(x)
             curvesTab(k, :) = squeeze(dataset(x(k), y(k), :));
             tmp(x(k), y(k)) = 1;
         end
         
         avgCurve = mean(curvesTab, 1);
         upBound = max(curvesTab);
         lwBound = min(curvesTab);
     end
 
 end