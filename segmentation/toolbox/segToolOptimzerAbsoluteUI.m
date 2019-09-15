% segToolOptimzerUI.m
% brief:
% segToolOptimzer User Interface
% author: C.Daviller
% date: 06-Oct-2017


function  segToolOptimzerAbsoluteUI()

    rootpath = 'D:\02_Matlab\Data\deconvTool\patientData\patients\Segmentation';
    rootpath = 'D:\02_Matlab\Data\deconvTool\patientData\02_CHUSE';
    patientSet = {'Arthaud_Gerard-new', 'Chassard_Alain-new',...
        'Delahais_Albert-new', 'Faure_Claude-new', 'Jurine_Michel__new',...
        'Outters', 'Rivolier_Alain-new', 'Thioliere_Roger__Mr_new'};
    patientSet = { 'Arthaud_Gerard-new', 'Chassard_Alain-new',...
        'Delahais_Albert-new', 'Jurine_Michel__new',...
        'Outters', 'Rivolier_Alain-new', 'Thioliere_Roger__Mr_new'};
    % segToolOptimzer('D:\02_Matlab\Data\deconvTool\patientData\patients\ZZ_CHUSE\Genin\');
    patientSet = {'Boncompain', 'Defihles', 'Genin'};
    patientSet = {'0001_ARGE'};
    for k = 1: length(patientSet)
        close all;
        fprintf('running patient %s\n', char(patientSet(k)));
        [features, firstRoiMask] = segToolOptimzerAbsolute(fullfile(rootpath, char(patientSet(k))));
        if isdir(fullfile(rootpath, char(patientSet(k)), 'optimization'))
            rmdir(fullfile(rootpath, char(patientSet(k)), 'optimization'), 's');
        end
        mkdir(fullfile(rootpath, char(patientSet(k)), 'optimization'));
        figureMgr.getInstance().saveAll(fullfile(rootpath, char(patientSet(k)), 'optimization'));
        savemat(fullfile(rootpath, char(patientSet(k)), 'optimization', 'FirstROISurface'), features.FirstROISurface);
        savemat(fullfile(rootpath, char(patientSet(k)), 'optimization', 'AUC'), features.AUC);
        savemat(fullfile(rootpath, char(patientSet(k)), 'optimization', 'ttp'), features.ttp);
        savemat(fullfile(rootpath, char(patientSet(k)), 'optimization', 'maxSlope'), features.maxSlope);
        savemat(fullfile(rootpath, char(patientSet(k)), 'optimization', 'maxSlopePos'), features.maxSlopePos);
        savemat(fullfile(rootpath, char(patientSet(k)), 'optimization', 'nbROI'), features.nbROI);
        savemat(fullfile(rootpath, char(patientSet(k)), 'optimization', 'peakVal'), features.peakValue);
        
        savemat(fullfile(rootpath, char(patientSet(k)), 'optimization', 'firstRoiMask_apex'), firstRoiMask(:,:,3));
        savemat(fullfile(rootpath, char(patientSet(k)), 'optimization', 'firstRoiMask_mid'), firstRoiMask(:,:,2));
        savemat(fullfile(rootpath, char(patientSet(k)), 'optimization', 'firstRoiMask_base'), firstRoiMask(:,:,1));
    end

end