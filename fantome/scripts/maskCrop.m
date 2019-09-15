% maskCrop.m
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
% date: 20-Apr-2018 


function maskCrop(arg1, arg2)
rootPath = 'D:\02_Matlab\Data\deconvTool\patientData\02_CHUSE\clustering';
PatientList = dir(rootPath);
maskName = 'roisMask.mat';

imSerie = 'mid';

for k = 3 : length(PatientList)
    if strncmp(PatientList(k).name, '0000', 4)
        % folder starting by 0000 are not patients folder
        continue;
    end
    mask = loadmat(fullfile(rootPath, PatientList(k).name, 'featuresDisplay/autoRoiClustering', imSerie , maskName));
    tmp = zeros(size(mask));
    tmp(mask > 0) = 1;
    blobMeasurements = regionprops(tmp, 'BoundingBox');
    bBox = floor(blobMeasurements.BoundingBox);
    %square bBox;
    if bBox(4) > bBox(3)
        bBox(3) = bBox(4);
    else
        bBox(4) = bBox(3);
    end
    opt.sideLength =   bBox(4) + 1;
    
    mask = mask(bBox(2):bBox(2) + bBox(4), bBox(1):bBox(1) + bBox(3));
    
    savemat(fullfile(rootPath, PatientList(k).name, 'featuresDisplay/autoRoiClustering', imSerie , ['croped_' maskName '.mat']), mask);
    
end
cprintf('DGreen', 'maskCrop Completed for %d patients\n', k - 3);
end