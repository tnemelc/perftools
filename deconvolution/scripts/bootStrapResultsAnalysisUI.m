% bootStrapResultsAnalysisUI.m
% brief: 
% bootStrapResultsAnalysis User Interface
% author: C.Daviller
% date: 25-Feb-2018 


 function  bootStrapResultsAnalysisUI()
close all;

 rootPath = 'D:\02_Matlab\Data\deconvTool\patientData\02_CHUSE\3T\';
 %patientDataSet = {'Arthaud', 'Boncompain', 'Chassard', 'Coco_jean', 'Delahais', 'Faure', 'Jurine', 'Neyme', 'Outters', 'Rivolier', 'Sarda', 'Thioliere'};
 patientDataSet = {'0043_ARTH', '0044_BONC',  '0045_CHAS', ...
                                '0046_COCO', '0047_DELA',  '0048_FAUR',...
                                '0049_JURI', '0050_NEYM', '0051_OUTT',...
                                '0052_RIVOL', '0053_SARD', '0054_THIO'};
 %% missing regions
 % Arthaud      - base          - normal            1
 % Chassard     - base          - lesion            2
 % Chassard     - apex          - lesion+normal     3
 % Jurine       - base/mid/apex - lesion            6
 % Neyme        - base/mid/apex - normal            9
 % Outters      - base          - lesion            10
 % Rivolier     - base          - lesion	        12
 % Sarda        - apex          - lesion            13
 % Thiollière   - base/mid      - lesion            15

