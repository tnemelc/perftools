% roiAnalyzerUI.m
% brief: 
% roiAnalyzer User Interface
% author: C.Daviller
% date: 02-Oct-2017 


 function  roiAnalyzerUI()
 close all;
    rootPath = 'D:\02_Matlab\Data\deconvTool\segmentation\Manual';
    tissue = 'normal';
    fm = figureMgr.getInstance();
    processedPathesList = roiAnalyzer(rootPath, tissue);
    
    curPatient = [];
    
    for k = 1 : length(processedPathesList)
        
        patientFolder = fileparts(fileparts(fileparts(char(processedPathesList(k)))));
        [~, patient] = fileparts(patientFolder);
        if ~strcmp(patient, curPatient)
            
            curPatient = patient;
            timecurveList = {};
        end
        
        disp(['loading ' fullfile(char(processedPathesList(k)), 'avgCurve.mat')]);
        currentTC = loadmat(fullfile(char(processedPathesList(k)), 'avgCurve.mat'));
        if ~isempty(currentTC)
            [~, slice] = fileparts(char(processedPathesList(k)));
            timecurveList = [timecurveList slice];
            pkImg = loadDcm(fullfile(patientFolder, slice));
            pkImg = pkImg(:,:, 31);
            mask = loadmat(fullfile(patientFolder, 'segmentation', tissue, slice, 'labeledImg001.mat'));
            fm.newFig([curPatient '_' slice]); 
            
            subplot(122); imagesc(overlay(pkImg, mask)); axis off image; title([curPatient '_' slice]);
            subplot(121); imagesc(pkImg); colormap gray; axis off image;
        end
        fm.newFig(curPatient); hold all;
        plot(currentTC); ylim([0 120]);
        try legend(timecurveList); catch; disp(''); end
        title(patient);
    end
    
    fm.saveAll(rootPath, 'pdf');
    
    
end