% restoremyoMasks.m
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
% date: 06-Apr-2018 


 function [arg3, arg4] = restoremyoMasks(arg1, arg2)
close all

     rootPath = 'D:\02_Matlab\Data\deconvTool\patientData\02_CHUSE\3T\';
     %patientDataSet = {'Arthaud', 'Boncompain', 'Chassard', 'Coco_jean', 'Delahais', 'Faure', 'Jurine', 'Neyme', 'Outters', 'Rivolier', 'Sarda', 'Thioliere'};
     patientDataSet = {'0043_ARTH', '0044_BONC',  '0045_CHAS', ...
                                    '0046_COCO', '0047_DELA',  '0048_FAUR',...
                                    '0049_JURI', '0050_NEYM', '0051_OUTT',...
                                    '0052_RIVOL', '0053_SARD', '0054_THIO'};
                                
    slcKS = {'base', 'mid','apex'};


    for k = 1 : length(patientDataSet)
            disp(patientDataSet(k))
            curPatient = char(patientDataSet(k));
            for l = 1 : length(slcKS)
                curSlc = char(slcKS(l));
                myoMask = loadmat(fullfile(rootPath, curPatient, 'dataPrep', curSlc, 'mask.mat'));
                roisMask = loadmat(fullfile(rootPath, curPatient, 'segmentation/ManualMultiRoiMapDisplay', ['labelsMask_' curSlc '.mat']));
                roisPos = find(roisMask > 0);
                
                if min(myoMask(roisPos)) == 0
                    myoMask = emphaseNullPos(myoMask, roisPos);
                    cprintf('Red', 'pb with mask of patient %s slice %s\n', curPatient, curSlc);
                    figure; imagesc(myoMask + roisMask);
                    axis off image; title(sprintf('%s %s', curPatient, curSlc));
                    savemat(fullfile(rootPath, curPatient, 'dataPrep', curSlc, 'mask.mat'), myoMask);
                end
            end%for l = 1 : length(slcKS)
    end
    
    
    %% inner functions
     function mask = emphaseNullPos(mask, pos)
         for i = 1 : length(pos)
             if mask(pos(i))  == 0;
                 mask(pos(i)) = 1;
             end
         end
     end
                            
end