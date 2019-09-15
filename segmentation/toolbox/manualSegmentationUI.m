function manualSegmentationUI()

seriePath = 'D:\02_Matlab\Data\deconvTool\patientDataPrep\ARBANE\rest\apex\CtcSet';


serie = loadmat(seriePath);

manualSegmentation(serie, 'apex');


end