%                %Arthaud  Chassard                   Jurine                         Neyme                        Outters    Rivollier           Sarda     Thioliere
%                %base     base      apex             base       mid       apex      base      mid       apex      base      base      mid       apex      base      mid 
 missingRoiKS = {'normal', 'lesion', 'lesion+normal', 'lesion', 'lesion', 'lesion', 'lesion', 'lesion', 'lesion', 'lesion', 'lesion', 'lesion', 'lesion', 'lesion', 'lesion'};
 
 missingRoiCpt = 1;
 
 
 %% 
 for k = 1 : length(patientDataSet)
     disp(patientDataSet(k))
     resBay = xml2struct(fullfile(rootPath, char(patientDataSet(k)), 'autoDeconvolution', 'Bayesian', 'summary.xml'));
     resFermi = xml2struct(fullfile(rootPath, char(patientDataSet(k)), 'autoDeconvolution', 'Fermi', 'summary.xml'));
      
     %% check
     slcSet = {'base', 'mid','apex'};
     for l = 1 : length(slcSet)
         if ~isfield(resBay.summary.slc.(char(slcSet(l))).bfRoiUncertainty, 'roi03')
             %choice = questdlg(sprintf('%s:%s: a roi is missing. is it:', char(patientDataSet(k)), char(slcSet(l))), '', 'lesion', 'normal', 'lesion+normal', 'lesion');
             choice = char(missingRoiKS(missingRoiCpt)); missingRoiCpt = missingRoiCpt + 1;
             switch choice
                 case 'lesion'
                     resBay.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi03 = resBay.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi02;
                     resFermi.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi03 = resFermi.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi02;
                     
                     resBay.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi02.roiAvgCtc.Text = 'nan';
                     resBay.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi02.roiRepresentativeCtc.Text = 'nan';
                     resBay.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi02.wildBootstrap.mean.Text = 'nan';
                     resBay.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi02.wildBootstrap.std.Text = 'nan';
                     resBay.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi02.wildBootstrap.min.Text = 'nan';
                     resBay.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi02.wildBootstrap.max.Text = 'nan';
                     
                     resFermi.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi02.roiAvgCtc.Text = 'nan';
                     resFermi.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi02.roiRepresentativeCtc.Text = 'nan';
                     resFermi.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi02.roiAvgCtc.Text = 'nan';
                     resFermi.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi02.wildBootstrap.mean.Text = 'nan';
                     resFermi.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi02.wildBootstrap.std.Text = 'nan';
                     resFermi.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi02.wildBootstrap.min.Text = 'nan';
                     resFermi.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi02.wildBootstrap.max.Text = 'nan';
                     
                 case 'normal'
                     resBay.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi03.roiAvgCtc.Text = 'nan';
                     resBay.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi03.roiRepresentativeCtc.Text = 'nan';
                     resBay.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi03.wildBootstrap.mean.Text = 'nan';
                     resBay.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi03.wildBootstrap.std.Text = 'nan';
                     resBay.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi03.wildBootstrap.min.Text = 'nan';
                     resBay.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi03.wildBootstrap.max.Text = 'nan';
                     
                     resFermi.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi03.roiAvgCtc.Text = 'nan';
                     resFermi.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi03.roiRepresentativeCtc.Text = 'nan';
                     resFermi.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi03.wildBootstrap.mean.Text = 'nan';
                     resFermi.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi03.wildBootstrap.std.Text = 'nan';
                     resFermi.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi03.wildBootstrap.min.Text = 'nan';
                     resFermi.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi03.wildBootstrap.max.Text = 'nan';
                     
                 case 'lesion+normal'
                     %roi2
                     resBay.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi02.roiAvgCtc.Text = 'nan';
                     resBay.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi02.roiRepresentativeCtc.Text = 'nan';
                     resBay.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi02.wildBootstrap.mean.Text = 'nan';
                     resBay.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi02.wildBootstrap.std.Text = 'nan';
                     resBay.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi02.wildBootstrap.min.Text = 'nan';
                     resBay.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi02.wildBootstrap.max.Text = 'nan';
                     
                     resFermi.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi02.roiAvgCtc.Text = 'nan';
                     resFermi.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi02.roiRepresentativeCtc.Text = 'nan';
                     resFermi.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi02.wildBootstrap.mean.Text = 'nan';
                     resFermi.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi02.wildBootstrap.std.Text = 'nan';
                     resFermi.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi02.wildBootstrap.min.Text = 'nan';
                     resFermi.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi02.wildBootstrap.max.Text = 'nan';
                     
                     %roi3
                     resBay.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi03.roiAvgCtc.Text = 'nan';
                     resBay.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi03.roiRepresentativeCtc.Text = 'nan';
                     resBay.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi03.wildBootstrap.mean.Text = 'nan';
                     resBay.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi03.wildBootstrap.std.Text = 'nan';
                     resBay.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi03.wildBootstrap.min.Text = 'nan';
                     resBay.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi03.wildBootstrap.max.Text = 'nan';
                     
                     resFermi.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi03.roiAvgCtc.Text = 'nan';
                     resFermi.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi03.roiRepresentativeCtc.Text = 'nan';
                     resFermi.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi03.wildBootstrap.mean.Text = 'nan';
                     resFermi.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi03.wildBootstrap.std.Text = 'nan';
                     resFermi.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi03.wildBootstrap.min.Text = 'nan';
                     resFermi.summary.slc.(char(slcSet(l))).bfRoiUncertainty.roi03.wildBootstrap.max.Text = 'nan';
             end
         end
     end
    
         
     %% roi 1
     % bayesian
     bayRoi1.base.avg(k) = str2double(resBay.summary.slc.base.bfRoiUncertainty.roi01.wildBootstrap.mean.Text);
     bayRoi1.base.std(k) = str2double(resBay.summary.slc.base.bfRoiUncertainty.roi01.wildBootstrap.std.Text);
     
     bayRoi1.mid.roiAvg(k) = str2double(resBay.summary.slc.mid.bfRoiUncertainty.roi01.roiAvgCtc.Text);
     bayRoi1.mid.roiRepresentativeCtc(k) = str2double(resBay.summary.slc.mid.bfRoiUncertainty.roi01.roiRepresentativeCtc.Text);
     bayRoi1.mid.avg(k) = str2double(resBay.summary.slc.mid.bfRoiUncertainty.roi01.wildBootstrap.mean.Text);
     bayRoi1.mid.std(k) = str2double(resBay.summary.slc.mid.bfRoiUncertainty.roi01.wildBootstrap.std.Text);
     bayRoi1.mid.min(k) = str2double(resBay.summary.slc.mid.bfRoiUncertainty.roi01.wildBootstrap.min.Text);
     bayRoi1.mid.max(k) = str2double(resBay.summary.slc.mid.bfRoiUncertainty.roi01.wildBootstrap.max.Text);
     
     bayRoi1.apex.avg(k) = str2double(resBay.summary.slc.apex.bfRoiUncertainty.roi01.wildBootstrap.mean.Text);
     bayRoi1.apex.std(k) = str2double(resBay.summary.slc.apex.bfRoiUncertainty.roi01.wildBootstrap.std.Text);
     
     % Fermi
     fermiRoi1.base.avg(k) = str2double(resFermi.summary.slc.base.bfRoiUncertainty.roi01.wildBootstrap.mean.Text);
     fermiRoi1.base.std(k) = str2double(resFermi.summary.slc.base.bfRoiUncertainty.roi01.wildBootstrap.std.Text);
     
     fermiRoi1.mid.roiAvg(k) = str2double(resFermi.summary.slc.mid.bfRoiUncertainty.roi01.roiAvgCtc.Text);
     fermiRoi1.mid.roiRepresentativeCtc(k) = str2double(resFermi.summary.slc.mid.bfRoiUncertainty.roi01.roiRepresentativeCtc.Text);
     fermiRoi1.mid.avg(k) = str2double(resFermi.summary.slc.mid.bfRoiUncertainty.roi01.wildBootstrap.mean.Text);
     fermiRoi1.mid.std(k) = str2double(resFermi.summary.slc.mid.bfRoiUncertainty.roi01.wildBootstrap.std.Text);
     fermiRoi1.mid.min(k) = str2double(resFermi.summary.slc.mid.bfRoiUncertainty.roi01.wildBootstrap.mean.Text);
     fermiRoi1.mid.max(k) = str2double(resFermi.summary.slc.mid.bfRoiUncertainty.roi01.wildBootstrap.std.Text);
     
     
     fermiRoi1.apex.avg(k) = str2double(resFermi.summary.slc.apex.bfRoiUncertainty.roi01.wildBootstrap.mean.Text);
     fermiRoi1.apex.std(k) = str2double(resFermi.summary.slc.apex.bfRoiUncertainty.roi01.wildBootstrap.std.Text);
     
     
     %% roi 2
     % bayesian
     bayRoi2.base.avg(k) = str2double(resBay.summary.slc.base.bfRoiUncertainty.roi02.wildBootstrap.mean.Text);
     bayRoi2.base.std(k) = str2double(resBay.summary.slc.base.bfRoiUncertainty.roi02.wildBootstrap.std.Text);
     
     bayRoi2.mid.roiAvg(k) = str2double(resBay.summary.slc.mid.bfRoiUncertainty.roi02.roiAvgCtc.Text);
     bayRoi2.mid.roiRepresentativeCtc(k) = str2double(resBay.summary.slc.mid.bfRoiUncertainty.roi02.roiRepresentativeCtc.Text);
     bayRoi2.mid.avg(k) = str2double(resBay.summary.slc.mid.bfRoiUncertainty.roi02.wildBootstrap.mean.Text);
     bayRoi2.mid.std(k) = str2double(resBay.summary.slc.mid.bfRoiUncertainty.roi02.wildBootstrap.std.Text);
     bayRoi2.mid.min(k) = str2double(resBay.summary.slc.mid.bfRoiUncertainty.roi02.wildBootstrap.min.Text);
     bayRoi2.mid.max(k) = str2double(resBay.summary.slc.mid.bfRoiUncertainty.roi02.wildBootstrap.max.Text);
     
     bayRoi2.apex.avg(k) = str2double(resBay.summary.slc.apex.bfRoiUncertainty.roi02.wildBootstrap.mean.Text);
     bayRoi2.apex.std(k) = str2double(resBay.summary.slc.apex.bfRoiUncertainty.roi02.wildBootstrap.std.Text);
     
     % Fermi
     fermiRoi2.base.avg(k) = str2double(resFermi.summary.slc.base.bfRoiUncertainty.roi02.wildBootstrap.mean.Text);
     fermiRoi2.base.std(k) = str2double(resFermi.summary.slc.base.bfRoiUncertainty.roi02.wildBootstrap.std.Text);
     
     fermiRoi2.mid.roiAvg(k) = str2double(resFermi.summary.slc.mid.bfRoiUncertainty.roi02.roiAvgCtc.Text);
     fermiRoi2.mid.roiRepresentativeCtc(k) = str2double(resFermi.summary.slc.mid.bfRoiUncertainty.roi02.roiRepresentativeCtc.Text);
     fermiRoi2.mid.avg(k) = str2double(resFermi.summary.slc.mid.bfRoiUncertainty.roi02.wildBootstrap.mean.Text);
     fermiRoi2.mid.std(k) = str2double(resFermi.summary.slc.mid.bfRoiUncertainty.roi02.wildBootstrap.std.Text);
     fermiRoi2.mid.min(k) = str2double(resFermi.summary.slc.mid.bfRoiUncertainty.roi02.wildBootstrap.min.Text);
     fermiRoi2.mid.max(k) = str2double(resFermi.summary.slc.mid.bfRoiUncertainty.roi02.wildBootstrap.max.Text);
     
     
     fermiRoi2.apex.avg(k) = str2double(resFermi.summary.slc.apex.bfRoiUncertainty.roi02.wildBootstrap.mean.Text);
     fermiRoi2.apex.std(k) = str2double(resFermi.summary.slc.apex.bfRoiUncertainty.roi02.wildBootstrap.std.Text);
     
     
     %% roi 3
     % bayesian
     bayRoi3.base.avg(k) = str2double(resBay.summary.slc.base.bfRoiUncertainty.roi03.wildBootstrap.mean.Text);
     bayRoi3.base.std(k) = str2double(resBay.summary.slc.base.bfRoiUncertainty.roi03.wildBootstrap.std.Text);
     
     bayRoi3.mid.roiAvg(k) = str2double(resBay.summary.slc.mid.bfRoiUncertainty.roi03.roiAvgCtc.Text);
     bayRoi3.mid.roiRepresentativeCtc(k) = str2double(resBay.summary.slc.mid.bfRoiUncertainty.roi03.roiRepresentativeCtc.Text);
     bayRoi3.mid.avg(k) = str2double(resBay.summary.slc.mid.bfRoiUncertainty.roi03.wildBootstrap.mean.Text);
     bayRoi3.mid.std(k) = str2double(resBay.summary.slc.mid.bfRoiUncertainty.roi03.wildBootstrap.std.Text);
     bayRoi3.mid.min(k) = str2double(resBay.summary.slc.mid.bfRoiUncertainty.roi03.wildBootstrap.min.Text);
     bayRoi3.mid.max(k) = str2double(resBay.summary.slc.mid.bfRoiUncertainty.roi03.wildBootstrap.max.Text);
     
     bayRoi3.apex.avg(k) = str2double(resBay.summary.slc.apex.bfRoiUncertainty.roi03.wildBootstrap.mean.Text);
     bayRoi3.apex.std(k) = str2double(resBay.summary.slc.apex.bfRoiUncertainty.roi03.wildBootstrap.std.Text);
     
     % Fermi
     fermiRoi3.base.avg(k) = str2double(resFermi.summary.slc.base.bfRoiUncertainty.roi03.wildBootstrap.mean.Text);
     fermiRoi3.base.std(k) = str2double(resFermi.summary.slc.base.bfRoiUncertainty.roi03.wildBootstrap.std.Text);
     
     fermiRoi3.mid.roiAvg(k) = str2double(resFermi.summary.slc.mid.bfRoiUncertainty.roi03.roiAvgCtc.Text);
     fermiRoi3.mid.roiRepresentativeCtc(k) = str2double(resFermi.summary.slc.mid.bfRoiUncertainty.roi03.roiRepresentativeCtc.Text);
     fermiRoi3.mid.avg(k) = str2double(resFermi.summary.slc.mid.bfRoiUncertainty.roi03.wildBootstrap.mean.Text);
     fermiRoi3.mid.std(k) = str2double(resFermi.summary.slc.mid.bfRoiUncertainty.roi03.wildBootstrap.std.Text);
     fermiRoi3.mid.min(k) = str2double(resFermi.summary.slc.mid.bfRoiUncertainty.roi03.wildBootstrap.min.Text);
     fermiRoi3.mid.max(k) = str2double(resFermi.summary.slc.mid.bfRoiUncertainty.roi03.wildBootstrap.max.Text);
     
     fermiRoi3.apex.avg(k) = str2double(resFermi.summary.slc.apex.bfRoiUncertainty.roi03.wildBootstrap.mean.Text);
     fermiRoi3.apex.std(k) = str2double(resFermi.summary.slc.apex.bfRoiUncertainty.roi03.wildBootstrap.std.Text);
     
     
 end

 
 %% results 
 %% display
  fm = figureMgr.getInstance();
  
  colorTab = [148, 239, 163;
              10, 81, 43;
              132, 224, 255;
              4, 33, 137] / 255;
 
 %roi02 (lesion)
 % bayesian
