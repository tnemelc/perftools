classdef manualMultiRoiMapDisplayRoiAnalyzerToolCtc < roiAnalyzerToolCtc & manualMultiRoiMapDisplayRoiAnalyzerTool
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods (Access = protected)
        function obj = loadRoisMask(obj, ~)
            for k = 1 : length(obj.isKS)
                    isName = obj.isKS{k};
%                     try 
%                         %load both aha and gnd truth mask
%                         ahaMask = loadmat(fullfile(obj.dataPath, 'segmentation', 'AHA_Segments', isName, 'labeledImg.mat'));
%                         gndTrthMask = loadmat(fullfile(obj.dataPath, 'segmentation', 'ManualMultiRoiMapDisplay', ['labelsMask_' isName '.mat']));
%                         %create empty mask
%                         mask = zeros(size(gndTrthMask));
%                         %only keep lesion labels in gndTruth
%                         nbLbls = max(gndTrthMask(:));
%                         for m = 1 : nbLbls
%                             if ~strncmp('lesion', obj.getRoiLabel(isName, m), length('lesion'))
%                                 gndTrthMask(gndTrthMask == m) = 0;
%                             else
%                                 gndTrthMask(gndTrthMask == m) = 1;
%                             end
%                         end
%                         
%                         %only keep aha segment overlaping with gndTruthMask
%                         nbSeg = max(ahaMask(:));
%                         for m = 1 : nbSeg
%                             tmp = ahaMask;
%                             tmp(tmp ~= m) = 0;
%                             tmp(tmp == m) = 1;
%                             if max(max(tmp & gndTrthMask))
%                                 mask = mask + tmp;
%                             end
%                         end
%                         
%                     catch
%                         mask = 0;
%                     end
                    mask = loadmat(fullfile(obj.dataPath, 'segmentation', 'ManualMultiRoiMapDisplay', ['labelsMask_' isName '.mat']));
                    obj.roisMaskMap = mapInsert(obj.roisMaskMap, isName, mask);
                    
                    roiLabels.roi_1 = 'lesion';
                    obj.roiLabelsMap = mapInsert(obj.roiLabelsMap, isName, roiLabels);
            end
        end
    end
end