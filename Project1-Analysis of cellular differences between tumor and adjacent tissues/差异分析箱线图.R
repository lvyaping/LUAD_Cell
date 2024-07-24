library(tidyverse)
library(rstatix)
library(ggpubr)
library(dplyr)  
library(ggplot2)

# 数据
set.seed(123)
path <- 'C:/Users/dell/Desktop/lungproject/variation_analysis/Tcga_cell.csv'
data <-read.csv(file=path, header=T)
data <- as.data.frame(data)
data$Label <- as.factor(data$Label)


##复发和非复发组间差异
my_comparisons <- list( c("normal", "tumor"))##分组设定
e<-data %>% 
  dplyr::filter(Label%in% c("normal", "tumor")) %>% #筛选行
  ggviolin(x = "Label", y = c(colnames(data)[5]), fill = "Label",
           combine = T,
           #palette = c("#00AFBB", "#E7B800", "#FC4E07"),##颜色设置
           ylab="cell number",
           add = "boxplot", add.params = list(fill = "white"))
e+stat_compare_means(method = "t.test",
                     label = "p.signif",##星号设置
                     comparisons = my_comparisons)
ggsave('C:/Users/dell/Desktop/lungproject/variation_analysis/TCGA癌旁和肿瘤间Epithelial.Lymphocyte细胞差异分析.pdf', width = 5, height = 7)
