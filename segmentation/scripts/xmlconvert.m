% xmlconvert.m
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
% date: 27-Apr-2018


function [arg3, arg4] = xmlconvert(arg1, arg2)
    rootPath = 'D:\02_Matlab\Data\deconvTool\patientData\02_CHUSE\clustering\';
    patientKS = {'0001_ARGE', '1001_BODA',  '0003_CHAL', ...
        '0005_COJE', '0009_DEAL',  '0002_FACL',...
        '0004_JUMI', '0007_OUGW',  '0012_RIAL',...
        '0018_SALI', '0006_THRO'};
    isKS = {'base', 'mid', 'apex'};
    
    for k = 1 : length(patientKS)
        patientName = char(patientKS(k));
        for m = 1 : length(isKS)
            isName = char(isKS(m));
            oldStruct = xml2struct(fullfile(rootPath, patientName, 'segmentation', 'ManualMultiRoiMapDisplay', ['rois_' isName '.xml']));
            newStruct.roisInfo.roi = {};
            for n = 1 : length(oldStruct.rois.roi)
                if iscell(oldStruct.rois.roi)
                oldRoi = oldStruct.rois.roi{n};
                else
                    oldRoi = oldStruct.rois.roi;
                end
                roi.id = oldRoi.id;
                roi.name = oldRoi.name;
                roi.surface = oldRoi.surface;
                roi.seed.x = -1;
                roi.seed.y = -1;
                roi.thresh = -1;
                newStruct.roisInfo.roi = [newStruct.roisInfo.roi roi];
                roi = [];
            end
            struct2xml(newStruct, fullfile(rootPath, patientName, 'segmentation', 'ManualMultiRoiMapDisplay', ['roiInfo_' isName '.xml']));
            newStruct = [];
        end
    end

end