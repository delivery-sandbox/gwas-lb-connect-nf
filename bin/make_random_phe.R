n = 1000

cancer_types <- c('endometrial_carcinoma','malignt_melanoma','prostate','hepatopancreatobiliary',
                  'upper_gastrointestil','ovarian','adult_glioma','unknown','sinosal',
                  'sopharyngeal','haemonc','carcinoma_of_unknown_primary','sarcoma',
                  'testicular_germ_cell_tumours','breast','colorectal','childhood','bladder',
                  'other','oral_oropharyngeal')



df <- data.frame( IID = seq(n), FID = seq(n),
                  sex = sample(1:2, n, replace=T),
                  age = sample(35:96, n, replace=T),
                  cancer_type = sample(cancer_types, n, replace=T),
                  bmi = (rt(n, df = 3) / sqrt(3))*1.5+26 )


plot(density(df$age))

write.table(df, file = "testdata/random.phe", 
            sep = '\t', quote = F, row.names = F) 

