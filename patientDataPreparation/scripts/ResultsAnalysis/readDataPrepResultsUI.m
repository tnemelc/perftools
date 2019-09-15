% readDataPrepResultsUI.m
% brief: 
% readDataPrepResults User Interface
% author: C.Daviller
% date: 13-Dec-2017 


 function  readDataPrepResultsUI()

    rootPath = 'D:\02_Matlab\Data\deconvTool\patientData\02_CHUSE\3T';
%     patientKS  = {'Arthaud', 'Boncompain', 'Chassard', 'Coco_jean', 'Delahais', 'Faure', 'Jurine', 'Neyme', 'Outters', 'Rivolier', 'Sarda', 'Thioliere'};
    patientKS = {'0043_ARTH', '0044_BONC',  '0045_CHAS', ...
                                    '0046_COCO', '0047_DELA',  '0048_FAUR',...
                                    '0049_JURI', '0050_NEYM', '0051_OUTT',...
                                    '0052_RIVOL', '0053_SARD', '0054_THIO'};
    
    for k = 1 : length(patientKS)
        clc;
        patientName = char(patientKS(k));
        
        cprintf([0, 0 1], '%s\n', patientName);
        
        slice = 'aif';
        cprintf('green', '%s\n', slice);
        readDataPrepResults(fullfile(rootPath, patientName, 'dataPrep', slice));
        
        slice = 'apex';
        cprintf('green', '%s\n', slice);
        readDataPrepResults(fullfile(rootPath, patientName, 'dataPrep', slice));
        
        slice = 'mid';
        cprintf('green', '%s\n', slice);
        readDataPrepResults(fullfile(rootPath, patientName, 'dataPrep', slice));
        
        slice = 'base';
        cprintf('green', '%s\n', slice);
        readDataPrepResults(fullfile(rootPath, patientName, 'dataPrep', slice));
        fprintf('press any key to continue...\n');
        pause;
    end
    fprintf('completed');
end