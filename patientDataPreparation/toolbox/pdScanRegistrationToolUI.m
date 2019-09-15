% pdScanRegistrationToolUI.m
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
% date: 31-Jan-2018 


function pdScanRegistrationToolUI()
     clear all;
    close all;
    opt.pdScanImg = loadDcm('D:\02_Matlab\Data\deconvTool\patientData\test\jurine\apex');
    opt.pdScanImg = opt.pdScanImg(:, :, 1);
    opt.mask = loadmat('D:\02_Matlab\Data\deconvTool\patientData\test\jurine\dataPrep\apex\mask.mat');
    
    tool = pdScanRegistrationTool();
    tool = tool.prepare(opt);
    tool = tool.run();
    img = tool.getCorrPdScanImg();
    figure; imagesc(img);
    disp('done');
end