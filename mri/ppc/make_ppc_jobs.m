% script to create PPC jobs
% 3.25.2017

% define paths
projectDir = '/projects/dsnlab/SFIC_Self3';
jobDir = '/Users/danicosme/Documents/code/SFIC-code/spm/ppc/ppc_jobs/';

% define variables (skull-stripped symmetrical T2 MNI template)
template = '/projects/dsnlab/SPM12/canonical/mni_icbm152_nlin_sym_09a/b_mni_icbm152_t2_tal_nlin_sym_09a.nii';

% load reo params
load ~/Documents/code/SFIC-code/spm/ppc/reo/reoCell_final.mat

% loop through subjects and replace subject ID, wave, reo parameters
for subCount = 1:96;
	if subCount < 10
		subID = ['s00',num2str(subCount)];
	else
		subID = ['s0',num2str(subCount)];
	end
	for tCount = 1:3
		subReoParams{tCount} = reoCell{tCount}(subCount,:);
		matlabbatch{1}.cfg_basicio.file_dir.file_ops.file_fplist.dir = {[projectDir,'/subjects/',subID,'/t',(num2str(tCount)),'/ppc']};
		matlabbatch{1}.cfg_basicio.file_dir.file_ops.file_fplist.filter = ['^b_t',(num2str(tCount)),'_self*'];
		matlabbatch{1}.cfg_basicio.file_dir.file_ops.file_fplist.rec = 'FPList';
		matlabbatch{2}.spm.spatial.realign.estwrite.data{1}(1) = cfg_dep('File Selector (Batch Mode): Selected Files (^b_t,(num2str(tCount)),_self*)', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files'));
        matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.quality = 0.9;
		matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.sep = 4;
		matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.fwhm = 5;
		matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.rtm = 1;
		matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.interp = 3;
		matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.wrap = [0 0 0];
		matlabbatch{2}.spm.spatial.realign.estwrite.eoptions.weight = '';
		matlabbatch{2}.spm.spatial.realign.estwrite.roptions.which = [0 1];
		matlabbatch{2}.spm.spatial.realign.estwrite.roptions.interp = 3;
		matlabbatch{2}.spm.spatial.realign.estwrite.roptions.wrap = [0 0 0];
		matlabbatch{2}.spm.spatial.realign.estwrite.roptions.mask = 1;
		matlabbatch{2}.spm.spatial.realign.estwrite.roptions.prefix = 'r';
		matlabbatch{3}.spm.spatial.coreg.estimate.ref = {[projectDir,'/subjects',filesep,subID,filesep,['t',(num2str(tCount))],'/ppc/',['b_t',num2str(tCount),'_hires.nii'] ]};
		matlabbatch{3}.spm.spatial.coreg.estimate.source(1) = cfg_dep('Realign: Estimate & Reslice: Mean Image', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','rmean'));
		matlabbatch{3}.spm.spatial.coreg.estimate.other(1) = cfg_dep('Realign: Estimate & Reslice: Realigned Images (Sess 1)', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','sess', '()',{1}, '.','cfiles'));
		matlabbatch{3}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
		matlabbatch{3}.spm.spatial.coreg.estimate.eoptions.sep = [32 16 8 4 2];
		matlabbatch{3}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
		matlabbatch{3}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];
		matlabbatch{4}.spm.util.reorient.srcfiles(1) = cfg_dep('Coregister: Estimate: Coregistered Images', substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','cfiles'));
		matlabbatch{4}.spm.util.reorient.transform.transprm = [subReoParams{tCount}];
		matlabbatch{4}.spm.util.reorient.prefix = 'o';
		matlabbatch{5}.spm.util.reorient.srcfiles(1) = {[projectDir,'/subjects',filesep,subID,filesep,['t',(num2str(tCount))],'/ppc/',['b_t',num2str(tCount),'_hires.nii'] ]};
		matlabbatch{5}.spm.util.reorient.transform.transprm = [subReoParams{tCount}];
		matlabbatch{5}.spm.util.reorient.prefix = 'o';
        matlabbatch{6}.spm.tools.oldnorm.estwrite.subj.source(1) = cfg_dep('Reorient Images: Reoriented Images', substruct('.','val', '{}',{4}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files'));
        matlabbatch{6}.spm.tools.oldnorm.estwrite.subj.wtsrc = '';
        matlabbatch{6}.spm.tools.oldnorm.estwrite.subj.resample(1) = cfg_dep('Reorient Images: Reoriented Images', substruct('.','val', '{}',{4}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files'));
        matlabbatch{6}.spm.tools.oldnorm.estwrite.eoptions.template = {[template,',1']};
        matlabbatch{6}.spm.tools.oldnorm.estwrite.eoptions.weight = '';
        matlabbatch{6}.spm.tools.oldnorm.estwrite.eoptions.smosrc = 8;
        matlabbatch{6}.spm.tools.oldnorm.estwrite.eoptions.smoref = 0;
        matlabbatch{6}.spm.tools.oldnorm.estwrite.eoptions.regtype = 'mni';
        matlabbatch{6}.spm.tools.oldnorm.estwrite.eoptions.cutoff = 25;
        matlabbatch{6}.spm.tools.oldnorm.estwrite.eoptions.nits = 16;
        matlabbatch{6}.spm.tools.oldnorm.estwrite.eoptions.reg = 1;
        matlabbatch{6}.spm.tools.oldnorm.estwrite.roptions.preserve = 0;
        matlabbatch{6}.spm.tools.oldnorm.estwrite.roptions.bb = [-78 -112 -70
                                                                 78 76 85];
        matlabbatch{6}.spm.tools.oldnorm.estwrite.roptions.vox = [3 3 3];
        matlabbatch{6}.spm.tools.oldnorm.estwrite.roptions.interp = 1;
        matlabbatch{6}.spm.tools.oldnorm.estwrite.roptions.wrap = [0 0 0];
        matlabbatch{6}.spm.tools.oldnorm.estwrite.roptions.prefix = 'w';
        matlabbatch{7}.spm.tools.oldnorm.estwrite.subj.source(1) = cfg_dep('Reorient Images: Reoriented Images', substruct('.','val', '{}',{5}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files'));
        matlabbatch{7}.spm.tools.oldnorm.estwrite.subj.wtsrc = '';
        matlabbatch{7}.spm.tools.oldnorm.estwrite.subj.resample(1) = cfg_dep('Reorient Images: Reoriented Images', substruct('.','val', '{}',{5}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files'));
        matlabbatch{7}.spm.tools.oldnorm.estwrite.eoptions.template = {[template,',1']};
        matlabbatch{7}.spm.tools.oldnorm.estwrite.eoptions.weight = '';
        matlabbatch{7}.spm.tools.oldnorm.estwrite.eoptions.smosrc = 8;
        matlabbatch{7}.spm.tools.oldnorm.estwrite.eoptions.smoref = 0;
        matlabbatch{7}.spm.tools.oldnorm.estwrite.eoptions.regtype = 'mni';
        matlabbatch{7}.spm.tools.oldnorm.estwrite.eoptions.cutoff = 25;
        matlabbatch{7}.spm.tools.oldnorm.estwrite.eoptions.nits = 16;
        matlabbatch{7}.spm.tools.oldnorm.estwrite.eoptions.reg = 1;
        matlabbatch{7}.spm.tools.oldnorm.estwrite.roptions.preserve = 0;
        matlabbatch{7}.spm.tools.oldnorm.estwrite.roptions.bb = [-78 -112 -70
                                                                 78 76 85];
        matlabbatch{7}.spm.tools.oldnorm.estwrite.roptions.vox = [2 2 2];
        matlabbatch{7}.spm.tools.oldnorm.estwrite.roptions.interp = 1;
        matlabbatch{7}.spm.tools.oldnorm.estwrite.roptions.wrap = [0 0 0];
        matlabbatch{7}.spm.tools.oldnorm.estwrite.roptions.prefix = 'w';
        matlabbatch{8}.spm.spatial.smooth.data(1) = cfg_dep('Old Normalise: Estimate & Write: Normalised Images (Subj 1)', substruct('.','val', '{}',{6}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('()',{1}, '.','files'));
        matlabbatch{8}.spm.spatial.smooth.fwhm = [6 6 6];
        matlabbatch{8}.spm.spatial.smooth.dtype = 0;
        matlabbatch{8}.spm.spatial.smooth.im = 0;
        matlabbatch{8}.spm.spatial.smooth.prefix = 's6';

		saveJob = [jobDir,[subID,'_t',num2str(tCount),'_ppc_job.mat']];
		save(saveJob,'matlabbatch');
		clear matlabbatch;
	end
end


