% dispOptimResInFeatSpaceUI.m
% brief: 
% dispOptimResInFeatSpace User Interface
% author: C.Daviller
% date: 28-Oct-2017 


 function  dispOptimResInFeatSpaceUI()

    rootpath = 'D:\02_Matlab\Data\deconvTool\patientData\patients\Segmentation\';
    patientSet = {'Arthaud_Gerard-new', 'Chassard_Alain-new',...
        'Delahais_Albert-new', 'Faure_Claude-new', 'Jurine_Michel__new',...
        'Outters', 'Rivolier_Alain-new', 'Thioliere_Roger__Mr_new'};
    patientSet = { 'Arthaud_Gerard-new', 'Chassard_Alain-new',...
        'Delahais_Albert-new', 'Jurine_Michel__new',...
        'Outters', 'Rivolier_Alain-new', 'Thioliere_Roger__Mr_new'};
    % segToolOptimzer('D:\02_Matlab\Data\deconvTool\patientData\patients\ZZ_CHUSE\Genin\');
%      patientSet = {'Arthaud_Gerard-new'};
dimensionsNameKS = {'TTP'; 'ROI surface'; 'AUC'};

    for k = 1: length(patientSet)
        dispOptimResInFeatSpace(fullfile(rootpath, char(patientSet(k)), 'optimization'));
    end
    
    
end