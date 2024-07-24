rm(list = ls())

library(ggplot2)
library(stringr)  
library(dplyr)  
library(survival)
library(survminer)

### 设置的工作路径
setwd("E:/work/项目/项目-大连姚文厚-肺癌预测复发转移/新思路_6月4日/图6. 差异基因的筛选及预后建模/Neutrophil_diff_gene_expression/")

### 数据处理
##读取数据
gene<-read.csv("挑选的基因.csv",row.names = 1)
surv<-read.csv("survival_data.csv",row.names = 1)
##数据处理
#取交集
all_data <-intersect(rownames(gene), rownames(surv))
gene_select <- gene %>% filter(rownames(gene) %in% all_data)
surv_select <- surv %>% filter(rownames(surv) %in% all_data)
final_data <- data.frame(surv_select, gene_select, row.names = rownames(gene_select))  
write.csv(final_data, "生存分析所用数据.csv", row.names = T)

### COX分析
## Cox单因素分析
Coxoutput <- NULL
for(i in 3:ncol(final_data)){
  g <- colnames(final_data)[i]
  cox <- coxph(Surv(os_time,os_status) ~ final_data[,i], data = final_data) # 单变量cox模型
  coxSummary = summary(cox)
  
  Coxoutput <- rbind.data.frame(Coxoutput,
                                data.frame(gene = g,    
                                           HR = as.numeric(coxSummary$coefficients[,"exp(coef)"])[1],
                                           z = as.numeric(coxSummary$coefficients[,"z"])[1],
                                           pvalue = as.numeric(coxSummary$coefficients[,"Pr(>|z|)"])[1],
                                           lower = as.numeric(coxSummary$conf.int[,3][1]),
                                           upper = as.numeric(coxSummary$conf.int[,4][1]),
                                           stringsAsFactors = F),
                                stringsAsFactors = F)
}

write.csv(Coxoutput, "Cox单因素分析result.csv", row.names = F)

## 设定阈值，挑选基因
pcutoff <- 0.05
topgene <- Coxoutput[which(Coxoutput$pvalue < pcutoff),] # 取出p值小于阈值的基因
mutipul_gene_data <- gene_select[topgene$gene]
multigene<- data.frame(surv_select, mutipul_gene_data, row.names = rownames(mutipul_gene_data)) 

## COX多因素分析
multicox <- coxph(Surv(time = os_time,event = os_status) ~ ., data = multigene)
multisum <- summary(multicox)
multiresult <- data.frame(feature=colnames(multigene)[3:ncol(multigene)],
                          coef=as.numeric(multisum$coefficients[, "coef"]),
                          HR=as.numeric(multisum$coefficients[,"exp(coef)"]),
                          z = as.numeric(multisum$coefficients[,"z"]),
                          pvalue = as.numeric(multisum$coefficients[,"Pr(>|z|)"]),
                          lower=as.numeric(multisum$conf.int[,3]),
                          upper = as.numeric(multisum$conf.int[,4]),
                          stringsAsFactors = F)
write.csv(multiresult, "Cox多因素分析result.csv", row.names = F)

### 计算线性预测器（风险评分的代理）  
multigene$risk_time <- predict(multicox, type = 'risk') 

### 生存曲线
## 数据整理
risk_name <- multigene$risk_time
med <- median(risk_name) # 中位数
average <- mean(risk_name) # 平均数
high_group <- multigene[risk_name > average, ]
low_group <- multigene[risk_name <= average, ] 
high_group$group <- "High"
low_group$group <- "Low"
combined_data <- rbind(high_group, low_group)  
write.csv(combined_data, "带有风险评分和分组的文件.csv")
## 绘制图像
fit <- survfit(Surv(os_time, os_status) ~ group, data =combined_data )
ggsurvplot(fit, 
           data = combined_data,
           size = 1,                 # 更改线条粗细
           palette = c("#E7B800", "#2E9FDF"),
           xlab = "Time in days",
           conf.int = TRUE,          # 可信区间
           pval = TRUE,              # log-rank P值，也可以提供一个数值
           pval.method = TRUE,       # 计算P值的方法
           log.rank.weights = "1",
           conf.int.style = "step", 
           legend.labs = c("High", "Low"),    # 图例标签
           ggtheme = theme_light()      # 主题，支持ggplot2及其扩展包的主题
)
ggsave("ATP11AUN生存曲线.pdf", width = 6, height = 5)
dev.off()

### 其他数据
other1<-read.csv("CPTAC_Exptime.csv",row.names = 1)
other2<-read.csv("GSE37745_Exptime.csv",row.names = 1)
other3<-read.csv("GSE50081_Exptime.csv",row.names = 1)
other4<-read.csv("GSE68465_Exptime.csv",row.names = 1)

new1 <- other1[,c("futime","fustat","FABP7","ATP11AUN")]
new2 <- other2[,c("futime","fustat","FABP7","ATP11AUN")]
new3 <- other3[,c("futime","fustat","FABP7","ATP11AUN")]
new4 <- other4[,c("futime","fustat","FABP7","ATP11AUN")]

## 根据多因素权重计算独立数据风险值
coef_FABP7 <- multiresult[1,2]
coef_ATP11AUN <- multiresult[2,2]
new1$Riskvalue <- coef_FABP7 * new1$FABP7 + coef_ATP11AUN * new1$ATP11AUN

risk <- new1$Riskvalue
med2 <- median(risk) # 中位数
average2 <- mean(risk) # 平均数
high_group2 <- new1[risk > med2, ]
low_group2 <- new1[risk <= med2, ] 
high_group2$group <- "High"
low_group2$group <- "Low"
combined_data2 <- rbind(high_group2, low_group2)  
write.csv(combined_data2, "独立数据带有风险评分和分组的文件.csv")

## 绘制图像
fit2 <- survfit(Surv(futime, fustat) ~ group, data =combined_data2 )
ggsurvplot(fit2, 
           data = combined_data2,
           size = 1,                 # 更改线条粗细
           palette = c("#E7B800", "#2E9FDF"),
           xlab = "Time in days",
           conf.int = TRUE,          # 可信区间
           pval = TRUE,              # log-rank P值，也可以提供一个数值
           pval.method = TRUE,       # 计算P值的方法
           log.rank.weights = "1",
           conf.int.style = "step", 
           legend.labs = c("High", "Low"),    # 图例标签
           ggtheme = theme_light()      # 主题，支持ggplot2及其扩展包的主题
)
ggsave("独立数据生存曲线.pdf", width = 6, height = 5)
dev.off()
