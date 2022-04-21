load(file = '~/Dropbox/MORU/Severe malaria/RData/kemri_SM_HRP2_genotypes.RData')

table(is.na(kemri_case_data$HRP2))
table(is.na(kemri_case_data$parasite_gn))
table(is.na(kemri_case_data$platelet))
table(is.na(kemri_case_data$HRP2)&
        is.na(kemri_case_data$parasite_gn)&
        is.na(kemri_case_data$platelet))

# remove patients who don't have parasite densities, HRP2 or platelet count
kemri_case_data =
  kemri_case_data[!(is.na(kemri_case_data$HRP2)&
                      is.na(kemri_case_data$parasite_gn)&
                      is.na(kemri_case_data$platelet)), ]


# log transform variables
kemri_case_data$log_parasites = log10(kemri_case_data$parasite_gn+50)
kemri_case_data$log_platelet = log10(kemri_case_data$platelet)
kemri_case_data$log_wbc = log10(kemri_case_data$wbc)
kemri_case_data$log_hrp2= log10(kemri_case_data$HRP2)

var_imp = c('agemths',"died","sex","ethnic","muac",'baseexc',
            "oxysat","hb","creat","bcstot",'bloodculture_pos',
            'k','na','log_platelet','log_parasites',
            'log_hrp2','log_wbc')

par(las=1, mar=c(4,8,2,2),cex.axis=1)
Missing_data=is.na(kemri_case_data[, var_imp])
image(x = 1:nrow(Missing_data), y = 1:length(var_imp), Missing_data,
      yaxt='n',ylab='',xaxt='n', xlab='')
axis(2, at = 1:length(var_imp), labels = tolower(var_imp),cex=.7)
title('Kilifi: missing/available data')
par(las=1, family='serif', cex.lab=1.5, cex.axis=1.5,mar=c(6,6,2,2))

RE_RUN_IMPUTATION=F
K_imputes = 10
if(RE_RUN_IMPUTATION){
  set.seed(8758768)
  registerDoParallel(cores = 12)

  my_dat = as.data.frame(kemri_case_data[,var_imp])
  my_dat[] <- lapply(my_dat, function(x) { attributes(x) <- NULL; x })

  my_dat$died = (as.factor(my_dat$died))
  my_dat$ethnic = (as.factor(my_dat$ethnic))
  my_dat$sex = (as.factor(my_dat$sex))
  my_dat$bloodculture_pos = (as.factor(my_dat$bloodculture_pos))

  imputed_data = list()
  for(k in 1:K_imputes){

    out_impute = missForest(xmis = my_dat,
                            variablewise = T,
                            ntree = 200,
                            decreasing = T,verbose = T,
                            parallelize = 'variables')

    imputed_data[[k]] = out_impute$ximp

  }

  save(imputed_data, file = '~/Dropbox/MORU/Severe malaria/Parasite_biomass_HRP2/Imputed_Data_kemri.RData')
} else {
  load('~/Dropbox/MORU/Severe malaria/Parasite_biomass_HRP2/Imputed_Data_kemri.RData')
}

gg_names_char = c('hbb_rs334',
                  'frem3_rs186873296',
                  'abo_rs8176719',
                  'atp2b4_rs1541255',
                  'g6pd_202',
                  'cd40lg_rs3092945',
                  'rps6kl1_rs3742785',
                  'loc727982_rs1371478',
                  'arl14_rs75731597',
                  'lphn2_rs72933304',
                  'il10_rs1800890',
                  'cand1_rs10459266',
                  'gnas_rs8386')

gg_names = c('hbb_rs334_num',
             'hba1_2',
             'frem3_rs186873296_num',
             'abo_rs8176719_num',
             'atp2b4_rs1541255_num',
             'g6pd_202',
             'cd40lg_rs3092945_num',
             'rps6kl1_rs3742785_num',
             'loc727982_rs1371478_num',
             'arl14_rs75731597_num',
             'lphn2_rs72933304_num',
             'il10_rs1800890_num',
             'cand1_rs10459266_num',
             'gnas_rs8386_num')
print(gg_names)
length(gg_names)

var_names = c('log_parasites', 'log_hrp2',
              'log_platelet','log_wbc',
              'hb', 'bloodculture_pos', 'ethnic', 'agemths')
kemri_case_data = kemri_case_data[, c(var_names, gg_names, gg_names_char)]
kemri_case_data$ethnic = as.factor(kemri_case_data$ethnic)

gg_name_main = c('hbb_rs334_num',
                 'hba1_2',
                 'frem3_rs186873296_num',
                 'abo_rs8176719_num',
                 'atp2b4_rs1541255_num')
ndila_dat_control$g6pd_202 = ndila_dat_control$g6pd_rs1050828
kemri_control_data = ndila_dat_control[, c(gg_name_main, gg_names_char)]

for(i in 1:length(imputed_data)){
  imputed_data[[i]] = imputed_data[[i]][, var_names]
}

save(gg_names, gg_name_main, gg_names_char,
     kemri_case_data,
     kemri_control_data,
     imputed_data,
     file = 'analysis_data.Rdata')
write.csv(kemri_case_data, file = 'kemri_case_data.csv',quote = F,row.names = F)
write.csv(kemri_control_data, file = 'kemri_control_data.csv',quote = F,row.names = F)
