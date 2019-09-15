% selectPeakImageUI.m
% brief: 
% selectPeakImage User Interface
% author: C.Daviller
% date: 03-Jan-2018 


 function  selectPeakImageUI()

    imStack = loadDcm('D:\02_Matlab\Data\deconvTool\patientData\02_CHUSE\Boncompain\apex');
    
    pos = selectPeakImage(imStack);
    fprintf('selected pos: %d\n', uint8(pos));
end