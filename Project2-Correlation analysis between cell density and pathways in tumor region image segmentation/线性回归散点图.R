rm(list=ls()) # 清除环境变量
### 设置工作目录
setwd("E:/work/项目/项目-大连姚文厚-肺癌预测复发转移/新思路_6月4日/图2. 肿瘤区域图像分割的细胞密度和通路之间的相关性分析")

### 回归分析相关性散点图
library(ggplot2) #加载作图需要的包
library(ggpubr) #加载显著性检验需要的包

### 导入数据
diffmicro<-read.csv("通路匹配结果_217.csv",row.names = 1)
immunecell<-read.csv("细胞含量_217.csv",row.names = 1)


### 创建分析数据框
##嗜中性粒细胞
## 按中位数分组
Neutrophil <- immunecell[,4]
median_Neutrophil <- median(Neutrophil)
high_group <- immunecell[Neutrophil  > median_Neutrophil, ]
low_group <- immunecell[Neutrophil <= median_Neutrophil, ]  
Neutrophil_high <- rownames(high_group)
Neutrophil_low <- rownames(low_group)
cell_high <- high_group['Neutrophil']
cell_low <- low_group['Neutrophil']
cell_data <- rbind(cell_high, cell_low) 

## 根据ID在第二个CSV文件中筛选数据 
Neutrophil_high_data <- diffmicro[rownames(diffmicro) %in% Neutrophil_high, ]
Neutrophil_low_data <- diffmicro[rownames(diffmicro) %in% Neutrophil_low, ]

## 根据HALLMARK_HEME_METABOLISM特征合并相应的数据框
Neutrophil_high_data$group <- "High"
Neutrophil_low_data$group <- "Low"
combined_data <- rbind(Neutrophil_high_data, Neutrophil_low_data) 
# HALLMARK_HEME_METABOLISM
Neutrophil_aim_data <- combined_data[, c('HALLMARK_ANDROGEN_RESPONSE','group')]
# HALLMARK_PROTEIN_SECRETION
Neutrophil_aim_data <- combined_data[, c('HALLMARK_PROTEIN_SECRETION','group')]
# HALLMARK_ANDROGEN_RESPONSE
Neutrophil_aim_data <- combined_data[, c('HALLMARK_ANDROGEN_RESPONSE','group')]
# HALLMARK_UV_RESPONSE_DN
Neutrophil_aim_data <- combined_data[, c('HALLMARK_UV_RESPONSE_DN','group')]
# HALLMARK_NOTCH_SIGNALING
Neutrophil_aim_data <- combined_data[, c('HALLMARK_NOTCH_SIGNALING','group')]

## 按照行名合并最终数据
final_data <- cbind(cell_data ,Neutrophil_aim_data)
## 删除Neutrophil=110449，属于异常值
final_data <- final_data[final_data$Neutrophil != 110449, ]


# 拟合Neutrophil和HALLMARK_HEME_METABOLISM的线性关系，添加置信区间
ggscatter(final_data, x = "Neutrophil", y = "HALLMARK_NOTCH_SIGNALING",
          size = 2,
          add = "reg.line",  # 添加回归线
          add.params = list(color = "#77C034", fill = "#C5E99B", size = 1.5),  # 自定义回归线的颜色
          conf.int = TRUE  # 添加置信区间
          ) +
  stat_cor(method = "spearman", label.sep = "\n") +
  xlab("Neutrophil content") +
  ylab("HALLMARK_PROTEIN_SECRETION pathway")

ggsave("Neutrophil与HALLMARK_NOTCH_SIGNALING的回归分析相关性散点图.pdf", height = 2.5, width = 8)


##淋巴细胞
## 按中位数分组
Lymphocyte <- immunecell[,2]
median_Lymphocyte <- median(Lymphocyte)
high_group <- immunecell[Lymphocyte > median_Lymphocyte, ]
low_group <- immunecell[Lymphocyte<= median_Lymphocyte, ]  
Neutrophil_high <- rownames(high_group)
Neutrophil_low <- rownames(low_group)
cell_high <- high_group['Lymphocyte']
cell_low <- low_group['Lymphocyte']
cell_data <- rbind(cell_high, cell_low) 

## 根据ID在第二个CSV文件中筛选数据 
Neutrophil_high_data <- diffmicro[rownames(diffmicro) %in% Neutrophil_high, ]
Neutrophil_low_data <- diffmicro[rownames(diffmicro) %in% Neutrophil_low, ]

## 根据HALLMARK_HEME_METABOLISM特征合并相应的数据框
Neutrophil_high_data$group <- "High"
Neutrophil_low_data$group <- "Low"
combined_data <- rbind(Neutrophil_high_data, Neutrophil_low_data) 
# HALLMARK_HEME_METABOLISM
Neutrophil_aim_data <- combined_data[, c('HALLMARK_HEME_METABOLISM','group')]
# HALLMARK_PROTEIN_SECRETION
Neutrophil_aim_data <- combined_data[, c('HALLMARK_PROTEIN_SECRETION','group')]
# HALLMARK_ANDROGEN_RESPONSE
Neutrophil_aim_data <- combined_data[, c('HALLMARK_ANDROGEN_RESPONSE','group')]
# HALLMARK_UV_RESPONSE_DN
Neutrophil_aim_data <- combined_data[, c('HALLMARK_UV_RESPONSE_DN','group')]
# HALLMARK_NOTCH_SIGNALING
Neutrophil_aim_data <- combined_data[, c('HALLMARK_NOTCH_SIGNALING','group')]

## 按照行名合并最终数据
final_data <- cbind(cell_data ,Neutrophil_aim_data)

# 拟合Neutrophil和HALLMARK_HEME_METABOLISM的线性关系，添加置信区间
ggscatter(final_data, x = "Lymphocyte", y = "HALLMARK_NOTCH_SIGNALING",
          size = 2,
          add = "reg.line",  # 添加回归线
          add.params = list(color = "#77C034", fill = "#C5E99B", size = 1.5),  # 自定义回归线的颜色
          conf.int = TRUE  # 添加置信区间
) +
  stat_cor(method = "spearman", label.sep = "\n") +
  xlab("Neutrophil content") +
  ylab("HALLMARK_NOTCH_SIGNALING pathway")
ggsave("Lymphocyte与HALLMARK_NOTCH_SIGNALING的回归分析相关性散点图.pdf", height = 2.5, width = 8)