%  fm.newFig('base'); hold on; errorbar(1:length(patientDataSet), bayRoi2.base.avg, bayRoi2.base.std, 'o', 'color', [0.9 0.6 0]);
%  fm.newFig('mid');  hold on; errorbar(1:length(patientDataSet), bayRoi2.mid.avg,  bayRoi2.mid.std, 'o', 'color', [0.9 0.6 0]);
%  fm.newFig('apex'); hold on; errorbar(1:length(patientDataSet), bayRoi2.apex.avg, bayRoi2.apex.std, 'o', 'color', [0.9 0.6 0]);
%  %fermi 
%  fm.newFig('base'); hold on; errorbar(1:length(patientDataSet), fermiRoi2.base.avg, fermiRoi2.base.std, 'o', 'color', [0.9 0 0]);
%  fm.newFig('mid');  hold on; errorbar(1:length(patientDataSet), fermiRoi2.mid.avg,  fermiRoi2.mid.std, 'o', 'color', [0.9 0 0]);
%  fm.newFig('apex'); hold on; errorbar(1:length(patientDataSet), fermiRoi2.apex.avg, fermiRoi2.apex.std, 'o', 'color', [0.9 0 0]);
%  
%  
%  %roi03 (normal)
%  %bayesian
%  fm.newFig('base'); errorbar(1:length(patientDataSet), bayRoi3.base.avg, bayRoi3.base.std, 'o', 'color', [0.2 0.6 0.2]);
%  fm.newFig('mid');  errorbar(1:length(patientDataSet), bayRoi3.mid.avg,  bayRoi3.mid.std, 'o', 'color',  [0.2 0.6 0.2]);
%  fm.newFig('apex'); errorbar(1:length(patientDataSet), bayRoi3.apex.avg, bayRoi3.apex.std, 'o', 'color', [0.2 0.6 0.2]);
%   %fermi 
%  fm.newFig('base'); hold on; errorbar(1:length(patientDataSet), fermiRoi3.base.avg, fermiRoi3.base.std, 'o', 'color', 'cyan');
%  fm.newFig('mid');  hold on; errorbar(1:length(patientDataSet), fermiRoi3.mid.avg,  fermiRoi3.mid.std, 'o', 'color',  'cyan');
%  fm.newFig('apex'); hold on; errorbar(1:length(patientDataSet), fermiRoi3.apex.avg, fermiRoi3.apex.std, 'o', 'color', 'cyan');
%  
%  
% fm.newFig('base'); 
% xlim([0.5 12.5]); ylim([0 5]);
% set(gca, 'LineWidth',2,'FontWeight','bold', 'FontSize',14);
% xlabel('patient','FontWeight','bold','FontSize',16);
% ylabel('MBF (ml/min/g)','FontWeight','bold','FontSize',16);
% legend('bayesian - abnormal', 'fermi - abnormal', 'bayesian - normal','fermi - normal')
% 
% fm.newFig('mid');
% xlim([0.5 12.5]); ylim([0 5]);
% set(gca, 'LineWidth',2,'FontWeight','bold', 'FontSize',14)
% xlabel('patient','FontWeight','bold','FontSize',16);
% ylabel('MBF (ml/min/g)','FontWeight','bold','FontSize',16);
% legend('bayesian - abnormal', 'fermi - abnormal', 'bayesian - normal','fermi - normal')
%  
% fm.newFig('apex');
% xlim([0.5 12.5]); ylim([0 5]);
% set(gca, 'LineWidth',2,'FontWeight','bold', 'FontSize',14)
% xlabel('patient','FontWeight','bold','FontSize',16);
% ylabel('MBF (ml/min/g)','FontWeight','bold','FontSize',16);
% legend('bayesian - abnormal', 'fermi - abnormal', 'bayesian - normal','fermi - normal')



