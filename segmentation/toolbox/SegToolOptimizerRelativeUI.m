% SegToolOptimizerRelativeUI.m
% brief: 
% SegToolOptimizerRelative User Interface
% author: C.Daviller
% date: 23-Oct-2017 



function  SegToolOptimizerRelativeUI()

    rootpath = 'D:\02_Matlab\Data\deconvTool\patientData\patients\SegmentationRelative';
    patientSet = {'Arthaud_Gerard-new', 'Chassard_Alain-new',...
        'Delahais_Albert-new', 'Faure_Claude-new', 'Jurine_Michel__new',...
        'Outters', 'Rivolier_Alain-new', 'Thioliere_Roger__Mr_new'};
    patientSet = { 'Arthaud_Gerard-new', 'Chassard_Alain-new',...
        'Delahais_Albert-new', 'Jurine_Michel__new',...
        'Outters', 'Rivolier_Alain-new', 'Thioliere_Roger__Mr_new'};
    % segToolOptimzer('D:\02_Matlab\Data\deconvTool\patientData\patients\ZZ_CHUSE\Genin\');
    patientSet = {'Arthaud_Gerard-new'};

    for k = 1: length(patientSet)
%         close all;
        fprintf('running patient %s\n', char(patientSet(k)));
        SegToolOptimizerRelative(fullfile(rootpath, char(patientSet(k))));
        if isdir(fullfile(rootpath, char(patientSet(k)), 'optimization'))
            rmdir(fullfile(rootpath, char(patientSet(k)), 'optimization'), 's');
        end
        mkdir(fullfile(rootpath, char(patientSet(k)), 'optimization'));
        figureMgr.getInstance().saveAll(fullfile(rootpath, char(patientSet(k)), 'optimization'));
%         pause;
    end

end