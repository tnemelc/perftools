% deconvPatientList.m
% brief: process deconvolution automatically on patients
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
% date: 05-Apr-2018 


function deconvPatientList()
     rootPath = 'D:\02_Matlab\Data\deconvTool\patientData\02_CHUSE\3T\';
     patientDataSet = {'0001_ARGE', '1001_BODA', '0003_CHAL', ...
         '0005_COCO', '0009_DEAL',  '0002_FACL',...
         '0004_JUMI', '1002_NEMO', '0007_OUGW',...
         '0012_RIAL', '0018_SALI', '0006_THRO'};
     %patientDataSet = {'0001_ARGE', '1001_BODA'};
     methodKS = {'Bayesian', 'Fermi'};
     
     for k = 1 : length(patientDataSet)
         curPatient =  char(patientDataSet(k));
         patientPath = fullfile(rootPath, curPatient);
         
         options.timePortion = 1;
         options.deconvMode = 'patient';
         options.patchWidth = 1;
         options.processMeasUncertainty = false;
         options.aifDataPath = fullfile(patientPath, 'dataPrep', 'Aif'); 
         options.dataPath = patientPath;
         %
         slcKS = {'base', 'mid', 'apex'};
         
         for l = 1 : length(methodKS)
             curMethod = char(methodKS(l));
             root = [];
             decTool = [];
             root.patientName = curPatient;
             root.aifPath = options.aifDataPath;
             switch curMethod
                 case 'Bayesian'
                     decTool = deconvToolBayesian();
                 case 'Fermi'
                     decTool = deconvToolFermi();
             end
             for m = 1 : length(slcKS)
                 curSlc = char(slcKS(m));
                 %run deconvolution
                 options.slicePath = fullfile(patientPath, 'dataPrep', curSlc);
                 decTool.prepare(options);
                 decTool.runDeconvolution();
                 decTool.runRoiDeconvolution();
                 
                 %save results
                 savePath = fullfile(patientPath, 'autoDeconvolution', curMethod, curSlc);
                 if ~isdir(savePath)
                     mkdir(savePath);
                 end
                 
                 savemat(fullfile(savePath, 'mbfMap'), decTool.getMbfMap('pixels', [], 'ml/min/g'));
                 savemat(fullfile(savePath, 'mbvMap'), decTool.getMbvMap());
                 savemat(fullfile(savePath, 'delayMap'), decTool.getDelayMap());
                 savemat(fullfile(savePath, 'mbfUncertaintyMap'), decTool.getMbfUncertaintyMap('ml/min/g'));
                 savemat(fullfile(savePath, 'ctcSet'), decTool.getCtcSet());
                 savemat(fullfile(savePath, 'fitCtcSet'), decTool.getFitCtcSet());
                 savemat(fullfile(savePath, 'ttpMap'), decTool.getTimeToPeakMap());
                 savemat(fullfile(savePath, 'mbfRoiMapSet'), decTool.getMbfRoiMapSet());
                 savemat(fullfile(savePath, 'mbvRoiMapSet'), decTool.getMbvRoiMapSet());
                 savemat(fullfile(savePath, 'fitRoiCtcSet'), decTool.getFitRoiCtcSet());
                 savemat(fullfile(savePath, 'roiCtcSet'), decTool.getRoiCtcSet());
                 savemat(fullfile(savePath, 'roiMaskSet'), decTool.getRoiMaskSet());
                 
                 
                 [x, y] = decTool.getRoiRepresentativePosSet();
                mbfMap = decTool.getMbfMap('pixels', [], 'ml/min/g');
                
                if options.processMeasUncertainty 
                    for n = 1 : decTool.getNbRoi()
                        root.slc.(curSlc).bfRoiUncertainty.(sprintf('roi%02d', n)).roiAvgCtc = 60 * decTool.getRoiMbfByIdx(n);
                        roiMBFUnscertaintyStruct = decTool.getRoiMbfUncertainty(n);
                        root.slc.(curSlc).bfRoiUncertainty.(sprintf('roi%02d', n)).roiRepresentativeCtc = mbfMap(x(n), y(n));
                        root.slc.(curSlc).bfRoiUncertainty.(sprintf('roi%02d', n)).wildBootstrap.mean = 60 * roiMBFUnscertaintyStruct.avg;
                        root.slc.(curSlc).bfRoiUncertainty.(sprintf('roi%02d', n)).wildBootstrap.std = 60 * roiMBFUnscertaintyStruct.std;
                        root.slc.(curSlc).bfRoiUncertainty.(sprintf('roi%02d', n)).wildBootstrap.min = 60 * roiMBFUnscertaintyStruct.minVal;
                        root.slc.(curSlc).bfRoiUncertainty.(sprintf('roi%02d', n)).wildBootstrap.max = 60 * roiMBFUnscertaintyStruct.maxVal;
                        
                    end
                end
                % slice wise processing summary
                root.slc.(curSlc).timeProcessing = decTool.getProcessingTime();
                root.bootstrap.nbIterations = decTool.getNbBsIterations();
             end%for m = 1 : length(slcKS)
             struct2xml(struct('summary', root), fullfile(patientPath, 'autoDeconvolution', curMethod, 'summary.xml'));
         end%for l = 1 : length(methodKS)
         
     end%for k = 1 : length(patientDataSet)
     

end