fm.newFig('mid bar')
data = [bayRoi2.mid.avg', bayRoi3.mid.avg', fermiRoi2.mid.avg', fermiRoi3.mid.avg'];
errData = [bayRoi2.mid.std', bayRoi3.mid.std', fermiRoi2.mid.std', fermiRoi3.mid.std'];

errData(isnan(data)) = 0;
data(isnan(data)) = 0;
h = barwitherr(errData, data);
% set(gca,'xtick',[]); 
set(gca,'XTickLabel',{'1','2', '3', ...
                      '4','5', '6', ...
                      '7','8', '9', ...
                      '10','11', '12'});
xlabel('patient')
ylabel('MBF (ml/min/g)','FontWeight','bold','FontSize',16);
legend('bayesian (abnormal)', 'bayesian (normal)', 'fermi (abnormal)', 'fermi (normal)');
set(h(1), 'FaceColor', colorTab(1, :));
set(h(2), 'FaceColor', colorTab(2, :));
set(h(3), 'FaceColor', colorTab(3, :));
set(h(4), 'FaceColor', colorTab(4, :));
set(gca, 'LineWidth',1.5,'FontWeight','bold', 'FontSize',14);



%% write results in a text file


methodsKS = {'Bayesian', 'Fermi'};

for k = 1 : length(methodsKS)
    curMethod = char(methodsKS(k));
    fid = fopen(fullfile(rootPath, ['bsResultsAnalysis' curMethod '.txt']), 'w');
    switch curMethod
        case 'Bayesian'
            roi2Results = bayRoi2;
            roi3Results = bayRoi3;
        case 'Fermi'
            roi2Results = fermiRoi2;
            roi3Results = fermiRoi3;
    end
    
    try
        fprintf(fid, 'results: \n');
        fprintf(fid, 'Mid (lesion): \n');
        fprintf(fid, 'roi avg:\n');
        fprintf(fid, '%0.02f ', roi2Results.mid.roiAvg);
        fprintf(fid, '\nroi representative:\n');
        fprintf(fid, '%0.02f ', roi2Results.mid.roiRepresentativeCtc);
        fprintf(fid, '\nWB avg:\n');
        fprintf(fid, '%0.02f ', roi2Results.mid.avg);
        fprintf(fid, '\nWB std:\n');
        fprintf(fid, '%0.02f ', roi2Results.mid.std);
        fprintf(fid, '\nWB min:\n');
        fprintf(fid, '%0.02f ', roi2Results.mid.min);
        fprintf(fid, '\nWB max:\n');
        fprintf(fid, '%0.02f ', roi2Results.mid.max);
        
        fprintf(fid, '\n\nMid (normal): \n');
        fprintf(fid, 'roi avg:\n');
        fprintf(fid, '%0.02f ', roi3Results.mid.roiAvg);
        fprintf(fid, '\nroi representative:\n');
        fprintf(fid, '%0.02f ', roi3Results.mid.roiRepresentativeCtc);
        fprintf(fid, '\nWB avg:\n');
        fprintf(fid, '%0.02f ', roi3Results.mid.avg);
        fprintf(fid, '\nWB std:\n');
        fprintf(fid, '%0.02f ', roi3Results.mid.std);
        fprintf(fid, '\nWB min:\n');
        fprintf(fid, '%0.02f ', roi3Results.mid.min);
        fprintf(fid, '\nWB max:\n');
        fprintf(fid, '%0.02f ', roi3Results.mid.max);
        
    catch
        logger.getInstance().err('error writing bootstrap analysis');
        fclose(fid);
        return
    end
    fclose(fid);
