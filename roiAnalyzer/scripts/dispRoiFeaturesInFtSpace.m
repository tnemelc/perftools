% dispRoiFeaturesInFtSpace.m
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
% date: 07-Jun-2018 


 function [arg3, arg4] = dispRoiFeaturesInFtSpace(arg1, arg2)
 close all
    rootPath = 'D:\02_Matlab\Data\deconvTool\patientData\02_CHUSE\clustering';
    
    patientSet = {'0001_ARGE', '0002_FACL', '0005_COJE','0007_OUGW',...
        '0009_DEAL', '0010_LEOD', '0021_CUCH',...
        '0022_HODO', '0026_SARE', ...
        '0029_HURO', '0030_MARE', '0039_MOBE', '0040_SEJO',...
        '0048_BUJA', '0050_BRFR', '1001_BODA', '1002_NEMO'
        };
    isKS = {'base', 'mid', 'apex'};

    try
    for k = 1 : length(patientSet)
        disp(patientSet{k})
        manuRoiInfoStruct = xml2struct(fullfile(rootPath, patientSet{k}, 'roiAnalyzer', 'segmentation', 'ManualMultiRoiMapDisplay', 'summary.xml'));
        autoRoiInfoStruct = xml2struct(fullfile(rootPath, patientSet{k}, 'roiAnalyzer', 'ticFeatures', 'dynamic_threshold_roi_growing', 'summary.xml'));
        
        for m = 1 : length(isKS)
            %collect normal roi features
            for n = 1 : length(manuRoiInfoStruct.root.(isKS{m}).roi)
                if iscell(manuRoiInfoStruct.root.(isKS{m}).roi)
                    curRoi = manuRoiInfoStruct.root.(isKS{m}).roi{n};
                else
                    curRoi = manuRoiInfoStruct.root.(isKS{m}).roi;
                end
                if strcmp('normal', curRoi.label.Text)
                    normalFtVectStruct.(isKS{m}).auc(k) = str2double(curRoi.auc.Text);
                    normalFtVectStruct.(isKS{m}).maxSlope(k) = str2double(curRoi.maxSlope.Text);
                    normalFtVectStruct.(isKS{m}).ttp(k) = str2double(curRoi.ttp.Text);
                    break;
                end
            end%for n
            
            %collect lesion features found by strg
            lesionFtVectStruct.(isKS{m}).auc(k) = str2double(autoRoiInfoStruct.root.(isKS{m}).roi.auc.Text);
            lesionFtVectStruct.(isKS{m}).maxSlope(k) = str2double(autoRoiInfoStruct.root.(isKS{m}).roi.maxSlope.Text);
            lesionFtVectStruct.(isKS{m}).ttp(k) = str2double(autoRoiInfoStruct.root.(isKS{m}).roi.ttp.Text);
        end%m = 1 : length(isKS)
    end
    
    for m = 1 : length(isKS)
        %display features space
        figureMgr.getInstance().newFig(['ftSpace ' isKS{m}]);
        %display features in a 3D space
        plot3(lesionFtVectStruct.(isKS{m}).auc, lesionFtVectStruct.(isKS{m}).ttp, lesionFtVectStruct.(isKS{m}).maxSlope, 'color', [.6, 0, 0] , 'linestyle', '*');
        hold on;
        plot3(normalFtVectStruct.(isKS{m}).auc, normalFtVectStruct.(isKS{m}).ttp, normalFtVectStruct.(isKS{m}).maxSlope, 'color', [0, .6, 0] , 'linestyle', '*');
        xlabel('auc')
        ylabel('ttp')
        zlabel('maxSlope')
        grid
    end
    
    catch e
        disp(patientSet{k}); disp(isKS{m});
        rethrow(e);
    end
 end