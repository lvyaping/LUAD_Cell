library(ggplot2)
library(reshape2)
library(ggpubr)
library(ggsignif)  #添加显著性标记

diffmicro<-read.csv("E:/work/项目/项目-大连姚文厚-肺癌预测复发转移/新思路_6月4日/图2. 肿瘤区域图像分割的细胞密度和通路之间的相关性分析/通路匹配结果_217.csv",row.names = 1)
immunecell<-read.csv("E:/work/项目/项目-大连姚文厚-肺癌预测复发转移/新思路_6月4日/图2. 肿瘤区域图像分割的细胞密度和通路之间的相关性分析/细胞含量_217.csv",row.names = 1)
#根据相关性提取两列，并计算中位数，进行分组
Lymphocyte <- immunecell[,2]
median_Lymphocyte <- median(Lymphocyte)
high_group <- immunecell[Lymphocyte > median_Lymphocyte, ]
low_group <- immunecell[Lymphocyte <= median_Lymphocyte, ]  
Lymphocyte_high <- rownames(high_group)
Lymphocyte_low <- rownames(low_group)

Neutrophil <- immunecell[,4]
median_Neutrophil <- median(Neutrophil)
high_group <- immunecell[Neutrophil  > median_Neutrophil, ]
low_group <- immunecell[Neutrophil <= median_Neutrophil, ]  
Neutrophil_high <- rownames(high_group)
Neutrophil_low <- rownames(low_group)

# 根据ID在第二个CSV文件中筛选数据  
Lymphocyte_high_data <- diffmicro[rownames(diffmicro) %in% Lymphocyte_high, ]
Lymphocyte_low_data <- diffmicro[rownames(diffmicro) %in% Lymphocyte_low, ]

Neutrophil_high_data <- diffmicro[rownames(diffmicro) %in% Neutrophil_high, ]
Neutrophil_low_data <- diffmicro[rownames(diffmicro) %in% Neutrophil_low, ]

# 根据指定的几个特征合并相应的数据框
# 特征分别有HALLMARK_NOTCH_SIGNALING，HALLMARK_UV_RESPONSE_DN，HALLMARK_ANDROGEN_RESPONSE，HALLMARK_PROTEIN_SECRETION，HALLMARK_HEME_METABOLISM
Lymphocyte_high_data$group <- "High"
Lymphocyte_low_data$group <- "Low"
combined_data <- rbind(Lymphocyte_high_data, Lymphocyte_low_data)  
Lymphocyte_aim_data <- combined_data[, c("HALLMARK_NOTCH_SIGNALING", "HALLMARK_UV_RESPONSE_DN","HALLMARK_ANDROGEN_RESPONSE",'HALLMARK_PROTEIN_SECRETION','HALLMARK_HEME_METABOLISM','group')]

Neutrophil_high_data$group <- "High"
Neutrophil_low_data$group <- "Low"
combined_data <- rbind(Neutrophil_high_data, Neutrophil_low_data)  
Neutrophil_aim_data <- combined_data[, c("HALLMARK_NOTCH_SIGNALING", "HALLMARK_UV_RESPONSE_DN","HALLMARK_ANDROGEN_RESPONSE",'HALLMARK_PROTEIN_SECRETION','HALLMARK_HEME_METABOLISM','group')]

# 小提琴图
data=melt(Neutrophil_aim_data,id.vars=c("group"))
colnames(data)=c("Type","Gene","Expression")

p=ggviolin(data, x="Gene", y="Expression", color = "Type", 
           ylab="Gene expression",
           xlab="Gene",
           add.params = list(fill="white"),
           palette = c("#3B4992FF","#EE0000FF"),    
           width=1, add = "boxplot")
p=p+rotate_x_text(60)
p1=p+stat_compare_means(aes(group=Type),
                        method="wilcox.test", #可换其他统计方法
                        symnum.args=list(cutpoints = c(0, 0.001, 0.01, 0.05, 1), symbols = c("***", "**", "*", " ")),
                        label = "p.signif")
ggsave("E:/work/项目/项目-大连姚文厚-肺癌预测复发转移/新思路_6月4日/图2. 肿瘤区域图像分割的细胞密度和通路之间的相关性分析/Neutrophil_差异分析.pdf",plot=p1, width = 6, height = 8)