end


%% write results in excel sheet structure way

for k = 1 : length(methodsKS)
    curMethod = char(methodsKS(k));
    
    switch curMethod
        case 'Bayesian'
            roi2Results = bayRoi2;
            roi3Results = bayRoi3;
        case 'Fermi'
            roi2Results = fermiRoi2;
            roi3Results = fermiRoi3;
    end
    
    lesionRoiAvg(k,:) = roi2Results.mid.roiAvg;
    lesionRoiRepresentative(k,:) = roi2Results.mid.roiRepresentativeCtc;
    lesionAvg(k,:) = roi2Results.mid.avg;
    lesionStd(k,:) = roi2Results.mid.std;
    lesionMin(k,:) = roi2Results.mid.min;
    lesionMax(k,:) = roi2Results.mid.max;
    
    normalRoiAvg(k,:) = roi3Results.mid.roiAvg;
    normalRoiRepresentative(k,:) = roi3Results.mid.roiRepresentativeCtc;
    normalAvg(k,:) = roi3Results.mid.avg;
    normalStd(k,:) = roi3Results.mid.std;
    normalMin(k,:) = roi3Results.mid.min;
    normalMax(k,:) = roi3Results.mid.max;
    
end


lesionRoiAvg = [bayRoi2.mid.roiAvg; bayRoi3.mid.roiAvg; fermiRoi2.mid.roiAvg; fermiRoi3.mid.roiAvg];
lesionRoiAvg = lesionRoiAvg(:)';
lesionRoiRepresentative = [bayRoi2.mid.roiRepresentativeCtc; bayRoi3.mid.roiRepresentativeCtc; fermiRoi2.mid.roiRepresentativeCtc; fermiRoi3.mid.roiRepresentativeCtc];
lesionRoiRepresentative = lesionRoiRepresentative(:)';
lesionAvg = [bayRoi2.mid.avg; bayRoi3.mid.avg; fermiRoi2.mid.avg; fermiRoi3.mid.avg];
lesionAvg = lesionAvg(:)';
lesionStd = [bayRoi2.mid.std; bayRoi3.mid.std; fermiRoi2.mid.std; fermiRoi3.mid.std];
lesionStd = lesionStd(:)';
lesionMin = [bayRoi2.mid.min; bayRoi3.mid.min; fermiRoi2.mid.min; fermiRoi3.mid.min];
lesionMin = lesionMin(:)';
lesionMax = [bayRoi2.mid.max; bayRoi3.mid.max; fermiRoi2.mid.max; fermiRoi3.mid.max];
lesionMax = lesionMax(:)';

fid = fopen(fullfile(rootPath, '0000_Results', 'bsResultsAnalysis4Excel.txt'), 'w');
try
        fprintf(fid, 'results: \n');
        fprintf(fid, 'Mid (bayesian_lesion, bayesian_normal, fermi lesion, fermi_normal, ...): \n');
        fprintf(fid, 'roi avg:\n');
        fprintf(fid, '%0.02f ', lesionRoiAvg);
        fprintf(fid, '\nroi representative:\n');
        fprintf(fid, '%0.02f ', lesionRoiRepresentative);
        fprintf(fid, '\nWB avg:\n');
        fprintf(fid, '%0.02f ', lesionAvg);
        fprintf(fid, '\nWB std:\n');
        fprintf(fid, '%0.02f ', lesionStd);
        fprintf(fid, '\nWB min:\n');
        fprintf(fid, '%0.02f ', lesionMin);
        fprintf(fid, '\nWB max:\n');
        fprintf(fid, '%0.02f ', lesionMax);
catch
    logger.getInstance().err('error writing bootstrap analysis 4 excel');
    fclose(fid);
    return
end
fclose(fid);

 end